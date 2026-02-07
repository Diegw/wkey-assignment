local Bezier = {}
Bezier.__index = Bezier

-- Bezier.DebugComparisons = 0
local ARC_SAMPLE_COUNT :number = 50

function Bezier.new(position0: Vector3, position1: Vector3, position2: Vector3)
	if position0 == nil or position1 == nil or position2 == nil then
		warn("Bezier requires 3 positions")
		return nil
	end
	local self = setmetatable({}, Bezier)

	self.Position0 = position0
	self.Position1 = position1
	self.Position2 = position2

	self:SetupArc()

	return self
end

function Bezier:SetupArc()
	self.ArcTable = {}
	self.TotalLength = 0

	local lastPosition :Vector3 = self:GetPosition(0)
	table.insert(self.ArcTable, { progress = 0, length = 0 })

	for i = 1, ARC_SAMPLE_COUNT do
		local newProgress :number = i / ARC_SAMPLE_COUNT
		local position :Vector3 = self:GetPosition(newProgress)
		local segmentLength :number = (position - lastPosition).Magnitude

		self.TotalLength += segmentLength
		table.insert(self.ArcTable, {
			progress = newProgress,
			length = self.TotalLength,
		})

		lastPosition = position
	end
end

function Bezier:GetPosition(progress: number): Vector3
	local remaining :number = 1 - progress
	local startInfluence :Vector3 = (remaining * remaining) * self.Position0
	local controlInfluence :Vector3 = (2 * remaining * progress) * self.Position1
	local finishInfluence :Vector3 = (progress * progress) * self.Position2
	local position :Vector3 = startInfluence + controlInfluence + finishInfluence
	return position
end

function Bezier:GetTangent(progress: number): Vector3
	local directionFromStartToControl :Vector3 = (2 * (1 - progress)) * (self.Position1 - self.Position0)
	local directionFromControlToFinish :Vector3 = (2 * progress) * (self.Position2 - self.Position1)
	local tangent :Vector3 = directionFromStartToControl + directionFromControlToFinish
	return tangent
end

function Bezier:GetLength(): number
	return self.TotalLength
end

function Bezier:GetCFrameFromProgress(progress: number, upVector: Vector3?): CFrame
	local position :Vector3 = self:GetPosition(progress)
	local tangent :Vector3 = self:GetTangent(progress)

	if tangent.Magnitude == 0 then
		return CFrame.new(position)
	end

	return CFrame.lookAt(position, position + tangent.Unit, upVector or Vector3.yAxis)
end

function Bezier:GetProgressFromDistance(distance: number): number
	distance = math.clamp(distance, 0, self.TotalLength)

	for i = 2, #self.ArcTable do
		-- Bezier.DebugComparisons += 1
		local previous = self.ArcTable[i - 1]
		local current = self.ArcTable[i]

		if distance <= current.length then
			local alpha = (distance - previous.length) / (current.length - previous.length)
			return previous.progress + alpha * (current.progress - previous.progress)
		end
	end

	return 1
end

function Bezier:GetProgressFromDistanceCached(distance: number, state: table): number
	distance = math.clamp(distance, 0, self.TotalLength)

	local arcTable = self.ArcTable
	local index = state.ArcIndex or 1

	-- Advance forward only
	while index < #arcTable and distance > arcTable[index + 1].length do
		-- Bezier.DebugComparisons += 1
		index += 1
	end

	state.ArcIndex = index

	local current = arcTable[index]
	local nextSample = arcTable[index + 1]

	if not nextSample then
		return 1
	end

	local alpha = (distance - current.length) / (nextSample.length - current.length)
	return current.progress + alpha * (nextSample.progress - current.progress)
end

return Bezier