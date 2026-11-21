-- 99 Nights in the Forest — ollie v4 (PC + mobile)
-- Dán vào executor khi đã vào game.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local RS = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local LP = Players.LocalPlayer
local PlayerGui = LP:WaitForChild("PlayerGui")

-- ================= REMOTES (từ capture Cobalt) =================
local Remotes = RS:WaitForChild("RemoteEvents", 10)
local EquipRE    = Remotes and Remotes:FindFirstChild("EquipItemHandle")
local UnequipRE  = Remotes and Remotes:FindFirstChild("UnequipItemHandle")
local DamageRF   = Remotes and Remotes:FindFirstChild("ToolDamageObject")
local MapRE      = Remotes and Remotes:FindFirstChild("MapCellsDiscovered")
local DragRE     = Remotes and Remotes:FindFirstChild("RequestStartDraggingItem")
local StopDragRE = Remotes and Remotes:FindFirstChild("StopDraggingItem")

-- ================= CONFIG =================
local CFG = {
    Speed = false, WalkSpeed = 40,
    Jump = false, JumpPower = 90,
    Fly = false, FlySpeed = 60,
    KillAura = false, KillRadius = 40,
    AutoChop = false, ChopRadius = 120,
    AutoDrop = false,
    ESPChild = false,
    Fullbright = false,
    Tool = "Old Axe",
    Delay = 0.5,
}

local TOOL_SUFFIX = "11960515286" -- phần cuối debug ID của tool, lấy từ capture
local CHILD_KEY = "Lost Child"
local ANIMAL_KEYS = { "Wolf", "Bear", "Boar", "Deer", "Rabbit", "Fox", "Cultist" }
local DROP_KEYS = { "Ladder", "Chair", "Head" }

local cache = { animals = {}, trees = {}, children = {} }

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

local function getTool()
    local inv = LP:FindFirstChild("Inventory")
    local t = inv and inv:FindFirstChild(CFG.Tool)
    if not t and LP.Character then t = LP.Character:FindFirstChild(CFG.Tool) end
    return t
end

local function getFirePart()
    local map = Workspace:FindFirstChild("Map")
    local camp = map and map:FindFirstChild("Campground")
    local fire = camp and camp:FindFirstChild("MainFire", true)
    return fire and partOf(fire)
end

-- ================= QUÉT & COMBAT (làm mới liên tục) =================
local MAX_PER_TICK = 3
local skipUntil = {}   -- mục tiêu vừa đánh sẽ tạm bỏ qua để chuyển sang mục khác

local function skipped(m)
    return (skipUntil[m] or 0) > os.clock()
end
local function setSkip(m, sec)
    skipUntil[m] = os.clock() + sec
end

-- Trẻ: cập nhật mỗi 1 giây (dùng cho ESP và danh sách trẻ)
local function scanChildren()
    local out = {}
    for _, o in ipairs(Workspace:GetDescendants()) do
        if o:IsA("Model") and string.find(o.Name, CHILD_KEY, 1, true) then
            table.insert(out, o)
        end
    end
    cache.children = out
end

-- Quái/thú: mọi Model có máu, trừ người chơi và trẻ
local function scanAnimals()
    local out, ch = {}, LP.Character
    for _, o in ipairs(Workspace:GetDescendants()) do
        if o:IsA("Model") and o ~= ch
            and not Players:GetPlayerFromCharacter(o)
            and not string.find(o.Name, CHILD_KEY, 1, true) then
            local h = o:FindFirstChildWhichIsA("Humanoid", true)
            if h and h.Health > 0 and partOf(o) then
                table.insert(out, o)
            end
        end
    end
    return out
end

task.spawn(function()
    while true do
        pcall(scanChildren)
        task.wait(1)
    end
end)

-- Counter debug ID (reset khi đổi map / spawn lại)
local hitCounter = 0
local function resetCounter() hitCounter = 0 end
Workspace.ChildAdded:Connect(function(c) if c.Name == "Map" then resetCounter() end end)
Workspace.ChildRemoved:Connect(function(c) if c.Name == "Map" then resetCounter() end end)
LP.CharacterAdded:Connect(resetCounter)

