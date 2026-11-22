-- 99 Nights in the Forest — Ollie UI (Full Functions Integrated)
local Players      = game:GetService("Players")
local RunService   = game:GetService("RunService")
local UIS          = game:GetService("UserInputService")
local Lighting     = game:GetService("Lighting")
local RS           = game:GetService("ReplicatedStorage")
local Workspace    = game:GetService("Workspace")
local CoreGui      = game:GetService("CoreGui")

local LP        = Players.LocalPlayer
local PlayerGui = LP:WaitForChild("PlayerGui")

-- =================== XOÁ MENU CŨ ===================
local function clearOldMenus()
    for _, name in ipairs({"OllieMenu", "ollie_v9"}) do
        pcall(function()
            local g = CoreGui:FindFirstChild(name)
            if g then g:Destroy() end
        end)
        pcall(function()
            local g = PlayerGui:FindFirstChild(name)
            if g then g:Destroy() end
        end)
    end
end
clearOldMenus()

-- =================== REMOTES & DATA ===================
local Remotes    = RS:WaitForChild("RemoteEvents", 10)
local EquipRE    = Remotes and Remotes:FindFirstChild("EquipItemHandle")
local UnequipRE  = Remotes and Remotes:FindFirstChild("UnequipItemHandle")
local DamageRF   = Remotes and Remotes:FindFirstChild("ToolDamageObject")
local MapRE      = Remotes and Remotes:FindFirstChild("MapCellsDiscovered")
local DragRE     = Remotes and Remotes:FindFirstChild("RequestStartDraggingItem")
local StopDragRE = Remotes and Remotes:FindFirstChild("StopDraggingItem")
local HitSoundRE = Remotes and Remotes:FindFirstChild("PlayEnemyHitSound")
local PlantRE    = Remotes and Remotes:FindFirstChild("RequestPlantItem")
local ConsumeRF  = Remotes and Remotes:FindFirstChild("RequestConsumeItem")

local AXES = {
    "Old Axe","Good Axe","Ice Axe","Strong Axe","Chainsaw","Admin Axe",
}
local MELEE_WEAPONS = {
    "Spear","Honey Spear","Morningstar","Katana","Laser Sword","Ice Sword",
    "Trident","Poison Claws","Poison Spear","Infernal Sword",
    "Cultist King Mace","Brutal Battleaxe","Obsidiron Hammer",
    "Scythe","Vampire Scythe","Happy's Scythe",
}
local FOOD_ITEMS  = { "Berry","Carrot","Apple","Corn","Pumpkin","Chili" }
local SCRAP_ITEMS = {
    "Log","Bolt","Sheet Metal","Broken Fan","Broken Radio",
    "Broken Microwave","Washing Machine","Tires & Engines",
}
local FUEL_EXACT = {
    "Log","Chair","Biofuel","Coal",
    "Purple Fur Tuft","Fuel Canister","Oil Barrel",
}

local CFG = {
    Speed=false,      WalkSpeed=40,
    Jump=false,       JumpPower=90,
    Fly=false,        FlySpeed=60,
    Noclip=false,
    KillAura=false,   KillRadius=150,
    AutoChop=false,   ChopRadius=130,
    AutoDrop=false,
    AutoEat=false,
    ESPChild=false,
    Fullbright=false,
    FixLag=false,
    Delay=0.35,
}

local MAX_KILL_PER_CYCLE = 6
local TOOL_SUFFIX = "11960515286"
local CHILD_KEY   = "Lost Child"

-- =================== HELPERS ===================
local function hasKey(name, keys)
    local n = string.lower(name)
    for _, k in ipairs(keys) do
        if string.find(n, string.lower(k), 1, true) then return true end
    end
    return false
end

local function matchesExact(name, list)
    for _, v in ipairs(list) do if name == v then return true end end
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
    if m:IsA("Model") then
        if m.PrimaryPart then return m.PrimaryPart end
        local hrp = m:FindFirstChild("HumanoidRootPart")
        if hrp then return hrp end
        return m:FindFirstChildWhichIsA("BasePart", true)
    end
    return nil
end

local function findFromList(list, inv, char)
    for _, name in ipairs(list) do
        local t = (inv and inv:FindFirstChild(name))
            or (char and char:FindFirstChild(name))
        if t then return t end
    end
end

local function getFallbackTool(inv, char)
    if inv then
        local t = inv:FindFirstChildWhichIsA("Tool")
        if t then return t end
        for _, item in ipairs(inv:GetChildren()) do
            if item:IsA("Model") then return item end
        end
    end
    return char and char:FindFirstChildWhichIsA("Tool")
end

local function getKillTool()
    local inv, char = LP:FindFirstChild("Inventory"), LP.Character
    return findFromList(MELEE_WEAPONS, inv, char)
        or findFromList(AXES, inv, char)
        or getFallbackTool(inv, char)
end

local function getChopTool()
    local inv, char = LP:FindFirstChild("Inventory"), LP.Character
    return findFromList(AXES, inv, char)
        or findFromList(MELEE_WEAPONS, inv, char)
        or getFallbackTool(inv, char)
end

local function getFirePart()
    local map  = Workspace:FindFirstChild("Map")
    local camp = map and map:FindFirstChild("Campground")
    local fire = camp and camp:FindFirstChild("MainFire", true)
    if fire then return partOf(fire) end
    for _, o in ipairs(Workspace:GetDescendants()) do
        if o.Name == "MainFire" or o.Name == "Campfire" then
            local p = partOf(o); if p then return p end
        end
    end
end

local function getNilByName(name)
    local out = {}
    if not getnilinstances then return out end
    local ok, nilList = pcall(getnilinstances)
    if not ok or not nilList then return out end
    for _, obj in ipairs(nilList) do
        local ok2, n = pcall(function() return obj.Name end)
        if ok2 and n == name then
            table.insert(out, obj)
        end
    end
    return out
end

-- =================== CACHE TRẺ ===================
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
        task.wait(1.5)
    end
end)

-- =================== COUNTER & SWING ===================
local hitCounter = 0
local function resetCounter() hitCounter = 0 end
Workspace.ChildAdded:Connect(function(c)
    if c.Name == "Map" then resetCounter() end
end)
Workspace.ChildRemoved:Connect(function(c)
    if c.Name == "Map" then resetCounter() end
end)

local function nextId()
    hitCounter += 1
    return hitCounter .. "_" .. TOOL_SUFFIX
end

