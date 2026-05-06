local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Lighting = game:GetService("Lighting")
local Camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local Settings = {
    -- Combat
    Aimbot = false,
    FireCheck = false,
    WallCheck = false,
    AutoFire = false,
    FOV = 93,
    FOVColor = Color3.fromRGB(255,60,60),
    Smooth = 18.0,
    SilentAim = false,
    TriggerBot = false,
    HitboxExpander = false,
    HitboxSize = 6.0,
    NoRecoil = false,
    NoSpread = false,
    RapidFire = false,
    Spinbot = false,
    TargetLock = false,
    Prediction = false,
    PredictionAmount = 0.12,
    KillAura = false,
    KillAuraRange = 15.0,
    -- Visual
    ESPBox = false,
    ESPName = false,
    Chams = false,
    ESPHealth = false,
    Tracers = false,
    SkeletonESP = false,
    DistanceESP = false,
    WeaponESP = false,
    SnapLines = false,
    Fullbright = false,
    NoFog = false,
    FOVChanger = false,
    FOVValue = 70,
    ThirdPerson = false,
    ThirdPersonDist = 8.0,
    -- Movement
    SpeedHack = false,
    SpeedValue = 32.0,
    Fly = false,
    FlySpeed = 50.0,
    Noclip = false,
    SuperJump = false,
    JumpPower = 100.0,
    InfiniteJump = false,
    AutoSprint = false,
    NoSlowdown = false,
    NoFallDamage = false,
    BunnyHop = false,
    StrafeHelper = false,
    -- Misc
    GodMode = false,
    InfiniteAmmo = false,
    SpinbotKey = Enum.KeyCode.X,
    FlyKey = Enum.KeyCode.F,
    NoclipKey = Enum.KeyCode.N,
    Notifications = true,
    FPSCounter = false,
    PingDisplay = false,
    AutoRespawn = false,
    PanicKey = Enum.KeyCode.End,
    SpeedKey = Enum.KeyCode.LeftShift,
    SpamChat = false,
    SpamMsg = "memeSense",
}

-- Notification system
local notifFrame = Instance.new("Frame")
notifFrame.Size = UDim2.new(0,280,1,0)
notifFrame.Position = UDim2.new(1,-290,0,0)
notifFrame.BackgroundTransparency = 1
notifFrame.Parent = nil -- parented after gui created

local function notify(title, msg, color)
    if not Settings.Notifications then return end
    color = color or Color3.fromRGB(255,50,50)
    local n = Instance.new("Frame", notifFrame)
    n.Size = UDim2.new(1,0,0,60)
    n.Position = UDim2.new(0,0,1,10)
    n.BackgroundColor3 = Color3.fromRGB(25,25,25)
    n.BorderSizePixel = 0
    local nc = Instance.new("UICorner",n) nc.CornerRadius = UDim.new(0,10)
    local accent = Instance.new("Frame",n)
    accent.Size = UDim2.new(0,4,1,0)
    accent.BackgroundColor3 = color
    accent.BorderSizePixel=0
    local ac2 = Instance.new("UICorner",accent) ac2.CornerRadius=UDim.new(0,4)
    local t1 = Instance.new("TextLabel",n)
    t1.Position = UDim2.new(0,14,0,8)
    t1.Size = UDim2.new(1,-18,0,20)
    t1.BackgroundTransparency=1
    t1.Text = title
    t1.Font = Enum.Font.GothamBold
    t1.TextSize = 14
    t1.TextColor3 = color
    t1.TextXAlignment = Enum.TextXAlignment.Left
    local t2 = Instance.new("TextLabel",n)
    t2.Position = UDim2.new(0,14,0,28)
    t2.Size = UDim2.new(1,-18,0,20)
    t2.BackgroundTransparency=1
    t2.Text = msg
    t2.Font = Enum.Font.Gotham
    t2.TextSize = 13
    t2.TextColor3 = Color3.fromRGB(180,180,180)
    t2.TextXAlignment = Enum.TextXAlignment.Left
    TweenService:Create(n, TweenInfo.new(0.3), {Position=UDim2.new(0,0,1,-70)}):Play()
    task.delay(3, function()
        TweenService:Create(n, TweenInfo.new(0.3), {Position=UDim2.new(0,0,1,10)}):Play()
        task.wait(0.35)
        n:Destroy()
    end)
end

local ESPObjects = {}
local FOVCircle = nil
local flyBodyVelocity = nil
local flyBodyGyro = nil
local flyActive = false
local lockedTarget = nil
local spinActive = false
local originalFog = {Start=Lighting.FogStart, End=Lighting.FogEnd, Color=Lighting.FogColor}
local originalAmbient = Lighting.Ambient
local originalBrightness = Lighting.Brightness

pcall(function()
    FOVCircle = Drawing.new("Circle")
    FOVCircle.Thickness = 2
    FOVCircle.NumSides = 64
    FOVCircle.Radius = Settings.FOV
    FOVCircle.Filled = false
    FOVCircle.Visible = false
    FOVCircle.ZIndex = 999
    FOVCircle.Transparency = 1
    FOVCircle.Color = Settings.FOVColor
end)

local blur = Instance.new("BlurEffect")
blur.Size = 22
blur.Parent = Lighting
blur.Enabled = false

local gui = Instance.new("ScreenGui")
gui.Name = "memeSenseGUI"
gui.Parent = playerGui
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false

notifFrame.Parent = gui
notifFrame.Size = UDim2.new(0,280,0.6,0)
notifFrame.Position = UDim2.new(1,-290,0.2,0)

-- HUD (FPS/Ping)
local hudLabel = Instance.new("TextLabel", gui)
hudLabel.Position = UDim2.new(0,8,0,8)
hudLabel.Size = UDim2.new(0,200,0,40)
hudLabel.BackgroundTransparency=1
hudLabel.Font = Enum.Font.GothamBold
hudLabel.TextSize = 14
hudLabel.TextColor3 = Color3.fromRGB(255,50,50)
hudLabel.TextXAlignment = Enum.TextXAlignment.Left
hudLabel.Text = ""

