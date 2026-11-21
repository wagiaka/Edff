-- 99 Nights in the Forest — ollie v6 (solo map, PC + mobile)
-- Dán vào executor khi đã vào game.

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS        = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting   = game:GetService("Lighting")
local RS         = game:GetService("ReplicatedStorage")
local Workspace  = game:GetService("Workspace")

local LP        = Players.LocalPlayer
local PlayerGui = LP:WaitForChild("PlayerGui")

-- ================= REMOTES =================
local Remotes     = RS:WaitForChild("RemoteEvents", 10)
local EquipRE     = Remotes and Remotes:FindFirstChild("EquipItemHandle")
local UnequipRE   = Remotes and Remotes:FindFirstChild("UnequipItemHandle")
local DamageRF    = Remotes and Remotes:FindFirstChild("ToolDamageObject")
local MapRE       = Remotes and Remotes:FindFirstChild("MapCellsDiscovered")
local DragRE      = Remotes and Remotes:FindFirstChild("RequestStartDraggingItem")
local StopDragRE  = Remotes and Remotes:FindFirstChild("StopDraggingItem")
local HitSoundRE  = Remotes and Remotes:FindFirstChild("PlayEnemyHitSound")

-- ================= DANH SÁCH VŨ KHÍ =================
local WEAPONS = {
    "Old Axe", "Good Axe", "Ice Axe", "Strong Axe", "Chainsaw",
    "Admin Axe", "Spear", "Honey Spear", "Morningstar", "Katana",
    "Laser Sword", "Ice Sword", "Trident", "Poison Claws", "Poison Spear",
    "Infernal Sword", "Cultist King Mace", "Brutal Battleaxe",
    "Obsidiron Hammer", "Scythe", "Vampire Scythe", "Happy's Scythe",
}

-- ================= CONFIG =================
local CFG = {
    Speed      = false, WalkSpeed  = 40,
    Jump       = false, JumpPower  = 90,
    Fly        = false, FlySpeed   = 60,
    KillAura   = false, KillRadius = 40,
    AutoChop   = false, ChopRadius = 120,
    AutoDrop   = false,
    ESPChild   = false,
    Fullbright = false,
    Delay      = 0.5,
}

local TOOL_SUFFIX = "11960515286"
local CHILD_KEY   = "Lost Child"
local DROP_KEYS   = { "Ladder", "Chair", "Head", "Plank", "Log", "Stick", "Wood" }

-- ================= HELPERS =================
local function hasKey(name, keys)
    local n = string.lower(name)
    for _, k in ipairs(keys) do
        if string.find(n, string.lower(k), 1, true) then return true end
    end
    return false
end

local function root()
    local c = LP.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function hum()
    local c = LP.Character
    return c and c:FindFirstChildOfClass("Humanoid")
end

local function partOf(m)
    if not m then return nil end
    if m:IsA("BasePart") then return m end
    return m:FindFirstChildWhichIsA("BasePart", true)
end

-- Tự động tìm vũ khí đang có trong Inventory hoặc Character
-- Ưu tiên theo thứ tự danh sách WEAPONS, fallback lấy bất kỳ tool nào
local function getTool()
    local inv = LP:FindFirstChild("Inventory")
    local char = LP.Character

    -- Ưu tiên: tìm theo danh sách vũ khí đã biết
    for _, name in ipairs(WEAPONS) do
        local t = (inv and inv:FindFirstChild(name))
            or (char and char:FindFirstChild(name))
        if t then return t end
    end

    -- Fallback: lấy Tool bất kỳ trong Inventory
    if inv then
        local t = inv:FindFirstChildWhichIsA("Tool")
        if t then return t end
        -- Hoặc tìm không phải Tool class (một số game dùng Model)
        for _, item in ipairs(inv:GetChildren()) do
            if item:IsA("Model") or item:IsA("Tool") then return item end
        end
    end

    -- Fallback cuối: tool đang cầm trong tay
    return char and char:FindFirstChildWhichIsA("Tool")
end

local function getFirePart()
    local map  = Workspace:FindFirstChild("Map")
    local camp = map and map:FindFirstChild("Campground")
    local fire = camp and camp:FindFirstChild("MainFire", true)
    if fire then return partOf(fire) end
    for _, o in ipairs(Workspace:GetDescendants()) do
        if o.Name == "MainFire" or o.Name == "Campfire" then
            local p = partOf(o)
            if p then return p end
        end
    end