local function hitOnce(tool, target, p)
    if not DamageRF then return false end
    local ok = pcall(DamageRF.InvokeServer, DamageRF,
        target, tool, nextId(), CFrame.new(p.Position), false)
    if HitSoundRE then
        pcall(HitSoundRE.FireServer, HitSoundRE, "FireAllClients", target, tool)
    end
    return ok
end

local function swing(tool, target, p)
    if not (EquipRE and UnequipRE and DamageRF) then return false end
    pcall(EquipRE.FireServer, EquipRE, "FireAllClients", tool)
    task.wait(0.03)
    local ok = hitOnce(tool, target, p)
    task.wait(0.025)
    pcall(UnequipRE.FireServer, UnequipRE, "FireAllClients", tool)
    return ok
end

local function swingBatch(tool, targets)
    if not (EquipRE and UnequipRE and DamageRF) or #targets == 0 then return end
    pcall(EquipRE.FireServer, EquipRE, "FireAllClients", tool)
    task.wait(0.03)
    local limit = math.min(#targets, MAX_KILL_PER_CYCLE)
    for i = 1, limit do
        if not CFG.KillAura then break end
        local t = targets[i]
        if t.m and t.m.Parent and t.p and t.p.Parent then
            local h = t.m:FindFirstChildWhichIsA("Humanoid", true)
            if h and h.Health > 0 then hitOnce(tool, t.m, t.p) end
        end
        if i < limit then task.wait(0.05) end
    end
    pcall(UnequipRE.FireServer, UnequipRE, "FireAllClients", tool)
end

-- =================== KILL AURA & AUTO CHOP ===================
local SCAN_FOLDERS = { "Characters","Enemies","Mobs","NPCs" }
local function getAnimals(r)
    local out, ch, seen = {}, LP.Character, {}
    local maxDSq = CFG.KillRadius * CFG.KillRadius
    local rPos   = r.Position

    local function tryAdd(o)
        if seen[o] or o == ch then return end
        seen[o] = true
        if Players:GetPlayerFromCharacter(o) then return end
        if string.find(o.Name, CHILD_KEY, 1, true) then return end
        local h = o:FindFirstChildWhichIsA("Humanoid", true)
        if not (h and h.Health > 0) then return end
        local p = partOf(o); if not p then return end
        local d = p.Position - rPos
        local dSq = d.X*d.X + d.Y*d.Y + d.Z*d.Z
        if dSq <= maxDSq then table.insert(out, {m=o, p=p, dSq=dSq}) end
    end

    for _, o in ipairs(Workspace:GetChildren()) do
        if o:IsA("Model") then tryAdd(o) end
    end
    for _, fn in ipairs(SCAN_FOLDERS) do
        local folder = Workspace:FindFirstChild(fn)
        if folder then
            for _, o in ipairs(folder:GetChildren()) do
                if o:IsA("Model") then tryAdd(o) end
            end
        end
    end
    table.sort(out, function(a,b) return a.dSq < b.dSq end)
    return out
end

local skipTree = {}
local TREE_KEYS = { "Tree","Pine","Oak","Birch","Fir","Bush","Foliage" }

local function getTrees(r)
    local out = {}
    local maxDSq = CFG.ChopRadius * CFG.ChopRadius
    local rPos   = r.Position
    local now    = os.clock()

    local function scanFolder(folder)
        if not folder then return end
        for _, t in ipairs(folder:GetChildren()) do
            if not (skipTree[t] and now < skipTree[t]) then
                local p = partOf(t)
                if p then
                    local d = p.Position - rPos
                    local dSq = d.X*d.X + d.Y*d.Y + d.Z*d.Z
                    if dSq <= maxDSq then
                        table.insert(out, {m=t, p=p, dSq=dSq})
                    end
                end
            end
        end
    end

    local map = Workspace:FindFirstChild("Map")
    scanFolder(map and map:FindFirstChild("Foliage"))
    scanFolder(map and map:FindFirstChild("Trees"))
    scanFolder(Workspace:FindFirstChild("Foliage"))
    scanFolder(Workspace:FindFirstChild("Trees"))

    if #out == 0 then
        local scanRoot = map or Workspace
        for _, o in ipairs(scanRoot:GetDescendants()) do
            if o:IsA("Model") and hasKey(o.Name, TREE_KEYS)
                and not (skipTree[o] and now < skipTree[o]) then
                local p = partOf(o)
                if p then
                    local d = p.Position - rPos
                    local dSq = d.X*d.X + d.Y*d.Y + d.Z*d.Z
                    if dSq <= maxDSq then
                        table.insert(out, {m=o, p=p, dSq=dSq})
                    end
                end
            end
        end
    end
    table.sort(out, function(a,b) return a.dSq < b.dSq end)
    return out
end

task.spawn(function()
    while true do
        task.wait(CFG.Delay)
        if CFG.KillAura then
            local r, tool = root(), getKillTool()
            if r and tool then
                local targets = getAnimals(r)
                if #targets > 0 then swingBatch(tool, targets) end
            end
        end
        if CFG.AutoChop then
            local r, tool = root(), getChopTool()
            if r and tool then
                local trees = getTrees(r)
                if #trees > 0 then
                    local t = trees[1]
                    local ok = swing(tool, t.m, t.p)
                    skipTree[t.m] = os.clock() + (ok and 3.0 or 1.5)
                end
            end
        end
    end
end)

-- =================== MOVEMENT, NOCLIP & FLY ===================
local noclipBackup = {}
local function restoreNoclip()
    for part, wasCollide in pairs(noclipBackup) do
        if part and part.Parent and part:IsA("BasePart") then
            pcall(function() part.CanCollide = wasCollide end)
        end
    end
    noclipBackup = {}
end

RunService.Heartbeat:Connect(function()
    local h = hum(); if not h then return end
    if CFG.Speed then h.WalkSpeed = CFG.WalkSpeed end
    if CFG.Jump  then h.UseJumpPower = true; h.JumpPower = CFG.JumpPower end
end)

RunService.Stepped:Connect(function()
    local c = LP.Character; if not c then return end
    if CFG.Noclip then
        for _, obj in ipairs(c:GetDescendants()) do
            if obj:IsA("BasePart") then
                if noclipBackup[obj] == nil then noclipBackup[obj] = obj.CanCollide end
                if obj.CanCollide then obj.CanCollide = false end
            end
        end
    elseif next(noclipBackup) then
        restoreNoclip()
    end
end)

local flyBV, flyBG, flyConn
local padUp, padDown = false, false

local function stopFly()
    if flyConn then flyConn:Disconnect(); flyConn = nil end
    if flyBV and flyBV.Parent then flyBV:Destroy() end
    if flyBG and flyBG.Parent then flyBG:Destroy() end
    flyBV, flyBG = nil, nil
    local h = hum(); if h then h.PlatformStand = false end
end

local function startFly()
    stopFly()
    local r, h = root(), hum(); if not (r and h) then return end
    h.PlatformStand = true
    flyBV = Instance.new("BodyVelocity")
    flyBV.MaxForce = Vector3.new(1e6,1e6,1e6)
    flyBV.Velocity = Vector3.zero; flyBV.Parent = r
    flyBG = Instance.new("BodyGyro")
    flyBG.MaxTorque = Vector3.new(1e6,1e6,1e6)
    flyBG.P = 1e4; flyBG.Parent = r
    flyConn = RunService.Heartbeat:Connect(function()
        local cam = Workspace.CurrentCamera
        local rr, hh = root(), hum()
        if not (cam and rr and hh and flyBV and flyBV.Parent) then return end
        local md = hh.MoveDirection
        local camLook  = cam.CFrame.LookVector
        local camRight = cam.CFrame.RightVector
        local flatLook  = Vector3.new(camLook.X,  0, camLook.Z)
        local flatRight = Vector3.new(camRight.X, 0, camRight.Z)
        if flatLook.Magnitude  > 0 then flatLook  = flatLook.Unit  end
        if flatRight.Magnitude > 0 then flatRight = flatRight.Unit end
        local moveDir = flatLook * (-md.Z) + flatRight * md.X
        local vy = 0
        if UIS:IsKeyDown(Enum.KeyCode.Space)       or padUp   then vy =  1 end
        if UIS:IsKeyDown(Enum.KeyCode.LeftControl) or padDown then vy = -1 end
        flyBV.Velocity = moveDir * CFG.FlySpeed + Vector3.new(0, vy * CFG.FlySpeed, 0)
        flyBG.CFrame   = CFrame.new(rr.Position, rr.Position + flatLook)
    end)
end

LP.CharacterAdded:Connect(function()
    task.wait(0.5); resetCounter()
    if CFG.Fly then startFly() end
end)

-- =================== FULLBRIGHT & FIX LAG ===================
local fbPrev, fbConn
local function applyFB()
    Lighting.Brightness = 3; Lighting.ClockTime = 12; Lighting.FogEnd = 1e6
    Lighting.Ambient = Color3.fromRGB(180,180,180)
    Lighting.OutdoorAmbient = Color3.fromRGB(180,180,180)
end
local function setFullbright(on)
    if on then
        if not fbPrev then fbPrev = {
            B=Lighting.Brightness, C=Lighting.ClockTime,
            F=Lighting.FogEnd, A=Lighting.Ambient, OA=Lighting.OutdoorAmbient
        } end
        applyFB()
        if not fbConn then
            fbConn = RunService.Heartbeat:Connect(function()
                if CFG.Fullbright then applyFB() end
            end)
        end
    else
        if fbConn then fbConn:Disconnect(); fbConn = nil end
        if fbPrev then
            Lighting.Brightness = fbPrev.B; Lighting.ClockTime = fbPrev.C
            Lighting.FogEnd = fbPrev.F; Lighting.Ambient = fbPrev.A
            Lighting.OutdoorAmbient = fbPrev.OA; fbPrev = nil
        end
    end
end

local LagBackup = {}
local lagConn, lagGen = nil, 0
local HEAVY_MATS = {
    [Enum.Material.Neon]          = Enum.Material.SmoothPlastic,
    [Enum.Material.Glass]         = Enum.Material.SmoothPlastic,
    [Enum.Material.ForceField]    = Enum.Material.SmoothPlastic,
    [Enum.Material.DiamondPlate]  = Enum.Material.SmoothPlastic,
    [Enum.Material.CorrodedMetal] = Enum.Material.SmoothPlastic,
    [Enum.Material.Foil]          = Enum.Material.SmoothPlastic,
    [Enum.Material.WoodPlanks]    = Enum.Material.SmoothPlastic,
    [Enum.Material.Cobblestone]   = Enum.Material.SmoothPlastic,
}
local function saveProp(obj, prop)
    local t = LagBackup[obj]
    if not t then t = {}; LagBackup[obj] = t end
    if t[prop] == nil then
        local ok, val = pcall(function() return obj[prop] end)
        if ok then t[prop] = val end
    end
end
local function optimizeObj(obj)
    if not CFG.FixLag or not obj or not obj.Parent then return end
    if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam")
    or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles")
    or obj:IsA("PointLight") or obj:IsA("SpotLight") or obj:IsA("SurfaceLight") then
        saveProp(obj, "Enabled"); pcall(function() obj.Enabled = false end); return
    end
    if obj:IsA("BasePart") then
        saveProp(obj, "CastShadow"); pcall(function() obj.CastShadow = false end)
        saveProp(obj, "Material")
        local mat = HEAVY_MATS[obj.Material] or Enum.Material.Plastic
        if obj.Material ~= mat then pcall(function() obj.Material = mat end) end
    end
end
local function setFixLag(v)
    if v then
        if CFG.FixLag then return end; CFG.FixLag = true; lagGen += 1; local gen = lagGen
        for _, prop in ipairs({"GlobalShadows","EnvironmentDiffuseScale","EnvironmentSpecularScale","ShadowSoftness"}) do
            saveProp(Lighting, prop)
        end
        pcall(function()
            Lighting.GlobalShadows = false; Lighting.EnvironmentDiffuseScale = 0
            Lighting.EnvironmentSpecularScale = 0; Lighting.ShadowSoftness = 0
        end)
        if not lagConn then
            lagConn = Workspace.DescendantAdded:Connect(function(obj)
                if CFG.FixLag then task.defer(optimizeObj, obj) end
            end)
        end
        task.spawn(function()
            local all = Workspace:GetDescendants()
            for i = 1, #all do
                if not CFG.FixLag or gen ~= lagGen then return end
                optimizeObj(all[i])
                if i % 500 == 0 then task.wait() end
            end
        end)
    else
        if not CFG.FixLag then return end; CFG.FixLag = false; lagGen += 1
        if lagConn then lagConn:Disconnect(); lagConn = nil end
        for obj, props in pairs(LagBackup) do
            if obj and obj.Parent then
                for prop, val in pairs(props) do pcall(function() obj[prop] = val end) end
            end
        end
        LagBackup = {}
    end
end

-- =================== AUTO EAT CARROT ===================
local eatStatusText = "Chờ bật để ăn carrot tự động..."
local eatStatusLbl = nil

local function updateEatStatus(txt, col)
    eatStatusText = txt
    if eatStatusLbl and eatStatusLbl.Parent then
        eatStatusLbl.Text = txt
        if col then eatStatusLbl.TextColor3 = col end
    end
end

task.spawn(function()
    while true do
        task.wait(2)
        if CFG.AutoEat then
            if not ConsumeRF then
                updateEatStatus("❌ Thiếu remote RequestConsumeItem", Color3.fromRGB(255,100,100))
                continue
            end
            if not getnilinstances then
                updateEatStatus("❌ Executor không hỗ trợ getnilinstances", Color3.fromRGB(255,100,100))
                continue
            end
            local carrots = getNilByName("Carrot")
            if #carrots == 0 then
                updateEatStatus("⚠️ Không tìm thấy Carrot", Color3.fromRGB(255,180,60))
                continue
            end
            local ate = 0
            for _, carrot in ipairs(carrots) do
                if not CFG.AutoEat then break end
                local ok = pcall(ConsumeRF.InvokeServer, ConsumeRF, carrot)
                if ok then
                    ate += 1
                    updateEatStatus(string.format("✅ Đã ăn %d carrot", ate), Color3.fromRGB(95,210,135))
                end
                task.wait(0.3)
            end
        end
    end
end)

-- =================== ESP TRẺ ===================
local espTag = {}
local function clearESPChild()
    for _, pair in pairs(espTag) do
        if pair.hl  and pair.hl.Parent  then pair.hl:Destroy()  end
        if pair.bb  and pair.bb.Parent  then pair.bb:Destroy()  end
        if pair.conn then pair.conn:Disconnect() end
    end
    espTag = {}
end

task.spawn(function()
    while true do
        task.wait(0.5)
        if CFG.ESPChild then
            for m, pair in pairs(espTag) do
                if not m.Parent then
                    if pair.hl  and pair.hl.Parent  then pair.hl:Destroy()  end
                    if pair.bb  and pair.bb.Parent  then pair.bb:Destroy()  end
                    if pair.conn then pair.conn:Disconnect() end
                    espTag[m] = nil
                end
            end
            for _, m in ipairs(childCache) do
                if m.Parent and not espTag[m] then
                    local hl = Instance.new("Highlight")
                    hl.FillColor        = Color3.fromRGB(255,220,80)
                    hl.OutlineColor     = Color3.fromRGB(255,220,80)
                    hl.FillTransparency = 0.45
                    hl.Adornee = m; hl.Parent = m
                    local adornPart = partOf(m)
                    local bb, lblConn
                    if adornPart then
                        bb = Instance.new("BillboardGui")
                        bb.Adornee     = adornPart
                        bb.Size        = UDim2.new(0,160,0,44)
                        bb.StudsOffset = Vector3.new(0,3,0)
                        bb.AlwaysOnTop = true; bb.Parent = adornPart
                        local lbl = Instance.new("TextLabel")
                        lbl.Size               = UDim2.new(1,0,1,0)
                        lbl.BackgroundTransparency = 1
                        lbl.TextColor3         = Color3.fromRGB(255,230,80)
                        lbl.TextStrokeColor3   = Color3.new(0,0,0)
                        lbl.TextStrokeTransparency = 0.3
                        lbl.Font               = Enum.Font.GothamBold
                        lbl.TextSize           = 14; lbl.Parent = bb
                        lblConn = RunService.Heartbeat:Connect(function()
                            if not m.Parent or not CFG.ESPChild then
                                lblConn:Disconnect(); return
                            end
                            local rr = root(); local pp = partOf(m)
                            if rr and pp then
                                local dist = math.floor((pp.Position - rr.Position).Magnitude)
                                lbl.Text = m.Name .. "\n📍 " .. dist .. " studs"
                            else
                                lbl.Text = m.Name
                            end
                        end)
                    end
                    espTag[m] = { hl=hl, bb=bb, conn=lblConn }
                end
            end
        else
            if next(espTag) then clearESPChild() end
        end
    end
end)

-- =================== TP, PULL & UTILITY ACTIONS ===================
local function tpTo(m)
    local r, p = root(), partOf(m)
    if r and p then r.CFrame = CFrame.new(p.Position + Vector3.new(0,4,0)) end
end

local function tpCampfire()
    local fp = getFirePart(); local r = root()
    if fp and r then r.CFrame = CFrame.new(fp.Position + Vector3.new(0,4,0)) end
end

local function pullPlayerToMe(plr)
    if not plr or plr == LP then return false end
    local r = root()
    local targetRoot = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
    if r and targetRoot then
        targetRoot.CFrame = r.CFrame * CFrame.new(0,1,-4)
        return true
    end
    return false
end

local function pullAllExact(nameList)
    local r = root(); if not r then return 0 end
    local ch = LP.Character
    local found = {}
    for _, o in ipairs(Workspace:GetDescendants()) do
        if ch and o:IsDescendantOf(ch) then continue end
        if Players:GetPlayerFromCharacter(o) then continue end
        if (o:IsA("Model") or o:IsA("BasePart")) and matchesExact(o.Name, nameList) then
            local p = partOf(o)
            if p then
                local d = (p.Position - r.Position).Magnitude
                table.insert(found, { obj=o, dist=d })
            end
        end
    end
    table.sort(found, function(a,b) return a.dist < b.dist end)
    local count = 0
    for i = 1, math.min(#found, 20) do
        if not (DragRE and StopDragRE) then break end
        local o  = found[i].obj
        local rr = root(); if not rr then break end
        local spreadX = ((count % 3) - 1) * 1.4
        local liftY   = 1.2 + math.floor(count / 3) * 0.6
        local goalCF  = rr.CFrame * CFrame.new(spreadX, liftY, -3)
        if o:IsA("Model") then
            if not o.PrimaryPart then
                pcall(function() o.PrimaryPart = partOf(o) end)
            end
            pcall(DragRE.FireServer, DragRE, o)
            if o.PrimaryPart then
                pcall(function() o:SetPrimaryPartCFrame(goalCF) end)
            else
                pcall(function() o:PivotTo(goalCF) end)
            end
        elseif o:IsA("BasePart") then
            pcall(DragRE.FireServer, DragRE, o)
            pcall(function() o.CFrame = goalCF end)
        end
        task.wait(0.04)
        pcall(StopDragRE.FireServer, StopDragRE, o)
        count += 1; task.wait(0.08)
    end
    return count
end

local droppedAt = {}
local function dumpFuelToFire()
    local fp = getFirePart()
    if not (fp and DragRE and StopDragRE) then return 0 end
    local ch, count, seen = LP.Character, 0, {}
    for _, o in ipairs(Workspace:GetDescendants()) do
        if not o:IsA("Model") then continue end
        if seen[o] then continue end
        if ch and o:IsDescendantOf(ch) then continue end
        if Players:GetPlayerFromCharacter(o) then continue end
        if (droppedAt[o] or 0) + 20 > os.clock() then continue end
        if not matchesExact(o.Name, FUEL_EXACT) then continue end
        seen[o] = true
        if not o.PrimaryPart then pcall(function() o.PrimaryPart = partOf(o) end) end
        if not o.PrimaryPart then continue end
        droppedAt[o] = os.clock()
        local offset = Vector3.new(math.random(-20,20)/10, 7+count*0.4, math.random(-20,20)/10)
        pcall(DragRE.FireServer,  DragRE, o)
        pcall(function() o:SetPrimaryPartCFrame(CFrame.new(fp.Position + offset)) end)
        task.wait(0.05)
        pcall(StopDragRE.FireServer, StopDragRE, o)
        count += 1; task.wait(0.1)
    end
    return count
end

task.spawn(function()
    while true do
        task.wait(5)
        if CFG.AutoDrop then pcall(dumpFuelToFire) end
    end
end)

local function plantAllSaplings(statusLbl)
    local function setStatus(txt, col)
        if statusLbl and statusLbl.Parent then
            statusLbl.Text       = txt
            statusLbl.TextColor3 = col or Color3.fromRGB(235, 238, 245)
        end
    end
    if not PlantRE then
        setStatus("❌ Không có remote RequestPlantItem", Color3.fromRGB(255,100,100)); return 0
    end
    if not getnilinstances then
        setStatus("❌ Executor không hỗ trợ getnilinstances", Color3.fromRGB(255,100,100)); return 0
    end
    setStatus("🔍 Đang quét mầm cây...", Color3.fromRGB(255,220,80))
    local saplings = getNilByName("Sapling")
    if #saplings == 0 then
        setStatus("⚠️ Không tìm thấy mầm cây nào", Color3.fromRGB(255,180,60)); return 0
    end
    setStatus(string.format("🌱 Tìm thấy %d mầm — đang trồng...", #saplings), Color3.fromRGB(120,165,255))
    local r = root()
    if not r then
        setStatus("❌ Không tìm thấy nhân vật", Color3.fromRGB(255,100,100)); return 0
    end
    local basePos = r.CFrame.Position - Vector3.new(0, 3, 0)
    local count = 0
    for _, sapling in ipairs(saplings) do
        local ok0 = pcall(function() return sapling.Name end)
        if not ok0 then continue end
        local offset = Vector3.new(math.random(-3,3)/10, 0, math.random(-3,3)/10)
        local ok2 = pcall(PlantRE.InvokeServer, PlantRE, sapling, basePos + offset)
        if StopDragRE then pcall(StopDragRE.FireServer, StopDragRE, sapling) end
        if ok2 then count += 1 end
        task.wait(0.15)
    end
    if count > 0 then
        setStatus(string.format("✅ Đã trồng %d/%d mầm cây", count, #saplings), Color3.fromRGB(65,155,105))
    else
        setStatus("⚠️ Trồng thất bại — thử đứng sát đất hơn", Color3.fromRGB(255,180,60))
    end
    return count
end

local function revealMap()
    if not MapRE then return end
    local cells = {}
    for row = 1, 64 do
        for col = 1, 64 do table.insert(cells, {Row=row, Col=col}) end
    end
    for i = 1, #cells, 200 do
        local b = {}
        for j = i, math.min(i+199, #cells) do table.insert(b, cells[j]) end
        pcall(MapRE.FireServer, MapRE, b, {}); task.wait(0.1)
    end
end

-- =====================================================================
-- =================== GIAO DIỆN OLLIE MENU MỚI ========================
-- =====================================================================
local Gui = Instance.new("ScreenGui")
Gui.Name = "OllieMenu"
Gui.ResetOnSpawn = false
if not pcall(function() Gui.Parent = CoreGui end) then
    Gui.Parent = PlayerGui
end

local Main = Instance.new("Frame")
Main.Size = UDim2.fromOffset(540, 370)
Main.Position = UDim2.new(0.5, -270, 0.5, -185)
Main.BackgroundColor3 = Color3.fromRGB(22, 24, 30)
Main.BorderSizePixel = 0
Main.Parent = Gui
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)

local Top = Instance.new("Frame")
Top.Size = UDim2.new(1, 0, 0, 42)
Top.BackgroundColor3 = Color3.fromRGB(31, 34, 43)
Top.BorderSizePixel = 0
Top.Parent = Main
Instance.new("UICorner", Top).CornerRadius = UDim.new(0, 10)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -50, 1, 0)
Title.Position = UDim2.fromOffset(14, 0)
Title.BackgroundTransparency = 1
Title.Text = "OLLIE  |  99 NIGHTS"
Title.TextColor3 = Color3.fromRGB(235, 238, 245)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 15
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Top

local Close = Instance.new("TextButton")
Close.Size = UDim2.fromOffset(34, 30)
Close.Position = UDim2.new(1, -40, 0, 6)
Close.BackgroundColor3 = Color3.fromRGB(180, 55, 60)
Close.Text = "X"
Close.TextColor3 = Color3.new(1, 1, 1)
Close.Font = Enum.Font.GothamBold
Close.TextSize = 14
Close.Parent = Top
Instance.new("UICorner", Close).CornerRadius = UDim.new(0, 6)

local Tabs = Instance.new("Frame")
Tabs.Size = UDim2.new(0, 135, 1, -55)
Tabs.Position = UDim2.fromOffset(8, 49)
Tabs.BackgroundColor3 = Color3.fromRGB(27, 30, 37)
Tabs.BorderSizePixel = 0
Tabs.Parent = Main
Instance.new("UICorner", Tabs).CornerRadius = UDim.new(0, 8)

local TabList = Instance.new("UIListLayout")
TabList.Padding = UDim.new(0, 6)
TabList.SortOrder = Enum.SortOrder.LayoutOrder
TabList.Parent = Tabs

local TabPadding = Instance.new("UIPadding")
TabPadding.PaddingTop = UDim.new(0, 8)
TabPadding.PaddingLeft = UDim.new(0, 7)
TabPadding.PaddingRight = UDim.new(0, 7)
TabPadding.Parent = Tabs

local Content = Instance.new("ScrollingFrame")
Content.Size = UDim2.new(1, -160, 1, -55)
Content.Position = UDim2.fromOffset(151, 49)
Content.BackgroundColor3 = Color3.fromRGB(27, 30, 37)
Content.BorderSizePixel = 0
Content.ScrollBarThickness = 4
Content.CanvasSize = UDim2.new()
Content.AutomaticCanvasSize = Enum.AutomaticSize.Y
Content.Parent = Main
Instance.new("UICorner", Content).CornerRadius = UDim.new(0, 8)

local ContentList = Instance.new("UIListLayout")
ContentList.Padding = UDim.new(0, 8)
ContentList.SortOrder = Enum.SortOrder.LayoutOrder
ContentList.Parent = Content

local ContentPadding = Instance.new("UIPadding")
ContentPadding.PaddingTop = UDim.new(0, 10)
ContentPadding.PaddingLeft = UDim.new(0, 10)
ContentPadding.PaddingRight = UDim.new(0, 10)
ContentPadding.PaddingBottom = UDim.new(0, 10)
ContentPadding.Parent = Content

-- Kéo cửa sổ
local dragging, dragStart, startPos
Top.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = Main.Position
    end
end)
UIS.InputChanged:Connect(function(input)
    if dragging and (
        input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch
    ) then
        local delta = input.Position - dragStart
        Main.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)
UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

-- Nút mở lại (Reopen)
local Reopen = Instance.new("TextButton")
Reopen.Size = UDim2.fromOffset(45, 45)
Reopen.Position = UDim2.new(0, 15, 0.5, -22)
Reopen.BackgroundColor3 = Color3.fromRGB(80, 115, 220)
Reopen.Text = "99"
Reopen.TextColor3 = Color3.new(1, 1, 1)
Reopen.Font = Enum.Font.GothamBold
Reopen.TextSize = 17
Reopen.Visible = false
Reopen.Parent = Gui
Instance.new("UICorner", Reopen).CornerRadius = UDim.new(1, 0)

Close.MouseButton1Click:Connect(function()
    Main.Visible = false
    Reopen.Visible = true
end)
Reopen.MouseButton1Click:Connect(function()
    Main.Visible = true
    Reopen.Visible = false
end)

-- Nút bay lên/xuống cho Mobile (Fly Pad)
local flyPad = Instance.new("Frame")
flyPad.Size = UDim2.new(0, 60, 0, 124)
flyPad.Position = UDim2.new(1, -70, 1, -132)
flyPad.BackgroundTransparency = 1
flyPad.Visible = false
flyPad.Parent = Gui

local function holdBtn(yOff, text, onState)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 56, 0, 56)
    b.Position = UDim2.new(0, 0, 0, yOff)
    b.BackgroundColor3 = Color3.fromRGB(37, 41, 51)
    b.BorderSizePixel = 0
    b.Text = text
    b.TextColor3 = Color3.fromRGB(120, 165, 255)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 20
    b.Parent = flyPad
    Instance.new("UICorner", b).CornerRadius = UDim.new(1, 0)
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

-- =================== UI BUILDERS ===================
local CurrentTab = nil
local TabButtons = {}

local function ClearContent()
    eatStatusLbl = nil
    for _, child in ipairs(Content:GetChildren()) do
        if child:IsA("GuiObject") and child ~= ContentList and child ~= ContentPadding then
            child:Destroy()
        end
    end
end

local function Section(text)
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, 0, 0, 24)
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.TextColor3 = Color3.fromRGB(120, 165, 255)
    Label.Font = Enum.Font.GothamBold
    Label.TextSize = 13
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Content
    return Label
end

local function InfoBox(text)
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, 0, 0, 28)
    Frame.BackgroundColor3 = Color3.fromRGB(31, 34, 43)
    Frame.BorderSizePixel = 0
    Frame.Parent = Content
    Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 6)

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -16, 1, 0)
    Label.Position = UDim2.fromOffset(8, 0)
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.TextColor3 = Color3.fromRGB(170, 178, 195)
    Label.Font = Enum.Font.Gotham
    Label.TextSize = 11
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.TextTruncate = Enum.TextTruncate.AtEnd
    Label.Parent = Frame
    return Label
