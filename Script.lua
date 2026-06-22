local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Настройки
local ESP_Enabled = false
local Aimbot_Enabled = false
local Fly_Enabled = false
local Aimbot_FOV = 150 

-- Хранилище для графики ESP
local ESP_Cache = {}

-- Круг FOV строго по центру
local FOVCircle = Drawing.new("Circle")
FOVCircle.Color = Color3.fromRGB(0, 255, 255)
FOVCircle.Thickness = 1.5
FOVCircle.NumSides = 60
FOVCircle.Radius = Aimbot_FOV
FOVCircle.Filled = false
FOVCircle.Visible = false

-- Оптимизированный ESP
local function CreateESP(player)
    if player == LocalPlayer then return end

    local Box = Drawing.new("Square")
    Box.Visible = false
    Box.Color = Color3.fromRGB(255, 0, 0)
    Box.Thickness = 1.5
    Box.Filled = false

    local Line = Drawing.new("Line")
    Line.Visible = false
    Line.Color = Color3.fromRGB(255, 255, 255)
    Line.Thickness = 1

    ESP_Cache[player] = {Box = Box, Line = Line}
end

local function RemoveESP(player)
    if ESP_Cache[player] then
        ESP_Cache[player].Box:Remove()
        ESP_Cache[player].Line:Remove()
        ESP_Cache[player] = nil
    end
end

for _, p in pairs(Players:GetPlayers()) do CreateESP(p) end
Players.PlayerAdded:Connect(CreateESP)
Players.PlayerRemoving:Connect(RemoveESP)

-- Умный поиск цели с приоритетом по дистанции до центра экрана
local function GetClosestPlayerToCenter()
    local closestPlayer = nil
    local shortestDistance = Aimbot_FOV
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Head") and player.Character:FindFirstChildOfClass("Humanoid") and player.Character.Humanoid.Health > 0 then
            
            local pos, onScreen = Camera:WorldToViewportPoint(player.Character.Head.Position)
            if onScreen then
                local distance = (Vector2.new(pos.X, pos.Y) - screenCenter).Magnitude

                -- Проверяем попадание в FOV радиус
                if distance < shortestDistance then
                    closestPlayer = player
                    shortestDistance = distance
                end
            end
        end
    end
    return closestPlayer
end

-- Бесконечный прыжок (Fly)
UserInputService.JumpRequest:Connect(function()
    if Fly_Enabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):ChangeState("Jumping")
    end
end)

-- Высокопроизводительный цикл обновлений
RunService.Heartbeat:Connect(function()
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    -- Визуализация FOV круга
    if Aimbot_Enabled then
        FOVCircle.Radius = Aimbot_FOV
        FOVCircle.Position = screenCenter
        FOVCircle.Visible = true
    else
        FOVCircle.Visible = false
    end

    -- Плавный и быстрый ESP без задержек
    for player, objs in pairs(ESP_Cache) do
        if ESP_Enabled and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChildOfClass("Humanoid") and player.Character.Humanoid.Health > 0 then
            local hrp = player.Character.HumanoidRootPart
            local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)

            if onScreen then
                local distance = (Camera.CFrame.Position - hrp.Position).Magnitude
                local sizeX = 2300 / distance 
                local sizeY = 3300 / distance

                objs.Box.Size = Vector2.new(sizeX, sizeY)
                objs.Box.Position = Vector2.new(pos.X - sizeX / 2, pos.Y - sizeY / 2)
                objs.Box.Visible = true

                objs.Line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                objs.Line.To = Vector2.new(pos.X, pos.Y + (sizeY / 2))
                objs.Line.Visible = true
            else
                objs.Box.Visible = false
                objs.Line.Visible = false
            end
        else
            objs.Box.Visible = false
            objs.Line.Visible = false
        end
    end

    -- Улучшенная логика Постоянного Аимбота
    if Aimbot_Enabled then
        local target = GetClosestPlayerToCenter()
        
        if target and target.Character and target.Character:FindFirstChild("Head") then
            local targetHead = target.Character.Head
            
            -- Проверяем, двигает ли пользователь камеру пальцем/мышкой в этот момент
            local isMovingCamera = UserInputService:GetMouseDelta().Magnitude > 2
            
            if isMovingCamera then
                Camera.CFrame = Camera.CFrame:Lerp(CFrame.lookAt(Camera.CFrame.Position, targetHead.Position), 0.4)
            else
                Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, targetHead.Position)
            end
        end
    end
