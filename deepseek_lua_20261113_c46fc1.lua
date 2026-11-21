-- 99 Nights in the Forest — ollie v7 (solo map, PC + mobile)
local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS        = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting   = game:GetService("Lighting")
local RS         = game:GetService("ReplicatedStorage")
local Workspace  = game:GetService("Workspace")

local LP        = Players.LocalPlayer
local PlayerGui = LP:WaitForChild("PlayerGui")

local Remotes    = RS:WaitForChild("RemoteEvents", 10)
local EquipRE    = Remotes and Remotes:FindFirstChild("EquipItemHandle")
local UnequipRE  = Remotes and Remotes:FindFirstChild("UnequipItemHandle")
local DamageRF   = Remotes and Remotes:FindFirstChild("ToolDamageObject")
local MapRE      = Remotes and Remotes:FindFirstChild("MapCellsDiscovered")
local DragRE     = Remotes and Remotes:FindFirstChild("RequestStartDraggingItem")
local StopDragRE = Remotes and Remotes:FindFirstChild("StopDraggingItem")
local HitSoundRE = Remotes and Remotes:FindFirstChild("PlayEnemyHitSound")

local AXES = {
    "Old Axe","Good Axe","Ice Axe","Strong Axe","Chainsaw","Admin Axe",
}

local MELEE_WEAPONS = {
    "Spear","Honey Spear","Morningstar","Katana","Laser Sword","Ice Sword",
    "Trident","Poison Claws","Poison Spear","Infernal Sword",
    "Cultist King Mace","Brutal Battleaxe","Obsidiron Hammer",
    "Scythe","Vampire Scythe","Happy's Scythe",
}

local FOOD_ITEMS = {
    "Berry",
    "Carrot",
    "Apple",
    "Corn",
    "Pumpkin",
    "Chili",
}

local SCRAP_ITEMS = {
    "Bolt",
    "Sheet Metal",
    "Broken Fan",
    "Broken Radio",
    "Broken Microwave",
    "Washing Machine",
    "Tires & Engines",
}

local CFG = {
    Speed        = false, WalkSpeed   = 40,
    Jump         = false, JumpPower   = 90,
    Fly          = false, FlySpeed    = 60,
    Noclip       = false,
    KillAura     = false, KillRadius  = 150,
    AutoChop     = false, ChopRadius  = 130,
    AutoDrop     = false,
    ESPChild     = false,
    Fullbright   = false,
    Delay        = 0.35,
}

local MAX_KILL_PER_CYCLE = 6
local TOOL_SUFFIX = "11960515286"
local CHILD_KEY   = "Lost Child"

-- ===================== HELPERS =====================
local function hasKey(name, keys)
    local n = string.lower(name)
    for _, k in ipairs(keys) do
        if string.find(n, string.lower(k), 1, true) then return true end
    end
    return false
end

local function matchesExact(name, list)
    for _, itemName in ipairs(list) do
        if name == itemName then return true end
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
    if m:IsA("Model") and m.PrimaryPart then return m.PrimaryPart end
    local hrp = m:FindFirstChild("HumanoidRootPart")
    if hrp and hrp:IsA("BasePart") then return hrp end
    return m:FindFirstChildWhichIsA("BasePart", true)
end

local function moveObjectToCFrame(obj, targetCF)
    if not obj or not obj.Parent then return false end
    if obj:IsA("BasePart") then
        obj.CFrame = targetCF
        return true
    elseif obj:IsA("Model") then
        if not obj.PrimaryPart then
            local p = partOf(obj)
            if p then pcall(function() obj.PrimaryPart = p end) end
        end
        if obj.PrimaryPart then
            pcall(function() obj:SetPrimaryPartCFrame(targetCF) end)
            return true
        else
            pcall(function() obj:PivotTo(targetCF) end)
            return true
        end
    end
    return false
end

local function bringToPlayer(obj, indexOffset)
    local r = root()
    if not r or not obj or not obj.Parent then return false end
    local idx = indexOffset or 0
    local spreadX = ((idx % 3) - 1) * 1.4
    local liftY = 1.2 + math.floor(idx / 3) * 0.6
    local goalCF = r.CFrame * CFrame.new(spreadX, liftY, -4)

    if DragRE and StopDragRE then
        pcall(DragRE.FireServer, DragRE, obj)
        moveObjectToCFrame(obj, goalCF)
        task.wait(0.04)
        pcall(StopDragRE.FireServer, StopDragRE, obj)
        return true
    end

    return moveObjectToCFrame(obj, goalCF)
end

local function findFromList(list, inv, char)
    for _, name in ipairs(list) do
        local t = (inv and inv:FindFirstChild(name))
            or (char and char:FindFirstChild(name))
        if t then return t end
    end
    return nil
end

local function getFallbackTool(inv, char)
    if inv then
        local t = inv:FindFirstChildWhichIsA("Tool")
        if t then return t end
        for _, item in ipairs(inv:GetChildren()) do
            if item:IsA("Model") then return item end
        end
    end
    return char and char:FindFirstChild("Tool")
end

-- Ưu tiên vũ khí không phải rìu cho Kill Aura; chỉ dùng rìu nếu không có vũ khí khác
local function getKillTool()
    local inv  = LP:FindFirstChild("Inventory")
    local char = LP.Character
    return findFromList(MELEE_WEAPONS, inv, char)
        or findFromList(AXES, inv, char)
        or getFallbackTool(inv, char)
end

-- Ưu tiên rìu cho Auto Chop; fallback sang vũ khí/công cụ khác nếu không có rìu
local function getChopTool()
    local inv  = LP:FindFirstChild("Inventory")
    local char = LP.Character
    return findFromList(AXES, inv, char)
        or findFromList(MELEE_WEAPONS, inv, char)
        or getFallbackTool(inv, char)
end

local function getTool()
    return getKillTool()
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

-- ===================== CACHE TRẺ =====================
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

-- ===================== COUNTER =====================
local hitCounter = 0
local function resetCounter() hitCounter = 0 end
Workspace.ChildAdded:Connect(function(c)   if c.Name=="Map" then resetCounter() end end)
Workspace.ChildRemoved:Connect(function(c) if c.Name=="Map" then resetCounter() end end)
LP.CharacterAdded:Connect(function()
    task.wait(0.5); resetCounter()
    if CFG.Fly then startFly() end
end)
local function nextId() hitCounter+=1; return hitCounter.."_"..TOOL_SUFFIX end