end

local function ActionButton(text, callback)
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(1, 0, 0, 34)
    Btn.BackgroundColor3 = Color3.fromRGB(45, 52, 68)
    Btn.BorderSizePixel = 0
    Btn.Text = text
    Btn.TextColor3 = Color3.fromRGB(235, 238, 245)
    Btn.Font = Enum.Font.GothamSemibold
    Btn.TextSize = 12
    Btn.Parent = Content
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 6)
    Btn.MouseButton1Click:Connect(function()
        if callback then callback(Btn) end
    end)
    return Btn
end

local function Toggle(text, default, callback)
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, 0, 0, 38)
    Frame.BackgroundColor3 = Color3.fromRGB(37, 41, 51)
    Frame.BorderSizePixel = 0
    Frame.Parent = Content
    Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 6)

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -65, 1, 0)
    Label.Position = UDim2.fromOffset(10, 0)
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.TextColor3 = Color3.fromRGB(235, 238, 245)
    Label.Font = Enum.Font.Gotham
    Label.TextSize = 12
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Frame

    local Button = Instance.new("TextButton")
    Button.Size = UDim2.fromOffset(42, 23)
    Button.Position = UDim2.new(1, -50, 0.5, -11)
    Button.BackgroundColor3 = default and Color3.fromRGB(65, 155, 105) or Color3.fromRGB(70, 75, 88)
    Button.Text = default and "ON" or "OFF"
    Button.TextColor3 = Color3.new(1, 1, 1)
    Button.Font = Enum.Font.GothamBold
    Button.TextSize = 10
    Button.Parent = Frame
    Instance.new("UICorner", Button).CornerRadius = UDim.new(0, 5)

    local enabled = default

    local function Update()
        Button.Text = enabled and "ON" or "OFF"
        Button.BackgroundColor3 = enabled
            and Color3.fromRGB(65, 155, 105)
            or Color3.fromRGB(70, 75, 88)
        if callback then callback(enabled) end
    end

    Button.MouseButton1Click:Connect(function()
        enabled = not enabled
        Update()
    end)

    return function(value)
        enabled = value
        Update()
    end
