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
    gui.Parent = CoreGui
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 240, 0, 40)
    frame.Position = UDim2.new(0.5, -120, 0, -60)
    frame.BackgroundColor3 = Color3.fromRGB(30, 20, 40)
    frame.BorderSizePixel = 0
    frame.Parent = gui
    local c = Instance.new("UICorner", frame)
    c.CornerRadius = UDim.new(0, 10)
    local stroke = Instance.new("UIStroke", frame)
    stroke.Color = Color3.fromRGB(255, 90, 255)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 14
    lbl.Parent = frame
    frame:TweenPosition(UDim2.new(0.5, -120, 0, 16), "Out", "Quad", 0.3)
    task.delay(2, function()
        frame:TweenPosition(UDim2.new(0.5, -120, 0, -60), "In", "Quad", 0.3)
        task.wait(0.4)
        gui:Destroy()
    end)
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ollie_menu_horizontal"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = CoreGui

local Circle = Instance.new("TextButton")
Circle.Size = UDim2.new(0, 50, 0, 50)
Circle.Position = UDim2.new(0, 12, 0.5, -25)
Circle.BackgroundColor3 = Color3.fromRGB(30, 20, 40)
Circle.Text = "o"
Circle.TextColor3 = Color3.fromRGB(255, 90, 255)
Circle.Font = Enum.Font.GothamBold
Circle.TextSize = 26
Circle.BorderSizePixel = 0
Circle.Active = true
Circle.Draggable = true
Circle.Parent = ScreenGui
local cc = Instance.new("UICorner", Circle)
cc.CornerRadius = UDim.new(1, 0)
local cs = Instance.new("UIStroke", Circle)
cs.Color = Color3.fromRGB(255, 90, 255)
cs.Thickness = 2

-- KHUNG CHÍNH NẰM NGANG (520 x 270)
local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 520, 0, 270)
Main.Position = UDim2.new(0.5, -260, 0.5, -135)
Main.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Main.Visible = false
Main.Parent = ScreenGui
local mc = Instance.new("UICorner", Main)
mc.CornerRadius = UDim.new(0, 12)
local ms = Instance.new("UIStroke", Main)
ms.Color = Color3.fromRGB(200, 40, 200)
ms.Thickness = 2
ms.Transparency = 0.2

