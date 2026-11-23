-- 99 Nights in the Forest — ollie v10 (UI Dark Blue)
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
    Speed=false,     WalkSpeed=40,
    Jump=false,      JumpPower=90,
    Fly=false,       FlySpeed=60,
    Noclip=false,
    KillAura=false,  KillRadius=150,
    AutoChop=false,  ChopRadius=130,
    AutoDrop=false,
    AutoEat=false,
    ESPChild=false,
    Fullbright=false,
    Delay=0.35,
}

local MAX_KILL   = 6
local TOOL_SFX   = "11960515286"
local CHILD_KEY  = "Lost Child"
local GUI_NAME   = "OllieUI"

-- =================== XOÁ MENU CŨ ===================
for _, v in ipairs(PlayerGui:GetChildren()) do
    if v:IsA("ScreenGui") and v.Name == GUI_NAME then v:Destroy() end
end
pcall(function()
    for _, v in ipairs(game:GetService("CoreGui"):GetChildren()) do
        if v:IsA("ScreenGui") and v.Name == GUI_NAME then v:Destroy() end
    end
end)

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
    local c = LP.Character; return c and c:FindFirstChild("HumanoidRootPart")
end
local function hum()
    local c = LP.Character; return c and c:FindFirstChildOfClass("Humanoid")
end
local function partOf(m)
    if not m then return nil end
    if m:IsA("BasePart") then return m end
    if m:IsA("Model") then
        if m.PrimaryPart then return m.PrimaryPart end
        local hrp = m:FindFirstChild("HumanoidRootPart"); if hrp then return hrp end
        return m:FindFirstChildWhichIsA("BasePart", true)
    end
end
local function findFromList(list, inv, char)
    for _, name in ipairs(list) do
        local t = (inv and inv:FindFirstChild(name)) or (char and char:FindFirstChild(name))
        if t then return t end
    end
end
local function getFallback(inv, char)
    if inv then
        local t = inv:FindFirstChildWhichIsA("Tool"); if t then return t end
        for _, item in ipairs(inv:GetChildren()) do if item:IsA("Model") then return item end end
    end
    return char and char:FindFirstChildWhichIsA("Tool")
end
local function getKillTool()
    local inv, char = LP:FindFirstChild("Inventory"), LP.Character
    return findFromList(MELEE_WEAPONS,inv,char) or findFromList(AXES,inv,char) or getFallback(inv,char)
end
local function getChopTool()
    local inv, char = LP:FindFirstChild("Inventory"), LP.Character
    return findFromList(AXES,inv,char) or findFromList(MELEE_WEAPONS,inv,char) or getFallback(inv,char)
end
local function getFirePart()
    local map = Workspace:FindFirstChild("Map")
    local camp = map and map:FindFirstChild("Campground")
    local fire = camp and camp:FindFirstChild("MainFire", true)
    if fire then return partOf(fire) end
    for _, o in ipairs(Workspace:GetDescendants()) do
        if o.Name=="MainFire" or o.Name=="Campfire" then
            local p=partOf(o); if p then return p end
        end
    end
end
local function getNilByName(name)
    local out = {}
    if not getnilinstances then return out end
    local ok, nilList = pcall(getnilinstances); if not ok then return out end
    for _, obj in ipairs(nilList) do
        local ok2, n = pcall(function() return obj.Name end)
        if ok2 and n == name then table.insert(out, obj) end
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
        childCache = out; task.wait(1.5)
    end
end)

-- =================== COUNTER ===================
local hitCounter = 0
local function resetCounter() hitCounter = 0 end
Workspace.ChildAdded:Connect(function(c) if c.Name=="Map" then resetCounter() end end)
Workspace.ChildRemoved:Connect(function(c) if c.Name=="Map" then resetCounter() end end)
LP.CharacterAdded:Connect(function()
    task.wait(0.5); resetCounter()
    if CFG.Fly then startFly() end
end)
local function nextId() hitCounter+=1; return hitCounter.."_"..TOOL_SFX end

-- =================== SWING ===================
local function hitOnce(tool, target, p)
    if not DamageRF then return false end
    local ok = pcall(DamageRF.InvokeServer, DamageRF, target, tool, nextId(), CFrame.new(p.Position), false)
    if HitSoundRE then pcall(HitSoundRE.FireServer, HitSoundRE, "FireAllClients", target, tool) end
    return ok
end
local function swing(tool, target, p)
    if not (EquipRE and UnequipRE and DamageRF) then return false end
    pcall(EquipRE.FireServer, EquipRE, "FireAllClients", tool); task.wait(0.03)
    local ok = hitOnce(tool, target, p); task.wait(0.025)
    pcall(UnequipRE.FireServer, UnequipRE, "FireAllClients", tool)
    return ok