end

-- ================= CACHE TRẺ =================
local childCache = {}
task.spawn(function()
    while true do
        local out = {}
        for _, o in ipairs(Workspace:GetDescendants()) do
            if o:IsA("Model") and string.find(o.Name, CHILD_KEY, 1, true) then
                table.insert(out, o)
            end
        end
        childCache = out
        task.wait(1)
    end
end)

-- ================= COUNTER DEBUG ID =================
local hitCounter = 0
local function resetCounter() hitCounter = 0 end

Workspace.ChildAdded:Connect(function(c)
    if c.Name == "Map" then resetCounter() end
end)
Workspace.ChildRemoved:Connect(function(c)
    if c.Name == "Map" then resetCounter() end
end)
LP.CharacterAdded:Connect(function()
    task.wait(0.5)
    resetCounter()
    if CFG.Fly then startFly() end
end)

local function nextId()
    hitCounter += 1
    return hitCounter .. "_" .. TOOL_SUFFIX
end

-- ================= SWING =================
local function swing(tool, target, p)
    if not (EquipRE and UnequipRE and DamageRF) then return false end

    pcall(EquipRE.FireServer, EquipRE, "FireAllClients", tool)
    task.wait(0.05)

    local ok = pcall(DamageRF.InvokeServer, DamageRF,
        target, tool, nextId(), CFrame.new(p.Position), false)

    if HitSoundRE then
        pcall(HitSoundRE.FireServer, HitSoundRE, "FireAllClients", target, tool)
    end

    task.wait(0.03)
    pcall(UnequipRE.FireServer, UnequipRE, "FireAllClients", tool)
    return ok
end

-- ================= KILL AURA =================
-- Quét nhiều folder khác nhau, không dùng tên cứng
local SCAN_FOLDERS = { "Characters", "Map", "Enemies", "Mobs", "NPCs" }

local function getAnimals(r)
    local out, ch, seen = {}, LP.Character, {}

    local function tryAdd(o)
        if seen[o] then return end
        seen[o] = true
        if o == ch then return end
        if Players:GetPlayerFromCharacter(o) then return end
        if string.find(o.Name, CHILD_KEY, 1, true) then return end

        local h = o:FindFirstChildWhichIsA("Humanoid", true)
        if not (h and h.Health > 0) then return end
        local p = partOf(o)
        if not p then return end

        local d = (p.Position - r.Position).Magnitude
        if d <= CFG.KillRadius then
            table.insert(out, { m = o, p = p, d = d })
        end
    end

    -- Quét workspace trực tiếp
    for _, o in ipairs(Workspace:GetChildren()) do
        if o:IsA("Model") then tryAdd(o) end
    end

    -- Quét các folder phổ biến
    for _, fname in ipairs(SCAN_FOLDERS) do
        local folder = Workspace:FindFirstChild(fname)
        if folder then
            for _, o in ipairs(folder:GetDescendants()) do
                if o:IsA("Model") then tryAdd(o) end
            end
        end
    end

    table.sort(out, function(a, b) return a.d < b.d end)
    return out
end

-- ================= AUTO CHOP =================
local skipTree = {}

local function getTrees(r)
    local out = {}

    -- Tìm Foliage trong mọi Map có thể có
    local function scanFoliage(folder)
        if not folder then return end
        for _, t in ipairs(folder:GetChildren()) do
            if not (skipTree[t] and os.clock() < skipTree[t]) then
                local p = partOf(t)
                if p then
                    local d = (p.Position - r.Position).Magnitude
                    if d <= CFG.ChopRadius then
                        table.insert(out, { m = t, p = p, d = d })
                    end
                end
            end
        end
    end

    -- Thử các đường dẫn phổ biến
    local map = Workspace:FindFirstChild("Map")
    scanFoliage(map and map:FindFirstChild("Foliage"))
    scanFoliage(map and map:FindFirstChild("Trees"))
    scanFoliage(Workspace:FindFirstChild("Foliage"))
    scanFoliage(Workspace:FindFirstChild("Trees"))

    -- Nếu vẫn rỗng: quét toàn Workspace tìm model có tên liên quan đến cây
    if #out == 0 then
        local TREE_KEYS = { "Tree", "Pine", "Oak", "Birch", "Fir", "Bush", "Log" }
        for _, o in ipairs(Workspace:GetDescendants()) do
            if o:IsA("Model") and hasKey(o.Name, TREE_KEYS) then
                if not (skipTree[o] and os.clock() < skipTree[o]) then
                    local p = partOf(o)
                    if p then
                        local d = (p.Position - r.Position).Magnitude
                        if d <= CFG.ChopRadius then
                            table.insert(out, { m = o, p = p, d = d })
                        end
                    end
                end
            end
        end
    end

    table.sort(out, function(a, b) return a.d < b.d end)
    return out
