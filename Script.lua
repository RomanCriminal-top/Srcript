-- ============================================
-- ЧАСТЬ 1: ЯДРО, НАСТРОЙКИ, ESP И СЕРВИСЫ
-- ============================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")

-- === НАСТРОЙКИ ===
local ESP_Enabled = false
local Aimbot_Enabled = false
local Crosshair_Enabled = false
local Fly_Enabled = false
local Fly_Speed = 50
local Speed_Enabled = false
local WalkSpeed_Value = 16
local DefaultWalkSpeed = 16
local Jump_Enabled = false
local JumpPower_Value = 50
local DefaultJumpPower = 50
local Noclip_Enabled = false
local Aimbot_Smoothness = 0.4
local Aimbot_FOV = 150
local Crosshair_Size = 10
local Vis_Boxes = true
local Vis_Lines = true
local Vis_FOV = true
local Vis_Names = true
local Vis_Dist = true
local Aimbot_Part = "Head"
local CurrentColorIndex = 1
local ColorModes = {"DEFAULT", "GREEN", "PURPLE", "RAINBOW"}
local CurrentStaticColor = Color3.fromRGB(255, 255, 255)
local ESP_Cache = {}
local Aimbot_Target = nil

-- === СОХРАНЕНИЕ СТАНДАРТНЫХ ЗНАЧЕНИЙ ===
LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        DefaultWalkSpeed = hum.WalkSpeed
        DefaultJumpPower = hum.JumpPower
        if Noclip_Enabled then
            for _, part in pairs(char:GetChildren()) do
                if part:IsA("BasePart") then part.CanCollide = false end
            end
        end
    end
end)

if LocalPlayer.Character then
    local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if hum then DefaultWalkSpeed = hum.WalkSpeed; DefaultJumpPower = hum.JumpPower end
end

-- === РИСОВАНИЕ ESP ===
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 1.5; FOVCircle.NumSides = 60; FOVCircle.Radius = Aimbot_FOV; FOVCircle.Filled = false; FOVCircle.Visible = false
local Crosshair_Horizontal = Drawing.new("Line")
Crosshair_Horizontal.Thickness = 2; Crosshair_Horizontal.Visible = false
local Crosshair_Vertical = Drawing.new("Line")
Crosshair_Vertical.Thickness = 2; Crosshair_Vertical.Visible = false

local function CreateESP(player)
    if player == LocalPlayer then return end
    ESP_Cache[player] = {
        Box = Drawing.new("Square"),
        Line = Drawing.new("Line"),
        Text = Drawing.new("Text")
    }
    local e = ESP_Cache[player]
    e.Box.Visible = false; e.Box.Thickness = 1.5; e.Box.Filled = false
    e.Line.Visible = false; e.Line.Thickness = 1
    e.Text.Visible = false; e.Text.Size = 14; e.Text.Center = true; e.Text.Outline = true; e.Text.Color = Color3.fromRGB(255,255,255)
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

-- === ВЫБОР ЦЕЛИ С ПРОВЕРКОЙ ВИДИМОСТИ ===
local function IsVisible(targetPart)
    local origin = Camera.CFrame.Position
    local direction = (targetPart.Position - origin).Unit * 1000
    local ray = Ray.new(origin, direction)
    local hit = workspace:FindPartOnRayWithIgnoreList(ray, {LocalPlayer.Character, targetPart.Parent})
    return hit == targetPart
end

local function GetClosestPlayerToCenter()
    local closest = nil
    local shortest = Aimbot_FOV
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local targetPart = player.Character:FindFirstChild(Aimbot_Part)
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            if targetPart and humanoid and humanoid.Health > 0 and IsVisible(targetPart) then
                local pos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                if onScreen then
                    local dist = (Vector2.new(pos.X, pos.Y) - screenCenter).Magnitude
                    if dist < shortest then
                        closest = player; shortest = dist
                    end
                end
            end
        end
    end
    return closest