-- Tracer lines (Drawing)
local tracerLines = {}
local snapLines = {}

local openBtn = Instance.new("TextButton")
openBtn.Name = "DragOpenBtn"
openBtn.Size = UDim2.new(0,56,0,56)
openBtn.Position = UDim2.new(0,24,1,-88)
openBtn.BackgroundColor3 = Color3.fromRGB(255,60,60)
openBtn.Text = "MENU"
openBtn.Font = Enum.Font.GothamBold
openBtn.TextColor3 = Color3.new(1,1,1)
openBtn.TextSize = 15
openBtn.AutoButtonColor = true
openBtn.Parent = gui
local btnCorner = Instance.new("UICorner", openBtn)
btnCorner.CornerRadius = UDim.new(1,0)

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
            0, math.clamp(startPos.X.Offset + delta.X, 0, (gui.AbsoluteSize.X or 800) - 56),
            0, math.clamp(startPos.Y.Offset + delta.Y, 0, (gui.AbsoluteSize.Y or 500) - 56)
        )
    end
end)

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 400, 0, 380)
frame.Position = UDim2.new(0.5, -200, 0.5, -190)
frame.BackgroundColor3 = Color3.fromRGB(20,20,20)
frame.Visible = false
frame.Parent = gui
frame.Active = true
frame.Draggable = true
local menuCorner = Instance.new("UICorner", frame)
menuCorner.CornerRadius = UDim.new(0, 14)

local titleRed = Instance.new("TextLabel", frame)
titleRed.Size = UDim2.new(0, 130, 0, 35)
titleRed.Position = UDim2.new(0, 18, 0, 10)
titleRed.BackgroundTransparency = 1
titleRed.Text = "meme"
titleRed.Font = Enum.Font.GothamBlack
titleRed.TextSize = 30
titleRed.TextColor3 = Color3.fromRGB(255, 50, 50)
titleRed.TextXAlignment = Enum.TextXAlignment.Left

local titleWhite = Instance.new("TextLabel", frame)
titleWhite.Size = UDim2.new(0, 150, 0, 35)
titleWhite.Position = UDim2.new(0, 118, 0, 10)
titleWhite.BackgroundTransparency = 1
titleWhite.Text = "sense"
titleWhite.Font = Enum.Font.GothamBlack
titleWhite.TextSize = 30
titleWhite.TextColor3 = Color3.new(1,1,1)
titleWhite.TextXAlignment = Enum.TextXAlignment.Left

local tabHolder = Instance.new("Frame", frame)
tabHolder.Size = UDim2.new(1, -36, 0, 38)
tabHolder.Position = UDim2.new(0, 18, 0, 50)
tabHolder.BackgroundTransparency = 1
local tabLayout = Instance.new("UIListLayout", tabHolder)
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.Padding = UDim.new(0, 8)
tabLayout.VerticalAlignment = Enum.VerticalAlignment.Center

local tabs = {
    {Title="Combat", Key="Combat"},
    {Title="Visual", Key="Visual"},
    {Title="Movement", Key="Movement"},
    {Title="Misc", Key="Misc"},
    {Title="Setting", Key="Setting"},
}

local pages = {}
local tabBtns = {}

for i,tabData in pairs(tabs) do
    local t = Instance.new("TextButton")
    t.Size = UDim2.new(0,72,1,0)
    t.BackgroundColor3 = (i==1) and Color3.fromRGB(255,50,50) or Color3.fromRGB(40,40,40)
    t.TextColor3 = (i==1) and Color3.new(1,1,1) or Color3.fromRGB(180,180,180)
    t.Font = Enum.Font.GothamBold
    t.Text = tabData.Title
    t.TextSize = 13
    t.Parent = tabHolder
    tabBtns[tabData.Key] = t
    local corner = Instance.new("UICorner", t)
    corner.CornerRadius = UDim.new(1,0)
end

local content = Instance.new("Frame", frame)
content.Size = UDim2.new(1, -36, 1, -100)
content.Position = UDim2.new(0, 18, 0, 95)
content.BackgroundColor3 = Color3.fromRGB(30,30,30)
content.BorderSizePixel = 0
local contentCorner = Instance.new("UICorner", content)
contentCorner.CornerRadius = UDim.new(0,12)
content.ClipsDescendants = true

local function createPage()
    local sc = Instance.new("ScrollingFrame")
    sc.Size = UDim2.new(1,0,1,0)
    sc.BackgroundTransparency = 1
    sc.BorderSizePixel = 0
    sc.ScrollBarThickness = 4
    sc.ScrollBarImageColor3 = Color3.fromRGB(255,50,50)
    sc.CanvasSize = UDim2.new(0,0,2,0)
    sc.AutomaticCanvasSize = Enum.AutomaticSize.Y
    sc.Visible = false
    sc.Parent = content
    local lay = Instance.new("UIListLayout", sc)
    lay.Padding = UDim.new(0,8)
    lay.HorizontalAlignment = Enum.HorizontalAlignment.Left
    local pad = Instance.new("UIPadding", sc)
    pad.PaddingTop = UDim.new(0,8)
    pad.PaddingLeft = UDim.new(0,6)
    pad.PaddingRight = UDim.new(0,6)
    return sc
end

for _,tab in pairs(tabs) do
    pages[tab.Key] = createPage()
end
pages["Combat"].Visible = true

for key,btn in pairs(tabBtns) do
    btn.MouseButton1Click:Connect(function()
        for n,page in pairs(pages) do page.Visible=false tabBtns[n].BackgroundColor3=Color3.fromRGB(40,40,40) tabBtns[n].TextColor3=Color3.fromRGB(180,180,180) end
        pages[key].Visible=true
        btn.BackgroundColor3 = Color3.fromRGB(255,50,50)
        btn.TextColor3 = Color3.new(1,1,1)
    end)
