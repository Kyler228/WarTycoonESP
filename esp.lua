-- ╔══════════════════════════════════════════════════════════╗
-- ║     WAR TYCOON ESP  |  Codex Android + Xeno PC         ║
-- ╚══════════════════════════════════════════════════════════╝

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer      = Players.LocalPlayer

local Config = {
    ESP_Enabled         = true,
    Highlight_Enabled   = true,
    Names_Enabled       = true,
    Distance_Enabled    = true,
    TeamCheck           = true,
    MaxDistance         = 1000,
    EnemyFillColor      = Color3.fromRGB(255, 50, 50),
    EnemyOutlineColor   = Color3.fromRGB(255, 255, 255),
    AllyFillColor       = Color3.fromRGB(50, 150, 255),
    AllyOutlineColor    = Color3.fromRGB(200, 230, 255),
    FillTransparency    = 0.6,
    OutlineTransparency = 0.0,
    ToggleKey           = Enum.KeyCode.F4,
}

local ESPObjects = {}

local function isEnemy(player)
    if not Config.TeamCheck then return true end
    if player.Team == nil or LocalPlayer.Team == nil then return true end
    return player.Team ~= LocalPlayer.Team
end

local function getDistance(character)
    local lc = LocalPlayer.Character
    if not lc then return 0 end
    local a = lc:FindFirstChild("HumanoidRootPart")
    local b = character:FindFirstChild("HumanoidRootPart")
    if not a or not b then return 0 end
    return math.floor((a.Position - b.Position).Magnitude)
end

local function isAlive(character)
    local h = character:FindFirstChildOfClass("Humanoid")
    return h and h.Health > 0
end

local function createESP(player)
    if player == LocalPlayer then return end
    local character = player.Character or player.CharacterAdded:Wait()
    if ESPObjects[player] then
        pcall(function()
            if ESPObjects[player].highlight then ESPObjects[player].highlight:Destroy() end
            if ESPObjects[player].billboard then ESPObjects[player].billboard:Destroy() end
        end)
    end

    local highlight = Instance.new("Highlight")
    highlight.Name = "_ESP_Highlight"
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.FillTransparency = Config.FillTransparency
    highlight.OutlineTransparency = Config.OutlineTransparency
    highlight.FillColor = isEnemy(player) and Config.EnemyFillColor or Config.AllyFillColor
    highlight.OutlineColor = isEnemy(player) and Config.EnemyOutlineColor or Config.AllyOutlineColor
    highlight.Parent = character

    local hrp = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Head")
    if not hrp then
        ESPObjects[player] = { highlight = highlight, billboard = nil }
        return
    end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "_ESP_Billboard"
    billboard.AlwaysOnTop = true
    billboard.Size = UDim2.new(0, 200, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 3.5, 0)
    billboard.Adornee = hrp
    billboard.Parent = character

    local nameLabel = Instance.new("TextLabel")
    nameLabel.BackgroundTransparency = 1
    nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
    nameLabel.Text = player.DisplayName
    nameLabel.TextColor3 = isEnemy(player) and Color3.fromRGB(255, 80, 80) or Color3.fromRGB(100, 180, 255)
    nameLabel.TextStrokeTransparency = 0.3
    nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 14
    nameLabel.Parent = billboard

    local distLabel = Instance.new("TextLabel")
    distLabel.BackgroundTransparency = 1
    distLabel.Size = UDim2.new(1, 0, 0.5, 0)
    distLabel.Position = UDim2.new(0, 0, 0.5, 0)
    distLabel.Text = "0m"
    distLabel.TextColor3 = Color3.fromRGB(255, 255, 150)
    distLabel.TextStrokeTransparency = 0.3
    distLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    distLabel.Font = Enum.Font.Gotham
    distLabel.TextSize = 12
    distLabel.Parent = billboard

    ESPObjects[player] = { highlight=highlight, billboard=billboard, nameLabel=nameLabel, distLabel=distLabel }
end

local function removeESP(player)
    if ESPObjects[player] then
        pcall(function()
            if ESPObjects[player].highlight then ESPObjects[player].highlight:Destroy() end
            if ESPObjects[player].billboard then ESPObjects[player].billboard:Destroy() end
        end)
        ESPObjects[player] = nil
    end
end

local function initPlayer(player)
    if player == LocalPlayer then return end
    player.CharacterAdded:Connect(function() task.wait(0.3) createESP(player) end)
    if player.Character then createESP(player) end
end

for _, p in ipairs(Players:GetPlayers()) do initPlayer(p) end
Players.PlayerAdded:Connect(initPlayer)
Players.PlayerRemoving:Connect(removeESP)