end
local function swingBatch(tool, targets)
    if not (EquipRE and UnequipRE and DamageRF) or #targets==0 then return end
    pcall(EquipRE.FireServer, EquipRE, "FireAllClients", tool); task.wait(0.03)
    local limit = math.min(#targets, MAX_KILL)
    for i=1,limit do
        if not CFG.KillAura then break end
        local t = targets[i]
        if t.m and t.m.Parent and t.p and t.p.Parent then
            local h = t.m:FindFirstChildWhichIsA("Humanoid", true)
            if h and h.Health>0 then hitOnce(tool, t.m, t.p) end
        end
        if i<limit then task.wait(0.05) end
    end
    pcall(UnequipRE.FireServer, UnequipRE, "FireAllClients", tool)
end

-- =================== KILL AURA ===================
local SCAN_FOLDERS = { "Characters","Enemies","Mobs","NPCs" }
local function getAnimals(r)
    local out, ch, seen = {}, LP.Character, {}
    local maxDSq = CFG.KillRadius * CFG.KillRadius
    local rPos   = r.Position
    local function tryAdd(o)
        if seen[o] or o==ch then return end; seen[o]=true
        if Players:GetPlayerFromCharacter(o) then return end
        if string.find(o.Name, CHILD_KEY, 1, true) then return end
        local h = o:FindFirstChildWhichIsA("Humanoid", true)
        if not (h and h.Health>0) then return end
        local p = partOf(o); if not p then return end
        local d = p.Position-rPos; local dSq=d.X*d.X+d.Y*d.Y+d.Z*d.Z
        if dSq<=maxDSq then table.insert(out,{m=o,p=p,dSq=dSq}) end
    end
    for _, o in ipairs(Workspace:GetChildren()) do if o:IsA("Model") then tryAdd(o) end end
    for _, fn in ipairs(SCAN_FOLDERS) do
        local folder = Workspace:FindFirstChild(fn)
        if folder then for _, o in ipairs(folder:GetChildren()) do if o:IsA("Model") then tryAdd(o) end end end
    end
    table.sort(out, function(a,b) return a.dSq<b.dSq end)
    return out
end

-- =================== AUTO CHOP ===================
local skipTree = {}
local TREE_KEYS = { "Tree","Pine","Oak","Birch","Fir","Bush","Foliage" }
local function getTrees(r)
    local out = {}; local maxDSq=CFG.ChopRadius*CFG.ChopRadius; local rPos=r.Position; local now=os.clock()
    local function scanFolder(folder)
        if not folder then return end
        for _, t in ipairs(folder:GetChildren()) do
            if not (skipTree[t] and now<skipTree[t]) then
                local p=partOf(t)
                if p then
                    local d=p.Position-rPos; local dSq=d.X*d.X+d.Y*d.Y+d.Z*d.Z
                    if dSq<=maxDSq then table.insert(out,{m=t,p=p,dSq=dSq}) end
                end
            end
        end
    end
    local map = Workspace:FindFirstChild("Map")
    scanFolder(map and map:FindFirstChild("Foliage"))
    scanFolder(map and map:FindFirstChild("Trees"))
    scanFolder(Workspace:FindFirstChild("Foliage"))
    scanFolder(Workspace:FindFirstChild("Trees"))
    if #out==0 then
        local scanRoot = map or Workspace
        for _, o in ipairs(scanRoot:GetDescendants()) do
            if o:IsA("Model") and hasKey(o.Name,TREE_KEYS) and not (skipTree[o] and now<skipTree[o]) then
                local p=partOf(o)
                if p then
                    local d=p.Position-rPos; local dSq=d.X*d.X+d.Y*d.Y+d.Z*d.Z
                    if dSq<=maxDSq then table.insert(out,{m=o,p=p,dSq=dSq}) end
                end
            end
        end
    end
    table.sort(out, function(a,b) return a.dSq<b.dSq end)
    return out
end

-- =================== COMBAT LOOP ===================
task.spawn(function()
    while true do
        task.wait(CFG.Delay)
        if CFG.KillAura then
            local r, tool = root(), getKillTool()
            if r and tool then
                local targets = getAnimals(r)
                if #targets>0 then swingBatch(tool, targets) end
            end
        end
        if CFG.AutoChop then
            local r, tool = root(), getChopTool()
            if r and tool then
                local trees = getTrees(r)
                if #trees>0 then
                    local t=trees[1]; local ok=swing(tool,t.m,t.p)
                    skipTree[t.m] = os.clock()+(ok and 3.0 or 1.5)
                end
            end
        end
    end
end)

-- =================== NOCLIP ===================
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
    local h=hum(); if not h then return end
    if CFG.Speed then h.WalkSpeed=CFG.WalkSpeed end
    if CFG.Jump  then h.UseJumpPower=true; h.JumpPower=CFG.JumpPower end
end)
RunService.Stepped:Connect(function()
    local c=LP.Character; if not c then return end
    if CFG.Noclip then
        for _, obj in ipairs(c:GetDescendants()) do
            if obj:IsA("BasePart") then
                if noclipBackup[obj]==nil then noclipBackup[obj]=obj.CanCollide end
                if obj.CanCollide then obj.CanCollide=false end
            end
        end
    elseif next(noclipBackup) then restoreNoclip() end
end)

-- =================== FLY ===================
local flyBV, flyBG, flyConn
local padUp, padDown = false, false
local function stopFly()
    if flyConn then flyConn:Disconnect(); flyConn=nil end
    if flyBV and flyBV.Parent then flyBV:Destroy() end
    if flyBG and flyBG.Parent then flyBG:Destroy() end
    flyBV, flyBG = nil, nil
    local h=hum(); if h then h.PlatformStand=false end
end
function startFly()
    stopFly()
    local r, h = root(), hum(); if not (r and h) then return end
    h.PlatformStand = true
    flyBV = Instance.new("BodyVelocity"); flyBV.MaxForce=Vector3.new(1e6,1e6,1e6); flyBV.Velocity=Vector3.zero; flyBV.Parent=r
    flyBG = Instance.new("BodyGyro"); flyBG.MaxTorque=Vector3.new(1e6,1e6,1e6); flyBG.P=1e4; flyBG.Parent=r
    flyConn = RunService.Heartbeat:Connect(function()
        local cam=Workspace.CurrentCamera; local rr,hh=root(),hum()
        if not (cam and rr and hh and flyBV and flyBV.Parent) then return end
        local md=hh.MoveDirection
        local fl=cam.CFrame.LookVector; local fr=cam.CFrame.RightVector
        local flatL=Vector3.new(fl.X,0,fl.Z); local flatR=Vector3.new(fr.X,0,fr.Z)
        if flatL.Magnitude>0 then flatL=flatL.Unit end
        if flatR.Magnitude>0 then flatR=flatR.Unit end
        local vy=0
        if UIS:IsKeyDown(Enum.KeyCode.Space) or padUp   then vy= 1 end
        if UIS:IsKeyDown(Enum.KeyCode.LeftControl) or padDown then vy=-1 end
        flyBV.Velocity = (flatL*(-md.Z)+flatR*md.X)*CFG.FlySpeed + Vector3.new(0,vy*CFG.FlySpeed,0)
        flyBG.CFrame   = CFrame.new(rr.Position, rr.Position+flatL)
    end)
end

-- =================== FULLBRIGHT ===================
local fbPrev, fbConn
local function applyFB()
    Lighting.Brightness=3; Lighting.ClockTime=12; Lighting.FogEnd=1e6
    Lighting.Ambient=Color3.fromRGB(180,180,180); Lighting.OutdoorAmbient=Color3.fromRGB(180,180,180)
end
local function setFullbright(on)
    if on then
        if not fbPrev then fbPrev={B=Lighting.Brightness,C=Lighting.ClockTime,F=Lighting.FogEnd,A=Lighting.Ambient,OA=Lighting.OutdoorAmbient} end
        applyFB()
        if not fbConn then fbConn=RunService.Heartbeat:Connect(function() if CFG.Fullbright then applyFB() end end) end
    else
        if fbConn then fbConn:Disconnect(); fbConn=nil end
        if fbPrev then Lighting.Brightness=fbPrev.B; Lighting.ClockTime=fbPrev.C; Lighting.FogEnd=fbPrev.F; Lighting.Ambient=fbPrev.A; Lighting.OutdoorAmbient=fbPrev.OA; fbPrev=nil end
    end
