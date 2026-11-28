--========================================================
-- SUNSET UI + OLLIE 99 NIGHTS (COMPLETE FINAL)
-- Fixed Scrapper + God Mode + All Features
--========================================================

local Players      = game:GetService("Players")
local RunService   = game:GetService("RunService")
local UIS          = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting     = game:GetService("Lighting")
local RS           = game:GetService("ReplicatedStorage")
local Workspace    = game:GetService("Workspace")
local CoreGui      = game:GetService("CoreGui")

local Player    = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

for _, name in ipairs({"OllieUI","OllieMenu","ollie_v9","SunsetUI","OllieV10"}) do
    pcall(function() local g=PlayerGui:FindFirstChild(name); if g then g:Destroy() end end)
    pcall(function() local g=CoreGui:FindFirstChild(name);  if g then g:Destroy() end end)
end

--========================================================
-- REMOTES
--========================================================

local Remotes         = RS:WaitForChild("RemoteEvents", 10)
local EquipRE         = Remotes and Remotes:FindFirstChild("EquipItemHandle")
local UnequipRE       = Remotes and Remotes:FindFirstChild("UnequipItemHandle")
local DamageRF        = Remotes and Remotes:FindFirstChild("ToolDamageObject")
local MapRE           = Remotes and Remotes:FindFirstChild("MapCellsDiscovered")
local DragRE          = Remotes and Remotes:FindFirstChild("RequestStartDraggingItem")
local StopDragRE      = Remotes and Remotes:FindFirstChild("StopDraggingItem")
local HitSoundRE      = Remotes and Remotes:FindFirstChild("PlayEnemyHitSound")
local WoodChopSoundRE = Remotes and Remotes:FindFirstChild("RequestReplicateSound")
local PlantRE         = Remotes and Remotes:FindFirstChild("RequestPlantItem")
local ConsumeRF       = Remotes and Remotes:FindFirstChild("RequestConsumeItem")
local OpenChestRE     = Remotes and Remotes:FindFirstChild("RequestOpenItemChest")
local CollectCoinRF   = Remotes and Remotes:FindFirstChild("RequestCollectCoints")
local HotbarItemRF    = Remotes and Remotes:FindFirstChild("RequestHotbarItem")
local BagStoreRF      = Remotes and Remotes:FindFirstChild("RequestBagStoreItem")
local BagDropRE       = Remotes and Remotes:FindFirstChild("RequestBagDropItem")

--========================================================
-- ITEM LISTS
--========================================================

local AXES = { "Old Axe","Good Axe","Ice Axe","Strong Axe","Chainsaw","Admin Axe" }
local HEAVY_AXES = { ["Strong Axe"]=true,["Chainsaw"]=true,["Admin Axe"]=true }
local MELEE_WEAPONS = {
    "Spear","Diamond Spear","Honey Spear","Morningstar","Morning Star",
    "Kunai","Katana","Laser Sword","Ice Sword","Trident",
    "Poison Claws","Poison Spear","Infernal Sword",
    "Cultist King Mace","Brutal Battleaxe","Obsidiron Hammer",
    "Scythe","Vampire Scythe","Happy's Scythe",
}
local SACK_NAMES = { "Admin Sack","Giant Sack","Infernal Sack","Good Sack","Old Sack","Sack","Bag" }
local FOOD_ITEMS = { "Berry","Carrot","Apple","Corn","Pumpkin","Chili" }
local SCRAPPER_KEYS = { "Scrapper","Grinder","Recycler","Anvil" }

-- Tên chính xác phế liệu (case-sensitive)
local SCRAP_EXACT = {
    "Bolt","Sheet Metal","Tyre","Tires & Engines",
    "Metal Chair","Chair","Log",
    "Broken Fan","Broken Radio","Old Radio",
    "Broken Microwave","Washing Machine","Old Car Engine",
    "UFO Junk","UFO Component","UFO Scrap",
    "Cultist Experiment","Cultist Prototype",
    "Obsidiron Shard","Obsidiron Ingot",
}
local SCRAP_EXACT_SET = {}
for _, v in ipairs(SCRAP_EXACT) do SCRAP_EXACT_SET[v] = true end

local FUEL_EXACT = {
    "Biofuel","Coal","Purple Fur Tuft","Fuel Canister","Oil Barrel",
}
local FUEL_EXACT_SET = {}
for _, v in ipairs(FUEL_EXACT) do FUEL_EXACT_SET[v] = true end

local CHEST_KEYS = {
    "Chest","Crate","Supply","Loot",
    "Common Chest","Good Chest","Iron Chest","Legendary Chest",
    "Gold Chest","Ruby Chest","Diamond Chest",
    "Alien Chest","Cold Chest","Ice Chest",
    "Jungle Chest","Vine Chest","Stone Chest","Golden Stone Chest",
    "Volcanic Chest","Infernal Chest","Frog Chest",
    "Spooky Chest","Vampire Chest","Obsidiron Chest",
}
local CHEST_LOOT_WHITELIST = {
    "Old Sack","Good Sack","Infernal Sack","Giant Sack","Admin Sack",
    "Good Axe","Ice Axe","Strong Axe","Chainsaw","Admin Axe",
    "Old Taming Flute","Good Taming Flute","Strong Taming Flute","Admin Taming Flute",
    "Old Flashlight","Strong Flashlight","Admin Flashlight",
    "Spear","Honey Spear","Morningstar","Katana","Laser Sword",
    "Ice Sword","Trident","Poison Claws","Poison Spear","Infernal Sword",
    "Cultist King Mace","Brutal Battleaxe","Obsidiron Hammer",
    "Scythe","Vampire Scythe","Happy's Scythe",
    "Revolver","Rifle","Tactical Shotgun","Snowball","Frozen Shuriken",
    "Impact Gernade","Impact Grenade","Kunai","Ray Gun","Laser Cannon",
    "Laser Shotgun","Flamethrower","Blowpipe","Admin Gun","Friendly Gun",
    "Wildfire","Infernal Crossbow","Witch Potion","Crossbow","potion","Potion",
    "Bouncing Blade","Air Rifle","Ice Bow",
    "Revolver Ammo","Rifle Ammo","Shotgun Ammo","Ghost Crossbow",
    "Leather Body","Poison Armour","Iron Body","Thorn Body",
    "Riot Shield","Alien Armour","Obsidiron Body","Vampire Cloak",
    "Crafting Blueprint","Defense Blueprint",
    "Bandage","Medkit",
}
local CHEST_LOOT_SET = {}
for _, v in ipairs(CHEST_LOOT_WHITELIST) do CHEST_LOOT_SET[v] = true end

local STACKABLE_BLUEPRINTS = { ["crafting blueprint"]=true,["defense blueprint"]=true }
local COIN_KEYS  = { "Coin" }
local AMMO_KEYS  = { "Ammo","Bullet","Shell","Arrow","Dart","Rocket","Cartridge" }
local IGNORE_LOOT_KEYS = {
    "Tree","Pine","Oak","Birch","Fir","Bush","Foliage",
    "Wall","Floor","Ground","Terrain","Campfire","MainFire",
    "Scrapper","Grinder","Recycler","Anvil",
    "Spawn","Part","Baseplate","Hitbox",
}
local YOUNG_TREE_KEYS = { "Sapling","Young","Small","Sprout","Growing","Baby","Seedling" }
local BIG_TREE_KEYS   = { "Big","Large","Giant","Huge","Ancient","Mega","Elder","Great" }
local TREE_KEYS       = { "Tree","Pine","Oak","Birch","Fir" }

--========================================================
-- CONFIG
--========================================================

local CFG = {
    Speed=false,            WalkSpeed=40,
    Jump=false,             JumpPower=90,
    Fly=false,              FlySpeed=60,
    Noclip=false,
    GodMode=false,          GodHeight=80,
    KillAura=false,         KillRadius=150,
    AutoChop=false,         ChopRadius=130,
    AutoDrop=false,
    AutoScrapper=false,
    AutoEat=false,
    AutoChestAndLoot=false,
    AutoCollectCoins=false,
    AutoRescueChild=false,
    ESPChild=false,
    Fullbright=false,
    FixLag=false,
    Delay=0.35,
}

local MAX_KILL   = 6
local TOOL_SFX   = "11960515286"
local CHILD_KEY  = "Lost Child"

--========================================================
-- HELPERS
--========================================================

local function hasKey(name, keys)
    if type(name)~="string" then return false end
    local n=string.lower(name)
    for _,k in ipairs(keys) do if string.find(n,string.lower(k),1,true) then return true end end
end
local function root() local c=Player.Character; return c and c:FindFirstChild("HumanoidRootPart") end
local function hum()  local c=Player.Character; return c and c:FindFirstChildOfClass("Humanoid") end
local function partOf(m)
    if not m then return nil end
    local ok,res=pcall(function()
        if m:IsA("BasePart") then return m end
        if m:IsA("Model") then
            if m.PrimaryPart then return m.PrimaryPart end
            local h=m:FindFirstChild("HumanoidRootPart"); if h then return h end
            return m:FindFirstChildWhichIsA("BasePart",true)
        end
    end)
    return ok and res or nil
end
local function findFromList(list,inv,char)
    for _,name in ipairs(list) do
        local t=(inv and inv:FindFirstChild(name)) or (char and char:FindFirstChild(name))
        if t then return t end
    end
end
local function getFallback(inv,char)
    if inv then local t=inv:FindFirstChildWhichIsA("Tool"); if t then return t end end
    return char and char:FindFirstChildWhichIsA("Tool")
end
local function getKillTool()
    local inv,char=Player:FindFirstChild("Inventory"),Player.Character
    return findFromList(MELEE_WEAPONS,inv,char) or findFromList(AXES,inv,char) or getFallback(inv,char)
end
local function getChopTool()
    local inv,char=Player:FindFirstChild("Inventory"),Player.Character
    local pri={"Admin Axe","Chainsaw","Strong Axe","Ice Axe","Good Axe","Old Axe"}
    return findFromList(pri,inv,char) or findFromList(AXES,inv,char) or getFallback(inv,char)
end
local function getSackTool()
    local inv,char=Player:FindFirstChild("Inventory"),Player.Character
    local t=findFromList(SACK_NAMES,inv,char); if t then return t end
    for _,src in ipairs({inv,char}) do
        if src then for _,item in ipairs(src:GetChildren()) do if hasKey(item.Name,{"Sack","Bag"}) then return item end end end
    end