end

local function Slider(text, min, max, default, callback)
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, 0, 0, 58)
    Frame.BackgroundColor3 = Color3.fromRGB(37, 41, 51)
    Frame.BorderSizePixel = 0
    Frame.Parent = Content
    Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 6)

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -20, 0, 22)
    Label.Position = UDim2.fromOffset(10, 4)
    Label.BackgroundTransparency = 1
    Label.TextColor3 = Color3.fromRGB(235, 238, 245)
    Label.Font = Enum.Font.Gotham
    Label.TextSize = 12
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Frame

    local Bar = Instance.new("Frame")
    Bar.Size = UDim2.new(1, -20, 0, 7)
    Bar.Position = UDim2.fromOffset(10, 36)
    Bar.BackgroundColor3 = Color3.fromRGB(65, 70, 83)
    Bar.BorderSizePixel = 0
    Bar.Parent = Frame
    Instance.new("UICorner", Bar).CornerRadius = UDim.new(1, 0)

    local Fill = Instance.new("Frame")
    Fill.BackgroundColor3 = Color3.fromRGB(90, 135, 240)
    Fill.BorderSizePixel = 0
    Fill.Parent = Bar
    Instance.new("UICorner", Fill).CornerRadius = UDim.new(1, 0)

    local Knob = Instance.new("Frame")
    Knob.Size = UDim2.fromOffset(15, 15)
    Knob.AnchorPoint = Vector2.new(0.5, 0.5)
    Knob.BackgroundColor3 = Color3.new(1, 1, 1)
    Knob.BorderSizePixel = 0
    Knob.Parent = Bar
    Instance.new("UICorner", Knob).CornerRadius = UDim.new(1, 0)

    local value = math.clamp(default, min, max)
    local sliding = false

    local function SetValue(v, skipCb)
        value = math.clamp(math.floor(v + 0.5), min, max)
        local alpha = (value - min) / (max - min)
        Fill.Size = UDim2.new(alpha, 0, 1, 0)
        Knob.Position = UDim2.new(alpha, 0, 0.5, 0)
        Label.Text = text .. ": " .. value
        if callback and not skipCb then callback(value) end
    end

    local function FromInput(input)
        local alpha = math.clamp(
            (input.Position.X - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X,
            0, 1
        )
        SetValue(min + (max - min) * alpha, false)
    end

    Bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            sliding = true
            FromInput(input)
        end
    end)

    UIS.InputChanged:Connect(function(input)
        if sliding and (
            input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch
        ) then
            FromInput(input)
        end
    end)

    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            sliding = false
        end
    end)

    SetValue(value, true)
    return SetValue
