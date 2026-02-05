local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CONVEYOR_FOLDER_NAME = "Conveyor"

local event :UnreliableRemoteEvent = nil

local function FireConveyorChangeValueEvent(sign :number, variable :string)
    if sign == nil or variable == nil then
        return
    end
    if event == nil then
        event = ReplicatedStorage.Assets:FindFirstChild("ConveyorEvent")
    end
    if event then
        event:FireServer(sign, variable)
    end
end

local function SetupConveyorSurfaceGui(surfaceGui :SurfaceGui)
    if surfaceGui == nil or not surfaceGui:IsA("SurfaceGui") then
        return
    end
    local speedFrame :Frame = surfaceGui:FindFirstChild("SpeedFrame", true)
    if speedFrame then
        local leftButton :ImageButton = speedFrame:FindFirstChild("LeftButton", true)
        if leftButton then
            leftButton.MouseButton1Click:Connect(function()
                FireConveyorChangeValueEvent(-1, "Speed")
            end)
        end
        local rightButton :ImageButton = speedFrame:FindFirstChild("RightButton", true)
        if rightButton then
            rightButton.MouseButton1Click:Connect(function()
                FireConveyorChangeValueEvent(1, "Speed")
            end)
        end
    end

    local frequencyFrame :Frame = surfaceGui:FindFirstChild("FrequencyFrame", true)
    if frequencyFrame then
        local leftButton :ImageButton = frequencyFrame:FindFirstChild("LeftButton", true)
        if leftButton then
            leftButton.MouseButton1Click:Connect(function()
                FireConveyorChangeValueEvent(-1, "Frequency")
            end)
        end
        local rightButton :ImageButton = frequencyFrame:FindFirstChild("RightButton", true)
        if rightButton then
            rightButton.MouseButton1Click:Connect(function()
                FireConveyorChangeValueEvent(1, "Frequency")
            end)
        end
    end
end

local function SetupConveyor(conveyorModel :Model)
    if conveyorModel == nil or not conveyorModel:IsA("Model") then
        return
    end
    local surfaceGui :SurfaceGui = conveyorModel:FindFirstChild("SurfaceGui", true)
    if surfaceGui == nil then
        conveyorModel.DescendantAdded:Connect(function(child)
            SetupConveyorSurfaceGui(child)
        end)
        return
    end
    SetupConveyorSurfaceGui(surfaceGui)
end

local function Setup()
    local folder :Folder = workspace.World:FindFirstChild(CONVEYOR_FOLDER_NAME)
    if folder == nil then
        warn("No conveyor folder in workspace")
        return
    end

    local conveyors = folder:GetChildren()
    if conveyors == nil or #conveyors <= 0 then
        folder.ChildAdded:Connect(function(child)
            SetupConveyor(child)
        end)
        return
    end
    for _, conveyorModel :Model in conveyors do
        SetupConveyor(conveyorModel)
    end
end

Setup()