local function nextDebugId()
    hitCounter = hitCounter + 1
    return hitCounter .. "_" .. TOOL_SUFFIX
end

local function swing(tool, target, p)
    if not (EquipRE and UnequipRE and DamageRF) then return end
    pcall(EquipRE.FireServer, EquipRE, "FireAllClients", tool)
    task.wait(0.05)
    pcall(DamageRF.InvokeServer, DamageRF, target, tool, nextDebugId(), CFrame.new(p.Position), false)
    task.wait(0.03)
    pcall(UnequipRE.FireServer, UnequipRE, "FireAllClients", tool)
end

-- Gom mục tiêu hiện có (quét lại mỗi lượt, không dùng cache cũ)
local function collectTargets(r)
    local list = {}

    if CFG.KillAura then
        for _, m in ipairs(scanAnimals()) do
            local p = partOf(m)
            if p and not skipped(m) then
                local d = (p.Position - r.Position).Magnitude
                if d <= CFG.KillRadius then
                    table.insert(list, { m = m, p = p, d = d, kind = "animal" })
                end
            end
        end
    end

    if CFG.AutoChop then
        local map = Workspace:FindFirstChild("Map")
        local foliage = map and map:FindFirstChild("Foliage")
        if foliage then
            for _, t in ipairs(foliage:GetChildren()) do
                local p = partOf(t)
                if p and not skipped(t) then
                    local d = (p.Position - r.Position).Magnitude
                    if d <= CFG.ChopRadius then
                        table.insert(list, { m = t, p = p, d = d, kind = "tree" })
                    end
                end
            end
        end
    end

    table.sort(list, function(a, b) return a.d < b.d end)
    return list
end

