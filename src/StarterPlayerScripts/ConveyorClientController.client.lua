local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Bezier = require(ReplicatedStorage.Source.Bezier)

local CONVEYOR_FOLDER_NAME = "Conveyor"
local DEFAULT_SPEED :number = 2

local ConveyorClient = {}
ConveyorClient.__index = ConveyorClient

function ConveyorClient.new(model: Model)
	local self = setmetatable({}, ConveyorClient)

	self.Model = model
	self.SegmentsFolder = nil
	self.Segments = {}

	self.StartPart = model:WaitForChild("Start")
	self.ControlPart = model:WaitForChild("Control")
	self.FinishPart = model:WaitForChild("Finish")

	self.Speed = model:GetAttribute("Speed") or DEFAULT_SPEED
	self.SegmentLength = model:GetAttribute("SegmentLength") or 4
	self.ScrollDistance = model:GetAttribute("ScrollDistance") or 0

	self.Curve = nil
	self.CurveLength = 0
	self.Rebuilding = false

	self:WaitSegments()
	self:SetupCurve()
	self:RegisterSegments()
	self:ListenEvents()
	self:Start()

	return self
end

function ConveyorClient:WaitSegments()
	self.SegmentsFolder = self.Model:WaitForChild("Segments", 5)
end

function ConveyorClient:SetupCurve()
	self.Curve = Bezier.new(
		self.StartPart.Position,
		self.ControlPart.Position,
		self.FinishPart.Position
	)
	self.CurveLength = self.Curve:GetLength()

	for _, segment in ipairs(self.Segments) do
		segment.ArcIndex = 1
	end
end

function ConveyorClient:RegisterSegments()
	table.clear(self.Segments)

	local index = 1
	for _, segmentModel in ipairs(self.SegmentsFolder:GetChildren()) do
		if segmentModel:IsA("Model") then
			self.Segments[index] = {
				Model = segmentModel,
				Distance = (index - 1) * self.SegmentLength,
				ArcIndex = 1,
			}
			index += 1
		end
	end
end

function ConveyorClient:ListenEvents()
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

	self.Model:GetAttributeChangedSignal("Speed"):Connect(function()
		self.Speed = self.Model:GetAttribute("Speed") or self.Speed
	end)
	self.Model:GetAttributeChangedSignal("SegmentLength"):Connect(function()
		self.SegmentLength = self.Model:GetAttribute("SegmentLength") or self.SegmentLength
	end)

	self.SegmentsFolder.ChildAdded:Connect(function()
		self:RegisterSegments()
	end)
	self.SegmentsFolder.ChildRemoved:Connect(function()
		self:RegisterSegments()
	end)
end

function ConveyorClient:Start()
	RunService.Heartbeat:Connect(function(dt)
		if self.Rebuilding or self.CurveLength <= 0 then
			return
		end

		self.ScrollDistance += self.Speed * dt
		if self.ScrollDistance >= self.CurveLength then
			self.ScrollDistance -= self.CurveLength
		end

		for i, segment in ipairs(self.Segments) do
			local previousDistance = segment.Distance

			local distance = (self.ScrollDistance + (i - 1) * self.SegmentLength) % self.CurveLength
			if distance < previousDistance then
				segment.ArcIndex = 1
			end
			segment.Distance = distance

			local progress = self.Curve:GetProgressFromDistanceCached(distance, segment)
			local cframe = self.Curve:GetCFrameFromProgress(progress)
			segment.Model:PivotTo(cframe)
		end
	end)
end

local controllers = {}

local function SetupConveyor(model: Model)
    if model == nil then
        return
    end
    if controllers == nil then
        controllers = {}
    end
	if controllers[model.Name] then
		return
	end
	controllers[model] = ConveyorClient.new(model)
end

local function SetupClientConveyors()
	local world = workspace:WaitForChild("World", 5)
    if world == nil then
        return
    end
	local folder = world:WaitForChild(CONVEYOR_FOLDER_NAME, 5)
    if folder == nil then
        return
    end
    folder.ChildAdded:Connect(function(model)
        if model:IsA("Model") then
            SetupConveyor(model)
        end
    end)
    local conveyors = folder:GetChildren()
	for _, model in ipairs(conveyors) do
		if model and model:IsA("Model") then
			SetupConveyor(model)
		end
	end
end

SetupClientConveyors()