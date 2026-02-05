local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Bezier = require(ReplicatedStorage.Source.Bezier)
local Luggage = require(ReplicatedStorage.Source.Luggage)

local INITIAL_SPEED :number = 2
local INITIAL_FREQUENCY :number = 4

local Conveyor = {}
Conveyor.__index = Conveyor

function Conveyor.new(model: Model)
    if model == nil then
        warn("Conveyor Model is nil")
        return nil
    end
	local self = setmetatable({}, Conveyor)

	self.Model = model
	self.SegmentTemplate = ReplicatedStorage.Assets:FindFirstChild("ConveyorSegment")
	self.Speed = INITIAL_SPEED
    self.ScrollDistance = 0
    self.Rebuilding = false
    self.Segments = {}

    self.Luggage = {}
	self.LuggageSpawnFrequency = INITIAL_FREQUENCY
	self.LuggageOffsetY = 2
	self.LuggageLastTime = 0

	self.StartPart = model:FindFirstChild("Start")
	self.ControlPart = model:FindFirstChild("Control")
	self.FinishPart = model:FindFirstChild("Finish")

    self.SegmentsFolder = model:FindFirstChild("Segments")
    if self.SegmentsFolder == nil then
        self.SegmentsFolder = Instance.new("Folder")
        self.SegmentsFolder.Name = "Segments"
        self.SegmentsFolder.Parent = model
    end

	self:SetupCurve()
	self:SpawnSegments()
	self:PlaceSegments()
	self:SetConnections()
	self:SetupSurfaceGui()
	self:ListenEvent()
	self:Start()

	return self
end

function Conveyor:SetupCurve()
	self.Curve = Bezier.new(
		self.StartPart.CFrame.Position,
		self.ControlPart.CFrame.Position,
		self.FinishPart.CFrame.Position
	)
	self.CurveLength = self.Curve:GetLength()
end

function Conveyor:SpawnSegments()
	self.SegmentLength = self.SegmentTemplate.PrimaryPart.Size.Z
	local segmentCount = math.ceil(self.CurveLength / self.SegmentLength) + 1

	for i = 1, segmentCount do
		local segmentModel = self.SegmentTemplate:Clone()
		segmentModel.Name = "Segment"
		segmentModel.Parent = self.SegmentsFolder

		local segmentDistance :number = (i - 1) * self.SegmentLength

		self.Segments[i] = {
			Model = segmentModel,
			Distance = segmentDistance,
		}
	end
end

function Conveyor:PlaceSegments(inSegment :table)
	local function PlaceSegment(segment :table)
        local progress :number = self.Curve:GetProgressFromDistance(segment.Distance)
        local cframe :CFrame = self.Curve:GetCFrameFromProgress(progress)
        segment.Model:PivotTo(cframe)
    end

    if inSegment ~= nil then
        PlaceSegment(inSegment)
    else
        for _, segment :table in ipairs(self.Segments) do
            PlaceSegment(segment)
        end
    end
end

function Conveyor:SetConnections()
	local function RebuildCurve()
		if self.Rebuilding then
            return
        end
		self.Rebuilding = true
		self:SetupCurve()

        for i, segment in ipairs(self.Segments) do
            segment.Distance = self.ScrollDistance + (i - 1) * self.SegmentLength
        end

		local requiredCount = math.max(1, math.ceil(self.CurveLength / self.SegmentLength) + 1)
		for i = #self.Segments, requiredCount + 1, -1 do
			self.Segments[i].Model:Destroy()
			self.Segments[i] = nil
		end
		for i = #self.Segments + 1, requiredCount do
			local previous = self.Segments[i - 1]
			local distance = previous and (previous.Distance + self.SegmentLength) or 0

			local segmentModel = self.SegmentTemplate:Clone()
			segmentModel.Name = "Segment"
			segmentModel.Parent = self.SegmentsFolder

			self.Segments[i] = {
				Model = segmentModel,
				Distance = distance,
			}
		end

		self:PlaceSegments()
		self.Rebuilding = false
	end

	self.StartPart:GetPropertyChangedSignal("Position"):Connect(RebuildCurve)
	self.ControlPart:GetPropertyChangedSignal("Position"):Connect(RebuildCurve)
	self.FinishPart:GetPropertyChangedSignal("Position"):Connect(RebuildCurve)
end

function Conveyor:SetupSurfaceGui()
	local surfaceGui :SurfaceGui = self.Model:FindFirstChild("SurfaceGui", true)
	if surfaceGui == nil then
		return
	end

	local speedFrame :Frame = surfaceGui:FindFirstChild("SpeedFrame", true)
	if speedFrame then
		self.SpeedValueLabel = speedFrame:FindFirstChild("ValueLabel", true)
		if self.SpeedValueLabel then
			self.SpeedValueLabel.Text = self.Speed
		end
	end

	local frequencyFrame :Frame = surfaceGui:FindFirstChild("FrequencyFrame", true)
	if frequencyFrame then
		self.FrequencyValueLabel = frequencyFrame:FindFirstChild("ValueLabel", true)
		if self.FrequencyValueLabel then
			self.FrequencyValueLabel.Text = self.LuggageSpawnFrequency
		end
	end
end

function Conveyor:Start()
	RunService.Heartbeat:Connect(function(dt)
        if self.Rebuilding then
            return
        end
		local delta :number = self.Speed * dt
		local curveLength = self.CurveLength

		self.ScrollDistance += delta
		if self.ScrollDistance > curveLength then
			self.ScrollDistance -= curveLength
		end

		for i, segment in ipairs(self.Segments) do
			local distance = (self.ScrollDistance + (i - 1) * self.SegmentLength) % curveLength
			segment.Distance = distance

            self:PlaceSegments(segment)
		end

		self.LuggageLastTime += dt
		if self.LuggageLastTime >= self.LuggageSpawnFrequency then
			self.LuggageLastTime = 0
			self:SpawnLuggage()
		end

		for i = #self.Luggage, 1, -1 do
			local luggage = self.Luggage[i]
			luggage.Distance += delta

			if luggage.Distance >= curveLength then
				luggage:Destroy()
				table.remove(self.Luggage, i)
			else
				luggage:Update(self.Curve, luggage.Distance)
			end
		end
	end)
end

function Conveyor:ListenEvent()
	local event :UnreliableRemoteEvent = ReplicatedStorage.Assets:FindFirstChild("ConveyorEvent")
	if event == nil then
		return
    end
	event.OnServerEvent:Connect(function(player, sign :number, variable :string)
		if sign == nil or variable == nil then
			return
		end
		sign = math.sign(sign)
		if variable == "Speed" then
			self.Speed += sign
			self.Speed = math.clamp(self.Speed, 1, math.huge)
			self.SpeedValueLabel.Text = self.Speed
		elseif variable == "Frequency" then
			self.LuggageSpawnFrequency += sign
			self.LuggageSpawnFrequency = math.clamp(self.LuggageSpawnFrequency, 1, math.huge)
			self.FrequencyValueLabel.Text = self.LuggageSpawnFrequency
		end
	end)
end

function Conveyor:SpawnLuggage()
	local luggage = Luggage.new(self.Model)
	table.insert(self.Luggage, luggage)
end

return Conveyor