end)

--- ========================================== ---
---                 ИНТЕРФЕЙС (GUI)            ---
--- ========================================== ---

if CoreGui:FindFirstChild("DeltaESP_Gui") then
    CoreGui.DeltaESP_Gui:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "DeltaESP_Gui"
ScreenGui.Parent = CoreGui
ScreenGui.ResetOnSpawn = false

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 220, 0, 240) -- Оптимальная высота под новый лейаут
MainFrame.Position = UDim2.new(0.5, -110, 0.4, -120)
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true 
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 10)
UICorner.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 35)
Title.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
Title.Text = "@RomanCriminal script"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 14
Title.Parent = MainFrame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 10)
TitleCorner.Parent = Title

-- Кнопка ESP (Слева в верхнем ряду)
local ToggleButton = Instance.new("TextButton")
ToggleButton.Size = UDim2.new(0, 85, 0, 40)
ToggleButton.Position = UDim2.new(0, 20, 0, 50)
ToggleButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
ToggleButton.Text = "ESP: OFF"
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.Font = Enum.Font.GothamBold
ToggleButton.TextSize = 14
ToggleButton.Parent = MainFrame

local ButtonCorner = Instance.new("UICorner")
ButtonCorner.CornerRadius = UDim.new(0, 8)
ButtonCorner.Parent = ToggleButton

ToggleButton.MouseButton1Click:Connect(function()
    ESP_Enabled = not ESP_Enabled
    if ESP_Enabled then
        ToggleButton.Text = "ESP: ON"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
    else
        ToggleButton.Text = "ESP: OFF"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    end
end)

-- Кнопка FLY (Справа в верхнем ряду, рядом с ESP)
local FlyButton = Instance.new("TextButton")
FlyButton.Size = UDim2.new(0, 85, 0, 40)
FlyButton.Position = UDim2.new(0, 115, 0, 50)
FlyButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
FlyButton.Text = "FLY: OFF"
FlyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
FlyButton.Font = Enum.Font.GothamBold
FlyButton.TextSize = 14
FlyButton.Parent = MainFrame

local FlyCorner = Instance.new("UICorner")
FlyCorner.CornerRadius = UDim.new(0, 8)
FlyCorner.Parent = FlyButton

FlyButton.MouseButton1Click:Connect(function()
    Fly_Enabled = not Fly_Enabled
    if Fly_Enabled then
        FlyButton.Text = "FLY: ON"
        FlyButton.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
    else
        FlyButton.Text = "FLY: OFF"
        FlyButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    end
end)

-- Кнопка AIMBOT (Ниже под ESP и FLY)
local AimButton = Instance.new("TextButton")
AimButton.Size = UDim2.new(0, 180, 0, 40)
AimButton.Position = UDim2.new(0.5, -90, 0, 105)
AimButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
AimButton.Text = "AIMBOT: OFF"
AimButton.TextColor3 = Color3.fromRGB(255, 255, 255)
AimButton.Font = Enum.Font.GothamBold
AimButton.TextSize = 16
AimButton.Parent = MainFrame

local AimCorner = Instance.new("UICorner")
AimCorner.CornerRadius = UDim.new(0, 8)
AimCorner.Parent = AimButton

AimButton.MouseButton1Click:Connect(function()
    Aimbot_Enabled = not Aimbot_Enabled
    if Aimbot_Enabled then
        AimButton.Text = "AIMBOT: ON"
        AimButton.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
    else
        AimButton.Text = "AIMBOT: OFF"
        AimButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    end
end)

--- ПОЛЗУНОК FOV (В самом низу) ---
local SliderLabel = Instance.new("TextLabel")
SliderLabel.Size = UDim2.new(0, 180, 0, 20)
SliderLabel.Position = UDim2.new(0.5, -90, 0, 160)
SliderLabel.BackgroundTransparency = 1
SliderLabel.Text = "FOV Радиус: " .. tostring(Aimbot_FOV)
SliderLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
SliderLabel.Font = Enum.Font.GothamBold
SliderLabel.TextSize = 12
SliderLabel.Parent = MainFrame

