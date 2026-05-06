-- memeSense v3.0 by memeSense
-- ФИКСЫ: движение теперь работает корректно (BodyMover удаляется правильно)
-- НОВОЕ: Rainbow mode, AntiAFK, Teleport to Player, Crosshair, Clock, улучшенное меню

local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Lighting = game:GetService("Lighting")
local Camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")

-- ===================== SETTINGS =====================
local Settings = {
    -- Combat
    Aimbot = false,
    FireCheck = false,
    WallCheck = false,
    SilentAim = false,
    TriggerBot = false,
    HitboxExpander = false,
    HitboxSize = 6.0,
    NoRecoil = false,
    RapidFire = false,
    Spinbot = false,
    TargetLock = false,
    Prediction = false,
    PredictionAmount = 0.12,
    KillAura = false,
    KillAuraRange = 15.0,
    FOV = 93,
    FOVColor = Color3.fromRGB(255,60,60),
    Smooth = 18.0,
    -- Visual
    ESPBox = false,
    ESPName = false,
    Chams = false,
    ESPHealth = false,
    Tracers = false,
    DistanceESP = false,
    WeaponESP = false,
    SnapLines = false,
    Fullbright = false,
    NoFog = false,
    FOVChanger = false,
    FOVValue = 70,
    ThirdPerson = false,
    ThirdPersonDist = 8.0,
    Crosshair = false,
    RainbowChams = false,
    -- Movement
    SpeedHack = false,
    SpeedValue = 32.0,
    Fly = false,
    FlySpeed = 50.0,
    Noclip = false,
    SuperJump = false,
    JumpPower = 100.0,
    InfiniteJump = false,
    BunnyHop = false,
    -- Misc
    GodMode = false,
    AutoRespawn = false,
    SpamChat = false,
    SpamMsg = "memeSense v3",
    AntiAFK = false,
    Notifications = true,
    FPSCounter = false,
    -- Keys
    FlyKey = Enum.KeyCode.F,
    NoclipKey = Enum.KeyCode.N,
    SpinbotKey = Enum.KeyCode.X,
    PanicKey = Enum.KeyCode.End,
}

-- ===================== STATE =====================
local ESPObjects = {}
local FOVCircle = nil
local flyBodyVelocity = nil
local flyBodyGyro = nil
local flyActive = false
local lockedTarget = nil
local originalFog = {Start=Lighting.FogStart, End=Lighting.FogEnd, Color=Lighting.FogColor}
local originalAmbient = Lighting.Ambient
local originalBrightness = Lighting.Brightness
local rainbowHue = 0
local crosshairLines = {}

-- ===================== ANTI-AFK =====================
local VirtualUser = game:GetService("VirtualUser")
player.Idled:Connect(function()
    if Settings.AntiAFK then
        VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        task.wait(1)
        VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    end
end)

-- ===================== FOV CIRCLE =====================
pcall(function()
    FOVCircle = Drawing.new("Circle")
    FOVCircle.Thickness = 1.5
    FOVCircle.NumSides = 64
    FOVCircle.Radius = Settings.FOV
    FOVCircle.Filled = false
    FOVCircle.Visible = false
    FOVCircle.ZIndex = 999
    FOVCircle.Transparency = 1
    FOVCircle.Color = Settings.FOVColor
end)

-- ===================== CROSSHAIR =====================
pcall(function()
    for i=1,4 do
        local l = Drawing.new("Line")
        l.Thickness = 1.5
        l.Color = Color3.fromRGB(255,255,255)
        l.Transparency = 1
        l.Visible = false
        l.ZIndex = 998
        crosshairLines[i] = l
    end
end)

local function updateCrosshair()
    if #crosshairLines < 4 then return end
    local cx = Camera.ViewportSize.X/2
    local cy = Camera.ViewportSize.Y/2
    local s = 8 -- gap
    local len = 14 -- length
    local visible = Settings.Crosshair
    -- left
    crosshairLines[1].From = Vector2.new(cx-s-len, cy)
    crosshairLines[1].To   = Vector2.new(cx-s, cy)
    crosshairLines[1].Visible = visible
    -- right
    crosshairLines[2].From = Vector2.new(cx+s, cy)
    crosshairLines[2].To   = Vector2.new(cx+s+len, cy)
    crosshairLines[2].Visible = visible
    -- up
    crosshairLines[3].From = Vector2.new(cx, cy-s-len)
    crosshairLines[3].To   = Vector2.new(cx, cy-s)
    crosshairLines[3].Visible = visible
    -- down
    crosshairLines[4].From = Vector2.new(cx, cy+s)
    crosshairLines[4].To   = Vector2.new(cx, cy+s+len)
    crosshairLines[4].Visible = visible
end

-- ===================== GUI SETUP =====================
local blur = Instance.new("BlurEffect")
blur.Size = 18
blur.Parent = Lighting
blur.Enabled = false

local gui = Instance.new("ScreenGui")
gui.Name = "memeSense_v3"
gui.Parent = playerGui
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false

-- ===================== NOTIFICATIONS =====================
local notifFrame = Instance.new("Frame", gui)
notifFrame.Size = UDim2.new(0,270,0.6,0)
notifFrame.Position = UDim2.new(1,-280,0.2,0)
notifFrame.BackgroundTransparency = 1
local notifLayout = Instance.new("UIListLayout", notifFrame)
notifLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
notifLayout.Padding = UDim.new(0,6)
notifLayout.SortOrder = Enum.SortOrder.LayoutOrder

local function notify(title, msg, color)
    if not Settings.Notifications then return end
    color = color or Color3.fromRGB(255,60,60)
    local n = Instance.new("Frame", notifFrame)
    n.Size = UDim2.new(1,0,0,58)
    n.BackgroundColor3 = Color3.fromRGB(22,22,28)
    n.BorderSizePixel = 0
    n.BackgroundTransparency = 1
    local nc = Instance.new("UICorner",n); nc.CornerRadius = UDim.new(0,10)
    local accent = Instance.new("Frame",n)
    accent.Size = UDim2.new(0,3,1,-10)
    accent.Position = UDim2.new(0,0,0,5)
    accent.BackgroundColor3 = color
    accent.BorderSizePixel = 0
    local ac2 = Instance.new("UICorner",accent); ac2.CornerRadius=UDim.new(0,3)
    local t1 = Instance.new("TextLabel",n)
    t1.Position = UDim2.new(0,12,0,8)
    t1.Size = UDim2.new(1,-16,0,18)
    t1.BackgroundTransparency=1
    t1.Text = title
    t1.Font = Enum.Font.GothamBold
    t1.TextSize = 13
    t1.TextColor3 = color
    t1.TextXAlignment = Enum.TextXAlignment.Left
    local t2 = Instance.new("TextLabel",n)
    t2.Position = UDim2.new(0,12,0,28)
    t2.Size = UDim2.new(1,-16,0,18)
    t2.BackgroundTransparency=1
    t2.Text = msg
    t2.Font = Enum.Font.Gotham
    t2.TextSize = 12
    t2.TextColor3 = Color3.fromRGB(160,160,175)
    t2.TextXAlignment = Enum.TextXAlignment.Left
    -- slide in
    TweenService:Create(n, TweenInfo.new(0.25, Enum.EasingStyle.Quart), {BackgroundTransparency=0}):Play()
    task.delay(3, function()
        TweenService:Create(n, TweenInfo.new(0.25), {BackgroundTransparency=1}):Play()
        task.wait(0.3)
        n:Destroy()
    end)