end

-- Section label
local function addSection(page, txt)
    local lbl = Instance.new("TextLabel", page)
    lbl.Size = UDim2.new(1,-12,0,22)
    lbl.BackgroundTransparency=1
    lbl.Text = "— "..txt.." —"
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 12
    lbl.TextColor3 = Color3.fromRGB(255,50,50)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
end

local function addToggle(page, txt, settingKey, cb)
    local holder = Instance.new("Frame", page)
    holder.Size = UDim2.new(1,-12,0,36)
    holder.BackgroundColor3 = Color3.fromRGB(40,40,40)
    holder.BorderSizePixel=0
    local cor = Instance.new("UICorner", holder) cor.CornerRadius = UDim.new(0,8)
    local lbl = Instance.new("TextLabel", holder)
    lbl.AnchorPoint = Vector2.new(0,0.5)
    lbl.Position = UDim2.new(0,12,0.5,0)
    lbl.Size = UDim2.new(1,-60,1,-8)
    lbl.BackgroundTransparency = 1
    lbl.Text = txt
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 15
    lbl.TextColor3 = Color3.fromRGB(215,215,215)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    local tog = Instance.new("TextButton", holder)
    tog.Size = UDim2.new(0,34,0,20)
    tog.AnchorPoint = Vector2.new(1,0.5)
    tog.Position = UDim2.new(1,-14,0.5,0)
    tog.BackgroundColor3 = Settings[settingKey] and Color3.fromRGB(255,50,50) or Color3.fromRGB(80,80,80)
    local togCor = Instance.new("UICorner", tog) togCor.CornerRadius = UDim.new(1,0)
    tog.Text = ""
    local dot = Instance.new("Frame", tog)
    dot.Size = UDim2.new(0,12,0,12)
    dot.Position = UDim2.new(Settings[settingKey] and 1 or 0, Settings[settingKey] and -16 or 4,0.5,-6)
    dot.BackgroundColor3 = Color3.new(1,1,1)
    local dotCor = Instance.new("UICorner", dot) dotCor.CornerRadius = UDim.new(1,0)
    tog.MouseButton1Click:Connect(function()
        Settings[settingKey] = not Settings[settingKey]
        tog.BackgroundColor3 = Settings[settingKey] and Color3.fromRGB(255,50,50) or Color3.fromRGB(80,80,80)
        dot.Position = UDim2.new(Settings[settingKey] and 1 or 0, Settings[settingKey] and -16 or 4,0.5,-6)
        if cb then cb(Settings[settingKey]) end
        notify(txt, Settings[settingKey] and "Enabled" or "Disabled", Settings[settingKey] and Color3.fromRGB(255,50,50) or Color3.fromRGB(120,120,120))
    end)
end

local function addSlider(page, name, settingKey, min, max, decimals)
    local holder = Instance.new("Frame", page)
    holder.Size = UDim2.new(1,-12,0,38)
    holder.BackgroundColor3 = Color3.fromRGB(40,40,40)
    holder.BorderSizePixel=0
    local cor = Instance.new("UICorner", holder) cor.CornerRadius = UDim.new(0,8)
    local lbl = Instance.new("TextLabel", holder)
    lbl.Position = UDim2.new(0,12,0,0)
    lbl.Size = UDim2.new(0.45,0,1,0)
    lbl.BackgroundTransparency = 1
    lbl.Text = name
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 15
    lbl.TextColor3 = Color3.fromRGB(215,215,215)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    local valLbl = Instance.new("TextLabel", holder)
    valLbl.AnchorPoint = Vector2.new(1,0)
    valLbl.Position = UDim2.new(1,-16,0,0)
    valLbl.Size = UDim2.new(0.25,0,1,0)
    valLbl.BackgroundTransparency = 1
    valLbl.Text = decimals and string.format("%.1f", Settings[settingKey]) or tostring(Settings[settingKey])
    valLbl.Font = Enum.Font.GothamBold
    valLbl.TextSize = 15
    valLbl.TextColor3 = Color3.fromRGB(255, 60, 60)
    valLbl.TextXAlignment = Enum.TextXAlignment.Right
    local bar = Instance.new("Frame", holder)
    bar.Position = UDim2.new(0.5,12,1,-14)
    bar.Size = UDim2.new(0.47,-24,0,6)
    bar.BackgroundColor3 = Color3.fromRGB(60,60,80)
    local barCor = Instance.new("UICorner", bar) barCor.CornerRadius = UDim.new(1,0)
    local fill = Instance.new("Frame", bar)
    fill.BackgroundColor3 = Color3.fromRGB(255,60,60)
    fill.Size = UDim2.new((Settings[settingKey]-min)/(max-min),0,1,0)
    fill.BorderSizePixel=0
    local fillCor = Instance.new("UICorner", fill) fillCor.CornerRadius = UDim.new(1,0)
    local sdrag = false
    local function update(newVal)
        Settings[settingKey] = math.clamp(newVal,min,max)
        valLbl.Text = decimals and string.format("%.1f", Settings[settingKey]) or tostring(math.floor(Settings[settingKey]))
        fill.Size = UDim2.new((Settings[settingKey]-min)/(max-min),0,1,0)
    end
    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            sdrag = true
        end
    end)
    UIS.InputChanged:Connect(function(input)
        if sdrag and bar.AbsoluteSize.X > 0 then
            local rel = math.clamp((input.Position.X-bar.AbsolutePosition.X)/bar.AbsoluteSize.X, 0, 1)
            update(rel*(max-min)+min)
        end
    end)
    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            sdrag = false
        end
    end)
end

