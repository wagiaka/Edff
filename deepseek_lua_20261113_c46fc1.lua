local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local Config = {
    ESP = false,
    Speed = false,
    SpeedValue = 50,
    JumpPower = false,
    JumpValue = 100,
    InfiniteJump = false,
    Fly = false,
    FlySpeed = 60,
    Noclip = false,
    FlyForward = false,
    FlyBack = false,
    FlyLeft = false,
    FlyRight = false,
    FlyUp = false,
    FlyDown = false,
    SavedPos = nil,
}

local ESPObjects = {}
local noclipSaved = {}

local function notify(text)
    local gui = Instance.new("ScreenGui")
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 999
    gui.Parent = CoreGui
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 240, 0, 40)
    frame.Position = UDim2.new(0.5, -120, 0, -56)
    frame.BackgroundColor3 = Color3.fromRGB(30, 20, 40)
    frame.BorderSizePixel = 0
    frame.ZIndex = 10
    frame.Parent = gui
    local c = Instance.new("UICorner", frame)
    c.CornerRadius = UDim.new(0, 10)
    local s = Instance.new("UIStroke", frame)
    s.Color = Color3.fromRGB(255, 90, 255)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 14
    lbl.ZIndex = 11
    lbl.Parent = frame
    frame:TweenPosition(UDim2.new(0.5, -120, 0, 16), "Out", "Quad", 0.3)
    task.delay(2, function()
        frame:TweenPosition(UDim2.new(0.5, -120, 0, -56), "In", "Quad", 0.3)
        task.wait(0.4)
        gui:Destroy()
    end)
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ollie_menu"
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 500
ScreenGui.Parent = CoreGui

local Circle = Instance.new("TextButton")
Circle.Name = "Circle"
Circle.Size = UDim2.new(0, 56, 0, 56)
Circle.Position = UDim2.new(0.03, 0, 0.5, -28)
Circle.BackgroundColor3 = Color3.fromRGB(30, 20, 40)
Circle.Text = "o"
Circle.TextColor3 = Color3.fromRGB(255, 90, 255)
Circle.Font = Enum.Font.GothamBold
Circle.TextSize = 28
Circle.BorderSizePixel = 0
Circle.Active = true
Circle.ZIndex = 20
Circle.Parent = ScreenGui
local cc = Instance.new("UICorner", Circle)
cc.CornerRadius = UDim.new(1, 0)
local cstroke = Instance.new("UIStroke", Circle)
cstroke.Color = Color3.fromRGB(255, 90, 255)
cstroke.Thickness = 2

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.new(0.94, 0, 0, 200)
Main.Position = UDim2.new(0.03, 0, 0.5, -100)
Main.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
Main.BorderSizePixel = 0
Main.Visible = false
Main.Active = true
Main.ZIndex = 15
Main.Parent = ScreenGui
local mc = Instance.new("UICorner", Main)
mc.CornerRadius = UDim.new(0, 12)
local mstroke = Instance.new("UIStroke", Main)
mstroke.Color = Color3.fromRGB(200, 40, 200)
mstroke.Thickness = 2
mstroke.Transparency = 0.2

local Header = Instance.new("Frame")
Header.Name = "Header"
Header.Size = UDim2.new(1, 0, 0, 40)
Header.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
Header.BorderSizePixel = 0
Header.Active = true
Header.ZIndex = 16
Header.Parent = Main
local hc = Instance.new("UICorner", Header)
hc.CornerRadius = UDim.new(0, 12)

local HeaderTitle = Instance.new("TextLabel")
HeaderTitle.Size = UDim2.new(1, -56, 1, 0)
HeaderTitle.Position = UDim2.new(0, 14, 0, 0)
HeaderTitle.BackgroundTransparency = 1
HeaderTitle.Text = "ollie  ·  roblox"
HeaderTitle.TextColor3 = Color3.fromRGB(255, 90, 255)
HeaderTitle.Font = Enum.Font.GothamBold
HeaderTitle.TextSize = 15
HeaderTitle.TextXAlignment = Enum.TextXAlignment.Left
HeaderTitle.ZIndex = 17
HeaderTitle.Parent = Header