-- ===================== SWING =====================
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
            if h and h.Health > 0 then
                hitOnce(tool, t.m, t.p)
            end
        end
        if i < limit then
            task.wait(0.05)
        end
    end
    pcall(UnequipRE.FireServer, UnequipRE, "FireAllClients", tool)
end

-- ===================== KILL AURA =====================
local SCAN_FOLDERS = {"Characters","Enemies","Mobs","NPCs"}
local function getAnimals(r)
    local out, ch, seen = {}, LP.Character, {}
    local maxDistSq = CFG.KillRadius * CFG.KillRadius
    local rPos = r.Position

    local function tryAdd(o)
        if seen[o] or o==ch then return end
        seen[o] = true
        if Players:GetPlayerFromCharacter(o) then return end
        if string.find(o.Name, CHILD_KEY, 1, true) then return end
        local h = o:FindFirstChildWhichIsA("Humanoid", true)
        if not (h and h.Health>0) then return end
        local p = partOf(o); if not p then return end
        local delta = p.Position - rPos
        local dSq = delta.X*delta.X + delta.Y*delta.Y + delta.Z*delta.Z
        if dSq <= maxDistSq then
            table.insert(out, {m=o, p=p, dSq=dSq})
        end
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

    table.sort(out, function(a,b) return a.dSq<b.dSq end)
    return out
end

-- ===================== AUTO CHOP =====================
local skipTree = {}
local TREE_KEYS = {"Tree","Pine","Oak","Birch","Fir","Bush","Foliage"}

local function getTrees(r)
    local out = {}
    local maxDistSq = CFG.ChopRadius * CFG.ChopRadius
    local rPos = r.Position
    local now = os.clock()

    local function scanFolder(folder)
        if not folder then return end
        for _, t in ipairs(folder:GetChildren()) do
            if not (skipTree[t] and now < skipTree[t]) then
                local p = partOf(t)
                if p then
                    local delta = p.Position - rPos
                    local dSq = delta.X*delta.X + delta.Y*delta.Y + delta.Z*delta.Z
                    if dSq <= maxDistSq then
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
                    local delta = p.Position - rPos
                    local dSq = delta.X*delta.X + delta.Y*delta.Y + delta.Z*delta.Z
                    if dSq <= maxDistSq then
                        table.insert(out, {m=o, p=p, dSq=dSq})
                    end
                end
            end
        end
    end

    table.sort(out, function(a,b) return a.dSq<b.dSq end)
    return out
end