task.spawn(function()
    while true do
        task.wait(CFG.Delay)
        if not (CFG.KillAura or CFG.AutoChop) then continue end

        local r, tool = root(), getTool()
        if not (r and tool) then continue end

        local list = collectTargets(r)
        for i = 1, math.min(#list, MAX_PER_TICK) do
            local t = list[i]
            swing(tool, t.m, t.p)
            -- Cây: nghỉ 3 giây rồi mới đánh lại. Quái: nghỉ ngắn, chết thì tự bị lọc
            setSkip(t.m, t.kind == "tree" and 3 or 0.6)
        end
    end
end)

-- ================= MOVEMENT =================
RunService.Heartbeat:Connect(function()
    local h = hum()
    if not h then return end
    if CFG.Speed and h.WalkSpeed ~= CFG.WalkSpeed then h.WalkSpeed = CFG.WalkSpeed end
    if CFG.Jump then
        h.UseJumpPower = true
        if h.JumpPower ~= CFG.JumpPower then h.JumpPower = CFG.JumpPower end
    end
end)

-- ================= FLY (PC + mobile) =================
local flyBV, flyBG, flyConn
local padUp, padDown = false, false -- set bởi nút ▲ ▼ trên mobile

local function stopFly()
    if flyConn then flyConn:Disconnect(); flyConn = nil end
    if flyBV then flyBV:Destroy(); flyBV = nil end
    if flyBG then flyBG:Destroy(); flyBG = nil end
    local h = hum()
    if h then h.PlatformStand = false end
end

local function startFly()
    stopFly()
    local r, h = root(), hum()
    if not (r and h) then return end

    h.PlatformStand = true

    flyBV = Instance.new("BodyVelocity")
    flyBV.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    flyBV.Velocity = Vector3.zero
    flyBV.Parent = r

    flyBG = Instance.new("BodyGyro")
    flyBG.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    flyBG.P = 1e4
    flyBG.Parent = r

    flyConn = RunService.Heartbeat:Connect(function()
        local cam = Workspace.CurrentCamera
        local rr, hh = root(), hum()
        if not (cam and rr and hh and flyBV and flyBV.Parent) then return end

        local md = hh.MoveDirection -- joystick ảo (mobile) và WASD (PC) đều ra vector này
        local vy = 0
        if UIS:IsKeyDown(Enum.KeyCode.Space) or padUp then vy = vy + 1 end
        if UIS:IsKeyDown(Enum.KeyCode.LeftControl) or padDown then vy = vy - 1 end

        flyBV.Velocity = Vector3.new(md.X * CFG.FlySpeed, vy * CFG.FlySpeed, md.Z * CFG.FlySpeed)

        local look = cam.CFrame.LookVector
        flyBG.CFrame = CFrame.new(rr.Position, rr.Position + Vector3.new(look.X, 0, look.Z))
    end)
end

LP.CharacterAdded:Connect(function()
    task.wait(0.5)
    if CFG.Fly then startFly() end
    if CFG.Speed or CFG.Jump then return end
end)

-- ================= ESP TRẺ =================
local espTag = {}

local function clearESPChild()
    for _, hl in pairs(espTag) do if hl then hl:Destroy() end end
    espTag = {}
end

task.spawn(function()
    while true do
        task.wait(1)
        if CFG.ESPChild then
            for m in pairs(espTag) do
                if not m.Parent then espTag[m] = nil end
            end
            for _, m in ipairs(cache.children) do
                if m.Parent and not espTag[m] then
                    local hl = Instance.new("Highlight")
                    hl.FillColor = Color3.fromRGB(255, 220, 80)
                    hl.OutlineColor = Color3.fromRGB(255, 220, 80)
                    hl.FillTransparency = 0.6
                    hl.Adornee = m
                    hl.Parent = m
                    espTag[m] = hl
                end
            end
        end
    end
end)

-- ================= FULLBRIGHT =================
local fbPrev
local function setFullbright(on)
    if on then
        fbPrev = fbPrev or { B = Lighting.Brightness, C = Lighting.ClockTime, F = Lighting.FogEnd }
        Lighting.Brightness = 3
        Lighting.ClockTime = 12
        Lighting.FogEnd = 1e6
    elseif fbPrev then
        Lighting.Brightness = fbPrev.B
        Lighting.ClockTime = fbPrev.C
        Lighting.FogEnd = fbPrev.F
        fbPrev = nil
    end
end

-- ================= TP =================
local function tpTo(m)
    local r, p = root(), partOf(m)
    if r and p then r.CFrame = CFrame.new(p.Position + Vector3.new(0, 4, 0)) end
end

local function tpCampfire()
    local fp = getFirePart()
    local r = root()
    if fp and r then r.CFrame = CFrame.new(fp.Position + Vector3.new(0, 4, 0)) end
end

-- ================= REVEAL MAP =================
local function revealMap()
    if not MapRE then warn("[ollie] Thiếu MapCellsDiscovered"); return end
    local cells = {}
    for r = 1, 64 do
        for c = 1, 64 do table.insert(cells, { Row = r, Col = c }) end
    end
    for i = 1, #cells, 200 do
        local b = {}
        for j = i, math.min(i + 199, #cells) do table.insert(b, cells[j]) end
        pcall(MapRE.FireServer, MapRE, b, {})
        task.wait(0.1)
    end
    print("[ollie] Reveal map đã gửi")
end

-- ================= DỒN THANG/GHẾ/ĐẦU VỀ LỬA TRẠI =================
local droppedAt = {}  -- tránh kéo lại cùng một món liên tục

local function dropOnce()
    local fp = getFirePart()
    if not (fp and DragRE and StopDragRE) then return 0 end

    local ch = LP.Character
    local count = 0

    for _, o in ipairs(Workspace:GetDescendants()) do
        if count >= 10 then break end
        if o:IsA("Model") and hasKey(o.Name, DROP_KEYS)
            and (droppedAt[o] or 0) + 30 < os.clock() then
            if ch and o:IsDescendantOf(ch) then continue end
            if Players:GetPlayerFromCharacter(o) then continue end

            if not o.PrimaryPart then pcall(function() o.PrimaryPart = partOf(o) end) end
            if not o.PrimaryPart then continue end

            droppedAt[o] = os.clock()
            local offset = Vector3.new(math.random(-30, 30) / 10, 8 + count * 0.4, math.random(-30, 30) / 10)
            local target = fp.Position + offset

            pcall(DragRE.FireServer, DragRE, o)
            pcall(function() o:SetPrimaryPartCFrame(CFrame.new(target)) end)
            task.wait(0.05)
            pcall(StopDragRE.FireServer, StopDragRE, o)

            count = count + 1
            task.wait(0.1)
        end
    end
    return count
end

-- Tự động dồn: quét lại mỗi 3 giây khi bật
task.spawn(function()
    while true do
        task.wait(3)
        if CFG.AutoDrop then pcall(dropOnce) end
    end
end)

-- ================= GUI =================
local old = PlayerGui:FindFirstChild("ollie_v4")
if old then old:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "ollie_v4"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = PlayerGui

local C_BG  = Color3.fromRGB(16, 17, 23)
local C_HDR = Color3.fromRGB(22, 24, 32)
local C_ROW = Color3.fromRGB(26, 28, 38)
local C_ON  = Color3.fromRGB(80, 195, 120)
local C_OFF = Color3.fromRGB(55, 58, 72)
local C_TXT = Color3.fromRGB(220, 222, 232)
local C_ACC = Color3.fromRGB(110, 225, 165)
local C_SUB = Color3.fromRGB(150, 150, 165)

local function corner(p, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 8)
    c.Parent = p
    return c
end

-- Kéo được bằng chuột và cảm ứng
local function makeDraggable(handle, target)
    local dragging, startInput, startPos
    handle.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            startInput = i.Position
            startPos = target.Position
        end
    end)
    handle.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if not dragging then return end
        if i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch then
            local d = i.Position - startInput
            target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
end

-- Nút thu nhỏ
local fab = Instance.new("TextButton")
fab.Size = UDim2.new(0, 46, 0, 46)
fab.Position = UDim2.new(0, 12, 0.5, -23)
fab.BackgroundColor3 = C_BG
fab.Text = "99"
fab.Font = Enum.Font.GothamBold
fab.TextSize = 14
fab.TextColor3 = C_ACC
fab.Visible = false
fab.Parent = gui
corner(fab, 23)
makeDraggable(fab, fab)

-- Panel chính
local W, H = 380, 300
local panel = Instance.new("Frame")
panel.Size = UDim2.new(0, W, 0, H)
panel.Position = UDim2.new(0.5, -W / 2, 0.5, -H / 2)
panel.BackgroundColor3 = C_BG
panel.BorderSizePixel = 0
panel.Parent = gui
corner(panel, 10)

local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 32)
header.BackgroundColor3 = C_HDR
header.BorderSizePixel = 0
header.Parent = panel
corner(header, 10)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -44, 1, 0)
title.Position = UDim2.new(0, 10, 0, 0)
title.BackgroundTransparency = 1
title.Text = "99 Nights · ollie"
title.TextColor3 = C_ACC
title.Font = Enum.Font.GothamBold
title.TextSize = 13
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