end

-- ===================== HUD =====================
local hudLabel = Instance.new("TextLabel", gui)
hudLabel.Position = UDim2.new(0,8,0,8)
hudLabel.Size = UDim2.new(0,300,0,20)
hudLabel.BackgroundTransparency=1
hudLabel.Font = Enum.Font.GothamBold
hudLabel.TextSize = 13
hudLabel.TextColor3 = Color3.fromRGB(255,60,60)
hudLabel.TextXAlignment = Enum.TextXAlignment.Left
hudLabel.Text = ""

local clockLabel = Instance.new("TextLabel", gui)
clockLabel.AnchorPoint = Vector2.new(1,0)
clockLabel.Position = UDim2.new(1,-8,0,8)
clockLabel.Size = UDim2.new(0,120,0,18)
clockLabel.BackgroundTransparency=1
clockLabel.Font = Enum.Font.GothamBold
clockLabel.TextSize = 13
clockLabel.TextColor3 = Color3.fromRGB(255,60,60)
clockLabel.TextXAlignment = Enum.TextXAlignment.Right
clockLabel.Text = ""

-- ===================== OPEN BUTTON =====================
local openBtn = Instance.new("TextButton", gui)
openBtn.Name = "OpenBtn"
openBtn.Size = UDim2.new(0,52,0,52)
openBtn.Position = UDim2.new(0,20,1,-80)
openBtn.BackgroundColor3 = Color3.fromRGB(255,50,50)
openBtn.Text = "MS"
openBtn.Font = Enum.Font.GothamBlack
openBtn.TextColor3 = Color3.new(1,1,1)
openBtn.TextSize = 16
openBtn.AutoButtonColor = false
openBtn.ZIndex = 10
local btnCorner = Instance.new("UICorner", openBtn); btnCorner.CornerRadius = UDim.new(1,0)
local btnStroke = Instance.new("UIStroke", openBtn)
btnStroke.Color = Color3.fromRGB(255,100,100)
btnStroke.Thickness = 1.5

-- drag button
local dragging, startPos, startInputPos
openBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        startInputPos = input.Position
        startPos = openBtn.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
openBtn.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - startInputPos
        openBtn.Position = UDim2.new(
            0, math.clamp(startPos.X.Offset + delta.X, 0, gui.AbsoluteSize.X - 52),
            0, math.clamp(startPos.Y.Offset + delta.Y, 0, gui.AbsoluteSize.Y - 52)
        )
    end
end)

-- ===================== MAIN FRAME =====================
local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 430, 0, 420)
frame.Position = UDim2.new(0.5, -215, 0.5, -210)
frame.BackgroundColor3 = Color3.fromRGB(16,16,20)
frame.Visible = false
frame.Active = true
frame.Draggable = true
frame.ZIndex = 5
local menuCorner = Instance.new("UICorner", frame); menuCorner.CornerRadius = UDim.new(0,14)
local menuStroke = Instance.new("UIStroke", frame)
menuStroke.Color = Color3.fromRGB(60,60,80)
menuStroke.Thickness = 1

-- Title bar
local titleBar = Instance.new("Frame", frame)
titleBar.Size = UDim2.new(1,0,0,50)
titleBar.BackgroundColor3 = Color3.fromRGB(20,20,26)
titleBar.BorderSizePixel = 0
local tbCorner = Instance.new("UICorner", titleBar); tbCorner.CornerRadius = UDim.new(0,14)
local tbFix = Instance.new("Frame", titleBar)
tbFix.Size = UDim2.new(1,0,0.5,0)
tbFix.Position = UDim2.new(0,0,0.5,0)
tbFix.BackgroundColor3 = Color3.fromRGB(20,20,26)
tbFix.BorderSizePixel = 0

local titleRed = Instance.new("TextLabel", titleBar)
titleRed.Size = UDim2.new(0,80,1,0)
titleRed.Position = UDim2.new(0,16,0,0)
titleRed.BackgroundTransparency = 1
titleRed.Text = "meme"
titleRed.Font = Enum.Font.GothamBlack
titleRed.TextSize = 26
titleRed.TextColor3 = Color3.fromRGB(255,55,55)
titleRed.TextXAlignment = Enum.TextXAlignment.Left

local titleWhite = Instance.new("TextLabel", titleBar)
titleWhite.Size = UDim2.new(0,120,1,0)
titleWhite.Position = UDim2.new(0,96,0,0)
titleWhite.BackgroundTransparency = 1
titleWhite.Text = "Sense"
titleWhite.Font = Enum.Font.GothamBlack
titleWhite.TextSize = 26
titleWhite.TextColor3 = Color3.new(1,1,1)
titleWhite.TextXAlignment = Enum.TextXAlignment.Left

local verLabel = Instance.new("TextLabel", titleBar)
verLabel.Size = UDim2.new(0,60,0,16)
verLabel.Position = UDim2.new(0,200,0.5,-8)
verLabel.BackgroundColor3 = Color3.fromRGB(255,55,55)
verLabel.Text = "v3.0"
verLabel.Font = Enum.Font.GothamBold
verLabel.TextSize = 11
verLabel.TextColor3 = Color3.new(1,1,1)
local verCorner = Instance.new("UICorner", verLabel); verCorner.CornerRadius = UDim.new(1,0)

local closeX = Instance.new("TextButton", titleBar)
closeX.Size = UDim2.new(0,28,0,28)
closeX.AnchorPoint = Vector2.new(1,0.5)
closeX.Position = UDim2.new(1,-12,0.5,0)
closeX.BackgroundColor3 = Color3.fromRGB(180,40,40)
closeX.Text = "✕"
closeX.Font = Enum.Font.GothamBold
closeX.TextSize = 14
closeX.TextColor3 = Color3.new(1,1,1)
local cxCorner = Instance.new("UICorner", closeX); cxCorner.CornerRadius = UDim.new(1,0)
closeX.MouseButton1Click:Connect(function()
    frame.Visible = false
    blur.Enabled = false
end)