end

-- =================== AUTO EAT ===================
local eatStatusMsg = "Chờ bật..."
task.spawn(function()
    while true do
        task.wait(2)
        if CFG.AutoEat then
            if not ConsumeRF then eatStatusMsg="❌ Thiếu remote"; continue end
            if not getnilinstances then eatStatusMsg="❌ Executor không hỗ trợ"; continue end
            local carrots = getNilByName("Carrot")
            if #carrots==0 then eatStatusMsg="⚠️ Không có Carrot"; continue end
            local ate=0
            for _, carrot in ipairs(carrots) do
                if not CFG.AutoEat then break end
                local ok = pcall(ConsumeRF.InvokeServer, ConsumeRF, carrot)
                if ok then ate+=1 end
                task.wait(0.3)
            end
            eatStatusMsg = string.format("✅ Đã ăn %d carrot", ate)
        end
    end
end)

-- =================== ESP TRẺ ===================
local espTag = {}
local function clearESPChild()
    for _, pair in pairs(espTag) do
        if pair.hl and pair.hl.Parent then pair.hl:Destroy() end
        if pair.bb and pair.bb.Parent then pair.bb:Destroy() end
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
                    if pair.hl and pair.hl.Parent then pair.hl:Destroy() end
                    if pair.bb and pair.bb.Parent then pair.bb:Destroy() end
                    if pair.conn then pair.conn:Disconnect() end
                    espTag[m] = nil
                end
            end
            for _, m in ipairs(childCache) do
                if m.Parent and not espTag[m] then
                    local hl=Instance.new("Highlight"); hl.FillColor=Color3.fromRGB(255,220,80); hl.OutlineColor=Color3.fromRGB(255,220,80); hl.FillTransparency=0.45; hl.Adornee=m; hl.Parent=m
                    local ap=partOf(m); local bb, lc
                    if ap then
                        bb=Instance.new("BillboardGui"); bb.Adornee=ap; bb.Size=UDim2.new(0,160,0,44); bb.StudsOffset=Vector3.new(0,3,0); bb.AlwaysOnTop=true; bb.Parent=ap
                        local lbl=Instance.new("TextLabel"); lbl.Size=UDim2.new(1,0,1,0); lbl.BackgroundTransparency=1; lbl.TextColor3=Color3.fromRGB(255,230,80); lbl.TextStrokeColor3=Color3.new(0,0,0); lbl.TextStrokeTransparency=0.3; lbl.Font=Enum.Font.GothamBold; lbl.TextSize=14; lbl.Parent=bb
                        lc=RunService.Heartbeat:Connect(function()
                            if not m.Parent or not CFG.ESPChild then lc:Disconnect(); return end
                            local rr=root(); local pp=partOf(m)
                            if rr and pp then lbl.Text=m.Name.."\n📍 "..math.floor((pp.Position-rr.Position).Magnitude).." studs"
                            else lbl.Text=m.Name end
                        end)
                    end
                    espTag[m]={hl=hl,bb=bb,conn=lc}
                end
            end
        else
            if next(espTag) then clearESPChild() end
        end
    end
end)

-- =================== TP ===================
local function tpTo(m) local r,p=root(),partOf(m); if r and p then r.CFrame=CFrame.new(p.Position+Vector3.new(0,4,0)) end end
local function tpCampfire() local fp=getFirePart(); local r=root(); if fp and r then r.CFrame=CFrame.new(fp.Position+Vector3.new(0,4,0)) end end
local function pullPlayerToMe(plr)
    if not plr or plr==LP then return end
    local r=root(); local tr=plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
    if r and tr then tr.CFrame=r.CFrame*CFrame.new(0,1,-4) end
end