local minBtn = Instance.new("TextButton")
minBtn.Size = UDim2.new(0, 26, 0, 26)
minBtn.Position = UDim2.new(1, -30, 0, 3)
minBtn.BackgroundColor3 = C_OFF
minBtn.Text = "–"
minBtn.TextColor3 = C_TXT
minBtn.Font = Enum.Font.GothamBold
minBtn.TextSize = 16
minBtn.Parent = header
corner(minBtn, 6)

makeDraggable(header, panel)

local body = Instance.new("Frame")
body.Size = UDim2.new(1, -12, 1, -38)
body.Position = UDim2.new(0, 6, 0, 36)
body.BackgroundTransparency = 1
body.Parent = panel

-- Cột trái: toggle + nút
local left = Instance.new("ScrollingFrame")
left.Size = UDim2.new(0.5, -3, 1, 0)
left.BackgroundTransparency = 1
left.BorderSizePixel = 0
left.ScrollBarThickness = 2
left.ScrollBarImageColor3 = C_ACC
left.AutomaticCanvasSize = Enum.AutomaticSize.Y
left.CanvasSize = UDim2.new(0, 0, 0, 0)
left.Parent = body
local ll = Instance.new("UIListLayout")
ll.Padding = UDim.new(0, 4)
ll.Parent = left