end
local cachedFirePart=nil
local function getFirePart()
    if cachedFirePart and cachedFirePart.Parent then return cachedFirePart end
    local map=Workspace:FindFirstChild("Map"); local camp=map and map:FindFirstChild("Campground")
    local fire=camp and camp:FindFirstChild("MainFire",true)
    if fire then cachedFirePart=partOf(fire); if cachedFirePart then return cachedFirePart end end
    for _,o in ipairs(Workspace:GetDescendants()) do
        if o.Name=="MainFire" or o.Name=="Campfire" then local p=partOf(o); if p then cachedFirePart=p; return p end end
    end
end
local cachedScrapperPart=nil
local function getScrapperPart()
    if cachedScrapperPart and cachedScrapperPart.Parent then return cachedScrapperPart end
    for _,o in ipairs(Workspace:GetDescendants()) do
        local ok,n=pcall(function() return o.Name end)
        if ok and type(n)=="string" and hasKey(n,SCRAPPER_KEYS) then
            local p=partOf(o); if p then cachedScrapperPart=p; return p end
        end
    end
end
local function getNilByName(name)
    local out={}; if not getnilinstances then return out end
    local ok,list=pcall(getnilinstances); if not ok then return out end
    for _,obj in ipairs(list) do local ok2,n=pcall(function() return obj.Name end); if ok2 and n==name then table.insert(out,obj) end end
    return out
end
local function isStackableBP(name) return type(name)=="string" and STACKABLE_BLUEPRINTS[string.lower(name)]==true end

--========================================================
-- CHILD CACHE
--========================================================

local childSet={}
local function isChildModel(o) return o and o:IsA("Model") and string.find(o.Name,CHILD_KEY,1,true)~=nil end
local function initChildCache()
    local folders={Workspace}; local cf=Workspace:FindFirstChild("Characters"); if cf then table.insert(folders,cf) end
    for _,folder in ipairs(folders) do
        for _,o in ipairs(folder:GetChildren()) do if isChildModel(o) then childSet[o]=true end end
        folder.ChildAdded:Connect(function(o) if isChildModel(o) then childSet[o]=true end end)
        folder.ChildRemoved:Connect(function(o) childSet[o]=nil end)
    end
    task.spawn(function()
        local all=Workspace:GetDescendants()
        for i=1,#all do if isChildModel(all[i]) then childSet[all[i]]=true end; if i%800==0 then task.wait() end end
    end)
end
initChildCache()

--========================================================
-- AUTO RESCUE CHILDREN
--========================================================

local rescueStatusText="Chờ bật tự động cứu trẻ..."
local rescueStatusLbl=nil
local rescuedChildren=setmetatable({},{__mode="k"})
local rescuedChildKeys={}
local totalChildrenSaved=0

local function updateRescueStatus(txt)
    rescueStatusText=txt; if rescueStatusLbl and rescueStatusLbl.Parent then rescueStatusLbl.Text=txt end
end
local function getChildKey(c) if not c then return nil end; local ok,d=pcall(function() return c:GetDebugId() end); if ok and d then return d end; return tostring(c) end
local function isRescued(child)
    if not child then return true end; if rescuedChildren[child] then return true end
    local k=getChildKey(child); if k and rescuedChildKeys[k] then return true end
    local fp=getFirePart(); local cp=partOf(child)
    if fp and cp and (cp.Position-fp.Position).Magnitude<=22 then rescuedChildren[child]=true; if k then rescuedChildKeys[k]=true end; return true end
    return false
end
local function markRescued(child) if not child then return end; rescuedChildren[child]=true; local k=getChildKey(child); if k then rescuedChildKeys[k]=true end end
local function findInBag(childName)
    local bag=Player:FindFirstChild("ItemBag"); if not bag then return nil end
    return bag:FindFirstChild(childName) or bag:FindFirstChild(CHILD_KEY) or bag:FindFirstChildWhichIsA("Model")
end
local function rescueOne(child)
    if not child or not child.Parent then return false end
    if not (BagStoreRF and BagDropRE) then updateRescueStatus("❌ Thiếu remote BagStore/BagDrop"); return false end
    local sack=getSackTool(); if not sack then updateRescueStatus("❌ Không có túi"); return false end
    local fp=getFirePart(); if not fp then updateRescueStatus("❌ Không thấy lửa trại"); return false end
    local r=root(); local cp=partOf(child); if not (r and cp) then return false end
    local childName=child.Name
    updateRescueStatus("🏃 TP tới: "..childName)
    r.CFrame=CFrame.new(cp.Position+Vector3.new(0,3,2)); task.wait(0.25)
    if not CFG.AutoRescueChild then return false end
    updateRescueStatus("🎒 Cất balo: "..childName)
    pcall(BagStoreRF.InvokeServer,BagStoreRF,sack,findInBag(childName) or child); task.wait(0.25)
    if not CFG.AutoRescueChild then return false end
    r=root(); if r and fp and fp.Parent then r.CFrame=CFrame.new(fp.Position+Vector3.new(0,4,3)) end
    task.wait(0.25)
    local dropTarget=(child and child.Parent) and child or findInBag(childName)
    if dropTarget then pcall(BagDropRE.FireServer,BagDropRE,sack,dropTarget,true) end
    task.wait(0.2); markRescued(child); totalChildrenSaved+=1
    updateRescueStatus(string.format("✅ Đã cứu %s (Tổng: %d)",childName,totalChildrenSaved))
    return true
end
task.spawn(function()
    while true do
        if CFG.AutoRescueChild then
            local r=root(); local rPos=r and r.Position; local best,bestD=nil,math.huge
            for child,_ in pairs(childSet) do
                if child and child.Parent and not isRescued(child) then
                    local p=partOf(child); if p then local d=rPos and (p.Position-rPos).Magnitude or 0; if d<bestD then bestD=d; best=child end end
                end
            end
            if not best then updateRescueStatus(string.format("✅ Hết trẻ · Tổng: %d",totalChildrenSaved))
            else pcall(rescueOne,best) end
            task.wait(1)
        else task.wait(0.5) end
    end
end)

--========================================================
-- CHEST / COIN / AMMO CACHE
--========================================================

local chestLootStatusText="Chờ bật mở rương..."
local chestLootStatusLbl=nil
local coinStatusText="Chờ bật nhặt xu..."
local coinStatusLbl=nil

local cachedChests={}; local cachedAmmo={}; local cachedCoins={}
local openedChests=setmetatable({},{__mode="k"})
local lootedItems=setmetatable({},{__mode="k"})
local fireSentItems=setmetatable({},{__mode="k"})
local claimedAmmo=setmetatable({},{__mode="k"})

local totalChestsOpened=0; local totalItemsLooted=0
local totalSentToFire=0;   local totalAmmoCollected=0; local totalCollectedCoins=0

local STEP_WAIT=0.35
local function updateChestLootStatus(txt) chestLootStatusText=txt; if chestLootStatusLbl and chestLootStatusLbl.Parent then chestLootStatusLbl.Text=txt end end
local function updateCoinStatus(txt) coinStatusText=txt; if coinStatusLbl and coinStatusLbl.Parent then coinStatusLbl.Text=txt end end

local function isChestObj(o) return (o:IsA("Model") or o:IsA("BasePart")) and hasKey(o.Name,CHEST_KEYS) end
local function isAmmoObj(o)
    if not o then return false end; local ok,n=pcall(function() return o.Name end); if not ok or type(n)~="string" then return false end
    if hasKey(n,IGNORE_LOOT_KEYS) or hasKey(n,CHEST_KEYS) or hasKey(n,COIN_KEYS) then return false end
    return hasKey(n,AMMO_KEYS)
end
local function isCoinObj(o) if not o then return false end; local ok,n=pcall(function() return o.Name end); return ok and hasKey(n,COIN_KEYS) end

local itemsCacheInit=false
local function initItemsCache()
    if itemsCacheInit then return end; itemsCacheInit=true
    local iF=Workspace:FindFirstChild("Items"); local root_=iF or Workspace
    task.spawn(function()
        local all=root_:GetDescendants()
        for i=1,#all do
            local o=all[i]
            if isChestObj(o) then cachedChests[o]=true
            elseif isAmmoObj(o) then cachedAmmo[o]=true
            elseif isCoinObj(o) then cachedCoins[o]=true end
            if i%600==0 then task.wait() end
        end
    end)
    root_.DescendantAdded:Connect(function(o)
        if isChestObj(o) then cachedChests[o]=true
        elseif isAmmoObj(o) then cachedAmmo[o]=true
        elseif isCoinObj(o) then cachedCoins[o]=true end
    end)
    root_.DescendantRemoving:Connect(function(o)
        cachedChests[o]=nil; cachedAmmo[o]=nil; cachedCoins[o]=nil
    end)
end

local coinCacheInit=false
local function initCoinCache()
    if coinCacheInit then return end; coinCacheInit=true
    local iF=Workspace:FindFirstChild("Items"); local root_=iF or Workspace
    task.spawn(function()
        local all=root_:GetDescendants()
        for i=1,#all do if isCoinObj(all[i]) then cachedCoins[all[i]]=true end; if i%800==0 then task.wait() end end
    end)
    root_.DescendantAdded:Connect(function(o) if isCoinObj(o) then cachedCoins[o]=true end end)
    root_.DescendantRemoving:Connect(function(o) cachedCoins[o]=nil end)
end

local function collectAmmoBatch()
    if not ConsumeRF then return 0 end
    local got=0
    for a,_ in pairs(cachedAmmo) do
        if not CFG.AutoChestAndLoot or got>=8 then break end
        if a and a.Parent and not claimedAmmo[a] then
            if pcall(ConsumeRF.InvokeServer,ConsumeRF,a) then claimedAmmo[a]=true; cachedAmmo[a]=nil; got+=1; totalAmmoCollected+=1 end
        else cachedAmmo[a]=nil end
    end
    return got
end

local overlapParams=OverlapParams.new(); overlapParams.FilterType=Enum.RaycastFilterType.Exclude
local function getChestBounds(chest)
    local ok,cf,sz=pcall(function()
        if chest:IsA("Model") then return chest:GetBoundingBox()
        elseif chest:IsA("BasePart") then return chest.CFrame,chest.Size end
    end)
    if ok and cf and sz then
        local iSz=Vector3.new(math.max(math.min(sz.X,6.5),1.5),math.max(math.min(sz.Y+2.2,6.5),2),math.max(math.min(sz.Z,6.5),1.5))
        return cf*CFrame.new(0,math.clamp(sz.Y*0.25,0.2,1.2),0),iSz
    end
    local p=partOf(chest); if p then return p.CFrame*CFrame.new(0,1,0),Vector3.new(4.5,4,4.5) end