local function addColorBtn(page, name, settingKey)
    local holder = Instance.new("Frame", page)
    holder.Size = UDim2.new(1,-12,0,36)
    holder.BackgroundColor3 = Color3.fromRGB(40,40,40)
    holder.BorderSizePixel=0
    local cor = Instance.new("UICorner", holder) cor.CornerRadius = UDim.new(0,8)
    local lbl = Instance.new("TextLabel", holder)
    lbl.Position = UDim2.new(0,12,0,0)
    lbl.Size = UDim2.new(0.75,0,1,0)
    lbl.BackgroundTransparency = 1
    lbl.Text = name
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 15
    lbl.TextColor3 = Color3.fromRGB(215,215,215)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    local clrBtn = Instance.new("TextButton", holder)
    clrBtn.Size = UDim2.new(0,32,0,22)
    clrBtn.AnchorPoint = Vector2.new(1,0.5)
    clrBtn.Position = UDim2.new(1,-14,0.5,0)
    clrBtn.BackgroundColor3 = Settings[settingKey]
    clrBtn.Text = ""
    local cor2 = Instance.new("UICorner", clrBtn) cor2.CornerRadius = UDim.new(1,0)
    local i = 1
    local colors = {
        Color3.fromRGB(255,60,60),
        Color3.fromRGB(60,100,255),
        Color3.fromRGB(60,255,110),
        Color3.fromRGB(255,200,40),
        Color3.fromRGB(180,40,220),
        Color3.fromRGB(255,255,255)
    }
    clrBtn.MouseButton1Click:Connect(function()
        i = i%#colors+1
        Settings[settingKey] = colors[i]
        clrBtn.BackgroundColor3 = colors[i]
    end)
end

-- ==================== COMBAT PAGE ====================
addSection(pages.Combat, "Aimbot")
addToggle(pages.Combat, "Aimbot", "Aimbot")
addToggle(pages.Combat, "Silent Aim", "SilentAim")
addToggle(pages.Combat, "Target Lock", "TargetLock")
addToggle(pages.Combat, "Triggerbot", "TriggerBot")
addToggle(pages.Combat, "FireCheck", "FireCheck")
addToggle(pages.Combat, "WallCheck", "WallCheck")
addToggle(pages.Combat, "AutoFire", "AutoFire")
addToggle(pages.Combat, "Prediction", "Prediction")
addSlider(pages.Combat, "FOV", "FOV", 30, 350, false)
addSlider(pages.Combat, "Smooth", "Smooth", 0.0, 300.0, true)
addSlider(pages.Combat, "Prediction", "PredictionAmount", 0.0, 1.0, true)
addColorBtn(pages.Combat, "FOV Color", "FOVColor")
addSection(pages.Combat, "Combat")
addToggle(pages.Combat, "Hitbox Expander", "HitboxExpander")
addSlider(pages.Combat, "Hitbox Size", "HitboxSize", 2.0, 20.0, true)
addToggle(pages.Combat, "No Recoil", "NoRecoil")
addToggle(pages.Combat, "No Spread", "NoSpread")
addToggle(pages.Combat, "Rapid Fire", "RapidFire")
addToggle(pages.Combat, "Kill Aura", "KillAura")
addSlider(pages.Combat, "Kill Aura Range", "KillAuraRange", 5.0, 60.0, true)
addToggle(pages.Combat, "Spinbot", "Spinbot")

-- ==================== VISUAL PAGE ====================
addSection(pages.Visual, "ESP")
addToggle(pages.Visual, "ESP Box", "ESPBox")
addToggle(pages.Visual, "ESP Name", "ESPName")
addToggle(pages.Visual, "ESP Healthbar", "ESPHealth")
addToggle(pages.Visual, "Distance ESP", "DistanceESP")
addToggle(pages.Visual, "Weapon ESP", "WeaponESP")
addToggle(pages.Visual, "Chams", "Chams")
addToggle(pages.Visual, "Tracers", "Tracers")
addToggle(pages.Visual, "Snap Lines", "SnapLines")
addToggle(pages.Visual, "Skeleton ESP", "SkeletonESP")
addSection(pages.Visual, "World")
addToggle(pages.Visual, "Fullbright", "Fullbright", function(v)
    if v then
        Lighting.Ambient = Color3.new(1,1,1)
        Lighting.Brightness = 2
    else
        Lighting.Ambient = originalAmbient
        Lighting.Brightness = originalBrightness
    end
end)
addToggle(pages.Visual, "No Fog", "NoFog", function(v)
    if v then
        Lighting.FogEnd = 1e6
        Lighting.FogStart = 1e6
    else
        Lighting.FogStart = originalFog.Start
        Lighting.FogEnd = originalFog.End
        Lighting.FogColor = originalFog.Color
    end
end)
addToggle(pages.Visual, "FOV Changer", "FOVChanger", function(v)
    Camera.FieldOfView = v and Settings.FOVValue or 70
end)
addSlider(pages.Visual, "FOV Value", "FOVValue", 30, 120, false)
addToggle(pages.Visual, "Third Person", "ThirdPerson")
addSlider(pages.Visual, "3rd Person Dist", "ThirdPersonDist", 3.0, 30.0, true)

-- ==================== MOVEMENT PAGE ====================
addSection(pages.Movement, "Speed / Fly")
addToggle(pages.Movement, "Speed Hack", "SpeedHack")
addSlider(pages.Movement, "Speed Value", "SpeedValue", 16.0, 200.0, true)
addToggle(pages.Movement, "Fly", "Fly", function(v)
    local char = player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    if v then
        flyBodyVelocity = Instance.new("BodyVelocity")
        flyBodyVelocity.Velocity = Vector3.zero
        flyBodyVelocity.MaxForce = Vector3.new(1e5,1e5,1e5)
        flyBodyVelocity.Parent = hrp
        flyBodyGyro = Instance.new("BodyGyro")
        flyBodyGyro.MaxTorque = Vector3.new(1e5,1e5,1e5)
        flyBodyGyro.D = 100
        flyBodyGyro.Parent = hrp
        flyActive = true
    else
        flyActive = false
        if flyBodyVelocity then flyBodyVelocity:Destroy() flyBodyVelocity = nil end
        if flyBodyGyro then flyBodyGyro:Destroy() flyBodyGyro = nil end
    end
end)
addSlider(pages.Movement, "Fly Speed", "FlySpeed", 10.0, 200.0, true)
addToggle(pages.Movement, "Noclip", "Noclip")
addSection(pages.Movement, "Jump / Misc")
addToggle(pages.Movement, "Super Jump", "SuperJump")
addSlider(pages.Movement, "Jump Power", "JumpPower", 50.0, 500.0, true)
addToggle(pages.Movement, "Infinite Jump", "InfiniteJump")
addToggle(pages.Movement, "Bunny Hop", "BunnyHop")
addToggle(pages.Movement, "Strafe Helper", "StrafeHelper")
addToggle(pages.Movement, "Auto Sprint", "AutoSprint")
addToggle(pages.Movement, "No Slowdown", "NoSlowdown")
addToggle(pages.Movement, "No Fall Damage", "NoFallDamage")