local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 42)
Header.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
Header.BorderSizePixel = 0
Header.Parent = Main
local hc = Instance.new("UICorner", Header)
hc.CornerRadius = UDim.new(0, 12)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(0, 140, 1, 0)
Title.BackgroundTransparency = 1
Title.Text = "  ollie · menu"
Title.TextColor3 = Color3.fromRGB(255, 90, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 16
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

local TabBar = Instance.new("Frame")
TabBar.Size = UDim2.new(1, -190, 1, -10)
TabBar.Position = UDim2.new(0, 145, 0, 5)
TabBar.BackgroundTransparency = 1
TabBar.Parent = Header

local tabLayout = Instance.new("UIListLayout", TabBar)
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.Padding = UDim.new(0, 6)
tabLayout.VerticalAlignment = Enum.VerticalAlignment.Center

local Close = Instance.new("TextButton")
Close.Size = UDim2.new(0, 42, 0, 42)
Close.Position = UDim2.new(1, -42, 0, 0)
Close.BackgroundTransparency = 1
Close.Text = "−"
Close.TextColor3 = Color3.fromRGB(255, 90, 255)
Close.Font = Enum.Font.GothamBold
Close.TextSize = 24
Close.Parent = Header

local ContentContainer = Instance.new("Frame")
ContentContainer.Size = UDim2.new(1, -16, 1, -50)
ContentContainer.Position = UDim2.new(0, 8, 0, 46)
ContentContainer.BackgroundTransparency = 1
ContentContainer.Parent = Main

Circle.MouseButton1Click:Connect(function()
    Circle.Visible = false
    Main.Visible = true
end)

Close.MouseButton1Click:Connect(function()
    Main.Visible = false
    Circle.Visible = true
end)

local Tabs = {}
local TabButtons = {}

local function createTab(tabName)
    local TabBtn = Instance.new("TextButton")
    TabBtn.Size = UDim2.new(0, 100, 1, 0)
    TabBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
    TabBtn.Text = tabName
    TabBtn.TextColor3 = Color3.fromRGB(180, 180, 180)
    TabBtn.Font = Enum.Font.GothamBold
    TabBtn.TextSize = 13
    TabBtn.BorderSizePixel = 0
    TabBtn.Parent = TabBar
    local tc = Instance.new("UICorner", TabBtn)
    tc.CornerRadius = UDim.new(0, 8)

    local Page = Instance.new("ScrollingFrame")
    Page.Size = UDim2.new(1, 0, 1, 0)
    Page.BackgroundTransparency = 1
    Page.BorderSizePixel = 0
    Page.ScrollBarThickness = 3
    Page.ScrollBarImageColor3 = Color3.fromRGB(255, 90, 255)
    Page.CanvasSize = UDim2.new(0, 0, 0, 0)
    Page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    Page.Visible = false
    Page.Parent = ContentContainer

    local grid = Instance.new("UIGridLayout", Page)
    grid.CellSize = UDim2.new(0.49, 0, 0, 48)
    grid.CellPadding = UDim2.new(0.02, 0, 0, 8)
    grid.SortOrder = Enum.SortOrder.LayoutOrder

    TabBtn.MouseButton1Click:Connect(function()
        for _, p in pairs(Tabs) do p.Visible = false end
        for _, b in pairs(TabButtons) do
            b.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
            b.TextColor3 = Color3.fromRGB(180, 180, 180)
        end
        Page.Visible = true
        TabBtn.BackgroundColor3 = Color3.fromRGB(75, 25, 75)
        TabBtn.TextColor3 = Color3.fromRGB(255, 130, 255)
    end)

    table.insert(Tabs, Page)
    table.insert(TabButtons, TabBtn)

    if #Tabs == 1 then
        Page.Visible = true
        TabBtn.BackgroundColor3 = Color3.fromRGB(75, 25, 75)
        TabBtn.TextColor3 = Color3.fromRGB(255, 130, 255)
    end

    return Page
end

local TabPlayer = createTab("Nhân vật")
local TabFly = createTab("Bay & Di chuyển")
local TabMisc = createTab("Tiện ích")

local function addToggle(parent, name, default, callback)
    local Btn = Instance.new("TextButton")
    Btn.BackgroundColor3 = default and Color3.fromRGB(60, 20, 60) or Color3.fromRGB(25, 25, 30)
    Btn.Text = "  " .. name .. " [" .. (default and "BẬT" or "TẮT") .. "]"
    Btn.TextColor3 = default and Color3.fromRGB(255, 120, 255) or Color3.fromRGB(200, 200, 200)
    Btn.Font = Enum.Font.GothamMedium
    Btn.TextSize = 13
    Btn.TextXAlignment = Enum.TextXAlignment.Left
    Btn.BorderSizePixel = 0
    Btn.AutoButtonColor = false
    Btn.Parent = parent
    local c = Instance.new("UICorner", Btn)
    c.CornerRadius = UDim.new(0, 8)
    local state = default
    Btn.MouseButton1Click:Connect(function()
        state = not state
        Btn.BackgroundColor3 = state and Color3.fromRGB(60, 20, 60) or Color3.fromRGB(25, 25, 30)
        Btn.TextColor3 = state and Color3.fromRGB(255, 120, 255) or Color3.fromRGB(200, 200, 200)
        Btn.Text = "  " .. name .. " [" .. (state and "BẬT" or "TẮT") .. "]"
        callback(state)
    end)
    return Btn
end

local function addButton(parent, name, callback)
    local Btn = Instance.new("TextButton")
    Btn.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
    Btn.Text = "  " .. name
    Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    Btn.Font = Enum.Font.GothamMedium
    Btn.TextSize = 13
    Btn.TextXAlignment = Enum.TextXAlignment.Left
    Btn.BorderSizePixel = 0
    Btn.Parent = parent
    local c = Instance.new("UICorner", Btn)
    c.CornerRadius = UDim.new(0, 8)
    Btn.MouseButton1Click:Connect(callback)
    return Btn
end

local function addHoldButton(parent, name, onStart, onEnd)
    local Btn = Instance.new("TextButton")
    Btn.BackgroundColor3 = Color3.fromRGB(45, 25, 55)
    Btn.Text = "  " .. name
    Btn.TextColor3 = Color3.fromRGB(255, 180, 255)
    Btn.Font = Enum.Font.GothamMedium
    Btn.TextSize = 13
    Btn.TextXAlignment = Enum.TextXAlignment.Left
    Btn.BorderSizePixel = 0
    Btn.Parent = parent
    local c = Instance.new("UICorner", Btn)
    c.CornerRadius = UDim.new(0, 8)
    Btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            onStart()
        end
    end)
    Btn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            onEnd()
        end
    end)
    return Btn