end-- ============================================
-- ЧАСТЬ 2: ПОЛЁТ И ГЛАВНЫЙ ЦИКЛ HEARTBEAT
-- ============================================
-- === ПОЛЁТ ===
local function UpdateFly(dt)
    if not Fly_Enabled or not LocalPlayer.Character then return end
    local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if not root or not hum then return end
    hum.PlatformStand = true
    local move = Vector3.new(
        (UserInputService:IsKeyDown(Enum.KeyCode.D) and 1 or 0) - (UserInputService:IsKeyDown(Enum.KeyCode.A) and 1 or 0),
        (UserInputService:IsKeyDown(Enum.KeyCode.Space) and 1 or 0) - (UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) and 1 or 0),
        (UserInputService:IsKeyDown(Enum.KeyCode.S) and 1 or 0) - (UserInputService:IsKeyDown(Enum.KeyCode.W) and 1 or 0)
    )
    if move.Magnitude > 0 then move = move.Unit end
    local velocity = (Camera.CFrame:VectorToWorldSpace(move) * Fly_Speed) + Vector3.new(0, move.Y * Fly_Speed, 0)
    root.Velocity = velocity
end

-- === ГЛАВНЫЙ ЦИКЛ ===
RunService.Heartbeat:Connect(function(dt)
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local DynamicColor = CurrentStaticColor
    if ColorModes[CurrentColorIndex] == "RAINBOW" then
        DynamicColor = Color3.fromHSV(tick() % 5 / 5, 1, 1)
    end
    _G.CurrentRainbowColor = DynamicColor

    -- PLAYER НАСТРОЙКИ
    if LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.WalkSpeed = Speed_Enabled and WalkSpeed_Value or DefaultWalkSpeed
            if Jump_Enabled then
                hum.JumpPower = JumpPower_Value
                hum.UseJumpPower = true
            else
                hum.JumpPower = DefaultJumpPower
                hum.UseJumpPower = false
            end
        end
        if Noclip_Enabled then
            for _, part in pairs(LocalPlayer.Character:GetChildren()) do
                if part:IsA("BasePart") then part.CanCollide = false end
            end
        end
    end

    -- ПОЛЁТ
    if Fly_Enabled then UpdateFly(dt) end

    -- FOV КРУГ
    if Aimbot_Enabled and Vis_FOV then
        FOVCircle.Radius = Aimbot_FOV
        FOVCircle.Position = screenCenter
        FOVCircle.Color = DynamicColor
        FOVCircle.Visible = true
    else FOVCircle.Visible = false end

    -- ПРИЦЕЛ
    if Crosshair_Enabled then
        local lSize = Crosshair_Size; local gap = 3
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

    -- ESP
    for player, objs in pairs(ESP_Cache) do
        local shouldShow = ESP_Enabled and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChildOfClass("Humanoid") and player.Character.Humanoid.Health > 0
        if shouldShow then
            local hrp = player.Character.HumanoidRootPart
            local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
            if onScreen then
                local distance = math.floor((Camera.CFrame.Position - hrp.Position).Magnitude)
                local sizeX = 2300 / distance; local sizeY = 3300 / distance
                objs.Box.Color = DynamicColor
                objs.Line.Color = DynamicColor
                objs.Text.Color = DynamicColor

                if Vis_Boxes then
                    objs.Box.Size = Vector2.new(sizeX, sizeY)
                    objs.Box.Position = Vector2.new(pos.X - sizeX/2, pos.Y - sizeY/2)
                    objs.Box.Visible = true
                else objs.Box.Visible = false end

                if Vis_Lines then
                    objs.Line.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
                    objs.Line.To = Vector2.new(pos.X, pos.Y + sizeY/2)
                    objs.Line.Visible = true
                else objs.Line.Visible = false end

                if Vis_Names or Vis_Dist then
                    local text = (Vis_Names and player.Name or "") .. (Vis_Dist and (Vis_Names and " " or "") .. "["..distance.."m]" or "")
                    objs.Text.Text = text
                    objs.Text.Position = Vector2.new(pos.X, pos.Y - sizeY/2 - 18)
                    objs.Text.Visible = true
                else objs.Text.Visible = false end
            else objs.Box.Visible = false; objs.Line.Visible = false; objs.Text.Visible = false end
        else objs.Box.Visible = false; objs.Line.Visible = false; objs.Text.Visible = false end
    end

    -- АИМБОТ С БЛОКИРОВКОЙ
    if Aimbot_Enabled then
        if not Aimbot_Target or not Aimbot_Target.Character or not Aimbot_Target.Character:FindFirstChild(Aimbot_Part) then
            Aimbot_Target = GetClosestPlayerToCenter()
        else
            local targetPart = Aimbot_Target.Character:FindFirstChild(Aimbot_Part)
            if not targetPart or not IsVisible(targetPart) then
                Aimbot_Target = GetClosestPlayerToCenter()
            end
        end

        if Aimbot_Target and Aimbot_Target.Character then
            local targetPart = Aimbot_Target.Character:FindFirstChild(Aimbot_Part)
            if targetPart then
                local currentCF = Camera.CFrame
                local lookAt = CFrame.lookAt(currentCF.Position, targetPart.Position)
                local angle = math.acos(math.clamp(currentCF.LookVector:Dot(lookAt.LookVector), -1, 1))
                if angle > 0.01 then
                    local speed = math.min(Aimbot_Smoothness * (1 + 5 / (Camera.CFrame.Position - targetPart.Position).Magnitude), 0.9)
                    Camera.CFrame = currentCF:Lerp(lookAt, math.min(speed / angle, 0.9))
                end
            end
        end
    end
end)-- ============================================
-- ЧАСТЬ 3: GUI, МЕНЮ, КНОПКИ И ВЗАИМОДЕЙСТВИЕ
-- ============================================
if CoreGui:FindFirstChild("DeltaESP_Gui") then CoreGui.DeltaESP_Gui:Destroy() end
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "DeltaESP_Gui"; ScreenGui.Parent = CoreGui; ScreenGui.ResetOnSpawn = false