-- ==================== MISC PAGE ====================
addSection(pages.Misc, "Player")
addToggle(pages.Misc, "God Mode", "GodMode")
addToggle(pages.Misc, "Infinite Ammo", "InfiniteAmmo")
addToggle(pages.Misc, "Auto Respawn", "AutoRespawn")
addToggle(pages.Misc, "Spam Chat", "SpamChat")
addSection(pages.Misc, "Display")
addToggle(pages.Misc, "Notifications", "Notifications")
addToggle(pages.Misc, "FPS Counter", "FPSCounter")
addToggle(pages.Misc, "Ping Display", "PingDisplay")

-- ==================== SETTING PAGE ====================
addSection(pages.Setting, "Info")
local verLbl = Instance.new("TextLabel", pages.Setting)
verLbl.Size = UDim2.new(1,-12,0,30)
verLbl.BackgroundTransparency=1
verLbl.Text = "memeSense v2.0  |  Hotkeys: F=Fly  N=Noclip  END=Panic"
verLbl.Font = Enum.Font.Gotham
verLbl.TextSize = 12
verLbl.TextColor3 = Color3.fromRGB(120,120,120)
verLbl.TextXAlignment = Enum.TextXAlignment.Left

local closeBtn = Instance.new("TextButton", pages.Setting)
closeBtn.Size = UDim2.new(0.6,0,0,34)
closeBtn.BackgroundColor3 = Color3.fromRGB(60,60,60)
closeBtn.Text = "Close Menu"
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 16
closeBtn.TextColor3 = Color3.new(1,1,1)
local closeCor = Instance.new("UICorner", closeBtn) closeCor.CornerRadius = UDim.new(1,0)
closeBtn.MouseButton1Click:Connect(function()
    frame.Visible = false
    blur.Enabled = false
end)

local destroyBtn = Instance.new("TextButton", pages.Setting)
destroyBtn.Size = UDim2.new(0.6,0,0,34)
destroyBtn.BackgroundColor3 = Color3.fromRGB(180,30,30)
destroyBtn.Text = "🗑 Unload Script"
destroyBtn.Font = Enum.Font.GothamBold
destroyBtn.TextSize = 16
destroyBtn.TextColor3 = Color3.new(1,1,1)
local destroyCor = Instance.new("UICorner", destroyBtn) destroyCor.CornerRadius = UDim.new(1,0)
destroyBtn.MouseButton1Click:Connect(function()
    gui:Destroy()
    if FOVCircle then FOVCircle:Remove() end
    blur:Destroy()
    for _, obj in pairs(ESPObjects) do
        for _, v in pairs(obj) do pcall(function() v:Destroy() end) end
    end
end)

openBtn.MouseButton1Click:Connect(function()
    frame.Visible = not frame.Visible
    blur.Enabled = frame.Visible
end)

-- ==================== HELPER FUNCTIONS ====================
local function getClosestPlayer()
    if Settings.TargetLock and lockedTarget and lockedTarget.Character and lockedTarget.Character:FindFirstChild("Head") then
        return lockedTarget
    end
    local closestPlayer, closestDistance = nil, Settings.FOV
    local centerScreen = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    for _, plr in pairs(game.Players:GetPlayers()) do
        if plr ~= player and plr.Character and plr.Character:FindFirstChild("Head") then
            local head = plr.Character.Head
            local screenPos, onScreen = Camera:WorldToViewportPoint(head.Position)
            if onScreen then
                local distance = (Vector2.new(screenPos.X, screenPos.Y) - centerScreen).Magnitude
                if distance < closestDistance then
                    if Settings.WallCheck then
                        local ray = Ray.new(Camera.CFrame.Position, (head.Position - Camera.CFrame.Position).Unit * 500)
                        local hit = workspace:FindPartOnRayWithIgnoreList(ray, {player.Character, Camera})
                        if hit and hit:IsDescendantOf(plr.Character) then
                            closestPlayer = plr
                            closestDistance = distance
                        end
                    else
                        closestPlayer = plr
                        closestDistance = distance
                    end
                end
            end
        end
    end
    if Settings.TargetLock then lockedTarget = closestPlayer end
    return closestPlayer
end

local function getTargetHead(plr)
    if not plr or not plr.Character then return nil end
    local head = plr.Character:FindFirstChild("Head")
    if not head then return nil end
    if Settings.Prediction then
        local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            return head.Position + hrp.AssemblyLinearVelocity * Settings.PredictionAmount
        end
    end
    return head.Position
end

-- ==================== ESP ====================
local function clearDrawings(espData)
    if espData.Box then pcall(function() espData.Box:Remove() end) end
    if espData.Tracer then pcall(function() espData.Tracer:Remove() end) end
    if espData.SnapLine then pcall(function() espData.SnapLine:Remove() end) end
    for _, v in pairs(espData.SkeletonLines or {}) do pcall(function() v:Remove() end) end
end