end
local function scanLootInChest(chest)
    local cf,sz=getChestBounds(chest); if not (cf and sz) then return {} end
    local ex={chest}; if Player.Character then table.insert(ex,Player.Character) end
    overlapParams.FilterDescendantsInstances=ex
    local parts=Workspace:GetPartBoundsInBox(cf,sz,overlapParams)
    local out,seen={},{}
    for _,part in ipairs(parts) do
        local c=part:FindFirstAncestorOfClass("Tool") or part:FindFirstAncestorOfClass("Model") or part
        if c and not seen[c] and not fireSentItems[c] and not lootedItems[c] then
            seen[c]=true
            if c~=chest and not c:IsDescendantOf(chest) then
                local ok,n=pcall(function() return c.Name end)
                if ok and CHEST_LOOT_SET[n] then table.insert(out,c) end
            end
        end
    end
    return out
end
local function tryTakeItem(item)
    if not HotbarItemRF or not item or not item.Parent then return false end
    local inv=Player:FindFirstChild("Inventory"); local bag=Player:FindFirstChild("ItemBag")
    local b1=inv and #inv:GetChildren() or 0; local b2=bag and #bag:GetChildren() or 0
    local ok=pcall(HotbarItemRF.InvokeServer,HotbarItemRF,item); if not ok then return false end
    local a1=inv and #inv:GetChildren() or 0; local a2=bag and #bag:GetChildren() or 0
    return (inv and item.Parent==inv) or (bag and item.Parent==bag) or (item.Parent==Player.Character) or a1>b1 or a2>b2 or not item.Parent
end
local function tpItemToFire(item,idx)
    if not item or not item.Parent or fireSentItems[item] then return false end
    local fp=getFirePart(); if not fp then return false end
    local spread=Vector3.new(math.random(-25,25)/10,10+((idx or 1)%6)*0.6,math.random(-25,25)/10)
    local ok=pcall(function()
        if DragRE then pcall(DragRE.FireServer,DragRE,item) end
        if item:IsA("Model") then item:PivotTo(CFrame.new(fp.Position+spread))
        elseif item:IsA("BasePart") then item.CFrame=CFrame.new(fp.Position+spread) end
        if StopDragRE then pcall(StopDragRE.FireServer,StopDragRE,item) end
    end)
    if ok then fireSentItems[item]=true; totalSentToFire+=1 end
    return ok
end

local function processChest()
    if not OpenChestRE then updateChestLootStatus("❌ Thiếu remote OpenChest"); return end
    initItemsCache()
    local target=nil; local r=root(); local rPos=r and r.Position; local best=math.huge
    for c,_ in pairs(cachedChests) do
        if c and c.Parent then
            local p=partOf(c); if p then
                local d=rPos and (p.Position-rPos).Magnitude or 0
                local pen=openedChests[c] and 5000 or 0
                if d+pen<best then best=d+pen; target=c end
            end
        else cachedChests[c]=nil end
    end
    if not target then
        local ag=collectAmmoBatch()
        updateChestLootStatus(string.format("✅ Hết rương · Nhặt:%d →Lửa:%d Đạn:%d(+%d)",totalItemsLooted,totalSentToFire,totalAmmoCollected,ag))
        return
    end
    if not openedChests[target] then
        pcall(OpenChestRE.FireServer,OpenChestRE,target); openedChests[target]=true; totalChestsOpened+=1
    end
    local items=scanLootInChest(target)
    local bagNameSet={}
    for _,cont in ipairs({Player:FindFirstChild("Inventory"),Player:FindFirstChild("ItemBag"),Player.Character}) do
        if cont then for _,o in ipairs(cont:GetChildren()) do local ok,n=pcall(function() return o.Name end); if ok then bagNameSet[string.lower(n)]=true end end end
    end
    local got,toFire=0,0
    for idx,item in ipairs(items) do
        if not CFG.AutoChestAndLoot then break end
        if not item or not item.Parent or fireSentItems[item] then continue end
        local ok2,n=pcall(function() return item.Name end)
        local alreadyHave = ok2 and not isStackableBP(n) and bagNameSet[string.lower(n)]
        if alreadyHave then
            if tpItemToFire(item,idx) then toFire+=1 end
        else
            if tryTakeItem(item) then
                lootedItems[item]=true; got+=1; totalItemsLooted+=1
                if ok2 and not isStackableBP(n) then bagNameSet[string.lower(n)]=true end
            else
                if tpItemToFire(item,idx) then toFire+=1 end
            end
        end
    end
    local ag=collectAmmoBatch()
    updateChestLootStatus(string.format("📦 #%d +%d nhặt +%d→Lửa +%d đạn · R:%d Đ:%d",totalChestsOpened,got,toFire,ag,totalChestsOpened,totalItemsLooted))
end
task.spawn(function() while true do if CFG.AutoChestAndLoot then pcall(processChest); task.wait(STEP_WAIT) else task.wait(0.4) end end end)

local function collectCoins()
    if not CollectCoinRF then updateCoinStatus("❌ Thiếu remote"); return 0 end
    initCoinCache()
    local list={}
    for c,_ in pairs(cachedCoins) do if c and c.Parent then table.insert(list,c) else cachedCoins[c]=nil end end
    if #list==0 then updateCoinStatus("⚠️ Chưa thấy xu (Tổng:"..totalCollectedCoins..")"); return 0 end
    local got=0
    for _,coin in ipairs(list) do
        if not CFG.AutoCollectCoins then break end
        if pcall(CollectCoinRF.InvokeServer,CollectCoinRF,coin) then cachedCoins[coin]=nil; got+=1; totalCollectedCoins+=1 end
        task.wait(0.05)
    end
    updateCoinStatus(string.format("🪙 +%d xu (Tổng:%d)",got,totalCollectedCoins)); return got
end
task.spawn(function() while true do task.wait(1.2); if CFG.AutoCollectCoins then pcall(collectCoins) end end end)

--========================================================
-- COUNTER & COMBAT
--========================================================

local hitCounter=0
local function resetCounter() hitCounter=0 end
Workspace.ChildAdded:Connect(function(c) if c.Name=="Map" then resetCounter(); cachedFirePart=nil; cachedScrapperPart=nil end end)
Workspace.ChildRemoved:Connect(function(c) if c.Name=="Map" then resetCounter(); cachedFirePart=nil; cachedScrapperPart=nil end end)
local function nextId() hitCounter+=1; return hitCounter.."_"..TOOL_SFX end

local function hitOnce(tool, target, p)
    if not DamageRF or not target or not target.Parent or not p or not p.Parent then return false end
    -- Thứ tự từ capture: WoodChop → ToolDamageObject → HitSound
    if WoodChopSoundRE then
        local char=Player.Character; local head=char and char:FindFirstChild("Head")
        if head then pcall(WoodChopSoundRE.FireServer,WoodChopSoundRE,"FireAllClients","WoodChop",{Instance=head,Volume=0.4}) end
    end
    local ok=pcall(DamageRF.InvokeServer,DamageRF,target,tool,nextId(),CFrame.new(p.Position),false)
    if HitSoundRE then pcall(HitSoundRE.FireServer,HitSoundRE,"FireAllClients",target,tool) end
    return ok==true
end

local function equipSafe(tool) if EquipRE and tool then pcall(EquipRE.FireServer,EquipRE,"FireAllClients",tool); task.wait(0.03) end end
local function unequipSafe(tool) if UnequipRE and tool then pcall(UnequipRE.FireServer,UnequipRE,"FireAllClients",tool); task.wait(0.025) end end