end

-- =================== CÁC TAB CHỨC NĂNG ===================
local TAB_ORDER = { "Di chuyển", "Chiến đấu", "Hiển thị", "Trẻ em", "TP & Đồ" }
local Pages = {}

-- 1. DI CHUYỂN
Pages["Di chuyển"] = function()
    Section("MOVEMENT")

    Toggle("Speed", CFG.Speed, function(enabled)
        CFG.Speed = enabled
        if not enabled then
            local h = hum(); if h then h.WalkSpeed = 16 end
        end
    end)
    Slider("Walk Speed", 16, 300, CFG.WalkSpeed, function(value)
        CFG.WalkSpeed = value
    end)

    Toggle("High Jump", CFG.Jump, function(enabled)
        CFG.Jump = enabled
        if not enabled then
            local h = hum(); if h then h.JumpPower = 50 end
        end
    end)
    Slider("Jump Power", 50, 500, CFG.JumpPower, function(value)
        CFG.JumpPower = value
    end)

    Toggle("Fly", CFG.Fly, function(enabled)
        CFG.Fly = enabled
        flyPad.Visible = enabled
        if enabled then startFly() else stopFly() end
    end)
    Slider("Fly Speed", 10, 200, CFG.FlySpeed, function(value)
        CFG.FlySpeed = value
    end)

    Toggle("👻 Noclip", CFG.Noclip, function(enabled)
        CFG.Noclip = enabled
        if not enabled then restoreNoclip() end
    end)
