--[[
	VB MENU — MaldixAura Style
	Logic: 100% gốc từ SUNSET UI + OLLIE 99 NIGHTS
	UI: MaldixAura_V77 style — ImageLabel shadow, sidebar, scroll, mobile-first
]]

--======================================================
-- SERVICES
--======================================================
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
for _, name in ipairs({"OllieUI","OllieMenu","ollie_v9","SunsetUI","VbMenu","VbMaldix","MaldixAura_V77"}) do
	pcall(function() local g = PlayerGui:FindFirstChild(name); if g then g:Destroy() end end)
	pcall(function() local g = CoreGui:FindFirstChild(name);   if g then g:Destroy() end end)
end

--======================================================
-- REMOTES & GAME DATA
--======================================================
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
local HEAVY_AXES = { ["Strong Axe"]=true, ["Chainsaw"]=true, ["Admin Axe"]=true }
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
for _,v in ipairs(FUEL_EXACT)     do FireAllowedItems[v]  = true end
for _,v in ipairs(SCRAPPER_ITEMS) do ScrapAllowedItems[v] = true end

local MAX_KILL_PER_CYCLE = 6
local TOOL_SUFFIX = "11960515286"
local CHILD_KEY   = "Lost Child"

--======================================================
-- HELPERS (100% gốc)
--======================================================
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
	for _,item in ipairs(inv and inv:GetChildren() or {}) do if hasKey(item.Name,{"Sack","Bag"}) then return item end end
	for _,item in ipairs(char and char:GetChildren() or {}) do if hasKey(item.Name,{"Sack","Bag"}) then return item end end
	return nil
end
local function getNilByName(name)
	local out={}
	if not getnilinstances then return out end
	local ok,nilList=pcall(getnilinstances)
	if not ok or not nilList then return out end
	for _,obj in ipairs(nilList) do
		local ok2,n=pcall(function() return obj.Name end)
		if ok2 and n==name then table.insert(out,obj) end
	end
	return out
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
			local p=partOf(o); if p then cachedFirePart=p; return p end
		end
	end
	return nil
end

local cachedScrapperPart=nil
local function getScrapperPart()
	if cachedScrapperPart and cachedScrapperPart.Parent then return cachedScrapperPart end
	local map=Workspace:FindFirstChild("Map")
	local obj=(map and map:FindFirstChild("Scrapper",true)) or Workspace:FindFirstChild("Scrapper",true)
	cachedScrapperPart=obj and partOf(obj) or nil
	return cachedScrapperPart
end

--======================================================
-- GOD MODE (100% gốc)
--======================================================
local godCharConns={}
local function clearGodConns()
	for _,conn in ipairs(godCharConns) do pcall(function() conn:Disconnect() end) end
	godCharConns={}
end
local function bindGodModeToChar(char)
	clearGodConns(); if not char then return end
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
		table.insert(godCharConns,c1); table.insert(godCharConns,c2)
	end
	local eh=char:FindFirstChildOfClass("Humanoid"); if eh then hookHum(eh) end
	local cAdd=char.ChildAdded:Connect(function(child) if child:IsA("Humanoid") then hookHum(child) end end)
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

--======================================================
-- CHILD CACHE (100% gốc)
--======================================================
local childSet={}
local function isChildModel(o) return o and o:IsA("Model") and string.find(o.Name,CHILD_KEY,1,true)~=nil end
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

--======================================================
-- AUTO RESCUE CHILDREN (100% gốc)
--======================================================
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
	local itemBag=Player:FindFirstChild("ItemBag"); if not itemBag then return nil end
	return itemBag:FindFirstChild(childName) or itemBag:FindFirstChild(CHILD_KEY) or itemBag:FindFirstChildWhichIsA("Model")
end
local function tpTo(m)
	local r,p=root(),partOf(m)
	if r and p then r.CFrame=CFrame.new(p.Position+Vector3.new(0,4,0)) end
end
local function rescueSingleChild(child)
	if not child or not child.Parent then return false end
	if not (BagStoreRF and BagDropRE) then updateRescueStatus("❌ Thiếu remote BagStore/BagDrop"); return false end
	local sack=getSackTool()
	if not sack then updateRescueStatus("❌ Không tìm thấy túi (Old Sack...)"); return false end
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
	updateRescueStatus("🔥 Đang TP về lửa trại...")
	r=root()
	if r and fp and fp.Parent then r.CFrame=CFrame.new(fp.Position+Vector3.new(0,4,3)) end
	task.wait(0.25)
	updateRescueStatus("📤 Đang thả trẻ tại lửa trại...")
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
			if nearestChild then
				pcall(rescueSingleChild,nearestChild)
			else
				updateRescueStatus(string.format("✅ Đã cứu hết trẻ · Tổng: %d",totalChildrenSaved))
			end
			task.wait(1.0)
		else task.wait(0.5) end
	end
end)

--======================================================
-- ESP CHILD (100% gốc)
--======================================================
local espTag={}
local function clearESPChild()
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
					local saved=isChildAlreadyRescued(m)
					local espColor=saved and Color3.fromRGB(100,255,130) or Color3.fromRGB(255,220,80)
					local hl=Instance.new("Highlight")
					hl.FillColor=espColor; hl.OutlineColor=espColor
					hl.FillTransparency=0.45; hl.Adornee=m; hl.Parent=m
					local adornPart=partOf(m)
					local bb,lblConn
					if adornPart then
						bb=Instance.new("BillboardGui")
						bb.Adornee=adornPart; bb.Size=UDim2.new(0,170,0,46)
						bb.StudsOffset=Vector3.new(0,3,0); bb.AlwaysOnTop=true; bb.Parent=adornPart
						local lbl=Instance.new("TextLabel")
						lbl.Size=UDim2.new(1,0,1,0); lbl.BackgroundTransparency=1
						lbl.TextColor3=espColor; lbl.TextStrokeColor3=Color3.new(0,0,0)
						lbl.TextStrokeTransparency=0.3; lbl.Font=Enum.Font.GothamBold
						lbl.TextSize=13; lbl.Parent=bb
						lblConn=RunService.Heartbeat:Connect(function()
							if not m.Parent or not CFG.ESPChild then lblConn:Disconnect(); return end
							local rr=root(); local pp=partOf(m)
							local statusTag=isChildAlreadyRescued(m) and " [Đã cứu]" or ""
							if rr and pp then
								local dist=math.floor((pp.Position-rr.Position).Magnitude)
								lbl.Text=m.Name..statusTag.."\n📍 "..dist.." studs"
							else lbl.Text=m.Name..statusTag end
						end)
					end
					espTag[m]={hl=hl,bb=bb,conn=lblConn}
				end
			end
		else
			if next(espTag) then clearESPChild() end
		end
	end
end)

--======================================================
-- CHEST / AMMO / COINS (100% gốc)
--======================================================
local chestLootStatusText="Chờ bật tự động mở & nhặt rương..."
local chestLootStatusLbl=nil
local coinStatusText="Chờ bật tự động nhặt xu..."
local coinStatusLbl=nil
local totalChestsOpened,totalItemsLooted,totalAmmoCollected,totalCollectedCoins=0,0,0,0

local function updateChestLootStatus(txt)
	chestLootStatusText=txt
	if chestLootStatusLbl and chestLootStatusLbl.Parent then chestLootStatusLbl.Text=txt end
end
local function updateCoinStatus(txt)
	coinStatusText=txt
	if coinStatusLbl and coinStatusLbl.Parent then coinStatusLbl.Text=txt end
end

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
	local list=refreshAmmoCache(false); if #list==0 then return 0 end
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
local function setItemPosition(item,goalCF)
	if item:IsA("Model") then
		if not item.PrimaryPart then pcall(function() item.PrimaryPart=partOf(item) end) end
		if item.PrimaryPart then pcall(function() item:SetPrimaryPartCFrame(goalCF) end)
		else pcall(function() item:PivotTo(goalCF) end) end
	elseif item:IsA("BasePart") then pcall(function() item.CFrame=goalCF end)
	elseif item:IsA("Tool") then
		local h=item:FindFirstChild("Handle"); if h then pcall(function() h.CFrame=goalCF end) end
	end
end
local function moveItemTo(item,worldPos)
	if not (DragRE and StopDragRE and item and item.Parent) then return false end
	pcall(DragRE.FireServer,DragRE,item)
	setItemPosition(item,CFrame.new(worldPos))
	task.wait(0.05)
	pcall(StopDragRE.FireServer,StopDragRE,item)
	return true
end
local function moveItemBesideChest(item,chest)
	local cp=partOf(chest); if not cp then return false end
	local a=math.random()*math.pi*2
	local pos=cp.Position+Vector3.new(math.cos(a)*3.5,2,math.sin(a)*3.5)
	return moveItemTo(item,pos)
end

local Filter={}
Filter.wanted={}
local CHEST_WANTED_LIST={
	"Bandage","Good Sack","Good Axe","Old Flashlight","Spear","Revolver","Fuel Canister",
	"Leather Body","Rifle","Strong Flashlight","Defensive Blueprint Spikes",
	"Iron Body","Strong Axe","Giant Sack","Medkit","Oil Barrel",
	"Morningstar","Dynamite","Impact Grenade","Bear Trap","Ammo Crate Recipe Tablet","Cultist Gem",
	"Chainsaw","Kunai","Thorn Armor","Throwing Knives",
	"Raygun","Laser Sword","Laser Cannon","Alien Armor","Laser Fence Blueprint",
	"Diamond","Diamonds",
}
for _,n in ipairs(CHEST_WANTED_LIST) do Filter.wanted[n]=true end
for _,n in ipairs(AXES) do Filter.wanted[n]=true end
for _,n in ipairs(MELEE_WEAPONS) do Filter.wanted[n]=true end
for _,n in ipairs(SACK_NAMES) do Filter.wanted[n]=true end

local function hasItemInBackpack(name)
	local inv=Player:FindFirstChild("Inventory")
	if inv and inv:FindFirstChild(name) then return true end
	local ch=Player.Character
	if ch and ch:FindFirstChild(name) then return true end
	local bag=Player:FindFirstChild("ItemBag")
	if bag and bag:FindFirstChild(name) then return true end
	return false