end

-- ================= VÒNG LẶP COMBAT =================
task.spawn(function()
    while true do
        task.wait(CFG.Delay)

        if CFG.KillAura then
            local r, tool = root(), getTool()
            if r and tool then
                for _, t in ipairs(getAnimals(r)) do
                    swing(tool, t.m, t.p)
                    task.wait(0.1)
                end
            end
        end

        if CFG.AutoChop then
            local r, tool = root(), getTool()
            if r and tool then
                local trees = getTrees(r)
                if #trees > 0 then
                    local t = trees[1]
                    local ok = swing(tool, t.m, t.p)
                    if ok then
                        skipTree[t.m] = os.clock() + 2.5
                    end
                end
            end
        end
    end
end)

-- ================= MOVEMENT =================
RunService.Heartbeat:Connect(function()
    local h = hum()
    if not h then return end
    if CFG.Speed then h.WalkSpeed = CFG.WalkSpeed end
    if CFG.Jump  then
        h.UseJumpPower = true
        h.JumpPower    = CFG.JumpPower
    end
end)

-- ================= FLY =================
local flyBV, flyBG, flyConn
local padUp, padDown = false, false

local function stopFly()
    if flyConn then flyConn:Disconnect(); flyConn = nil end
    if flyBV and flyBV.Parent then flyBV:Destroy() end
    if flyBG and flyBG.Parent then flyBG:Destroy() end
    flyBV, flyBG = nil, nil
    local h = hum()
    if h then h.PlatformStand = false end
end

function startFly()
    stopFly()
    local r, h = root(), hum()
    if not (r and h) then return end
    h.PlatformStand = true

    flyBV = Instance.new("BodyVelocity")
    flyBV.MaxForce = Vector3.new(1e6, 1e6, 1e6)
    flyBV.Velocity = Vector3.zero
    flyBV.Parent   = r

    flyBG = Instance.new("BodyGyro")
    flyBG.MaxTorque = Vector3.new(1e6, 1e6, 1e6)
    flyBG.P        = 1e4
    flyBG.Parent   = r

    flyConn = RunService.Heartbeat:Connect(function()
        local cam = Workspace.CurrentCamera
        local rr, hh = root(), hum()
        if not (cam and rr and hh and flyBV and flyBV.Parent) then return end

        local md  = hh.MoveDirection
        local vy  = 0
        if UIS:IsKeyDown(Enum.KeyCode.Space)       or padUp   then vy =  1 end
        if UIS:IsKeyDown(Enum.KeyCode.LeftControl) or padDown then vy = -1 end

        local look  = Vector3.new(cam.CFrame.LookVector.X,  0, cam.CFrame.LookVector.Z)
        local right = Vector3.new(cam.CFrame.RightVector.X, 0, cam.CFrame.RightVector.Z)
        if look.Magnitude  > 0 then look  = look.Unit  end
        if right.Magnitude > 0 then right = right.Unit end

        flyBV.Velocity = (look * -md.Z + right * md.X) * CFG.FlySpeed
            + Vector3.new(0, vy * CFG.FlySpeed, 0)
        flyBG.CFrame = CFrame.new(rr.Position, rr.Position + look)
    end)
end

-- ================= FULLBRIGHT =================
local fbPrev, fbConn

local function applyFB()
    Lighting.Brightness      = 3
    Lighting.ClockTime       = 12
    Lighting.FogEnd          = 1e6
    Lighting.Ambient         = Color3.fromRGB(180, 180, 180)
    Lighting.OutdoorAmbient  = Color3.fromRGB(180, 180, 180)
end