local function createESP(char)
    if ESPObjects[char] then return end
    local espData = {}
    -- Highlight (chams)
    if Settings.Chams then
        local highlight = Instance.new("Highlight")
        highlight.FillColor = Color3.fromRGB(255, 60, 60)
        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
        highlight.FillTransparency = 0.5
        highlight.OutlineTransparency = 0
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Parent = char
        espData.Highlight = highlight
    end
    -- Hitbox expander
    if Settings.HitboxExpander and char:FindFirstChild("Head") then
        char.Head.Size = Vector3.new(Settings.HitboxSize, Settings.HitboxSize, Settings.HitboxSize)
        char.Head.Transparency = 1
    end
    -- Billboard
    local billboard = Instance.new("BillboardGui")
    billboard.AlwaysOnTop = true
    billboard.Size = UDim2.new(0, 220, 0, 70)
    billboard.StudsOffset = Vector3.new(0, 4, 0)
    billboard.Parent = char:WaitForChild("Head")
    espData.Billboard = billboard
    if Settings.ESPName then
        local nameLabel = Instance.new("TextLabel", billboard)
        nameLabel.Size = UDim2.new(1, 0, 0.45, 0)
        nameLabel.BackgroundTransparency = 1
        local plr = game.Players:GetPlayerFromCharacter(char)
        nameLabel.Text = plr and plr.DisplayName or "?"
        nameLabel.TextColor3 = Color3.new(1, 1, 1)
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextSize = 14
        nameLabel.TextStrokeTransparency = 0
        espData.NameLabel = nameLabel
    end
    if Settings.DistanceESP then
        local distLbl = Instance.new("TextLabel", billboard)
        distLbl.Size = UDim2.new(1,0,0.45,0)
        distLbl.Position = UDim2.new(0,0,0.5,0)
        distLbl.BackgroundTransparency=1
        distLbl.Font = Enum.Font.Gotham
        distLbl.TextSize = 12
        distLbl.TextColor3 = Color3.fromRGB(200,200,200)
        distLbl.TextStrokeTransparency=0
        espData.DistLabel = distLbl
    end
    if Settings.WeaponESP then
        local wepLbl = Instance.new("TextLabel", billboard)
        wepLbl.Size = UDim2.new(1,0,0.45,0)
        wepLbl.Position = UDim2.new(0,0,0.55,0)
        wepLbl.BackgroundTransparency=1
        wepLbl.Font = Enum.Font.Gotham
        wepLbl.TextSize = 11
        wepLbl.TextColor3 = Color3.fromRGB(255,200,50)
        wepLbl.TextStrokeTransparency=0
        espData.WepLabel = wepLbl
    end
    -- Box ESP (Drawing)
    pcall(function()
        local box = Drawing.new("Square")
        box.Visible = false
        box.Thickness = 2
        box.Color = Color3.fromRGB(255,50,50)
        box.Filled = false
        box.ZIndex = 5
        espData.Box = box
        local tracer = Drawing.new("Line")
        tracer.Visible = false
        tracer.Thickness = 1
        tracer.Color = Color3.fromRGB(255,50,50)
        tracer.ZIndex = 4
        espData.Tracer = tracer
        local snapLine = Drawing.new("Line")
        snapLine.Visible = false
        snapLine.Thickness = 1
        snapLine.Color = Color3.fromRGB(255,180,0)
        snapLine.ZIndex = 4
        espData.SnapLine = snapLine
    end)
    ESPObjects[char] = espData
end

local function removeESP(char)
    if ESPObjects[char] then
        clearDrawings(ESPObjects[char])
        for _, obj in pairs(ESPObjects[char]) do
            pcall(function() obj:Destroy() end)
        end
        ESPObjects[char] = nil
    end
end

for _, plr in pairs(game.Players:GetPlayers()) do
    if plr ~= player and plr.Character then createESP(plr.Character) end
    plr.CharacterAdded:Connect(function(char) task.wait(0.5) createESP(char) end)
    plr.CharacterRemoving:Connect(function(char) removeESP(char) end)
end
game.Players.PlayerAdded:Connect(function(plr)
    plr.CharacterAdded:Connect(function(char) task.wait(0.5) createESP(char) end)
    plr.CharacterRemoving:Connect(function(char) removeESP(char) end)
end)
game.Players.PlayerRemoving:Connect(function(plr)
    if plr.Character then removeESP(plr.Character) end
end)

-- ==================== KEYBINDS ====================
UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    -- Fly toggle
    if input.KeyCode == Settings.FlyKey then
        Settings.Fly = not Settings.Fly
        local flyToggleFn = function(v)
            local char = player.Character
            if not char then return end
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            if v then
                flyBodyVelocity = Instance.new("BodyVelocity")
                flyBodyVelocity.Velocity = Vector3.zero
                flyBodyVelocity.MaxForce = Vector3.new(1e5,1e5,1e5)
                flyBodyVelocity.Parent = hrp
                flyBodyGyro = Instance.new("BodyGyro")
                flyBodyGyro.MaxTorque = Vector3.new(1e5,1e5,1e5)
                flyBodyGyro.D = 100
                flyBodyGyro.Parent = hrp
                flyActive = true
            else
                flyActive = false
                if flyBodyVelocity then flyBodyVelocity:Destroy() flyBodyVelocity = nil end
                if flyBodyGyro then flyBodyGyro:Destroy() flyBodyGyro = nil end
            end
        end
        flyToggleFn(Settings.Fly)
        notify("Fly", Settings.Fly and "Enabled" or "Disabled")
    end
    -- Noclip toggle
    if input.KeyCode == Settings.NoclipKey then
        Settings.Noclip = not Settings.Noclip
        notify("Noclip", Settings.Noclip and "Enabled" or "Disabled")
    end
    -- Panic key
    if input.KeyCode == Settings.PanicKey then
        gui:Destroy()
        if FOVCircle then FOVCircle:Remove() end
        blur:Destroy()
        for _, obj in pairs(ESPObjects) do
            for _, v in pairs(obj) do pcall(function() v:Destroy() end) end
        end
    end
    -- Infinite jump
    if input.KeyCode == Enum.KeyCode.Space and Settings.InfiniteJump then
        local char = player.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
        end
    end