local Minimize = Instance.new("TextButton")
Minimize.Name = "Minimize"
Minimize.Size = UDim2.new(0, 44, 1, 0)
Minimize.Position = UDim2.new(1, -44, 0, 0)
Minimize.BackgroundTransparency = 1
Minimize.Text = "−"
Minimize.TextColor3 = Color3.fromRGB(255, 90, 255)
Minimize.Font = Enum.Font.GothamBold
Minimize.TextSize = 24
Minimize.ZIndex = 18
Minimize.Parent = Header

local TabBar = Instance.new("Frame")
TabBar.Size = UDim2.new(1, 0, 0, 32)
TabBar.Position = UDim2.new(0, 0, 0, 40)
TabBar.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
TabBar.BorderSizePixel = 0
TabBar.ZIndex = 16
TabBar.Parent = Main

local tabNames = {"Chạy", "Bay", "Hành động", "ESP"}
local tabButtons = {}
local tabContents = {}

local ContentArea = Instance.new("Frame")
ContentArea.Size = UDim2.new(1, 0, 1, -72)
ContentArea.Position = UDim2.new(0, 0, 0, 72)
ContentArea.BackgroundTransparency = 1
ContentArea.ZIndex = 16
ContentArea.Parent = Main

for i, name in ipairs(tabNames) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1/4, 0, 1, 0)
    btn.Position = UDim2.new((i-1)/4, 0, 0, 0)
    btn.BackgroundColor3 = i == 1 and Color3.fromRGB(45, 25, 55) or Color3.fromRGB(20, 20, 25)
    btn.Text = name
    btn.TextColor3 = i == 1 and Color3.fromRGB(255, 120, 255) or Color3.fromRGB(160, 160, 160)
    btn.Font = Enum.Font.GothamMedium
    btn.TextSize = 13
    btn.BorderSizePixel = 0
    btn.ZIndex = 17
    btn.Parent = TabBar
    tabButtons[i] = btn

    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, -8, 1, -8)
    scroll.Position = UDim2.new(0, 4, 0, 4)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 3
    scroll.ScrollBarImageColor3 = Color3.fromRGB(255, 90, 255)
    scroll.ScrollDirection = Enum.ScrollDirection.Horizontal
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.X
    scroll.CanvasSize = UDim2.new(0, 0, 1, 0)
    scroll.Visible = (i == 1)
    scroll.ZIndex = 17
    scroll.Parent = ContentArea
    tabContents[i] = scroll

    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.Padding = UDim.new(0, 8)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = scroll
end

for i, btn in ipairs(tabButtons) do
    btn.MouseButton1Click:Connect(function()
        for j, b in ipairs(tabButtons) do
            b.BackgroundColor3 = j == i and Color3.fromRGB(45, 25, 55) or Color3.fromRGB(20, 20, 25)
            b.TextColor3 = j == i and Color3.fromRGB(255, 120, 255) or Color3.fromRGB(160, 160, 160)
        end
        for j, s in ipairs(tabContents) do
            s.Visible = (j == i)
        end
    end)
end

local function makeTapOrDrag(obj, onClick, dragTarget)
    local startPos
    local startObjPos
    local moved = false
    obj.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            startPos = input.Position
            startObjPos = dragTarget.Position
            moved = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if not startPos then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - startPos
            if delta.Magnitude > 8 then
                moved = true
                dragTarget.Position = UDim2.new(
                    startObjPos.X.Scale, startObjPos.X.Offset + delta.X,
                    startObjPos.Y.Scale, startObjPos.Y.Offset + delta.Y
                )
            end
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if not startPos then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            if not moved then
                onClick()
            end
            startPos = nil
            moved = false
        end
    end)
end

makeTapOrDrag(Circle, function()
    Circle.Visible = false
    Main.Visible = true
end, Circle)

Minimize.MouseButton1Click:Connect(function()
    Main.Visible = false
    Circle.Visible = true
end)

makeTapOrDrag(HeaderTitle, function() end, Main)

local scrollLocks = {}
local function lockScroll(scroll)
    scrollLocks[scroll] = (scrollLocks[scroll] or 0) + 1
    scroll.ScrollingEnabled = false
end
local function unlockScroll(scroll)
    scrollLocks[scroll] = math.max(0, (scrollLocks[scroll] or 0) - 1)
    if scrollLocks[scroll] == 0 then
        scroll.ScrollingEnabled = true
    end
end