RunService.RenderStepped:Connect(function()
    for player, esp in pairs(ESPObjects) do
        if not player or not player.Parent then removeESP(player) continue end
        local char = player.Character
        if not char or not isAlive(char) then
            if esp.highlight then esp.highlight.Enabled = false end
            if esp.billboard then esp.billboard.Enabled = false end
            continue
        end
        local dist = getDistance(char)
        local enemy = isEnemy(player)
        local show = Config.ESP_Enabled and (dist <= Config.MaxDistance)
        if Config.TeamCheck and not enemy then show = false end
        if esp.highlight then
            esp.highlight.Enabled = show and Config.Highlight_Enabled
            esp.highlight.FillColor = enemy and Config.EnemyFillColor or Config.AllyFillColor
            esp.highlight.OutlineColor = enemy and Config.EnemyOutlineColor or Config.AllyOutlineColor
            esp.highlight.FillTransparency = Config.FillTransparency
        end
        if esp.billboard then esp.billboard.Enabled = show and (Config.Names_Enabled or Config.Distance_Enabled) end
        if esp.nameLabel then esp.nameLabel.Visible = Config.Names_Enabled esp.nameLabel.Text = player.DisplayName end
        if esp.distLabel then esp.distLabel.Visible = Config.Distance_Enabled esp.distLabel.Text = dist.."m" end
    end
end)

-- GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "WarTycoonESP_GUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
if syn and syn.protect_gui then syn.protect_gui(ScreenGui) ScreenGui.Parent = game.CoreGui
elseif gethui then ScreenGui.Parent = gethui()
else ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 285, 0, 400)
MainFrame.Position = UDim2.new(0, 20, 0.5, -200)
MainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)
local stroke = Instance.new("UIStroke", MainFrame)
stroke.Color = Color3.fromRGB(200, 40, 40) stroke.Thickness = 1.5

-- Перетаскивание для Android (Touch)
local draggingFrame, dragStart, startPos = false, nil, nil
MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch then
        draggingFrame = true dragStart = input.Position startPos = MainFrame.Position
    end
end)
MainFrame.InputChanged:Connect(function(input)
    if draggingFrame and input.UserInputType == Enum.UserInputType.Touch then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
MainFrame.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch then draggingFrame = false end
end)

local TitleBar = Instance.new("Frame", MainFrame)
TitleBar.Size = UDim2.new(1, 0, 0, 44) TitleBar.BackgroundColor3 = Color3.fromRGB(200, 35, 35) TitleBar.BorderSizePixel = 0
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 10)
local fix = Instance.new("Frame", TitleBar)
fix.Size = UDim2.new(1,0,0.5,0) fix.Position = UDim2.new(0,0,0.5,0) fix.BackgroundColor3 = Color3.fromRGB(200,35,35) fix.BorderSizePixel = 0

local TitleLabel = Instance.new("TextLabel", TitleBar)
TitleLabel.Size = UDim2.new(1,-55,1,0) TitleLabel.Position = UDim2.new(0,14,0,0)
TitleLabel.BackgroundTransparency = 1 TitleLabel.Text = "[WAR TYCOON ESP]"
TitleLabel.TextColor3 = Color3.fromRGB(255,255,255) TitleLabel.Font = Enum.Font.GothamBold TitleLabel.TextSize = 14
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left

local MinBtn = Instance.new("TextButton", TitleBar)
MinBtn.Size = UDim2.new(0,36,0,36) MinBtn.Position = UDim2.new(1,-42,0.5,-18)
MinBtn.BackgroundColor3 = Color3.fromRGB(255,255,255) MinBtn.BackgroundTransparency = 0.75
MinBtn.Text = "-" MinBtn.TextColor3 = Color3.fromRGB(255,255,255)
MinBtn.Font = Enum.Font.GothamBold MinBtn.TextSize = 20 MinBtn.BorderSizePixel = 0
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(1, 0)

local ContentFrame = Instance.new("ScrollingFrame", MainFrame)
ContentFrame.Size = UDim2.new(1,0,1,-44) ContentFrame.Position = UDim2.new(0,0,0,44)
ContentFrame.BackgroundTransparency = 1 ContentFrame.ScrollBarThickness = 4
ContentFrame.ScrollBarImageColor3 = Color3.fromRGB(200,40,40)
ContentFrame.CanvasSize = UDim2.new(0,0,0,0) ContentFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
local UIList = Instance.new("UIListLayout", ContentFrame) UIList.Padding = UDim.new(0, 8)
local UIPad = Instance.new("UIPadding", ContentFrame)
UIPad.PaddingLeft = UDim.new(0,12) UIPad.PaddingRight = UDim.new(0,12)
UIPad.PaddingTop = UDim.new(0,10) UIPad.PaddingBottom = UDim.new(0,10)

