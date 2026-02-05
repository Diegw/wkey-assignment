local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Bezier = require(ReplicatedStorage.Source.Bezier)

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
	self.Speed = 1 --TODO:set value with ui
    self.ScrollDistance = 0
    self.Rebuilding = false
    self.Segments = {}

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
        local t = self.Curve:GetProgressFromDistance(segment.Distance)
        local cf = self.Curve:GetCFrameFromProgress(t)
        segment.Model:PivotTo(cf)
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
			segmentModel.Parent = self.Model

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
	end)
end

return Conveyor