end
local function scanLootAtChestPos(chestPos,targetChest,now)
	local excludeList={targetChest}
	if Player.Character then table.insert(excludeList,Player.Character) end
	overlapParams.FilterDescendantsInstances=excludeList
	local nearbyParts=Workspace:GetPartBoundsInRadius(chestPos,CHEST_LOOT_RADIUS,overlapParams)
	local out,seen={},{}
	for _,part in ipairs(nearbyParts) do
		local candidate=part:FindFirstAncestorOfClass("Tool") or part:FindFirstAncestorOfClass("Model") or part
		if candidate and not seen[candidate] then
			seen[candidate]=true
			if not isLootSkipped(candidate,now) and isValidChestLoot(candidate,targetChest) then
				local p=partOf(candidate)
				local dist=p and (p.Position-chestPos).Magnitude or CHEST_LOOT_RADIUS
				table.insert(out,{obj=candidate,dist=dist})
			end
		end
	end
	table.sort(out,function(a,b) return a.dist<b.dist end)
	local sortedItems={}
	for i=1,#out do sortedItems[i]=out[i].obj end
	return sortedItems
end
local function tryLootSingleItem(item)
	if not HotbarItemRF then return false end
	local inv=Player:FindFirstChild("Inventory")
	local beforeCount=inv and #inv:GetChildren() or 0
	local done,ok,res=false,false,nil
	task.spawn(function() ok,res=pcall(HotbarItemRF.InvokeServer,HotbarItemRF,item); done=true end)
	local timeout=0
	while not done and timeout<0.5 do task.wait(0.05); timeout+=0.05 end
	if not done or not ok or res==false then return false end
	local nowInInv=(inv and item.Parent==inv) or (item.Parent==Player.Character)
	local afterCount=inv and #inv:GetChildren() or 0
	return nowInInv or afterCount>beforeCount or not item.Parent
end
local function openSingleChest(chest)
	if not OpenChestRE or not chest or not chest.Parent then return false end
	local ok=pcall(OpenChestRE.FireServer,OpenChestRE,chest)
	return ok==true
end
local function lootOneItemAtChest(chest,chestPos)
	local items=scanLootAtChestPos(chestPos,chest,os.clock())
	if #items==0 then return "empty" end
	local result="skip"
	for _,item in ipairs(items) do
		local name=item.Name
		if not Filter.wanted[name] then
			lootedItems[item]=true
		elseif hasItemInBackpack(name) then
			lootedItems[item]=true
			moveItemBesideChest(item,chest)
			result="dup"
		else
			if tryLootSingleItem(item) then
				lootedItems[item]=true; totalItemsLooted+=1; return "picked"
			else failedLootAt[item]=os.clock() end
		end
	end
	return result
end
local function getAvailableChests(now)
	local r=root(); local rPos=r and r.Position; local list={}
	for chest in pairs(cachedChests) do
		if not isChestSkipped(chest,now) then
			local p=partOf(chest)
			if p then
				local d=rPos and (p.Position-rPos).Magnitude or 0
				table.insert(list,{chest=chest,pos=p.Position,dist=d})
			end
		end
	end
	table.sort(list,function(a,b) return a.dist<b.dist end)
	return list