local function swingBatch(tool,targets)
    if not (EquipRE and UnequipRE and DamageRF) or #targets==0 then return end
    equipSafe(tool)
    for i=1,math.min(#targets,MAX_KILL) do
        if not CFG.KillAura then break end
        local t=targets[i]
        if t.m and t.m.Parent and t.p and t.p.Parent then
            local h=t.m:FindFirstChildWhichIsA("Humanoid",true); if h and h.Health>0 then hitOnce(tool,t.m,t.p) end
        end
        if i<MAX_KILL then task.wait(0.05) end
    end
    unequipSafe(tool)
end

local SCAN_FOLDERS={"Characters","Enemies","Mobs","NPCs"}
local function getAnimals(r)
    local out,ch,seen={},Player.Character,{}
    local maxDSq=CFG.KillRadius*CFG.KillRadius; local rPos=r.Position
    local function try(o)
        if seen[o] or o==ch or childSet[o] then return end; seen[o]=true
        if Players:GetPlayerFromCharacter(o) then return end
        if string.find(o.Name,CHILD_KEY,1,true) then return end
        local h=o:FindFirstChildWhichIsA("Humanoid",true); if not (h and h.Health>0) then return end
        local p=partOf(o); if not p then return end
        local d=p.Position-rPos; local dSq=d.X*d.X+d.Y*d.Y+d.Z*d.Z
        if dSq<=maxDSq then table.insert(out,{m=o,p=p,dSq=dSq}) end
    end
    for _,o in ipairs(Workspace:GetChildren()) do if o:IsA("Model") then try(o) end end
    for _,fn in ipairs(SCAN_FOLDERS) do local f=Workspace:FindFirstChild(fn); if f then for _,o in ipairs(f:GetChildren()) do if o:IsA("Model") then try(o) end end end end
    table.sort(out,function(a,b) return a.dSq<b.dSq end); return out
end

task.spawn(function()
    while true do
        if CFG.KillAura then
            local r,tool=root(),getKillTool()
            if r and tool then local t=getAnimals(r); if #t>0 then pcall(swingBatch,tool,t) end end
            task.wait(CFG.Delay)
        else task.wait(0.25) end
    end
end)

--========================================================
-- TP AUTO CHOP
--========================================================

local skipTree={}
local function isTreeBroken(m,p)
    if not m or not m.Parent then return true end; if not p or not p.Parent then return true end
    local hp=m:GetAttribute("Health") or m:GetAttribute("HP")
    if type(hp)=="number" and hp<=0 then return true end
    local h=m:FindFirstChildWhichIsA("Humanoid",true); if h and h.Health<=0 then return true end
    if p:IsA("BasePart") and not p.Anchored then return true end
    return false
end
local function classifyTree(m)
    if not m or not m.Parent or not m:IsA("Model") then return nil end
    if not hasKey(m.Name,TREE_KEYS) then return nil end
    if hasKey(m.Name,YOUNG_TREE_KEYS) then return "young" end
    local p=partOf(m); if not p or isTreeBroken(m,p) then return nil end
    local ok,sz=pcall(function() local _,s=m:GetBoundingBox(); return s end)
    if ok and sz then if sz.Y<9 then return "young" end; if sz.Y>=32 or math.max(sz.X,sz.Z)>=18 then return "big" end end
    if hasKey(m.Name,BIG_TREE_KEYS) then return "big" end
    return "normal"
end
local function getTrees(r,maxR,tool)
    local out={}; local lim=type(maxR)=="number" and maxR>0; local maxDSq=lim and maxR*maxR or math.huge
    local rPos=r.Position; local now=os.clock()
    local allowBig=tool and HEAVY_AXES[tool.Name]==true
    local function tryAdd(t)
        if skipTree[t] and now<skipTree[t] then return end
        local tt=classifyTree(t); if not tt or tt=="young" then return end
        if tt=="big" and not allowBig then return end
        local p=partOf(t); if not p then return end
        local d=p.Position-rPos; local dSq=d.X*d.X+d.Y*d.Y+d.Z*d.Z
        if dSq<=maxDSq then table.insert(out,{m=t,p=p,dSq=dSq}) end
    end
    local map=Workspace:FindFirstChild("Map")
    for _,f in ipairs({map and map:FindFirstChild("Foliage"),map and map:FindFirstChild("Trees"),Workspace:FindFirstChild("Foliage"),Workspace:FindFirstChild("Trees")}) do
        if f then for _,t in ipairs(f:GetChildren()) do tryAdd(t) end end
    end
    if #out==0 then for _,o in ipairs((map or Workspace):GetDescendants()) do if o:IsA("Model") then tryAdd(o) end end end
    table.sort(out,function(a,b) return a.dSq<b.dSq end); return out
end
local function tpChop(m,p,tool)
    local r=root(); if not (r and m and m.Parent and p and p.Parent) then return false end
    local pos=p.Position; r.CFrame=CFrame.new(pos+Vector3.new(0,3,-3.5),pos); task.wait(0.1)
    equipSafe(tool); local swings,maxSw,fails=0,35,0
    while CFG.AutoChop and not isTreeBroken(m,p) and swings<maxSw do
        local rr=root(); local ct=getChopTool(); if not (rr and ct) then break end
        local cp=p.Position
        if (rr.Position-cp).Magnitude>12 then rr.CFrame=CFrame.new(cp+Vector3.new(0,3,-3.5),cp) end
        if hitOnce(ct,m,p) then fails=0 else fails+=1; if fails>=5 then break end end
        swings+=1; task.wait(math.max(CFG.Delay,0.12))
    end
    unequipSafe(tool); return isTreeBroken(m,p)
end
task.spawn(function()
    while true do
        if CFG.AutoChop then
            local r,tool=root(),getChopTool()
            if r and tool then
                local trees=getTrees(r,CFG.ChopRadius,tool)
                if #trees==0 then trees=getTrees(r,nil,tool) end
                if #trees>0 then
                    local c=trees[1]; local broken=false
                    pcall(function() broken=tpChop(c.m,c.p,tool) end)
                    skipTree[c.m]=os.clock()+(broken and 60 or 5)
                end
            end
            task.wait(0.15)
        else task.wait(0.25) end
    end
end)

--========================================================
-- MOVEMENT, NOCLIP, FLY
--========================================================

local noclipBak={}
local function restoreNoclip()
    for p,v in pairs(noclipBak) do if p and p.Parent and p:IsA("BasePart") then pcall(function() p.CanCollide=v end) end end
    noclipBak={}
end
RunService.Heartbeat:Connect(function()
    local h=hum(); if not h then return end
    if CFG.Speed then h.WalkSpeed=CFG.WalkSpeed end
    if CFG.Jump  then h.UseJumpPower=true; h.JumpPower=CFG.JumpPower end
end)
RunService.Stepped:Connect(function()
    local c=Player.Character; if not c then return end
    if CFG.Noclip then
        for _,o in ipairs(c:GetDescendants()) do
            if o:IsA("BasePart") then
                if noclipBak[o]==nil then noclipBak[o]=o.CanCollide end
                if o.CanCollide then o.CanCollide=false end
            end
        end
    elseif next(noclipBak) then restoreNoclip() end
end)

local flyBV,flyBG,flyConn; local padUp,padDown=false,false
local function stopFly()
    if flyConn then flyConn:Disconnect(); flyConn=nil end
    if flyBV and flyBV.Parent then flyBV:Destroy() end
    if flyBG and flyBG.Parent then flyBG:Destroy() end
    flyBV,flyBG=nil,nil; local h=hum(); if h then h.PlatformStand=false end
end
local function startFly()
    stopFly(); local r,h=root(),hum(); if not (r and h) then return end
    h.PlatformStand=true
    flyBV=Instance.new("BodyVelocity"); flyBV.MaxForce=Vector3.new(1e6,1e6,1e6); flyBV.Velocity=Vector3.zero; flyBV.Parent=r
    flyBG=Instance.new("BodyGyro"); flyBG.MaxTorque=Vector3.new(1e6,1e6,1e6); flyBG.P=1e4; flyBG.Parent=r
    flyConn=RunService.Heartbeat:Connect(function()
        local cam=Workspace.CurrentCamera; local rr,hh=root(),hum()
        if not (cam and rr and hh and flyBV and flyBV.Parent) then return end
        local md=hh.MoveDirection
        local fl=Vector3.new(cam.CFrame.LookVector.X,0,cam.CFrame.LookVector.Z)
        local fr=Vector3.new(cam.CFrame.RightVector.X,0,cam.CFrame.RightVector.Z)
        if fl.Magnitude>0 then fl=fl.Unit end; if fr.Magnitude>0 then fr=fr.Unit end
        local vy=0
        if UIS:IsKeyDown(Enum.KeyCode.Space) or padUp    then vy= 1 end
        if UIS:IsKeyDown(Enum.KeyCode.LeftControl) or padDown then vy=-1 end
        flyBV.Velocity=(fl*(-md.Z)+fr*md.X)*CFG.FlySpeed+Vector3.new(0,vy*CFG.FlySpeed,0)
        flyBG.CFrame=CFrame.new(rr.Position,rr.Position+fl)
    end)
end

--========================================================
-- GOD MODE — BAY CAO TRÁNH SÁT THƯƠNG
--========================================================

local godBV,godBG,godConn
local function stopGodMode()
    CFG.GodMode=false
    if godConn then godConn:Disconnect(); godConn=nil end
    if godBV and godBV.Parent then godBV:Destroy() end
    if godBG and godBG.Parent then godBG:Destroy() end
    godBV,godBG=nil,nil
    local h=hum(); if h then h.PlatformStand=false; h.AutoRotate=true end
end
local function startGodMode()
    stopGodMode(); CFG.GodMode=true
    local r,h=root(),hum(); if not (r and h) then return end
    h.PlatformStand=true; h.AutoRotate=false
    godBV=Instance.new("BodyVelocity"); godBV.MaxForce=Vector3.new(1e6,1e6,1e6); godBV.Velocity=Vector3.zero; godBV.Parent=r
    godBG=Instance.new("BodyGyro"); godBG.MaxTorque=Vector3.new(1e6,1e6,1e6); godBG.P=1e4; godBG.CFrame=CFrame.new(r.Position); godBG.Parent=r
    -- Đưa lên cao ngay
    r.CFrame=CFrame.new(r.Position+Vector3.new(0,CFG.GodHeight,0))
    godConn=RunService.Heartbeat:Connect(function()
        local rr,hh=root(),hum()
        if not (rr and hh and godBV and godBV.Parent) then stopGodMode(); return end
        if not CFG.GodMode then stopGodMode(); return end
        -- Tính mặt đất thực bằng Raycast
        local rp=RaycastParams.new(); rp.FilterDescendantsInstances={Player.Character}; rp.FilterType=Enum.RaycastFilterType.Exclude
        local ray=Workspace:Raycast(rr.Position,Vector3.new(0,-500,0),rp)
        local groundY=ray and ray.Position.Y or 0
        local targetY=groundY+CFG.GodHeight
        local currentY=rr.Position.Y
        -- Điều khiển di chuyển ngang
        local cam=Workspace.CurrentCamera; local hh2=hum()
        local md=hh2 and hh2.MoveDirection or Vector3.zero
        local fl=Vector3.new(cam.CFrame.LookVector.X,0,cam.CFrame.LookVector.Z)
        local fr=Vector3.new(cam.CFrame.RightVector.X,0,cam.CFrame.RightVector.Z)
        if fl.Magnitude>0 then fl=fl.Unit end; if fr.Magnitude>0 then fr=fr.Unit end
        local horizontal=(fl*(-md.Z)+fr*md.X)*CFG.WalkSpeed
        -- Điều khiển độ cao
        local vy=0
        if currentY<targetY-3 then vy=80
        elseif currentY>targetY+3 then vy=-30
        else vy=0 end
        godBV.Velocity=Vector3.new(horizontal.X,vy,horizontal.Z)
        godBG.CFrame=CFrame.new(rr.Position)
        -- Liên tục hồi HP về max
        if hh.Health<hh.MaxHealth then
            pcall(function() hh.Health=hh.MaxHealth end)
        end
    end)
end

--========================================================
-- FULLBRIGHT & FIX LAG
--========================================================

local fbPrev,fbConn
local function applyFB() Lighting.Brightness=3; Lighting.ClockTime=12; Lighting.FogEnd=1e6; Lighting.Ambient=Color3.fromRGB(180,180,180); Lighting.OutdoorAmbient=Color3.fromRGB(180,180,180) end
local function setFB(on)
    if on then
        if not fbPrev then fbPrev={B=Lighting.Brightness,C=Lighting.ClockTime,F=Lighting.FogEnd,A=Lighting.Ambient,OA=Lighting.OutdoorAmbient} end
        applyFB(); if not fbConn then fbConn=RunService.Heartbeat:Connect(function() if CFG.Fullbright then applyFB() end end) end
    else
        if fbConn then fbConn:Disconnect(); fbConn=nil end
        if fbPrev then Lighting.Brightness=fbPrev.B; Lighting.ClockTime=fbPrev.C; Lighting.FogEnd=fbPrev.F; Lighting.Ambient=fbPrev.A; Lighting.OutdoorAmbient=fbPrev.OA; fbPrev=nil end
    end
end

local LagBak={}; local lagConn,lagGen=nil,0
local HM={[Enum.Material.Neon]=Enum.Material.SmoothPlastic,[Enum.Material.Glass]=Enum.Material.SmoothPlastic,[Enum.Material.ForceField]=Enum.Material.SmoothPlastic,[Enum.Material.DiamondPlate]=Enum.Material.SmoothPlastic,[Enum.Material.CorrodedMetal]=Enum.Material.SmoothPlastic,[Enum.Material.Foil]=Enum.Material.SmoothPlastic,[Enum.Material.WoodPlanks]=Enum.Material.SmoothPlastic,[Enum.Material.Cobblestone]=Enum.Material.SmoothPlastic}
local function sp(o,p) local t=LagBak[o]; if not t then t={}; LagBak[o]=t end; if t[p]==nil then local ok,v=pcall(function() return o[p] end); if ok then t[p]=v end end end
local function optObj(o)
    if not CFG.FixLag or not o or not o.Parent then return end
    if o:IsA("ParticleEmitter") or o:IsA("Trail") or o:IsA("Beam") or o:IsA("Smoke") or o:IsA("Fire") or o:IsA("Sparkles") or o:IsA("PointLight") or o:IsA("SpotLight") or o:IsA("SurfaceLight") then
        sp(o,"Enabled"); pcall(function() o.Enabled=false end); return end
    if o:IsA("BasePart") then sp(o,"CastShadow"); pcall(function() o.CastShadow=false end); sp(o,"Material"); local m=HM[o.Material] or Enum.Material.Plastic; if o.Material~=m then pcall(function() o.Material=m end) end end
end
local function setFixLag(v)
    if v then
        if CFG.FixLag then return end; CFG.FixLag=true; lagGen+=1; local gen=lagGen
        for _,p in ipairs({"GlobalShadows","EnvironmentDiffuseScale","EnvironmentSpecularScale","ShadowSoftness"}) do sp(Lighting,p) end
        pcall(function() Lighting.GlobalShadows=false; Lighting.EnvironmentDiffuseScale=0; Lighting.EnvironmentSpecularScale=0; Lighting.ShadowSoftness=0 end)
        if not lagConn then lagConn=Workspace.DescendantAdded:Connect(function(o) if CFG.FixLag then task.defer(optObj,o) end end) end
        task.spawn(function() local all=Workspace:GetDescendants(); for i=1,#all do if not CFG.FixLag or gen~=lagGen then return end; optObj(all[i]); if i%500==0 then task.wait() end end end)
    else
        if not CFG.FixLag then return end; CFG.FixLag=false; lagGen+=1
        if lagConn then lagConn:Disconnect(); lagConn=nil end
        for o,props in pairs(LagBak) do if o and o.Parent then for p,val in pairs(props) do pcall(function() o[p]=val end) end end end
        LagBak={}
    end
end

--========================================================
-- AUTO EAT & ESP TRẺ
--========================================================

local eatStatusText="Chờ bật ăn carrot..."
local eatStatusLbl=nil
local function updateEatStatus(txt) eatStatusText=txt; if eatStatusLbl and eatStatusLbl.Parent then eatStatusLbl.Text=txt end end
task.spawn(function()
    while true do
        task.wait(2)
        if CFG.AutoEat then
            if not ConsumeRF then updateEatStatus("❌ Thiếu remote"); continue end
            if not getnilinstances then updateEatStatus("❌ Executor thiếu getnilinstances"); continue end
            local carrots=getNilByName("Carrot")
            if #carrots==0 then updateEatStatus("⚠️ Không có Carrot"); continue end
            local ate=0
            for _,c in ipairs(carrots) do
                if not CFG.AutoEat then break end
                if pcall(ConsumeRF.InvokeServer,ConsumeRF,c) then ate+=1; updateEatStatus("✅ Đã ăn "..ate.." carrot") end
                task.wait(0.3)
            end
        end
    end
end)

local espTag={}
local function clearESP()
    for _,pair in pairs(espTag) do
        if pair.hl and pair.hl.Parent then pair.hl:Destroy() end
        if pair.bb and pair.bb.Parent then pair.bb:Destroy() end
        if pair.conn then pair.conn:Disconnect() end
    end
    espTag={}
end
task.spawn(function()
    while true do
        task.wait(0.6)
        if CFG.ESPChild then
            for m,pair in pairs(espTag) do
                if not m.Parent then
                    if pair.hl and pair.hl.Parent then pair.hl:Destroy() end
                    if pair.bb and pair.bb.Parent then pair.bb:Destroy() end
                    if pair.conn then pair.conn:Disconnect() end
                    espTag[m]=nil
                end
            end
            for m,_ in pairs(childSet) do
                if m.Parent and not espTag[m] then
                    local saved=isRescued(m); local col=saved and Color3.fromRGB(100,255,130) or Color3.fromRGB(255,220,80)
                    local hl=Instance.new("Highlight"); hl.FillColor=col; hl.OutlineColor=col; hl.FillTransparency=0.45; hl.Adornee=m; hl.Parent=m
                    local ap=partOf(m); local bb,lc
                    if ap then
                        bb=Instance.new("BillboardGui"); bb.Adornee=ap; bb.Size=UDim2.new(0,170,0,46); bb.StudsOffset=Vector3.new(0,3,0); bb.AlwaysOnTop=true; bb.Parent=ap
                        local lbl=Instance.new("TextLabel"); lbl.Size=UDim2.new(1,0,1,0); lbl.BackgroundTransparency=1; lbl.TextColor3=col; lbl.TextStrokeColor3=Color3.new(0,0,0); lbl.TextStrokeTransparency=0.3; lbl.Font=Enum.Font.GothamBold; lbl.TextSize=13; lbl.Parent=bb
                        lc=RunService.Heartbeat:Connect(function()
                            if not m.Parent or not CFG.ESPChild then lc:Disconnect(); return end
                            local rr=root(); local pp=partOf(m)
                            local tag=isRescued(m) and " [Đã cứu]" or ""
                            lbl.Text=m.Name..tag..(rr and pp and "\n📍 "..math.floor((pp.Position-rr.Position).Magnitude).." studs" or "")
                        end)
                    end
                    espTag[m]={hl=hl,bb=bb,conn=lc}
                end
            end
        else if next(espTag) then clearESP() end end
    end
end)

--========================================================
-- TP, PULL, DUMP FUEL
--========================================================

local function tpTo(m) local r,p=root(),partOf(m); if r and p then r.CFrame=CFrame.new(p.Position+Vector3.new(0,4,0)) end end
local function tpFire() local fp=getFirePart(); local r=root(); if fp and r then r.CFrame=CFrame.new(fp.Position+Vector3.new(0,4,0)) end end
local function tpScrapper_() local sp=getScrapperPart(); local r=root(); if sp and r then r.CFrame=CFrame.new(sp.Position+Vector3.new(0,4,0)) end end
local function pullPlayer(plr)
    if not plr or plr==Player then return end
    local r=root(); local tr=plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
    if r and tr then tr.CFrame=r.CFrame*CFrame.new(0,1,-4) end
end
local function pullExact(nameList)
    local r=root(); if not r then return 0 end
    local ch=Player.Character; local found={}
    local iF=Workspace:FindFirstChild("Items"); local src=iF and iF:GetChildren() or Workspace:GetChildren()
    for _,o in ipairs(src) do
        if ch and o:IsDescendantOf(ch) then continue end
        if Players:GetPlayerFromCharacter(o) then continue end
        local ok,n=pcall(function() return o.Name end)
        if ok and (o:IsA("Model") or o:IsA("BasePart")) then
            for _,v in ipairs(nameList) do
                if n==v then local p=partOf(o); if p then table.insert(found,{obj=o,dist=(p.Position-r.Position).Magnitude}) end; break end
            end
        end
    end
    table.sort(found,function(a,b) return a.dist<b.dist end)
    local count=0
    for i=1,math.min(#found,20) do
        if not (DragRE and StopDragRE) then break end
        local o=found[i].obj; local rr=root(); if not rr then break end
        local sx=((count%3)-1)*1.4; local ly=1.2+math.floor(count/3)*0.6
        local gcf=rr.CFrame*CFrame.new(sx,ly,-3)
        pcall(function()
            if DragRE then pcall(DragRE.FireServer,DragRE,o) end
            if o:IsA("Model") then o:PivotTo(gcf) elseif o:IsA("BasePart") then o.CFrame=gcf end
            if StopDragRE then pcall(StopDragRE.FireServer,StopDragRE,o) end
        end)
        count+=1; task.wait(0.08)
    end
    return count
end

-- Fuel dump
local fireStatusText="Chờ bật auto dồn lửa trại..."
local fireStatusLbl=nil
local isDumpingFuel=false; local totalFuelMoved=0
local function updateFireStatus(txt) fireStatusText=txt; if fireStatusLbl and fireStatusLbl.Parent then fireStatusLbl.Text=txt end end
local function dumpFuel()
    if isDumpingFuel then return 0 end; isDumpingFuel=true
    local ok,moved=pcall(function()
        local fp=getFirePart(); if not fp or not fp.Parent then updateFireStatus("❌ Không thấy lửa trại"); return 0 end
        local ch=Player.Character; local iF=Workspace:FindFirstChild("Items")
        local src=iF and iF:GetChildren() or Workspace:GetChildren(); local count=0
        for _,o in ipairs(src) do
            if not CFG.AutoDrop then break end
            if not (o and o.Parent and (o:IsA("Model") or o:IsA("BasePart"))) then continue end
            if ch and o:IsDescendantOf(ch) then continue end
            if Players:GetPlayerFromCharacter(o) then continue end
            local mapF=Workspace:FindFirstChild("Map"); if mapF and o:IsDescendantOf(mapF) then continue end
            local ok2,n=pcall(function() return o.Name end)
            if ok2 and FUEL_EXACT_SET[n] then
                local p=partOf(o)
                if p and (p.Position-fp.Position).Magnitude>14 then
                    local dropPos=fp.Position+Vector3.new(math.random(-20,20)/10,9+(count%5)*0.6,math.random(-20,20)/10)
                    pcall(function()
                        if DragRE then pcall(DragRE.FireServer,DragRE,o) end
                        if o:IsA("Model") then o:PivotTo(CFrame.new(dropPos)) elseif o:IsA("BasePart") then o.CFrame=CFrame.new(dropPos) end
                        if StopDragRE then pcall(StopDragRE.FireServer,StopDragRE,o) end
                    end)
                    count+=1; totalFuelMoved+=1
                    updateFireStatus(string.format("🔥 %s → Lửa (Tổng:%d)",n,totalFuelMoved))
                    task.wait(0.05)
                end
            end
        end
        if count==0 then updateFireStatus(string.format("🔥 Đang quét · Tổng:%d",totalFuelMoved)) end
        return count
    end)
    isDumpingFuel=false
    if not ok then cachedFirePart=nil; updateFireStatus("⚠️ Làm mới lửa trại..."); return 0 end
    return moved or 0
end
task.spawn(function() while true do if CFG.AutoDrop then pcall(dumpFuel); task.wait(0.1) else task.wait(0.3) end end end)

--========================================================
-- SCRAPPER — FIX TRIỆT ĐỂ
-- Check tên trước, double-check trước khi drag
--========================================================

local scrapStatusText="Chờ bật auto Scrapper..."
local scrapStatusLbl=nil
local isMovingScrap=false; local totalScrapMoved=0
local function updateScrapStatus(txt) scrapStatusText=txt; if scrapStatusLbl and scrapStatusLbl.Parent then scrapStatusLbl.Text=txt end end

local function isValidScrapItem(obj)
    if not obj then return false end
    local okA=pcall(function() return obj.Parent end); if not okA or not obj.Parent then return false end
    if not (obj:IsA("Model") or obj:IsA("BasePart")) then return false end
    -- Tên phải khớp chính xác trong SCRAP_EXACT_SET
    local okN,name=pcall(function() return obj.Name end)
    if not okN or type(name)~="string" then return false end
    if not SCRAP_EXACT_SET[name] then return false end
    -- Không trong Map
    local mapF=Workspace:FindFirstChild("Map"); if mapF and obj:IsDescendantOf(mapF) then return false end
    -- Không phải nhân vật/người chơi
    local ch=Player.Character; if ch and obj:IsDescendantOf(ch) then return false end
    if Players:GetPlayerFromCharacter(obj) then return false end
    -- BasePart: không anchored, không quá lớn
    if obj:IsA("BasePart") then
        if obj.Anchored then return false end
        local sz=obj.Size; if sz.X>5 or sz.Y>5 or sz.Z>5 then return false end
    end
    -- Model: không quá lớn
    if obj:IsA("Model") then
        local ok2,sz=pcall(function() local _,s=obj:GetBoundingBox(); return s end)
        if ok2 and sz and (sz.X>7 or sz.Y>7 or sz.Z>7) then return false end
        if not partOf(obj) then return false end
    end
    return true
end

local function moveScrapItem(obj, goalCF)
    -- Double-check ngay trước khi drag
    if not isValidScrapItem(obj) then return false end
    local ok=pcall(function()
        if DragRE then pcall(DragRE.FireServer,DragRE,obj) end
        if obj:IsA("Model") then obj:PivotTo(goalCF)
        elseif obj:IsA("BasePart") then obj.CFrame=goalCF end
    end)
    if StopDragRE then pcall(StopDragRE.FireServer,StopDragRE,obj) end
    return ok==true
end

local function sendScrapToScrapper()
    if isMovingScrap then return 0 end; isMovingScrap=true
    local ok,moved=pcall(function()
        local sp=getScrapperPart()
        if not sp or not sp.Parent then updateScrapStatus("❌ Không tìm thấy Scrapper"); return 0 end
        -- Chỉ quét Items folder (GetChildren, không GetDescendants)
        local iF=Workspace:FindFirstChild("Items")
        local scanList
        if iF then
            scanList=iF:GetChildren()
        else
            -- Fallback: lọc bỏ Map, Characters, Terrain
            local SKIP={Map=true,Characters=true,Terrain=true,Enemies=true,Mobs=true,NPCs=true,Campground=true}
            scanList={}
            for _,o in ipairs(Workspace:GetChildren()) do if not SKIP[o.Name] then table.insert(scanList,o) end end
        end
        local count=0
        for _,o in ipairs(scanList) do
            if not CFG.AutoScrapper then break end
            -- isValidScrapItem check đầy đủ trước khi làm bất cứ gì
            if isValidScrapItem(o) then
                local p=partOf(o)
                if p and (p.Position-sp.Position).Magnitude>11 then
                    local dropCF=CFrame.new(sp.Position+Vector3.new(
                        math.random(-10,10)/10, 8+(count%4)*0.7, math.random(-10,10)/10))
                    if moveScrapItem(o,dropCF) then
                        count+=1; totalScrapMoved+=1
                        updateScrapStatus(string.format("⚙️ %s → Scrapper (Tổng:%d)",o.Name,totalScrapMoved))
                        task.wait(0.06)
                    end
                end
            end
        end
        if count==0 then updateScrapStatus(string.format("⚙️ Đang quét · Đã rớt:%d",totalScrapMoved)) end
        return count
    end)
    isMovingScrap=false
    if not ok then cachedScrapperPart=nil; updateScrapStatus("⚠️ Lỗi — làm mới Scrapper..."); return 0 end
    return moved or 0
end
task.spawn(function() while true do if CFG.AutoScrapper then pcall(sendScrapToScrapper); task.wait(0.1) else task.wait(0.3) end end end)

--========================================================
-- PLANT & REVEAL MAP
--========================================================

local function plantSaplings(statusLbl)
    local function ss(txt) if statusLbl and statusLbl.Parent then statusLbl.Text=txt end end
    if not PlantRE then ss("❌ Thiếu remote PlantItem"); return 0 end
    if not getnilinstances then ss("❌ Executor thiếu getnilinstances"); return 0 end
    ss("🔍 Đang quét..."); local saps=getNilByName("Sapling")
    if #saps==0 then ss("⚠️ Không có mầm cây"); return 0 end
    ss("🌱 "..#saps.." mầm — đang trồng...")
    local r=root(); if not r then ss("❌ Không thấy nhân vật"); return 0 end
    local base=r.CFrame.Position-Vector3.new(0,3,0); local count=0
    for _,s in ipairs(saps) do
        if not pcall(function() return s.Name end) then continue end
        local off=Vector3.new(math.random(-3,3)/10,0,math.random(-3,3)/10)
        if pcall(PlantRE.InvokeServer,PlantRE,s,base+off) then count+=1 end
        if StopDragRE then pcall(StopDragRE.FireServer,StopDragRE,s) end
        task.wait(0.15)
    end
    ss(count>0 and "✅ Đã trồng "..count.."/"..#saps.." mầm" or "⚠️ Trồng thất bại"); return count
end

local function revealMap()
    if not MapRE then return end; local cells={}
    for r=1,64 do for c=1,64 do table.insert(cells,{Row=r,Col=c}) end end
    for i=1,#cells,200 do local b={}; for j=i,math.min(i+199,#cells) do table.insert(b,cells[j]) end; pcall(MapRE.FireServer,MapRE,b,{}); task.wait(0.1) end
end

--========================================================
-- CharacterAdded
--========================================================

Player.CharacterAdded:Connect(function()
    task.wait(0.5); resetCounter()
    if CFG.Fly then startFly() end
    if CFG.GodMode then startGodMode() end
end)

--========================================================
-- SUNSET UI LIBRARY
--========================================================

local Library={}
function Library:CreateWindow(title)
    local gui=Instance.new("ScreenGui"); gui.Name="SunsetUI"; gui.IgnoreGuiInset=true; gui.ResetOnSpawn=false; gui.DisplayOrder=100
    pcall(function() gui.Parent=CoreGui end); if gui.Parent~=CoreGui then gui.Parent=PlayerGui end

    local currentColor=Color3.fromRGB(255,128,0)
    local toggleButton,mainFrame,sidebarFrame,titleLabel,contentFrame

    local function updateTheme(c)
        currentColor=c
        if mainFrame and mainFrame:FindFirstChild("UIStroke") then mainFrame.UIStroke.Color=c end
        if sidebarFrame and sidebarFrame:FindFirstChild("UIStroke") then sidebarFrame.UIStroke.Color=c end
        if titleLabel then titleLabel.TextColor3=c end
        if toggleButton then toggleButton.BackgroundColor3=c end
    end
    local function Notify(t,tx,d) pcall(function() game:GetService("StarterGui"):SetCore("SendNotification",{Title=t,Text=tx,Duration=d or 5}) end) end

    toggleButton=Instance.new("ImageButton"); toggleButton.Size=UDim2.fromOffset(44,44); toggleButton.Position=UDim2.new(0,10,0.5,-22)
    toggleButton.BackgroundColor3=currentColor; toggleButton.Image="rbxassetid://97939372251102"; toggleButton.ZIndex=20; toggleButton.Parent=gui
    Instance.new("UICorner",toggleButton).CornerRadius=UDim.new(1,0)

    local dragB,dSB,sPB,movedB=false,nil,nil,false
    toggleButton.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then
            dragB=true; movedB=false; dSB=i.Position; sPB=toggleButton.Position end end)
    toggleButton.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then dragB=false end end)
    UIS.InputChanged:Connect(function(i)
        if dragB and (i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseMovement) then
            local d=i.Position-dSB; if d.Magnitude>5 then movedB=true end
            toggleButton.Position=UDim2.new(sPB.X.Scale,sPB.X.Offset+d.X,sPB.Y.Scale,sPB.Y.Offset+d.Y) end end)

    mainFrame=Instance.new("Frame"); mainFrame.Size=UDim2.new(0,460,0,390)
    mainFrame.Position=UDim2.new(0.5,-230,0.5,-195); mainFrame.BackgroundColor3=Color3.fromRGB(0,0,0)
    mainFrame.BackgroundTransparency=0.15; mainFrame.Parent=gui
    Instance.new("UICorner",mainFrame).CornerRadius=UDim.new(0,8)
    local strokeMain=Instance.new("UIStroke",mainFrame); strokeMain.Color=currentColor; strokeMain.Thickness=1

    local dragM,dSM,sPM=false,nil,nil
    mainFrame.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then dragM=true; dSM=i.Position; sPM=mainFrame.Position end end)
    mainFrame.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then dragM=false end end)
    UIS.InputChanged:Connect(function(i)
        if dragM and (i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseMovement) then
            local d=i.Position-dSM; mainFrame.Position=UDim2.new(sPM.X.Scale,sPM.X.Offset+d.X,sPM.Y.Scale,sPM.Y.Offset+d.Y) end end)

    sidebarFrame=Instance.new("Frame"); sidebarFrame.Size=UDim2.new(0,95,1,0)
    sidebarFrame.BackgroundColor3=Color3.fromRGB(18,18,18); sidebarFrame.BackgroundTransparency=0.15; sidebarFrame.Parent=mainFrame
    Instance.new("UICorner",sidebarFrame).CornerRadius=UDim.new(0,8)
    Instance.new("UIStroke",sidebarFrame).Color=currentColor

    titleLabel=Instance.new("TextLabel"); titleLabel.Size=UDim2.new(1,0,0,30); titleLabel.Text=title
    titleLabel.TextColor3=currentColor; titleLabel.BackgroundTransparency=1; titleLabel.TextSize=13; titleLabel.Font=Enum.Font.GothamBold; titleLabel.Parent=sidebarFrame

    contentFrame=Instance.new("Frame"); contentFrame.Size=UDim2.new(1,-95,1,0); contentFrame.Position=UDim2.new(0,95,0,0); contentFrame.BackgroundTransparency=1; contentFrame.Parent=mainFrame

    local currentTab; local tabY=33; local tabOrderList={}; local WF={}

    function WF:CreateTab(name)
        local btn=Instance.new("TextButton"); btn.Size=UDim2.new(1,-10,0,28); btn.Position=UDim2.new(0,5,0,tabY)
        btn.Text=name; btn.BackgroundColor3=Color3.fromRGB(38,38,38); btn.TextColor3=currentColor
        btn.Font=Enum.Font.GothamBold; btn.TextSize=11; btn.Parent=sidebarFrame
        Instance.new("UICorner",btn).CornerRadius=UDim.new(0,4); tabY+=33; table.insert(tabOrderList,btn)

        local Tab=Instance.new("ScrollingFrame"); Tab.Size=UDim2.new(1,0,1,0); Tab.Visible=false; Tab.Parent=contentFrame
        Tab.ScrollBarThickness=4; Tab.ScrollBarImageColor3=currentColor; Tab.BackgroundTransparency=1
        Tab.BorderSizePixel=0; Tab.CanvasSize=UDim2.new(0,0,0,0); Tab.AutomaticCanvasSize=Enum.AutomaticSize.Y
        local lay=Instance.new("UIListLayout",Tab); lay.Padding=UDim.new(0,8); lay.SortOrder=Enum.SortOrder.LayoutOrder; lay.HorizontalAlignment=Enum.HorizontalAlignment.Center
        local pad=Instance.new("UIPadding",Tab); pad.PaddingTop=UDim.new(0,8); pad.PaddingBottom=UDim.new(0,10)

        btn.MouseButton1Click:Connect(function()
            for _,c in ipairs(sidebarFrame:GetChildren()) do if c:IsA("TextButton") then c.BackgroundColor3=Color3.fromRGB(38,38,38); c.TextColor3=currentColor end end
            btn.BackgroundColor3=currentColor; btn.TextColor3=Color3.fromRGB(0,0,0)
            if currentTab then currentTab.Visible=false end; currentTab=Tab; Tab.Visible=true
        end)

        local E={}
        function E:AddSection(sTitle)
            local S={}
            local sf=Instance.new("Frame"); sf.Size=UDim2.new(1,-12,0,0); sf.BackgroundColor3=Color3.fromRGB(14,14,14); sf.BackgroundTransparency=0.25; sf.Parent=Tab; sf.AutomaticSize=Enum.AutomaticSize.Y
            Instance.new("UICorner",sf).CornerRadius=UDim.new(0,6)
            local stk=Instance.new("UIStroke",sf); stk.Color=currentColor; stk.Thickness=1
            Instance.new("UIListLayout",sf).Padding=UDim.new(0,4)
            local stl=Instance.new("TextLabel",sf); stl.Size=UDim2.new(1,0,0,22); stl.Text=" "..sTitle; stl.BackgroundTransparency=1; stl.TextColor3=currentColor; stl.TextSize=12; stl.Font=Enum.Font.GothamBold; stl.TextXAlignment=Enum.TextXAlignment.Left
            local con=Instance.new("Frame",sf); con.Size=UDim2.new(1,0,0,0); con.BackgroundTransparency=1; con.AutomaticSize=Enum.AutomaticSize.Y
            local cl=Instance.new("UIListLayout",con); cl.Padding=UDim.new(0,6); cl.HorizontalAlignment=Enum.HorizontalAlignment.Center
            local cp=Instance.new("UIPadding",con); cp.PaddingBottom=UDim.new(0,6)

            function S:AddLabel(text)
                local l=Instance.new("TextLabel"); l.Size=UDim2.new(1,-12,0,20); l.Text=text; l.BackgroundTransparency=1
                l.TextColor3=Color3.fromRGB(210,210,210); l.Font=Enum.Font.Gotham; l.TextSize=11; l.TextXAlignment=Enum.TextXAlignment.Left; l.TextTruncate=Enum.TextTruncate.AtEnd; l.Parent=con; return l
            end
            function S:AddButton(text,cb)
                local b=Instance.new("TextButton"); b.Size=UDim2.new(1,-12,0,32); b.Text=text
                b.BackgroundColor3=Color3.fromRGB(28,28,28); b.TextColor3=currentColor; b.Font=Enum.Font.GothamBold; b.TextSize=11; b.Parent=con
                Instance.new("UICorner",b).CornerRadius=UDim.new(0,4)
                b.MouseButton1Click:Connect(function() if cb then pcall(cb) end end); return b
            end
            function S:AddToggle(text,defOrCb,mayCb)
                local def,cb=false,nil
                if type(defOrCb)=="boolean" then def=defOrCb; cb=mayCb else cb=defOrCb end
                local state=def==true
                local f=Instance.new("Frame"); f.Size=UDim2.new(1,-12,0,36); f.BackgroundColor3=Color3.fromRGB(28,28,28); f.Parent=con
                Instance.new("UICorner",f).CornerRadius=UDim.new(0,4)
                local lbl=Instance.new("TextLabel",f); lbl.Size=UDim2.new(1,-55,1,0); lbl.Position=UDim2.new(0,10,0,0); lbl.Text=text; lbl.BackgroundTransparency=1; lbl.TextColor3=currentColor; lbl.Font=Enum.Font.Gotham; lbl.TextSize=11; lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.TextTruncate=Enum.TextTruncate.AtEnd
                local tgl=Instance.new("Frame",f); tgl.Size=UDim2.new(0,40,0,20); tgl.Position=UDim2.new(1,-50,0.5,-10); tgl.BackgroundColor3=state and currentColor or Color3.fromRGB(50,50,50); Instance.new("UICorner",tgl).CornerRadius=UDim.new(1,0)
                local cir=Instance.new("Frame",tgl); cir.Size=UDim2.new(0,16,0,16); cir.Position=state and UDim2.new(1,-18,0.5,-8) or UDim2.new(0,2,0.5,-8); cir.BackgroundColor3=state and Color3.fromRGB(0,0,0) or currentColor; Instance.new("UICorner",cir).CornerRadius=UDim.new(1,0)
                f.InputBegan:Connect(function(i)
                    if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then
                        state=not state
                        TweenService:Create(tgl,TweenInfo.new(0.2),{BackgroundColor3=state and currentColor or Color3.fromRGB(50,50,50)}):Play()
                        TweenService:Create(cir,TweenInfo.new(0.2),{Position=state and UDim2.new(1,-18,0.5,-8) or UDim2.new(0,2,0.5,-8),BackgroundColor3=state and Color3.fromRGB(0,0,0) or currentColor}):Play()
                        if cb then pcall(cb,state) end
                    end
                end)
                return f
            end
            function S:AddSlider(text,min,max,defOrCb,mayCb)
                local def,cb=min,nil
                if type(defOrCb)=="number" then def=math.clamp(defOrCb,min,max); cb=mayCb else cb=defOrCb end
                local value,dragging=def,false; local iA=math.clamp((value-min)/math.max(max-min,1),0,1)
                local frame=Instance.new("Frame"); frame.Size=UDim2.new(1,-12,0,55); frame.BackgroundColor3=Color3.fromRGB(28,28,28); frame.Parent=con; Instance.new("UICorner",frame).CornerRadius=UDim.new(0,4)
                local lbl=Instance.new("TextLabel",frame); lbl.Size=UDim2.new(1,-10,0,20); lbl.Position=UDim2.new(0,5,0,5); lbl.Text=text.." ("..value..")"; lbl.BackgroundTransparency=1; lbl.TextColor3=currentColor; lbl.Font=Enum.Font.Gotham; lbl.TextSize=11
                local bar=Instance.new("Frame",frame); bar.Size=UDim2.new(1,-20,0,5); bar.Position=UDim2.new(0,10,1,-15); bar.BackgroundColor3=Color3.fromRGB(50,50,50); Instance.new("UICorner",bar).CornerRadius=UDim.new(1,0)
                local fill=Instance.new("Frame",bar); fill.Size=UDim2.new(iA,0,1,0); fill.BackgroundColor3=currentColor; Instance.new("UICorner",fill).CornerRadius=UDim.new(1,0)
                local function upd(inp)
                    if bar.AbsoluteSize.X<=0 then return end
                    local pos=math.clamp((inp.Position.X-bar.AbsolutePosition.X)/bar.AbsoluteSize.X,0,1)
                    fill.Size=UDim2.new(pos,0,1,0); value=math.floor(min+(max-min)*pos+0.5); lbl.Text=text.." ("..value..")"
                    if cb then pcall(cb,value) end
                end
                bar.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true; upd(i) end end)
                UIS.InputChanged:Connect(function(i) if dragging and (i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseMovement) then upd(i) end end)
                UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end end)
                return frame
            end
            return S
        end
        return E
    end

    function WF:SetThemeColor(c) updateTheme(c) end
    function WF:Notify(t,tx,d) Notify(t,tx,d) end
    function WF:SetToggleSize(size)
        if toggleButton then
            toggleButton.Size=UDim2.fromOffset(size,size)
            toggleButton.Position=UDim2.new(0,10,0.5,-size/2)
        end
    end

    local open,notified=true,false
    toggleButton.MouseButton1Click:Connect(function()
        if movedB then return end; open=not open; mainFrame.Visible=open
        if open and not notified then Notify("Sunset 🌅","99 Nights Loaded ✓",4); notified=true end
    end)
    task.defer(function() if tabOrderList[1] then tabOrderList[1].MouseButton1Click:Fire() end end)
    return WF
