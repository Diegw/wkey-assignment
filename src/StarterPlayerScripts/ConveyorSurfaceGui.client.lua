local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CONVEYOR_FOLDER_NAME = "Conveyor"

local event :UnreliableRemoteEvent = nil

local function FireConveyorAxisChangeEvent(sign :number, variable :string)
    if sign == nil or variable == nil then
        return
    end
    if event == nil then
        event = ReplicatedStorage.Assets:FindFirstChild("ConveyorAxisEvent")
    end
    if event then
        event:FireServer(sign, variable)
    end
end

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

local function SetupConveyorAxisSurfaceGui(surfaceGui :SurfaceGui, variable :string)
    if surfaceGui == nil or not surfaceGui:IsA("SurfaceGui") then
        return
    end
    warn(surfaceGui)
    local xFrame :Frame = surfaceGui:FindFirstChild("XFrame", true)
    if xFrame then
        local leftButton :ImageButton = xFrame:FindFirstChild("LeftButton", true)
        if leftButton then
            leftButton.MouseButton1Click:Connect(function()
                FireConveyorAxisChangeEvent(-Vector3.xAxis, variable)
            end)
        end
        local rightButton :ImageButton = xFrame:FindFirstChild("RightButton", true)
        if rightButton then
            rightButton.MouseButton1Click:Connect(function()
                FireConveyorAxisChangeEvent(Vector3.xAxis, variable)
            end)
        end
    end

    local zFrame :Frame = surfaceGui:FindFirstChild("ZFrame", true)
    if zFrame then
        local leftButton :ImageButton = zFrame:FindFirstChild("LeftButton", true)
        if leftButton then
            leftButton.MouseButton1Click:Connect(function()
                FireConveyorAxisChangeEvent(-Vector3.zAxis, variable)
            end)
        end
        local rightButton :ImageButton = zFrame:FindFirstChild("RightButton", true)
        if rightButton then
            rightButton.MouseButton1Click:Connect(function()
                FireConveyorAxisChangeEvent(Vector3.zAxis, variable)
            end)
        end
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
    conveyorModel.DescendantAdded:Connect(function(child)
        if child == nil then
            return
        end
        if child.Name == "SurfaceGui" then
            SetupConveyorSurfaceGui(child)
        elseif child.Name == "StartSurfaceGui" then
            SetupConveyorAxisSurfaceGui(child, "Start")
        elseif child.Name == "ControlSurfaceGui" then
            SetupConveyorAxisSurfaceGui(child, "Control")
        elseif child.Name == "FinishSurfaceGui" then
            SetupConveyorAxisSurfaceGui(child, "Finish")
        end
    end)

    local surfaceGui :SurfaceGui = conveyorModel:FindFirstChild("SurfaceGui", true)
    if surfaceGui then
        SetupConveyorSurfaceGui(surfaceGui)
    end

    local startSurfaceGui :SurfaceGui = conveyorModel:FindFirstChild("StartSurfaceGui", true)
    if startSurfaceGui then
        SetupConveyorAxisSurfaceGui(startSurfaceGui, "Start")
    end

    local controlSurfaceGui :SurfaceGui = conveyorModel:FindFirstChild("ControlSurfaceGui", true)
    if controlSurfaceGui then
        SetupConveyorAxisSurfaceGui(controlSurfaceGui, "Control")
    end

    local finishSurfaceGui :SurfaceGui = conveyorModel:FindFirstChild("FinishSurfaceGui", true)
    if finishSurfaceGui then
        SetupConveyorAxisSurfaceGui(finishSurfaceGui, "Finish")
    end
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