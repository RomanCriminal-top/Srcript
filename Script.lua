-- ЧАСТЬ 1: ОСНОВНАЯ ЛОГИКА И НАСТРОЙКИ
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Настройки функций
local ESP_Enabled = false
local Aimbot_Enabled = false
local Fly_Enabled = false
local Crosshair_Enabled = false
local Aimbot_FOV = 150 
local Crosshair_Size = 10 
local Aimbot_Smooth = 0.2 -- Плавность перевода (от 0.05 до 1.0)
local Team_Check = true    -- Проверка на команду (не целиться в своих)

-- Настройки тумблеров VISUAL 
local Vis_Boxes = true
local Vis_Lines = true
local Vis_FOV = true
local Vis_Names = true
local Vis_Dist = true

-- Смена Цветов (1 = Белый, 2 = Зеленый, 3 = Фиолетовый, 4 = Радуга)
local CurrentColorIndex = 1
local ColorModes = {"DEFAULT", "GREEN", "PURPLE", "RAINBOW"}
local CurrentStaticColor = Color3.fromRGB(255, 255, 255) 

-- Хранилище для графики ESP
local ESP_Cache = {}

-- Круг FOV строго по центру
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 1.5
FOVCircle.NumSides = 60
FOVCircle.Radius = Aimbot_FOV
FOVCircle.Filled = false
FOVCircle.Visible = false

-- Кроссхеир (Перекрестие)
local Crosshair_Horizontal = Drawing.new("Line")
Crosshair_Horizontal.Thickness = 2
Crosshair_Horizontal.Visible = false

local Crosshair_Vertical = Drawing.new("Line")
Crosshair_Vertical.Thickness = 2
Crosshair_Vertical.Visible = false

-- Оптимизированный ESP с текстом
local function CreateESP(player)
    if player == LocalPlayer then return end

    local Box = Drawing.new("Square")
    Box.Visible = false
    Box.Thickness = 1.5
    Box.Filled = false

    local Line = Drawing.new("Line")
    Line.Visible = false
    Line.Thickness = 1

    local Text = Drawing.new("Text")
    Text.Visible = false
    Text.Size = 14
    Text.Center = true
    Text.Outline = true
    Text.Color = Color3.fromRGB(255, 255, 255)

    ESP_Cache[player] = {Box = Box, Line = Line, Text = Text}
end

local function RemoveESP(player)
    if ESP_Cache[player] then
        ESP_Cache[player].Box:Remove()
        ESP_Cache[player].Line:Remove()
        ESP_Cache[player].Text:Remove()
        ESP_Cache[player] = nil
    end
end

for _, p in pairs(Players:GetPlayers()) do CreateESP(p) end
Players.PlayerAdded:Connect(CreateESP)
Players.PlayerRemoving:Connect(RemoveESP)

-- Универсальный и умный поиск цели
local function GetClosestPlayerToCenter()
    local closestPlayer = nil
    local shortestDistance = Aimbot_FOV
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Head") and player.Character:FindFirstChildOfClass("Humanoid") and player.Character.Humanoid.Health > 0 then
            
            -- Проверка на команду (Team Check)
            if Team_Check and player.Team == LocalPlayer.Team then continue end
            
            local pos, onScreen = Camera:WorldToViewportPoint(player.Character.Head.Position)
            if onScreen then
                local distance = (Vector2.new(pos.X, pos.Y) - screenCenter).Magnitude
                if distance < shortestDistance then
                    closestPlayer = player
                    shortestDistance = distance
                end
            end
        end
    end
    return closestPlayer
end

