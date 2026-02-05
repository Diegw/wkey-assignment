local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Conveyor = require(ReplicatedStorage.Source.Conveyor)

local CONVEYOR_FOLDER_NAME = "Conveyor"

local function SetupConveyors()
    local folder :Folder = workspace.World:FindFirstChild(CONVEYOR_FOLDER_NAME)
    if folder == nil then
        warn("No conveyor folder in workspace")
        return
    end
    local conveyors = folder:GetChildren()
    if conveyors == nil then
        warn("No conveyor models in conveyor folder")
        return
    end
    for _, conveyorModel :Model in conveyors do
        if conveyorModel == nil or not conveyorModel:IsA("Model") then
            continue
        end
        local newConveyor = Conveyor.new(conveyorModel)
        if newConveyor == nil then
            warn("Conveyor is nil")
        end
    end
end

SetupConveyors()