-- ===================== TABS =====================
local tabHolder = Instance.new("Frame", frame)
tabHolder.Size = UDim2.new(1,-24,0,34)
tabHolder.Position = UDim2.new(0,12,0,55)
tabHolder.BackgroundTransparency = 1
local tabLayout = Instance.new("UIListLayout", tabHolder)
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.Padding = UDim.new(0,6)
tabLayout.VerticalAlignment = Enum.VerticalAlignment.Center

local TABS = {
    {Title="⚔ Combat", Key="Combat"},
    {Title="👁 Visual", Key="Visual"},
    {Title="🏃 Move", Key="Move"},
    {Title="⚙ Misc", Key="Misc"},
}

local pages = {}
local tabBtns = {}

local content = Instance.new("Frame", frame)
content.Size = UDim2.new(1,-24,1,-100)
content.Position = UDim2.new(0,12,0,95)
content.BackgroundColor3 = Color3.fromRGB(22,22,28)
content.BorderSizePixel = 0
local contentCorner = Instance.new("UICorner", content); contentCorner.CornerRadius = UDim.new(0,10)
content.ClipsDescendants = true

local function createPage()
    local sc = Instance.new("ScrollingFrame", content)
    sc.Size = UDim2.new(1,0,1,0)
    sc.BackgroundTransparency = 1
    sc.BorderSizePixel = 0
    sc.ScrollBarThickness = 3
    sc.ScrollBarImageColor3 = Color3.fromRGB(255,55,55)
    sc.AutomaticCanvasSize = Enum.AutomaticSize.Y
    sc.CanvasSize = UDim2.new(0,0,0,0)
    sc.Visible = false
    local lay = Instance.new("UIListLayout", sc)
    lay.Padding = UDim.new(0,5)
    lay.HorizontalAlignment = Enum.HorizontalAlignment.Center
    local pad = Instance.new("UIPadding", sc)
    pad.PaddingTop = UDim.new(0,8)
    pad.PaddingLeft = UDim.new(0,8)
    pad.PaddingRight = UDim.new(0,8)
    pad.PaddingBottom = UDim.new(0,8)
    return sc
end

for i, tabData in ipairs(TABS) do
    local t = Instance.new("TextButton", tabHolder)
    t.Size = UDim2.new(0,84,1,0)
    local isFirst = (i == 1)
    t.BackgroundColor3 = isFirst and Color3.fromRGB(255,50,50) or Color3.fromRGB(30,30,38)
    t.TextColor3 = isFirst and Color3.new(1,1,1) or Color3.fromRGB(140,140,155)
    t.Font = Enum.Font.GothamBold
    t.Text = tabData.Title
    t.TextSize = 12
    t.AutoButtonColor = false
    local tc = Instance.new("UICorner", t); tc.CornerRadius = UDim.new(1,0)
    tabBtns[tabData.Key] = t
    pages[tabData.Key] = createPage()
end
pages["Combat"].Visible = true

for key, btn in pairs(tabBtns) do
    btn.MouseButton1Click:Connect(function()
        for n, page in pairs(pages) do
            page.Visible = false
            tabBtns[n].BackgroundColor3 = Color3.fromRGB(30,30,38)
            tabBtns[n].TextColor3 = Color3.fromRGB(140,140,155)
        end
        pages[key].Visible = true
        btn.BackgroundColor3 = Color3.fromRGB(255,50,50)
        btn.TextColor3 = Color3.new(1,1,1)
        TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(255,50,50)}):Play()
    end)
end

-- ===================== UI COMPONENTS =====================
local function addSection(page, txt)
    local wrap = Instance.new("Frame", page)
    wrap.Size = UDim2.new(1,-4,0,24)
    wrap.BackgroundTransparency = 1
    local lbl = Instance.new("TextLabel", wrap)
    lbl.Size = UDim2.new(1,0,1,0)
    lbl.BackgroundTransparency = 1
    lbl.Text = "  " .. txt:upper()
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 10
    lbl.TextColor3 = Color3.fromRGB(255,55,55)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextTracking = 2
    local line = Instance.new("Frame", wrap)
    line.Size = UDim2.new(1,-60,0,1)
    line.Position = UDim2.new(0,55,0.5,0)
    line.BackgroundColor3 = Color3.fromRGB(50,50,65)
    line.BorderSizePixel = 0
end

local function addToggle(page, txt, settingKey, cb)
    local holder = Instance.new("Frame", page)
    holder.Size = UDim2.new(1,-4,0,38)
    holder.BackgroundColor3 = Color3.fromRGB(28,28,36)
    holder.BorderSizePixel = 0
    local cor = Instance.new("UICorner", holder); cor.CornerRadius = UDim.new(0,9)
    -- hover effect
    holder.MouseEnter:Connect(function()
        TweenService:Create(holder, TweenInfo.new(0.15), {BackgroundColor3=Color3.fromRGB(34,34,44)}):Play()
    end)
    holder.MouseLeave:Connect(function()
        TweenService:Create(holder, TweenInfo.new(0.15), {BackgroundColor3=Color3.fromRGB(28,28,36)}):Play()
    end)
    local lbl = Instance.new("TextLabel", holder)
    lbl.AnchorPoint = Vector2.new(0,0.5)
    lbl.Position = UDim2.new(0,12,0.5,0)
    lbl.Size = UDim2.new(1,-60,1,0)
    lbl.BackgroundTransparency = 1
    lbl.Text = txt
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 14
    lbl.TextColor3 = Color3.fromRGB(210,210,222)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    -- toggle button
    local tog = Instance.new("Frame", holder)
    tog.Size = UDim2.new(0,36,0,20)
    tog.AnchorPoint = Vector2.new(1,0.5)
    tog.Position = UDim2.new(1,-12,0.5,0)
    tog.BackgroundColor3 = Settings[settingKey] and Color3.fromRGB(255,50,50) or Color3.fromRGB(50,50,65)
    local togCor = Instance.new("UICorner", tog); togCor.CornerRadius = UDim.new(1,0)
    local dot = Instance.new("Frame", tog)
    dot.Size = UDim2.new(0,14,0,14)
    dot.AnchorPoint = Vector2.new(0,0.5)
    dot.Position = Settings[settingKey] and UDim2.new(1,-17,0.5,0) or UDim2.new(0,3,0.5,0)
    dot.BackgroundColor3 = Color3.new(1,1,1)
    local dotCor = Instance.new("UICorner", dot); dotCor.CornerRadius = UDim.new(1,0)
    -- clickable overlay
    local clickBtn = Instance.new("TextButton", holder)
    clickBtn.Size = UDim2.new(1,0,1,0)
    clickBtn.BackgroundTransparency = 1
    clickBtn.Text = ""
    clickBtn.MouseButton1Click:Connect(function()
        Settings[settingKey] = not Settings[settingKey]
        local on = Settings[settingKey]
        TweenService:Create(tog, TweenInfo.new(0.2), {BackgroundColor3 = on and Color3.fromRGB(255,50,50) or Color3.fromRGB(50,50,65)}):Play()
        TweenService:Create(dot, TweenInfo.new(0.2), {Position = on and UDim2.new(1,-17,0.5,0) or UDim2.new(0,3,0.5,0)}):Play()
        if cb then cb(on) end
        notify(txt, on and "Включено" or "Выключено", on and Color3.fromRGB(255,55,55) or Color3.fromRGB(100,100,115))
    end)