end

--========================================================
-- FLY PAD MOBILE
--========================================================

local flyPad=Instance.new("Frame"); flyPad.Size=UDim2.fromOffset(60,124); flyPad.Position=UDim2.new(1,-70,1,-132); flyPad.BackgroundTransparency=1; flyPad.Visible=false
pcall(function() flyPad.Parent=CoreGui end); if flyPad.Parent~=CoreGui then flyPad.Parent=PlayerGui end

local function holdBtn(y,txt,fn)
    local b=Instance.new("TextButton"); b.Size=UDim2.fromOffset(56,56); b.Position=UDim2.fromOffset(0,y)
    b.BackgroundColor3=Color3.fromRGB(22,22,22); b.Text=txt; b.TextColor3=Color3.fromRGB(255,128,0)
    b.Font=Enum.Font.GothamBold; b.TextSize=20; b.Parent=flyPad; Instance.new("UICorner",b).CornerRadius=UDim.new(1,0)
    Instance.new("UIStroke",b).Color=Color3.fromRGB(255,128,0)
    b.MouseButton1Down:Connect(function() fn(true) end); b.MouseButton1Up:Connect(function() fn(false) end); b.MouseLeave:Connect(function() fn(false) end)
    b.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.Touch then fn(true) end end)
    b.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.Touch then fn(false) end end)