-- Высокопроизводительный цикл обновлений
RunService.Heartbeat:Connect(function()
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    
    -- Безопасный Inf Jump без бесконечной рекурсии
    if Fly_Enabled and UserInputService:IsKeyDown(Enum.KeyCode.Space) then
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.Velocity = Vector3.new(hrp.Velocity.X, 45, hrp.Velocity.Z)
        end
    end

    -- Вычисление динамического цвета (для Радуги)
    local DynamicColor = CurrentStaticColor
    if ColorModes[CurrentColorIndex] == "RAINBOW" then
        DynamicColor = Color3.fromHSV(tick() % 5 / 5, 1, 1)
    end

    _G.CurrentRainbowColor = DynamicColor

    -- Визуализация FOV круга
    if Aimbot_Enabled and Vis_FOV then
        FOVCircle.Radius = Aimbot_FOV
        FOVCircle.Position = screenCenter
        FOVCircle.Color = DynamicColor
        FOVCircle.Visible = true
    else
        FOVCircle.Visible = false
    end

    -- Визуализация Кроссхеира
    if Crosshair_Enabled then
        local lSize = Crosshair_Size
        local gap = 3
        
        Crosshair_Horizontal.From = Vector2.new(screenCenter.X - lSize - gap, screenCenter.Y)
        Crosshair_Horizontal.To = Vector2.new(screenCenter.X + lSize + gap, screenCenter.Y)
        Crosshair_Vertical.From = Vector2.new(screenCenter.X, screenCenter.Y - lSize - gap)
        Crosshair_Vertical.To = Vector2.new(screenCenter.X, screenCenter.Y + lSize + gap)
        
        Crosshair_Horizontal.Color = DynamicColor
        Crosshair_Vertical.Color = DynamicColor
        Crosshair_Horizontal.Visible = true
        Crosshair_Vertical.Visible = true
    else
        Crosshair_Horizontal.Visible = false
        Crosshair_Vertical.Visible = false
    end

    -- Обновление ESP
    for player, objs in pairs(ESP_Cache) do
        if ESP_Enabled and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChildOfClass("Humanoid") and player.Character.Humanoid.Health > 0 then
            
            -- Скрываем, если включен Team Check и это тиммейт
            if Team_Check and player.Team == LocalPlayer.Team then
                objs.Box.Visible = false
                objs.Line.Visible = false
                objs.Text.Visible = false
                continue
            end

            local hrp = player.Character.HumanoidRootPart
            local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)

            if onScreen then
                local distance = math.floor((Camera.CFrame.Position - hrp.Position).Magnitude)
                local sizeX = 2300 / distance 
                local sizeY = 3300 / distance

                objs.Box.Color = DynamicColor
                objs.Line.Color = DynamicColor
                
                -- Скейлинг шрифта, чтобы текст не мылил экран издалека
                objs.Text.Size = math.clamp(1800 / distance, 11, 15)

                -- Условный показ Боксов
                if Vis_Boxes then
                    objs.Box.Size = Vector2.new(sizeX, sizeY)
                    objs.Box.Position = Vector2.new(pos.X - sizeX / 2, pos.Y - sizeY / 2)
                    objs.Box.Visible = true
                else
                    objs.Box.Visible = false
                end

                -- Условный показ Линий
                if Vis_Lines then
                    objs.Line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                    objs.Line.To = Vector2.new(pos.X, pos.Y + (sizeY / 2))
                    objs.Line.Visible = true
                else
                    objs.Line.Visible = false
                end

                -- Условный конструкт текста
                if Vis_Names or Vis_Dist then
                    local textString = ""
                    if Vis_Names then textString = textString .. player.Name end
                    if Vis_Dist then 
                        if Vis_Names then textString = textString .. " " end
                        textString = textString .. "[" .. tostring(distance) .. "m]"
                    end
                    objs.Text.Text = textString
                    objs.Text.Position = Vector2.new(pos.X, pos.Y - (sizeY / 2) - 18)
                    objs.Text.Visible = true
                else
                    objs.Text.Visible = false
                end
            else
                objs.Box.Visible = false
                objs.Line.Visible = false
                objs.Text.Visible = false
            end
        else
            objs.Box.Visible = false
            objs.Line.Visible = false
            objs.Text.Visible = false
        end
    end

    -- Логика универсального Аимбота (Работает везде и плавно)
    if Aimbot_Enabled then
        local target = GetClosestPlayerToCenter()
        if target and target.Character and target.Character:FindFirstChild("Head") then
            local targetHead = target.Character.Head
            -- Чистый математический перевод камеры без привязки к мыши
            Camera.CFrame = Camera.CFrame:Lerp(CFrame.lookAt(Camera.CFrame.Position, targetHead.Position), Aimbot_Smooth)
        end
    end
end)
-- ЧАСТЬ 2: ИНТЕРФЕЙС GUI С ВКЛАДКАМИ
if CoreGui:FindFirstChild("DeltaESP_Gui") then
    CoreGui.DeltaESP_Gui:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "DeltaESP_Gui"
ScreenGui.Parent = CoreGui
ScreenGui.ResetOnSpawn = false

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 240, 0, 360) -- Увеличенный размер под новый ползунок
MainFrame.Position = UDim2.new(0.5, -120, 0.4, -180)
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

--- КНОПКИ ДЛЯ ПЕРЕКЛЮЧЕНИЯ ВКЛАДОК ---
local MainTabButton = Instance.new("TextButton")
MainTabButton.Size = UDim2.new(0, 95, 0, 25)
MainTabButton.Position = UDim2.new(0, 20, 0, 42)
MainTabButton.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
MainTabButton.Text = "MAIN"
MainTabButton.TextColor3 = Color3.fromRGB(255, 255, 255)
MainTabButton.Font = Enum.Font.GothamBold
MainTabButton.TextSize = 11
MainTabButton.Parent = MainFrame