local function setFullbright(on)
    if on then
        if not fbPrev then
            fbPrev = {
                B  = Lighting.Brightness,
                C  = Lighting.ClockTime,
                F  = Lighting.FogEnd,
                A  = Lighting.Ambient,
                OA = Lighting.OutdoorAmbient,
            }
        end
        applyFB()
        if not fbConn then
            fbConn = RunService.Heartbeat:Connect(function()
                if CFG.Fullbright then applyFB() end
            end)
        end
    else
        if fbConn then fbConn:Disconnect(); fbConn = nil end
        if fbPrev then
            Lighting.Brightness     = fbPrev.B
            Lighting.ClockTime      = fbPrev.C
            Lighting.FogEnd         = fbPrev.F
            Lighting.Ambient        = fbPrev.A
            Lighting.OutdoorAmbient = fbPrev.OA
            fbPrev = nil
        end
    end
end

-- ================= ESP TRẺ =================
local espTag = {}

local function clearESPChild()
    for _, hl in pairs(espTag) do if hl and hl.Parent then hl:Destroy() end end
    espTag = {}
end

task.spawn(function()
    while true do
        task.wait(1)
        if CFG.ESPChild then
            for m in pairs(espTag) do
                if not m.Parent then
                    if espTag[m] then espTag[m]:Destroy() end
                    espTag[m] = nil
                end
            end
            for _, m in ipairs(childCache) do
                if m.Parent and not espTag[m] then
                    local hl = Instance.new("Highlight")
                    hl.FillColor        = Color3.fromRGB(255, 220, 80)
                    hl.OutlineColor     = Color3.fromRGB(255, 220, 80)
                    hl.FillTransparency = 0.5
                    hl.Adornee          = m
                    hl.Parent           = m
                    espTag[m]           = hl
                end
            end
        end
    end
end)

-- ================= TP =================
local function tpTo(m)
    local r, p = root(), partOf(m)
    if r and p then r.CFrame = CFrame.new(p.Position + Vector3.new(0, 4, 0)) end
end

local function tpCampfire()
    local fp = getFirePart()
    local r  = root()
    if fp and r then r.CFrame = CFrame.new(fp.Position + Vector3.new(0, 4, 0)) end
end

-- ================= REVEAL MAP =================
local function revealMap()
    if not MapRE then warn("[ollie] Thiếu MapCellsDiscovered"); return end
    local cells = {}
    for row = 1, 64 do
        for col = 1, 64 do table.insert(cells, { Row = row, Col = col }) end
    end
    for i = 1, #cells, 200 do
        local b = {}
        for j = i, math.min(i + 199, #cells) do table.insert(b, cells[j]) end
        pcall(MapRE.FireServer, MapRE, b, {})
        task.wait(0.1)
    end
    print("[ollie] Reveal map đã gửi")
end

-- ================= DỒN ĐỒ VỀ LỬA =================
local droppedAt = {}

local function dropScan()
    local fp = getFirePart()
    if not (fp and DragRE and StopDragRE) then return 0 end

    local ch, count = LP.Character, 0
    for _, o in ipairs(Workspace:GetDescendants()) do
        if o:IsA("Model") and hasKey(o.Name, DROP_KEYS) then
            if ch and o:IsDescendantOf(ch) then continue end
            if Players:GetPlayerFromCharacter(o) then continue end
            if (droppedAt[o] or 0) + 20 > os.clock() then continue end

            if not o.PrimaryPart then
                pcall(function() o.PrimaryPart = partOf(o) end)
            end
            if not o.PrimaryPart then continue end

            droppedAt[o] = os.clock()
            local offset  = Vector3.new(
                math.random(-25, 25) / 10,
                8 + count * 0.5,
                math.random(-25, 25) / 10
            )

            pcall(DragRE.FireServer, DragRE, o)
            pcall(function() o:SetPrimaryPartCFrame(CFrame.new(fp.Position + offset)) end)
            task.wait(0.05)
            pcall(StopDragRE.FireServer, StopDragRE, o)

            count += 1
            task.wait(0.1)
        end
    end
    return count
end

task.spawn(function()
    while true do
        task.wait(5)
        if CFG.AutoDrop then pcall(dropScan) end
    end
end)

-- ================= GUI =================
local old = PlayerGui:FindFirstChild("ollie_v6")
if old then old:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name           = "ollie_v6"
gui.ResetOnSpawn   = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent         = PlayerGui

local C_BG  = Color3.fromRGB(14, 15, 20)
local C_HDR = Color3.fromRGB(20, 22, 30)
local C_ROW = Color3.fromRGB(24, 26, 36)
local C_ON  = Color3.fromRGB(75, 190, 115)
local C_OFF = Color3.fromRGB(50, 53, 68)
local C_TXT = Color3.fromRGB(215, 218, 230)
local C_ACC = Color3.fromRGB(105, 220, 160)
local C_BTN = Color3.fromRGB(180, 210, 255)
local C_SUB = Color3.fromRGB(140, 142, 158)

local function mkCorner(p, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 7)
    c.Parent = p
end

local function mkStroke(p, col, th)
    local s = Instance.new("UIStroke")
    s.Color     = col or Color3.fromRGB(40, 43, 55)
    s.Thickness = th or 1
    s.Parent    = p
end

local function makeDraggable(handle, target)
    local drag, si, sp
    handle.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            drag = true; si = i.Position; sp = target.Position
        end
    end)
    handle.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            drag = false
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if not drag then return end
        if i.UserInputType == Enum.UserInputType.MouseMovement
        or i.UserInputType == Enum.UserInputType.Touch then
            local d = i.Position - si
            target.Position = UDim2.new(
                sp.X.Scale, sp.X.Offset + d.X,
                sp.Y.Scale, sp.Y.Offset + d.Y
            )
        end
    end)