local function makeCell(scroll, width)
    local cell = Instance.new("Frame")
    cell.Size = UDim2.new(0, width, 1, 0)
    cell.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    cell.BorderSizePixel = 0
    cell.ZIndex = 18
    cell.Parent = scroll
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 8)
    c.Parent = cell
    return cell
end

local function addToggle(scroll, name, default, callback)
    local cell = makeCell(scroll, 100)

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.ZIndex = 19
    btn.Parent = cell

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -8, 0.5, 0)
    label.Position = UDim2.new(0, 4, 0, 6)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Color3.fromRGB(220, 220, 220)
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 12
    label.TextWrapped = true
    label.ZIndex = 19
    label.Parent = cell

    local pill = Instance.new("TextLabel")
    pill.Size = UDim2.new(1, -16, 0, 24)
    pill.Position = UDim2.new(0, 8, 1, -30)
    pill.BackgroundColor3 = default and Color3.fromRGB(60, 20, 60) or Color3.fromRGB(40, 40, 48)
    pill.Text = default and "BẬT" or "TẮT"
    pill.TextColor3 = default and Color3.fromRGB(255, 120, 255) or Color3.fromRGB(160, 160, 160)
    pill.Font = Enum.Font.GothamBold
    pill.TextSize = 11
    pill.BorderSizePixel = 0
    pill.ZIndex = 19
    pill.Parent = cell
    local pc = Instance.new("UICorner", pill)
    pc.CornerRadius = UDim.new(1, 0)

    local state = default
    btn.MouseButton1Click:Connect(function()
        state = not state
        pill.BackgroundColor3 = state and Color3.fromRGB(60, 20, 60) or Color3.fromRGB(40, 40, 48)
        pill.TextColor3 = state and Color3.fromRGB(255, 120, 255) or Color3.fromRGB(160, 160, 160)
        pill.Text = state and "BẬT" or "TẮT"
        callback(state)
    end)
end

local function addSlider(scroll, name, min, max, default, callback)
    local cell = makeCell(scroll, 100)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -8, 0, 40)
    label.Position = UDim2.new(0, 4, 0, 6)
    label.BackgroundTransparency = 1
    label.Text = name .. "\n" .. default
    label.TextColor3 = Color3.fromRGB(220, 220, 220)
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 12
    label.TextWrapped = true
    label.ZIndex = 19
    label.Parent = cell

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, -16, 0, 14)
    bar.Position = UDim2.new(0, 8, 1, -26)
    bar.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    bar.BorderSizePixel = 0
    bar.ZIndex = 19
    bar.Parent = cell
    local bc = Instance.new("UICorner", bar)
    bc.CornerRadius = UDim.new(1, 0)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(255, 90, 255)
    fill.BorderSizePixel = 0
    fill.ZIndex = 20
    fill.Parent = bar
    local fc = Instance.new("UICorner", fill)
    fc.CornerRadius = UDim.new(1, 0)

    local dragging = false
    local function setFromX(x)
        local pct = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        local val = math.floor(min + pct * (max - min) + 0.5)
        fill.Size = UDim2.new(pct, 0, 1, 0)
        label.Text = name .. "\n" .. val
        callback(val)
    end

    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            lockScroll(scroll)
            setFromX(input.Position.X)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
            setFromX(input.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch) then
            dragging = false
            unlockScroll(scroll)
        end
    end)
end

local function addHold(scroll, name, onStart, onEnd)
    local cell = makeCell(scroll, 100)

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundColor3 = Color3.fromRGB(45, 25, 55)
    btn.Text = name
    btn.TextColor3 = Color3.fromRGB(255, 180, 255)
    btn.Font = Enum.Font.GothamMedium
    btn.TextSize = 13
    btn.TextWrapped = true
    btn.BorderSizePixel = 0
    btn.ZIndex = 19
    btn.Parent = cell
    local bc = Instance.new("UICorner", btn)
    bc.CornerRadius = UDim.new(0, 8)

    local idle = Color3.fromRGB(45, 25, 55)
    local pressed = Color3.fromRGB(120, 40, 140)

    btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            lockScroll(scroll)
            btn.BackgroundColor3 = pressed
            onStart()
        end
    end)
    btn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            unlockScroll(scroll)
            btn.BackgroundColor3 = idle
            onEnd()
        end
    end)
end