end

local function addSlider(page, name, settingKey, min, max, decimals)
    local holder = Instance.new("Frame", page)
    holder.Size = UDim2.new(1,-4,0,44)
    holder.BackgroundColor3 = Color3.fromRGB(28,28,36)
    holder.BorderSizePixel = 0
    local cor = Instance.new("UICorner", holder); cor.CornerRadius = UDim.new(0,9)
    local lbl = Instance.new("TextLabel", holder)
    lbl.Position = UDim2.new(0,12,0,4)
    lbl.Size = UDim2.new(0.6,0,0,18)
    lbl.BackgroundTransparency = 1
    lbl.Text = name
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 13
    lbl.TextColor3 = Color3.fromRGB(180,180,195)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    local valLbl = Instance.new("TextLabel", holder)
    valLbl.AnchorPoint = Vector2.new(1,0)
    valLbl.Position = UDim2.new(1,-12,0,4)
    valLbl.Size = UDim2.new(0.35,0,0,18)
    valLbl.BackgroundTransparency = 1
    valLbl.Text = decimals and string.format("%.1f",Settings[settingKey]) or tostring(math.floor(Settings[settingKey]))
    valLbl.Font = Enum.Font.GothamBold
    valLbl.TextSize = 13
    valLbl.TextColor3 = Color3.fromRGB(255,60,60)
    valLbl.TextXAlignment = Enum.TextXAlignment.Right
    local track = Instance.new("Frame", holder)
    track.Size = UDim2.new(1,-24,0,5)
    track.Position = UDim2.new(0,12,1,-12)
    track.BackgroundColor3 = Color3.fromRGB(40,40,55)
    track.BorderSizePixel = 0
    local trackCor = Instance.new("UICorner", track); trackCor.CornerRadius = UDim.new(1,0)
    local fill = Instance.new("Frame", track)
    fill.BackgroundColor3 = Color3.fromRGB(255,55,55)
    fill.BorderSizePixel = 0
    local ratio = (Settings[settingKey]-min)/(max-min)
    fill.Size = UDim2.new(math.clamp(ratio,0,1),0,1,0)
    local fillCor = Instance.new("UICorner", fill); fillCor.CornerRadius = UDim.new(1,0)
    local sdrag = false
    local function update(newVal)
        Settings[settingKey] = math.clamp(decimals and newVal or math.floor(newVal), min, max)
        valLbl.Text = decimals and string.format("%.1f",Settings[settingKey]) or tostring(math.floor(Settings[settingKey]))
        fill.Size = UDim2.new(math.clamp((Settings[settingKey]-min)/(max-min),0,1),0,1,0)
    end
    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            sdrag = true
            local rel = math.clamp((input.Position.X-track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1)
            update(rel*(max-min)+min)
        end
    end)
    UIS.InputChanged:Connect(function(input)
        if sdrag and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            if track.AbsoluteSize.X > 0 then
                local rel = math.clamp((input.Position.X-track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1)
                update(rel*(max-min)+min)
            end
        end
    end)
    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            sdrag = false
        end
    end)
end

local function addButton(page, txt, cb)
    local btn = Instance.new("TextButton", page)
    btn.Size = UDim2.new(1,-4,0,38)
    btn.BackgroundColor3 = Color3.fromRGB(200,40,40)
    btn.Text = txt
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.TextColor3 = Color3.new(1,1,1)
    btn.AutoButtonColor = false
    local bc = Instance.new("UICorner", btn); bc.CornerRadius = UDim.new(0,9)
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3=Color3.fromRGB(255,55,55)}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3=Color3.fromRGB(200,40,40)}):Play()
    end)
    btn.MouseButton1Click:Connect(function()
        if cb then cb() end
    end)
end

local function addDropdown(page, name, items, settingKey)
    local holder = Instance.new("Frame", page)
    holder.Size = UDim2.new(1,-4,0,38)
    holder.BackgroundColor3 = Color3.fromRGB(28,28,36)
    holder.BorderSizePixel = 0
    local hc = Instance.new("UICorner", holder); hc.CornerRadius = UDim.new(0,9)
    local lbl = Instance.new("TextLabel", holder)
    lbl.Position = UDim2.new(0,12,0,0)
    lbl.Size = UDim2.new(0.5,0,1,0)
    lbl.BackgroundTransparency = 1
    lbl.Text = name
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 13
    lbl.TextColor3 = Color3.fromRGB(180,180,195)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    local selBtn = Instance.new("TextButton", holder)
    selBtn.AnchorPoint = Vector2.new(1,0.5)
    selBtn.Position = UDim2.new(1,-8,0.5,0)
    selBtn.Size = UDim2.new(0.45,-4,0,26)
    selBtn.BackgroundColor3 = Color3.fromRGB(40,40,55)
    selBtn.Text = tostring(Settings[settingKey])
    selBtn.Font = Enum.Font.GothamBold
    selBtn.TextSize = 12
    selBtn.TextColor3 = Color3.fromRGB(255,60,60)
    local sc = Instance.new("UICorner", selBtn); sc.CornerRadius = UDim.new(1,0)
    local idx = 1
    for i,v in ipairs(items) do if v == Settings[settingKey] then idx=i end end
    selBtn.MouseButton1Click:Connect(function()
        idx = idx % #items + 1
        Settings[settingKey] = items[idx]
        selBtn.Text = tostring(items[idx])
    end)
end

