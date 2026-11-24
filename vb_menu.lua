--[[
	VB MENU — Bright Citrus UI
	Features: God Mode · Speed/Jump/Fly/Noclip · Kill Aura · Auto Chop
	Auto Chest/Loot · Auto Collect Coins · Auto Rescue Child · ESP Child
	Auto Eat · Auto Drop Fuel → Fire · Auto Scrap → Scrapper
	Fullbright · Fix Lag · Reveal Map · Plant Saplings · Pull Items/Players
	Custom Item Filter Tables (Fire & Scrapper)
]]

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

-- Cleanup old GUIs
for _, name in ipairs({"OllieUI","OllieMenu","ollie_v9","SunsetUI","VbMenu"}) do
	pcall(function() local g = PlayerGui:FindFirstChild(name); if g then g:Destroy() end end)
	pcall(function() local g = CoreGui:FindFirstChild(name);   if g then g:Destroy() end end)
end

------------------------------------------------------------------------
-- REMOTES & LISTS
------------------------------------------------------------------------
local Remotes          = RS:WaitForChild("RemoteEvents", 10)
local EquipRE          = Remotes and Remotes:FindFirstChild("EquipItemHandle")
local UnequipRE        = Remotes and Remotes:FindFirstChild("UnequipItemHandle")
local DamageRF         = Remotes and Remotes:FindFirstChild("ToolDamageObject")
local MapRE            = Remotes and Remotes:FindFirstChild("MapCellsDiscovered")
local DragRE           = Remotes and Remotes:FindFirstChild("RequestStartDraggingItem")
local StopDragRE       = Remotes and Remotes:FindFirstChild("StopDraggingItem")
local HitSoundRE       = Remotes and Remotes:FindFirstChild("PlayEnemyHitSound")
local ReplicateSoundRE = Remotes and Remotes:FindFirstChild("RequestReplicateSound")
local PlantRE          = Remotes and Remotes:FindFirstChild("RequestPlantItem")
local ConsumeRF        = Remotes and Remotes:FindFirstChild("RequestConsumeItem")
local OpenChestRE      = Remotes and Remotes:FindFirstChild("RequestOpenItemChest")
local CollectCoinRF    = Remotes and Remotes:FindFirstChild("RequestCollectCoints")
local HotbarItemRF     = Remotes and Remotes:FindFirstChild("RequestHotbarItem")
local BagStoreRF       = Remotes and Remotes:FindFirstChild("RequestBagStoreItem")
local BagDropRE        = Remotes and Remotes:FindFirstChild("RequestBagDropItem")

local AXES = { "Old Axe","Good Axe","Ice Axe","Strong Axe","Chainsaw","Admin Axe" }
local HEAVY_AXES = { ["Strong Axe"]=true,["Chainsaw"]=true,["Admin Axe"]=true }
local MELEE_WEAPONS = {
	"Spear","Honey Spear","Morningstar","Katana","Laser Sword","Ice Sword",
	"Trident","Poison Claws","Poison Spear","Infernal Sword",
	"Cultist King Mace","Brutal Battleaxe","Obsidiron Hammer",
	"Scythe","Vampire Scythe","Happy's Scythe",
}
local SACK_NAMES  = { "Admin Sack","Strong Sack","Good Sack","Old Sack","Sack","Bag" }
local FOOD_ITEMS  = { "Berry","Carrot","Apple","Corn","Pumpkin","Chili" }
local SCRAP_ITEMS = { "Log","Chair","Bolt","Sheet Metal","Broken Fan","Broken Radio","Broken Microwave","Washing Machine","Tires & Engines" }
local FUEL_EXACT  = { "Log","Chair","Biofuel","Coal","Purple Fur Tuft","Fuel Canister","Oil Barrel" }
local SCRAPPER_ITEMS = { "Bolt","Sheet Metal","Broken Fan","Broken Radio","Broken Microwave","Washing Machine","Tires & Engines" }
local CHEST_KEYS  = { "Chest","Crate","Supply","Loot" }
local COIN_KEYS   = { "Coin" }
local AMMO_KEYS   = { "Ammo","Bullet","Shell","Arrow","Dart","Rocket","Cartridge" }
local IGNORE_LOOT_KEYS = {
	"Tree","Pine","Oak","Birch","Fir","Bush","Foliage","Wall","Floor","Ground",
	"Terrain","Campfire","MainFire","Spawn","Part","Baseplate","Hitbox"
}

local CFG = {
	GodMode=false,
	Speed=false,            WalkSpeed=40,
	Jump=false,             JumpPower=90,
	Fly=false,              FlySpeed=60,
	Noclip=false,
	KillAura=false,         KillRadius=150,
	AutoChop=false,         ChopRadius=130,
	AutoDrop=false,
	AutoScrap=false,
	AutoEat=false,
	AutoChestAndLoot=false,
	AutoCollectCoins=false,
	AutoRescueChild=false,
	ESPChild=false,
	Fullbright=false,
	FixLag=false,
	Delay=0.35,
}

local FireAllowedItems, ScrapAllowedItems = {}, {}
for _, v in ipairs(FUEL_EXACT)     do FireAllowedItems[v]  = true end
for _, v in ipairs(SCRAPPER_ITEMS) do ScrapAllowedItems[v] = true end

local MAX_KILL_PER_CYCLE = 6
local TOOL_SUFFIX = "11960515286"
local CHILD_KEY   = "Lost Child"

------------------------------------------------------------------------
-- HELPERS
------------------------------------------------------------------------
local function hasKey(name, keys)
	if type(name)~="string" then return false end
	local n = name:lower()
	for _,k in ipairs(keys) do if n:find(k:lower(),1,true) then return true end end
	return false
end
local function matchesExact(name, list)
	for _,v in ipairs(list) do if name==v then return true end end
	return false
end
local function root() local c=Player.Character; return c and c:FindFirstChild("HumanoidRootPart") end
local function hum()  local c=Player.Character; return c and c:FindFirstChildOfClass("Humanoid") end
local function getHeadPart()
	local c=Player.Character
	return c and (c:FindFirstChild("Head") or c:FindFirstChild("HumanoidRootPart"))
end
local function partOf(m)
	if not m then return nil end
	if m:IsA("BasePart") then return m end
	if m:IsA("Model") then
		if m.PrimaryPart then return m.PrimaryPart end
		for _,ch in ipairs(m:GetDescendants()) do
			if ch:IsA("BasePart") and hasKey(ch.Name,{"Trunk","Wood","Log","Hitbox","Stem"}) then return ch end
		end
		local hrp=m:FindFirstChild("HumanoidRootPart")
		if hrp then return hrp end
		return m:FindFirstChildWhichIsA("BasePart",true)
	end
	return nil
end
local function findFromList(list,inv,char)
	for _,name in ipairs(list) do
		local t=(inv and inv:FindFirstChild(name)) or (char and char:FindFirstChild(name))
		if t then return t end
	end
end
local function getFallbackTool(inv,char)
	if inv then
		local t=inv:FindFirstChildWhichIsA("Tool")
		if t then return t end
		for _,item in ipairs(inv:GetChildren()) do if item:IsA("Model") then return item end end
	end
	return char and char:FindFirstChildWhichIsA("Tool")
end
local function getKillTool()
	local inv,char=Player:FindFirstChild("Inventory"),Player.Character
	return findFromList(MELEE_WEAPONS,inv,char) or findFromList(AXES,inv,char) or getFallbackTool(inv,char)
end
local function getChopTool()
	local inv,char=Player:FindFirstChild("Inventory"),Player.Character
	local pri={"Admin Axe","Chainsaw","Strong Axe","Ice Axe","Good Axe","Old Axe"}
	return findFromList(pri,inv,char) or findFromList(AXES,inv,char) or findFromList(MELEE_WEAPONS,inv,char) or getFallbackTool(inv,char)
end
local function getSackTool()
	local inv,char=Player:FindFirstChild("Inventory"),Player.Character
	local ex=findFromList(SACK_NAMES,inv,char)
	if ex then return ex end
	for _,item in ipairs((inv and inv:GetChildren()) or {}) do if hasKey(item.Name,{"Sack","Bag"}) then return item end end
	for _,item in ipairs((char and char:GetChildren()) or {}) do if hasKey(item.Name,{"Sack","Bag"}) then return item end end
	return nil
end

local cachedFirePart=nil
local function getFirePart()
	if cachedFirePart and cachedFirePart.Parent then return cachedFirePart end
	local map=Workspace:FindFirstChild("Map")
	local camp=map and map:FindFirstChild("Campground")
	local fire=camp and camp:FindFirstChild("MainFire",true)
	if fire then cachedFirePart=partOf(fire); return cachedFirePart end
	for _,o in ipairs(Workspace:GetDescendants()) do
		if o.Name=="MainFire" or o.Name=="Campfire" then
			local p=partOf(o)
			if p then cachedFirePart=p; return p end
		end
	end
	return nil
end
local function getScrapperPart()
	for _,o in ipairs(Workspace:GetDescendants()) do
		if hasKey(o.Name,{"Scrapper","Recycler"}) then
			local p=partOf(o)
			if p then return p end
		end
	end
	return nil
end

------------------------------------------------------------------------
-- GOD MODE
------------------------------------------------------------------------
local godCharConns={}
local function clearGodConns()
	for _,conn in ipairs(godCharConns) do pcall(function() conn:Disconnect() end) end
	godCharConns={}