end

local function addSlider(parent, name, min, max, default, callback)
    local Holder = Instance.new("Frame")
    Holder.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    Holder.BorderSizePixel = 0
    Holder.Parent = parent
    local c = Instance.new("UICorner", Holder)
    c.CornerRadius = UDim.new(0, 8)

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -16, 0, 20)
    Label.Position = UDim2.new(0, 8, 0, 3)
    Label.BackgroundTransparency = 1
    Label.Text = name .. ": " .. default
    Label.TextColor3 = Color3.fromRGB(255, 255, 255)
    Label.Font = Enum.Font.GothamMedium
    Label.TextSize = 13
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Holder

    local Bar = Instance.new("Frame")
    Bar.Size = UDim2.new(1, -16, 0, 12)
    Bar.Position = UDim2.new(0, 8, 0, 28)
    Bar.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    Bar.BorderSizePixel = 0
    Bar.Parent = Holder
    local bc = Instance.new("UICorner", Bar)
    bc.CornerRadius = UDim.new(1, 0)

    local Fill = Instance.new("Frame")
    Fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    Fill.BackgroundColor3 = Color3.fromRGB(255, 90, 255)
    Fill.BorderSizePixel = 0
    Fill.Parent = Bar
    local fc = Instance.new("UICorner", Fill)
    fc.CornerRadius = UDim.new(1, 0)

    local dragging = false
    local function setFromX(x)
        local pct = math.clamp((x - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X, 0, 1)
        local val = math.floor(min + pct * (max - min) + 0.5)
        Fill.Size = UDim2.new(pct, 0, 1, 0)
        Label.Text = name .. ": " .. val
        callback(val)
    end

    Bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
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
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    return Holder
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

-- === HỆ THỐNG BAY MỚI (SMOOTH CFRAME FLY) ===
local flyPart = nil

local function setupFly()
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end
    
    hum.PlatformStand = true
    hum:ChangeState(Enum.HumanoidStateType.Physics)
end

local function stopFly()
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.PlatformStand = false
            hum:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then
            for _, v in ipairs(hrp:GetChildren()) do
                if v:IsA("BodyVelocity") or v:IsA("BodyGyro") then
                    v:Destroy()
                end
            end
        end
    end
end

-- === TAB 1: NHÂN VẬT ===
addToggle(TabPlayer, "Tốc độ chạy", false, function(s)
    Config.Speed = s
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum.WalkSpeed = s and Config.SpeedValue or 16 end
end)
addSlider(TabPlayer, "Mức tốc độ", 16, 250, 50, function(v)
    Config.SpeedValue = v
    if Config.Speed then
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = v end
    end
end)

addToggle(TabPlayer, "Độ cao nhảy", false, function(s)
    Config.JumpPower = s
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum.UseJumpPower = true; hum.JumpPower = s and Config.JumpValue or 50 end
end)
addSlider(TabPlayer, "Mức nhảy", 50, 500, 100, function(v)
    Config.JumpValue = v
    if Config.JumpPower then
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.JumpPower = v end
    end
end)

addToggle(TabPlayer, "Nhảy vô hạn", false, function(s)
    Config.InfiniteJump = s
end)

addToggle(TabPlayer, "ESP Người chơi", false, function(s)
    Config.ESP = s
    refreshESP()
end)

-- === TAB 2: BAY & DI CHUYỂN ===
addToggle(TabFly, "Bật Bay", false, function(s)
    Config.Fly = s
    if s then setupFly() else stopFly() end
end)
addSlider(TabFly, "Tốc độ bay", 20, 300, 60, function(v)
    Config.FlySpeed = v
end)

addToggle(TabFly, "Xuyên tường", false, function(s)
    Config.Noclip = s
    applyNoclip(s)
end)

addHoldButton(TabFly, "Giữ: Bay lên", function() Config.FlyUp = true end, function() Config.FlyUp = false end)
addHoldButton(TabFly, "Giữ: Bay tới", function() Config.FlyForward = true end, function() Config.FlyForward = false end)
addHoldButton(TabFly, "Giữ: Bay xuống", function() Config.FlyDown = true end, function() Config.FlyDown = false end)
addHoldButton(TabFly, "Giữ: Bay lui", function() Config.FlyBack = true end, function() Config.FlyBack = false end)
addHoldButton(TabFly, "Giữ: Bay trái", function() Config.FlyLeft = true end, function() Config.FlyLeft = false end)
addHoldButton(TabFly, "Giữ: Bay phải", function() Config.FlyRight = true end, function() Config.FlyRight = false end)

-- === TAB 3: TIỆN ÍCH ===
addButton(TabMisc, "Lưu vị trí", function()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        Config.SavedPos = char.HumanoidRootPart.CFrame
        notify("Đã lưu vị trí")
    end
end)

addButton(TabMisc, "Dịch chuyển vị trí lưu", function()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") and Config.SavedPos then
        char.HumanoidRootPart.CFrame = Config.SavedPos
        notify("Đã dịch chuyển")
    end
end)

addButton(TabMisc, "Bán TẤT CẢ", function()
    local ev = ReplicatedStorage:FindFirstChild("SellEvent")
    if ev and ev:IsA("RemoteEvent") then
        ev:FireServer("SellAll")
        notify("Đã gửi lệnh bán")
    end
end)

addButton(TabMisc, "Nâng cấp balo", function()
    local ev = ReplicatedStorage:FindFirstChild("UpgradeEvent")
    if ev and ev:IsA("RemoteEvent") then
        ev:FireServer("Pocket", 1)
        notify("Đã nâng cấp balo")
    end
end)

addButton(TabMisc, "Nâng cấp tầm nhìn", function()
    local ev = ReplicatedStorage:FindFirstChild("UpgradeEvent")
    if ev and ev:IsA("RemoteEvent") then
        ev:FireServer("Eyesight", 2)
        notify("Đã nâng cấp tầm nhìn")
    end
end)

-- VÒNG LẶP XỬ LÝ CHÍNH
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

-- XỬ LÝ BAY MƯỢT BẰNG C_FRAME HOẶC VELOCITY CẢI TIẾN
RunService.RenderStepped:Connect(function(dt)
    if not Config.Fly then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end

    local camCF = Camera.CFrame
    local moveDir = Vector3.zero

    if hum.MoveDirection.Magnitude > 0.05 then
        moveDir = hum.MoveDirection.Unit
    end

    if Config.FlyForward then moveDir = moveDir + camCF.LookVector end
    if Config.FlyBack then moveDir = moveDir - camCF.LookVector end
    if Config.FlyLeft then moveDir = moveDir - camCF.RightVector end
    if Config.FlyRight then moveDir = moveDir + camCF.RightVector end
    if Config.FlyUp then moveDir = moveDir + Vector3.new(0, 1, 0) end
    if Config.FlyDown then moveDir = moveDir - Vector3.new(0, 1, 0) end

    if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + camCF.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - camCF.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - camCF.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + camCF.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveDir = moveDir - Vector3.new(0, 1, 0) end

    if moveDir.Magnitude > 0 then
        moveDir = moveDir.Unit
        hrp.Velocity = moveDir * Config.FlySpeed
    else
        hrp.Velocity = Vector3.new(0, 0.1, 0) -- Giữ lơ lửng không bị rơi
    end
    
    hrp.CFrame = CFrame.new(hrp.Position, hrp.Position + camCF.LookVector)
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

print("[ollie] menu ngang + bay siêu mượt đã được tải!")