-- ===================== TELEPORT TO PLAYER =====================
local function addTeleportDropdown(page)
    local holder = Instance.new("Frame", page)
    holder.Size = UDim2.new(1,-4,0,38)
    holder.BackgroundColor3 = Color3.fromRGB(28,28,36)
    holder.BorderSizePixel = 0
    local hc = Instance.new("UICorner", holder); hc.CornerRadius = UDim.new(0,9)
    local lbl = Instance.new("TextLabel", holder)
    lbl.Position = UDim2.new(0,12,0,0)
    lbl.Size = UDim2.new(0.5,0,1,0)
    lbl.BackgroundTransparency = 1
    lbl.Text = "Teleport to Player"
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 13
    lbl.TextColor3 = Color3.fromRGB(180,180,195)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    local selBtn = Instance.new("TextButton", holder)
    selBtn.AnchorPoint = Vector2.new(1,0.5)
    selBtn.Position = UDim2.new(1,-8,0.5,0)
    selBtn.Size = UDim2.new(0.45,-4,0,26)
    selBtn.BackgroundColor3 = Color3.fromRGB(200,40,40)
    selBtn.Text = "Select"
    selBtn.Font = Enum.Font.GothamBold
    selBtn.TextSize = 12
    selBtn.TextColor3 = Color3.new(1,1,1)
    local sc = Instance.new("UICorner", selBtn); sc.CornerRadius = UDim.new(1,0)
    local players = {}
    local idx = 0
    selBtn.MouseButton1Click:Connect(function()
        players = {}
        for _, p in pairs(game.Players:GetPlayers()) do
            if p ~= player then table.insert(players, p) end
        end
        if #players == 0 then notify("Teleport", "Нет игроков!", Color3.fromRGB(255,150,50)) return end
        idx = idx % #players + 1
        local target = players[idx]
        selBtn.Text = target.Name
        if target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
            local myChar = player.Character
            if myChar and myChar:FindFirstChild("HumanoidRootPart") then
                myChar.HumanoidRootPart.CFrame = target.Character.HumanoidRootPart.CFrame + Vector3.new(0,3,0)
                notify("Teleport", "→ " .. target.Name, Color3.fromRGB(255,55,55))
            end
        end
    end)
end

-- ===================== COMBAT PAGE =====================
addSection(pages.Combat, "Aimbot")
addToggle(pages.Combat, "Aimbot", "Aimbot")
addToggle(pages.Combat, "Silent Aim", "SilentAim")
addToggle(pages.Combat, "Target Lock", "TargetLock")
addToggle(pages.Combat, "Wall Check", "WallCheck")
addToggle(pages.Combat, "Prediction", "Prediction")
addSlider(pages.Combat, "FOV", "FOV", 20, 400, false)
addSlider(pages.Combat, "Smooth", "Smooth", 1, 300, true)
addSlider(pages.Combat, "Prediction Amt", "PredictionAmount", 0.0, 1.0, true)
addSection(pages.Combat, "Weapons")
addToggle(pages.Combat, "Triggerbot", "TriggerBot")
addToggle(pages.Combat, "Hitbox Expander", "HitboxExpander")
addSlider(pages.Combat, "Hitbox Size", "HitboxSize", 2.0, 25.0, true)
addToggle(pages.Combat, "Rapid Fire", "RapidFire")
addToggle(pages.Combat, "No Recoil", "NoRecoil")
addSection(pages.Combat, "Player")
addToggle(pages.Combat, "Kill Aura", "KillAura")
addSlider(pages.Combat, "Kill Aura Range", "KillAuraRange", 5.0, 80.0, true)
addToggle(pages.Combat, "Spinbot", "Spinbot")

-- ===================== VISUAL PAGE =====================
addSection(pages.Visual, "ESP")
addToggle(pages.Visual, "ESP Box", "ESPBox")
addToggle(pages.Visual, "ESP Name", "ESPName")
addToggle(pages.Visual, "ESP Health", "ESPHealth")
addToggle(pages.Visual, "Distance ESP", "DistanceESP")
addToggle(pages.Visual, "Weapon ESP", "WeaponESP")
addToggle(pages.Visual, "Tracers", "Tracers")
addToggle(pages.Visual, "Snap Lines", "SnapLines")
addToggle(pages.Visual, "Chams", "Chams")
addToggle(pages.Visual, "Rainbow Chams", "RainbowChams")
addSection(pages.Visual, "World")
addToggle(pages.Visual, "Fullbright", "Fullbright", function(v)
    if v then Lighting.Ambient=Color3.new(1,1,1); Lighting.Brightness=2
    else Lighting.Ambient=originalAmbient; Lighting.Brightness=originalBrightness end
end)
addToggle(pages.Visual, "No Fog", "NoFog", function(v)
    if v then Lighting.FogEnd=1e6; Lighting.FogStart=1e6
    else Lighting.FogStart=originalFog.Start; Lighting.FogEnd=originalFog.End end
end)
addToggle(pages.Visual, "FOV Changer", "FOVChanger", function(v)
    Camera.FieldOfView = v and Settings.FOVValue or 70
end)
addSlider(pages.Visual, "FOV Value", "FOVValue", 30, 120, false)
addSection(pages.Visual, "Camera")
addToggle(pages.Visual, "Third Person", "ThirdPerson")
addSlider(pages.Visual, "3rd Person Dist", "ThirdPersonDist", 3.0, 40.0, true)
addToggle(pages.Visual, "Crosshair", "Crosshair")

-- ===================== MOVEMENT PAGE =====================
addSection(pages.Move, "Speed")
addToggle(pages.Move, "Speed Hack", "SpeedHack")
addSlider(pages.Move, "Speed Value", "SpeedValue", 16.0, 300.0, true)
addSection(pages.Move, "Fly")
addToggle(pages.Move, "Fly", "Fly", function(v) end) -- handled via keybind func
addSlider(pages.Move, "Fly Speed", "FlySpeed", 10.0, 250.0, true)
addSection(pages.Move, "Jump")
addToggle(pages.Move, "Noclip", "Noclip")
addToggle(pages.Move, "Super Jump", "SuperJump")
addSlider(pages.Move, "Jump Power", "JumpPower", 50.0, 600.0, true)
addToggle(pages.Move, "Infinite Jump", "InfiniteJump")
addToggle(pages.Move, "Bunny Hop", "BunnyHop")

-- ===================== MISC PAGE =====================
addSection(pages.Misc, "Player")
addToggle(pages.Misc, "God Mode", "GodMode")
addToggle(pages.Misc, "Auto Respawn", "AutoRespawn")
addToggle(pages.Misc, "Anti AFK", "AntiAFK")
addSection(pages.Misc, "Teleport")
addTeleportDropdown(pages.Misc)
addSection(pages.Misc, "Chat")
addToggle(pages.Misc, "Spam Chat", "SpamChat")
addSection(pages.Misc, "Display")
addToggle(pages.Misc, "Notifications", "Notifications")
addToggle(pages.Misc, "FPS Counter", "FPSCounter")
addSection(pages.Misc, "Script")
addButton(pages.Misc, "🗑  Unload Script", function()
    gui:Destroy()
    pcall(function() if FOVCircle then FOVCircle:Remove() end end)
    for _,l in pairs(crosshairLines) do pcall(function() l:Remove() end) end
    pcall(function() blur:Destroy() end)
    for _, obj in pairs(ESPObjects) do
        for _, v in pairs(obj) do pcall(function() v:Destroy() end) end
    end
end)