-- ===================== VÒNG LẶP COMBAT =====================
task.spawn(function()
    while true do
        task.wait(CFG.Delay)
        if CFG.KillAura then
            local r, tool = root(), getKillTool()
            if r and tool then
                local targets = getAnimals(r)
                if #targets > 0 then
                    swingBatch(tool, targets)
                end
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

-- ===================== MOVEMENT & NOCLIP =====================
local noclipBackup = {}

local function restoreNoclip()
    for part, wasCollide in pairs(noclipBackup) do
        if part and part.Parent and part:IsA("BasePart") then
            pcall(function() part.CanCollide = wasCollide end)
        end
        noclipBackup[part] = nil
    end
end

RunService.Heartbeat:Connect(function()
    local h = hum(); if not h then return end
    if CFG.Speed then h.WalkSpeed = CFG.WalkSpeed end
    if CFG.Jump  then h.UseJumpPower=true; h.JumpPower=CFG.JumpPower end
end)

RunService.Stepped:Connect(function()
    local c = LP.Character
    if not c then return end
    if CFG.Noclip then
        for _, obj in ipairs(c:GetDescendants()) do
            if obj:IsA("BasePart") then
                if noclipBackup[obj] == nil then
                    noclipBackup[obj] = obj.CanCollide
                end
                if obj.CanCollide then
                    obj.CanCollide = false
                end
            end
        end
    elseif next(noclipBackup) ~= nil then
        restoreNoclip()
    end
end)

-- ===================== FLY =====================
local flyBV, flyBG, flyConn
local padUp, padDown = false, false

local function stopFly()
    if flyConn then flyConn:Disconnect(); flyConn=nil end
    if flyBV and flyBV.Parent then flyBV:Destroy() end
    if flyBG and flyBG.Parent then flyBG:Destroy() end
    flyBV, flyBG = nil, nil
    local h = hum(); if h then h.PlatformStand=false end
end

function startFly()
    stopFly()
    local r, h = root(), hum(); if not (r and h) then return end
    h.PlatformStand = true
    flyBV = Instance.new("BodyVelocity")
    flyBV.MaxForce = Vector3.new(1e6,1e6,1e6); flyBV.Velocity=Vector3.zero; flyBV.Parent=r
    flyBG = Instance.new("BodyGyro")
    flyBG.MaxTorque = Vector3.new(1e6,1e6,1e6); flyBG.P=1e4; flyBG.Parent=r
    flyConn = RunService.Heartbeat:Connect(function()
        local cam = Workspace.CurrentCamera
        local rr, hh = root(), hum()
        if not (cam and rr and hh and flyBV and flyBV.Parent) then return end
        local md = hh.MoveDirection
        local vy = 0
        if UIS:IsKeyDown(Enum.KeyCode.Space)       or padUp   then vy= 1 end
        if UIS:IsKeyDown(Enum.KeyCode.LeftControl) or padDown then vy=-1 end
        local look  = Vector3.new(cam.CFrame.LookVector.X,  0, cam.CFrame.LookVector.Z)
        local right = Vector3.new(cam.CFrame.RightVector.X, 0, cam.CFrame.RightVector.Z)
        if look.Magnitude>0  then look=look.Unit   end
        if right.Magnitude>0 then right=right.Unit end
        flyBV.Velocity = (look*-md.Z + right*md.X)*CFG.FlySpeed + Vector3.new(0,vy*CFG.FlySpeed,0)
        flyBG.CFrame = CFrame.new(rr.Position, rr.Position+look)
    end)
end

-- ===================== FULLBRIGHT =====================
local fbPrev, fbConn
local function applyFB()
    Lighting.Brightness=3; Lighting.ClockTime=12; Lighting.FogEnd=1e6
    Lighting.Ambient=Color3.fromRGB(180,180,180)
    Lighting.OutdoorAmbient=Color3.fromRGB(180,180,180)
end
local function setFullbright(on)
    if on then
        if not fbPrev then fbPrev={B=Lighting.Brightness,C=Lighting.ClockTime,
            F=Lighting.FogEnd,A=Lighting.Ambient,OA=Lighting.OutdoorAmbient} end
        applyFB()
        if not fbConn then
            fbConn = RunService.Heartbeat:Connect(function() if CFG.Fullbright then applyFB() end end)
        end
    else
        if fbConn then fbConn:Disconnect(); fbConn=nil end
        if fbPrev then
            Lighting.Brightness=fbPrev.B; Lighting.ClockTime=fbPrev.C
            Lighting.FogEnd=fbPrev.F; Lighting.Ambient=fbPrev.A
            Lighting.OutdoorAmbient=fbPrev.OA; fbPrev=nil
        end
    end
end

-- ===================== ESP TRẺ =====================
local espTag = {}
local function clearESPChild()
    for _,hl in pairs(espTag) do if hl and hl.Parent then hl:Destroy() end end
    espTag={}
end
task.spawn(function()
    while true do
        task.wait(1)
        if CFG.ESPChild then
            for m in pairs(espTag) do
                if not m.Parent then if espTag[m] then espTag[m]:Destroy() end; espTag[m]=nil end
            end
            for _, m in ipairs(childCache) do
                if m.Parent and not espTag[m] then
                    local hl=Instance.new("Highlight")
                    hl.FillColor=Color3.fromRGB(255,220,80)
                    hl.OutlineColor=Color3.fromRGB(255,220,80)
                    hl.FillTransparency=0.5; hl.Adornee=m; hl.Parent=m
                    espTag[m]=hl
                end
            end
        end
    end
end)

-- ===================== TP & KÉO ĐỒ VỀ NGƯỜI CHƠI =====================
local function tpTo(m)
    local r,p = root(), partOf(m)
    if r and p then r.CFrame=CFrame.new(p.Position+Vector3.new(0,4,0)) end
end
local function tpCampfire()
    local fp=getFirePart(); local r=root()
    if fp and r then r.CFrame=CFrame.new(fp.Position+Vector3.new(0,4,0)) end
end

local function pullPlayerToMe(plr)
    if not plr or plr == LP then return false end
    local r = root()
    local targetRoot = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
    if r and targetRoot then
        targetRoot.CFrame = r.CFrame * CFrame.new(0, 1, -4)
        return true
    end
    return false
end

local function scanExactItems(nameList)
    local r = root()
    local rPos = r and r.Position
    local ch = LP.Character
    local out = {}
    local seen = {}

    for _, o in ipairs(Workspace:GetDescendants()) do
        if seen[o] then continue end
        if ch and o:IsDescendantOf(ch) then continue end
        if o:IsA("Model") or o:IsA("BasePart") then
            if matchesExact(o.Name, nameList) then
                seen[o] = true
                local p = partOf(o)
                if p then
                    local dist = rPos and math.floor((p.Position - rPos).Magnitude) or 0
                    table.insert(out, {
                        obj = o,
                        name = o.Name,
                        part = p,
                        dist = dist,
                    })
                end
            end
        end
    end

    table.sort(out, function(a, b) return a.dist < b.dist end)
    return out
end

-- ===================== REVEAL MAP =====================
local function revealMap()
    if not MapRE then return end
    local cells={}
    for row=1,64 do for col=1,64 do table.insert(cells,{Row=row,Col=col}) end end
    for i=1,#cells,200 do
        local b={}
        for j=i,math.min(i+199,#cells) do table.insert(b,cells[j]) end
        pcall(MapRE.FireServer,MapRE,b,{}); task.wait(0.1)
    end
end

-- ===================== DỒN NGUYÊN LIỆU =====================
-- Chỉ dồn đúng các loại này, không có bộ lọc phụ
local FUEL_EXACT = {
    "Log", "Chair", "Biofuel", "Coal",
    "Purple Fur Tuft", "Fuel Canister", "Oil Barrel",
}

local droppedAt = {}

local function dropScan()
    local fp = getFirePart()
    if not (fp and DragRE and StopDragRE) then
        warn("[ollie] Thiếu lửa trại hoặc remote kéo thả")
        return 0
    end

    local ch    = LP.Character
    local count = 0
    local seen  = {}

    for _, o in ipairs(Workspace:GetDescendants()) do
        if not o:IsA("Model") then continue end
        if seen[o] then continue end
        if ch and o:IsDescendantOf(ch) then continue end
        if Players:GetPlayerFromCharacter(o) then continue end
        if (droppedAt[o] or 0) + 20 > os.clock() then continue end

        -- Khớp chính xác tên (không dùng find để tránh nhầm)
        local name = o.Name
        local matched = false
        for _, key in ipairs(FUEL_EXACT) do
            if name == key then matched = true; break end
        end
        if not matched then continue end

        seen[o] = true
        if not o.PrimaryPart then
            pcall(function() o.PrimaryPart = partOf(o) end)
        end
        if not o.PrimaryPart then continue end

        droppedAt[o] = os.clock()
        local offset = Vector3.new(
            math.random(-20, 20) / 10,
            8 + count * 0.5,
            math.random(-20, 20) / 10
        )

        pcall(DragRE.FireServer,  DragRE, o)
        pcall(function() o:SetPrimaryPartCFrame(CFrame.new(fp.Position + offset)) end)
        task.wait(0.05)
        pcall(StopDragRE.FireServer, StopDragRE, o)

        count += 1
        task.wait(0.1)
    end

    return count
end

task.spawn(function()
    while true do
        task.wait(5)
        if CFG.AutoDrop then pcall(dropScan) end
    end
end)

-- ===================== FIX LAG PRO (GỌN & MẠNH) =====================
local FixLag = false
local LagBackup = {}
local lagConn = nil
local lagGen = 0

local HEAVY_MATS = {
    [Enum.Material.Neon] = Enum.Material.SmoothPlastic,
    [Enum.Material.Glass] = Enum.Material.SmoothPlastic,
    [Enum.Material.ForceField] = Enum.Material.SmoothPlastic,
    [Enum.Material.DiamondPlate] = Enum.Material.SmoothPlastic,
    [Enum.Material.CorrodedMetal] = Enum.Material.SmoothPlastic,
    [Enum.Material.Foil] = Enum.Material.SmoothPlastic,
    [Enum.Material.WoodPlanks] = Enum.Material.SmoothPlastic,
    [Enum.Material.Cobblestone] = Enum.Material.SmoothPlastic,
}

local function saveProp(obj, prop)
    local t = LagBackup[obj]
    if not t then
        t = {}
        LagBackup[obj] = t
    end
    if t[prop] == nil then
        local ok, val = pcall(function() return obj[prop] end)
        if ok then t[prop] = val end
    end
end

local function optimizeObj(obj)
    if not FixLag or not obj or not obj.Parent then return end

    if obj:IsA("ParticleEmitter")
    or obj:IsA("Trail")
    or obj:IsA("Beam")
    or obj:IsA("Smoke")
    or obj:IsA("Fire")
    or obj:IsA("Sparkles")
    or obj:IsA("PointLight")
    or obj:IsA("SpotLight")
    or obj:IsA("SurfaceLight") then
        saveProp(obj, "Enabled")
        pcall(function() obj.Enabled = false end)
        return
    end

    if obj:IsA("BasePart") then
        saveProp(obj, "CastShadow")
        pcall(function() obj.CastShadow = false end)

        saveProp(obj, "Material")
        local nextMat = HEAVY_MATS[obj.Material] or Enum.Material.Plastic
        if obj.Material ~= nextMat then
            pcall(function() obj.Material = nextMat end)
        end
    end
end

local function enableFixLag()
    if FixLag then return end
    FixLag = true
    lagGen += 1
    local gen = lagGen

    for _, prop in ipairs({"GlobalShadows", "EnvironmentDiffuseScale", "EnvironmentSpecularScale", "ShadowSoftness"}) do
        saveProp(Lighting, prop)
    end
    pcall(function()
        Lighting.GlobalShadows = false
        Lighting.EnvironmentDiffuseScale = 0
        Lighting.EnvironmentSpecularScale = 0
        Lighting.ShadowSoftness = 0
    end)

    if not lagConn then
        lagConn = Workspace.DescendantAdded:Connect(function(obj)
            if FixLag then task.defer(optimizeObj, obj) end
        end)
    end

    task.spawn(function()
        local all = Workspace:GetDescendants()
        for i = 1, #all do
            if not FixLag or gen ~= lagGen then return end
            optimizeObj(all[i])
            if i % 500 == 0 then task.wait() end
        end
    end)

    print("[ollie] Fix Lag Pro ON")
end

local function disableFixLag()
    if not FixLag then return end
    FixLag = false
    lagGen += 1

    if lagConn then
        lagConn:Disconnect()
        lagConn = nil
    end

    for obj, props in pairs(LagBackup) do
        if obj and obj.Parent then
            for prop, val in pairs(props) do
                pcall(function() obj[prop] = val end)
            end
        end
    end

    LagBackup = {}
    print("[ollie] Fix Lag Pro OFF")
end

local function setFixLag(value)
    if value then enableFixLag() else disableFixLag() end
end

-- ===================== GUI =====================
local old = PlayerGui:FindFirstChild("ollie_v7")
if old then old:Destroy() end
local gui = Instance.new("ScreenGui")
gui.Name="ollie_v7"; gui.ResetOnSpawn=false
gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling; gui.Parent=PlayerGui

local C_BG  = Color3.fromRGB(14,15,20)
local C_HDR = Color3.fromRGB(20,22,30)
local C_ROW = Color3.fromRGB(24,26,36)
local C_ON  = Color3.fromRGB(75,190,115)
local C_OFF = Color3.fromRGB(50,53,68)
local C_TXT = Color3.fromRGB(215,218,230)
local C_ACC = Color3.fromRGB(105,220,160)
local C_BTN = Color3.fromRGB(180,210,255)
local C_SUB = Color3.fromRGB(140,142,158)
local C_SLD = Color3.fromRGB(80,160,220)

local function mkCorner(p,r) local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,r or 7); c.Parent=p end
local function mkStroke(p,col,th) local s=Instance.new("UIStroke"); s.Color=col or Color3.fromRGB(40,43,55); s.Thickness=th or 1; s.Parent=p end

local function makeDraggable(handle, target)
    local drag,si,sp
    handle.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            drag=true; si=i.Position; sp=target.Position end end)
    handle.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            drag=false end end)
    UIS.InputChanged:Connect(function(i)
        if not drag then return end
        if i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch then
            local d=i.Position-si
            target.Position=UDim2.new(sp.X.Scale,sp.X.Offset+d.X,sp.Y.Scale,sp.Y.Offset+d.Y) end end)