_G.RomanMainFrame = Instance.new("Frame")
local MainFrame = _G.RomanMainFrame
MainFrame.Name = "MainFrame"; MainFrame.Size = UDim2.new(0, 230, 0, 380)
MainFrame.Position = UDim2.new(0.5, -115, 0.4, -190)
MainFrame.BackgroundColor3 = Color3.fromRGB(30,30,35); MainFrame.BorderSizePixel = 0
MainFrame.Active = true; MainFrame.Draggable = true; MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0,10)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1,0,0,35); Title.BackgroundColor3 = Color3.fromRGB(45,45,50)
Title.Text = "@RomanCriminal 10/10"; Title.TextColor3 = Color3.fromRGB(255,255,255)
Title.Font = Enum.Font.GothamBold; Title.TextSize = 13; Title.Parent = MainFrame
Instance.new("UICorner", Title).CornerRadius = UDim.new(0,10)

-- ВКЛАДКИ
local function MakeTab(name, x, w)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, w, 0, 25); btn.Position = UDim2.new(0, x, 0, 42)
    btn.BackgroundColor3 = Color3.fromRGB(40,40,45); btn.Text = name
    btn.TextColor3 = Color3.fromRGB(150,150,150); btn.Font = Enum.Font.GothamBold; btn.TextSize = 10
    btn.Parent = MainFrame; Instance.new("UICorner", btn).CornerRadius = UDim.new(0,5)
    return btn
end
local MainTab = MakeTab("MAIN", 10, 62)
local VisualTab = MakeTab("VISUAL", 77, 62)
local PlayerTab = MakeTab("PLAYER", 144, 70)

_G.MainContentFrame = Instance.new("Frame"); _G.VisualContentFrame = Instance.new("Frame"); _G.PlayerContentFrame = Instance.new("Frame")
for _, f in pairs({_G.MainContentFrame, _G.VisualContentFrame, _G.PlayerContentFrame}) do
    f.Size = UDim2.new(1,0,1,-75); f.Position = UDim2.new(0,0,0,75); f.BackgroundTransparency = 1; f.Parent = MainFrame
end
_G.VisualContentFrame.Visible = false; _G.PlayerContentFrame.Visible = false