end

-- 2. CHIẾN ĐẤU & FARM
Pages["Chiến đấu"] = function()
    local t = getKillTool()
    InfoBox("🗡 Vũ khí hiện tại: " .. (t and t.Name or "Không có vũ khí"))

    Section("COMBAT & CHOP")

    Toggle("Kill Aura", CFG.KillAura, function(enabled)
        CFG.KillAura = enabled
    end)
    Slider("Kill Radius", 10, 500, CFG.KillRadius, function(value)
        CFG.KillRadius = value
    end)

    Toggle("Auto Chop", CFG.AutoChop, function(enabled)
        CFG.AutoChop = enabled
    end)
    Slider("Chop Radius", 10, 500, CFG.ChopRadius, function(value)
        CFG.ChopRadius = value
    end)

    Slider("Delay (x10ms)", 5, 60, math.floor(CFG.Delay * 100), function(value)
        CFG.Delay = value / 100
    end)

    Section("SINH TỒN & TRỒNG CÂY")

    Toggle("🥕 Auto Eat Carrot", CFG.AutoEat, function(enabled)
        CFG.AutoEat = enabled
        if not enabled then
            updateEatStatus("Tắt", Color3.fromRGB(170, 178, 195))
        end
    end)
    eatStatusLbl = InfoBox(eatStatusText)

    local plantLbl = InfoBox("Đứng vào vị trí muốn trồng → bấm nút dưới")
    ActionButton("🌱 Trồng tất cả mầm cây (Sapling)", function()
        task.spawn(function() plantAllSaplings(plantLbl) end)
    end)