-- =================== PULL ITEMS ===================
local function pullAllExact(nameList)
    local r=root(); if not r then return 0 end
    local ch=LP.Character; local found={}
    for _, o in ipairs(Workspace:GetDescendants()) do
        if ch and o:IsDescendantOf(ch) then continue end
        if Players:GetPlayerFromCharacter(o) then continue end
        if (o:IsA("Model") or o:IsA("BasePart")) and matchesExact(o.Name, nameList) then
            local p=partOf(o); if p then table.insert(found,{obj=o,dist=(p.Position-r.Position).Magnitude}) end
        end
    end
    table.sort(found,function(a,b) return a.dist<b.dist end)
    local count=0
    for i=1,math.min(#found,20) do
        if not (DragRE and StopDragRE) then break end
        local o=found[i].obj; local rr=root(); if not rr then break end
        local spreadX=((count%3)-1)*1.4; local liftY=1.2+math.floor(count/3)*0.6
        local goalCF=rr.CFrame*CFrame.new(spreadX,liftY,-3)
        if o:IsA("Model") then
            if not o.PrimaryPart then pcall(function() o.PrimaryPart=partOf(o) end) end
            pcall(DragRE.FireServer,DragRE,o)
            if o.PrimaryPart then pcall(function() o:SetPrimaryPartCFrame(goalCF) end)
            else pcall(function() o:PivotTo(goalCF) end) end
        elseif o:IsA("BasePart") then
            pcall(DragRE.FireServer,DragRE,o); pcall(function() o.CFrame=goalCF end)
        end
        task.wait(0.04); pcall(StopDragRE.FireServer,StopDragRE,o); count+=1; task.wait(0.08)
    end
    return count
end

-- =================== DỒN NHIÊN LIỆU ===================
local droppedAt = {}
local function dumpFuelToFire()
    local fp=getFirePart(); if not (fp and DragRE and StopDragRE) then return 0 end
    local ch,count,seen=LP.Character,0,{}
    for _, o in ipairs(Workspace:GetDescendants()) do
        if not o:IsA("Model") then continue end
        if seen[o] then continue end
        if ch and o:IsDescendantOf(ch) then continue end
        if Players:GetPlayerFromCharacter(o) then continue end
        if (droppedAt[o] or 0)+20>os.clock() then continue end
        if not matchesExact(o.Name,FUEL_EXACT) then continue end
        seen[o]=true
        if not o.PrimaryPart then pcall(function() o.PrimaryPart=partOf(o) end) end
        if not o.PrimaryPart then continue end
        droppedAt[o]=os.clock()
        local offset=Vector3.new(math.random(-20,20)/10,7+count*0.4,math.random(-20,20)/10)
        pcall(DragRE.FireServer,DragRE,o)
        pcall(function() o:SetPrimaryPartCFrame(CFrame.new(fp.Position+offset)) end)
        task.wait(0.05); pcall(StopDragRE.FireServer,StopDragRE,o); count+=1; task.wait(0.1)
    end
    return count
end
task.spawn(function()
    while true do task.wait(5); if CFG.AutoDrop then pcall(dumpFuelToFire) end end
end)

-- =================== TRỒNG CÂY ===================
local plantStatusMsg = "Đứng vào vị trí muốn trồng"
local function plantAllSaplings()
    if not PlantRE then plantStatusMsg="❌ Thiếu remote PlantItem"; return 0 end
    if not getnilinstances then plantStatusMsg="❌ Executor không hỗ trợ"; return 0 end
    plantStatusMsg = "🔍 Đang quét..."
    local saplings = getNilByName("Sapling")
    if #saplings==0 then plantStatusMsg="⚠️ Không có mầm cây"; return 0 end
    plantStatusMsg = string.format("🌱 %d mầm — đang trồng...", #saplings)
    local r=root(); if not r then plantStatusMsg="❌ Không thấy nhân vật"; return 0 end
    local basePos = r.CFrame.Position - Vector3.new(0,3,0)
    local count=0
    for _, sapling in ipairs(saplings) do
        local ok0=pcall(function() return sapling.Name end); if not ok0 then continue end
        local offset=Vector3.new(math.random(-3,3)/10,0,math.random(-3,3)/10)
        local ok2=pcall(PlantRE.InvokeServer,PlantRE,sapling,basePos+offset)
        if StopDragRE then pcall(StopDragRE.FireServer,StopDragRE,sapling) end
        if ok2 then count+=1 end; task.wait(0.15)
    end
    plantStatusMsg = count>0 and string.format("✅ Đã trồng %d/%d mầm",count,#saplings) or "⚠️ Trồng thất bại"
    return count
end

-- =================== REVEAL MAP ===================
local function revealMap()
    if not MapRE then return end
    local cells={}
    for row=1,64 do for col=1,64 do table.insert(cells,{Row=row,Col=col}) end end
    for i=1,#cells,200 do
        local b={}; for j=i,math.min(i+199,#cells) do table.insert(b,cells[j]) end
        pcall(MapRE.FireServer,MapRE,b,{}); task.wait(0.1)
    end
end

-- =================== FIX LAG ===================
local FixLag=false; local LagBackup={}; local lagConn,lagGen=nil,0
local HEAVY_MATS={[Enum.Material.Neon]=Enum.Material.SmoothPlastic,[Enum.Material.Glass]=Enum.Material.SmoothPlastic,[Enum.Material.ForceField]=Enum.Material.SmoothPlastic,[Enum.Material.DiamondPlate]=Enum.Material.SmoothPlastic,[Enum.Material.CorrodedMetal]=Enum.Material.SmoothPlastic,[Enum.Material.Foil]=Enum.Material.SmoothPlastic,[Enum.Material.WoodPlanks]=Enum.Material.SmoothPlastic,[Enum.Material.Cobblestone]=Enum.Material.SmoothPlastic}
local function saveProp(obj,prop) local t=LagBackup[obj]; if not t then t={}; LagBackup[obj]=t end; if t[prop]==nil then local ok,val=pcall(function() return obj[prop] end); if ok then t[prop]=val end end end
local function optimizeObj(obj)
    if not FixLag or not obj or not obj.Parent then return end
    if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") or obj:IsA("PointLight") or obj:IsA("SpotLight") or obj:IsA("SurfaceLight") then
        saveProp(obj,"Enabled"); pcall(function() obj.Enabled=false end); return
    end
    if obj:IsA("BasePart") then
        saveProp(obj,"CastShadow"); pcall(function() obj.CastShadow=false end)
        saveProp(obj,"Material"); local mat=HEAVY_MATS[obj.Material] or Enum.Material.Plastic
        if obj.Material~=mat then pcall(function() obj.Material=mat end) end
    end
end
local function enableFixLag()
    if FixLag then return end; FixLag=true; lagGen+=1; local gen=lagGen
    for _, prop in ipairs({"GlobalShadows","EnvironmentDiffuseScale","EnvironmentSpecularScale","ShadowSoftness"}) do saveProp(Lighting,prop) end
    pcall(function() Lighting.GlobalShadows=false; Lighting.EnvironmentDiffuseScale=0; Lighting.EnvironmentSpecularScale=0; Lighting.ShadowSoftness=0 end)
    if not lagConn then lagConn=Workspace.DescendantAdded:Connect(function(obj) if FixLag then task.defer(optimizeObj,obj) end end) end
    task.spawn(function() local all=Workspace:GetDescendants(); for i=1,#all do if not FixLag or gen~=lagGen then return end; optimizeObj(all[i]); if i%500==0 then task.wait() end end end)
end
local function disableFixLag()
    if not FixLag then return end; FixLag=false; lagGen+=1
    if lagConn then lagConn:Disconnect(); lagConn=nil end
    for obj,props in pairs(LagBackup) do if obj and obj.Parent then for prop,val in pairs(props) do pcall(function() obj[prop]=val end) end end end
    LagBackup={}
end
local function setFixLag(v) if v then enableFixLag() else disableFixLag() end end

--========================================================
-- GUI FRAMEWORK (Dark Blue V10)
--========================================================

local Theme = {
    Background   = Color3.fromRGB(15, 20, 32),
    Sidebar      = Color3.fromRGB(20, 28, 43),
    Panel        = Color3.fromRGB(24, 34, 52),
    Element      = Color3.fromRGB(33, 46, 67),
    Accent       = Color3.fromRGB(72, 128, 235),
    AccentLight  = Color3.fromRGB(120, 169, 255),
    Text         = Color3.fromRGB(238, 243, 255),
    SubText      = Color3.fromRGB(153, 171, 199),
    Green        = Color3.fromRGB(55, 180, 120),
    Red          = Color3.fromRGB(190, 65, 75),
    Yellow       = Color3.fromRGB(235, 185, 60),
}

local ANIM       = 0.22
local WIN_SIZE   = UDim2.fromOffset(570, 420)

-- Assets
local Images = {
    Background = "rbxassetid://7072706763", -- dark abstract
    Banner     = "rbxassetid://7072706763",
    Logo       = "rbxassetid://6031075929", -- roblox star
}

local function Tween(obj, t, props)
    local tw = TweenService:Create(obj, TweenInfo.new(t, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), props)
    tw:Play(); return tw
end
local function Corner(obj, r)
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r); c.Parent = obj
end
local function MakeLabel(parent, text, size, color, bold)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1; l.Text = text; l.TextSize = size
    l.TextColor3 = color or Theme.Text
    l.Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham
    l.Parent = parent; return l
end

-- Root
local Gui = Instance.new("ScreenGui")
Gui.Name = GUI_NAME; Gui.ResetOnSpawn = false
Gui.IgnoreGuiInset = true; Gui.DisplayOrder = 100
Gui.Parent = PlayerGui

local Scale = Instance.new("UIScale"); Scale.Parent = Gui
local function UpdateScale()
    local cam = workspace.CurrentCamera; if not cam then return end
    local v = cam.ViewportSize
    Scale.Scale = math.clamp(math.min(v.X/650, v.Y/480), 0.5, 1)
end
UpdateScale()
if workspace.CurrentCamera then
    workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(UpdateScale)
end

-- Main window
local Main = Instance.new("Frame")
Main.Name = "Main"; Main.Size = WIN_SIZE
Main.Position = UDim2.new(0.5,0,0.5,0); Main.AnchorPoint = Vector2.new(0.5,0.5)
Main.BackgroundColor3 = Theme.Background; Main.BorderSizePixel = 0
Main.ClipsDescendants = true; Main.Visible = false; Main.Parent = Gui
Corner(Main, 13)
local MainStroke = Instance.new("UIStroke"); MainStroke.Color=Theme.Accent; MainStroke.Transparency=0.5; MainStroke.Thickness=1; MainStroke.Parent=Main

-- Background image
local BgImg = Instance.new("ImageLabel")
BgImg.Size=UDim2.fromScale(1,1); BgImg.BackgroundTransparency=1
BgImg.Image=Images.Background; BgImg.ImageTransparency=0.6
BgImg.ScaleType=Enum.ScaleType.Crop; BgImg.ZIndex=0; BgImg.Parent=Main
local Overlay = Instance.new("Frame"); Overlay.Size=UDim2.fromScale(1,1)
Overlay.BackgroundColor3=Theme.Background; Overlay.BackgroundTransparency=0.15
Overlay.BorderSizePixel=0; Overlay.ZIndex=0; Overlay.Parent=Main

-- Header
local Header = Instance.new("Frame")
Header.Size=UDim2.new(1,0,0,48); Header.BackgroundColor3=Theme.Sidebar
Header.BackgroundTransparency=0.08; Header.BorderSizePixel=0; Header.ZIndex=2; Header.Parent=Main

local LogoImg = Instance.new("ImageLabel")
LogoImg.Size=UDim2.fromOffset(30,30); LogoImg.Position=UDim2.fromOffset(10,9)
LogoImg.BackgroundTransparency=1; LogoImg.Image=Images.Logo
LogoImg.ScaleType=Enum.ScaleType.Fit; LogoImg.ZIndex=3; LogoImg.Parent=Header

local Title = MakeLabel(Header, "OLLIE  /  99 NIGHTS", 15, Theme.Text, true)
Title.Position=UDim2.fromOffset(48,0); Title.Size=UDim2.new(1,-150,1,0); Title.TextXAlignment=Enum.TextXAlignment.Left; Title.ZIndex=3

local VerLbl = MakeLabel(Header, "V10", 10, Theme.SubText, true)
VerLbl.Position=UDim2.new(1,-100,0,0); VerLbl.Size=UDim2.fromOffset(45,48); VerLbl.ZIndex=3

-- Weapon display in header
local WeaponLbl = MakeLabel(Header, "🗡 —", 10, Theme.AccentLight, false)
WeaponLbl.Position=UDim2.new(0.3,0,0,0); WeaponLbl.Size=UDim2.new(0.4,0,1,0)
WeaponLbl.TextXAlignment=Enum.TextXAlignment.Center; WeaponLbl.ZIndex=3
task.spawn(function()
    while true do task.wait(1)
        local t=getKillTool(); WeaponLbl.Text="🗡 "..(t and t.Name or "—")
    end
end)

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size=UDim2.fromOffset(33,30); CloseBtn.Position=UDim2.new(1,-41,0,9)
CloseBtn.BackgroundColor3=Theme.Red; CloseBtn.Text="×"; CloseBtn.TextSize=22
CloseBtn.TextColor3=Theme.Text; CloseBtn.Font=Enum.Font.GothamBold
CloseBtn.BorderSizePixel=0; CloseBtn.ZIndex=4; CloseBtn.Parent=Header
Corner(CloseBtn, 7)

-- Drag
local dragging=false; local dragStart; local startPos
Header.InputBegan:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
        dragging=true; dragStart=i.Position; startPos=Main.Position end end)
UIS.InputChanged:Connect(function(i)
    if dragging and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
        local d=i.Position-dragStart
        Main.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,startPos.Y.Scale,startPos.Y.Offset+d.Y) end end)
UIS.InputEnded:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragging=false end end)

-- Sidebar
local Sidebar = Instance.new("Frame")
Sidebar.Size=UDim2.new(0,145,1,-58); Sidebar.Position=UDim2.fromOffset(8,53)
Sidebar.BackgroundColor3=Theme.Sidebar; Sidebar.BackgroundTransparency=0.05
Sidebar.BorderSizePixel=0; Sidebar.ZIndex=2; Sidebar.Parent=Main
Corner(Sidebar, 9)
local TabLayout=Instance.new("UIListLayout"); TabLayout.Padding=UDim.new(0,7); TabLayout.SortOrder=Enum.SortOrder.LayoutOrder; TabLayout.Parent=Sidebar
local TabPad=Instance.new("UIPadding"); TabPad.PaddingTop=UDim.new(0,9); TabPad.PaddingLeft=UDim.new(0,8); TabPad.PaddingRight=UDim.new(0,8); TabPad.Parent=Sidebar

-- Content
local Content = Instance.new("ScrollingFrame")
Content.Size=UDim2.new(1,-165,1,-62); Content.Position=UDim2.fromOffset(157,55)
Content.BackgroundColor3=Theme.Panel; Content.BackgroundTransparency=0.08
Content.BorderSizePixel=0; Content.ScrollBarThickness=3
Content.ScrollBarImageColor3=Theme.Accent; Content.AutomaticCanvasSize=Enum.AutomaticSize.Y
Content.CanvasSize=UDim2.new(); Content.ZIndex=2; Content.Parent=Main
Corner(Content, 9)
local CLayout=Instance.new("UIListLayout"); CLayout.Padding=UDim.new(0,8); CLayout.SortOrder=Enum.SortOrder.LayoutOrder; CLayout.Parent=Content
local CPad=Instance.new("UIPadding"); CPad.PaddingTop=UDim.new(0,10); CPad.PaddingLeft=UDim.new(0,10); CPad.PaddingRight=UDim.new(0,10); CPad.PaddingBottom=UDim.new(0,10); CPad.Parent=Content

-- Reopen FAB
local Reopen = Instance.new("TextButton")
Reopen.Size=UDim2.fromOffset(48,48); Reopen.Position=UDim2.new(0,15,0.5,0)
Reopen.AnchorPoint=Vector2.new(0,0.5); Reopen.BackgroundColor3=Theme.Accent
Reopen.Text="99"; Reopen.TextColor3=Theme.Text; Reopen.Font=Enum.Font.GothamBold
Reopen.TextSize=17; Reopen.BorderSizePixel=0; Reopen.Parent=Gui
Corner(Reopen, 50)

-- Fly pad
local flyPad=Instance.new("Frame"); flyPad.Size=UDim2.fromOffset(60,124); flyPad.Position=UDim2.new(1,-74,1,-132); flyPad.BackgroundTransparency=1; flyPad.Visible=false; flyPad.Parent=Gui
local function holdBtn(yOff,text,onState)
    local b=Instance.new("TextButton"); b.Size=UDim2.fromOffset(56,56); b.Position=UDim2.fromOffset(0,yOff)
    b.BackgroundColor3=Theme.Element; b.BorderSizePixel=0; b.Text=text; b.TextColor3=Theme.AccentLight
    b.Font=Enum.Font.GothamBold; b.TextSize=20; b.Parent=flyPad; Corner(b,28)
    b.MouseButton1Down:Connect(function() onState(true) end); b.MouseButton1Up:Connect(function() onState(false) end); b.MouseLeave:Connect(function() onState(false) end)
    b.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.Touch then onState(true) end end)
    b.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.Touch then onState(false) end end)