-- Cột phải: quét trẻ
local right = Instance.new("Frame")
right.Size = UDim2.new(0.5, -3, 1, 0)
right.Position = UDim2.new(0.5, 3, 0, 0)
right.BackgroundTransparency = 1
right.Parent = body

local rScan = Instance.new("TextButton")
rScan.Size = UDim2.new(1, 0, 0, 26)
rScan.BackgroundColor3 = C_ROW
rScan.BorderSizePixel = 0
rScan.Text = "🔍 Quét trẻ"
rScan.TextColor3 = C_TXT
rScan.Font = Enum.Font.GothamBold
rScan.TextSize = 12
rScan.Parent = right
corner(rScan, 6)

local childList = Instance.new("ScrollingFrame")
childList.Size = UDim2.new(1, 0, 1, -30)
childList.Position = UDim2.new(0, 0, 0, 30)
childList.BackgroundTransparency = 1
childList.BorderSizePixel = 0
childList.ScrollBarThickness = 2
childList.ScrollBarImageColor3 = C_ACC
childList.AutomaticCanvasSize = Enum.AutomaticSize.Y
childList.CanvasSize = UDim2.new(0, 0, 0, 0)
childList.Parent = right
local cl = Instance.new("UIListLayout")
cl.Padding = UDim.new(0, 4)
cl.Parent = childList

-- Nút ▲ ▼ cho Fly trên mobile (tạo trước để toggle Fly tham chiếu được)
local flyPad = Instance.new("Frame")
flyPad.Size = UDim2.new(0, 60, 0, 124)
flyPad.Position = UDim2.new(1, -72, 1, -140)
flyPad.BackgroundTransparency = 1
flyPad.Visible = false
flyPad.Parent = gui

local function holdBtn(yOff, text, onState)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 56, 0, 56)
    b.Position = UDim2.new(0, 0, 0, yOff)
    b.BackgroundColor3 = C_ROW
    b.BorderSizePixel = 0
    b.Text = text
    b.TextColor3 = C_ACC
    b.Font = Enum.Font.GothamBold
    b.TextSize = 20
    b.Parent = flyPad
    corner(b, 28)
    b.MouseButton1Down:Connect(function() onState(true) end)
    b.MouseButton1Up:Connect(function() onState(false) end)
    b.MouseLeave:Connect(function() onState(false) end)
end
holdBtn(0, "▲", function(v) padUp = v end)
holdBtn(68, "▼", function(v) padDown = v end)

-- Toggle
local function toggle(label, getV, setV)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -4, 0, 28)
    row.BackgroundColor3 = C_ROW
    row.BorderSizePixel = 0
    row.Parent = left
    corner(row, 6)

    local lb = Instance.new("TextLabel")
    lb.Size = UDim2.new(1, -50, 1, 0)
    lb.Position = UDim2.new(0, 8, 0, 0)
    lb.BackgroundTransparency = 1
    lb.Text = label
    lb.TextColor3 = C_TXT
    lb.Font = Enum.Font.Gotham
    lb.TextSize = 11
    lb.TextXAlignment = Enum.TextXAlignment.Left
    lb.Parent = row

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 38, 0, 18)
    btn.Position = UDim2.new(1, -44, 0.5, -9)
    btn.BorderSizePixel = 0
    btn.Text = ""
    btn.Parent = row
    corner(btn, 9)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 14, 0, 14)
    knob.AnchorPoint = Vector2.new(0, 0.5)
    knob.BackgroundColor3 = Color3.new(1, 1, 1)
    knob.BorderSizePixel = 0
    knob.Parent = btn
    corner(knob, 7)

    local function refresh(instant)
        local on = getV()
        btn.BackgroundColor3 = on and C_ON or C_OFF
        local goal = { Position = on and UDim2.new(1, -16, 0.5, 0) or UDim2.new(0, 2, 0.5, 0) }
        if instant then
            knob.Position = goal.Position
        else
            TweenService:Create(knob, TweenInfo.new(0.12), goal):Play()
        end
    end
    refresh(true)

    btn.MouseButton1Click:Connect(function()
        setV(not getV())
        refresh()
    end)