local function addAction(scroll, name, callback)
    local cell = makeCell(scroll, 100)

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
    btn.Text = name
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamMedium
    btn.TextSize = 13
    btn.TextWrapped = true
    btn.BorderSizePixel = 0
    btn.ZIndex = 19
    btn.Parent = cell
    local bc = Instance.new("UICorner", btn)
    bc.CornerRadius = UDim.new(0, 8)

    btn.MouseButton1Click:Connect(callback)
end

local function applyESP(char)
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local head = char:FindFirstChild("Head")
    if not head then return end
    local bb = Instance.new("BillboardGui")
    bb.Name = "ollie_esp"
    bb.Adornee = head
    bb.Size = UDim2.new(0, 200, 0, 50)
    bb.StudsOffset = Vector3.new(0, 2.5, 0)
    bb.AlwaysOnTop = true
    bb.Parent = head
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = char.Name
    lbl.TextColor3 = Color3.fromRGB(255, 90, 255)
    lbl.TextStrokeTransparency = 0
    lbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 14
    lbl.Parent = bb
    local hl = Instance.new("Highlight")
    hl.Name = "ollie_hl"
    hl.FillColor = Color3.fromRGB(255, 90, 255)
    hl.FillTransparency = 0.7
    hl.OutlineColor = Color3.fromRGB(255, 90, 255)
    hl.Parent = char
    ESPObjects[char] = { Billboard = bb, Highlight = hl }
end

local function removeESP(char)
    if ESPObjects[char] then
        if ESPObjects[char].Billboard then ESPObjects[char].Billboard:Destroy() end
        if ESPObjects[char].Highlight then ESPObjects[char].Highlight:Destroy() end
        ESPObjects[char] = nil
    end
end

local function refreshESP()
    if not Config.ESP then
        for char in pairs(ESPObjects) do removeESP(char) end
        return
    end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            applyESP(plr.Character)
        end
    end
end

local function applyNoclip(state)
    local char = LocalPlayer.Character
    if not char then return end
    if state then
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                if noclipSaved[part] == nil then
                    noclipSaved[part] = part.CanCollide
                end
                part.CanCollide = false
            end
        end
    else
        for part, value in pairs(noclipSaved) do
            if part.Parent then
                part.CanCollide = value
            end
        end
        noclipSaved = {}
    end
end

local flyBV, flyBG

local function stopFly()
    if flyBV then flyBV:Destroy(); flyBV = nil end
    if flyBG then flyBG:Destroy(); flyBG = nil end
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.PlatformStand = false
            hum:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
    end
end

local function setupFly()
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end
    stopFly()
    hum.PlatformStand = true
    hum:ChangeState(Enum.HumanoidStateType.Physics)
    hrp.Anchored = false
    flyBV = Instance.new("BodyVelocity")
    flyBV.MaxForce = Vector3.new(1e5, 1e5, 1e5)
    flyBV.Velocity = Vector3.zero
    flyBV.Parent = hrp
    flyBG = Instance.new("BodyGyro")
    flyBG.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
    flyBG.P = 9e4
    flyBG.D = 500
    flyBG.CFrame = hrp.CFrame
    flyBG.Parent = hrp
end

local tMove = tabContents[1]
addToggle(tMove, "Tốc độ chạy", false, function(s)
    Config.Speed = s
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum.WalkSpeed = s and Config.SpeedValue or 16 end
end)
addSlider(tMove, "Tốc độ", 16, 250, 50, function(v)
    Config.SpeedValue = v
    if Config.Speed then
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = v end
    end
end)
addToggle(tMove, "Độ cao nhảy", false, function(s)
    Config.JumpPower = s
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum.UseJumpPower = true; hum.JumpPower = s and Config.JumpValue or 50 end
end)
addSlider(tMove, "Nhảy cao", 50, 500, 100, function(v)
    Config.JumpValue = v
    if Config.JumpPower then
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.JumpPower = v end
    end
end)
addToggle(tMove, "Nhảy vô hạn", false, function(s)
    Config.InfiniteJump = s
end)
addToggle(tMove, "Xuyên tường", false, function(s)
    Config.Noclip = s
    applyNoclip(s)
end)

