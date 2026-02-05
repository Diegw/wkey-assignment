local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Luggage = {}
Luggage.__index = Luggage

function Luggage.new(parent: Instance)
	local self = setmetatable({}, Luggage)

	self.LuggageFolder = parent:FindFirstChild("Luggage")
    if self.LuggageFolder == nil then
        self.LuggageFolder = Instance.new("Folder")
        self.LuggageFolder.Name = "Luggage"
        self.LuggageFolder.Parent = parent
    end

	local luggageTemplate :Model = ReplicatedStorage.Assets:FindFirstChild("LuggageTemplate")

	self.Model = luggageTemplate:Clone()
	self.Model.Name = "Luggage"
	self.Model.Parent = self.LuggageFolder

	self.Distance = 0
	self.YOffset = 1.25

	return self
end

function Luggage:Update(curve, distance)
	self.Distance = distance

	local progress :number = curve:GetProgressFromDistance(distance)
	local cframe :CFrame = curve:GetCFrameFromProgress(progress)

	cframe = cframe * CFrame.new(0, self.YOffset, 0)
	self.Model:PivotTo(cframe)
end

function Luggage:Destroy()
	if self.Model then
		self.Model:Destroy()
		self.Model = nil
	end
end

return Luggage