end
holdBtn(0,"▲",function(v) padUp=v end); holdBtn(68,"▼",function(v) padDown=v end)

--========================================================
-- BUILD MENU
--========================================================

local Win=Library:CreateWindow("SUNSET")

-- TAB 1: CHÍNH
local T1=Win:CreateTab("Chính")
do
    local sC=T1:AddSection("COMBAT & FARM")
    local kt=getKillTool(); local ct=getChopTool()
    sC:AddLabel("🗡 Kill: "..(kt and kt.Name or "—").."  🪓 Chop: "..(ct and ct.Name or "—"))
    sC:AddToggle("Kill Aura",CFG.KillAura,function(v) CFG.KillAura=v end)
    sC:AddSlider("Kill Radius",10,500,CFG.KillRadius,function(v) CFG.KillRadius=v end)
    sC:AddToggle("TP Auto Chop",CFG.AutoChop,function(v) CFG.AutoChop=v end)
    sC:AddSlider("Chop Radius",10,500,CFG.ChopRadius,function(v) CFG.ChopRadius=v end)
    sC:AddSlider("Delay (x10ms)",5,60,math.floor(CFG.Delay*100),function(v) CFG.Delay=v/100 end)

    local sR=T1:AddSection("RƯƠNG, ĐẠN & XU")
    sR:AddToggle("Auto Rương & Nhặt Đồ",CFG.AutoChestAndLoot,function(v)
        CFG.AutoChestAndLoot=v
        if not v then updateChestLootStatus("Tắt · Nhặt:"..totalItemsLooted.." →Lửa:"..totalSentToFire) end
    end)
    chestLootStatusLbl=sR:AddLabel(chestLootStatusText)
    sR:AddToggle("Tự nhặt toàn bộ xu",CFG.AutoCollectCoins,function(v)
        CFG.AutoCollectCoins=v; if v then task.spawn(collectCoins) else updateCoinStatus("Tắt (Tổng:"..totalCollectedCoins..")") end
    end)
    coinStatusLbl=sR:AddLabel(coinStatusText)

    local sS=T1:AddSection("SINH TỒN & TRỒNG CÂY")
    sS:AddToggle("Auto Eat Carrot",CFG.AutoEat,function(v) CFG.AutoEat=v; if not v then updateEatStatus("Tắt") end end)
    eatStatusLbl=sS:AddLabel(eatStatusText)
    local plantLbl=sS:AddLabel("Đứng chỗ trồng → bấm nút")
    sS:AddButton("🌱 Trồng tất cả mầm cây",function() task.spawn(function() plantSaplings(plantLbl) end) end)