end

-- 3. HIỂN THỊ
Pages["Hiển thị"] = function()
    Section("VISUAL & PERFORMANCE")

    Toggle("Fullbright", CFG.Fullbright, function(enabled)
        CFG.Fullbright = enabled
        setFullbright(enabled)
    end)

    Toggle("⚡ Fix Lag Pro", CFG.FixLag, function(enabled)
        setFixLag(enabled)
    end)

    ActionButton("🗺️ Reveal Map (Mở toàn bộ bản đồ)", function()
        task.spawn(revealMap)
    end)
end

-- 4. TRẺ EM
Pages["Trẻ em"] = function()
    Section("CHILDREN ESP & TELEPORT")

    Toggle("ESP Trẻ em", CFG.ESPChild, function(enabled)
        CFG.ESPChild = enabled
        if not enabled then clearESPChild() end
    end)

    ActionButton("🔍 Quét lại danh sách trẻ em", function()
        if CurrentTab == "Trẻ em" then
            ClearContent()
            Pages["Trẻ em"]()
        end
    end)

    local r, list = root(), {}
    for _, m in ipairs(childCache) do
        if m.Parent then
            local p = partOf(m)
            if p then
                local d = r and math.floor((p.Position - r.Position).Magnitude) or 0
                table.insert(list, {m=m, p=p, d=d})
            end
        end
    end
    table.sort(list, function(a, b) return a.d < b.d end)

    if #list == 0 then
        InfoBox("Không tìm thấy trẻ nào trên bản đồ")
        return
    end

    for i, item in ipairs(list) do
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 44)
        row.BackgroundColor3 = Color3.fromRGB(37, 41, 51)
        row.BorderSizePixel = 0
        row.Parent = Content
        Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)

        local nameLbl = Instance.new("TextLabel")
        nameLbl.Size = UDim2.new(1, -65, 0, 20)
        nameLbl.Position = UDim2.fromOffset(10, 4)
        nameLbl.BackgroundTransparency = 1
        nameLbl.Text = string.format("%d. %s", i, item.m.Name)
        nameLbl.TextColor3 = Color3.fromRGB(235, 238, 245)
        nameLbl.Font = Enum.Font.GothamBold
        nameLbl.TextSize = 12
        nameLbl.TextXAlignment = Enum.TextXAlignment.Left
        nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
        nameLbl.Parent = row

        local distLbl = Instance.new("TextLabel")
        distLbl.Size = UDim2.new(1, -65, 0, 16)
        distLbl.Position = UDim2.fromOffset(10, 24)
        distLbl.BackgroundTransparency = 1
        distLbl.Text = string.format("📍 %d studs", item.d)
        distLbl.TextColor3 = Color3.fromRGB(160, 165, 180)
        distLbl.Font = Enum.Font.Gotham
        distLbl.TextSize = 11
        distLbl.TextXAlignment = Enum.TextXAlignment.Left
        distLbl.Parent = row

        local tpBtn = Instance.new("TextButton")
        tpBtn.Size = UDim2.fromOffset(44, 24)
        tpBtn.Position = UDim2.new(1, -52, 0.5, -12)
        tpBtn.BackgroundColor3 = Color3.fromRGB(65, 155, 105)
        tpBtn.BorderSizePixel = 0
        tpBtn.Text = "TP"
        tpBtn.TextColor3 = Color3.new(1, 1, 1)
        tpBtn.Font = Enum.Font.GothamBold
        tpBtn.TextSize = 11
        tpBtn.Parent = row
        Instance.new("UICorner", tpBtn).CornerRadius = UDim.new(0, 5)
        tpBtn.MouseButton1Click:Connect(function() tpTo(item.m) end)
    end