end

-- FAB
local fab = Instance.new("TextButton")
fab.Size             = UDim2.new(0, 44, 0, 44)
fab.Position         = UDim2.new(0, 10, 0.5, -22)
fab.BackgroundColor3 = C_HDR
fab.Text             = "99"
fab.Font             = Enum.Font.GothamBold
fab.TextSize         = 13
fab.TextColor3       = C_ACC
fab.Visible          = false
fab.Parent           = gui
mkCorner(fab, 22)
mkStroke(fab, C_ACC, 1.5)
makeDraggable(fab, fab)

-- Panel
local W, H = 400, 320
local panel = Instance.new("Frame")
panel.Size             = UDim2.new(0, W, 0, H)
panel.Position         = UDim2.new(0.5, -W/2, 0.5, -H/2)
panel.BackgroundColor3 = C_BG
panel.BorderSizePixel  = 0
panel.Parent           = gui
mkCorner(panel, 10)
mkStroke(panel, Color3.fromRGB(38, 40, 55), 1)

local header = Instance.new("Frame")
header.Size             = UDim2.new(1, 0, 0, 32)
header.BackgroundColor3 = C_HDR
header.BorderSizePixel  = 0
header.Parent           = panel
mkCorner(header, 10)
makeDraggable(header, panel)

local titleLbl = Instance.new("TextLabel")
titleLbl.Size               = UDim2.new(1, -44, 1, 0)
titleLbl.Position           = UDim2.new(0, 10, 0, 0)
titleLbl.BackgroundTransparency = 1
titleLbl.Text               = "🌲  99 Nights · ollie v6"
titleLbl.TextColor3         = C_ACC
titleLbl.Font               = Enum.Font.GothamBold
titleLbl.TextSize           = 13
titleLbl.TextXAlignment     = Enum.TextXAlignment.Left
titleLbl.Parent             = header

local minBtn = Instance.new("TextButton")
minBtn.Size             = UDim2.new(0, 26, 0, 26)
minBtn.Position         = UDim2.new(1, -30, 0, 3)
minBtn.BackgroundColor3 = C_OFF
minBtn.Text             = "–"
minBtn.TextColor3       = C_TXT
minBtn.Font             = Enum.Font.GothamBold
minBtn.TextSize         = 16
minBtn.Parent           = header
mkCorner(minBtn, 6)

minBtn.MouseButton1Click:Connect(function()
    panel.Visible = false; fab.Visible = true
end)
fab.MouseButton1Click:Connect(function()
    panel.Visible = true; fab.Visible = false
end)

-- Body 2 cột
local body = Instance.new("Frame")
body.Size               = UDim2.new(1, -12, 1, -38)
body.Position           = UDim2.new(0, 6, 0, 36)
body.BackgroundTransparency = 1
body.Parent             = panel