end
local function bindGodModeToChar(char)
	clearGodConns()
	if not char then return end
	local function hookHum(h)
		if not h then return end
		pcall(function() h:SetStateEnabled(Enum.HumanoidStateType.Dead,false) end)
		local c1=h.HealthChanged:Connect(function(hp)
			if CFG.GodMode and hp<h.MaxHealth then
				pcall(function()
					if h.MaxHealth<=0 or h.MaxHealth==math.huge then h.MaxHealth=100 end
					h.Health=h.MaxHealth
				end)
			end
		end)
		local c2=h.StateChanged:Connect(function(_,newState)
			if CFG.GodMode and newState==Enum.HumanoidStateType.Dead then
				pcall(function()
					h:SetStateEnabled(Enum.HumanoidStateType.Dead,false)
					h.Health=h.MaxHealth>0 and h.MaxHealth or 100
					h:ChangeState(Enum.HumanoidStateType.Running)
				end)
			end
		end)
		table.insert(godCharConns,c1)
		table.insert(godCharConns,c2)
	end
	local eh=char:FindFirstChildOfClass("Humanoid")
	if eh then hookHum(eh) end
	local cAdd=char.ChildAdded:Connect(function(child)
		if child:IsA("Humanoid") then hookHum(child) end
	end)
	table.insert(godCharConns,cAdd)
end
local function setGodMode(state)
	CFG.GodMode=state
	local c=Player.Character; local h=hum()
	if state then
		if c then bindGodModeToChar(c) end
		if h then pcall(function() h:SetStateEnabled(Enum.HumanoidStateType.Dead,false); h.Health=h.MaxHealth>0 and h.MaxHealth or 100 end) end
	else
		clearGodConns()
		if h then pcall(function() h:SetStateEnabled(Enum.HumanoidStateType.Dead,true) end) end
	end
end
RunService.Heartbeat:Connect(function()
	if not CFG.GodMode then return end
	local c=Player.Character; if not c then return end
	local h=c:FindFirstChildOfClass("Humanoid")
	if h then
		if h.MaxHealth<=0 then h.MaxHealth=100 end
		if h.Health<h.MaxHealth then h.Health=h.MaxHealth end
	end
	for _,part in ipairs(c:GetChildren()) do
		if part:IsA("BasePart") and part.Velocity.Y<-140 then
			part.AssemblyLinearVelocity=Vector3.new(part.AssemblyLinearVelocity.X,-40,part.AssemblyLinearVelocity.Z)
		end
	end
end)

------------------------------------------------------------------------
-- CHILD CACHE & RESCUE
------------------------------------------------------------------------
local childSet={}
local function isChildModel(o)
	return o and o:IsA("Model") and string.find(o.Name,CHILD_KEY,1,true)~=nil
end
local function initChildCache()
	local charFolder=Workspace:FindFirstChild("Characters")
	local scanTargets={Workspace}
	if charFolder then table.insert(scanTargets,charFolder) end
	for _,folder in ipairs(scanTargets) do
		for _,o in ipairs(folder:GetChildren()) do if isChildModel(o) then childSet[o]=true end end
		folder.ChildAdded:Connect(function(o) if isChildModel(o) then childSet[o]=true end end)
		folder.ChildRemoved:Connect(function(o) childSet[o]=nil end)
	end
	task.spawn(function()
		local all=Workspace:GetDescendants()
		for i=1,#all do
			if isChildModel(all[i]) then childSet[all[i]]=true end
			if i%800==0 then task.wait() end
		end
	end)
end
initChildCache()

local rescueStatusText="Chờ bật tự động cứu trẻ..."
local rescueStatusLbl=nil
local rescuedChildren=setmetatable({},{__mode="k"})
local rescuedChildKeys={}
local totalChildrenSaved=0
local function updateRescueStatus(txt)
	rescueStatusText=txt
	if rescueStatusLbl and rescueStatusLbl.Parent then rescueStatusLbl.Text=txt end
end
local function getChildUniqueKey(child)
	if not child then return nil end
	local ok,dbg=pcall(function() return child:GetDebugId() end)
	if ok and dbg then return dbg end
	return tostring(child)
end
local function isChildAlreadyRescued(child)
	if not child then return true end
	if rescuedChildren[child] then return true end
	local key=getChildUniqueKey(child)
	if key and rescuedChildKeys[key] then return true end
	local fp=getFirePart(); local cp=partOf(child)
	if fp and cp and (cp.Position-fp.Position).Magnitude<=22 then
		rescuedChildren[child]=true
		if key then rescuedChildKeys[key]=true end
		return true
	end
	return false
end
local function markChildRescued(child)
	if not child then return end
	rescuedChildren[child]=true
	local key=getChildUniqueKey(child)
	if key then rescuedChildKeys[key]=true end
end
local function findItemInBag(childName)
	local itemBag=Player:FindFirstChild("ItemBag")
	if not itemBag then return nil end
	return itemBag:FindFirstChild(childName) or itemBag:FindFirstChild(CHILD_KEY) or itemBag:FindFirstChildWhichIsA("Model")
end
local function tpTo(target)
	local r=root(); if not r then return end
	local p=partOf(target)
	if p then r.CFrame=CFrame.new(p.Position+Vector3.new(0,4,2)) end
end
local function rescueSingleChild(child)
	if not child or not child.Parent then return false end
	if not (BagStoreRF and BagDropRE) then updateRescueStatus("❌ Thiếu remote BagStore/BagDrop"); return false end
	local sack=getSackTool()
	if not sack then updateRescueStatus("❌ Không tìm thấy túi"); return false end
	local fp=getFirePart()
	if not fp then updateRescueStatus("❌ Không tìm thấy Lửa trại"); return false end
	local r=root(); local cp=partOf(child)
	if not (r and cp) then return false end
	local childName=child.Name
	updateRescueStatus("🏃 Đang TP tới: "..childName)
	r.CFrame=CFrame.new(cp.Position+Vector3.new(0,3,2))
	task.wait(0.25); if not CFG.AutoRescueChild then return false end
	updateRescueStatus("🎒 Đang cất vào balo: "..childName)
	local bagTarget=findItemInBag(childName) or child
	local storeOk=pcall(BagStoreRF.InvokeServer,BagStoreRF,sack,bagTarget)
	if not storeOk then
		local alt=(bagTarget==child) and findItemInBag(childName) or child
		if alt then pcall(BagStoreRF.InvokeServer,BagStoreRF,sack,alt) end
	end
	task.wait(0.25); if not CFG.AutoRescueChild then return false end
	updateRescueStatus("🔥 TP về lửa trại...")
	r=root()
	if r and fp and fp.Parent then r.CFrame=CFrame.new(fp.Position+Vector3.new(0,4,3)) end
	task.wait(0.25)
	updateRescueStatus("📤 Thả trẻ tại lửa trại...")
	local dropTarget=(child and child.Parent) and child or findItemInBag(childName)
	if dropTarget then pcall(BagDropRE.FireServer,BagDropRE,sack,dropTarget,true) end
	task.wait(0.2)
	markChildRescued(child)
	totalChildrenSaved+=1
	updateRescueStatus(string.format("✅ Đã cứu %s (Tổng: %d)",childName,totalChildrenSaved))
	return true
end
task.spawn(function()
	while true do
		if CFG.AutoRescueChild then
			local r2=root(); local rPos=r2 and r2.Position
			local nearestChild,bestDist=nil,math.huge
			for child,_ in pairs(childSet) do
				if child and child.Parent and not isChildAlreadyRescued(child) then
					local p=partOf(child)
					if p then
						local d=rPos and (p.Position-rPos).Magnitude or 0
						if d<bestDist then bestDist=d; nearestChild=child end
					end
				end
			end
			if nearestChild then pcall(rescueSingleChild,nearestChild)
			else updateRescueStatus(string.format("✅ Đã cứu hết · Tổng: %d",totalChildrenSaved)) end
			task.wait(1.0)
		else task.wait(0.5) end
	end
end)

------------------------------------------------------------------------
-- ESP CHILD
------------------------------------------------------------------------
local espChildBillboards={}
local function clearESPChild()
	for _,b in pairs(espChildBillboards) do pcall(function() b:Destroy() end) end
	espChildBillboards={}
end
RunService.Heartbeat:Connect(function()
	if not CFG.ESPChild then return end
	for child,_ in pairs(childSet) do
		if child and child.Parent and not espChildBillboards[child] then
			local part=partOf(child)
			if part then
				local bb=Instance.new("BillboardGui")
				bb.AlwaysOnTop=true; bb.Size=UDim2.new(0,120,0,30); bb.StudsOffset=Vector3.new(0,3,0)
				bb.Adornee=part; bb.Parent=CoreGui
				local lbl=Instance.new("TextLabel",bb)
				lbl.Size=UDim2.new(1,0,1,0); lbl.BackgroundTransparency=1
				lbl.Text="👦 "..child.Name; lbl.TextColor3=Color3.fromRGB(255,220,60)
				lbl.TextScaled=true; lbl.Font=Enum.Font.GothamBold
				espChildBillboards[child]=bb
			end
		end
		if (not child or not child.Parent) and espChildBillboards[child] then
			pcall(function() espChildBillboards[child]:Destroy() end)
			espChildBillboards[child]=nil
		end
	end
end)

------------------------------------------------------------------------
-- CHEST / LOOT / AMMO / COINS
------------------------------------------------------------------------
local chestLootStatusText="Chờ bật tự động mở & nhặt rương..."
local chestLootStatusLbl=nil
local coinStatusText="Tắt"
local coinStatusLbl=nil
local totalChestsOpened,totalItemsLooted,totalAmmoCollected,totalCollectedCoins=0,0,0,0