end

-- 5. TP & ĐỒ
Pages["TP & Đồ"] = function()
    Section("LỬA TRẠI & NHIÊN LIỆU")

    ActionButton("🔥 TP Lửa trại", tpCampfire)

    Toggle("Auto dồn nhiên liệu → Lửa trại", CFG.AutoDrop, function(enabled)
        CFG.AutoDrop = enabled
    end)

    ActionButton("🪵 Dồn nhiên liệu → Lửa trại ngay", function()
        task.spawn(function() dumpFuelToFire() end)
    end)

    Section("KÉO VẬT PHẨM VỀ NGƯỜI")

    ActionButton("🍎 Kéo thức ăn về người (Berry, Carrot, Apple...)", function()
        task.spawn(function() pullAllExact(FOOD_ITEMS) end)
    end)

    ActionButton("⚙️ Kéo nguyên liệu về người (Log, Bolt, Sheet Metal...)", function()
        task.spawn(function() pullAllExact(SCRAP_ITEMS) end)
    end)

    Section("NGƯỜI CHƠI")

    ActionButton("🔄 Làm mới danh sách người chơi", function()
        if CurrentTab == "TP & Đồ" then
            ClearContent()
            Pages["TP & Đồ"]()
        end
    end)

    local r = root()
    local others = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LP then
            local pRoot = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
            local dist  = (r and pRoot) and math.floor((pRoot.Position - r.Position).Magnitude) or 0
            table.insert(others, {plr=plr, dist=dist, hasChar=pRoot~=nil})
        end
    end
    table.sort(others, function(a, b) return a.dist < b.dist end)

    if #others == 0 then
        InfoBox("Không có người chơi khác trong phòng")
        return
    end

    for _, info in ipairs(others) do
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 36)
        row.BackgroundColor3 = Color3.fromRGB(37, 41, 51)
        row.BorderSizePixel = 0
        row.Parent = Content
        Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -68, 1, 0)
        lbl.Position = UDim2.fromOffset(10, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = info.hasChar
            and string.format("%s (%d studs)", info.plr.Name, info.dist)
            or info.plr.Name .. " (chờ spawn)"
        lbl.TextColor3 = Color3.fromRGB(235, 238, 245)
        lbl.Font = Enum.Font.Gotham
        lbl.TextSize = 11
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.TextTruncate = Enum.TextTruncate.AtEnd
        lbl.Parent = row

        local goBtn = Instance.new("TextButton")
        goBtn.Size = UDim2.fromOffset(52, 24)
        goBtn.Position = UDim2.new(1, -60, 0.5, -12)
        goBtn.BackgroundColor3 = info.hasChar and Color3.fromRGB(65, 155, 105) or Color3.fromRGB(70, 75, 88)
        goBtn.BorderSizePixel = 0
        goBtn.Text = "Kéo về"
        goBtn.TextColor3 = Color3.new(1, 1, 1)
        goBtn.Font = Enum.Font.GothamBold
        goBtn.TextSize = 10
        goBtn.Parent = row
        Instance.new("UICorner", goBtn).CornerRadius = UDim.new(0, 5)
        goBtn.MouseButton1Click:Connect(function() pullPlayerToMe(info.plr) end)
    end
end

-- =================== KHỞI TẠO TAB ===================
local function OpenTab(name)
    CurrentTab = name
    ClearContent()

    for tabName, button in pairs(TabButtons) do
        button.BackgroundColor3 = tabName == name
            and Color3.fromRGB(65, 105, 190)
            or Color3.fromRGB(37, 41, 51)
    end

    if Pages[name] then
        Pages[name]()
    end
end

for i, name in ipairs(TAB_ORDER) do
    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(1, 0, 0, 36)
    Button.LayoutOrder = i
    Button.BackgroundColor3 = Color3.fromRGB(37, 41, 51)
    Button.Text = name
    Button.TextColor3 = Color3.fromRGB(235, 238, 245)
    Button.Font = Enum.Font.GothamSemibold
    Button.TextSize = 12
    Button.Parent = Tabs
    Instance.new("UICorner", Button).CornerRadius = UDim.new(0, 6)

    TabButtons[name] = Button

    Button.MouseButton1Click:Connect(function()
        OpenTab(name)
    end)
end

OpenTab("Di chuyển")
print("[OllieMenu] Full functions loaded ✓")
