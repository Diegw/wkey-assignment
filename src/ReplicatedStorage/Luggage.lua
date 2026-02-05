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

	local colorMeshPart :MeshPart = self.Model:FindFirstChild("Paint", true)
	if colorMeshPart then
		local r :number = math.random(0, 255)
		local g :number = math.random(0, 255)
		local b :number = math.random(0, 255)
		colorMeshPart.Color = Color3.fromRGB(r, g, b)
	end

	self.InstanceId = self:GetUniqueId("luggage")
	self.Distance = 0
	self.YOffset = 1.25

	self:SetupProximityPrompt()

	return self
end

function Luggage:GetUniqueId(prefix :string?)
	local newId :string = nil
	if prefix ~= nil and type(prefix) == "string" and prefix ~= "" then
		newId = (newId == nil) and prefix or newId.."."..prefix
	end
	local date = os.date("!*t")
	if date ~= nil then
		newId = (newId == nil) and date.year or newId.."."..date.year
		newId = (newId == nil) and date.month or newId.."."..date.month
		newId = (newId == nil) and date.day or newId.."."..date.day
		newId = (newId == nil) and date.hour or newId.."."..date.hour
		newId = (newId == nil) and date.min or newId.."."..date.min
		newId = (newId == nil) and date.sec or newId.."."..date.sec
	end
	local clock :number = os.clock()
	if clock ~= nil then
		newId = (newId == nil) and clock or newId.."."..os.clock()
	end
	return newId
end

function Luggage:SetupProximityPrompt()
	local proximityPrompt :ProximityPrompt = self.Model:FindFirstChild("ProximityPrompt", true)
	if proximityPrompt == nil then
		return
	end
	proximityPrompt.Triggered:Connect(function()
		warn("Instance:"..self.InstanceId)
	end)
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