local cachedChests={}
local openedChestDone=setmetatable({},{__mode="k"})
local failedChestAt={}
local lootedItems=setmetatable({},{__mode="k"})
local failedLootAt={}
local claimedAmmo=setmetatable({},{__mode="k"})
local failedAmmoAt={}

local CHEST_FAIL_COOLDOWN,LOOT_FAIL_COOLDOWN,AMMO_FAIL_COOLDOWN=5,35,15
local CHEST_LOOT_RADIUS=12
local CHEST_OPEN_DELAY=0.35
local CHEST_CYCLE_WAIT=1
local CHESTS_MIN_PER_CYCLE,CHESTS_MAX_PER_CYCLE=2,3

local function updateChestLootStatus(txt)
	chestLootStatusText=txt
	if chestLootStatusLbl and chestLootStatusLbl.Parent then chestLootStatusLbl.Text=txt end
end
local function updateCoinStatus(txt)
	coinStatusText=txt
	if coinStatusLbl and coinStatusLbl.Parent then coinStatusLbl.Text=txt end
end

local function isChestObject(o)
	return (o:IsA("Model") or o:IsA("BasePart")) and hasKey(o.Name,CHEST_KEYS)
end
local chestCacheInit=false
local function initChestCache()
	if chestCacheInit then return end; chestCacheInit=true
	local itemsFolder=Workspace:FindFirstChild("Items")
	local targetRoot=itemsFolder or Workspace
	task.spawn(function()
		local all=targetRoot:GetDescendants()
		for i=1,#all do
			if isChestObject(all[i]) then cachedChests[all[i]]=true end
			if i%800==0 then task.wait() end
		end
	end)
	targetRoot.DescendantAdded:Connect(function(o) if isChestObject(o) then cachedChests[o]=true end end)
	targetRoot.DescendantRemoving:Connect(function(o) cachedChests[o]=nil; failedChestAt[o]=nil end)
end

local cachedAmmoList,lastAmmoScanAt={},0
local AMMO_SCAN_INTERVAL=2.5
local function isAmmoObject(obj)
	if not obj then return false end
	local ok,name=pcall(function() return obj.Name end)
	if not ok or type(name)~="string" then return false end
	if hasKey(name,IGNORE_LOOT_KEYS) or hasKey(name,CHEST_KEYS) or hasKey(name,COIN_KEYS) then return false end
	return hasKey(name,AMMO_KEYS)
end
local function refreshAmmoCache(force)
	local now=os.clock()
	if not force and (now-lastAmmoScanAt)<AMMO_SCAN_INTERVAL then return cachedAmmoList end
	lastAmmoScanAt=now
	local found,seen={},{}
	local function tryAdd(o)
		if not o or seen[o] or claimedAmmo[o] then return end
		if isAmmoObject(o) then seen[o]=true; table.insert(found,o) end
	end
	if getnilinstances then
		local ok2,nilList=pcall(getnilinstances)
		if ok2 and nilList then
			for i=1,#nilList do tryAdd(nilList[i]); if i%1000==0 then task.wait() end end
		end
	end
	local itemsFolder=Workspace:FindFirstChild("Items")
	if itemsFolder then for _,o in ipairs(itemsFolder:GetDescendants()) do tryAdd(o) end end
	cachedAmmoList=found; return found
end
local function tryClaimSingleAmmo(ammoObj)
	if not ConsumeRF or not ammoObj then return false end
	local okAlive=pcall(function() return ammoObj.Name end)
	if not okAlive then return false end
	local done,ok,res=false,false,nil
	task.spawn(function() ok,res=pcall(ConsumeRF.InvokeServer,ConsumeRF,ammoObj); done=true end)
	local timeout=0
	while not done and timeout<0.5 do task.wait(0.05); timeout+=0.05 end
	return done and ok and res~=false
