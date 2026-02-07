local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Bezier = require(ReplicatedStorage.Source.Bezier)

local CONVEYOR_FOLDER_NAME = "Conveyor"
local LUGGAGE_FOLDER_NAME = "Luggage"

local DEFAULT_SPEED :number = 2
local HEIGHT_OFFSET :number = 1.25

local LuggageClient = {}
LuggageClient.__index = LuggageClient

function LuggageClient.new(conveyorModel: Model, luggageModel: Model)
	local self = setmetatable({}, LuggageClient)

	self.ConveyorModel = conveyorModel
	self.Model = luggageModel

	self.StartPart = conveyorModel:WaitForChild("Start")
	self.ControlPart = conveyorModel:WaitForChild("Control")
	self.FinishPart = conveyorModel:WaitForChild("Finish")

	self.Speed = luggageModel:GetAttribute("Speed") or DEFAULT_SPEED
	self.Distance = luggageModel:GetAttribute("Distance") or 0

	self.Curve = nil
	self.CurveLength = 0
	self.Rebuilding = false
	self.ArcIndex = 1

	self:SetupCurve()
	self:ListenEvents(conveyorModel)
	self:Start()

	return self
end

function LuggageClient:SetupCurve()
	self.Curve = Bezier.new(
		self.StartPart.Position,
		self.ControlPart.Position,
		self.FinishPart.Position
	)
	self.CurveLength = self.Curve:GetLength()
	self.ArcIndex = 1
end

function LuggageClient:ListenEvents(conveyorModel :Model)
	local function RebuildCurve()
		if self.Rebuilding then
			return
		end
		self.Rebuilding = true
		self:SetupCurve()
		self.Rebuilding = false
	end

	self.StartPart:GetPropertyChangedSignal("Position"):Connect(RebuildCurve)
	self.ControlPart:GetPropertyChangedSignal("Position"):Connect(RebuildCurve)
	self.FinishPart:GetPropertyChangedSignal("Position"):Connect(RebuildCurve)

	conveyorModel:GetAttributeChangedSignal("Speed"):Connect(function()
		self.Speed = conveyorModel:GetAttribute("Speed") or self.Speed
	end)

	self.Model:GetAttributeChangedSignal("Distance"):Connect(function()
		self.Distance = self.Model:GetAttribute("Distance") or self.Distance
	end)
end

function LuggageClient:Start()
	RunService.Heartbeat:Connect(function(dt)
		if self.Rebuilding or self.CurveLength <= 0 then
			return
		end

		if not self.Model or not self.Model.Parent then
			return
		end

		local previousDistance = self.Distance
		self.Distance += self.Speed * dt

		if self.Distance >= self.CurveLength then
			return
		end

		if self.Distance < previousDistance then
			self.ArcIndex = 1
		end

		local progress = self.Curve:GetProgressFromDistanceCached(self.Distance, self)
		local cframe = self.Curve:GetCFrameFromProgress(progress)
		cframe = cframe * CFrame.new(0, HEIGHT_OFFSET, 0)

		self.Model:PivotTo(cframe)
	end)
end

local controllers = nil

local function SetupLuggage(conveyorModel: Model, luggageModel: Model)
    if conveyorModel == nil or luggageModel == nil then
        return
    end
    if controllers == nil then
        controllers = {}
    end
	if controllers[luggageModel] then
		return
	end
	controllers[luggageModel] = LuggageClient.new(conveyorModel, luggageModel)
end

local function CheckLuggage(conveyorModel: Model)
	local luggageFolder = conveyorModel:WaitForChild(LUGGAGE_FOLDER_NAME, 5)
	if luggageFolder == nil then
		return
	end

	luggageFolder.ChildAdded:Connect(function(luggageModel)
		if luggageModel:IsA("Model") then
			SetupLuggage(conveyorModel, luggageModel)
		end
	end)

	luggageFolder.ChildRemoved:Connect(function(luggageModel)
        if controllers then
            controllers[luggageModel] = nil
        end
	end)

	for _, model in ipairs(luggageFolder:GetChildren()) do
		if model:IsA("Model") then
			SetupLuggage(conveyorModel, model)
		end
	end
end

local function SetupClientLuggage()
	local world = workspace:WaitForChild("World", 5)
	if world == nil then
		return
	end

	local folder = world:WaitForChild(CONVEYOR_FOLDER_NAME, 5)
	if folder == nil then
		return
	end

	folder.ChildAdded:Connect(function(conveyorModel)
		if conveyorModel:IsA("Model") then
			CheckLuggage(conveyorModel)
		end
	end)

	for _, conveyorModel in ipairs(folder:GetChildren()) do
		if conveyorModel:IsA("Model") then
			CheckLuggage(conveyorModel)
		end
	end
end

SetupClientLuggage()