local function mkScroll(xScale, xOff)
    local sf = Instance.new("ScrollingFrame")
    sf.Size                = UDim2.new(xScale, -3, 1, 0)
    sf.Position            = UDim2.new(xOff, xOff > 0 and 3 or 0, 0, 0)
    sf.BackgroundTransparency = 1
    sf.BorderSizePixel     = 0
    sf.ScrollBarThickness  = 2
    sf.ScrollBarImageColor3 = C_ACC
    sf.AutomaticCanvasSize = Enum.AutomaticSize.Y
    sf.CanvasSize          = UDim2.new(0, 0, 0, 0)
    sf.Parent              = body
    local l = Instance.new("UIListLayout")
    l.Padding             = UDim.new(0, 4)
    l.HorizontalAlignment = Enum.HorizontalAlignment.Center
    l.Parent              = sf
    local p = Instance.new("UIPadding")
    p.PaddingTop = UDim.new(0, 2); p.Parent = sf
    return sf
end

local left  = mkScroll(0.5, 0)
local right = mkScroll(0.5, 0.5)

-- Nút ▲▼ Fly mobile
local flyPad = Instance.new("Frame")
flyPad.Size               = UDim2.new(0, 60, 0, 124)
flyPad.Position           = UDim2.new(1, -70, 1, -132)
flyPad.BackgroundTransparency = 1
flyPad.Visible            = false
flyPad.Parent             = gui

local function holdBtn(yOff, text, onState)
    local b = Instance.new("TextButton")
    b.Size             = UDim2.new(0, 56, 0, 56)
    b.Position         = UDim2.new(0, 0, 0, yOff)
    b.BackgroundColor3 = C_ROW
    b.BorderSizePixel  = 0
    b.Text             = text
    b.TextColor3       = C_ACC
    b.Font             = Enum.Font.GothamBold
    b.TextSize         = 20
    b.Parent           = flyPad
    mkCorner(b, 28); mkStroke(b, C_ACC, 1)
    b.MouseButton1Down:Connect(function() onState(true) end)
    b.MouseButton1Up:Connect(function() onState(false) end)
    b.MouseLeave:Connect(function() onState(false) end)
    b.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.Touch then onState(true) end
    end)
    b.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.Touch then onState(false) end
    end)
end
holdBtn(0,  "▲", function(v) padUp   = v end)
holdBtn(68, "▼", function(v) padDown = v end)

-- Toggle
local function toggle(parent, label, getV, setV)
    local row = Instance.new("Frame")
    row.Size             = UDim2.new(0.95, 0, 0, 28)
    row.BackgroundColor3 = C_ROW
    row.BorderSizePixel  = 0
    row.Parent           = parent
    mkCorner(row, 6)

    local lb = Instance.new("TextLabel")
    lb.Size               = UDim2.new(1, -50, 1, 0)
    lb.Position           = UDim2.new(0, 8, 0, 0)
    lb.BackgroundTransparency = 1
    lb.Text               = label
    lb.TextColor3         = C_TXT
    lb.Font               = Enum.Font.Gotham
    lb.TextSize           = 11
    lb.TextXAlignment     = Enum.TextXAlignment.Left
    lb.Parent             = row

    local track = Instance.new("TextButton")
    track.Size             = UDim2.new(0, 38, 0, 18)
    track.Position         = UDim2.new(1, -44, 0.5, -9)
    track.BorderSizePixel  = 0
    track.Text             = ""
    track.Parent           = row
    mkCorner(track, 9)

    local knob = Instance.new("Frame")
    knob.Size             = UDim2.new(0, 14, 0, 14)
    knob.AnchorPoint      = Vector2.new(0, 0.5)
    knob.BackgroundColor3 = Color3.new(1, 1, 1)
    knob.BorderSizePixel  = 0
    knob.Parent           = track
    mkCorner(knob, 7)

    local function refresh(instant)
        local on = getV()
        track.BackgroundColor3 = on and C_ON or C_OFF
        local goal = { Position = on and UDim2.new(1, -16, 0.5, 0) or UDim2.new(0, 2, 0.5, 0) }
        if instant then knob.Position = goal.Position
        else TweenService:Create(knob, TweenInfo.new(0.12), goal):Play() end
    end
    refresh(true)
    track.MouseButton1Click:Connect(function() setV(not getV()); refresh() end)
end

local function button(parent, text, cb)
    local b = Instance.new("TextButton")
    b.Size             = UDim2.new(0.95, 0, 0, 26)
    b.BackgroundColor3 = C_ROW
    b.BorderSizePixel  = 0
    b.Text             = text
    b.TextColor3       = C_BTN
    b.Font             = Enum.Font.Gotham
    b.TextSize         = 11
    b.Parent           = parent
    mkCorner(b, 6)
    b.MouseButton1Click:Connect(cb)
    return b