end)

-- Spam chat loop
task.spawn(function()
    while task.wait(3) do
        if Settings.SpamChat then
            pcall(function()
                game:GetService("ReplicatedStorage"):FindFirstChild("DefaultChatSystemChatEvents")
                    :FindFirstChild("SayMessageRequest"):FireServer(Settings.SpamMsg, "All")
            end)
        end
    end
end)

-- ==================== MAIN LOOP ====================
local frameCount = 0
local lastFPSTime = tick()
local fps = 0

RunService.RenderStepped:Connect(function(dt)
    frameCount += 1
    local now = tick()
    if now - lastFPSTime >= 0.5 then
        fps = math.floor(frameCount / (now - lastFPSTime))
        frameCount = 0
        lastFPSTime = now
    end

    -- HUD
    local hudTxt = ""
    if Settings.FPSCounter then hudTxt = hudTxt .. "FPS: "..fps.."  " end
    if Settings.PingDisplay then
        local stats = game:FindFirstChild("Stats")
        local ping = stats and math.floor(stats.Network.ServerStatsItem["Data Ping"]:GetValue()) or 0
        hudTxt = hudTxt .. "PING: "..ping.."ms"
    end
    hudLabel.Text = hudTxt

    -- FOV Circle
    if FOVCircle then
        FOVCircle.Visible = Settings.Aimbot or Settings.SilentAim
        FOVCircle.Radius = Settings.FOV
        FOVCircle.Color = Settings.FOVColor
        FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    end

    -- FOV Changer
    if Settings.FOVChanger then
        Camera.FieldOfView = Settings.FOVValue
    end

    local target = getClosestPlayer()
    local targetPos = getTargetHead(target)

    -- Aimbot
    if Settings.Aimbot and target and targetPos then
        if Settings.Smooth > 0 then
            Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, targetPos), 1 / Settings.Smooth)
        else
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, targetPos)
        end
    end

    -- Third Person
    if Settings.ThirdPerson then
        local char = player.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            Camera.CFrame = CFrame.new(
                char.HumanoidRootPart.Position - Camera.CFrame.LookVector * Settings.ThirdPersonDist + Vector3.new(0,2,0),
                char.HumanoidRootPart.Position
            )
        end
    end

    -- Spinbot
    if Settings.Spinbot then
        local char = player.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            char.HumanoidRootPart.CFrame = char.HumanoidRootPart.CFrame * CFrame.Angles(0, math.rad(20), 0)
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
                if not Settings.SpeedHack then hum.WalkSpeed = 16 end
            end

            -- Auto Sprint
            if Settings.AutoSprint then
                hum.WalkSpeed = Settings.SpeedHack and Settings.SpeedValue or math.max(hum.WalkSpeed, 24)
            end

            -- No Slowdown
            if Settings.NoSlowdown then
                hum.WalkSpeed = math.max(hum.WalkSpeed, 16)
            end

            -- Super Jump
            if Settings.SuperJump then
                hum.JumpPower = Settings.JumpPower
            else
                hum.JumpPower = 50
            end

            -- Bunny Hop
            if Settings.BunnyHop then
                if UIS:IsKeyDown(Enum.KeyCode.Space) and hum.FloorMaterial ~= Enum.Material.Air then
                    hum:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end

            -- Strafe Helper
            if Settings.StrafeHelper and hum.FloorMaterial == Enum.Material.Air then
                local moveDir = hum.MoveDirection
                if moveDir.Magnitude > 0.1 then
                    local vel = hrp.AssemblyLinearVelocity
                    local speed = Vector3.new(vel.X, 0, vel.Z).Magnitude
                    hrp.AssemblyLinearVelocity = Vector3.new(moveDir.X * (speed + 0.5), vel.Y, moveDir.Z * (speed + 0.5))
                end
            end

            -- God Mode
            if Settings.GodMode then
                hum.Health = hum.MaxHealth
            end

            -- No Fall Damage
            if Settings.NoFallDamage then
                hum.StateChanged:Connect(function(_, new)
                    if new == Enum.HumanoidStateType.Landed then
                        hum.Health = hum.Health
                    end
                end)
            end

            -- Fly
            if flyActive and flyBodyVelocity and flyBodyGyro then
                local camCF = Camera.CFrame
                local moveVec = Vector3.zero
                if UIS:IsKeyDown(Enum.KeyCode.W) then moveVec += camCF.LookVector end
                if UIS:IsKeyDown(Enum.KeyCode.S) then moveVec -= camCF.LookVector end
                if UIS:IsKeyDown(Enum.KeyCode.A) then moveVec -= camCF.RightVector end
                if UIS:IsKeyDown(Enum.KeyCode.D) then moveVec += camCF.RightVector end
                if UIS:IsKeyDown(Enum.KeyCode.Space) then moveVec += Vector3.new(0,1,0) end
                if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then moveVec -= Vector3.new(0,1,0) end
                flyBodyVelocity.Velocity = moveVec.Magnitude > 0 and moveVec.Unit * Settings.FlySpeed or Vector3.zero
                flyBodyGyro.CFrame = camCF
            end

            -- Noclip
            if Settings.Noclip then
                for _, part in pairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end

        -- Auto Respawn
        if Settings.AutoRespawn then
            local h = char:FindFirstChildOfClass("Humanoid")
            if h and h.Health <= 0 then
                task.wait(0.5)
                player:LoadCharacter()
            end
        end
    end

    -- Kill Aura
    if Settings.KillAura then
        local myChar = player.Character
        if myChar and myChar:FindFirstChild("HumanoidRootPart") then
            local myPos = myChar.HumanoidRootPart.Position
            for _, plr in pairs(game.Players:GetPlayers()) do
                if plr ~= player and plr.Character then
                    local ehr = plr.Character:FindFirstChild("HumanoidRootPart")
                    local ehum = plr.Character:FindFirstChildOfClass("Humanoid")
                    if ehr and ehum then
                        local dist = (ehr.Position - myPos).Magnitude
                        if dist <= Settings.KillAuraRange then
                            ehum:TakeDamage(ehum.MaxHealth)
                        end
                    end
                end
            end
        end
    end

    -- Triggerbot
    if Settings.TriggerBot and target and targetPos then
        local screenPos, onScreen = Camera:WorldToViewportPoint(targetPos)
        if onScreen then
            local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
            local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
            if dist < 30 then
                -- simulate click
                pcall(function()
                    local tool = player.Character and player.Character:FindFirstChildOfClass("Tool")
                    if tool and tool:FindFirstChild("Handle") then
                        local remote = tool:FindFirstChild("RemoteEvent") or tool:FindFirstChildOfClass("RemoteEvent")
                        if remote then remote:FireServer() end
                    end
                end)
            end
        end
    end

    -- Hitbox Expander live update
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

    -- ESP Update
    local centerScreen = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    for char, espData in pairs(ESPObjects) do
        local plr = game.Players:GetPlayerFromCharacter(char)
        if not plr or not char.Parent then
            clearDrawings(espData)
            continue
        end
        local head = char:FindFirstChild("Head")
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not head or not hrp then
            clearDrawings(espData)
            continue
        end

        local headPos, onScreen = Camera:WorldToViewportPoint(head.Position + Vector3.new(0,0.7,0))
        local feetPos, feetOnScreen = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0,2.5,0))

        -- Chams live toggle
        local existingHL = char:FindFirstChildOfClass("Highlight")
        if Settings.Chams and not existingHL then
            local hl = Instance.new("Highlight")
            hl.FillColor = Color3.fromRGB(255,60,60)
            hl.OutlineColor = Color3.fromRGB(255,255,255)
            hl.FillTransparency = 0.5
            hl.OutlineTransparency = 0
            hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            hl.Parent = char
            espData.Highlight = hl
        elseif not Settings.Chams and existingHL then
            existingHL:Destroy()
            espData.Highlight = nil
        end

        -- Box ESP
        if espData.Box then
            if (Settings.ESPBox) and onScreen and feetOnScreen then
                local height = math.abs(headPos.Y - feetPos.Y)
                local width = height * 0.6
                espData.Box.Visible = true
                espData.Box.Position = Vector2.new(headPos.X - width/2, headPos.Y)
                espData.Box.Size = Vector2.new(width, height)
            else
                espData.Box.Visible = false
            end
        end

        -- Tracers
        if espData.Tracer then
            if Settings.Tracers and onScreen then
                espData.Tracer.Visible = true
                espData.Tracer.From = Vector2.new(centerScreen.X, Camera.ViewportSize.Y)
                espData.Tracer.To = Vector2.new(headPos.X, headPos.Y)
                espData.Tracer.Color = Color3.fromRGB(255,50,50)
            else
                espData.Tracer.Visible = false
            end
        end

        -- Snap Lines
        if espData.SnapLine then
            if Settings.SnapLines and onScreen then
                espData.SnapLine.Visible = true
                espData.SnapLine.From = centerScreen
                espData.SnapLine.To = Vector2.new(headPos.X, headPos.Y)
                espData.SnapLine.Color = Color3.fromRGB(255,200,0)
            else
                espData.SnapLine.Visible = false
            end
        end

        -- Distance ESP
        if espData.DistLabel then
            if Settings.DistanceESP then
                local myHRP = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                if myHRP then
                    local dist = math.floor((hrp.Position - myHRP.Position).Magnitude)
                    espData.DistLabel.Text = dist.."m"
                    espData.DistLabel.Visible = true
                end
            else
                espData.DistLabel.Visible = false
            end
        end

        -- Weapon ESP
        if espData.WepLabel then
            if Settings.WeaponESP then
                local tool = char:FindFirstChildOfClass("Tool")
                espData.WepLabel.Text = tool and tool.Name or ""
                espData.WepLabel.Visible = true
            else
                espData.WepLabel.Visible = false
            end
        end

        -- Health bar
        if espData.Billboard then
            local healthLbl = espData.HealthBar
            if Settings.ESPHealth and hum then
                if not healthLbl then
                    local hl = Instance.new("TextLabel", espData.Billboard)
                    hl.Size = UDim2.new(1,0,0.3,0)
                    hl.Position = UDim2.new(0,0,0.7,0)
                    hl.BackgroundTransparency=1
                    hl.Font=Enum.Font.Gotham
                    hl.TextSize=12
                    hl.TextStrokeTransparency=0
                    hl.TextXAlignment=Enum.TextXAlignment.Left
                    espData.HealthBar = hl
                    healthLbl = hl
                end
                local hp = math.floor((hum.Health/hum.MaxHealth)*100)
                healthLbl.Text = "HP: "..hp.."%"
                local r = 1-(hp/100)
                healthLbl.TextColor3 = Color3.new(r, hp/100, 0)
                healthLbl.Visible = true
            elseif healthLbl then
                healthLbl.Visible = false
            end
        end
    end

    -- Silent Aim (manipulate camera to redirect shots)
    if Settings.SilentAim and target and targetPos then
        local originalCF = Camera.CFrame
        Camera.CFrame = CFrame.new(Camera.CFrame.Position, targetPos)
        task.defer(function()
            if Camera then
                Camera.CFrame = originalCF
            end
        end)
    end
end)

-- Noclip via Stepped
RunService.Stepped:Connect(function()
    if Settings.Noclip then
        local char = player.Character
        if char then
            for _, p in pairs(char:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = false end
            end
        end
    end
end)

notify("memeSense", "v2.0 Loaded!", Color3.fromRGB(255,50,50))