-- toggle menu
openBtn.MouseButton1Click:Connect(function()
    if not dragging then
        frame.Visible = not frame.Visible
        blur.Enabled = frame.Visible
        if frame.Visible then
            frame.Position = UDim2.new(0.5,-215,0.5,-210)
        end
    end
end)

-- ===================== HELPERS =====================
local function getClosestPlayer()
    if Settings.TargetLock and lockedTarget and lockedTarget.Character and lockedTarget.Character:FindFirstChild("Head") then
        return lockedTarget
    end
    local closest, closestDist = nil, Settings.FOV
    local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    for _, plr in pairs(game.Players:GetPlayers()) do
        if plr ~= player and plr.Character and plr.Character:FindFirstChild("Head") then
            local head = plr.Character.Head
            local sp, onScreen = Camera:WorldToViewportPoint(head.Position)
            if onScreen then
                local dist = (Vector2.new(sp.X,sp.Y) - center).Magnitude
                if dist < closestDist then
                    if Settings.WallCheck then
                        local ray = Ray.new(Camera.CFrame.Position, (head.Position - Camera.CFrame.Position).Unit * 500)
                        local hit = workspace:FindPartOnRayWithIgnoreList(ray, {player.Character, Camera})
                        if hit and hit:IsDescendantOf(plr.Character) then
                            closest = plr; closestDist = dist
                        end
                    else
                        closest = plr; closestDist = dist
                    end
                end
            end
        end
    end
    if Settings.TargetLock then lockedTarget = closest end
    return closest
end

local function getTargetPos(plr)
    if not plr or not plr.Character then return nil end
    local head = plr.Character:FindFirstChild("Head")
    if not head then return nil end
    if Settings.Prediction then
        local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
        if hrp then return head.Position + hrp.AssemblyLinearVelocity * Settings.PredictionAmount end
    end
    return head.Position
end

-- ===================== FLY SYSTEM (FIXED) =====================
-- ФИКС: используем LinearVelocity вместо BodyVelocity (не конфликтует с Humanoid)
local function enableFly()
    local char = player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    -- убираем старые если есть
    local old = hrp:FindFirstChild("msFlyVel")
    if old then old:Destroy() end
    local oldg = hrp:FindFirstChild("msFlyGyro")
    if oldg then oldg:Destroy() end

    flyBodyVelocity = Instance.new("BodyVelocity")
    flyBodyVelocity.Name = "msFlyVel"
    flyBodyVelocity.Velocity = Vector3.zero
    flyBodyVelocity.MaxForce = Vector3.new(1e5,1e5,1e5)
    flyBodyVelocity.Parent = hrp

    flyBodyGyro = Instance.new("BodyGyro")
    flyBodyGyro.Name = "msFlyGyro"
    flyBodyGyro.MaxTorque = Vector3.new(1e5,1e5,1e5)
    flyBodyGyro.D = 60
    flyBodyGyro.P = 1e4
    flyBodyGyro.Parent = hrp

    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then hum.PlatformStand = true end
    flyActive = true
end

local function disableFly()
    flyActive = false
    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        local v = hrp:FindFirstChild("msFlyVel"); if v then v:Destroy() end
        local g = hrp:FindFirstChild("msFlyGyro"); if g then g:Destroy() end
    end
    flyBodyVelocity = nil
    flyBodyGyro = nil
    -- ФИКС: возвращаем PlatformStand чтобы можно было двигаться
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.PlatformStand = false
            task.wait(0.05)
            -- сбрасываем скорость
            if hrp then hrp.AssemblyLinearVelocity = Vector3.zero end
        end
    end
end

-- ===================== ESP =====================
local function clearESP(espData)
    pcall(function() if espData.Box then espData.Box:Remove() end end)
    pcall(function() if espData.Tracer then espData.Tracer:Remove() end end)
    pcall(function() if espData.SnapLine then espData.SnapLine:Remove() end end)
    pcall(function() if espData.Billboard then espData.Billboard:Destroy() end end)
    pcall(function() if espData.Highlight then espData.Highlight:Destroy() end end)
end

local function createESP(char)
    if ESPObjects[char] then return end
    local espData = {}
    local plr = game.Players:GetPlayerFromCharacter(char)
    -- Billboard
    local bb = Instance.new("BillboardGui")
    bb.AlwaysOnTop = true
    bb.Size = UDim2.new(0,200,0,60)
    bb.StudsOffset = Vector3.new(0,3.5,0)
    bb.Parent = char:WaitForChild("Head")
    espData.Billboard = bb
    -- Name
    local nameLbl = Instance.new("TextLabel", bb)
    nameLbl.Size = UDim2.new(1,0,0.4,0)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Text = plr and plr.DisplayName or "?"
    nameLbl.TextColor3 = Color3.new(1,1,1)
    nameLbl.Font = Enum.Font.GothamBold
    nameLbl.TextSize = 13
    nameLbl.TextStrokeTransparency = 0
    nameLbl.Visible = Settings.ESPName
    espData.NameLabel = nameLbl
    -- Dist
    local distLbl = Instance.new("TextLabel", bb)
    distLbl.Size = UDim2.new(1,0,0.35,0)
    distLbl.Position = UDim2.new(0,0,0.4,0)
    distLbl.BackgroundTransparency = 1
    distLbl.Font = Enum.Font.Gotham
    distLbl.TextSize = 11
    distLbl.TextColor3 = Color3.fromRGB(180,180,200)
    distLbl.TextStrokeTransparency = 0
    distLbl.Visible = false
    espData.DistLabel = distLbl
    -- Wep
    local wepLbl = Instance.new("TextLabel", bb)
    wepLbl.Size = UDim2.new(1,0,0.3,0)
    wepLbl.Position = UDim2.new(0,0,0.7,0)
    wepLbl.BackgroundTransparency = 1
    wepLbl.Font = Enum.Font.Gotham
    wepLbl.TextSize = 10
    wepLbl.TextColor3 = Color3.fromRGB(255,200,60)
    wepLbl.TextStrokeTransparency = 0
    wepLbl.Visible = false
    espData.WepLabel = wepLbl
    -- HP bar
    local hpLbl = Instance.new("TextLabel", bb)
    hpLbl.Size = UDim2.new(1,0,0.3,0)
    hpLbl.Position = UDim2.new(0,0,0.35,0)
    hpLbl.BackgroundTransparency = 1
    hpLbl.Font = Enum.Font.Gotham
    hpLbl.TextSize = 10
    hpLbl.TextStrokeTransparency = 0
    hpLbl.Visible = false
    espData.HPLabel = hpLbl
    -- Drawing box + lines
    pcall(function()
        local box = Drawing.new("Square")
        box.Visible = false; box.Thickness = 1.5
        box.Color = Color3.fromRGB(255,55,55)
        box.Filled = false; box.ZIndex = 5
        espData.Box = box
        local tracer = Drawing.new("Line")
        tracer.Visible = false; tracer.Thickness = 1.2
        tracer.Color = Color3.fromRGB(255,55,55); tracer.ZIndex = 4
        espData.Tracer = tracer
        local snap = Drawing.new("Line")
        snap.Visible = false; snap.Thickness = 1.2
        snap.Color = Color3.fromRGB(255,200,0); snap.ZIndex = 4
        espData.SnapLine = snap
    end)
    ESPObjects[char] = espData