end

local function section(parent, text)
    local f = Instance.new("Frame")
    f.Size               = UDim2.new(0.95, 0, 0, 16)
    f.BackgroundTransparency = 1
    f.Parent             = parent
    local l = Instance.new("TextLabel")
    l.Size               = UDim2.new(1, 0, 1, 0)
    l.BackgroundTransparency = 1
    l.Text               = text
    l.TextColor3         = C_ACC
    l.Font               = Enum.Font.GothamBold
    l.TextSize           = 10
    l.TextXAlignment     = Enum.TextXAlignment.Left
    l.Parent             = f
end

-- Chọn vũ khí (dropdown đơn giản)
local weaponLabel = Instance.new("Frame")
weaponLabel.Size             = UDim2.new(0.95, 0, 0, 28)
weaponLabel.BackgroundColor3 = C_ROW
weaponLabel.BorderSizePixel  = 0
weaponLabel.Parent           = left
mkCorner(weaponLabel, 6)

local wLbl = Instance.new("TextLabel")
wLbl.Size               = UDim2.new(1, -8, 1, 0)
wLbl.Position           = UDim2.new(0, 8, 0, 0)
wLbl.BackgroundTransparency = 1
wLbl.TextColor3         = C_TXT
wLbl.Font               = Enum.Font.Gotham
wLbl.TextSize           = 10
wLbl.TextXAlignment     = Enum.TextXAlignment.Left
wLbl.TextTruncate       = Enum.TextTruncate.AtEnd
wLbl.Parent             = weaponLabel

-- Cập nhật tên tool đang dùng mỗi giây
task.spawn(function()
    while true do
        task.wait(1)
        local t = getTool()
        wLbl.Text = "🗡 " .. (t and t.Name or "Không có vũ khí")
    end
end)

-- Populate cột trái
section(left, "MOVEMENT")
toggle(left, "Speed",      function() return CFG.Speed end, function(v) CFG.Speed = v end)
toggle(left, "High Jump",  function() return CFG.Jump  end, function(v) CFG.Jump  = v end)
toggle(left, "Fly",        function() return CFG.Fly   end, function(v)
    CFG.Fly = v; flyPad.Visible = v
    if v then startFly() else stopFly() end
end)
toggle(left, "Fullbright", function() return CFG.Fullbright end, function(v)
    CFG.Fullbright = v; setFullbright(v)
end)

section(left, "COMBAT / CHOP")
toggle(left, "Kill Aura",  function() return CFG.KillAura  end, function(v) CFG.KillAura  = v end)
toggle(left, "Auto Chop",  function() return CFG.AutoChop  end, function(v) CFG.AutoChop  = v end)

section(left, "UTILITY")
toggle(left, "ESP Trẻ",    function() return CFG.ESPChild  end, function(v)
    CFG.ESPChild = v; if not v then clearESPChild() end
end)
toggle(left, "Auto dồn đồ", function() return CFG.AutoDrop end, function(v) CFG.AutoDrop = v end)

button(left, "🔥 TP Lửa trại", tpCampfire)
button(left, "🪵 Dồn đồ ngay", function()
    task.spawn(function()
        local n = dropScan()
        print("[ollie] Đã dồn " .. n .. " món")
    end)
end)
button(left, "🗺️ Reveal map", function() task.spawn(revealMap) end)

-- Populate cột phải: danh sách trẻ
local rHdr = Instance.new("Frame")
rHdr.Size             = UDim2.new(0.95, 0, 0, 26)
rHdr.BackgroundColor3 = C_HDR
rHdr.BorderSizePixel  = 0
rHdr.Parent           = right
mkCorner(rHdr, 6)

local rTitle = Instance.new("TextLabel")
rTitle.Size               = UDim2.new(1, -36, 1, 0)
rTitle.Position           = UDim2.new(0, 8, 0, 0)
rTitle.BackgroundTransparency = 1
rTitle.Text               = "Trẻ em"
rTitle.TextColor3         = C_ACC
rTitle.Font               = Enum.Font.GothamBold
rTitle.TextSize           = 11
rTitle.TextXAlignment     = Enum.TextXAlignment.Left
rTitle.Parent             = rHdr