local function switchTab(activeBtn, activeFrame)
    for _, f in pairs({_G.MainContentFrame, _G.VisualContentFrame, _G.PlayerContentFrame}) do f.Visible = false end
    for _, btn in pairs({MainTab, VisualTab, PlayerTab}) do btn.BackgroundColor3 = Color3.fromRGB(40,40,45); btn.TextColor3 = Color3.fromRGB(150,150,150) end
    activeFrame.Visible = true; activeBtn.BackgroundColor3 = Color3.fromRGB(50,50,60); activeBtn.TextColor3 = Color3.fromRGB(255,255,255)
end
MainTab.MouseButton1Click:Connect(function() switchTab(MainTab, _G.MainContentFrame) end)
VisualTab.MouseButton1Click:Connect(function() switchTab(VisualTab, _G.VisualContentFrame) end)
PlayerTab.MouseButton1Click:Connect(function() switchTab(PlayerTab, _G.PlayerContentFrame) end)

-- ФУНКЦИЯ СОЗДАНИЯ КНОПОК
local function CreateButton(parent, text, y, w, h, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, w or 190, 0, h or 35); btn.Position = UDim2.new(0.5, -(w or 190)/2, 0, y)
    btn.BackgroundColor3 = Color3.fromRGB(200,50,50); btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255,255,255); btn.Font = Enum.Font.GothamBold; btn.TextSize = (h or 35) > 30 and 12 or 10
    btn.Parent = parent; Instance.new("UICorner", btn).CornerRadius = UDim.new(0,8)
    btn.MouseButton1Click:Connect(callback)
    return btn
end

-- === MAIN ВКЛАДКА ===
local masterBtn = CreateButton(_G.MainContentFrame, "MASTER ESP: OFF", 10, 190, 38, function()
    ESP_Enabled = not ESP_Enabled; masterBtn.Text = ESP_Enabled and "MASTER ESP: ON" or "MASTER ESP: OFF"
    masterBtn.BackgroundColor3 = ESP_Enabled and Color3.fromRGB(50,200,50) or Color3.fromRGB(200,50,50)
end)

local aimBtn = CreateButton(_G.MainContentFrame, "AIM: OFF", 55, 90, 35, function()
    Aimbot_Enabled = not Aimbot_Enabled; aimBtn.Text = Aimbot_Enabled and "AIM: ON" or "AIM: OFF"
    aimBtn.BackgroundColor3 = Aimbot_Enabled and Color3.fromRGB(50,200,50) or Color3.fromRGB(200,50,50)
end)

local crossBtn = Instance.new("TextButton")
crossBtn.Size = UDim2.new(0, 90, 0, 35); crossBtn.Position = UDim2.new(0, 120, 0, 55)
crossBtn.BackgroundColor3 = Color3.fromRGB(200,50,50); crossBtn.Text = "CROSS: OFF"
crossBtn.TextColor3 = Color3.fromRGB(255,255,255); crossBtn.Font = Enum.Font.GothamBold; crossBtn.TextSize = 11
crossBtn.Parent = _G.MainContentFrame; Instance.new("UICorner", crossBtn).CornerRadius = UDim.new(0,8)
crossBtn.MouseButton1Click:Connect(function()
    Crosshair_Enabled = not Crosshair_Enabled; crossBtn.Text = Crosshair_Enabled and "CROSS: ON" or "CROSS: OFF"
    crossBtn.BackgroundColor3 = Crosshair_Enabled and Color3.fromRGB(50,200,50) or Color3.fromRGB(200,50,50)
end)

local colorBtn = CreateButton(_G.MainContentFrame, "COLOR: DEFAULT", 100, 190, 35, function()
    CurrentColorIndex = CurrentColorIndex % #ColorModes + 1
    local mode = ColorModes[CurrentColorIndex]
    colorBtn.Text = "COLOR: " .. mode
    if mode == "DEFAULT" then CurrentStaticColor = Color3.fromRGB(255,255,255)
    elseif mode == "GREEN" then CurrentStaticColor = Color3.fromRGB(50,250,50)
    elseif mode == "PURPLE" then CurrentStaticColor = Color3.fromRGB(180,50,255) end
    colorBtn.TextColor3 = CurrentStaticColor
end)