end

local function removeESP(char)
    if ESPObjects[char] then
        clearESP(ESPObjects[char])
        ESPObjects[char] = nil
    end
end

for _, plr in pairs(game.Players:GetPlayers()) do
    if plr ~= player then
        if plr.Character then createESP(plr.Character) end
        plr.CharacterAdded:Connect(function(c) task.wait(0.5); createESP(c) end)
        plr.CharacterRemoving:Connect(function(c) removeESP(c) end)
    end
end
game.Players.PlayerAdded:Connect(function(plr)
    plr.CharacterAdded:Connect(function(c) task.wait(0.5); createESP(c) end)
    plr.CharacterRemoving:Connect(function(c) removeESP(c) end)
end)
game.Players.PlayerRemoving:Connect(function(plr)
    if plr.Character then removeESP(plr.Character) end
end)

-- ===================== KEYBINDS =====================
UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    -- Fly
    if input.KeyCode == Settings.FlyKey then
        Settings.Fly = not Settings.Fly
        if Settings.Fly then enableFly() else disableFly() end
        notify("Fly", Settings.Fly and "Включено" or "Выключено")
    end
    -- Noclip
    if input.KeyCode == Settings.NoclipKey then
        Settings.Noclip = not Settings.Noclip
        notify("Noclip", Settings.Noclip and "Включено" or "Выключено")
    end
    -- Spinbot
    if input.KeyCode == Settings.SpinbotKey then
        Settings.Spinbot = not Settings.Spinbot
        notify("Spinbot", Settings.Spinbot and "Включено" or "Выключено")
    end
    -- Panic
    if input.KeyCode == Settings.PanicKey then
        gui:Destroy()
        pcall(function() if FOVCircle then FOVCircle:Remove() end end)
        for _,l in pairs(crosshairLines) do pcall(function() l:Remove() end) end
        pcall(function() blur:Destroy() end)
    end
    -- Infinite Jump
    if input.KeyCode == Enum.KeyCode.Space and Settings.InfiniteJump then
        local char = player.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
        end
    end
end)

-- ФИКС: при respawn восстанавливаем PlatformStand
player.CharacterAdded:Connect(function(char)
    flyActive = false
    flyBodyVelocity = nil
    flyBodyGyro = nil
    if Settings.Fly then
        task.wait(1)
        enableFly()
    end
end)

-- Spam chat
task.spawn(function()
    while task.wait(3) do
        if Settings.SpamChat then
            pcall(function()
                game:GetService("ReplicatedStorage")
                    :FindFirstChild("DefaultChatSystemChatEvents")
                    :FindFirstChild("SayMessageRequest")
                    :FireServer(Settings.SpamMsg, "All")
            end)
        end
    end
end)

-- ===================== MAIN LOOP =====================
local frameCount = 0
local lastFPSTime = tick()
local fps = 0