local function makeSection(text)
    local s = Instance.new("TextLabel", ContentFrame)
    s.Size = UDim2.new(1,0,0,20) s.BackgroundTransparency = 1
    s.Text = ">> "..text s.TextColor3 = Color3.fromRGB(255,75,75)
    s.Font = Enum.Font.GothamBold s.TextSize = 12 s.TextXAlignment = Enum.TextXAlignment.Left
end

local function makeToggle(labelText, defaultValue, callback)
    local row = Instance.new("Frame", ContentFrame)
    row.Size = UDim2.new(1,0,0,38) row.BackgroundColor3 = Color3.fromRGB(26,26,34) row.BorderSizePixel = 0
    Instance.new("UICorner", row).CornerRadius = UDim.new(0,7)
    local lbl = Instance.new("TextLabel", row)
    lbl.Size = UDim2.new(0.7,0,1,0) lbl.Position = UDim2.new(0,10,0,0)
    lbl.BackgroundTransparency = 1 lbl.Text = labelText lbl.TextColor3 = Color3.fromRGB(215,215,215)
    lbl.Font = Enum.Font.Gotham lbl.TextSize = 13 lbl.TextXAlignment = Enum.TextXAlignment.Left
    local togBg = Instance.new("Frame", row)
    togBg.Size = UDim2.new(0,48,0,26) togBg.Position = UDim2.new(1,-56,0.5,-13)
    togBg.BackgroundColor3 = defaultValue and Color3.fromRGB(220,50,50) or Color3.fromRGB(55,55,72)
    togBg.BorderSizePixel = 0 Instance.new("UICorner", togBg).CornerRadius = UDim.new(1,0)
    local togDot = Instance.new("Frame", togBg)
    togDot.Size = UDim2.new(0,20,0,20)
    togDot.Position = defaultValue and UDim2.new(1,-23,0.5,-10) or UDim2.new(0,3,0.5,-10)
    togDot.BackgroundColor3 = Color3.fromRGB(255,255,255) togDot.BorderSizePixel = 0
    Instance.new("UICorner", togDot).CornerRadius = UDim.new(1,0)
    local value = defaultValue
    local btn = Instance.new("TextButton", row)
    btn.Size = UDim2.new(1,0,1,0) btn.BackgroundTransparency = 1 btn.Text = ""
    btn.MouseButton1Click:Connect(function()
        value = not value
        togBg.BackgroundColor3 = value and Color3.fromRGB(220,50,50) or Color3.fromRGB(55,55,72)
        togDot.Position = value and UDim2.new(1,-23,0.5,-10) or UDim2.new(0,3,0.5,-10)
        callback(value)
    end)
end

local function makeSlider(labelText, minVal, maxVal, defaultVal, suffix, callback)
    local row = Instance.new("Frame", ContentFrame)
    row.Size = UDim2.new(1,0,0,58) row.BackgroundColor3 = Color3.fromRGB(26,26,34) row.BorderSizePixel = 0
    Instance.new("UICorner", row).CornerRadius = UDim.new(0,7)
    local lbl = Instance.new("TextLabel", row)
    lbl.Size = UDim2.new(0.7,0,0,24) lbl.Position = UDim2.new(0,10,0,4)
    lbl.BackgroundTransparency = 1 lbl.Text = labelText lbl.TextColor3 = Color3.fromRGB(215,215,215)
    lbl.Font = Enum.Font.Gotham lbl.TextSize = 12 lbl.TextXAlignment = Enum.TextXAlignment.Left
    local valLbl = Instance.new("TextLabel", row)
    valLbl.Size = UDim2.new(0.3,-10,0,24) valLbl.Position = UDim2.new(0.7,0,0,4)
    valLbl.BackgroundTransparency = 1 valLbl.Text = tostring(defaultVal)..(suffix or "")
    valLbl.TextColor3 = Color3.fromRGB(255,90,90) valLbl.Font = Enum.Font.GothamBold
    valLbl.TextSize = 12 valLbl.TextXAlignment = Enum.TextXAlignment.Right
    local trackBg = Instance.new("Frame", row)
    trackBg.Size = UDim2.new(1,-20,0,8) trackBg.Position = UDim2.new(0,10,0,38)
    trackBg.BackgroundColor3 = Color3.fromRGB(48,48,64) trackBg.BorderSizePixel = 0
    Instance.new("UICorner", trackBg).CornerRadius = UDim.new(1,0)
    local fill = Instance.new("Frame", trackBg)
    fill.Size = UDim2.new((defaultVal-minVal)/(maxVal-minVal),0,1,0)
    fill.BackgroundColor3 = Color3.fromRGB(220,50,50) fill.BorderSizePixel = 0
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1,0)
    local draggingSlider = false
    local hitbox = Instance.new("TextButton", trackBg)
    hitbox.Size = UDim2.new(1,0,0,24) hitbox.Position = UDim2.new(0,0,0.5,-12)
    hitbox.BackgroundTransparency = 1 hitbox.Text = ""
    local function update(x)
        local rel = math.clamp((x - trackBg.AbsolutePosition.X)/trackBg.AbsoluteSize.X,0,1)
        local val = math.floor(minVal + rel*(maxVal-minVal))
        fill.Size = UDim2.new(rel,0,1,0) valLbl.Text = tostring(val)..(suffix or "") callback(val)
    end
    hitbox.MouseButton1Down:Connect(function() draggingSlider = true end)
    hitbox.MouseButton1Up:Connect(function() draggingSlider = false end)
    hitbox.MouseButton1Click:Connect(function() update(UserInputService:GetMouseLocation().X) end)
    UserInputService.InputChanged:Connect(function(inp)
        if draggingSlider and inp.UserInputType == Enum.UserInputType.MouseMovement then update(inp.Position.X) end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then draggingSlider = false end
    end)
    hitbox.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.Touch then draggingSlider = true update(inp.Position.X) end
    end)
    hitbox.InputChanged:Connect(function(inp)
        if draggingSlider and inp.UserInputType == Enum.UserInputType.Touch then update(inp.Position.X) end
    end)
    hitbox.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.Touch then draggingSlider = false end
    end)