end
holdBtn(0,"▲",function(v) padUp=v end); holdBtn(68,"▼",function(v) padDown=v end)

-- Open/Close
local isOpen=false; local busy=false
local function OpenMenu()
    if isOpen or busy then return end; busy=true; isOpen=true
    Main.Visible=true; Main.Size=UDim2.fromOffset(470,330); Main.BackgroundTransparency=1
    BgImg.ImageTransparency=1; Overlay.BackgroundTransparency=1
    Tween(Main,ANIM,{Size=WIN_SIZE,BackgroundTransparency=0})
    Tween(BgImg,ANIM,{ImageTransparency=0.6}); Tween(Overlay,ANIM,{BackgroundTransparency=0.15}).Completed:Wait(); busy=false
end
local function CloseMenu()
    if not isOpen or busy then return end; busy=true; isOpen=false
    Tween(Main,ANIM,{Size=UDim2.fromOffset(470,330),BackgroundTransparency=1})
    Tween(BgImg,ANIM,{ImageTransparency=1}); Tween(Overlay,ANIM,{BackgroundTransparency=1}).Completed:Wait()
    Main.Visible=false; busy=false
end
CloseBtn.MouseButton1Click:Connect(CloseMenu)
Reopen.MouseButton1Click:Connect(OpenMenu)