end

-- FAB
local fab=Instance.new("TextButton")
fab.Size=UDim2.new(0,44,0,44); fab.Position=UDim2.new(0,10,0.5,-22)
fab.BackgroundColor3=C_HDR; fab.Text="99"; fab.Font=Enum.Font.GothamBold
fab.TextSize=13; fab.TextColor3=C_ACC; fab.Visible=false; fab.Parent=gui
mkCorner(fab,22); mkStroke(fab,C_ACC,1.5); makeDraggable(fab,fab)

-- Panel chính (rộng hơn để chứa slider)
local W,H = 460,360
local panel=Instance.new("Frame")
panel.Size=UDim2.new(0,W,0,H); panel.Position=UDim2.new(0.5,-W/2,0.5,-H/2)
panel.BackgroundColor3=C_BG; panel.BorderSizePixel=0; panel.Parent=gui
mkCorner(panel,10); mkStroke(panel,Color3.fromRGB(38,40,55),1)

local header=Instance.new("Frame")
header.Size=UDim2.new(1,0,0,32); header.BackgroundColor3=C_HDR
header.BorderSizePixel=0; header.Parent=panel; mkCorner(header,10)
makeDraggable(header,panel)

local titleLbl=Instance.new("TextLabel")
titleLbl.Size=UDim2.new(1,-44,1,0); titleLbl.Position=UDim2.new(0,10,0,0)
titleLbl.BackgroundTransparency=1; titleLbl.Text="🌲  99 Nights · ollie v7"
titleLbl.TextColor3=C_ACC; titleLbl.Font=Enum.Font.GothamBold
titleLbl.TextSize=13; titleLbl.TextXAlignment=Enum.TextXAlignment.Left; titleLbl.Parent=header