end

makeSection("ОСНОВНЫЕ")
makeToggle("ESP Включён", Config.ESP_Enabled, function(v) Config.ESP_Enabled = v end)
makeToggle("Подсветка сквозь стены", Config.Highlight_Enabled, function(v)
    Config.Highlight_Enabled = v
    for _,esp in pairs(ESPObjects) do if esp.highlight then esp.highlight.Enabled = v end end
end)
makeToggle("Показывать имена", Config.Names_Enabled, function(v) Config.Names_Enabled = v end)
makeToggle("Показывать дистанцию", Config.Distance_Enabled, function(v) Config.Distance_Enabled = v end)
makeToggle("Скрывать союзников", Config.TeamCheck, function(v) Config.TeamCheck = v end)
makeSection("ПАРАМЕТРЫ")
makeSlider("Макс. дистанция", 50, 2000, Config.MaxDistance, " studs", function(v) Config.MaxDistance = v end)
makeSlider("Прозрачность заливки", 0, 10, math.floor(Config.FillTransparency*10), "", function(v) Config.FillTransparency = v/10 end)

local hint = Instance.new("TextLabel", ContentFrame)
hint.Size = UDim2.new(1,0,0,22) hint.BackgroundTransparency = 1
hint.Text = "PC: [F4]  |  Android: кнопка [-]"
hint.TextColor3 = Color3.fromRGB(100,100,130) hint.Font = Enum.Font.Gotham
hint.TextSize = 11 hint.TextXAlignment = Enum.TextXAlignment.Center

local guiOpen = true
local function toggleGUI()
    guiOpen = not guiOpen
    ContentFrame.Visible = guiOpen
    MainFrame.Size = guiOpen and UDim2.new(0,285,0,400) or UDim2.new(0,285,0,44)
    MinBtn.Text = guiOpen and "-" or "+"
end
MinBtn.MouseButton1Click:Connect(toggleGUI)
UserInputService.InputBegan:Connect(function(inp, gp)
    if gp then return end
    if inp.KeyCode == Config.ToggleKey then toggleGUI() end
end)

task.spawn(function()
    local ng = Instance.new("ScreenGui") ng.Name = "_NotifyESP" ng.ResetOnSpawn = false
    if gethui then ng.Parent = gethui() else ng.Parent = LocalPlayer:WaitForChild("PlayerGui") end
    local nf = Instance.new("Frame", ng)
    nf.Size = UDim2.new(0,280,0,54) nf.Position = UDim2.new(0.5,-140,0,20)
    nf.BackgroundColor3 = Color3.fromRGB(18,18,24) nf.BorderSizePixel = 0
    Instance.new("UICorner", nf).CornerRadius = UDim.new(0,9)
    local ns = Instance.new("UIStroke", nf) ns.Color = Color3.fromRGB(200,40,40) ns.Thickness = 1.5
    local nl = Instance.new("TextLabel", nf)
    nl.Size = UDim2.new(1,0,1,0) nl.BackgroundTransparency = 1
    nl.Text = "War Tycoon ESP OK!  PC:[F4] / Android:[-]"
    nl.TextColor3 = Color3.fromRGB(245,245,245) nl.Font = Enum.Font.GothamBold nl.TextSize = 12
    task.wait(4) if ng and ng.Parent then ng:Destroy() end
end)

print("[WAR TYCOON ESP] Loaded. Codex Android + Xeno PC.")