end

local function button(parent, text, cb)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, -4, 0, 26)
    b.BackgroundColor3 = C_ROW
    b.BorderSizePixel = 0
    b.Text = text
    b.TextColor3 = Color3.fromRGB(190, 215, 255)
    b.Font = Enum.Font.Gotham
    b.TextSize = 11
    b.Parent = parent
    corner(b, 6)
    b.MouseButton1Click:Connect(cb)
    return b
end

toggle("Speed", function() return CFG.Speed end, function(v) CFG.Speed = v end)
toggle("High Jump", function() return CFG.Jump end, function(v) CFG.Jump = v end)
toggle("Fly", function() return CFG.Fly end, function(v)
    CFG.Fly = v
    flyPad.Visible = v
    if v then startFly() else stopFly() end
end)
toggle("Kill Aura", function() return CFG.KillAura end, function(v) CFG.KillAura = v end)
toggle("Auto Chop", function() return CFG.AutoChop end, function(v) CFG.AutoChop = v end)
toggle("Auto dồn đồ", function() return CFG.AutoDrop end, function(v) CFG.AutoDrop = v end)
toggle("ESP Trẻ", function() return CFG.ESPChild end, function(v)
    CFG.ESPChild = v
    if not v then clearESPChild() end
end)
toggle("Fullbright", function() return CFG.Fullbright end, function(v)
    CFG.Fullbright = v
    setFullbright(v)
end)

button(left, "🔥 TP Lửa trại", tpCampfire)
button(left, "🪵 Dồn ngay", function()
    task.spawn(function()
        local n = dropOnce()
        print("[ollie] Đã dồn " .. n .. " món về lửa trại")
    end)
end)
button(left, "🗺️ Reveal map", function() task.spawn(revealMap) end)

-- Danh sách trẻ (quét khi bấm, sắp xếp gần → xa)
local function populateChildren()
    for _, c in ipairs(childList:GetChildren()) do
        if c:IsA("TextButton") or c:IsA("TextLabel") then c:Destroy() end
    end

    local r = root()
    local list = {}
    for _, m in ipairs(cache.children) do
        local p = partOf(m)
        if p then
            local d = r and math.floor((p.Position - r.Position).Magnitude) or 0
            table.insert(list, { m = m, d = d })
        end
    end
    table.sort(list, function(a, b) return a.d < b.d end)

    if #list == 0 then
        local e = Instance.new("TextLabel")
        e.Size = UDim2.new(1, -4, 0, 24)
        e.BackgroundTransparency = 1
        e.Text = "Không thấy trẻ nào"
        e.TextColor3 = C_SUB
        e.Font = Enum.Font.Gotham
        e.TextSize = 11
        e.Parent = childList
        return
    end

    for i, item in ipairs(list) do
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(1, -4, 0, 26)
        b.BackgroundColor3 = C_ROW
        b.BorderSizePixel = 0
        b.Text = string.format("%d. %s  (%dm)", i, item.m.Name, item.d)
        b.TextColor3 = C_TXT
        b.Font = Enum.Font.Gotham
        b.TextSize = 11
        b.TextXAlignment = Enum.TextXAlignment.Left
        b.Parent = childList
        corner(b, 6)
        local pad = Instance.new("UIPadding")
        pad.PaddingLeft = UDim.new(0, 6)
        pad.Parent = b
        b.MouseButton1Click:Connect(function() tpTo(item.m) end)
    end
end
rScan.MouseButton1Click:Connect(populateChildren)

-- Thu nhỏ / mở lại
minBtn.MouseButton1Click:Connect(function()
    panel.Visible = false
    fab.Visible = true
end)
fab.MouseButton1Click:Connect(function()
    panel.Visible = true
    fab.Visible = false
end)

print("[ollie] v4 loaded")