local allOnBtn = CreateButton(_G.MainContentFrame, "🔥 ВСЕ ВКЛ", 145, 190, 30, function()
    ESP_Enabled = true; masterBtn.Text = "MASTER ESP: ON"; masterBtn.BackgroundColor3 = Color3.fromRGB(50,200,50)
    Vis_Boxes = true; Vis_Lines = true; Vis_FOV = true; Vis_Names = true; Vis_Dist = true
    for _, btn in pairs(VisualScroll:GetChildren()) do
        if btn:IsA("TextButton") and btn.Text:find("HIDDEN") then btn.MouseButton1Click:Fire() end
    end
end)

local resetBtn = CreateButton(_G.MainContentFrame, "🔄 СБРОС", 180, 190, 30, function()
    ESP_Enabled = false; Aimbot_Enabled = false; Crosshair_Enabled = false; Fly_Enabled = false; Speed_Enabled = false; Jump_Enabled = false; Noclip_Enabled = false
    WalkSpeed_Value = 16; JumpPower_Value = 50; Aimbot_FOV = 150; Aimbot_Smoothness = 0.4; Crosshair_Size = 10
    masterBtn.Text = "MASTER ESP: OFF"; masterBtn.BackgroundColor3 = Color3.fromRGB(200,50,50)
    aimBtn.Text = "AIM: OFF"; aimBtn.BackgroundColor3 = Color3.fromRGB(200,50,50)
    crossBtn.Text = "CROSS: OFF"; crossBtn.BackgroundColor3 = Color3.fromRGB(200,50,50)
    CurrentColorIndex = 1; CurrentStaticColor = Color3.fromRGB(255,255,255); colorBtn.Text = "COLOR: DEFAULT"; colorBtn.TextColor3 = CurrentStaticColor
    Vis_Boxes = true; Vis_Lines = true; Vis_FOV = true; Vis_Names = true; Vis_Dist = true
end)

local serverBtn = CreateButton(_G.MainContentFrame, "🌐 НАЙТИ СЕРВЕР", 220, 190, 35, function()
    pcall(function()
        local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
        local data = HttpService:JSONDecode(game:HttpGet(url))
        local best = nil; local min = math.huge
        for _, s in pairs(data.data) do
            if s.playing < s.maxPlayers and s.playing < min and s.id ~= game.JobId then
                min = s.playing; best = s.id
            end
        end
        if best then
            game.StarterGui:SetCore("SendNotification", {Title = "✅ Найден!", Text = "Игроков: "..min, Duration = 3})
            task.wait(1); TeleportService:TeleportToPlaceInstance(game.PlaceId, best, LocalPlayer)
        else
            game.StarterGui:SetCore("SendNotification", {Title = "❌ Не найден", Text = "Попробуйте позже", Duration = 3})
        end
    end)
end)

-- === VISUAL ВКЛАДКА ===
local VisualScroll = Instance.new("ScrollingFrame")
VisualScroll.Size = UDim2.new(1,0,1,0); VisualScroll.BackgroundTransparency = 1
VisualScroll.CanvasSize = UDim2.new(0,0,0,420); VisualScroll.ScrollBarThickness = 3
VisualScroll.Parent = _G.VisualContentFrame

local function CreateVisToggle(textOn, textOff, y, state, cb)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 190, 0, 28); btn.Position = UDim2.new(0.5, -95, 0, y)
    btn.BackgroundColor3 = state and Color3.fromRGB(55,60,75) or Color3.fromRGB(45,45,50)
    btn.Text = state and textOn or textOff; btn.TextColor3 = state and Color3.fromRGB(255,255,255) or Color3.fromRGB(130,130,130)
    btn.Font = Enum.Font.GothamBold; btn.TextSize = 11; btn.Parent = VisualScroll
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)
    btn.MouseButton1Click:Connect(function()
        state = not state; btn.Text = state and textOn or textOff
        btn.BackgroundColor3 = state and Color3.fromRGB(55,60,75) or Color3.fromRGB(45,45,50)
        btn.TextColor3 = state and Color3.fromRGB(255,255,255) or Color3.fromRGB(130,130,130)
        cb(state)
    end)
    return btn