local scanBtn = Instance.new("TextButton")
scanBtn.Size             = UDim2.new(0, 30, 0, 20)
scanBtn.Position         = UDim2.new(1, -34, 0.5, -10)
scanBtn.BackgroundColor3 = C_ON
scanBtn.Text             = "🔍"
scanBtn.TextSize         = 11
scanBtn.Font             = Enum.Font.Gotham
scanBtn.BorderSizePixel  = 0
scanBtn.Parent           = rHdr
mkCorner(scanBtn, 5)

local childScroll = Instance.new("ScrollingFrame")
childScroll.Size               = UDim2.new(0.95, 0, 1, -32)
childScroll.Position           = UDim2.new(0, 0, 0, 32)
childScroll.BackgroundTransparency = 1
childScroll.BorderSizePixel    = 0
childScroll.ScrollBarThickness = 2
childScroll.ScrollBarImageColor3 = C_ACC
childScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
childScroll.CanvasSize         = UDim2.new(0, 0, 0, 0)
childScroll.Parent             = right
local childLayout = Instance.new("UIListLayout")
childLayout.Padding = UDim.new(0, 4)
childLayout.Parent  = childScroll

local function populateChildren()
    for _, c in ipairs(childScroll:GetChildren()) do
        if c:IsA("GuiObject") then c:Destroy() end
    end

    local r, list = root(), {}
    for _, m in ipairs(childCache) do
        if m.Parent then
            local p = partOf(m)
            if p then
                local d = r and math.floor((p.Position - r.Position).Magnitude) or 0
                table.insert(list, { m = m, p = p, d = d })
            end
        end
    end
    table.sort(list, function(a, b) return a.d < b.d end)

    if #list == 0 then
        local e = Instance.new("TextLabel")
        e.Size               = UDim2.new(1, 0, 0, 24)
        e.BackgroundTransparency = 1
        e.Text               = "Không tìm thấy"
        e.TextColor3         = C_SUB
        e.Font               = Enum.Font.Gotham
        e.TextSize           = 11
        e.Parent             = childScroll
        return
    end

    for i, item in ipairs(list) do
        local row = Instance.new("Frame")
        row.Size             = UDim2.new(1, -4, 0, 48)
        row.BackgroundColor3 = C_ROW
        row.BorderSizePixel  = 0
        row.Parent           = childScroll
        mkCorner(row, 6)

        local nameLbl = Instance.new("TextLabel")
        nameLbl.Size               = UDim2.new(1, -50, 0, 20)
        nameLbl.Position           = UDim2.new(0, 8, 0, 4)
        nameLbl.BackgroundTransparency = 1
        nameLbl.Text               = string.format("%d. %s", i, item.m.Name)
        nameLbl.TextColor3         = C_TXT
        nameLbl.Font               = Enum.Font.GothamBold
        nameLbl.TextSize           = 11
        nameLbl.TextXAlignment     = Enum.TextXAlignment.Left
        nameLbl.TextTruncate       = Enum.TextTruncate.AtEnd
        nameLbl.Parent             = row

        local distLbl = Instance.new("TextLabel")
        distLbl.Size               = UDim2.new(1, -50, 0, 16)
        distLbl.Position           = UDim2.new(0, 8, 0, 24)
        distLbl.BackgroundTransparency = 1
        distLbl.Text               = string.format("📍 %d studs", item.d)
        distLbl.TextColor3         = C_SUB
        distLbl.Font               = Enum.Font.Gotham
        distLbl.TextSize           = 10
        distLbl.TextXAlignment     = Enum.TextXAlignment.Left
        distLbl.Parent             = row

        local tpBtn = Instance.new("TextButton")
        tpBtn.Size             = UDim2.new(0, 36, 0, 20)
        tpBtn.Position         = UDim2.new(1, -42, 0.5, -10)
        tpBtn.BackgroundColor3 = C_ON
        tpBtn.BorderSizePixel  = 0
        tpBtn.Text             = "TP"
        tpBtn.TextColor3       = Color3.new(1, 1, 1)
        tpBtn.Font             = Enum.Font.GothamBold
        tpBtn.TextSize         = 11
        tpBtn.Parent           = row
        mkCorner(tpBtn, 5)
        tpBtn.MouseButton1Click:Connect(function() tpTo(item.m) end)
    end
end

scanBtn.MouseButton1Click:Connect(populateChildren)

print("[ollie] v6 loaded ✓")