-- Content helpers
local function ClearContent()
    for _, obj in ipairs(Content:GetChildren()) do
        if obj~=CLayout and obj~=CPad then obj:Destroy() end
    end
    Content.CanvasPosition=Vector2.zero
end

local function Section(text)
    local l=MakeLabel(Content,text,12,Theme.AccentLight,true)
    l.Size=UDim2.new(1,0,0,22); l.TextXAlignment=Enum.TextXAlignment.Left
    return l
end

local function InfoLabel(text)
    local l=MakeLabel(Content,text,11,Theme.SubText,false)
    l.Size=UDim2.new(1,0,0,20); l.TextXAlignment=Enum.TextXAlignment.Left
    return l
end

local function Toggle(text, default, callback)
    local Frame=Instance.new("Frame"); Frame.Size=UDim2.new(1,0,0,40); Frame.BackgroundColor3=Theme.Element; Frame.BorderSizePixel=0; Frame.ZIndex=3; Frame.Parent=Content; Corner(Frame,7)
    local Label=MakeLabel(Frame,text,12,Theme.Text,true); Label.Position=UDim2.fromOffset(10,0); Label.Size=UDim2.new(1,-70,1,0); Label.TextXAlignment=Enum.TextXAlignment.Left
    local Button=Instance.new("TextButton"); Button.Size=UDim2.fromOffset(43,23); Button.Position=UDim2.new(1,-51,0.5,-11)
    Button.TextColor3=Theme.Text; Button.TextSize=10; Button.Font=Enum.Font.GothamBold; Button.BorderSizePixel=0; Button.ZIndex=4; Button.Parent=Frame; Corner(Button,6)
    local enabled=default==true
    local function Update()
        Button.Text=enabled and "ON" or "OFF"
        Tween(Button,0.15,{BackgroundColor3=enabled and Theme.Green or Color3.fromRGB(65,76,96)})
        if callback then callback(enabled) end
    end
    Button.MouseButton1Click:Connect(function() enabled=not enabled; Update() end)
    Button.BackgroundColor3=enabled and Theme.Green or Color3.fromRGB(65,76,96)
    Button.Text=enabled and "ON" or "OFF"
    return function(v) enabled=v==true; Update() end
end