local minBtn=Instance.new("TextButton")
minBtn.Size=UDim2.new(0,26,0,26); minBtn.Position=UDim2.new(1,-30,0,3)
minBtn.BackgroundColor3=C_OFF; minBtn.Text="–"; minBtn.TextColor3=C_TXT
minBtn.Font=Enum.Font.GothamBold; minBtn.TextSize=16; minBtn.Parent=header; mkCorner(minBtn,6)
minBtn.MouseButton1Click:Connect(function() panel.Visible=false; fab.Visible=true end)
fab.MouseButton1Click:Connect(function() panel.Visible=true; fab.Visible=false end)

-- Tab bar
local TAB_NAMES = {"Chính","Slider","Trẻ em","TP & Đồ"}
local tabs, tabBtns = {}, {}
local activeTab = 1

local tabBar=Instance.new("Frame")
tabBar.Size=UDim2.new(1,-12,0,28); tabBar.Position=UDim2.new(0,6,0,34)
tabBar.BackgroundTransparency=1; tabBar.Parent=panel
local tabLayout=Instance.new("UIListLayout")
tabLayout.FillDirection=Enum.FillDirection.Horizontal
tabLayout.Padding=UDim.new(0,4); tabLayout.Parent=tabBar

local body=Instance.new("Frame")
body.Size=UDim2.new(1,-12,1,-70); body.Position=UDim2.new(0,6,0,66)
body.BackgroundTransparency=1; body.Parent=panel

for i,name in ipairs(TAB_NAMES) do
    local sf=Instance.new("ScrollingFrame")
    sf.Size=UDim2.new(1,0,1,0); sf.BackgroundTransparency=1
    sf.BorderSizePixel=0; sf.ScrollBarThickness=2
    sf.ScrollBarImageColor3=C_ACC; sf.AutomaticCanvasSize=Enum.AutomaticSize.Y
    sf.CanvasSize=UDim2.new(0,0,0,0); sf.Visible=(i==1); sf.Parent=body
    local l=Instance.new("UIListLayout"); l.Padding=UDim.new(0,5)
    l.HorizontalAlignment=Enum.HorizontalAlignment.Center; l.Parent=sf
    local p=Instance.new("UIPadding"); p.PaddingTop=UDim.new(0,4); p.Parent=sf
    tabs[i]=sf

    local btn=Instance.new("TextButton")
    btn.Size=UDim2.new(0,0,1,0); btn.AutomaticSize=Enum.AutomaticSize.X
    btn.BackgroundColor3=(i==1) and C_ON or C_OFF
    btn.Text=" "..name.." "; btn.TextColor3=C_TXT
    btn.Font=Enum.Font.GothamBold; btn.TextSize=11
    btn.BorderSizePixel=0; btn.Parent=tabBar; mkCorner(btn,5)
    local function selectTab(idx)
        for j,t in ipairs(tabs) do t.Visible=(j==idx) end
        for j,b in ipairs(tabBtns) do b.BackgroundColor3=(j==idx) and C_ON or C_OFF end
        activeTab=idx
    end
    btn.MouseButton1Click:Connect(function() selectTab(i) end)
    tabBtns[i]=btn
end

-- ===================== WIDGET BUILDERS =====================
local function mkScroll(parent)
    return parent -- tabs[i] đã là ScrollingFrame
end

local function toggle(parent, label, getV, setV)
    local row=Instance.new("Frame")
    row.Size=UDim2.new(0.95,0,0,28); row.BackgroundColor3=C_ROW
    row.BorderSizePixel=0; row.Parent=parent; mkCorner(row,6)

    local lb=Instance.new("TextLabel")
    lb.Size=UDim2.new(1,-50,1,0); lb.Position=UDim2.new(0,8,0,0)
    lb.BackgroundTransparency=1; lb.Text=label; lb.TextColor3=C_TXT
    lb.Font=Enum.Font.Gotham; lb.TextSize=11
    lb.TextXAlignment=Enum.TextXAlignment.Left; lb.Parent=row

    local track=Instance.new("TextButton")
    track.Size=UDim2.new(0,38,0,18); track.Position=UDim2.new(1,-44,0.5,-9)
    track.BorderSizePixel=0; track.Text=""; track.Parent=row; mkCorner(track,9)

    local knob=Instance.new("Frame")
    knob.Size=UDim2.new(0,14,0,14); knob.AnchorPoint=Vector2.new(0,0.5)
    knob.BackgroundColor3=Color3.new(1,1,1); knob.BorderSizePixel=0
    knob.Parent=track; mkCorner(knob,7)

    local function refresh(instant)
        local on=getV()
        track.BackgroundColor3=on and C_ON or C_OFF
        local goal={Position=on and UDim2.new(1,-16,0.5,0) or UDim2.new(0,2,0.5,0)}
        if instant then knob.Position=goal.Position
        else TweenService:Create(knob,TweenInfo.new(0.12),goal):Play() end
    end
    refresh(true)
    track.MouseButton1Click:Connect(function() setV(not getV()); refresh() end)
    return refresh
end

local function button(parent, text, cb)
    local b=Instance.new("TextButton")
    b.Size=UDim2.new(0.95,0,0,26); b.BackgroundColor3=C_ROW
    b.BorderSizePixel=0; b.Text=text; b.TextColor3=C_BTN
    b.Font=Enum.Font.Gotham; b.TextSize=11; b.Parent=parent; mkCorner(b,6)
    b.MouseButton1Click:Connect(cb); return b
end

local function section(parent, text)
    local f=Instance.new("Frame"); f.Size=UDim2.new(0.95,0,0,16)
    f.BackgroundTransparency=1; f.Parent=parent
    local l=Instance.new("TextLabel"); l.Size=UDim2.new(1,0,1,0)
    l.BackgroundTransparency=1; l.Text=text; l.TextColor3=C_ACC
    l.Font=Enum.Font.GothamBold; l.TextSize=10
    l.TextXAlignment=Enum.TextXAlignment.Left; l.Parent=f
end