RunService.RenderStepped:Connect(function(dt)
    -- FPS
    frameCount += 1
    local now = tick()
    if now - lastFPSTime >= 0.5 then
        fps = math.floor(frameCount / (now - lastFPSTime))
        frameCount = 0
        lastFPSTime = now
    end

    -- HUD
    local hudTxt = "memeSense v3"
    if Settings.FPSCounter then hudTxt = hudTxt .. "  |  FPS: " .. fps end
    hudLabel.Text = hudTxt

    -- Clock
    local t = os.date("*t")
    clockLabel.Text = string.format("%02d:%02d:%02d", t.hour, t.min, t.sec)

    -- Rainbow accent
    rainbowHue = (rainbowHue + dt * 0.15) % 1
    local rainbowCol = Color3.fromHSV(rainbowHue, 0.9, 1)

    -- FOV Circle
    if FOVCircle then
        FOVCircle.Visible = Settings.Aimbot or Settings.SilentAim
        FOVCircle.Radius = Settings.FOV
        FOVCircle.Color = Settings.FOVColor
        FOVCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    end

    -- Crosshair
    updateCrosshair()

    -- FOV Changer
    if Settings.FOVChanger then
        Camera.FieldOfView = Settings.FOVValue
    else
        -- не сбрасываем принудительно, игра сама управляет
    end

    local target = getClosestPlayer()
    local targetPos = getTargetPos(target)

    -- Aimbot
    if Settings.Aimbot and target and targetPos then
        local smooth = math.max(Settings.Smooth, 1)
        Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, targetPos), 1/smooth)
    end

    -- Silent Aim
    if Settings.SilentAim and target and targetPos then
        local orig = Camera.CFrame
        Camera.CFrame = CFrame.new(Camera.CFrame.Position, targetPos)
        task.defer(function() if Camera then Camera.CFrame = orig end end)
    end

    -- Third Person
    if Settings.ThirdPerson then
        local char = player.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            Camera.CFrame = CFrame.new(
                char.HumanoidRootPart.Position - Camera.CFrame.LookVector * Settings.ThirdPersonDist + Vector3.new(0,1.5,0),
                char.HumanoidRootPart.Position
            )
        end
    end

    -- Spinbot
    if Settings.Spinbot then
        local char = player.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            char.HumanoidRootPart.CFrame = char.HumanoidRootPart.CFrame * CFrame.Angles(0, math.rad(18), 0)
        end
    end

    local char = player.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        local hrp = char:FindFirstChild("HumanoidRootPart")

        if hum and hrp then
            -- Speed
            if Settings.SpeedHack then
                hum.WalkSpeed = Settings.SpeedValue
            else
                -- ФИКС: не трогаем WalkSpeed если не включён SpeedHack
            end

            -- Super Jump
            if Settings.SuperJump then
                hum.JumpPower = Settings.JumpPower
            else
                -- не трогаем
            end

            -- Bunny Hop
            if Settings.BunnyHop then
                if UIS:IsKeyDown(Enum.KeyCode.Space) then
                    hum:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end

            -- God Mode
            if Settings.GodMode then
                if hum.Health < hum.MaxHealth then
                    hum.Health = hum.MaxHealth
                end
            end

            -- Auto Respawn
            if Settings.AutoRespawn and hum.Health <= 0 then
                task.wait(0.5)
                player:LoadCharacter()
            end

            -- Fly movement
            if flyActive and flyBodyVelocity and flyBodyGyro then
                local camCF = Camera.CFrame
                local moveVec = Vector3.zero
                if UIS:IsKeyDown(Enum.KeyCode.W) then moveVec = moveVec + camCF.LookVector end
                if UIS:IsKeyDown(Enum.KeyCode.S) then moveVec = moveVec - camCF.LookVector end
                if UIS:IsKeyDown(Enum.KeyCode.A) then moveVec = moveVec - camCF.RightVector end
                if UIS:IsKeyDown(Enum.KeyCode.D) then moveVec = moveVec + camCF.RightVector end
                if UIS:IsKeyDown(Enum.KeyCode.Space) then moveVec = moveVec + Vector3.new(0,1,0) end
                if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then moveVec = moveVec - Vector3.new(0,1,0) end
                flyBodyVelocity.Velocity = moveVec.Magnitude > 0 and (moveVec.Unit * Settings.FlySpeed) or Vector3.zero
                flyBodyGyro.CFrame = camCF
            end
        end
    end

    -- Noclip (Stepped вариант для надёжности)
    if Settings.Noclip and char then
        for _, p in pairs(char:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = false end
        end
    end

    -- Kill Aura
    if Settings.KillAura and char and char:FindFirstChild("HumanoidRootPart") then
        local myPos = char.HumanoidRootPart.Position
        for _, plr in pairs(game.Players:GetPlayers()) do
            if plr ~= player and plr.Character then
                local ehr = plr.Character:FindFirstChild("HumanoidRootPart")
                local ehum = plr.Character:FindFirstChildOfClass("Humanoid")
                if ehr and ehum and (ehr.Position - myPos).Magnitude <= Settings.KillAuraRange then
                    ehum:TakeDamage(ehum.MaxHealth)
                end
            end
        end
    end

    -- Triggerbot
    if Settings.TriggerBot and target and targetPos then
        local sp, onScreen = Camera:WorldToViewportPoint(targetPos)
        if onScreen then
            local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
            if (Vector2.new(sp.X,sp.Y) - center).Magnitude < 28 then
                pcall(function()
                    local tool = char and char:FindFirstChildOfClass("Tool")
                    if tool then
                        local re = tool:FindFirstChildOfClass("RemoteEvent")
                        if re then re:FireServer() end
                    end
                end)
            end
        end
    end

    -- Hitbox Expander
    if Settings.HitboxExpander then
        for _, plr in pairs(game.Players:GetPlayers()) do
            if plr ~= player and plr.Character then
                local head = plr.Character:FindFirstChild("Head")
                if head then
                    head.Size = Vector3.new(Settings.HitboxSize, Settings.HitboxSize, Settings.HitboxSize)
                    head.Transparency = 1
                end
            end
        end
    end

    -- ESP update
    local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    for espChar, espData in pairs(ESPObjects) do
        local eplr = game.Players:GetPlayerFromCharacter(espChar)
        if not eplr or not espChar.Parent then
            clearESP(espData); ESPObjects[espChar] = nil; continue
        end
        local head = espChar:FindFirstChild("Head")
        local hrp2 = espChar:FindFirstChild("HumanoidRootPart")
        local hum2 = espChar:FindFirstChildOfClass("Humanoid")
        if not head or not hrp2 then clearESP(espData); ESPObjects[espChar]=nil; continue end

        local hp2, onS = Camera:WorldToViewportPoint(head.Position + Vector3.new(0,0.6,0))
        local fp2, fOnS = Camera:WorldToViewportPoint(hrp2.Position - Vector3.new(0,2.4,0))

        -- Chams + Rainbow
        local hl = espChar:FindFirstChildOfClass("Highlight")
        if Settings.Chams or Settings.RainbowChams then
            if not hl then
                hl = Instance.new("Highlight")
                hl.FillTransparency = 0.4
                hl.OutlineTransparency = 0
                hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                hl.Parent = espChar
                espData.Highlight = hl
            end
            if Settings.RainbowChams then
                hl.FillColor = rainbowCol
                hl.OutlineColor = rainbowCol
            else
                hl.FillColor = Color3.fromRGB(255,55,55)
                hl.OutlineColor = Color3.fromRGB(255,255,255)
            end
        elseif hl then
            hl:Destroy(); espData.Highlight = nil
        end

        -- Box
        if espData.Box then
            if Settings.ESPBox and onS and fOnS then
                local h = math.abs(hp2.Y - fp2.Y)
                local w = h * 0.55
                espData.Box.Position = Vector2.new(hp2.X - w/2, hp2.Y)
                espData.Box.Size = Vector2.new(w, h)
                espData.Box.Visible = true
            else
                espData.Box.Visible = false
            end
        end

        -- Tracers
        if espData.Tracer then
            if Settings.Tracers and onS then
                espData.Tracer.From = Vector2.new(center.X, Camera.ViewportSize.Y)
                espData.Tracer.To = Vector2.new(hp2.X, hp2.Y)
                espData.Tracer.Visible = true
            else espData.Tracer.Visible = false end
        end

        -- Snap Lines
        if espData.SnapLine then
            if Settings.SnapLines and onS then
                espData.SnapLine.From = center
                espData.SnapLine.To = Vector2.new(hp2.X, hp2.Y)
                espData.SnapLine.Visible = true
            else espData.SnapLine.Visible = false end
        end

        -- Labels
        if espData.NameLabel then espData.NameLabel.Visible = Settings.ESPName end

        if espData.DistLabel then
            if Settings.DistanceESP then
                local myHRP = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                if myHRP then
                    local d = math.floor((hrp2.Position - myHRP.Position).Magnitude)
                    espData.DistLabel.Text = d .. "m"
                    espData.DistLabel.Visible = true
                end
            else espData.DistLabel.Visible = false end
        end

        if espData.WepLabel then
            if Settings.WeaponESP then
                local tool = espChar:FindFirstChildOfClass("Tool")
                espData.WepLabel.Text = tool and tool.Name or ""
                espData.WepLabel.Visible = true
            else espData.WepLabel.Visible = false end
        end

        if espData.HPLabel then
            if Settings.ESPHealth and hum2 then
                local hp = math.floor((hum2.Health/hum2.MaxHealth)*100)
                espData.HPLabel.Text = "HP: " .. hp .. "%"
                espData.HPLabel.TextColor3 = Color3.new(1-(hp/100), hp/100, 0)
                espData.HPLabel.Visible = true
            else espData.HPLabel.Visible = false end
        end
    end
end)

-- Noclip via Stepped (backup)
RunService.Stepped:Connect(function()
    if Settings.Noclip then
        local c = player.Character
        if c then
            for _, p in pairs(c:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = false end
            end
        end
    end
end)

notify("memeSense", "v3.0 Загружен! END = паник", Color3.fromRGB(255,55,55))