end
local function processChestCycle()
	if not OpenChestRE then updateChestLootStatus("❌ Thiếu remote RequestOpenItemChest"); return end
	if not HotbarItemRF then updateChestLootStatus("❌ Thiếu remote RequestHotbarItem"); return end
	initChestCache()
	local list=getAvailableChests(os.clock())
	if #list==0 then
		local ammoGot=collectScannedAmmo()
		updateChestLootStatus(string.format("✅ Hết rương · Rương: %d | Đồ: %d | Đạn: %d (+%d)",totalChestsOpened,totalItemsLooted,totalAmmoCollected,ammoGot))
		return
	end
	local want=math.random(CHESTS_MIN_PER_CYCLE,CHESTS_MAX_PER_CYCLE)
	local opened,picked,toFire=0,0,0
	for i=1,math.min(want,#list) do
		if not CFG.AutoChestAndLoot then break end
		local entry=list[i]; local chest=entry.chest
		if chest.Parent and not openedChestDone[chest] then
			updateChestLootStatus("📦 Đang mở: "..tostring(chest.Name))
			if openSingleChest(chest) then
				task.wait(CHEST_OPEN_DELAY)
				local p=partOf(chest); local pos=(p and p.Position) or entry.pos
				updateChestLootStatus("🎒 Đang xử lý đồ: "..tostring(chest.Name))
				local res=lootOneItemAtChest(chest,pos)
				openedChestDone[chest]=true; totalChestsOpened+=1; opened+=1
				if res=="picked" then picked+=1 elseif res=="dup" then toFire+=1 end
			else failedChestAt[chest]=os.clock() end
		end
	end
	local ammoGot=collectScannedAmmo()
	updateChestLootStatus(string.format("📦 Mở %d rương · Nhặt %d · Dời kế rương %d · Đạn +%d · Tổng: %d rương / %d đồ / %d đạn",opened,picked,toFire,ammoGot,totalChestsOpened,totalItemsLooted,totalAmmoCollected))
end
task.spawn(function()
	while true do
		if CFG.AutoChestAndLoot then pcall(processChestCycle); task.wait(CHEST_CYCLE_WAIT)
		else task.wait(0.5) end
	end
end)

local cachedCoins={}
local function isCoinObject(obj)
	if not obj then return false end
	local okName,name=pcall(function() return obj.Name end)
	return okName and hasKey(name,COIN_KEYS)
end
local coinCacheInitialized=false
local function initCoinCache()
	if coinCacheInitialized then return end; coinCacheInitialized=true
	local itemsFolder=Workspace:FindFirstChild("Items"); local targetRoot=itemsFolder or Workspace
	task.spawn(function()
		local all=targetRoot:GetDescendants()
		for i=1,#all do
			if isCoinObject(all[i]) then cachedCoins[all[i]]=true end
			if i%800==0 then task.wait() end
		end
	end)
	targetRoot.DescendantAdded:Connect(function(o) if isCoinObject(o) then cachedCoins[o]=true end end)
	targetRoot.DescendantRemoving:Connect(function(o) cachedCoins[o]=nil end)
end
local function collectAllCoinsOnce()
	if not CollectCoinRF then updateCoinStatus("❌ Thiếu remote RequestCollectCoints"); return 0 end
	initCoinCache()
	local toCollect={}
	for coin,_ in pairs(cachedCoins) do
		if coin and coin.Parent then table.insert(toCollect,coin) else cachedCoins[coin]=nil end
	end
	if getnilinstances then
		local ok,nilList=pcall(getnilinstances)
		if ok and nilList then
			for _,o in ipairs(nilList) do if isCoinObject(o) then table.insert(toCollect,o) end end
		end
	end
	local collected=0
	for _,coin in ipairs(toCollect) do
		if not CFG.AutoCollectCoins then break end
		local ok=pcall(CollectCoinRF.InvokeServer,CollectCoinRF,coin)
		if ok then cachedCoins[coin]=nil; collected+=1; totalCollectedCoins+=1 end
		task.wait(0.05)
	end
	updateCoinStatus(string.format("🪙 Đã nhặt +%d xu (Tổng: %d)",collected,totalCollectedCoins))
	return collected
end
task.spawn(function()
	while true do
		task.wait(1.2)
		if CFG.AutoCollectCoins then pcall(collectAllCoinsOnce) end
	end
end)

--======================================================
-- KILL AURA & TP AUTO CHOP (100% gốc)
--======================================================
local hitCounter=0
local lastEquippedChopTool=nil
local isChoppingNow=false
local function resetCounter() hitCounter=0; lastEquippedChopTool=nil; isChoppingNow=false end
Workspace.ChildAdded:Connect(function(c) if c.Name=="Map" then resetCounter(); cachedFirePart=nil end end)
Workspace.ChildRemoved:Connect(function(c) if c.Name=="Map" then resetCounter(); cachedFirePart=nil end end)
local function nextId() hitCounter+=1; return hitCounter.."_"..TOOL_SUFFIX end
local function fireWoodChopSound()
	local head=getHeadPart()
	if ReplicateSoundRE and head then
		pcall(ReplicateSoundRE.FireServer,ReplicateSoundRE,"FireAllClients","WoodChop",{Instance=head,Volume=0.4})
	end
end
local function isToolValid(tool)
	if not tool or not tool.Parent then return false end
	local inv=Player:FindFirstChild("Inventory"); local char=Player.Character
	return (inv and tool:IsDescendantOf(inv)) or (char and tool:IsDescendantOf(char))
end
local function isToolEquippedOnChar(tool)
	local char=Player.Character
	return char and tool and tool.Parent==char
end
local function hitOnce(tool,target,p)
	if not DamageRF or not target or not target.Parent or not p or not p.Parent then return false end
	if not isToolValid(tool) then return false end
	local ok=pcall(DamageRF.InvokeServer,DamageRF,target,tool,nextId(),CFrame.new(p.Position),false)
	if HitSoundRE and ok then pcall(HitSoundRE.FireServer,HitSoundRE,"FireAllClients",target,tool) end
	return ok==true
end
local function equipToolSafe(tool)
	if not (EquipRE and isToolValid(tool)) then return end
	if isToolEquippedOnChar(tool) then return end
	pcall(EquipRE.FireServer,EquipRE,"FireAllClients",tool); task.wait(0.06)
end
local function unequipToolSafe(tool)
	if not (UnequipRE and isToolValid(tool)) then return end
	if not isToolEquippedOnChar(tool) then return end
	pcall(UnequipRE.FireServer,UnequipRE,"FireAllClients",tool)
	if lastEquippedChopTool==tool then lastEquippedChopTool=nil end
	task.wait(0.05)
end
local function equipChopToolOnce(tool)
	if not (EquipRE and isToolValid(tool)) then return false end
	if isToolEquippedOnChar(tool) then lastEquippedChopTool=tool; return true end
	if lastEquippedChopTool~=tool or not isToolEquippedOnChar(tool) then
		pcall(EquipRE.FireServer,EquipRE,"FireAllClients",tool)
		lastEquippedChopTool=tool; task.wait(0.08)
	end
	return isToolValid(tool)
end
local function swingBatch(tool,targets)
	if not (EquipRE and UnequipRE and DamageRF) or #targets==0 then return end
	if not isToolValid(tool) then return end
	local sharedWithChop=isChoppingNow and (lastEquippedChopTool==tool)
	equipToolSafe(tool)
	local limit=math.min(#targets,MAX_KILL_PER_CYCLE)
	for i=1,limit do
		if not CFG.KillAura then break end
		local t=targets[i]
		if t.m and t.m.Parent and t.p and t.p.Parent then
			local h=t.m:FindFirstChildWhichIsA("Humanoid",true)
			if h and h.Health>0 then hitOnce(tool,t.m,t.p) end
		end
		if i<limit then task.wait(0.05) end
	end
	if not sharedWithChop and not CFG.AutoChop then unequipToolSafe(tool) end
end
local SCAN_FOLDERS={"Characters","Enemies","Mobs","NPCs"}
local function getAnimals(r)
	local out,ch,seen={},Player.Character,{}
	local maxDSq=CFG.KillRadius*CFG.KillRadius; local rPos=r.Position
	local function tryAdd(o)
		if seen[o] or o==ch or childSet[o] then return end
		seen[o]=true
		if Players:GetPlayerFromCharacter(o) then return end
		if string.find(o.Name,CHILD_KEY,1,true) then return end
		local h=o:FindFirstChildWhichIsA("Humanoid",true)
		if not (h and h.Health>0) then return end
		local p=partOf(o); if not p then return end
		local d=p.Position-rPos; local dSq=d.X*d.X+d.Y*d.Y+d.Z*d.Z
		if dSq<=maxDSq then table.insert(out,{m=o,p=p,dSq=dSq}) end
	end
	for _,o in ipairs(Workspace:GetChildren()) do if o:IsA("Model") then tryAdd(o) end end
	for _,fn in ipairs(SCAN_FOLDERS) do
		local folder=Workspace:FindFirstChild(fn)
		if folder then for _,o in ipairs(folder:GetChildren()) do if o:IsA("Model") then tryAdd(o) end end end
	end
	table.sort(out,function(a,b) return a.dSq<b.dSq end)
	return out
end
local skipTree={}
local function findNilEquivalent(targetName,targetDebugId)
	if not (targetName and targetDebugId and getnilinstances) then return nil end
	local okList,nilList=pcall(getnilinstances)
	if not okList or not nilList then return nil end
	for _,inst in ipairs(nilList) do
		local okN,n=pcall(function() return inst.Name end)
		local okD,d=pcall(function() return inst:GetDebugId() end)
		if okN and okD and n==targetName and d==targetDebugId then return inst end
	end
	return nil
end
local function isTreeBroken(treeModel,treePart)
	if not treeModel or not treeModel.Parent then return true end
	if not treePart or not treePart.Parent then return true end
	local hpAttr=treeModel:GetAttribute("Health") or treeModel:GetAttribute("HP")
	if type(hpAttr)=="number" and hpAttr<=0 then return true end
	local hpVal=treeModel:FindFirstChild("Health",true) or treeModel:FindFirstChild("HP",true)
	if hpVal and hpVal:IsA("ValueBase") and type(hpVal.Value)=="number" and hpVal.Value<=0 then return true end
	local h=treeModel:FindFirstChildWhichIsA("Humanoid",true)
	if h and h.Health<=0 then return true end
	if treePart:IsA("BasePart") and not treePart.Anchored then return true end
	return false
end
local function normalizeName(str) if type(str)~="string" then return "" end return string.lower(string.gsub(str,"%s+","")) end
local function isSmallTreeName(name) local n=normalizeName(name); return n=="smalltree" or string.find(n,"smalltree",1,true)~=nil end
local function isBigTreeName(name)
	local n=normalizeName(name)
	return n=="treebig1" or n=="treebig2" or string.find(n,"treebig1",1,true)~=nil or string.find(n,"treebig2",1,true)~=nil
end
local function canChopBigTree(tool) if not tool then return false end return HEAVY_AXES[tool.Name]==true end
local function classifyTree(treeModel)
	if not treeModel or not treeModel.Parent or not treeModel:IsA("Model") then return nil end
	local p=partOf(treeModel)
	if not p or isTreeBroken(treeModel,p) then return nil end
	if isSmallTreeName(treeModel.Name) then return "normal" end
	if isBigTreeName(treeModel.Name) then return "big" end
	return nil
end
local function getTrees(r,maxRadius,tool)
	local out={}
	local useLimit=type(maxRadius)=="number" and maxRadius>0
	local maxDSq=useLimit and (maxRadius*maxRadius) or math.huge
	local rPos=r.Position; local now=os.clock(); local allowBig=canChopBigTree(tool)
	local function tryAddTree(t)
		if skipTree[t] and now<skipTree[t] then return end
		local treeType=classifyTree(t); if not treeType then return end
		if treeType=="big" and not allowBig then return end
		local p=partOf(t); if not p then return end
		local d=p.Position-rPos; local dSq=d.X*d.X+d.Y*d.Y+d.Z*d.Z
		if dSq<=maxDSq then table.insert(out,{m=t,p=p,dSq=dSq,treeType=treeType}) end
	end
	local map=Workspace:FindFirstChild("Map")
	local folders={map and map:FindFirstChild("Foliage"),map and map:FindFirstChild("Trees"),Workspace:FindFirstChild("Foliage"),Workspace:FindFirstChild("Trees")}
	for _,folder in ipairs(folders) do if folder then for _,t in ipairs(folder:GetChildren()) do tryAddTree(t) end end end
	if #out==0 then local scanRoot=map or Workspace; for _,o in ipairs(scanRoot:GetDescendants()) do if o:IsA("Model") then tryAddTree(o) end end end
	table.sort(out,function(a,b) return a.dSq<b.dSq end)
	return out
end
local function spamChopDamageOnce(tool,treeModel,treePart,savedName,savedDebugId,fallbackPos)
	if not DamageRF or not isToolValid(tool) then return false end
	local actualTarget=(treeModel and treeModel.Parent) and treeModel or findNilEquivalent(savedName,savedDebugId)
	if not actualTarget then return false end
	local hitPos=(treePart and treePart.Parent) and treePart.Position or fallbackPos
	local rr=root(); local hitCF
	if rr and hitPos then local lookPos=Vector3.new(hitPos.X,rr.Position.Y,hitPos.Z); hitCF=CFrame.lookAt(hitPos,lookPos)
	elseif hitPos then hitCF=CFrame.new(hitPos) else hitCF=CFrame.new(0,0,0) end
	fireWoodChopSound()
	local ok=pcall(DamageRF.InvokeServer,DamageRF,actualTarget,tool,nextId(),hitCF,false)
	if HitSoundRE and ok then pcall(HitSoundRE.FireServer,HitSoundRE,"FireAllClients",actualTarget,tool) end
	return ok==true
end
local function tpToTreeAndChop(treeModel,treePart,initialTool)
	local r=root()
	if not (r and treeModel and treeModel.Parent and treePart and treePart.Parent) then return false end
	if not isToolValid(initialTool) then return false end
	local savedName=treeModel.Name
	local okDbg,savedDebugId=pcall(function() return treeModel:GetDebugId() end)
	if not okDbg then savedDebugId=nil end
	local targetPos=treePart.Position
	r.CFrame=CFrame.lookAt(targetPos+Vector3.new(0,2.5,-3),targetPos); task.wait(0.08)
	isChoppingNow=true; local lockedTool=initialTool
	if not equipChopToolOnce(lockedTool) then isChoppingNow=false; return false end
	local swings=0; local maxSwings=45; local failedHits=0
	local spamWait=math.min(math.max(CFG.Delay or 0.06,0.05),0.12)
	while CFG.AutoChop and not isTreeBroken(treeModel,treePart) and swings<maxSwings do
		local rr=root(); if not rr then break end
		if not isToolValid(lockedTool) then
			local fallback=getChopTool()
			if not isToolValid(fallback) then break end
			lockedTool=fallback; equipChopToolOnce(lockedTool)
		elseif not isToolEquippedOnChar(lockedTool) then equipChopToolOnce(lockedTool) end
		local curTreePos=(treePart and treePart.Parent) and treePart.Position or targetPos
		if (rr.Position-curTreePos).Magnitude>7 then rr.CFrame=CFrame.lookAt(curTreePos+Vector3.new(0,2.5,-3),curTreePos) end
		local hitOk=spamChopDamageOnce(lockedTool,treeModel,treePart,savedName,savedDebugId,curTreePos)
		if hitOk then failedHits=0 else failedHits+=1; if failedHits>=8 then break end end
		swings+=1; task.wait(spamWait)
	end
	isChoppingNow=false
	return isTreeBroken(treeModel,treePart)
end
task.spawn(function()
	while true do
		if CFG.KillAura then
			local r,tool=root(),getKillTool()
			if r and isToolValid(tool) then
				local targets=getAnimals(r)
				if #targets>0 then pcall(swingBatch,tool,targets) end
			end
			task.wait(CFG.Delay)
		else task.wait(0.25) end
	end
end)
task.spawn(function()
	while true do
		if CFG.AutoChop then
			local r,tool=root(),getChopTool()
			if r and isToolValid(tool) then
				local trees=getTrees(r,CFG.ChopRadius,tool)
				if #trees==0 then trees=getTrees(r,nil,tool) end
				if #trees>0 then
					local chosen=trees[1]; local broken=false
					pcall(function() broken=tpToTreeAndChop(chosen.m,chosen.p,tool) end)
					isChoppingNow=false
					if broken then skipTree[chosen.m]=os.clock()+60 else skipTree[chosen.m]=os.clock()+5 end
				end
			end
			task.wait(0.12)
		else isChoppingNow=false; lastEquippedChopTool=nil; task.wait(0.25) end
	end
end)

--======================================================
-- MOVEMENT, NOCLIP & FLY (100% gốc)
--======================================================
local noclipBackup={}
local function restoreNoclip()
	for part,wasCollide in pairs(noclipBackup) do
		if part and part.Parent and part:IsA("BasePart") then pcall(function() part.CanCollide=wasCollide end) end
	end
	noclipBackup={}
end
RunService.Heartbeat:Connect(function()
	local h=hum(); if not h then return end
	if CFG.Speed then h.WalkSpeed=CFG.WalkSpeed end
	if CFG.Jump then h.UseJumpPower=true; h.JumpPower=CFG.JumpPower end
end)
RunService.Stepped:Connect(function()
	local c=Player.Character; if not c then return end
	if CFG.Noclip then
		for _,obj in ipairs(c:GetDescendants()) do
			if obj:IsA("BasePart") then
				if noclipBackup[obj]==nil then noclipBackup[obj]=obj.CanCollide end
				if obj.CanCollide then obj.CanCollide=false end
			end
		end
	elseif next(noclipBackup) then restoreNoclip() end
end)

local flyBV,flyBG,flyConn
local padUp,padDown=false,false
local function stopFly()
	if flyConn then flyConn:Disconnect(); flyConn=nil end
	if flyBV and flyBV.Parent then flyBV:Destroy() end
	if flyBG and flyBG.Parent then flyBG:Destroy() end
	flyBV,flyBG=nil,nil
	local h=hum(); if h then h.PlatformStand=false end
end
local function startFly()
	stopFly()
	local r,h=root(),hum(); if not (r and h) then return end
	h.PlatformStand=true
	flyBV=Instance.new("BodyVelocity")
	flyBV.MaxForce=Vector3.new(1e6,1e6,1e6); flyBV.Velocity=Vector3.zero; flyBV.Parent=r
	flyBG=Instance.new("BodyGyro")
	flyBG.MaxTorque=Vector3.new(1e6,1e6,1e6); flyBG.P=1e4; flyBG.Parent=r
	flyConn=RunService.Heartbeat:Connect(function()
		local cam=Workspace.CurrentCamera; local rr,hh=root(),hum()
		if not (cam and rr and hh and flyBV and flyBV.Parent) then return end
		local md=hh.MoveDirection
		local camLook=cam.CFrame.LookVector; local camRight=cam.CFrame.RightVector
		local flatLook=Vector3.new(camLook.X,0,camLook.Z); local flatRight=Vector3.new(camRight.X,0,camRight.Z)
		if flatLook.Magnitude>0 then flatLook=flatLook.Unit end
		if flatRight.Magnitude>0 then flatRight=flatRight.Unit end
		local moveDir=flatLook*(-md.Z)+flatRight*md.X
		local vy=0
		if UIS:IsKeyDown(Enum.KeyCode.Space) or padUp then vy=1 end
		if UIS:IsKeyDown(Enum.KeyCode.LeftControl) or padDown then vy=-1 end
		flyBV.Velocity=moveDir*CFG.FlySpeed+Vector3.new(0,vy*CFG.FlySpeed,0)
		flyBG.CFrame=CFrame.new(rr.Position,rr.Position+flatLook)
	end)
end
Player.CharacterAdded:Connect(function(char)
	task.wait(0.5); resetCounter()
	if CFG.GodMode then bindGodModeToChar(char) end
	if CFG.Fly then startFly() end
end)

--======================================================
-- FULLBRIGHT & FIX LAG PRO (100% gốc)
--======================================================
local fbPrev,fbConn
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
		if fbPrev then
			Lighting.Brightness=fbPrev.B; Lighting.ClockTime=fbPrev.C; Lighting.FogEnd=fbPrev.F
			Lighting.Ambient=fbPrev.A; Lighting.OutdoorAmbient=fbPrev.OA; fbPrev=nil
		end
	end
end
local LagBackup={};local lagConn,lagGen=nil,0
local HEAVY_MATS={[Enum.Material.Neon]=Enum.Material.SmoothPlastic,[Enum.Material.Glass]=Enum.Material.SmoothPlastic,[Enum.Material.ForceField]=Enum.Material.SmoothPlastic,[Enum.Material.DiamondPlate]=Enum.Material.SmoothPlastic,[Enum.Material.CorrodedMetal]=Enum.Material.SmoothPlastic,[Enum.Material.Foil]=Enum.Material.SmoothPlastic,[Enum.Material.WoodPlanks]=Enum.Material.SmoothPlastic,[Enum.Material.Cobblestone]=Enum.Material.SmoothPlastic}
local function saveProp(obj,prop) local t=LagBackup[obj]; if not t then t={}; LagBackup[obj]=t end; if t[prop]==nil then local ok,val=pcall(function() return obj[prop] end); if ok then t[prop]=val end end end
local function optimizeObj(obj)
	if not CFG.FixLag or not obj or not obj.Parent then return end
	if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") or obj:IsA("PointLight") or obj:IsA("SpotLight") or obj:IsA("SurfaceLight") then
		saveProp(obj,"Enabled"); pcall(function() obj.Enabled=false end); return
	end
	if obj:IsA("BasePart") then
		saveProp(obj,"CastShadow"); pcall(function() obj.CastShadow=false end)
		saveProp(obj,"Material")
		local mat=HEAVY_MATS[obj.Material] or Enum.Material.Plastic
		if obj.Material~=mat then pcall(function() obj.Material=mat end) end
	end
end
local function setFixLag(v)
	if v then
		if CFG.FixLag then return end; CFG.FixLag=true; lagGen+=1; local gen=lagGen
		for _,prop in ipairs({"GlobalShadows","EnvironmentDiffuseScale","EnvironmentSpecularScale","ShadowSoftness"}) do saveProp(Lighting,prop) end
		pcall(function() Lighting.GlobalShadows=false; Lighting.EnvironmentDiffuseScale=0; Lighting.EnvironmentSpecularScale=0; Lighting.ShadowSoftness=0 end)
		if not lagConn then lagConn=Workspace.DescendantAdded:Connect(function(obj) if CFG.FixLag then task.defer(optimizeObj,obj) end end) end
		task.spawn(function()
			local all=Workspace:GetDescendants()
			for i=1,#all do if not CFG.FixLag or gen~=lagGen then return end; optimizeObj(all[i]); if i%500==0 then task.wait() end end
		end)
	else
		if not CFG.FixLag then return end; CFG.FixLag=false; lagGen+=1
		if lagConn then lagConn:Disconnect(); lagConn=nil end
		for obj,props in pairs(LagBackup) do if obj and obj.Parent then for prop,val in pairs(props) do pcall(function() obj[prop]=val end) end end end
		LagBackup={}
	end
end

--======================================================
-- AUTO EAT CARROT (100% gốc)
--======================================================
local eatStatusText="Chờ bật ăn carrot..."
local eatStatusLbl=nil
local function updateEatStatus(txt)
	eatStatusText=txt
	if eatStatusLbl and eatStatusLbl.Parent then eatStatusLbl.Text=txt end
end
task.spawn(function()
	while true do
		task.wait(2)
		if CFG.AutoEat then
			if not ConsumeRF then updateEatStatus("❌ Thiếu remote RequestConsumeItem"); continue end
			if not getnilinstances then updateEatStatus("❌ Executor thiếu getnilinstances"); continue end
			local carrots=getNilByName("Carrot")
			if #carrots==0 then updateEatStatus("⚠️ Không tìm thấy Carrot"); continue end
			local ate=0
			for _,carrot in ipairs(carrots) do
				if not CFG.AutoEat then break end
				local ok=pcall(ConsumeRF.InvokeServer,ConsumeRF,carrot)
				if ok then ate+=1; updateEatStatus(string.format("✅ Đã ăn %d carrot",ate)) end
				task.wait(0.3)
			end
		end
	end
end)

--======================================================
-- TP / PULL / FUEL / SCRAPPER / PLANT / MAP (100% gốc)
--======================================================
local function tpCampfire()
	local fp=getFirePart(); local r=root()
	if fp and r then r.CFrame=CFrame.new(fp.Position+Vector3.new(0,4,0)) end
end
local function pullPlayerToMe(plr)
	if not plr or plr==Player then return false end
	local r=root(); local targetRoot=plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
	if r and targetRoot then targetRoot.CFrame=r.CFrame*CFrame.new(0,1,-4); return true end
	return false
end
local function pullAllExact(nameList)
	local r=root(); if not r then return 0 end
	local ch=Player.Character; local found={}
	local itemsFolder=Workspace:FindFirstChild("Items")
	local searchList=itemsFolder and itemsFolder:GetDescendants() or Workspace:GetChildren()
	for _,o in ipairs(searchList) do
		if ch and o:IsDescendantOf(ch) then continue end
		if Players:GetPlayerFromCharacter(o) then continue end
		if (o:IsA("Model") or o:IsA("BasePart")) and matchesExact(o.Name,nameList) then
			local p=partOf(o); if p then local d=(p.Position-r.Position).Magnitude; table.insert(found,{obj=o,dist=d}) end
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
local droppedAt={}
local function dumpFuelToFire()
	local fp=getFirePart()
	if not (fp and DragRE and StopDragRE) then return 0 end
	local ch,count,seen=Player.Character,0,{}
	local itemsFolder=Workspace:FindFirstChild("Items")
	local searchList=itemsFolder and itemsFolder:GetDescendants() or Workspace:GetChildren()
	for _,o in ipairs(searchList) do
		if not o:IsA("Model") then continue end
		if seen[o] then continue end
		if ch and o:IsDescendantOf(ch) then continue end
		if Players:GetPlayerFromCharacter(o) then continue end
		if (droppedAt[o] or 0)+20>os.clock() then continue end
		if not FireAllowedItems[o.Name] then continue end
		seen[o]=true
		if not o.PrimaryPart then pcall(function() o.PrimaryPart=partOf(o) end) end
		if not o.PrimaryPart then continue end
		droppedAt[o]=os.clock()
		local offset=Vector3.new(math.random(-20,20)/10,7+count*0.4,math.random(-20,20)/10)
		pcall(DragRE.FireServer,DragRE,o)
		pcall(function() o:SetPrimaryPartCFrame(CFrame.new(fp.Position+offset)) end)
		task.wait(0.05); pcall(StopDragRE.FireServer,StopDragRE,o)
		count+=1; task.wait(0.1)
	end
	return count
end
task.spawn(function() while true do task.wait(5); if CFG.AutoDrop then pcall(dumpFuelToFire) end end end)
local scrapDroppedAt=setmetatable({},{__mode="k"})
local function dumpScrapToScrapper()
	local sp=getScrapperPart()
	if not (sp and DragRE and StopDragRE) then return 0 end
	local ch,count,seen=Player.Character,0,{}
	local itemsFolder=Workspace:FindFirstChild("Items")
	local searchList=itemsFolder and itemsFolder:GetDescendants() or Workspace:GetChildren()
	for _,o in ipairs(searchList) do
		if not o:IsA("Model") or seen[o] then continue end
		if ch and o:IsDescendantOf(ch) then continue end
		if Players:GetPlayerFromCharacter(o) then continue end
		if (scrapDroppedAt[o] or 0)+15>os.clock() then continue end
		if not ScrapAllowedItems[o.Name] then continue end
		seen[o]=true
		if not o.PrimaryPart then pcall(function() o.PrimaryPart=partOf(o) end) end
		if not o.PrimaryPart then continue end
		scrapDroppedAt[o]=os.clock()
		local offset=Vector3.new(math.random(-15,15)/10,6+count*0.4,math.random(-15,15)/10)
		pcall(DragRE.FireServer,DragRE,o)
		pcall(function() o:SetPrimaryPartCFrame(CFrame.new(sp.Position+offset)) end)
		task.wait(0.05); pcall(StopDragRE.FireServer,StopDragRE,o)
		count+=1; task.wait(0.1)
	end
	return count
end
task.spawn(function() while true do task.wait(4); if CFG.AutoScrap then pcall(dumpScrapToScrapper) end end end)
local function plantAllSaplings(statusLbl)
	local function setStatus(txt) if statusLbl and statusLbl.Parent then statusLbl.Text=txt end end
	if not PlantRE then setStatus("❌ Thiếu remote RequestPlantItem"); return 0 end
	if not getnilinstances then setStatus("❌ Executor thiếu getnilinstances"); return 0 end
	setStatus("🔍 Đang quét mầm cây...")
	local saplings=getNilByName("Sapling")
	if #saplings==0 then setStatus("⚠️ Không tìm thấy mầm cây nào"); return 0 end
	setStatus(string.format("🌱 Tìm thấy %d mầm — đang trồng...",#saplings))
	local r=root(); if not r then setStatus("❌ Không tìm thấy nhân vật"); return 0 end
	local basePos=r.CFrame.Position-Vector3.new(0,3,0); local count=0
	for _,sapling in ipairs(saplings) do
		local ok0=pcall(function() return sapling.Name end); if not ok0 then continue end
		local offset=Vector3.new(math.random(-3,3)/10,0,math.random(-3,3)/10)
		local ok2=pcall(PlantRE.InvokeServer,PlantRE,sapling,basePos+offset)
		if StopDragRE then pcall(StopDragRE.FireServer,StopDragRE,sapling) end
		if ok2 then count+=1 end; task.wait(0.15)
	end
	if count>0 then setStatus(string.format("✅ Đã trồng %d/%d mầm cây",count,#saplings))
	else setStatus("⚠️ Trồng thất bại — thử đứng sát đất") end
	return count
end
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

--======================================================
-- MOBILE FLY PAD (100% gốc)
--======================================================
local flyPad=Instance.new("Frame")
flyPad.Size=UDim2.fromOffset(60,124)
flyPad.Position=UDim2.new(1,-70,1,-132)
flyPad.BackgroundTransparency=1; flyPad.Visible=false
pcall(function() flyPad.Parent=CoreGui end)
if flyPad.Parent~=CoreGui then flyPad.Parent=PlayerGui end
local function holdBtn(yOff,text,onState)
	local b=Instance.new("TextButton")
	b.Size=UDim2.fromOffset(56,56); b.Position=UDim2.fromOffset(0,yOff)
	b.BackgroundColor3=Color3.fromRGB(15,15,20)
	b.Text=text; b.TextColor3=Color3.fromRGB(255,180,0)
	b.Font=Enum.Font.GothamBold; b.TextSize=20; b.Parent=flyPad
	Instance.new("UICorner",b).CornerRadius=UDim.new(1,0)
	local st=Instance.new("UIStroke",b); st.Color=Color3.fromRGB(255,180,0); st.Thickness=1.5
	b.MouseButton1Down:Connect(function() onState(true) end)
	b.MouseButton1Up:Connect(function() onState(false) end)
	b.MouseLeave:Connect(function() onState(false) end)
	b.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.Touch then onState(true) end end)
	b.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.Touch then onState(false) end end)
end
holdBtn(0,"▲",function(v) padUp=v end)
holdBtn(68,"▼",function(v) padDown=v end)

--======================================================
-- ============================================================
--   VB UI — MaldixAura V77 Style (Mobile-First)
--   ImageLabel shadow · sidebar · scroll · touch-friendly
-- ============================================================
--======================================================

local ACCENT   = Color3.fromRGB(255, 160, 0)
local BG_MAIN  = Color3.fromRGB(12, 12, 16)
local BG_INNER = Color3.fromRGB(18, 18, 24)
local BG_SIDE  = Color3.fromRGB(14, 14, 20)
local BG_SECT  = Color3.fromRGB(22, 22, 32)
local BG_ELEM  = Color3.fromRGB(26, 26, 38)
local TXT_ON   = Color3.fromRGB(240, 240, 255)
local TXT_DIM  = Color3.fromRGB(150, 150, 185)
local TXT_SECT = Color3.fromRGB(255, 160, 0)
local COL_ON   = Color3.fromRGB(80, 230, 110)
local COL_OFF  = Color3.fromRGB(55, 55, 80)
local COL_BTN  = Color3.fromRGB(255, 150, 0)
local COL_BTN2 = Color3.fromRGB(255, 100, 20)
local COL_CHIP_ON  = Color3.fromRGB(28, 70, 38)
local COL_CHIP_OFF = Color3.fromRGB(68, 28, 28)
local COL_CHIP_ON_TXT  = Color3.fromRGB(165,255,180)
local COL_CHIP_OFF_TXT = Color3.fromRGB(255,165,165)

local function mkCorner(p,r) local c=Instance.new("UICorner",p); c.CornerRadius=UDim.new(0,r or 8); return c end
local function mkStroke(p,col,th,tr) local s=Instance.new("UIStroke",p); s.Color=col or ACCENT; s.Thickness=th or 1; s.Transparency=tr or 0.5; return s end
local function tw(obj,props,t,st,dir)
	TweenService:Create(obj,TweenInfo.new(t or 0.15,st or Enum.EasingStyle.Quad,dir or Enum.EasingDirection.Out),props):Play()
end

-- Root ScreenGui
local AuraGui=Instance.new("ScreenGui")
AuraGui.Name="VbMaldix"; AuraGui.ResetOnSpawn=false; AuraGui.IgnoreGuiInset=true
pcall(function() AuraGui.Parent=CoreGui end)
if AuraGui.Parent~=CoreGui then AuraGui.Parent=PlayerGui end

-- Toggle button (draggable, like MaldixAura)
local toggleBtn=Instance.new("ImageButton",AuraGui)
toggleBtn.Size=UDim2.new(0,52,0,52)
toggleBtn.Position=UDim2.new(0,8,0.5,-26)
toggleBtn.BackgroundColor3=ACCENT
toggleBtn.Image="rbxassetid://97939372251102"
toggleBtn.ZIndex=20
mkCorner(toggleBtn,26)
mkStroke(toggleBtn,ACCENT,2,0.2)
-- glow ring
local ring=Instance.new("UIStroke",toggleBtn)
ring.Color=Color3.fromRGB(255,220,100); ring.Thickness=2; ring.Transparency=0.4

-- Main shadow ImageLabel (MaldixAura_V77 style)
local Main=Instance.new("ImageLabel",AuraGui)
Main.Name="Main"
Main.AnchorPoint=Vector2.new(0,0.5)
Main.Position=UDim2.new(0,70,0.5,0)
Main.Size=UDim2.new(0,0,0,0) -- opens from 0
Main.BackgroundTransparency=1
Main.Image="rbxassetid://1316045217"
Main.ImageColor3=Color3.fromRGB(0,0,0)
Main.ImageTransparency=0.3
Main.ScaleType=Enum.ScaleType.Slice
Main.SliceCenter=Rect.new(10,10,118,118)

-- Inner frame
local Inner=Instance.new("Frame",Main)
Inner.Size=UDim2.new(1,-16,1,-16)
Inner.Position=UDim2.new(0,8,0,8)
Inner.BackgroundColor3=BG_INNER
Inner.BorderSizePixel=0
mkCorner(Inner,10)

-- Sidebar
local Sidebar=Instance.new("Frame",Inner)
Sidebar.Size=UDim2.new(0,88,1,0)
Sidebar.BackgroundColor3=BG_SIDE
Sidebar.BorderSizePixel=0
mkCorner(Sidebar,10)
mkStroke(Sidebar,ACCENT,1,0.6)

-- Title in sidebar
local SideTitle=Instance.new("TextLabel",Sidebar)
SideTitle.Size=UDim2.new(1,0,0,38)
SideTitle.BackgroundTransparency=1
SideTitle.Text="VB"
SideTitle.TextColor3=ACCENT
SideTitle.TextSize=18
SideTitle.Font=Enum.Font.GothamBold
SideTitle.TextXAlignment=Enum.TextXAlignment.Center

-- Sidebar accent line
local sLine=Instance.new("Frame",Sidebar)
sLine.Size=UDim2.new(0.8,0,0,2)
sLine.Position=UDim2.new(0.1,0,0,36)
sLine.BackgroundColor3=ACCENT
sLine.BorderSizePixel=0
mkCorner(sLine,1)

-- Tab scroll in sidebar
local TabScroll=Instance.new("ScrollingFrame",Sidebar)
TabScroll.Size=UDim2.new(1,0,1,-42)
TabScroll.Position=UDim2.new(0,0,0,42)
TabScroll.BackgroundTransparency=1
TabScroll.ScrollBarThickness=0
TabScroll.CanvasSize=UDim2.new(0,0,0,0)
TabScroll.AutomaticCanvasSize=Enum.AutomaticSize.Y
local tabLayout=Instance.new("UIListLayout",TabScroll)
tabLayout.Padding=UDim.new(0,4)
tabLayout.SortOrder=Enum.SortOrder.LayoutOrder
tabLayout.HorizontalAlignment=Enum.HorizontalAlignment.Center
local tabPad=Instance.new("UIPadding",TabScroll)
tabPad.PaddingTop=UDim.new(0,4); tabPad.PaddingLeft=UDim.new(0,4); tabPad.PaddingRight=UDim.new(0,4); tabPad.PaddingBottom=UDim.new(0,4)

-- Content area
local Content=Instance.new("Frame",Inner)
Content.Size=UDim2.new(1,-96,1,-4)
Content.Position=UDim2.new(0,92,0,2)
Content.BackgroundTransparency=1

-- Tab management
local tabsList={}
local currentTabFrame=nil

local function switchTo(tabFrame, tabBtn)
	if currentTabFrame then currentTabFrame.Visible=false end
	currentTabFrame=tabFrame; tabFrame.Visible=true
	for _,td in ipairs(tabsList) do
		if td.frame==tabFrame then
			tw(td.btn,{BackgroundColor3=ACCENT,TextColor3=Color3.fromRGB(0,0,0)},0.12)
		else
			tw(td.btn,{BackgroundColor3=BG_ELEM,TextColor3=TXT_DIM},0.12)
		end
	end
end

-- Drag Main window
local draggingMain,dragStartMain,startPosMain=false,nil,nil
Inner.InputBegan:Connect(function(input)
	if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
		draggingMain=true; dragStartMain=input.Position; startPosMain=Main.Position
	end
end)
Inner.InputEnded:Connect(function(input)
	if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
		draggingMain=false
	end
end)
UIS.InputChanged:Connect(function(input)
	if draggingMain and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then
		local delta=input.Position-dragStartMain
		Main.Position=UDim2.new(startPosMain.X.Scale,startPosMain.X.Offset+delta.X,startPosMain.Y.Scale,startPosMain.Y.Offset+delta.Y)
	end
end)

-- Drag toggle button
local draggingBtn,dragStartBtn,startPosBtn,movedBtn=false,nil,nil,false
toggleBtn.InputBegan:Connect(function(input)
	if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
		draggingBtn=true; movedBtn=false; dragStartBtn=input.Position; startPosBtn=toggleBtn.Position
	end
end)
toggleBtn.InputEnded:Connect(function(input)
	if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
		draggingBtn=false
	end
end)
UIS.InputChanged:Connect(function(input)
	if draggingBtn and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then
		local delta=input.Position-dragStartBtn
		if delta.Magnitude>5 then movedBtn=true end
		toggleBtn.Position=UDim2.new(startPosBtn.X.Scale,startPosBtn.X.Offset+delta.X,startPosBtn.Y.Scale,startPosBtn.Y.Offset+delta.Y)
	end
end)

-- Open/close
local menuOpen=false
local W,H=380,440
local function setOpen(state)
	menuOpen=state
	if state then
		Main.Size=UDim2.new(0,0,0,0)
		Main.Visible=true
		tw(Main,{Size=UDim2.new(0,W,0,H)},0.3,Enum.EasingStyle.Back,Enum.EasingDirection.Out)
	else
		tw(Main,{Size=UDim2.new(0,0,0,0)},0.2)
		task.delay(0.22,function() Main.Visible=false end)
	end
end
Main.Visible=false
toggleBtn.MouseButton1Click:Connect(function()
	if movedBtn then return end
	setOpen(not menuOpen)
end)

-- Notify helper
local function Notify(title,text,dur)
	pcall(function()
		game:GetService("StarterGui"):SetCore("SendNotification",{Title=title,Text=text,Duration=dur or 4})
	end)
end

-- ============================================================
-- Library functions — CreateTab, AddSection, AddToggle, etc.
-- ============================================================

local Library={}
Library.toggleBtnRef=toggleBtn

function Library:CreateTab(name)
	local btn=Instance.new("TextButton",TabScroll)
	btn.Size=UDim2.new(1,0,0,30)
	btn.BackgroundColor3=BG_ELEM
	btn.Text=name
	btn.TextColor3=TXT_DIM
	btn.Font=Enum.Font.GothamBold
	btn.TextSize=10
	btn.AutoButtonColor=false
	btn.LayoutOrder=#tabsList+1
	mkCorner(btn,6)

	local page=Instance.new("ScrollingFrame",Content)
	page.Size=UDim2.new(1,0,1,0)
	page.BackgroundTransparency=1
	page.Visible=false
	page.ScrollBarThickness=3
	page.ScrollBarImageColor3=ACCENT
	page.CanvasSize=UDim2.new(0,0,0,0)
	page.AutomaticCanvasSize=Enum.AutomaticSize.Y
	page.BorderSizePixel=0

	local pageLayout=Instance.new("UIListLayout",page)
	pageLayout.Padding=UDim.new(0,6)
	pageLayout.SortOrder=Enum.SortOrder.LayoutOrder
	pageLayout.HorizontalAlignment=Enum.HorizontalAlignment.Center
	local pagePad=Instance.new("UIPadding",page)
	pagePad.PaddingTop=UDim.new(0,6); pagePad.PaddingBottom=UDim.new(0,8)

	local td={btn=btn,frame=page}
	table.insert(tabsList,td)

	btn.MouseButton1Click:Connect(function() switchTo(page,btn) end)
	btn.InputBegan:Connect(function(inp) if inp.UserInputType==Enum.UserInputType.Touch then switchTo(page,btn) end end)

	-- Elements API
	local Tab={}

	function Tab:AddSection(sTitle)
		local Section={}
		local sFrame=Instance.new("Frame",page)
		sFrame.Size=UDim2.new(0.97,0,0,0)
		sFrame.BackgroundColor3=BG_SECT
		sFrame.AutomaticSize=Enum.AutomaticSize.Y
		sFrame.LayoutOrder=999
		mkCorner(sFrame,8)
		local sStr=Instance.new("UIStroke",sFrame); sStr.Color=ACCENT; sStr.Thickness=1; sStr.Transparency=0.65

		local sLayout=Instance.new("UIListLayout",sFrame)
		sLayout.Padding=UDim.new(0,4); sLayout.SortOrder=Enum.SortOrder.LayoutOrder
		sLayout.HorizontalAlignment=Enum.HorizontalAlignment.Center

		-- section header
		local sHead=Instance.new("TextLabel",sFrame)
		sHead.Size=UDim2.new(1,0,0,22)
		sHead.BackgroundTransparency=1
		sHead.Text=" "..sTitle
		sHead.TextColor3=TXT_SECT
		sHead.TextSize=11; sHead.Font=Enum.Font.GothamBold
		sHead.TextXAlignment=Enum.TextXAlignment.Left
		sHead.LayoutOrder=0

		local sAccLine=Instance.new("Frame",sFrame)
		sAccLine.Size=UDim2.new(0.95,0,0,1)
		sAccLine.BackgroundColor3=ACCENT; sAccLine.BorderSizePixel=0
		sAccLine.LayoutOrder=1
		mkCorner(sAccLine,1)

		-- inner container
		local ctr=Instance.new("Frame",sFrame)
		ctr.Size=UDim2.new(1,0,0,0)
		ctr.BackgroundTransparency=1; ctr.AutomaticSize=Enum.AutomaticSize.Y
		ctr.LayoutOrder=2
		local cLayout=Instance.new("UIListLayout",ctr)
		cLayout.Padding=UDim.new(0,4); cLayout.SortOrder=Enum.SortOrder.LayoutOrder
		cLayout.HorizontalAlignment=Enum.HorizontalAlignment.Center
		local cPad=Instance.new("UIPadding",ctr)
		cPad.PaddingBottom=UDim.new(0,6); cPad.PaddingLeft=UDim.new(0,4); cPad.PaddingRight=UDim.new(0,4)

		function Section:AddLabel(text)
			local l=Instance.new("TextLabel",ctr)
			l.Size=UDim2.new(1,-8,0,18)
			l.BackgroundTransparency=1; l.Text=text
			l.TextColor3=TXT_DIM; l.Font=Enum.Font.Gotham; l.TextSize=11
			l.TextXAlignment=Enum.TextXAlignment.Left
			l.TextWrapped=true; l.AutomaticSize=Enum.AutomaticSize.Y
			l.LayoutOrder=999
			return l
		end

		function Section:AddButton(text,callback)
			local b=Instance.new("TextButton",ctr)
			b.Size=UDim2.new(1,-8,0,34)
			b.BackgroundColor3=COL_BTN
			b.Text=text; b.TextColor3=Color3.fromRGB(0,0,0)
			b.Font=Enum.Font.GothamBold; b.TextSize=11
			b.AutoButtonColor=false; b.LayoutOrder=999
			mkCorner(b,7)
			local bg=Instance.new("UIGradient",b)
			bg.Color=ColorSequence.new{ColorSequenceKeypoint.new(0,COL_BTN),ColorSequenceKeypoint.new(1,COL_BTN2)}
			bg.Rotation=90
			local function tap()
				tw(b,{BackgroundColor3=Color3.fromRGB(255,230,100)},0.07)
				task.delay(0.12,function() tw(b,{BackgroundColor3=COL_BTN},0.1) end)
				if callback then callback() end
			end
			b.MouseButton1Click:Connect(tap)
			b.InputBegan:Connect(function(inp) if inp.UserInputType==Enum.UserInputType.Touch then tap() end end)
			return b
		end

		function Section:AddToggle(text,defaultOrCb,maybeCb)
			local default=false; local callback=nil
			if type(defaultOrCb)=="boolean" then default=defaultOrCb; callback=maybeCb
			else callback=defaultOrCb end
			local state=default==true

			local row=Instance.new("Frame",ctr)
			row.Size=UDim2.new(1,-8,0,36)
			row.BackgroundColor3=BG_ELEM; row.LayoutOrder=999
			mkCorner(row,7)

			local lbl=Instance.new("TextLabel",row)
			lbl.Size=UDim2.new(1,-54,1,0)
			lbl.Position=UDim2.new(0,8,0,0)
			lbl.BackgroundTransparency=1; lbl.Text=text
			lbl.TextColor3=TXT_ON; lbl.Font=Enum.Font.Gotham; lbl.TextSize=11
			lbl.TextXAlignment=Enum.TextXAlignment.Left
			lbl.TextTruncate=Enum.TextTruncate.AtEnd

			local track=Instance.new("Frame",row)
			track.Size=UDim2.new(0,42,0,22)
			track.Position=UDim2.new(1,-50,0.5,-11)
			track.BackgroundColor3=state and COL_ON or COL_OFF
			mkCorner(track,11)

			local knob=Instance.new("Frame",track)
			knob.Size=UDim2.new(0,16,0,16)
			knob.Position=state and UDim2.new(1,-19,0.5,-8) or UDim2.new(0,3,0.5,-8)
			knob.BackgroundColor3=Color3.fromRGB(240,240,255)
			mkCorner(knob,8)

			local hitbox=Instance.new("TextButton",row)
			hitbox.Size=UDim2.new(1,0,1,0); hitbox.BackgroundTransparency=1; hitbox.Text=""
			local function toggle()
				state=not state
				tw(track,{BackgroundColor3=state and COL_ON or COL_OFF},0.14)
				tw(knob,{Position=state and UDim2.new(1,-19,0.5,-8) or UDim2.new(0,3,0.5,-8)},0.14,Enum.EasingStyle.Back)
				if callback then callback(state) end
			end
			hitbox.MouseButton1Click:Connect(toggle)
			hitbox.InputBegan:Connect(function(inp) if inp.UserInputType==Enum.UserInputType.Touch then toggle() end end)
			return row
		end

		function Section:AddSlider(text,min,max,defaultOrCb,maybeCb)
			local default=min; local callback=nil
			if type(defaultOrCb)=="number" then default=math.clamp(defaultOrCb,min,max); callback=maybeCb
			else callback=defaultOrCb end
			local value=default; local dragging=false
			local initAlpha=math.clamp((value-min)/math.max(max-min,1),0,1)

			local frame=Instance.new("Frame",ctr)
			frame.Size=UDim2.new(1,-8,0,52)
			frame.BackgroundColor3=BG_ELEM; frame.LayoutOrder=999
			mkCorner(frame,7)

			local lbl=Instance.new("TextLabel",frame)
			lbl.Size=UDim2.new(1,-10,0,20)
			lbl.Position=UDim2.new(0,8,0,4)
			lbl.BackgroundTransparency=1
			lbl.Text=text.." ("..value..")"
			lbl.TextColor3=TXT_ON; lbl.Font=Enum.Font.Gotham; lbl.TextSize=11
			lbl.TextXAlignment=Enum.TextXAlignment.Left

			local valTag=Instance.new("TextLabel",frame)
			valTag.Size=UDim2.new(0,50,0,20)
			valTag.Position=UDim2.new(1,-58,0,4)
			valTag.BackgroundTransparency=1
			valTag.Text=tostring(value)
			valTag.TextColor3=ACCENT; valTag.Font=Enum.Font.GothamBold; valTag.TextSize=11
			valTag.TextXAlignment=Enum.TextXAlignment.Right

			local bar=Instance.new("Frame",frame)
			bar.Size=UDim2.new(1,-16,0,6)
			bar.Position=UDim2.new(0,8,1,-16)
			bar.BackgroundColor3=Color3.fromRGB(40,40,60)
			mkCorner(bar,3)

			local fill=Instance.new("Frame",bar)
			fill.Size=UDim2.new(initAlpha,0,1,0)
			fill.BackgroundColor3=ACCENT
			fill.BorderSizePixel=0
			mkCorner(fill,3)
			local fillGrad=Instance.new("UIGradient",fill)
			fillGrad.Color=ColorSequence.new{ColorSequenceKeypoint.new(0,COL_BTN),ColorSequenceKeypoint.new(1,COL_BTN2)}

			local handle=Instance.new("Frame",bar)
			handle.Size=UDim2.new(0,14,0,14)
			handle.Position=UDim2.new(initAlpha,0,0.5,-7)
			handle.BackgroundColor3=Color3.fromRGB(255,255,255)
			mkCorner(handle,7)
			mkStroke(handle,ACCENT,1.5,0.2)

			local function update(input)
				if bar.AbsoluteSize.X<=0 then return end
				local pos=math.clamp((input.Position.X-bar.AbsolutePosition.X)/bar.AbsoluteSize.X,0,1)
				fill.Size=UDim2.new(pos,0,1,0)
				handle.Position=UDim2.new(pos,0,0.5,-7)
				value=math.floor(min+(max-min)*pos+0.5)
				lbl.Text=text.." ("..value..")"
				valTag.Text=tostring(value)
				if callback then callback(value) end
			end
			bar.InputBegan:Connect(function(inp)
				if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then
					dragging=true; update(inp)
				end
			end)
			UIS.InputChanged:Connect(function(inp)
				if dragging and (inp.UserInputType==Enum.UserInputType.MouseMovement or inp.UserInputType==Enum.UserInputType.Touch) then update(inp) end
			end)
			UIS.InputEnded:Connect(function(inp)
				if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then dragging=false end
			end)
			return frame
		end

		function Section:AddItemFilterTable(tableTitle,itemList,stateMap)
			local wrap=Instance.new("Frame",ctr)
			wrap.Size=UDim2.new(1,-8,0,0)
			wrap.BackgroundColor3=Color3.fromRGB(18,18,28)
			wrap.AutomaticSize=Enum.AutomaticSize.Y
			wrap.LayoutOrder=999
			mkCorner(wrap,8)
			mkStroke(wrap,Color3.fromRGB(60,60,90),1,0.5)

			local wLayout=Instance.new("UIListLayout",wrap)
			wLayout.Padding=UDim.new(0,4); wLayout.HorizontalAlignment=Enum.HorizontalAlignment.Center
			local wPad=Instance.new("UIPadding",wrap)
			wPad.PaddingTop=UDim.new(0,6); wPad.PaddingBottom=UDim.new(0,6)
			wPad.PaddingLeft=UDim.new(0,6); wPad.PaddingRight=UDim.new(0,6)

			local header=Instance.new("TextLabel",wrap)
			header.Size=UDim2.new(1,0,0,18)
			header.BackgroundTransparency=1; header.Text=tableTitle
			header.TextColor3=ACCENT; header.Font=Enum.Font.GothamBold; header.TextSize=11
			header.TextXAlignment=Enum.TextXAlignment.Left

			local sub=Instance.new("TextLabel",wrap)
			sub.Size=UDim2.new(1,0,0,14)
			sub.BackgroundTransparency=1; sub.Text="✓ Xanh = Cho phép TP | ✕ Đỏ = Chặn TP"
			sub.TextColor3=TXT_DIM; sub.Font=Enum.Font.Gotham; sub.TextSize=10
			sub.TextXAlignment=Enum.TextXAlignment.Left

			local bulkRow=Instance.new("Frame",wrap)
			bulkRow.Size=UDim2.new(1,0,0,26); bulkRow.BackgroundTransparency=1
			local btnAll=Instance.new("TextButton",bulkRow)
			btnAll.Size=UDim2.new(0.485,0,1,0); btnAll.Position=UDim2.new(0,0,0,0)
			btnAll.BackgroundColor3=Color3.fromRGB(32,85,45); btnAll.Text="✓ Cho phép tất cả"
			btnAll.TextColor3=COL_CHIP_ON_TXT; btnAll.Font=Enum.Font.GothamBold; btnAll.TextSize=10
			mkCorner(btnAll,5)
			local btnNone=Instance.new("TextButton",bulkRow)
			btnNone.Size=UDim2.new(0.485,0,1,0); btnNone.Position=UDim2.new(0.515,0,0,0)
			btnNone.BackgroundColor3=Color3.fromRGB(95,35,35); btnNone.Text="✕ Chặn tất cả"
			btnNone.TextColor3=COL_CHIP_OFF_TXT; btnNone.Font=Enum.Font.GothamBold; btnNone.TextSize=10
			mkCorner(btnNone,5)

			local grid=Instance.new("Frame",wrap)
			grid.Size=UDim2.new(1,0,0,0); grid.BackgroundTransparency=1; grid.AutomaticSize=Enum.AutomaticSize.Y
			local gLayout=Instance.new("UIGridLayout",grid)
			gLayout.CellSize=UDim2.new(0.485,0,0,26); gLayout.CellPadding=UDim2.new(0.03,0,0,4)
			gLayout.SortOrder=Enum.SortOrder.LayoutOrder

			local cellUpdaters={}
			for idx,itemName in ipairs(itemList) do
				local cell=Instance.new("TextButton",grid)
				cell.LayoutOrder=idx; cell.Font=Enum.Font.GothamBold; cell.TextSize=10
				cell.TextTruncate=Enum.TextTruncate.AtEnd
				mkCorner(cell,5)
				local cellStroke=Instance.new("UIStroke",cell); cellStroke.Thickness=1
				local function refreshCell()
					local allowed=stateMap[itemName]==true
					if allowed then
						cell.BackgroundColor3=COL_CHIP_ON; cell.TextColor3=COL_CHIP_ON_TXT
						cell.Text="✓ "..itemName; cellStroke.Color=Color3.fromRGB(75,190,95)
					else
						cell.BackgroundColor3=COL_CHIP_OFF; cell.TextColor3=COL_CHIP_OFF_TXT
						cell.Text="✕ "..itemName; cellStroke.Color=Color3.fromRGB(185,70,70)
					end
				end
				refreshCell(); table.insert(cellUpdaters,refreshCell)
				local function tap() stateMap[itemName]=not (stateMap[itemName]==true); refreshCell() end
				cell.MouseButton1Click:Connect(tap)
				cell.InputBegan:Connect(function(inp) if inp.UserInputType==Enum.UserInputType.Touch then tap() end end)
			end
			btnAll.MouseButton1Click:Connect(function()
				for _,n in ipairs(itemList) do stateMap[n]=true end
				for _,fn in ipairs(cellUpdaters) do fn() end
			end)
			btnAll.InputBegan:Connect(function(inp) if inp.UserInputType==Enum.UserInputType.Touch then for _,n in ipairs(itemList) do stateMap[n]=true end; for _,fn in ipairs(cellUpdaters) do fn() end end end)
			btnNone.MouseButton1Click:Connect(function()
				for _,n in ipairs(itemList) do stateMap[n]=false end
				for _,fn in ipairs(cellUpdaters) do fn() end
			end)
			btnNone.InputBegan:Connect(function(inp) if inp.UserInputType==Enum.UserInputType.Touch then for _,n in ipairs(itemList) do stateMap[n]=false end; for _,fn in ipairs(cellUpdaters) do fn() end end end)
			return wrap
		end

		return Section
	end

	return Tab
end

function Library:SetToggleSize(size)
	toggleBtn.Size=UDim2.new(0,size,0,size)
end
function Library:Notify(title,text,dur) Notify(title,text,dur) end

--======================================================
-- BUILD MENU (100% gốc call structure, new Library)
--======================================================
local Win = Library

local chopWarnLbl=nil
local function refreshChopCombatWarning()
	local bothOn=CFG.KillAura and CFG.AutoChop
	if chopWarnLbl and chopWarnLbl.Parent then
		if bothOn then
			chopWarnLbl.Text="⚠️ Đang bật cả Kill Aura & Auto Chop (dễ xung đột vũ khí)!"
			chopWarnLbl.TextColor3=Color3.fromRGB(255,85,85)
		else
			chopWarnLbl.Text="✅ Không xung đột vũ khí"
			chopWarnLbl.TextColor3=Color3.fromRGB(140,230,140)
		end
	end
	if bothOn then
		Win:Notify("⚠️ Cảnh báo xung đột vũ khí","Đang bật cả Kill Aura và TP Auto Chop. Nên tắt Kill Aura khi farm gỗ để chặt mượt hơn!",5)
	end
end

-- TAB 1: CHÍNH
local TabMain=Win:CreateTab("Chính")
do
	local sCombat=TabMain:AddSection("COMBAT & FARM")
	local tool=getKillTool(); local chopTool=getChopTool()
	sCombat:AddLabel("🗡 Vũ khí: "..(tool and tool.Name or "Không có").." | 🪓 Rìu: "..(chopTool and chopTool.Name or "Không có"))
	sCombat:AddToggle("Kill Aura",CFG.KillAura,function(v) CFG.KillAura=v; refreshChopCombatWarning() end)
	sCombat:AddSlider("Kill Radius",10,500,CFG.KillRadius,function(v) CFG.KillRadius=v end)
	sCombat:AddToggle("TP Auto Chop (Chặt gãy mới đổi)",CFG.AutoChop,function(v) CFG.AutoChop=v; refreshChopCombatWarning() end)
	sCombat:AddSlider("Chop Radius",10,500,CFG.ChopRadius,function(v) CFG.ChopRadius=v end)
	chopWarnLbl=sCombat:AddLabel("✅ Không xung đột vũ khí")
	chopWarnLbl.TextColor3=Color3.fromRGB(140,230,140)
	sCombat:AddSlider("Delay (x10ms)",5,60,math.floor(CFG.Delay*100),function(v) CFG.Delay=v/100 end)

	local sChest=TabMain:AddSection("RƯƠNG, ĐẠN & ĐỒNG XU")
	sChest:AddToggle("Mở rương (2-3/lần, 1 đồ/rương)",CFG.AutoChestAndLoot,function(v)
		CFG.AutoChestAndLoot=v
		if v then task.spawn(function() refreshAmmoCache(true) end)
		else updateChestLootStatus(string.format("Tắt · Rương: %d | Đồ: %d | Đạn: %d",totalChestsOpened,totalItemsLooted,totalAmmoCollected)) end
	end)
	chestLootStatusLbl=sChest:AddLabel(chestLootStatusText)
	sChest:AddToggle("Tự động nhặt toàn bộ xu",CFG.AutoCollectCoins,function(v)
		CFG.AutoCollectCoins=v
		if v then task.spawn(collectAllCoinsOnce) else updateCoinStatus("Tắt (Tổng: "..totalCollectedCoins..")") end
	end)
	coinStatusLbl=sChest:AddLabel(coinStatusText)

	local sSurv=TabMain:AddSection("SINH TỒN & TRỒNG CÂY")
	sSurv:AddToggle("🛡️ God Mode (Bất tử / Khóa máu)",CFG.GodMode,function(v)
		setGodMode(v)
		Win:Notify("🛡️ God Mode",v and "Đã bật God Mode (Bất tử)" or "Đã tắt God Mode",3)
	end)
	sSurv:AddToggle("Auto Eat Carrot",CFG.AutoEat,function(v) CFG.AutoEat=v; if not v then updateEatStatus("Tắt") end end)
	eatStatusLbl=sSurv:AddLabel(eatStatusText)
	local plantLbl=sSurv:AddLabel("Đứng chỗ trồng → bấm nút")
	sSurv:AddButton("🌱 Trồng tất cả mầm cây",function() task.spawn(function() plantAllSaplings(plantLbl) end) end)
end

-- TAB 2: DI CHUYỂN
local TabMove=Win:CreateTab("Di chuyển")
do
	local sMove=TabMove:AddSection("MOVEMENT")
	sMove:AddToggle("Speed",CFG.Speed,function(v)
		CFG.Speed=v; if not v then local h=hum(); if h then h.WalkSpeed=16 end end
	end)
	sMove:AddSlider("Walk Speed",16,300,CFG.WalkSpeed,function(v) CFG.WalkSpeed=v end)
	sMove:AddToggle("High Jump",CFG.Jump,function(v)
		CFG.Jump=v; if not v then local h=hum(); if h then h.JumpPower=50 end end
	end)
	sMove:AddSlider("Jump Power",50,500,CFG.JumpPower,function(v) CFG.JumpPower=v end)
	sMove:AddToggle("Fly",CFG.Fly,function(v)
		CFG.Fly=v; flyPad.Visible=v
		if v then startFly() else stopFly() end
	end)
	sMove:AddSlider("Fly Speed",10,200,CFG.FlySpeed,function(v) CFG.FlySpeed=v end)
	sMove:AddToggle("Noclip",CFG.Noclip,function(v)
		CFG.Noclip=v; if not v then restoreNoclip() end
	end)
end

-- TAB 3: TRẺ EM
local TabChild=Win:CreateTab("Trẻ em")
do
	local sAutoRescue=TabChild:AddSection("AUTO CỨU TRẺ VỀ LỬA TRẠI")
	local sack=getSackTool()
	sAutoRescue:AddLabel("🎒 Túi hiện tại: "..(sack and sack.Name or "Chưa có túi"))
	sAutoRescue:AddToggle("Auto cứu trẻ (TP → Balo → Lửa)",CFG.AutoRescueChild,function(v)
		CFG.AutoRescueChild=v
		if not v then updateRescueStatus(string.format("Tắt · Đã cứu: %d",totalChildrenSaved)) end
	end)
	rescueStatusLbl=sAutoRescue:AddLabel(rescueStatusText)
	sAutoRescue:AddButton("🔄 Reset danh sách trẻ đã cứu",function()
		rescuedChildren=setmetatable({},{__mode="k"}); rescuedChildKeys={}
		updateRescueStatus("🔄 Đã reset danh sách trẻ đã cứu")
	end)

	local sChild=TabChild:AddSection("ESP & TP THỦ CÔNG")
	sChild:AddToggle("ESP Trẻ em",CFG.ESPChild,function(v) CFG.ESPChild=v; if not v then clearESPChild() end end)
	local r=root(); local list={}
	for m,_ in pairs(childSet) do
		if m and m.Parent then
			local p=partOf(m); if p then local d=r and math.floor((p.Position-r.Position).Magnitude) or 0; table.insert(list,{m=m,p=p,d=d}) end
		end
	end
	table.sort(list,function(a,b) return a.d<b.d end)
	if #list==0 then sChild:AddLabel("Không tìm thấy trẻ nào")
	else
		for i,item in ipairs(list) do
			sChild:AddButton(string.format("TP %d. %s (%d studs)",i,item.m.Name,item.d),function() tpTo(item.m) end)
		end
	end
end

-- TAB 4: TP & ĐỒ
local TabItems=Win:CreateTab("TP & Đồ")
do
	local sFire=TabItems:AddSection("LỬA TRẠI & NHIÊN LIỆU")
	sFire:AddButton("🔥 TP Lửa trại",tpCampfire)
	sFire:AddToggle("Auto dồn nhiên liệu → Lửa",CFG.AutoDrop,function(v) CFG.AutoDrop=v end)
	sFire:AddButton("🪵 Dồn nhiên liệu → Lửa ngay",function() task.spawn(function() dumpFuelToFire() end) end)
	sFire:AddItemFilterTable("🔥 Bảng chọn vật phẩm TP về Lửa trại",FUEL_EXACT,FireAllowedItems)

	local sScrap=TabItems:AddSection("SCRAPPER")
	sScrap:AddButton("📍 TP tới Scrapper",function()
		local sp,r=getScrapperPart(),root()
		if sp and r then r.CFrame=CFrame.new(sp.Position+Vector3.new(0,5,0)) end
	end)
	sScrap:AddToggle("Auto dồn nguyên liệu → Scrapper",CFG.AutoScrap,function(v) CFG.AutoScrap=v end)
	sScrap:AddButton("⚙️ Dồn nguyên liệu → Scrapper ngay",function() task.spawn(dumpScrapToScrapper) end)
	sScrap:AddItemFilterTable("⚙️ Bảng chọn vật phẩm TP về Scrapper",SCRAPPER_ITEMS,ScrapAllowedItems)

	local sPull=TabItems:AddSection("KÉO VẬT PHẨM VỀ NGƯỜI")
	sPull:AddButton("🍎 Kéo thức ăn",function() task.spawn(function() pullAllExact(FOOD_ITEMS) end) end)
	sPull:AddButton("⚙️ Kéo nguyên liệu (Log, Chair...)",function() task.spawn(function() pullAllExact(SCRAP_ITEMS) end) end)

	local sPlr=TabItems:AddSection("NGƯỜI CHƠI")
	local r2=root(); local hasOther=false
	for _,plr in ipairs(Players:GetPlayers()) do
		if plr~=Player then
			hasOther=true
			local pRoot=plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
			local dist=(r2 and pRoot) and math.floor((pRoot.Position-r2.Position).Magnitude) or 0
			sPlr:AddButton(string.format("Kéo %s (%d studs)",plr.Name,dist),function() pullPlayerToMe(plr) end)
		end
	end
	if not hasOther then sPlr:AddLabel("Không có người chơi khác") end
end

-- TAB 5: CÀI ĐẶT
local TabSet=Win:CreateTab("Cài đặt")
do
	local sPerf=TabSet:AddSection("HIỆU NĂNG & ÁNH SÁNG")
	sPerf:AddToggle("Fix Lag Pro",CFG.FixLag,function(v) setFixLag(v) end)
	sPerf:AddToggle("Nhìn trong bóng tối (Fullbright)",CFG.Fullbright,function(v) CFG.Fullbright=v; setFullbright(v) end)

	local sMap=TabSet:AddSection("BẢN ĐỒ & GIAO DIỆN")
	sMap:AddButton("🗺️ Reveal Map",function() task.spawn(revealMap) end)
	sMap:AddSlider("Kích thước nút bật/tắt",32,70,52,function(v) Win:SetToggleSize(v) end)
end

-- Auto-open first tab
task.defer(function()
	if tabsList[1] then
		switchTo(tabsList[1].frame,tabsList[1].btn)
	end
end)

print("=========================================")
print("  VB MENU — MaldixAura Style LOADED ✓")
print("  Tap the orange button to open/close")
print("=========================================")