-- Slider tùy chỉnh
local function slider(parent, label, minV, maxV, getV, setV)
    local row=Instance.new("Frame")
    row.Size=UDim2.new(0.95,0,0,46); row.BackgroundColor3=C_ROW
    row.BorderSizePixel=0; row.Parent=parent; mkCorner(row,6)

    local lbl=Instance.new("TextLabel")
    lbl.Size=UDim2.new(1,-8,0,20); lbl.Position=UDim2.new(0,8,0,2)
    lbl.BackgroundTransparency=1
    lbl.Text=string.format("%s: %d", label, getV())
    lbl.TextColor3=C_TXT; lbl.Font=Enum.Font.Gotham; lbl.TextSize=11
    lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.Parent=row

    local track=Instance.new("Frame")
    track.Size=UDim2.new(1,-16,0,6); track.Position=UDim2.new(0,8,0,32)
    track.BackgroundColor3=C_OFF; track.BorderSizePixel=0; track.Parent=row; mkCorner(track,3)

    local fill=Instance.new("Frame")
    fill.Size=UDim2.new((getV()-minV)/(maxV-minV),0,1,0)
    fill.BackgroundColor3=C_SLD; fill.BorderSizePixel=0; fill.Parent=track; mkCorner(fill,3)

    local knob=Instance.new("TextButton")
    knob.Size=UDim2.new(0,16,0,16); knob.AnchorPoint=Vector2.new(0.5,0.5)
    knob.Position=UDim2.new((getV()-minV)/(maxV-minV),0,0.5,0)
    knob.BackgroundColor3=Color3.new(1,1,1); knob.Text=""
    knob.BorderSizePixel=0; knob.ZIndex=5; knob.Parent=track; mkCorner(knob,8)

    local dragging=false
    knob.MouseButton1Down:Connect(function() dragging=true end)
    knob.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.Touch then dragging=true end end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            dragging=false end end)
    UIS.InputChanged:Connect(function(i)
        if not dragging then return end
        if i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch then
            local mouse=UIS:GetMouseLocation()
            local abs=track.AbsolutePosition; local sz=track.AbsoluteSize
            local rel=math.clamp((mouse.X-abs.X)/sz.X,0,1)
            local val=math.floor(minV+(maxV-minV)*rel)
            fill.Size=UDim2.new(rel,0,1,0)
            knob.Position=UDim2.new(rel,0,0.5,0)
            lbl.Text=string.format("%s: %d",label,val)
            setV(val)
        end
    end)
end

-- Nút ▲▼ Fly
local flyPad=Instance.new("Frame")
flyPad.Size=UDim2.new(0,60,0,124); flyPad.Position=UDim2.new(1,-70,1,-132)
flyPad.BackgroundTransparency=1; flyPad.Visible=false; flyPad.Parent=gui

local function holdBtn(yOff,text,onState)
    local b=Instance.new("TextButton")
    b.Size=UDim2.new(0,56,0,56); b.Position=UDim2.new(0,0,0,yOff)
    b.BackgroundColor3=C_ROW; b.BorderSizePixel=0; b.Text=text
    b.TextColor3=C_ACC; b.Font=Enum.Font.GothamBold; b.TextSize=20
    b.Parent=flyPad; mkCorner(b,28); mkStroke(b,C_ACC,1)
    b.MouseButton1Down:Connect(function() onState(true) end)
    b.MouseButton1Up:Connect(function() onState(false) end)
    b.MouseLeave:Connect(function() onState(false) end)
    b.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.Touch then onState(true) end end)
    b.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.Touch then onState(false) end end)
end
holdBtn(0,"▲",function(v) padUp=v end)
holdBtn(68,"▼",function(v) padDown=v end)

-- ===================== TAB 1: CHÍNH =====================
local t1 = tabs[1]

-- Hiển thị vũ khí đang dùng
local wRow=Instance.new("Frame")
wRow.Size=UDim2.new(0.95,0,0,24); wRow.BackgroundColor3=C_HDR
wRow.BorderSizePixel=0; wRow.Parent=t1; mkCorner(wRow,5)
local wLbl=Instance.new("TextLabel")
wLbl.Size=UDim2.new(1,-8,1,0); wLbl.Position=UDim2.new(0,8,0,0)
wLbl.BackgroundTransparency=1; wLbl.TextColor3=C_ACC
wLbl.Font=Enum.Font.Gotham; wLbl.TextSize=10
wLbl.TextXAlignment=Enum.TextXAlignment.Left; wLbl.Parent=wRow
task.spawn(function()
    while true do task.wait(1)
        local t=getKillTool(); wLbl.Text="🗡 "..(t and t.Name or "Không có vũ khí") end end)

section(t1,"PERFORMANCE")

toggle(t1,"⚡ Fix Lag Pro",function()
    return FixLag
end,function(v)
    setFixLag(v)
end)

section(t1,"MOVEMENT")
toggle(t1,"Speed",   function() return CFG.Speed end, function(v) CFG.Speed=v end)
toggle(t1,"High Jump",function() return CFG.Jump  end, function(v) CFG.Jump=v end)
toggle(t1,"Fly",     function() return CFG.Fly   end, function(v)
    CFG.Fly=v; flyPad.Visible=v; if v then startFly() else stopFly() end end)
toggle(t1,"👻 Đi xuyên tường",function() return CFG.Noclip end, function(v)
    CFG.Noclip=v; if not v then restoreNoclip() end end)
toggle(t1,"Fullbright",function() return CFG.Fullbright end, function(v)
    CFG.Fullbright=v; setFullbright(v) end)

section(t1,"COMBAT")
toggle(t1,"Kill Aura", function() return CFG.KillAura end, function(v) CFG.KillAura=v end)
toggle(t1,"Auto Chop", function() return CFG.AutoChop end, function(v) CFG.AutoChop=v end)

section(t1,"UTILITY")
toggle(t1,"ESP Trẻ",   function() return CFG.ESPChild end, function(v)
    CFG.ESPChild=v; if not v then clearESPChild() end end)
toggle(t1,"Auto dồn đồ",function() return CFG.AutoDrop end, function(v) CFG.AutoDrop=v end)
button(t1,"🔥 TP Lửa trại", tpCampfire)
button(t1,"🪵 Dồn đồ ngay", function()
    task.spawn(function() local n=dropScan(); print("[ollie] Đã dồn "..n.." món") end) end)
button(t1,"🗺️ Reveal map", function() task.spawn(revealMap) end)