end

-- TAB 2: DI CHUYỂN
local T2=Win:CreateTab("Di chuyển")
do
    local sM=T2:AddSection("MOVEMENT")
    sM:AddToggle("Speed",CFG.Speed,function(v) CFG.Speed=v; if not v then local h=hum(); if h then h.WalkSpeed=16 end end end)
    sM:AddSlider("Walk Speed",16,300,CFG.WalkSpeed,function(v) CFG.WalkSpeed=v end)
    sM:AddToggle("High Jump",CFG.Jump,function(v) CFG.Jump=v; if not v then local h=hum(); if h then h.JumpPower=50 end end end)
    sM:AddSlider("Jump Power",50,500,CFG.JumpPower,function(v) CFG.JumpPower=v end)
    sM:AddToggle("Fly",CFG.Fly,function(v) CFG.Fly=v; flyPad.Visible=v; if v then startFly() else stopFly() end end)
    sM:AddSlider("Fly Speed",10,200,CFG.FlySpeed,function(v) CFG.FlySpeed=v end)
    sM:AddToggle("Noclip",CFG.Noclip,function(v) CFG.Noclip=v; if not v then restoreNoclip() end end)

    local sG=T2:AddSection("GOD MODE")
    sG:AddToggle("🛡 God Mode (Bay cao · Hồi HP)",CFG.GodMode,function(v)
        if v then startGodMode() else stopGodMode() end
    end)
    sG:AddSlider("God Height (studs)",20,300,CFG.GodHeight,function(v)
        CFG.GodHeight=v
        if CFG.GodMode then startGodMode() end
    end)