local SliderFrame = Instance.new("Frame")
SliderFrame.Size = UDim2.new(0, 180, 0, 10)
SliderFrame.Position = UDim2.new(0.5, -90, 0, 190)
SliderFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
SliderFrame.BorderSizePixel = 0
SliderFrame.Parent = MainFrame

local SliderCorner = Instance.new("UICorner")
SliderCorner.CornerRadius = UDim.new(0, 4)
SliderCorner.Parent = SliderFrame

local SliderFill = Instance.new("Frame")
SliderFill.Size = UDim2.new(Aimbot_FOV / 500, 0, 1, 0)
SliderFill.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
SliderFill.BorderSizePixel = 0
SliderFill.Parent = SliderFrame

local FillCorner = Instance.new("UICorner")
FillCorner.CornerRadius = UDim.new(0, 4)
FillCorner.Parent = SliderFill

local SliderButton = Instance.new("TextButton")
SliderButton.Size = UDim2.new(0, 16, 0, 16)
SliderButton.Position = UDim2.new(Aimbot_FOV / 500, -8, 0.5, -8)
SliderButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
SliderButton.Text = ""
SliderButton.Parent = SliderFrame

local RoundCorner = Instance.new("UICorner")
RoundCorner.CornerRadius = UDim.new(1, 0)
RoundCorner.Parent = SliderButton

local dragging = false

local function updateSlider(input)
    local minX = SliderFrame.AbsolutePosition.X
    local maxX = minX + SliderFrame.AbsoluteSize.X
    local inputX = math.clamp(input.Position.X, minX, maxX)
    local percentage = (inputX - minX) / SliderFrame.AbsoluteSize.X
    
    Aimbot_FOV = math.floor(10 + (percentage * 490))
    
    SliderLabel.Text = "FOV Радиус: " .. tostring(Aimbot_FOV)
    SliderButton.Position = UDim2.new(percentage, -8, 0.5, -8)
    SliderFill.Size = UDim2.new(percentage, 0, 1, 0)
end

SliderButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        updateSlider(input)
    end
end)

-- Кнопка закрытия
local CloseButton = Instance.new("TextButton")
CloseButton.Size = UDim2.new(0, 30, 0, 30)
CloseButton.Position = UDim2.new(1, -35, 0, 2)
CloseButton.BackgroundTransparency = 1
CloseButton.Text = "X"
CloseButton.TextColor3 = Color3.fromRGB(255, 100, 100)
CloseButton.Font = Enum.Font.GothamBold
CloseButton.TextSize = 18
CloseButton.Parent = MainFrame

-- Иконка открытия
local OpenButton = Instance.new("TextButton")
OpenButton.Name = "OpenButton"
OpenButton.Size = UDim2.new(0, 50, 0, 50)
OpenButton.Position = UDim2.new(0, 10, 0.3, 0)
OpenButton.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
OpenButton.Text = "MENU"
OpenButton.TextColor3 = Color3.fromRGB(255, 255, 255)
OpenButton.Font = Enum.Font.GothamBold
OpenButton.TextSize = 12
OpenButton.Visible = false
OpenButton.Active = true
OpenButton.Draggable = true
OpenButton.Parent = ScreenGui

local OpenCorner = Instance.new("UICorner")
OpenCorner.CornerRadius = UDim.new(1, 0)
OpenCorner.Parent = OpenButton

CloseButton.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
    OpenButton.Visible = true
end)

-- Умная кнопка открытия (защита от ложного клика при движении)
local dragStartPos = nil
OpenButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragStartPos = OpenButton.Position
    end
end)

OpenButton.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        if dragStartPos then
            local startX = dragStartPos.X.Offset
            local startY = dragStartPos.Y.Offset
            local currentX = OpenButton.Position.X.Offset
            local currentY = OpenButton.Position.Y.Offset
            local distanceMoved = math.sqrt((currentX - startX)^2 + (currentY - startY)^2)
            
            if distanceMoved < 5 then
                MainFrame.Visible = true
                OpenButton.Visible = false
            end
        end
    end
end)