-- ===================== TAB 2: SLIDER =====================
local t2 = tabs[2]
section(t2,"TỐC ĐỘ & NHẢY")
slider(t2,"Walk Speed",  16, 300, function() return CFG.WalkSpeed end, function(v) CFG.WalkSpeed=v end)
slider(t2,"Jump Power",  50, 500, function() return CFG.JumpPower end, function(v) CFG.JumpPower=v end)
slider(t2,"Fly Speed",   10, 200, function() return CFG.FlySpeed  end, function(v) CFG.FlySpeed=v  end)

section(t2,"PHẠM VI TẤN CÔNG")
slider(t2,"Kill Radius",  10, 500, function() return CFG.KillRadius  end, function(v) CFG.KillRadius=v  end)
slider(t2,"Chop Radius",  10, 500, function() return CFG.ChopRadius  end, function(v) CFG.ChopRadius=v  end)

section(t2,"TỐC ĐỘ ĐÁNH")
slider(t2,"Delay (x10ms)", 5, 60,
    function() return math.floor(CFG.Delay*100) end,
    function(v) CFG.Delay=v/100 end)

-- ===================== TAB 3: TRẺ EM =====================
local t3 = tabs[3]

local scanTop=Instance.new("Frame")
scanTop.Size=UDim2.new(0.95,0,0,28); scanTop.BackgroundColor3=C_HDR
scanTop.BorderSizePixel=0; scanTop.Parent=t3; mkCorner(scanTop,6)
local scanLbl=Instance.new("TextLabel")
scanLbl.Size=UDim2.new(1,-40,1,0); scanLbl.Position=UDim2.new(0,8,0,0)
scanLbl.BackgroundTransparency=1; scanLbl.Text="Danh sách trẻ em"
scanLbl.TextColor3=C_ACC; scanLbl.Font=Enum.Font.GothamBold
scanLbl.TextSize=11; scanLbl.TextXAlignment=Enum.TextXAlignment.Left; scanLbl.Parent=scanTop
local scanBtn=Instance.new("TextButton")
scanBtn.Size=UDim2.new(0,30,0,20); scanBtn.Position=UDim2.new(1,-34,0.5,-10)
scanBtn.BackgroundColor3=C_ON; scanBtn.Text="🔍"; scanBtn.TextSize=11
scanBtn.Font=Enum.Font.Gotham; scanBtn.BorderSizePixel=0; scanBtn.Parent=scanTop; mkCorner(scanBtn,5)

local childContainer=Instance.new("Frame")
childContainer.Size=UDim2.new(0.95,0,0,0); childContainer.AutomaticSize=Enum.AutomaticSize.Y
childContainer.BackgroundTransparency=1; childContainer.BorderSizePixel=0; childContainer.Parent=t3
local childLayout=Instance.new("UIListLayout")
childLayout.Padding=UDim.new(0,4); childLayout.Parent=childContainer

local function populateChildren()
    for _,c in ipairs(childContainer:GetChildren()) do
        if c:IsA("GuiObject") then c:Destroy() end
    end
    local r,list = root(),{}
    for _,m in ipairs(childCache) do
        if m.Parent then
            local p=partOf(m)
            if p then
                local d=r and math.floor((p.Position-r.Position).Magnitude) or 0
                table.insert(list,{m=m,p=p,d=d})
            end
        end
    end
    table.sort(list,function(a,b) return a.d<b.d end)
    if #list==0 then
        local e=Instance.new("TextLabel")
        e.Size=UDim2.new(1,0,0,24); e.BackgroundTransparency=1
        e.Text="Không tìm thấy trẻ nào"; e.TextColor3=C_SUB
        e.Font=Enum.Font.Gotham; e.TextSize=11; e.Parent=childContainer
        return
    end
    for i,item in ipairs(list) do
        local row=Instance.new("Frame")
        row.Size=UDim2.new(1,-4,0,48); row.BackgroundColor3=C_ROW
        row.BorderSizePixel=0; row.Parent=childContainer; mkCorner(row,6)

        local nameLbl=Instance.new("TextLabel")
        nameLbl.Size=UDim2.new(1,-50,0,20); nameLbl.Position=UDim2.new(0,8,0,4)
        nameLbl.BackgroundTransparency=1
        nameLbl.Text=string.format("%d. %s",i,item.m.Name)
        nameLbl.TextColor3=C_TXT; nameLbl.Font=Enum.Font.GothamBold
        nameLbl.TextSize=11; nameLbl.TextXAlignment=Enum.TextXAlignment.Left
        nameLbl.TextTruncate=Enum.TextTruncate.AtEnd; nameLbl.Parent=row

        local distLbl=Instance.new("TextLabel")
        distLbl.Size=UDim2.new(1,-50,0,16); distLbl.Position=UDim2.new(0,8,0,26)
        distLbl.BackgroundTransparency=1
        distLbl.Text=string.format("📍 %d studs",item.d)
        distLbl.TextColor3=C_SUB; distLbl.Font=Enum.Font.Gotham
        distLbl.TextSize=10; distLbl.TextXAlignment=Enum.TextXAlignment.Left; distLbl.Parent=row

        local tpBtn=Instance.new("TextButton")
        tpBtn.Size=UDim2.new(0,36,0,20); tpBtn.Position=UDim2.new(1,-42,0.5,-10)
        tpBtn.BackgroundColor3=C_ON; tpBtn.BorderSizePixel=0; tpBtn.Text="TP"
        tpBtn.TextColor3=Color3.new(1,1,1); tpBtn.Font=Enum.Font.GothamBold
        tpBtn.TextSize=11; tpBtn.Parent=row; mkCorner(tpBtn,5)
        tpBtn.MouseButton1Click:Connect(function() tpTo(item.m) end)
    end
end
scanBtn.MouseButton1Click:Connect(populateChildren)

-- ===================== TAB 4: TP & ĐỒ =====================
local t4 = tabs[4]

section(t4, "NGƯỜI CHƠI (KÉO VỀ VỊ TRÍ BẠN)")
local plrListContainer = Instance.new("Frame")
plrListContainer.Size = UDim2.new(0.95, 0, 0, 0)
plrListContainer.AutomaticSize = Enum.AutomaticSize.Y
plrListContainer.BackgroundTransparency = 1
plrListContainer.BorderSizePixel = 0
plrListContainer.Parent = t4
local plrLayout = Instance.new("UIListLayout")
plrLayout.Padding = UDim.new(0, 4)
plrLayout.Parent = plrListContainer