end

CreateVisToggle("BOXES: VISIBLE", "BOXES: HIDDEN", 5, true, function(v) Vis_Boxes = v end)
CreateVisToggle("LINES: VISIBLE", "LINES: HIDDEN", 38, true, function(v) Vis_Lines = v end)
CreateVisToggle("FOV: VISIBLE", "FOV: HIDDEN", 71, true, function(v) Vis_FOV = v end)
CreateVisToggle("NAMES: VISIBLE", "NAMES: HIDDEN", 104, true, function(v) Vis_Names = v end)
CreateVisToggle("DISTANCE: VISIBLE", "DISTANCE: HIDDEN", 137, true, function(v) Vis_Dist = v end)

-- ПОЛЗУНКИ
local function MakeSlider(parent, y, labelText, value, minVal, maxVal, callback, format)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0,190,0,15); label.Position = UDim2.new(0.5,-95,0,y)
    label.BackgroundTransparency = 1; label.Text = labelText .. tostring(value)
    label.TextColor3 = Color3.fromRGB(200,200,200); label.Font = Enum.Font.GothamBold; label.TextSize = 10
    label.Parent = parent

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0,190,0,6); frame.Position = UDim2.new(0.5,-95,0,y+20)
    frame.BackgroundColor3 = Color3.fromRGB(45,45,50); frame.Parent = parent

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((value-minVal)/(maxVal-minVal),0,1,0)
    fill.BackgroundColor3 = Color3.fromRGB(0,200,255); fill.Parent = frame

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0,12,0,12); btn.Position = UDim2.new((value-minVal)/(maxVal-minVal),-6,0.5,-6)
    btn.BackgroundColor3 = Color3.fromRGB(255,255,255); btn.Text = ""; btn.Parent = frame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(1,0)

    local dragging = false
    btn.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = true end end)
    UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local pct = math.clamp((input.Position.X - frame.AbsolutePosition.X) / frame.AbsoluteSize.X, 0, 1)
            local val = minVal + pct * (maxVal - minVal)
            if format then val = math.floor(val) end
            callback(val)
            label.Text = labelText .. (format and tostring(val) or string.format("%.2f", val))
            btn.Position = UDim2.new(pct, -6, 0.5, -6); fill.Size = UDim2.new(pct, 0, 1, 0)
        end
    end)
    return {label = label, frame = frame, fill = fill, btn = btn}
end

MakeSlider(VisualScroll, 175, "FOV Радиус: ", Aimbot_FOV, 30, 300, function(v) Aimbot_FOV = v end, true)
MakeSlider(VisualScroll, 220, "Размер прицела: ", Crosshair_Size, 3, 50, function(v) Crosshair_Size = v end, true)
MakeSlider(VisualScroll, 265, "Плавность Аима: ", Aimbot_Smoothness, 0.1, 0.9, function(v) Aimbot_Smoothness = v end, false)

local aimModeBtn = CreateVisToggle("ЦЕЛЬ: ГОЛОВА", "ЦЕЛЬ: ТЕЛО", 310, true, function(v)
    Aimbot_Part = v and "Head" or "Torso"
end)
aimModeBtn.Text = "ЦЕЛЬ: ГОЛОВА"

-- === PLAYER ВКЛАДКА ===
local PlayerScroll = Instance.new("ScrollingFrame")
PlayerScroll.Size = UDim2.new(1,0,1,0); PlayerScroll.BackgroundTransparency = 1
PlayerScroll.CanvasSize = UDim2.new(0,0,0,340); PlayerScroll.ScrollBarThickness = 3
PlayerScroll.Parent = _G.PlayerContentFrame