local MTabCorner = Instance.new("UICorner")
MTabCorner.CornerRadius = UDim.new(0, 6)
MTabCorner.Parent = MainTabButton

local VisualTabButton = Instance.new("TextButton")
VisualTabButton.Size = UDim2.new(0, 95, 0, 25)
VisualTabButton.Position = UDim2.new(0, 125, 0, 42)
VisualTabButton.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
VisualTabButton.Text = "VISUAL"
VisualTabButton.TextColor3 = Color3.fromRGB(150, 150, 150)
VisualTabButton.Font = Enum.Font.GothamBold
VisualTabButton.TextSize = 11
VisualTabButton.Parent = MainFrame

local VTabCorner = Instance.new("UICorner")
VTabCorner.CornerRadius = UDim.new(0, 6)
VTabCorner.Parent = VisualTabButton

-- Контейнеры контента для вкладок (Скроллинг)
local MainContentFrame = Instance.new("ScrollingFrame")
MainContentFrame.Size = UDim2.new(1, 0, 1, -75)
MainContentFrame.Position = UDim2.new(0, 0, 0, 75)
MainContentFrame.BackgroundTransparency = 1
MainContentFrame.CanvasSize = UDim2.new(0, 0, 0, 330)
MainContentFrame.ScrollBarThickness = 2
MainContentFrame.Parent = MainFrame

local VisualContentFrame = Instance.new("ScrollingFrame")
VisualContentFrame.Size = UDim2.new(1, 0, 1, -75)
VisualContentFrame.Position = UDim2.new(0, 0, 0, 75)
VisualContentFrame.BackgroundTransparency = 1
VisualContentFrame.CanvasSize = UDim2.new(0, 0, 0, 200)
VisualContentFrame.ScrollBarThickness = 2
VisualContentFrame.Visible = false
VisualContentFrame.Parent = MainFrame

-- Логика вкладок
MainTabButton.MouseButton1Click:Connect(function()
    MainContentFrame.Visible = true
    VisualContentFrame.Visible = false
    MainTabButton.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    MainTabButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    VisualTabButton.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    VisualTabButton.TextColor3 = Color3.fromRGB(150, 150, 150)
end)

VisualTabButton.MouseButton1Click:Connect(function()
    MainContentFrame.Visible = false
    VisualContentFrame.Visible = true
    VisualTabButton.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    VisualTabButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    MainTabButton.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    MainTabButton.TextColor3 = Color3.fromRGB(150, 150, 150)
end)

-- Универсальный конструктор тумблеров (Toggles)
local function CreateToggle(parent, text, yPos, startState, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 95, 0, 35)
    btn.BackgroundColor3 = startState and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(200, 50, 50)
    btn.Text = text .. (startState and ": ON" or ": OFF")
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    btn.Parent = parent
    
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 8)
    c.Parent = btn

    btn.MouseButton1Click:Connect(function()
        startState = not startState
        btn.Text = text .. (startState and ": ON" or ": OFF")
        btn.BackgroundColor3 = startState and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(200, 50, 50)
        callback(startState)
    end)
    return btn
end

-- Универсальный конструктор слайдеров без залипаний (Вне кнопок)
local function CreateSlider(parent, text, min, max, startVal, yPos, callback)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0, 200, 0, 15)
    label.Position = UDim2.new(0.5, -100, 0, yPos)
    label.BackgroundTransparency = 1
    label.Text = text .. ": " .. tostring(startVal)
    label.TextColor3 = Color3.fromRGB(200, 200, 200)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 11
    label.Parent = parent

    local sFrame = Instance.new("Frame")
    sFrame.Size = UDim2.new(0, 200, 0, 6)
    sFrame.Position = UDim2.new(0.5, -100, 0, yPos + 18)
    sFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
    sFrame.Parent = parent

    local sFill = Instance.new("Frame")
    sFill.Size = UDim2.new((startVal - min) / (max - min), 0, 1, 0)
    sFill.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
    sFill.Parent = sFrame

    local sBtn = Instance.new("TextButton")
    sBtn.Size = UDim2.new(0, 12, 0, 12)
    sBtn.Position = UDim2.new((startVal - min) / (max - min), -6, 0.5, -6)
    sBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    sBtn.Text = ""
    sBtn.Parent = sFrame

    local dragging = false

    local function update(input)
        local pos = math.clamp((input.Position.X - sFrame.AbsolutePosition.X) / sFrame.AbsoluteSize.X, 0, 1)
        local val = min + (pos * (max - min))
        if max <= 1 then
            val = math.round(val * 100) / 100 -- Скругление для Smooth
        else
            val = math.floor(val)
        end
        sFill.Size = UDim2.new(pos, 0, 1, 0)
        sBtn.Position = UDim2.new(pos, -6, 0.5, -6)
        label.Text = text .. ": " .. tostring(val)
        callback(val)
    end

    sBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            update(input)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