local function Slider(text, min, max, default, callback)
    local Frame=Instance.new("Frame"); Frame.Size=UDim2.new(1,0,0,67); Frame.BackgroundColor3=Theme.Element; Frame.BorderSizePixel=0; Frame.ZIndex=3; Frame.Parent=Content; Corner(Frame,7)
    local ValLbl=MakeLabel(Frame,"",11,Theme.Text,true); ValLbl.Position=UDim2.fromOffset(10,5); ValLbl.Size=UDim2.new(1,-20,0,22); ValLbl.TextXAlignment=Enum.TextXAlignment.Left
    local Bar=Instance.new("Frame"); Bar.Size=UDim2.new(1,-22,0,6); Bar.Position=UDim2.fromOffset(11,43); Bar.BackgroundColor3=Color3.fromRGB(60,73,96); Bar.BorderSizePixel=0; Bar.ZIndex=4; Bar.Parent=Frame; Corner(Bar,6)
    local Fill=Instance.new("Frame"); Fill.BackgroundColor3=Theme.Accent; Fill.BorderSizePixel=0; Fill.ZIndex=5; Fill.Parent=Bar; Corner(Fill,6)
    local Knob=Instance.new("Frame"); Knob.Size=UDim2.fromOffset(15,15); Knob.AnchorPoint=Vector2.new(0.5,0.5); Knob.BackgroundColor3=Theme.Text; Knob.BorderSizePixel=0; Knob.ZIndex=6; Knob.Parent=Bar; Corner(Knob,50)
    local ks=Instance.new("UIStroke"); ks.Color=Theme.Accent; ks.Parent=Knob
    local value=math.clamp(default,min,max); local sliding=false
    local function SetValue(v, smooth)
        value=math.clamp(math.floor(v+0.5),min,max)
        local alpha=(value-min)/(max-min)
        ValLbl.Text=text.." : "..tostring(value)
        local fs=UDim2.new(alpha,0,1,0); local kp=UDim2.new(alpha,0,0.5,0)
        if smooth then Tween(Fill,0.08,{Size=fs}); Tween(Knob,0.08,{Position=kp})
        else Fill.Size=fs; Knob.Position=kp end
        if callback then callback(value) end
    end
    local function FromInput(input)
        local w=Bar.AbsoluteSize.X; if w<=0 then return end
        SetValue(min+(max-min)*math.clamp((input.Position.X-Bar.AbsolutePosition.X)/w,0,1),true)
    end
    Bar.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then sliding=true; FromInput(i) end end)
    UIS.InputChanged:Connect(function(i) if sliding and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then FromInput(i) end end)
    UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then sliding=false end end)
    SetValue(value,false)
    return function(v) SetValue(v,true) end
end

local function ActionBtn(text, callback)
    local b=Instance.new("TextButton"); b.Size=UDim2.new(1,0,0,38); b.BackgroundColor3=Theme.Element
    b.Text=text; b.TextColor3=Theme.Text; b.TextSize=12; b.Font=Enum.Font.GothamSemibold
    b.BorderSizePixel=0; b.Parent=Content; Corner(b,7)
    b.MouseButton1Click:Connect(function()
        Tween(b,0.1,{BackgroundColor3=Theme.Accent})
        task.delay(0.14,function() if b.Parent then Tween(b,0.15,{BackgroundColor3=Theme.Element}) end end)
        if callback then callback() end
    end)
    return b
end

-- Page system
local Pages={}; local TabBtns={}; local CurrTab=nil; local switching=false
local function AddPage(name, icon, cb) Pages[name]={icon=icon,callback=cb} end
local function OpenTab(name)
    if switching or CurrTab==name then return end; switching=true; CurrTab=name
    for n, b in pairs(TabBtns) do Tween(b,0.15,{BackgroundColor3=n==name and Theme.Accent or Theme.Element}) end
    local origPos=Content.Position; Content.Position=origPos+UDim2.fromOffset(12,0); Content.BackgroundTransparency=0.5
    ClearContent()
    local page=Pages[name]; if page and page.callback then page.callback() end
    Tween(Content,0.2,{Position=origPos,BackgroundTransparency=0.08}).Completed:Wait(); switching=false
end

--========================================================
-- PAGES
--========================================================

-- TRANG CHỦ
AddPage("Chính","🏠",function()
    Section("PERFORMANCE")
    Toggle("⚡ Fix Lag Pro", false, function(v) setFixLag(v) end)
    Toggle("🌙 Fullbright",  false, function(v) CFG.Fullbright=v; setFullbright(v) end)

    Section("UTILITY")
    Toggle("🥕 Auto Eat Carrot", false, function(v) CFG.AutoEat=v end)
    InfoLabel(eatStatusMsg)
    Toggle("🪵 Auto dồn nhiên liệu → Lửa", false, function(v) CFG.AutoDrop=v end)
    ActionBtn("🔥 TP Lửa trại", tpCampfire)
    ActionBtn("🪵 Dồn nhiên liệu ngay", function() task.spawn(function() dumpFuelToFire() end) end)
    ActionBtn("🗺️ Reveal map", function() task.spawn(revealMap) end)

    Section("TRỒNG CÂY")
    InfoLabel(plantStatusMsg)
    ActionBtn("🌱 Trồng tất cả mầm cây (Sapling)", function()
        task.spawn(plantAllSaplings)
    end)
end)

-- DI CHUYỂN
AddPage("Di chuyển","🏃",function()
    Section("MOVEMENT")
    Toggle("Speed", false, function(v) CFG.Speed=v end)
    Slider("Walk Speed", 16, 300, CFG.WalkSpeed, function(v) CFG.WalkSpeed=v end)

    Toggle("High Jump", false, function(v) CFG.Jump=v end)
    Slider("Jump Power", 50, 500, CFG.JumpPower, function(v) CFG.JumpPower=v end)

    Toggle("Fly", false, function(v)
        CFG.Fly=v; flyPad.Visible=v
        if v then startFly() else stopFly() end
    end)
    Slider("Fly Speed", 10, 200, CFG.FlySpeed, function(v) CFG.FlySpeed=v end)

    Toggle("👻 Noclip", false, function(v)
        CFG.Noclip=v; if not v then restoreNoclip() end
    end)
end)

-- COMBAT
AddPage("Combat","⚔️",function()
    Section("COMBAT")
    Toggle("Kill Aura", false, function(v) CFG.KillAura=v end)
    Slider("Kill Radius", 10, 500, CFG.KillRadius, function(v) CFG.KillRadius=v end)

    Toggle("Auto Chop", false, function(v) CFG.AutoChop=v end)
    Slider("Chop Radius", 10, 500, CFG.ChopRadius, function(v) CFG.ChopRadius=v end)

    Section("TIMING")
    Slider("Delay (x10ms)", 5, 60, math.floor(CFG.Delay*100), function(v) CFG.Delay=v/100 end)
end)