local tFly = tabContents[2]
addToggle(tFly, "Bay", false, function(s)
    Config.Fly = s
    if s then setupFly() else stopFly() end
end)
addSlider(tFly, "Tốc độ bay", 20, 300, 60, function(v)
    Config.FlySpeed = v
end)
addHold(tFly, "Bay lên", function() Config.FlyUp = true end, function() Config.FlyUp = false end)
addHold(tFly, "Bay xuống", function() Config.FlyDown = true end, function() Config.FlyDown = false end)
addHold(tFly, "Bay tới", function() Config.FlyForward = true end, function() Config.FlyForward = false end)
addHold(tFly, "Bay lùi", function() Config.FlyBack = true end, function() Config.FlyBack = false end)
addHold(tFly, "Bay trái", function() Config.FlyLeft = true end, function() Config.FlyLeft = false end)
addHold(tFly, "Bay phải", function() Config.FlyRight = true end, function() Config.FlyRight = false end)

local tAct = tabContents[3]
addAction(tAct, "Lưu vị trí", function()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        Config.SavedPos = char.HumanoidRootPart.CFrame
        notify("Đã lưu vị trí")
    end
end)
addAction(tAct, "Dịch chuyển", function()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") and Config.SavedPos then
        char.HumanoidRootPart.CFrame = Config.SavedPos
        notify("Đã dịch chuyển")
    end
end)
addAction(tAct, "Bán TẤT CẢ", function()
    local ev = ReplicatedStorage:FindFirstChild("SellEvent")
    if ev and ev:IsA("RemoteEvent") then
        ev:FireServer("SellAll")
        notify("Đã gửi lệnh bán")
    end
end)
addAction(tAct, "Nâng balo", function()
    local ev = ReplicatedStorage:FindFirstChild("UpgradeEvent")
    if ev and ev:IsA("RemoteEvent") then
        ev:FireServer("Pocket", 1)
        notify("Đã nâng cấp balo")
    end
end)
addAction(tAct, "Nâng tầm nhìn", function()
    local ev = ReplicatedStorage:FindFirstChild("UpgradeEvent")
    if ev and ev:IsA("RemoteEvent") then
        ev:FireServer("Eyesight", 2)
        notify("Đã nâng cấp tầm nhìn")
    end
end)

local tESP = tabContents[4]
addToggle(tESP, "ESP người chơi", false, function(s)
    Config.ESP = s
    refreshESP()
end)

RunService.Heartbeat:Connect(function()
    if Config.ESP then
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character then
                if not ESPObjects[plr.Character] then
                    applyESP(plr.Character)
                end
            end
        end
        for char in pairs(ESPObjects) do
            if not char.Parent or not char:FindFirstChild("HumanoidRootPart") then
                removeESP(char)
            end
        end
    end
    if Config.Noclip then
        applyNoclip(true)
    end
end)

UserInputService.JumpRequest:Connect(function()
    if Config.InfiniteJump then
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

RunService.RenderStepped:Connect(function()
    if not Config.Fly then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum or not flyBV or not flyBG then return end

    local camCF = Camera.CFrame
    local dir = Vector3.zero

    if Config.FlyForward then dir = dir + camCF.LookVector end
    if Config.FlyBack then dir = dir - camCF.LookVector end
    if Config.FlyLeft then dir = dir - camCF.RightVector end
    if Config.FlyRight then dir = dir + camCF.RightVector end
    if Config.FlyUp then dir = dir + Vector3.new(0, 1, 0) end
    if Config.FlyDown then dir = dir - Vector3.new(0, 1, 0) end

    if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + camCF.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - camCF.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - camCF.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + camCF.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0, 1, 0) end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir = dir - Vector3.new(0, 1, 0) end

    if dir.Magnitude > 0 then
        dir = dir.Unit
    end

    flyBV.Velocity = dir * Config.FlySpeed
    flyBG.CFrame = camCF
end)

LocalPlayer.CharacterAdded:Connect(function(char)
    char:WaitForChild("Humanoid")
    task.wait(0.5)
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        if Config.Speed then hum.WalkSpeed = Config.SpeedValue end
        if Config.JumpPower then
            hum.UseJumpPower = true
            hum.JumpPower = Config.JumpValue
        end
    end
    if Config.Noclip then
        noclipSaved = {}
        applyNoclip(true)
    end
    if Config.Fly then
        task.wait(0.3)
        setupFly()
    end
end)

print("[ollie] menu ngang đã tải — chạm nút tròn để mở, olivia")