--- ========================================== ---
---              ВКЛАДКА 1: MAIN               ---
--- ========================================== ---

local t1 = CreateToggle(MainContentFrame, "ESP", 5, ESP_Enabled, function(v) ESP_Enabled = v end)
t1.Position = UDim2.new(0, 20, 0, 5)

local t2 = CreateToggle(MainContentFrame, "INF JUMP", 5, Fly_Enabled, function(v) Fly_Enabled = v end)
t2.Position = UDim2.new(0, 125, 0, 5)

local t3 = CreateToggle(MainContentFrame, "AIM", 45, Aimbot_Enabled, function(v) Aimbot_Enabled = v end)
t3.Position = UDim2.new(0, 20, 0, 45)

local t4 = CreateToggle(MainContentFrame, "CROSS", 45, Crosshair_Enabled, function(v) Crosshair_Enabled = v end)
t4.Position = UDim2.new(0, 125, 0, 45)

local t5 = CreateToggle(MainContentFrame, "TEAM CHECK", 85, Team_Check, function(v) Team_Check = v end)
t5.Position = UDim2.new(0, 20, 0, 85)
t5.Size = UDim2.new(0, 200, 0, 30)

-- Кастомная кнопка выбора цвета
local ColorButton = Instance.new("TextButton")
ColorButton.Size = UDim2.new(0, 200, 0, 32)
ColorButton.Position = UDim2.new(0.5, -100, 0, 125)
ColorButton.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
ColorButton.Text = "COLOR: DEFAULT"
ColorButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ColorButton.Font = Enum.Font.GothamBold
ColorButton.TextSize = 12
ColorButton.Parent = MainContentFrame

local ColorCorner = Instance.new("UICorner")
ColorCorner.CornerRadius = UDim.new(0, 8)
ColorCorner.Parent = ColorButton

ColorButton.MouseButton1Click:Connect(function()
    CurrentColorIndex = CurrentColorIndex + 1
    if CurrentColorIndex > #ColorModes then CurrentColorIndex = 1 end
    local mode = ColorModes[CurrentColorIndex]
    ColorButton.Text = "COLOR: " .. mode
    if mode == "DEFAULT" then CurrentStaticColor = Color3.fromRGB(255, 255, 255) ColorButton.TextColor3 = CurrentStaticColor
    elseif mode == "GREEN" then CurrentStaticColor = Color3.fromRGB(50, 250, 50) ColorButton.TextColor3 = CurrentStaticColor
    elseif mode == "PURPLE" then CurrentStaticColor = Color3.fromRGB(180, 50, 255) ColorButton.TextColor3 = CurrentStaticColor end
end)

RunService.Heartbeat:Connect(function()
    if ColorModes[CurrentColorIndex] == "RAINBOW" and _G.CurrentRainbowColor then
        ColorButton.TextColor3 = _G.CurrentRainbowColor
    end
end)

-- Слайдеры вкладки MAIN
CreateSlider(MainContentFrame, "FOV Радиус", 10, 500, Aimbot_FOV, 170, function(v) Aimbot_FOV = v end)
CreateSlider(MainContentFrame, "Размер прицела", 3, 50, Crosshair_Size, 215, function(v) Crosshair_Size = v end)
CreateSlider(MainContentFrame, "Smooth (Плавность)", 0.05, 1, Aimbot_Smooth, 260, function(v) Aimbot_Smooth = v end)

--- ========================================== ---
---              ВКЛАДКА 2: VISUAL             ---
--- ========================================== ---

local vt1 = CreateToggle(VisualContentFrame, "Boxes", 5, Vis_Boxes, function(v) Vis_Boxes = v end)
vt1.Position = UDim2.new(0, 20, 0, 5)

local vt2 = CreateToggle(VisualContentFrame, "Lines", 5, Vis_Lines, function(v) Vis_Lines = v end)
vt2.Position = UDim2.new(0, 125, 0, 5)

local vt3 = CreateToggle(VisualContentFrame, "Names", 45, Vis_Names, function(v) Vis_Names = v end)
vt3.Position = UDim2.new(0, 20, 0, 45)

local vt4 = CreateToggle(VisualContentFrame, "Distances", 45, Vis_Dist, function(v) Vis_Dist = v end)
vt4.Position = UDim2.new(0, 125, 0, 45)

local vt5 = CreateToggle(VisualContentFrame, "FOV Circle", 85, Vis_FOV, function(v) Vis_FOV = v end)
vt5.Position = UDim2.new(0, 20, 0, 85)
vt5.Size = UDim2.new(0, 200, 0, 35)