-- TRẺ EM
AddPage("Trẻ em","👶",function()
    Section("ESP")
    Toggle("ESP Trẻ em", false, function(v)
        CFG.ESPChild=v; if not v then clearESPChild() end
    end)

    Section("DANH SÁCH TRẺ EM")
    ActionBtn("🔍 Quét & hiện danh sách", function()
        -- Xoá danh sách cũ
        for _, obj in ipairs(Content:GetChildren()) do
            if obj:IsA("Frame") and obj.Name=="ChildRow" then obj:Destroy() end
        end
        local r=root()
        local list={}
        for _, m in ipairs(childCache) do
            if m.Parent then
                local p=partOf(m)
                if p then
                    local d=r and math.floor((p.Position-r.Position).Magnitude) or 0
                    table.insert(list,{m=m,d=d})
                end
            end
        end
        table.sort(list,function(a,b) return a.d<b.d end)
        if #list==0 then
            InfoLabel("Không tìm thấy trẻ nào"); return
        end
        for i, item in ipairs(list) do
            local row=Instance.new("Frame"); row.Name="ChildRow"
            row.Size=UDim2.new(1,0,0,38); row.BackgroundColor3=Theme.Element
            row.BorderSizePixel=0; row.Parent=Content; Corner(row,7)
            local nameLbl=MakeLabel(row,string.format("%d. %s   📍%d studs",i,item.m.Name,item.d),11,Theme.Text,true)
            nameLbl.Position=UDim2.fromOffset(10,0); nameLbl.Size=UDim2.new(1,-60,1,0); nameLbl.TextXAlignment=Enum.TextXAlignment.Left
            local tpBtn=Instance.new("TextButton"); tpBtn.Size=UDim2.fromOffset(44,24); tpBtn.Position=UDim2.new(1,-50,0.5,-12)
            tpBtn.BackgroundColor3=Theme.Green; tpBtn.Text="TP"; tpBtn.TextColor3=Theme.Text
            tpBtn.Font=Enum.Font.GothamBold; tpBtn.TextSize=11; tpBtn.BorderSizePixel=0; tpBtn.Parent=row; Corner(tpBtn,6)
            tpBtn.MouseButton1Click:Connect(function() tpTo(item.m) end)
        end
    end)
end)

-- TP & ĐỒ
AddPage("TP & Đồ","📦",function()
    Section("NGƯỜI CHƠI")
    ActionBtn("🔄 Làm mới người chơi", function()
        for _, obj in ipairs(Content:GetChildren()) do
            if obj:IsA("Frame") and obj.Name=="PlrRow" then obj:Destroy() end
        end
        local r=root(); local others={}
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr~=LP then
                local pRoot=plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
                local dist=(r and pRoot) and math.floor((pRoot.Position-r.Position).Magnitude) or 0
                table.insert(others,{plr=plr,dist=dist,hasChar=pRoot~=nil})
            end
        end
        table.sort(others,function(a,b) return a.dist<b.dist end)
        if #others==0 then InfoLabel("Không có người chơi khác"); return end
        for _, info in ipairs(others) do
            local row=Instance.new("Frame"); row.Name="PlrRow"
            row.Size=UDim2.new(1,0,0,38); row.BackgroundColor3=Theme.Element; row.BorderSizePixel=0; row.Parent=Content; Corner(row,7)
            local lbl=MakeLabel(row,
                info.hasChar and string.format("%s  (%d studs)",info.plr.Name,info.dist) or info.plr.Name.." (chờ spawn)",
                11,Theme.Text,true)
            lbl.Position=UDim2.fromOffset(10,0); lbl.Size=UDim2.new(1,-60,1,0); lbl.TextXAlignment=Enum.TextXAlignment.Left
            local btn=Instance.new("TextButton"); btn.Size=UDim2.fromOffset(44,24); btn.Position=UDim2.new(1,-50,0.5,-12)
            btn.BackgroundColor3=info.hasChar and Theme.Green or Color3.fromRGB(65,76,96)
            btn.Text="Kéo"; btn.TextColor3=Theme.Text; btn.Font=Enum.Font.GothamBold; btn.TextSize=11; btn.BorderSizePixel=0; btn.Parent=row; Corner(btn,6)
            btn.MouseButton1Click:Connect(function() pullPlayerToMe(info.plr) end)
        end
    end)

    Section("THỨC ĂN → VỀ NGƯỜI CHƠI")
    ActionBtn("🍎 Kéo thức ăn về người", function()
        task.spawn(function() local n=pullAllExact(FOOD_ITEMS); print("[ollie] Kéo "..n.." thức ăn") end)
    end)

    Section("NGUYÊN LIỆU → VỀ NGƯỜI CHƠI")
    ActionBtn("⚙️ Kéo nguyên liệu về người", function()
        task.spawn(function() local n=pullAllExact(SCRAP_ITEMS); print("[ollie] Kéo "..n.." nguyên liệu") end)
    end)
end)

-- CÀI ĐẶT
AddPage("Cài đặt","⚙️",function()
    Section("INTERFACE")
    Slider("Độ trong suốt nền", 0, 80, 15, function(v)
        Overlay.BackgroundTransparency = v/100
    end)

    Section("MENU")
    ActionBtn("Đóng menu", function() CloseMenu() end)
    ActionBtn("Mở lại menu", function() OpenMenu() end)
end)

-- Tạo tab buttons
local TabOrder = { "Chính","Di chuyển","Combat","Trẻ em","TP & Đồ","Cài đặt" }
for idx, name in ipairs(TabOrder) do
    local page=Pages[name]; if not page then continue end
    local btn=Instance.new("TextButton"); btn.Name=name
    btn.Size=UDim2.new(1,0,0,36); btn.BackgroundColor3=Theme.Element
    btn.Text=page.icon.."  "..name; btn.TextColor3=Theme.Text
    btn.TextSize=11; btn.Font=Enum.Font.GothamSemibold; btn.BorderSizePixel=0
    btn.LayoutOrder=idx; btn.Parent=Sidebar; Corner(btn,7)
    TabBtns[name]=btn
    btn.MouseButton1Click:Connect(function() OpenTab(name) end)
end

-- Start
OpenMenu()
OpenTab("Chính")

print("================================")
print("  OLLIE V10 DARK BLUE LOADED")
print("================================")