end

-- TAB 3: TRẺ EM
local T3=Win:CreateTab("Trẻ em")
do
    local sAR=T3:AddSection("AUTO CỨU TRẺ")
    local sk=getSackTool(); sAR:AddLabel("🎒 Túi: "..(sk and sk.Name or "Chưa có"))
    sAR:AddToggle("Auto cứu trẻ (TP→Balo→Lửa)",CFG.AutoRescueChild,function(v)
        CFG.AutoRescueChild=v; if not v then updateRescueStatus("Tắt · Đã cứu:"..totalChildrenSaved) end end)
    rescueStatusLbl=sAR:AddLabel(rescueStatusText)
    sAR:AddButton("🔄 Reset danh sách đã cứu",function()
        rescuedChildren=setmetatable({},{__mode="k"}); rescuedChildKeys={}; updateRescueStatus("🔄 Đã reset") end)

    local sE=T3:AddSection("ESP & TP THỦ CÔNG")
    sE:AddToggle("ESP Trẻ em",CFG.ESPChild,function(v) CFG.ESPChild=v; if not v then clearESP() end end)
    local r=root(); local list={}
    for m,_ in pairs(childSet) do if m and m.Parent then local p=partOf(m); if p then table.insert(list,{m=m,d=r and math.floor((p.Position-r.Position).Magnitude) or 0}) end end end
    table.sort(list,function(a,b) return a.d<b.d end)
    if #list==0 then sE:AddLabel("Không tìm thấy trẻ nào")
    else for i,item in ipairs(list) do sE:AddButton(string.format("TP %d. %s (%d studs)",i,item.m.Name,item.d),function() tpTo(item.m) end) end end
end

-- TAB 4: TP & ĐỒ
local T4=Win:CreateTab("TP & Đồ")
do
    local sF=T4:AddSection("LỬA TRẠI & NHIÊN LIỆU")
    sF:AddButton("🔥 TP Lửa trại",tpFire)
    sF:AddToggle("Auto dồn nhiên liệu → Lửa",CFG.AutoDrop,function(v)
        CFG.AutoDrop=v; if v then task.spawn(dumpFuel) else updateFireStatus("Tắt · Tổng:"..totalFuelMoved) end end)
    fireStatusLbl=sF:AddLabel(fireStatusText)
    sF:AddButton("🪵 Dồn nhiên liệu ngay",function() task.spawn(dumpFuel) end)

    local sSc=T4:AddSection("SCRAPPER (CHỈ VẬT PHẨM)")
    sSc:AddButton("⚙️ TP Scrapper",tpScrapper_)
    sSc:AddToggle("Auto TP phế liệu → Scrapper",CFG.AutoScrapper,function(v)
        CFG.AutoScrapper=v; if v then task.spawn(sendScrapToScrapper) else updateScrapStatus("Tắt · Tổng:"..totalScrapMoved) end end)
    scrapStatusLbl=sSc:AddLabel(scrapStatusText)
    sSc:AddButton("🔩 Đưa phế liệu ngay",function() task.spawn(sendScrapToScrapper) end)

    local sP=T4:AddSection("KÉO VẬT PHẨM VỀ NGƯỜI")
    sP:AddButton("🍎 Kéo thức ăn",function() task.spawn(function() pullExact(FOOD_ITEMS) end) end)
    sP:AddButton("⚙️ Kéo phế liệu về người",function() task.spawn(function() pullExact(SCRAP_EXACT) end) end)

    local sPl=T4:AddSection("NGƯỜI CHƠI")
    local r=root(); local hasOther=false
    for _,plr in ipairs(Players:GetPlayers()) do
        if plr~=Player then
            hasOther=true
            local pr=plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
            local d=(r and pr) and math.floor((pr.Position-r.Position).Magnitude) or 0
            sPl:AddButton(string.format("Kéo %s (%d studs)",plr.Name,d),function() pullPlayer(plr) end)
        end
    end
    if not hasOther then sPl:AddLabel("Không có người chơi khác") end
end

-- TAB 5: CÀI ĐẶT
local T5=Win:CreateTab("Cài đặt")
do
    local sP=T5:AddSection("HIỆU NĂNG & ÁNH SÁNG")
    sP:AddToggle("Fix Lag Pro",CFG.FixLag,function(v) setFixLag(v) end)
    sP:AddToggle("Fullbright",CFG.Fullbright,function(v) CFG.Fullbright=v; setFB(v) end)
    local sM=T5:AddSection("BẢN ĐỒ & GIAO DIỆN")
    sM:AddButton("🗺️ Reveal Map",function() task.spawn(revealMap) end)
    sM:AddSlider("Kích thước nút",32,70,44,function(v) Win:SetToggleSize(v) end)
end

print("=========================================")
print(" SUNSET UI + 99 NIGHTS FINAL LOADED ✓")
print("=========================================")