end
local function collectScannedAmmo()
	if not ConsumeRF then return 0 end
	local list=refreshAmmoCache(false)
	if #list==0 then return 0 end
	local now=os.clock(); local claimed=0
	for i=1,math.min(#list,12) do
		if not CFG.AutoChestAndLoot then break end
		local ammoObj=list[i]
		if claimedAmmo[ammoObj] then continue end
		local failT=failedAmmoAt[ammoObj]
		if failT and (now-failT)<AMMO_FAIL_COOLDOWN then continue end
		if tryClaimSingleAmmo(ammoObj) then
			claimedAmmo[ammoObj]=true; claimed+=1; totalAmmoCollected+=1
		else failedAmmoAt[ammoObj]=os.clock() end
		task.wait(0.05)
	end
	return claimed
end

local overlapParams=OverlapParams.new()
overlapParams.FilterType=Enum.RaycastFilterType.Exclude
local function isValidChestLoot(obj,targetChest)
	if not obj or not obj.Parent then return false end
	if cachedChests[obj] or obj==targetChest or obj:IsDescendantOf(targetChest) then return false end
	local ch=Player.Character
	if ch and obj:IsDescendantOf(ch) then return false end
	local inv=Player:FindFirstChild("Inventory")
	if inv and obj:IsDescendantOf(inv) then return false end
	if Players:GetPlayerFromCharacter(obj) then return false end
	local name=obj.Name
	if hasKey(name,CHEST_KEYS) or hasKey(name,COIN_KEYS) or hasKey(name,IGNORE_LOOT_KEYS) then return false end
	if obj:IsA("Tool") then return true end
	if obj:IsA("Model") then
		return (obj:FindFirstChildWhichIsA("ProximityPrompt",true)
			or obj:FindFirstChildWhichIsA("ClickDetector",true)
			or obj:FindFirstChildWhichIsA("BasePart",true))~=nil
	end
	return false
end
local function isChestSkipped(chest,now)
	if not chest or not chest.Parent then cachedChests[chest]=nil; return true end
	if openedChestDone[chest] then return true end
	local failT=failedChestAt[chest]
	return failT and (now-failT)<CHEST_FAIL_COOLDOWN
end
local function isLootSkipped(item,now)
	if not item or not item.Parent then return true end
	if lootedItems[item] then return true end
	local failT=failedLootAt[item]
	return failT and (now-failT)<LOOT_FAIL_COOLDOWN
end

task.spawn(function()
	initChestCache()
	while true do
		if CFG.AutoChestAndLoot then
			local r2=root()
			if not r2 then task.wait(1); continue end
			local now=os.clock()
			local chestList={}
			for chest,_ in pairs(cachedChests) do
				if not isChestSkipped(chest,now) then
					local p=partOf(chest)
					if p then table.insert(chestList,{obj=chest,p=p}) end
				end
			end
			local count=0
			local maxOpen=math.random(CHESTS_MIN_PER_CYCLE,CHESTS_MAX_PER_CYCLE)
			for _,entry in ipairs(chestList) do
				if count>=maxOpen then break end
				if not CFG.AutoChestAndLoot then break end
				local chest=entry.obj; local cp=entry.p
				r2.CFrame=CFrame.new(cp.Position+Vector3.new(0,3,2))
				task.wait(CHEST_OPEN_DELAY)
				if not OpenChestRE then break end
				local ok=pcall(OpenChestRE.FireServer,OpenChestRE,chest)
				if ok then
					openedChestDone[chest]=true; totalChestsOpened+=1; count+=1
					task.wait(0.4)
					local chestPos=cp.Position
					local excl={chest}
					if Player.Character then table.insert(excl,Player.Character) end
					overlapParams.FilterDescendantsInstances=excl
					local nearby=Workspace:GetPartBoundsInRadius(chestPos,CHEST_LOOT_RADIUS,overlapParams)
					local lootList,seen={},{}
					for _,part in ipairs(nearby) do
						local candidate=part:FindFirstAncestorOfClass("Tool") or part:FindFirstAncestorOfClass("Model") or part
						if candidate and not seen[candidate] then
							seen[candidate]=true
							if not isLootSkipped(candidate,now) and isValidChestLoot(candidate,chest) then
								local pp=partOf(candidate)
								local dist=pp and (pp.Position-chestPos).Magnitude or CHEST_LOOT_RADIUS
								table.insert(lootList,{obj=candidate,dist=dist})
							end
						end
					end
					table.sort(lootList,function(a,b) return a.dist<b.dist end)
					local lootPicked=0
					for _,lootEntry in ipairs(lootList) do
						if lootPicked>=1 then break end
						local lootObj=lootEntry.obj
						local ok2=pcall(function()
							if DragRE then DragRE:FireServer(lootObj) end
							task.wait(0.1)
							if StopDragRE then StopDragRE:FireServer(lootObj) end
						end)
						if ok2 then
							lootedItems[lootObj]=true; totalItemsLooted+=1; lootPicked+=1
						else failedLootAt[lootObj]=os.clock() end
						task.wait(0.08)
					end
					collectScannedAmmo()
					updateChestLootStatus(string.format("🔓 Rương: %d | Đồ: %d | Đạn: %d",totalChestsOpened,totalItemsLooted,totalAmmoCollected))
				else failedChestAt[chest]=os.clock() end
			end
			task.wait(CHEST_CYCLE_WAIT)
		else task.wait(0.5) end
	end
end)

local function collectAllCoinsOnce()
	if not CollectCoinRF then updateCoinStatus("❌ Thiếu remote CollectCoin"); return end
	updateCoinStatus("🔍 Đang quét xu...")
	local coins={}
	local function scanObj(o)
		local ok,name=pcall(function() return o.Name end)
		if ok and hasKey(name,COIN_KEYS) then table.insert(coins,o) end
	end
	for _,o in ipairs(Workspace:GetDescendants()) do scanObj(o) end
	if getnilinstances then
		local ok2,nil2=pcall(getnilinstances)
		if ok2 and nil2 then for _,o in ipairs(nil2) do scanObj(o) end end
	end
	local collected=0
	for _,coin in ipairs(coins) do
		if not CFG.AutoCollectCoins then break end
		local ok3,res=pcall(CollectCoinRF.InvokeServer,CollectCoinRF,coin)
		if ok3 and res~=false then collected+=1; totalCollectedCoins+=1 end
		task.wait(0.05)
	end
	updateCoinStatus(string.format("✅ Thu %d xu lần này (Tổng: %d)",collected,totalCollectedCoins))
end
task.spawn(function()
	while true do
		if CFG.AutoCollectCoins then
			pcall(collectAllCoinsOnce)
			task.wait(5)
		else task.wait(0.5) end
	end
end)

------------------------------------------------------------------------
-- FUEL / SCRAP / AUTO EAT / PLANT / PULL
------------------------------------------------------------------------
local eatStatusText="Tắt"
local eatStatusLbl=nil
local function updateEatStatus(txt)
	eatStatusText=txt
	if eatStatusLbl and eatStatusLbl.Parent then eatStatusLbl.Text=txt end
end

local function tpCampfire()
	local fp=getFirePart(); local r2=root()
	if fp and r2 then r2.CFrame=CFrame.new(fp.Position+Vector3.new(0,4,3)) end
end

local function dumpFuelToFire()
	local fp=getFirePart()
	if not fp then return end
	local inv=Player:FindFirstChild("Inventory")
	if not inv then return end
	for _,item in ipairs(inv:GetChildren()) do
		if matchesExact(item.Name,FUEL_EXACT) and FireAllowedItems[item.Name] then
			local r2=root()
			if r2 then r2.CFrame=CFrame.new(fp.Position+Vector3.new(0,4,2)) end
			task.wait(0.1)
			if DragRE then pcall(DragRE.FireServer,DragRE,item) end
			task.wait(0.15)
			if StopDragRE then pcall(StopDragRE.FireServer,StopDragRE,item) end
			task.wait(CFG.Delay)
		end
	end
end

local function dumpScrapToScrapper()
	local sp=getScrapperPart()
	if not sp then return end
	local inv=Player:FindFirstChild("Inventory")
	if not inv then return end
	for _,item in ipairs(inv:GetChildren()) do
		if matchesExact(item.Name,SCRAPPER_ITEMS) and ScrapAllowedItems[item.Name] then
			local r2=root()
			if r2 then r2.CFrame=CFrame.new(sp.Position+Vector3.new(0,4,2)) end
			task.wait(0.1)
			if DragRE then pcall(DragRE.FireServer,DragRE,item) end
			task.wait(0.15)
			if StopDragRE then pcall(StopDragRE.FireServer,StopDragRE,item) end
			task.wait(CFG.Delay)
		end
	end
end

task.spawn(function()
	while true do
		if CFG.AutoDrop then pcall(dumpFuelToFire) end
		if CFG.AutoScrap then pcall(dumpScrapToScrapper) end
		task.wait(3)
	end
end)

task.spawn(function()
	while true do
		if CFG.AutoEat then
			local inv=Player:FindFirstChild("Inventory")
			local ate=false
			if inv then
				for _,item in ipairs(inv:GetChildren()) do
					if matchesExact(item.Name,FOOD_ITEMS) then
						local h2=hum()
						if h2 and h2.Health<h2.MaxHealth*0.8 then
							if ConsumeRF then
								pcall(ConsumeRF.InvokeServer,ConsumeRF,item)
								updateEatStatus("🍎 Ăn: "..item.Name)
								ate=true
								break
							end
						end
					end
				end
			end
			if not ate then updateEatStatus("⏳ Chờ máu thấp...") end
			task.wait(2)
		else task.wait(0.5) end
	end
end)

local function pullAllExact(list)
	local inv=Player:FindFirstChild("Inventory"); local r2=root()
	if not r2 then return end
	for _,o in ipairs(Workspace:GetDescendants()) do
		if matchesExact(o.Name,list) then
			r2.CFrame=CFrame.new(o.Position+Vector3.new(0,3,2))
			task.wait(0.1)
			if DragRE then pcall(DragRE.FireServer,DragRE,o) end
			task.wait(0.15)
			if StopDragRE then pcall(StopDragRE.FireServer,StopDragRE,o) end
			task.wait(CFG.Delay)
		end
	end
end

local function pullPlayerToMe(plr)
	local pChar=plr.Character
	local pRoot=pChar and pChar:FindFirstChild("HumanoidRootPart")
	local r2=root()
	if pRoot and r2 then pRoot.CFrame=CFrame.new(r2.Position+Vector3.new(2,0,0)) end
end

local function plantAllSaplings(statusLbl)
	if statusLbl then statusLbl.Text="🌱 Đang trồng..." end
	local inv=Player:FindFirstChild("Inventory"); local r2=root()
	if not r2 then return end
	local planted=0
	if inv then
		for _,item in ipairs(inv:GetChildren()) do
			if hasKey(item.Name,{"Sapling","Seed","Sprout"}) then
				if PlantRE then
					pcall(PlantRE.FireServer,PlantRE,item,r2.CFrame*CFrame.new(math.random(-3,3),0,math.random(-3,3)))
					planted+=1
					task.wait(0.3)
				end
			end
		end
	end
	if statusLbl then statusLbl.Text=string.format("✅ Đã trồng %d cây",planted) end
end

------------------------------------------------------------------------
-- KILL AURA
------------------------------------------------------------------------
local function equipTool(tool)
	if not tool then return end
	if EquipRE then pcall(EquipRE.FireServer,EquipRE,tool) end
end
local function unequipTool(tool)
	if not tool then return end
	if UnequipRE then pcall(UnequipRE.FireServer,UnequipRE,tool) end
end
task.spawn(function()
	while true do
		if CFG.KillAura then
			local r2=root()
			if r2 then
				local tool=getKillTool()
				local killed=0
				for _,plr in ipairs(Players:GetPlayers()) do
					if killed>=MAX_KILL_PER_CYCLE then break end
					if plr==Player then continue end
					local ch=plr.Character
					local hrp=ch and ch:FindFirstChild("HumanoidRootPart")
					if hrp and (hrp.Position-r2.Position).Magnitude<=CFG.KillRadius then
						if tool then equipTool(tool) end
						if DamageRF then
							pcall(DamageRF.InvokeServer,DamageRF,hrp,9999)
						end
						killed+=1
					end
				end
			end
		end
		task.wait(CFG.Delay)
	end
end)

------------------------------------------------------------------------
-- AUTO CHOP
------------------------------------------------------------------------
local lastChoppedTree=nil
task.spawn(function()
	while true do
		if CFG.AutoChop then
			local r2=root()
			if r2 then
				local chopTool=getChopTool()
				local best,bestDist=nil,math.huge
				for _,o in ipairs(Workspace:GetDescendants()) do
					if o:IsA("Model") and hasKey(o.Name,{"Tree","Pine","Oak","Birch","Fir"}) then
						local p=partOf(o)
						if p then
							local d=(p.Position-r2.Position).Magnitude
							if d<=CFG.ChopRadius and d<bestDist then
								if o~=lastChoppedTree then best=o; bestDist=d end
							end
						end
					end
				end
				if best then
					local p=partOf(best)
					if p then
						r2.CFrame=CFrame.new(p.Position+Vector3.new(0,3,2))
						task.wait(0.15)
						if chopTool then equipTool(chopTool) end
						if DamageRF then
							for _,part in ipairs(best:GetDescendants()) do
								if part:IsA("BasePart") and hasKey(part.Name,{"Trunk","Wood","Log"}) then
									pcall(DamageRF.InvokeServer,DamageRF,part,9999)
									break
								end
							end
						end
						lastChoppedTree=best
					end
				end
			end
		end
		task.wait(CFG.Delay)
	end
end)

------------------------------------------------------------------------
-- FLY
------------------------------------------------------------------------
local flyConn=nil
local flyBodyVelocity=nil
local flyBodyGyro=nil
local function startFly()
	local char=Player.Character; local r2=root()
	if not char or not r2 then return end
	local bg=Instance.new("BodyGyro",r2)
	bg.MaxTorque=Vector3.new(4e5,4e5,4e5); bg.P=1e4; bg.D=1000
	flyBodyGyro=bg
	local bv=Instance.new("BodyVelocity",r2)
	bv.MaxForce=Vector3.new(1e4,1e4,1e4); bv.Velocity=Vector3.zero
	flyBodyVelocity=bv
	flyConn=RunService.Heartbeat:Connect(function()
		if not CFG.Fly then return end
		local cam=workspace.CurrentCamera
		local dir=Vector3.zero
		if UIS:IsKeyDown(Enum.KeyCode.W) then dir+=cam.CFrame.LookVector end
		if UIS:IsKeyDown(Enum.KeyCode.S) then dir-=cam.CFrame.LookVector end
		if UIS:IsKeyDown(Enum.KeyCode.A) then dir-=cam.CFrame.RightVector end
		if UIS:IsKeyDown(Enum.KeyCode.D) then dir+=cam.CFrame.RightVector end
		if UIS:IsKeyDown(Enum.KeyCode.Space) then dir+=Vector3.new(0,1,0) end
		if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then dir-=Vector3.new(0,1,0) end
		if dir.Magnitude>0 then dir=dir.Unit end
		bv.Velocity=dir*CFG.FlySpeed
		bg.CFrame=cam.CFrame
	end)
end
local function stopFly()
	if flyConn then flyConn:Disconnect(); flyConn=nil end
	if flyBodyVelocity then flyBodyVelocity:Destroy(); flyBodyVelocity=nil end
	if flyBodyGyro then flyBodyGyro:Destroy(); flyBodyGyro=nil end
end

------------------------------------------------------------------------
-- NOCLIP
------------------------------------------------------------------------
local noclipConn=nil
local function restoreNoclip()
	if noclipConn then noclipConn:Disconnect(); noclipConn=nil end
	local char=Player.Character
	if not char then return end
	for _,p in ipairs(char:GetDescendants()) do
		if p:IsA("BasePart") then p.CanCollide=true end
	end
end
RunService.Stepped:Connect(function()
	if not CFG.Noclip then return end
	local char=Player.Character
	if not char then return end
	for _,p in ipairs(char:GetDescendants()) do
		if p:IsA("BasePart") then p.CanCollide=false end
	end
end)

------------------------------------------------------------------------
-- SPEED / JUMP
------------------------------------------------------------------------
RunService.Heartbeat:Connect(function()
	local h2=hum()
	if not h2 then return end
	if CFG.Speed then h2.WalkSpeed=CFG.WalkSpeed end
	if CFG.Jump then h2.JumpPower=CFG.JumpPower end
end)

------------------------------------------------------------------------
-- FULLBRIGHT / FIX LAG / REVEAL MAP
------------------------------------------------------------------------
local origAmbient,origBrightness=Lighting.Ambient,Lighting.Brightness
local function setFullbright(state)
	if state then
		Lighting.Ambient=Color3.new(1,1,1)
		Lighting.Brightness=2
		Lighting.FogEnd=1e6
	else
		Lighting.Ambient=origAmbient
		Lighting.Brightness=origBrightness
	end
end
local function setFixLag(state)
	if state then
		for _,o in ipairs(Workspace:GetDescendants()) do
			if o:IsA("ParticleEmitter") or o:IsA("Trail") or o:IsA("Beam") then
				pcall(function() o.Enabled=false end)
			end
		end
	end
end
local function revealMap()
	if not MapRE then return end
	local cells={}
	for x=0,100 do for y=0,100 do table.insert(cells,Vector2.new(x,y)) end end
	for i=1,#cells,50 do
		local chunk={}
		for j=i,math.min(i+49,#cells) do table.insert(chunk,cells[j]) end
		pcall(MapRE.FireServer,MapRE,chunk)
		task.wait(0.1)
	end
end

------------------------------------------------------------------------
-- CONFLICT WARNING LABEL REFS
------------------------------------------------------------------------
local chopWarnLbl=nil
local function refreshChopCombatWarning()
	local bothOn=CFG.KillAura and CFG.AutoChop
	if chopWarnLbl then
		if bothOn then
			chopWarnLbl.Text="⚠️ Đang bật cả Kill Aura & Auto Chop!"
			chopWarnLbl.TextColor3=Color3.fromRGB(255,80,80)
		else
			chopWarnLbl.Text="✅ Không xung đột vũ khí"
			chopWarnLbl.TextColor3=Color3.fromRGB(80,230,120)
		end
	end
end

------------------------------------------------------------------------
-- =====================================================================
--                     BRIGHT CITRUS UI
-- =====================================================================
------------------------------------------------------------------------

local THEME = {
	-- Backgrounds
	Bg         = Color3.fromRGB(20, 22, 32),
	Panel      = Color3.fromRGB(28, 31, 46),
	Card       = Color3.fromRGB(34, 38, 56),
	-- Accents (citrus gradient stops)
	Accent1    = Color3.fromRGB(255, 180, 0),    -- amber
	Accent2    = Color3.fromRGB(255, 100, 30),   -- orange
	Accent3    = Color3.fromRGB(100, 220, 255),  -- cyan
	-- Tab active / inactive
	TabActive  = Color3.fromRGB(255, 160, 0),
	TabIdle    = Color3.fromRGB(50, 55, 80),
	-- Toggle
	ToggleOn   = Color3.fromRGB(80, 230, 130),
	ToggleOff  = Color3.fromRGB(80, 85, 110),
	Knob       = Color3.fromRGB(255, 255, 255),
	-- Text
	TextPrimary   = Color3.fromRGB(240, 240, 255),
	TextSecondary = Color3.fromRGB(160, 165, 200),
	TextLabel     = Color3.fromRGB(120, 125, 165),
	-- Section header
	SectionBg  = Color3.fromRGB(40, 44, 65),
	SectionTxt = Color3.fromRGB(255, 180, 0),
	-- Slider
	SliderFill = Color3.fromRGB(255, 150, 0),
	SliderBg   = Color3.fromRGB(50, 55, 80),
	-- Button
	BtnBg      = Color3.fromRGB(255, 130, 0),
	BtnHover   = Color3.fromRGB(255, 170, 40),
	BtnText    = Color3.fromRGB(20, 15, 5),
	-- Filter chip
	ChipOn     = Color3.fromRGB(80, 230, 130),
	ChipOff    = Color3.fromRGB(60, 65, 95),
	ChipText   = Color3.fromRGB(240, 240, 255),
}

local FONT_BOLD   = Enum.Font.GothamBold
local FONT_MED    = Enum.Font.Gotham
local FONT_LIGHT  = Enum.Font.Gotham
local CORNER = 8

local function corner(parent, radius)
	local c=Instance.new("UICorner",parent)
	c.CornerRadius=UDim.new(0, radius or CORNER)
	return c
end
local function pad(parent, top, right, bottom, left)
	local p=Instance.new("UIPadding",parent)
	p.PaddingTop=UDim.new(0,top or 6)
	p.PaddingRight=UDim.new(0,right or 8)
	p.PaddingBottom=UDim.new(0,bottom or 6)
	p.PaddingLeft=UDim.new(0,left or 8)
	return p
end
local function listLayout(parent, padding, fillDir)
	local l=Instance.new("UIListLayout",parent)
	l.FillDirection=fillDir or Enum.FillDirection.Vertical
	l.SortOrder=Enum.SortOrder.LayoutOrder
	l.Padding=UDim.new(0,padding or 4)
	return l
end
local function stroke(parent, color, thickness, transparency)
	local s=Instance.new("UIStroke",parent)
	s.Color=color or Color3.fromRGB(80,85,120)
	s.Thickness=thickness or 1
	s.Transparency=transparency or 0.6
	return s
end
local function label(parent, text, size, color, font, alignment)
	local l=Instance.new("TextLabel",parent)
	l.BackgroundTransparency=1
	l.Text=text or ""
	l.TextSize=size or 13
	l.TextColor3=color or THEME.TextPrimary
	l.Font=font or FONT_MED
	l.TextXAlignment=alignment or Enum.TextXAlignment.Left
	l.AutomaticSize=Enum.AutomaticSize.Y
	l.Size=UDim2.new(1,0,0,0)
	l.TextWrapped=true
	return l
end
local function tween(obj, props, t, style, dir)
	TweenService:Create(obj,
		TweenInfo.new(t or 0.18, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out),
		props
	):Play()
end

------------------------------------------------------------------------
-- ROOT GUI
------------------------------------------------------------------------
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "VbMenu"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function() ScreenGui.Parent=CoreGui end)
if not ScreenGui.Parent then ScreenGui.Parent=PlayerGui end

------------------------------------------------------------------------
-- OPEN/CLOSE TOGGLE BUTTON (top-left, draggable)
------------------------------------------------------------------------
local openBtn=Instance.new("TextButton",ScreenGui)
openBtn.Name="OpenBtn"
openBtn.Size=UDim2.new(0,110,0,34)
openBtn.Position=UDim2.new(0,14,0,14)
openBtn.BackgroundColor3=THEME.Accent1
openBtn.Text="✦ VB MENU"
openBtn.TextColor3=THEME.BtnText
openBtn.TextSize=13
openBtn.Font=FONT_BOLD
openBtn.AutoButtonColor=false
corner(openBtn,10)
stroke(openBtn,THEME.Accent2,1.5,0.3)

local openBtnGradient=Instance.new("UIGradient",openBtn)
openBtnGradient.Color=ColorSequence.new{
	ColorSequenceKeypoint.new(0,THEME.Accent1),
	ColorSequenceKeypoint.new(1,THEME.Accent2),
}
openBtnGradient.Rotation=90

-- drag openBtn
local draggingOB,dragStartOB,posStartOB=false,nil,nil
openBtn.InputBegan:Connect(function(inp)
	if inp.UserInputType==Enum.UserInputType.MouseButton1 then
		draggingOB=true
		dragStartOB=inp.Position
		posStartOB=openBtn.Position
	end
end)
openBtn.InputEnded:Connect(function(inp)
	if inp.UserInputType==Enum.UserInputType.MouseButton1 then draggingOB=false end
end)
UIS.InputChanged:Connect(function(inp)
	if draggingOB and inp.UserInputType==Enum.UserInputType.MouseMovement then
		local delta=inp.Position-dragStartOB
		openBtn.Position=UDim2.new(
			posStartOB.X.Scale, posStartOB.X.Offset+delta.X,
			posStartOB.Y.Scale, posStartOB.Y.Offset+delta.Y
		)
	end
end)

------------------------------------------------------------------------
-- MAIN WINDOW
------------------------------------------------------------------------
local MainFrame=Instance.new("Frame",ScreenGui)
MainFrame.Name="MainFrame"
MainFrame.Size=UDim2.new(0,480,0,560)
MainFrame.Position=UDim2.new(0.5,-240,0.5,-280)
MainFrame.BackgroundColor3=THEME.Bg
MainFrame.ClipsDescendants=true
MainFrame.Visible=false
corner(MainFrame,14)
stroke(MainFrame,THEME.Accent1,1.5,0.5)

-- Shadow
local shadow=Instance.new("ImageLabel",MainFrame)
shadow.Size=UDim2.new(1,40,1,40)
shadow.Position=UDim2.new(0,-20,0,-20)
shadow.BackgroundTransparency=1
shadow.Image="rbxassetid://6014261993"
shadow.ImageColor3=Color3.fromRGB(0,0,0)
shadow.ImageTransparency=0.5
shadow.ZIndex=-1
shadow.ScaleType=Enum.ScaleType.Slice
shadow.SliceCenter=Rect.new(49,49,450,450)

-- Gradient bar at top
local topBar=Instance.new("Frame",MainFrame)
topBar.Size=UDim2.new(1,0,0,46)
topBar.BackgroundColor3=THEME.Panel
topBar.BorderSizePixel=0
local topBarGrad=Instance.new("UIGradient",topBar)
topBarGrad.Color=ColorSequence.new{
	ColorSequenceKeypoint.new(0,Color3.fromRGB(255,170,0)),
	ColorSequenceKeypoint.new(0.5,Color3.fromRGB(255,90,30)),
	ColorSequenceKeypoint.new(1,Color3.fromRGB(80,180,255)),
}
topBarGrad.Rotation=90
topBarGrad.Transparency=NumberSequence.new{
	NumberSequenceKeypoint.new(0,0.3),
	NumberSequenceKeypoint.new(1,0.7),
}

-- Title
local titleLbl=Instance.new("TextLabel",topBar)
titleLbl.Size=UDim2.new(1,-50,1,0)
titleLbl.Position=UDim2.new(0,14,0,0)
titleLbl.BackgroundTransparency=1
titleLbl.Text="✦  VB MENU  ·  Citrus Edition"
titleLbl.TextColor3=THEME.TextPrimary
titleLbl.TextSize=14
titleLbl.Font=FONT_BOLD
titleLbl.TextXAlignment=Enum.TextXAlignment.Left

-- Accent dot
local accentDot=Instance.new("Frame",topBar)
accentDot.Size=UDim2.new(0,6,0,6)
accentDot.Position=UDim2.new(0,4,0.5,-3)
accentDot.BackgroundColor3=THEME.Accent1
corner(accentDot,10)

-- Close button
local closeBtn=Instance.new("TextButton",topBar)
closeBtn.Size=UDim2.new(0,30,0,30)
closeBtn.Position=UDim2.new(1,-38,0.5,-15)
closeBtn.BackgroundColor3=Color3.fromRGB(220,60,60)
closeBtn.Text="✕"
closeBtn.TextColor3=Color3.fromRGB(255,255,255)
closeBtn.TextSize=13
closeBtn.Font=FONT_BOLD
closeBtn.AutoButtonColor=false
corner(closeBtn,8)

-- Drag main window
local draggingMF,dragStartMF,posStartMF=false,nil,nil
topBar.InputBegan:Connect(function(inp)
	if inp.UserInputType==Enum.UserInputType.MouseButton1 then
		draggingMF=true; dragStartMF=inp.Position; posStartMF=MainFrame.Position
	end
end)
topBar.InputEnded:Connect(function(inp)
	if inp.UserInputType==Enum.UserInputType.MouseButton1 then draggingMF=false end
end)
UIS.InputChanged:Connect(function(inp)
	if draggingMF and inp.UserInputType==Enum.UserInputType.MouseMovement then
		local delta=inp.Position-dragStartMF
		MainFrame.Position=UDim2.new(
			posStartMF.X.Scale, posStartMF.X.Offset+delta.X,
			posStartMF.Y.Scale, posStartMF.Y.Offset+delta.Y
		)
	end
end)

-- Open/close logic
local menuOpen=false
local function setMenuVisible(state)
	menuOpen=state
	if state then
		MainFrame.Visible=true
		MainFrame.Size=UDim2.new(0,480,0,0)
		tween(MainFrame,{Size=UDim2.new(0,480,0,560)},0.22,Enum.EasingStyle.Back,Enum.EasingDirection.Out)
		openBtn.Text="✦ VB CLOSE"
	else
		tween(MainFrame,{Size=UDim2.new(0,480,0,0)},0.18)
		task.delay(0.2,function() MainFrame.Visible=false end)
		openBtn.Text="✦ VB MENU"
	end
end
openBtn.MouseButton1Click:Connect(function() setMenuVisible(not menuOpen) end)
closeBtn.MouseButton1Click:Connect(function() setMenuVisible(false) end)
closeBtn.MouseEnter:Connect(function() tween(closeBtn,{BackgroundColor3=Color3.fromRGB(255,80,80)},0.1) end)
closeBtn.MouseLeave:Connect(function() tween(closeBtn,{BackgroundColor3=Color3.fromRGB(220,60,60)},0.1) end)

------------------------------------------------------------------------
-- TAB BAR
------------------------------------------------------------------------
local tabBar=Instance.new("Frame",MainFrame)
tabBar.Size=UDim2.new(1,0,0,36)
tabBar.Position=UDim2.new(0,0,0,46)
tabBar.BackgroundColor3=THEME.Panel
tabBar.BorderSizePixel=0

local tabBarLayout=Instance.new("UIListLayout",tabBar)
tabBarLayout.FillDirection=Enum.FillDirection.Horizontal
tabBarLayout.SortOrder=Enum.SortOrder.LayoutOrder
tabBarLayout.Padding=UDim.new(0,2)
pad(tabBar,4,4,4,4)

-- Scroll container for content
local contentScroll=Instance.new("ScrollingFrame",MainFrame)
contentScroll.Size=UDim2.new(1,0,1,-82)
contentScroll.Position=UDim2.new(0,0,0,82)
contentScroll.BackgroundTransparency=1
contentScroll.ScrollBarThickness=4
contentScroll.ScrollBarImageColor3=THEME.Accent1
contentScroll.CanvasSize=UDim2.new(0,0,0,0)
contentScroll.AutomaticCanvasSize=Enum.AutomaticSize.Y
contentScroll.BorderSizePixel=0

local contentLayout=listLayout(contentScroll,0)
contentLayout.Padding=UDim.new(0,0)

------------------------------------------------------------------------
-- TAB SYSTEM
------------------------------------------------------------------------
local tabs={} -- {name, btn, page}
local activeTab=nil

local function switchTab(name)
	for _,t in ipairs(tabs) do
		if t.name==name then
			t.page.Visible=true
			tween(t.btn,{BackgroundColor3=THEME.TabActive,TextColor3=THEME.BtnText},0.12)
			activeTab=name
		else
			t.page.Visible=false
			tween(t.btn,{BackgroundColor3=THEME.TabIdle,TextColor3=THEME.TextSecondary},0.12)
		end
	end
end

local TAB_NAMES={"Chính","Di chuyển","Trẻ em","TP & Đồ","Cài đặt"}
local tabPages={}

for i,name in ipairs(TAB_NAMES) do
	-- Tab button
	local btn=Instance.new("TextButton",tabBar)
	btn.Size=UDim2.new(0,86,1,0)
	btn.BackgroundColor3=THEME.TabIdle
	btn.Text=name
	btn.TextColor3=THEME.TextSecondary
	btn.TextSize=11
	btn.Font=FONT_BOLD
	btn.AutoButtonColor=false
	btn.LayoutOrder=i
	corner(btn,6)

	-- Tab page
	local page=Instance.new("Frame",contentScroll)
	page.Size=UDim2.new(1,0,0,0)
	page.AutomaticSize=Enum.AutomaticSize.Y
	page.BackgroundTransparency=1
	page.Visible=(i==1)
	page.LayoutOrder=1
	local pageLayout=listLayout(page,8)
	pad(page,10,12,12,12)

	table.insert(tabs,{name=name,btn=btn,page=page})
	tabPages[name]=page

	btn.MouseButton1Click:Connect(function() switchTab(name) end)
end
switchTab("Chính")

------------------------------------------------------------------------
-- WIDGET HELPERS
------------------------------------------------------------------------
local function getPage(tabName)
	return tabPages[tabName]
end

local function addSection(page, title)
	local sFrame=Instance.new("Frame",page)
	sFrame.Size=UDim2.new(1,0,0,0)
	sFrame.AutomaticSize=Enum.AutomaticSize.Y
	sFrame.BackgroundColor3=THEME.SectionBg
	sFrame.LayoutOrder=999
	corner(sFrame,8)
	stroke(sFrame,THEME.Accent1,1,0.75)

	local sLayout=listLayout(sFrame,6)
	pad(sFrame,8,10,10,10)

	local sTitle=Instance.new("TextLabel",sFrame)
	sTitle.Size=UDim2.new(1,0,0,18)
	sTitle.BackgroundTransparency=1
	sTitle.Text="  "..title
	sTitle.TextColor3=THEME.SectionTxt
	sTitle.TextSize=11
	sTitle.Font=FONT_BOLD
	sTitle.TextXAlignment=Enum.TextXAlignment.Left
	sTitle.LayoutOrder=0

	-- thin accent line under header
	local line=Instance.new("Frame",sFrame)
	line.Size=UDim2.new(1,0,0,1)
	line.BackgroundColor3=THEME.Accent1
	line.BorderSizePixel=0
	line.LayoutOrder=1
	Instance.new("UIGradient",line).Transparency=NumberSequence.new{
		NumberSequenceKeypoint.new(0,0.2),NumberSequenceKeypoint.new(0.7,0.2),NumberSequenceKeypoint.new(1,1)
	}

	return sFrame, sLayout
end

local function addLabel(parent, text)
	local lbl=label(parent, text, 12, THEME.TextLabel, FONT_MED)
	lbl.LayoutOrder=999
	return lbl
end

local function addToggle(parent, text, default, callback)
	local row=Instance.new("Frame",parent)
	row.Size=UDim2.new(1,0,0,32)
	row.BackgroundTransparency=1
	row.LayoutOrder=999

	local lbl=Instance.new("TextLabel",row)
	lbl.Size=UDim2.new(1,-54,1,0)
	lbl.BackgroundTransparency=1
	lbl.Text=text
	lbl.TextColor3=THEME.TextPrimary
	lbl.TextSize=13
	lbl.Font=FONT_MED
	lbl.TextXAlignment=Enum.TextXAlignment.Left

	local track=Instance.new("Frame",row)
	track.Size=UDim2.new(0,46,0,24)
	track.Position=UDim2.new(1,-50,0.5,-12)
	track.BackgroundColor3=default and THEME.ToggleOn or THEME.ToggleOff
	corner(track,12)

	local knob=Instance.new("Frame",track)
	knob.Size=UDim2.new(0,18,0,18)
	knob.Position=default and UDim2.new(1,-21,0.5,-9) or UDim2.new(0,3,0.5,-9)
	knob.BackgroundColor3=THEME.Knob
	corner(knob,9)

	local state=default or false
	local btn=Instance.new("TextButton",row)
	btn.Size=UDim2.new(1,0,1,0)
	btn.BackgroundTransparency=1
	btn.Text=""
	btn.AutoButtonColor=false

	btn.MouseButton1Click:Connect(function()
		state=not state
		tween(track,{BackgroundColor3=state and THEME.ToggleOn or THEME.ToggleOff},0.14)
		tween(knob,{Position=state and UDim2.new(1,-21,0.5,-9) or UDim2.new(0,3,0.5,-9)},0.14,Enum.EasingStyle.Back)
		if callback then callback(state) end
	end)

	return row
end

local function addSlider(parent, text, min, max, default, callback)
	local container=Instance.new("Frame",parent)
	container.Size=UDim2.new(1,0,0,46)
	container.BackgroundTransparency=1
	container.LayoutOrder=999

	local topRow=Instance.new("Frame",container)
	topRow.Size=UDim2.new(1,0,0,18)
	topRow.BackgroundTransparency=1

	local lbl=Instance.new("TextLabel",topRow)
	lbl.Size=UDim2.new(1,-50,1,0)
	lbl.BackgroundTransparency=1
	lbl.Text=text
	lbl.TextColor3=THEME.TextPrimary
	lbl.TextSize=12
	lbl.Font=FONT_MED
	lbl.TextXAlignment=Enum.TextXAlignment.Left

	local valLbl=Instance.new("TextLabel",topRow)
	valLbl.Size=UDim2.new(0,48,1,0)
	valLbl.Position=UDim2.new(1,-48,0,0)
	valLbl.BackgroundTransparency=1
	valLbl.Text=tostring(default)
	valLbl.TextColor3=THEME.Accent1
	valLbl.TextSize=12
	valLbl.Font=FONT_BOLD
	valLbl.TextXAlignment=Enum.TextXAlignment.Right

	local track=Instance.new("Frame",container)
	track.Size=UDim2.new(1,0,0,8)
	track.Position=UDim2.new(0,0,0,26)
	track.BackgroundColor3=THEME.SliderBg
	corner(track,4)

	local fill=Instance.new("Frame",track)
	fill.Size=UDim2.new((default-min)/(max-min),0,1,0)
	fill.BackgroundColor3=THEME.SliderFill
	fill.BorderSizePixel=0
	corner(fill,4)
	Instance.new("UIGradient",fill).Color=ColorSequence.new{
		ColorSequenceKeypoint.new(0,THEME.Accent1),
		ColorSequenceKeypoint.new(1,THEME.Accent2),
	}

	local handle=Instance.new("Frame",track)
	handle.Size=UDim2.new(0,14,0,14)
	handle.Position=UDim2.new((default-min)/(max-min),0,0.5,-7)
	handle.BackgroundColor3=THEME.Knob
	corner(handle,7)
	stroke(handle,THEME.Accent1,1.5,0.3)

	local value=default
	local dragging=false

	local hitbox=Instance.new("TextButton",track)
	hitbox.Size=UDim2.new(1,0,0,22)
	hitbox.Position=UDim2.new(0,0,0.5,-11)
	hitbox.BackgroundTransparency=1
	hitbox.Text=""

	local function updateSlider(inputPos)
		local relX=math.clamp(inputPos.X-track.AbsolutePosition.X, 0, track.AbsoluteSize.X)
		local pct=relX/track.AbsoluteSize.X
		value=math.floor(min+(max-min)*pct+0.5)
		valLbl.Text=tostring(value)
		fill.Size=UDim2.new(pct,0,1,0)
		handle.Position=UDim2.new(pct,0,0.5,-7)
		if callback then callback(value) end
	end

	hitbox.InputBegan:Connect(function(inp)
		if inp.UserInputType==Enum.UserInputType.MouseButton1 then
			dragging=true; updateSlider(inp.Position)
		end
	end)
	hitbox.InputEnded:Connect(function(inp)
		if inp.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end
	end)
	UIS.InputChanged:Connect(function(inp)
		if dragging and inp.UserInputType==Enum.UserInputType.MouseMovement then
			updateSlider(inp.Position)
		end
	end)

	return container
end

local function addButton(parent, text, callback)
	local btn=Instance.new("TextButton",parent)
	btn.Size=UDim2.new(1,0,0,32)
	btn.BackgroundColor3=THEME.BtnBg
	btn.Text=text
	btn.TextColor3=THEME.BtnText
	btn.TextSize=12
	btn.Font=FONT_BOLD
	btn.AutoButtonColor=false
	btn.LayoutOrder=999
	corner(btn,8)
	Instance.new("UIGradient",btn).Color=ColorSequence.new{
		ColorSequenceKeypoint.new(0,THEME.Accent1),
		ColorSequenceKeypoint.new(1,THEME.Accent2),
	}
	btn.MouseEnter:Connect(function() tween(btn,{BackgroundColor3=THEME.BtnHover},0.1) end)
	btn.MouseLeave:Connect(function() tween(btn,{BackgroundColor3=THEME.BtnBg},0.1) end)
	btn.MouseButton1Click:Connect(function()
		tween(btn,{BackgroundColor3=Color3.fromRGB(255,255,180)},0.07)
		task.delay(0.1,function() tween(btn,{BackgroundColor3=THEME.BtnBg},0.12) end)
		if callback then callback() end
	end)
	return btn
end

local function addItemFilterTable(parent, title, items, allowedTable)
	local hdr=addLabel(parent, title)
	hdr.TextColor3=THEME.Accent3
	hdr.TextSize=12
	hdr.Font=FONT_BOLD
	hdr.LayoutOrder=999

	local grid=Instance.new("Frame",parent)
	grid.Size=UDim2.new(1,0,0,0)
	grid.AutomaticSize=Enum.AutomaticSize.Y
	grid.BackgroundTransparency=1
	grid.LayoutOrder=999
	local gl=Instance.new("UIGridLayout",grid)
	gl.CellSize=UDim2.new(0.5,-4,0,28)
	gl.CellPadding=UDim2.new(0,4,0,4)
	gl.SortOrder=Enum.SortOrder.LayoutOrder

	for i,itemName in ipairs(items) do
		local chip=Instance.new("TextButton",grid)
		chip.Size=UDim2.new(1,0,0,28)
		chip.BackgroundColor3=allowedTable[itemName] and THEME.ChipOn or THEME.ChipOff
		chip.Text=(allowedTable[itemName] and "✔ " or "✘ ")..itemName
		chip.TextColor3=THEME.ChipText
		chip.TextSize=11
		chip.Font=FONT_MED
		chip.AutoButtonColor=false
		chip.LayoutOrder=i
		corner(chip,6)
		chip.MouseButton1Click:Connect(function()
			allowedTable[itemName]=not allowedTable[itemName]
			chip.BackgroundColor3=allowedTable[itemName] and THEME.ChipOn or THEME.ChipOff
			chip.Text=(allowedTable[itemName] and "✔ " or "✘ ")..itemName
		end)
	end
	return grid
end

------------------------------------------------------------------------
-- =====================================================================
--                         BUILD TABS
-- =====================================================================
------------------------------------------------------------------------

------------------------------------------------------------------------
-- TAB 1: CHÍNH
------------------------------------------------------------------------
do
	local page=getPage("Chính")

	-- COMBAT & FARM
	local sFrame,_=addSection(page,"COMBAT & FARM")
	local tool=getKillTool(); local chopTool=getChopTool()
	addLabel(sFrame,"🗡 Vũ khí: "..(tool and tool.Name or "Không có").." | 🪓 Rìu: "..(chopTool and chopTool.Name or "Không có"))

	addToggle(sFrame,"Kill Aura",CFG.KillAura,function(v)
		CFG.KillAura=v; refreshChopCombatWarning()
	end)
	addSlider(sFrame,"Kill Radius",10,500,CFG.KillRadius,function(v) CFG.KillRadius=v end)
	addToggle(sFrame,"TP Auto Chop (Chặt gãy mới đổi)",CFG.AutoChop,function(v)
		CFG.AutoChop=v; refreshChopCombatWarning()
	end)
	addSlider(sFrame,"Chop Radius",10,500,CFG.ChopRadius,function(v) CFG.ChopRadius=v end)

	chopWarnLbl=addLabel(sFrame,"✅ Không xung đột vũ khí")
	chopWarnLbl.TextColor3=THEME.ToggleOn
	addSlider(sFrame,"Delay (x10ms)",5,60,math.floor(CFG.Delay*100),function(v) CFG.Delay=v/100 end)

	-- RƯƠNG & ĐẠN & XU
	local s2,_=addSection(page,"RƯƠNG, ĐẠN & ĐỒNG XU")
	addToggle(s2,"Mở rương (2-3/lần, 1 đồ/rương)",CFG.AutoChestAndLoot,function(v)
		CFG.AutoChestAndLoot=v
		if v then task.spawn(function() refreshAmmoCache(true) end)
		else updateChestLootStatus(string.format("Tắt · Rương: %d | Đồ: %d | Đạn: %d",totalChestsOpened,totalItemsLooted,totalAmmoCollected)) end
	end)
	chestLootStatusLbl=addLabel(s2,chestLootStatusText)
	addToggle(s2,"Tự động nhặt toàn bộ xu",CFG.AutoCollectCoins,function(v)
		CFG.AutoCollectCoins=v
		if v then task.spawn(collectAllCoinsOnce)
		else updateCoinStatus("Tắt (Tổng: "..totalCollectedCoins..")") end
	end)
	coinStatusLbl=addLabel(s2,coinStatusText)

	-- SINH TỒN & TRỒNG CÂY
	local s3,_=addSection(page,"SINH TỒN & TRỒNG CÂY")
	addToggle(s3,"🛡️ God Mode (Bất tử / Khóa máu)",CFG.GodMode,function(v) setGodMode(v) end)
	addToggle(s3,"Auto Eat Carrot",CFG.AutoEat,function(v)
		CFG.AutoEat=v
		if not v then updateEatStatus("Tắt") end
	end)
	eatStatusLbl=addLabel(s3,eatStatusText)
	local plantLbl=addLabel(s3,"Đứng chỗ trồng → bấm nút")
	addButton(s3,"🌱 Trồng tất cả mầm cây",function()
		task.spawn(function() plantAllSaplings(plantLbl) end)
	end)
end

------------------------------------------------------------------------
-- TAB 2: DI CHUYỂN
------------------------------------------------------------------------
do
	local page=getPage("Di chuyển")

	local s1,_=addSection(page,"MOVEMENT")
	addToggle(s1,"Speed",CFG.Speed,function(v)
		CFG.Speed=v
		if not v then local h2=hum(); if h2 then h2.WalkSpeed=16 end end
	end)
	addSlider(s1,"Walk Speed",16,300,CFG.WalkSpeed,function(v) CFG.WalkSpeed=v end)
	addToggle(s1,"High Jump",CFG.Jump,function(v)
		CFG.Jump=v
		if not v then local h2=hum(); if h2 then h2.JumpPower=50 end end
	end)
	addSlider(s1,"Jump Power",50,500,CFG.JumpPower,function(v) CFG.JumpPower=v end)
	addToggle(s1,"Fly",CFG.Fly,function(v)
		CFG.Fly=v
		if v then startFly() else stopFly() end
	end)
	addSlider(s1,"Fly Speed",10,200,CFG.FlySpeed,function(v) CFG.FlySpeed=v end)
	addToggle(s1,"Noclip",CFG.Noclip,function(v)
		CFG.Noclip=v
		if not v then restoreNoclip() end
	end)
end

------------------------------------------------------------------------
-- TAB 3: TRẺ EM
------------------------------------------------------------------------
do
	local page=getPage("Trẻ em")

	local s1,_=addSection(page,"AUTO CỨU TRẺ VỀ LỬA TRẠI")
	local sack=getSackTool()
	addLabel(s1,"🎒 Túi hiện tại: "..(sack and sack.Name or "Chưa có túi"))
	addToggle(s1,"Auto cứu trẻ (TP → Balo → Lửa)",CFG.AutoRescueChild,function(v)
		CFG.AutoRescueChild=v
		if not v then updateRescueStatus(string.format("Tắt · Đã cứu: %d",totalChildrenSaved)) end
	end)
	rescueStatusLbl=addLabel(s1,rescueStatusText)
	addButton(s1,"🔄 Reset danh sách trẻ đã cứu",function()
		rescuedChildren=setmetatable({},{__mode="k"})
		rescuedChildKeys={}
		updateRescueStatus("🔄 Đã reset danh sách")
	end)

	local s2,_=addSection(page,"ESP & TP THỦ CÔNG")
	addToggle(s2,"ESP Trẻ em",CFG.ESPChild,function(v)
		CFG.ESPChild=v
		if not v then clearESPChild() end
	end)

	local r2=root()
	local list={}
	for m,_ in pairs(childSet) do
		if m and m.Parent then
			local p=partOf(m)
			if p then
				local d=r2 and math.floor((p.Position-r2.Position).Magnitude) or 0
				table.insert(list,{m=m,p=p,d=d})
			end
		end
	end
	table.sort(list,function(a,b) return a.d<b.d end)
	if #list==0 then
		addLabel(s2,"Không tìm thấy trẻ nào")
	else
		for i,item in ipairs(list) do
			addButton(s2,string.format("TP %d. %s (%d studs)",i,item.m.Name,item.d),function()
				tpTo(item.m)
			end)
		end
	end
end

------------------------------------------------------------------------
-- TAB 4: TP & ĐỒ
------------------------------------------------------------------------
do
	local page=getPage("TP & Đồ")

	local s1,_=addSection(page,"LỬA TRẠI & NHIÊN LIỆU")
	addButton(s1,"🔥 TP Lửa trại",tpCampfire)
	addToggle(s1,"Auto dồn nhiên liệu → Lửa",CFG.AutoDrop,function(v) CFG.AutoDrop=v end)
	addButton(s1,"🪵 Dồn nhiên liệu → Lửa ngay",function() task.spawn(dumpFuelToFire) end)
	addItemFilterTable(s1,"🔥 Vật phẩm TP về Lửa trại",FUEL_EXACT,FireAllowedItems)

	local s2,_=addSection(page,"SCRAPPER")
	addButton(s2,"📍 TP tới Scrapper",function()
		local sp,r2=getScrapperPart(),root()
		if sp and r2 then r2.CFrame=CFrame.new(sp.Position+Vector3.new(0,5,0)) end
	end)
	addToggle(s2,"Auto dồn nguyên liệu → Scrapper",CFG.AutoScrap,function(v) CFG.AutoScrap=v end)
	addButton(s2,"⚙️ Dồn nguyên liệu → Scrapper ngay",function() task.spawn(dumpScrapToScrapper) end)
	addItemFilterTable(s2,"⚙️ Vật phẩm TP về Scrapper",SCRAPPER_ITEMS,ScrapAllowedItems)

	local s3,_=addSection(page,"KÉO VẬT PHẨM VỀ NGƯỜI")
	addButton(s3,"🍎 Kéo thức ăn",function() task.spawn(function() pullAllExact(FOOD_ITEMS) end) end)
	addButton(s3,"⚙️ Kéo nguyên liệu (Log, Chair...)",function() task.spawn(function() pullAllExact(SCRAP_ITEMS) end) end)

	local s4,_=addSection(page,"NGƯỜI CHƠI")
	local r2=root()
	local hasOther=false
	for _,plr in ipairs(Players:GetPlayers()) do
		if plr~=Player then
			hasOther=true
			local pRoot=plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
			local dist=(r2 and pRoot) and math.floor((pRoot.Position-r2.Position).Magnitude) or 0
			addButton(s4,string.format("Kéo %s (%d studs)",plr.Name,dist),function()
				pullPlayerToMe(plr)
			end)
		end
	end
	if not hasOther then addLabel(s4,"Không có người chơi khác") end
end

------------------------------------------------------------------------
-- TAB 5: CÀI ĐẶT
------------------------------------------------------------------------
do
	local page=getPage("Cài đặt")

	local s1,_=addSection(page,"HIỆU NĂNG & ÁNH SÁNG")
	addToggle(s1,"Fix Lag Pro",CFG.FixLag,function(v) setFixLag(v) end)
	addToggle(s1,"Nhìn trong bóng tối (Fullbright)",CFG.Fullbright,function(v)
		CFG.Fullbright=v; setFullbright(v)
	end)

	local s2,_=addSection(page,"BẢN ĐỒ & GIAO DIỆN")
	addButton(s2,"🗺️ Reveal Map",function() task.spawn(revealMap) end)

	local s3,_=addSection(page,"THÔNG TIN")
	addLabel(s3,"VB Menu — Citrus Edition")
	addLabel(s3,"Toggles: RightShift để ẩn/hiện menu")

	-- Keyboard shortcut
	UIS.InputBegan:Connect(function(inp,gpe)
		if gpe then return end
		if inp.KeyCode==Enum.KeyCode.RightShift then
			setMenuVisible(not menuOpen)
		end
	end)
end

------------------------------------------------------------------------
print("================================")
print("  VB MENU — Citrus Edition LOADED ✓")
print("  RightShift → toggle menu")
print("================================")