local function refreshPlayers()
    for _, c in ipairs(plrListContainer:GetChildren()) do
        if c:IsA("GuiObject") then c:Destroy() end
    end
    local r = root()
    local others = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LP then
            local pRoot = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
            local dist = (r and pRoot) and math.floor((pRoot.Position - r.Position).Magnitude) or 0
            table.insert(others, {plr = plr, dist = dist, hasChar = pRoot ~= nil})
        end
    end
    table.sort(others, function(a, b) return a.dist < b.dist end)
    if #others == 0 then
        local empty = Instance.new("TextLabel")
        empty.Size = UDim2.new(1, 0, 0, 22)
        empty.BackgroundTransparency = 1
        empty.Text = "Không có người chơi khác trong map"
        empty.TextColor3 = C_SUB
        empty.Font = Enum.Font.Gotham
        empty.TextSize = 10
        empty.Parent = plrListContainer
        return
    end
    for _, info in ipairs(others) do
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, -4, 0, 32)
        row.BackgroundColor3 = C_ROW
        row.BorderSizePixel = 0
        row.Parent = plrListContainer
        mkCorner(row, 6)

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -56, 1, 0)
        lbl.Position = UDim2.new(0, 8, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = info.hasChar and string.format("%s (%d studs)", info.plr.Name, info.dist) or (info.plr.Name .. " (chờ spawn)")
        lbl.TextColor3 = C_TXT
        lbl.Font = Enum.Font.Gotham
        lbl.TextSize = 11
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.TextTruncate = Enum.TextTruncate.AtEnd
        lbl.Parent = row

        local goBtn = Instance.new("TextButton")
        goBtn.Size = UDim2.new(0, 44, 0, 20)
        goBtn.Position = UDim2.new(1, -50, 0.5, -10)
        goBtn.BackgroundColor3 = info.hasChar and C_ON or C_OFF
        goBtn.BorderSizePixel = 0
        goBtn.Text = "Kéo về"
        goBtn.TextColor3 = Color3.new(1, 1, 1)
        goBtn.Font = Enum.Font.GothamBold
        goBtn.TextSize = 10
        goBtn.Parent = row
        mkCorner(goBtn, 5)
        goBtn.MouseButton1Click:Connect(function() pullPlayerToMe(info.plr) end)
    end
end

button(t4, "🔄 Làm mới danh sách người chơi", refreshPlayers)
refreshPlayers()

local function buildItemCategoryUI(titleText, scanBtnText, pullAllText, itemList, emptyLabel)
    section(t4, titleText)

    local listContainer = Instance.new("Frame")
    listContainer.Size = UDim2.new(0.95, 0, 0, 0)
    listContainer.AutomaticSize = Enum.AutomaticSize.Y
    listContainer.BackgroundTransparency = 1
    listContainer.BorderSizePixel = 0
    listContainer.Parent = t4
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 4)
    layout.Parent = listContainer

    local latestItems = {}

    local function renderList()
        for _, c in ipairs(listContainer:GetChildren()) do
            if c:IsA("GuiObject") then c:Destroy() end
        end
        if #latestItems == 0 then
            local empty = Instance.new("TextLabel")
            empty.Size = UDim2.new(1, 0, 0, 24)
            empty.BackgroundTransparency = 1
            empty.Text = "Không tìm thấy " .. emptyLabel
            empty.TextColor3 = C_SUB
            empty.Font = Enum.Font.Gotham
            empty.TextSize = 11
            empty.Parent = listContainer
            return
        end
        local maxShow = math.min(#latestItems, 20)
        for i = 1, maxShow do
            local entry = latestItems[i]
            local row = Instance.new("Frame")
            row.Size = UDim2.new(1, -4, 0, 34)
            row.BackgroundColor3 = C_ROW
            row.BorderSizePixel = 0
            row.Parent = listContainer
            mkCorner(row, 6)

            local nameLbl = Instance.new("TextLabel")
            nameLbl.Size = UDim2.new(1, -56, 1, 0)
            nameLbl.Position = UDim2.new(0, 8, 0, 0)
            nameLbl.BackgroundTransparency = 1
            nameLbl.Text = string.format("%d. %s · %d studs", i, entry.name, entry.dist)
            nameLbl.TextColor3 = C_TXT
            nameLbl.Font = Enum.Font.Gotham
            nameLbl.TextSize = 11
            nameLbl.TextXAlignment = Enum.TextXAlignment.Left
            nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
            nameLbl.Parent = row

            local pullBtn = Instance.new("TextButton")
            pullBtn.Size = UDim2.new(0, 44, 0, 20)
            pullBtn.Position = UDim2.new(1, -50, 0.5, -10)
            pullBtn.BackgroundColor3 = C_ON
            pullBtn.BorderSizePixel = 0
            pullBtn.Text = "Kéo về"
            pullBtn.TextColor3 = Color3.new(1, 1, 1)
            pullBtn.Font = Enum.Font.GothamBold
            pullBtn.TextSize = 10
            pullBtn.Parent = row
            mkCorner(pullBtn, 5)
            pullBtn.MouseButton1Click:Connect(function()
                bringToPlayer(entry.obj, i - 1)
            end)
        end
    end

    button(t4, scanBtnText, function()
        latestItems = scanExactItems(itemList)
        renderList()
    end)

    button(t4, pullAllText, function()
        task.spawn(function()
            latestItems = scanExactItems(itemList)
            local limit = math.min(#latestItems, 12)
            for i = 1, limit do
                bringToPlayer(latestItems[i].obj, i - 1)
                task.wait(0.06)
            end
            renderList()
        end)
    end)
end

buildItemCategoryUI(
    "THỨC ĂN",
    "🍎 Quét Thức ăn (Berry, Carrot, Apple, Corn, Pumpkin, Chili)",
    "🧺 Kéo Thức ăn gần nhất về người chơi",
    FOOD_ITEMS,
    "thức ăn trong map"
)

buildItemCategoryUI(
    "NGUYÊN LIỆU SẮT",
    "⚙️ Quét Nguyên liệu sắt (Bolt, Sheet Metal, Broken Fan...)",
    "🧲 Kéo Nguyên liệu sắt gần nhất về người chơi",
    SCRAP_ITEMS,
    "nguyên liệu sắt trong map"
)

print("[ollie] v7 loaded ✓")