local flyBtn = CreateButton(PlayerScroll, "FLY: OFF", 5, 190, 30, function()
    Fly_Enabled = not Fly_Enabled; flyBtn.Text = Fly_Enabled and "FLY: ON" or "FLY: OFF"
    flyBtn.BackgroundColor3 = Fly_Enabled and Color3.fromRGB(50,200,50) or Color3.fromRGB(200,50,50)
    if Fly_Enabled and LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.PlatformStand = true end
    end
end)

local noclipBtn = CreateButton(PlayerScroll, "NOCLIP: OFF", 40, 190, 30, function()
    Noclip_Enabled = not Noclip_Enabled; noclipBtn.Text = Noclip_Enabled and "NOCLIP: ON" or "NOCLIP: OFF"
    noclipBtn.BackgroundColor3 = Noclip_Enabled and Color3.fromRGB(50,200,50) or Color3.fromRGB(200,50,50)
    if Noclip_Enabled and LocalPlayer.Character then
        for _, part in pairs(LocalPlayer.Character:GetChildren()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end
end)

local speedBtn = CreateButton(PlayerScroll, "SPEED: OFF", 75, 190, 25, function()
    Speed_Enabled = not Speed_Enabled; speedBtn.Text = Speed_Enabled and "SPEED: ON" or "SPEED: OFF"
    speedBtn.BackgroundColor3 = Speed_Enabled and Color3.fromRGB(50,200,50) or Color3.fromRGB(200,50,50)
end)
MakeSlider(PlayerScroll, 110, "Скорость: ", WalkSpeed_Value, 16, 250, function(v) WalkSpeed_Value = v end, true)

local jumpBtn = CreateButton(PlayerScroll, "JUMP: OFF", 170, 190, 25, function()
    Jump_Enabled = not Jump_Enabled; jumpBtn.Text = Jump_Enabled and "JUMP: ON" or "JUMP: OFF"
    jumpBtn.BackgroundColor3 = Jump_Enabled and Color3.fromRGB(50,200,50) or Color3.fromRGB(200,50,50)
end)
MakeSlider(PlayerScroll, 205, "Высота прыжка: ", JumpPower_Value, 50, 350, function(v) JumpPower_Value = v end, true)

local flySpeedSlider = MakeSlider(PlayerScroll, 260, "Скорость полёта: ", Fly_Speed, 20, 150, function(v) Fly_Speed = v end, true)

-- === КНОПКИ СВЁРТЫВАНИЯ ===
local CloseButton = Instance.new("TextButton")
CloseButton.Size = UDim2.new(0,30,0,30); CloseButton.Position = UDim2.new(1,-35,0,2)
CloseButton.BackgroundTransparency = 1; CloseButton.Text = "X"
CloseButton.TextColor3 = Color3.fromRGB(255,100,100); CloseButton.Font = Enum.Font.GothamBold; CloseButton.TextSize = 18
CloseButton.Parent = MainFrame

local OpenButton = Instance.new("TextButton")
OpenButton.Size = UDim2.new(0,50,0,50); OpenButton.Position = UDim2.new(0,10,0.3,0)
OpenButton.BackgroundColor3 = Color3.fromRGB(45,45,50); OpenButton.Text = "MENU"
OpenButton.TextColor3 = Color3.fromRGB(255,255,255); OpenButton.Font = Enum.Font.GothamBold; OpenButton.TextSize = 12
OpenButton.Visible = false; OpenButton.Active = true; OpenButton.Draggable = true
OpenButton.Parent = MainFrame.Parent; Instance.new("UICorner", OpenButton).CornerRadius = UDim.new(1,0)

CloseButton.MouseButton1Click:Connect(function() MainFrame.Visible = false; OpenButton.Visible = true end)
local dragStart = nil
OpenButton.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragStart = OpenButton.Position end end)
OpenButton.InputEnded:Connect(function(i)
    if (i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch) and dragStart then
        local dist = math.sqrt((OpenButton.Position.X.Offset - dragStart.X.Offset)^2 + (OpenButton.Position.Y.Offset - dragStart.Y.Offset)^2)
        if dist < 5 then MainFrame.Visible = true; OpenButton.Visible = false end
    end
end)

print("✅ Скрипт улучшен до 10/10! @RomanCriminal")
