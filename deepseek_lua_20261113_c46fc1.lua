--========================================================
-- SUNSET UI + OLLIE 99 NIGHTS (GOD 20 + AUTO MAP + BOUNDARIES ORBIT)
-- God Mode: Normal Move + Auto HP Reset + Height Cap 20
-- Auto Map: Periodic Reveal Map Loop
-- Boundaries Orbit: Scan Boundaries + High Altitude + Fast Circle Inside Bounds
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

-- Cleanup old GUIs
for _, name in ipairs({"OllieUI", "OllieMenu", "ollie_v9", "SunsetUI"}) do
	pcall(function()
		local g = PlayerGui:FindFirstChild(name)
		if g then g:Destroy() end
	end)
	pcall(function()
		local g = CoreGui:FindFirstChild(name)
		if g then g:Destroy() end
	end)
end

--========================================================
-- REMOTES & GAME DATA (99 NIGHTS FILTERS)
--========================================================

local Remotes       = RS:WaitForChild("RemoteEvents", 10)
local EquipRE       = Remotes and Remotes:FindFirstChild("EquipItemHandle")
local UnequipRE     = Remotes and Remotes:FindFirstChild("UnequipItemHandle")
local DamageRF      = Remotes and Remotes:FindFirstChild("ToolDamageObject")
local MapRE         = Remotes and Remotes:FindFirstChild("MapCellsDiscovered")
local DragRE        = Remotes and Remotes:FindFirstChild("RequestStartDraggingItem")
local StopDragRE    = Remotes and Remotes:FindFirstChild("StopDraggingItem")
local HitSoundRE    = Remotes and Remotes:FindFirstChild("PlayEnemyHitSound")
local PlantRE       = Remotes and Remotes:FindFirstChild("RequestPlantItem")
local ConsumeRF     = Remotes and Remotes:FindFirstChild("RequestConsumeItem")
local OpenChestRE   = Remotes and Remotes:FindFirstChild("RequestOpenItemChest")
local CollectCoinRF = Remotes and Remotes:FindFirstChild("RequestCollectCoints")
local HotbarItemRF  = Remotes and Remotes:FindFirstChild("RequestHotbarItem")
local BagStoreRF    = Remotes and Remotes:FindFirstChild("RequestBagStoreItem")
local BagDropRE     = Remotes and Remotes:FindFirstChild("RequestBagDropItem")

local AXES = {
	"Old Axe", "Good Axe", "Ice Axe", "Strong Axe", "Chainsaw", "Admin Axe",
}

local MELEE_WEAPONS = {
	"Spear", "Diamond Spear", "Honey Spear", "Morningstar", "Morning Star",
	"Kunai", "Katana", "Laser Sword", "Ice Sword", "Trident",
	"Poison Claws", "Poison Spear", "Infernal Sword",
	"Cultist King Mace", "Brutal Battleaxe", "Obsidiron Hammer",
	"Scythe", "Vampire Scythe", "Happy's Scythe",
}

local SACK_NAMES = {
	"Admin Sack", "Giant Sack", "Infernal Sack", "Good Sack", "Old Sack", "Sack", "Bag",
}

local FOOD_ITEMS = { "Berry", "Carrot", "Apple", "Corn", "Pumpkin", "Chili" }

local SCRAPPER_KEYS = {
	"Scrapper", "Grinder", "Recycler", "Anvil",
}

-- Tên chính xác (case-sensitive) của phế liệu sắt + gỗ/ghế
local SCRAP_EXACT = {
	"Bolt", "Sheet Metal", "Tyre", "Tires & Engines",
	"Metal Chair", "Chair", "Log",
	"Broken Fan", "Broken Radio", "Old Radio",
	"Broken Microwave", "Washing Machine", "Old Car Engine",
	"UFO Junk", "UFO Component", "UFO Scrap",
	"Cultist Experiment", "Cultist Prototype",
	"Obsidiron Shard", "Obsidiron Ingot",
}

local SCRAP_EXACT_SET = {}
for _, v in ipairs(SCRAP_EXACT) do SCRAP_EXACT_SET[v] = true end

local SCRAP_ITEMS = SCRAP_EXACT

-- Nhiên liệu lửa trại (không gồm Log và Chair)
local FUEL_EXACT = {
	"Biofuel", "Coal", "Purple Fur Tuft", "Fuel Canister", "Oil Barrel",
}

local CHEST_KEYS = {
	"Chest", "Crate", "Supply", "Loot",
	"Common Chest", "Good Chest", "Iron Chest", "Legendary Chest",
	"Gold Chest", "Ruby Chest", "Diamond Chest",
	"Alien Chest", "Cold Chest", "Ice Chest",
	"Jungle Chest", "Vine Chest", "Stone Chest", "Golden Stone Chest",
	"Volcanic Chest", "Infernal Chest", "Frog Chest",
	"Spooky Chest", "Vampire Chest", "Obsidiron Chest",
}

-- Bộ lọc vật phẩm mở rương & nhặt đồ
local CHEST_LOOT_WHITELIST = {
	"Old Sack", "Good Sack", "Infernal Sack", "Giant Sack", "Admin Sack",
	"Good Axe", "Ice Axe", "Strong Axe", "Chainsaw", "Admin Axe",
	"Old Taming Flute", "Good Taming Flute", "Strong Taming Flute", "Admin Taming Flute",
	"Old Flashlight", "Strong Flashlight", "Admin Flashlight",
	"Spear", "Honey Spear", "Morningstar", "Katana", "Laser Sword",
	"Ice Sword", "Trident", "Poison Claws", "Poison Spear", "Infernal Sword",
	"Cultist King Mace", "Brutal Battleaxe", "Obsidiron Hammer",
	"Scythe", "Vampire Scythe", "Happy's Scythe",
	"Revolver", "Rifle", "Tactical Shotgun", "Snowball", "Frozen Shuriken",
	"Impact Gernade", "Impact Grenade", "Kunai", "Ray Gun", "Laser Cannon",
	"Laser Shotgun", "Flamethrower", "Blowpipe", "Admin Gun", "Friendly Gun",
	"Wildfire", "Infernal Crossbow", "Witch Potion", "Crossbow", "potion", "Potion",
	"Bouncing Blade", "Air Rifle", "Ice Bow",
	"Revolver Ammo", "Rifle Ammo", "Shotgun Ammo", "Ghost Crossbow",
	"Leather Body", "Poison Armour", "Iron Body", "Thorn Body",
	"Riot Shield", "Alien Armour", "Obsidiron Body", "Vampire Cloak",
	"Crafting Blueprint", "Defense Blueprint",
	"Bandage", "Medkit",
}

local STACKABLE_BLUEPRINTS = {
	["crafting blueprint"] = true,
	["defense blueprint"]  = true,
}

local COIN_KEYS = { "Coin" }
local AMMO_KEYS = { "Ammo", "Bullet", "Shell", "Arrow", "Dart", "Rocket", "Cartridge" }

local IGNORE_LOOT_KEYS = {
	"Tree", "Pine", "Oak", "Birch", "Fir", "Bush", "Foliage",
	"Wall", "Floor", "Ground", "Terrain", "Campfire", "MainFire",
	"Scrapper", "Grinder", "Recycler", "Anvil",
	"Spawn", "Part", "Baseplate", "Hitbox",
}

local CFG = {
	Speed = false,            WalkSpeed = 40,
	Jump = false,             JumpPower = 90,
	Fly = false,              FlySpeed = 60,
	Noclip = false,
	GodMode = false,
	AutoMap = false,
	CircleBoundaries = false,
	KillAura = false,         KillRadius = 150,
	AutoChop = false,         ChopRadius = 130,
	AutoDrop = false,
	AutoScrapper = false,
	AutoEat = false,
	AutoChestAndLoot = false,
	AutoCollectCoins = false,
	AutoRescueChild = false,
	ESPChild = false,
	Fullbright = false,
	FixLag = false,
	Delay = 0.35,
}

local MAX_KILL_PER_CYCLE = 6
local TOOL_SUFFIX = "11960515286"
local CHILD_KEY   = "Lost Child"

--========================================================
-- GAME HELPERS (OPTIMIZED)
--========================================================

local function hasKey(name, keys)
	if type(name) ~= "string" then return false end
	local n = string.lower(name)
	for _, k in ipairs(keys) do
		if string.find(n, string.lower(k), 1, true) then return true end
	end
	return false
end

local function matchesExact(name, list)
	if type(name) ~= "string" then return false end
	for _, v in ipairs(list) do
		if name == v or string.lower(name) == string.lower(v) then
			return true
		end
	end
	return false
end

local function isStackableBlueprint(name)
	if type(name) ~= "string" then return false end
	return STACKABLE_BLUEPRINTS[string.lower(name)] == true
end

local function root()
	local c = Player.Character
	return c and c:FindFirstChild("HumanoidRootPart")
end

local function hum()
	local c = Player.Character
	return c and c:FindFirstChildOfClass("Humanoid")
end

local function partOf(m)
	if not m then return nil end
	local ok, res = pcall(function()
		if m:IsA("BasePart") then return m end
		if m:IsA("Model") then
			if m.PrimaryPart then return m.PrimaryPart end
			local hrp = m:FindFirstChild("HumanoidRootPart")
			if hrp then return hrp end
			return m:FindFirstChildWhichIsA("BasePart", true)
		end
		return nil
	end)
	return ok and res or nil
end

local function isWorldArchitecture(obj)
	if not obj or not obj.Parent then return true end
	local mapFolder = Workspace:FindFirstChild("Map")
	if mapFolder and obj:IsDescendantOf(mapFolder) then
		return true
	end
	if obj:IsA("Model") then
		local ok, _, sz = pcall(function() return obj:GetBoundingBox() end)
		if ok and sz and (sz.X > 12 or sz.Y > 12 or sz.Z > 12) then
			return true
		end
	elseif obj:IsA("BasePart") then
		if obj.Anchored and (obj.Size.X > 10 or obj.Size.Y > 10 or obj.Size.Z > 10) then
			return true
		end
	end
	return false
end

local function getChestBounds(chest)
	if not chest or not chest.Parent then return nil, nil end
	local ok, cf, sz = pcall(function()
		if chest:IsA("Model") then
			local mcf, msz = chest:GetBoundingBox()
			return mcf, msz
		elseif chest:IsA("BasePart") then
			return chest.CFrame, chest.Size
		end
		return nil, nil
	end)
	if ok and cf and sz then
		local innerSize = Vector3.new(
			math.max(math.min(sz.X, 6.5), 1.5),
			math.max(math.min(sz.Y + 2.2, 6.5), 2.0),
			math.max(math.min(sz.Z, 6.5), 1.5)
		)
		local innerCF = cf * CFrame.new(0, math.clamp(sz.Y * 0.25, 0.2, 1.2), 0)
		return innerCF, innerSize
	end
	local p = partOf(chest)
	if p then
		return p.CFrame * CFrame.new(0, 1.0, 0), Vector3.new(4.5, 4.0, 4.5)
	end
	return nil, nil
end

local function moveItemToCFrame(obj, goalCF)
	if not obj or not obj.Parent then return false end
	local ok = pcall(function()
		if DragRE then
			pcall(DragRE.FireServer, DragRE, obj)
		end
		if obj:IsA("Model") then
			obj:PivotTo(goalCF)
		elseif obj:IsA("BasePart") then
			obj.CFrame = goalCF
		end
	end)
	if StopDragRE then
		pcall(StopDragRE.FireServer, StopDragRE, obj)
	end
	return ok == true
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
	local inv, char = Player:FindFirstChild("Inventory"), Player.Character
	return findFromList(MELEE_WEAPONS, inv, char)
		or findFromList(AXES, inv, char)
		or getFallbackTool(inv, char)
end

local function getChopTool()
	local inv, char = Player:FindFirstChild("Inventory"), Player.Character
	return findFromList(AXES, inv, char)
		or findFromList(MELEE_WEAPONS, inv, char)
		or getFallbackTool(inv, char)
end

local function getSackTool()
	local inv, char = Player:FindFirstChild("Inventory"), Player.Character
	local exact = findFromList(SACK_NAMES, inv, char)
	if exact then return exact end
	if inv then
		for _, item in ipairs(inv:GetChildren()) do
			if hasKey(item.Name, { "Sack", "Bag" }) then return item end
		end
	end
	if char then
		for _, item in ipairs(char:GetChildren()) do
			if hasKey(item.Name, { "Sack", "Bag" }) then return item end
		end
	end
	return nil
end

local cachedFirePart = nil
local function getFirePart()
	if cachedFirePart and cachedFirePart.Parent then
		return cachedFirePart
	end
	cachedFirePart = nil

	local map = Workspace:FindFirstChild("Map")
	local camp = map and map:FindFirstChild("Campground")
	local fire = camp and camp:FindFirstChild("MainFire", true)
	if fire then
		cachedFirePart = partOf(fire)
		if cachedFirePart then return cachedFirePart end
	end

	local searchRoots = { camp, map, Workspace:FindFirstChild("Items"), Workspace }
	for _, sr in ipairs(searchRoots) do
		if sr then
			local list = (sr == Workspace) and sr:GetChildren() or sr:GetDescendants()
			for _, o in ipairs(list) do
				if o.Name == "MainFire" or o.Name == "Campfire" then
					local p = partOf(o)
					if p then
						cachedFirePart = p
						return p
					end
				end
			end
		end
	end
	return nil
end

local cachedScrapperPart = nil
local function getScrapperPart()
	if cachedScrapperPart and cachedScrapperPart.Parent then
		return cachedScrapperPart
	end
	cachedScrapperPart = nil

	local map = Workspace:FindFirstChild("Map")
	local camp = map and map:FindFirstChild("Campground")
	local searchRoots = { camp, map, Workspace:FindFirstChild("Items"), Workspace }

	for _, sr in ipairs(searchRoots) do
		if sr then
			local list = (sr == Workspace) and sr:GetChildren() or sr:GetDescendants()
			for _, o in ipairs(list) do
				local okName, n = pcall(function() return o.Name end)
				if okName and type(n) == "string" and hasKey(n, SCRAPPER_KEYS) then
					local p = partOf(o)
					if p then
						cachedScrapperPart = p
						return p
					end
				end
			end
		end
	end
	return nil
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

--========================================================
-- EVENT-BASED CACHE: CHILDREN (NO WORKSPACE LAG)
--========================================================

local childSet = {}
local function isChildModel(o)
	return o and o:IsA("Model") and string.find(o.Name, CHILD_KEY, 1, true) ~= nil
end

local function initChildCache()
	local charFolder = Workspace:FindFirstChild("Characters")
	local scanTargets = { Workspace }
	if charFolder then table.insert(scanTargets, charFolder) end

	for _, folder in ipairs(scanTargets) do
		for _, o in ipairs(folder:GetChildren()) do
			if isChildModel(o) then childSet[o] = true end
		end
		folder.ChildAdded:Connect(function(o)
			if isChildModel(o) then childSet[o] = true end
		end)
		folder.ChildRemoved:Connect(function(o)
			childSet[o] = nil
		end)
	end

	task.spawn(function()
		local all = Workspace:GetDescendants()
		for i = 1, #all do
			local o = all[i]
			if isChildModel(o) then childSet[o] = true end
			if i % 800 == 0 then task.wait() end
		end
	end)
end
initChildCache()

--========================================================
-- AUTO RESCUE CHILDREN (TP -> BAG -> CAMPFIRE -> DROP)
--========================================================

local rescueStatusText   = "Chờ bật tự động cứu trẻ..."
local rescueStatusLbl    = nil
local rescuedChildren    = setmetatable({}, { __mode = "k" })
local rescuedChildKeys   = {}
local totalChildrenSaved = 0

local function updateRescueStatus(txt)
	rescueStatusText = txt
	if rescueStatusLbl and rescueStatusLbl.Parent then
		rescueStatusLbl.Text = txt
	end
end

local function getChildUniqueKey(child)
	if not child then return nil end
	local ok, dbg = pcall(function() return child:GetDebugId() end)
	if ok and dbg then return dbg end
	return tostring(child)
end

local function isChildAlreadyRescued(child)
	if not child then return true end
	if rescuedChildren[child] then return true end
	local key = getChildUniqueKey(child)
	if key and rescuedChildKeys[key] then return true end

	local fp = getFirePart()
	local cp = partOf(child)
	if fp and cp and (cp.Position - fp.Position).Magnitude <= 22 then
		rescuedChildren[child] = true
		if key then rescuedChildKeys[key] = true end
		return true
	end
	return false
end

local function markChildRescued(child)
	if not child then return end
	rescuedChildren[child] = true
	local key = getChildUniqueKey(child)
	if key then rescuedChildKeys[key] = true end
end

local function findItemInBag(childName)
	local itemBag = Player:FindFirstChild("ItemBag")
	if not itemBag then return nil end
	return itemBag:FindFirstChild(childName)
		or itemBag:FindFirstChild(CHILD_KEY)
		or itemBag:FindFirstChildWhichIsA("Model")
end

local function rescueSingleChild(child)
	if not child or not child.Parent then return false end
	if not (BagStoreRF and BagDropRE) then
		updateRescueStatus("❌ Thiếu remote BagStore / BagDrop")
		return false
	end

	local sack = getSackTool()
	if not sack then
		updateRescueStatus("❌ Không tìm thấy túi (Old Sack...)")
		return false
	end

	local fp = getFirePart()
	if not fp then
		updateRescueStatus("❌ Không tìm thấy Lửa trại")
		return false
	end

	local r = root()
	local cp = partOf(child)
	if not (r and cp) then return false end

	local childName = child.Name
	updateRescueStatus("🏃 Đang TP tới: " .. childName)

	r.CFrame = CFrame.new(cp.Position + Vector3.new(0, 3, 2))
	task.wait(0.25)
	if not CFG.AutoRescueChild then return false end

	updateRescueStatus("🎒 Đang cất vào balo: " .. childName)
	local bagTarget = findItemInBag(childName) or child
	local storeOk = pcall(BagStoreRF.InvokeServer, BagStoreRF, sack, bagTarget)
	if not storeOk then
		local altTarget = (bagTarget == child) and findItemInBag(childName) or child
		if altTarget then
			pcall(BagStoreRF.InvokeServer, BagStoreRF, sack, altTarget)
		end
	end
	task.wait(0.25)
	if not CFG.AutoRescueChild then return false end

	updateRescueStatus("🔥 Đang TP về lửa trại...")
	r = root()
	if r and fp and fp.Parent then
		r.CFrame = CFrame.new(fp.Position + Vector3.new(0, 4, 3))
	end
	task.wait(0.25)

	updateRescueStatus("📤 Đang thả trẻ tại lửa trại...")
	local dropTarget = (child and child.Parent) and child or findItemInBag(childName)
	if dropTarget then
		pcall(BagDropRE.FireServer, BagDropRE, sack, dropTarget, true)
	end
	task.wait(0.2)

	markChildRescued(child)
	totalChildrenSaved += 1
	updateRescueStatus(string.format("✅ Đã cứu %s (Tổng: %d)", childName, totalChildrenSaved))
	return true
end

local function processNextChildRescue()
	local r = root()
	local rPos = r and r.Position
	local nearestChild = nil
	local bestDist = math.huge

	for child, _ in pairs(childSet) do
		if child and child.Parent and not isChildAlreadyRescued(child) then
			local p = partOf(child)
			if p then
				local d = rPos and (p.Position - rPos).Magnitude or 0
				if d < bestDist then
					bestDist = d
					nearestChild = child
				end
			end
		end
	end

	if not nearestChild then
		updateRescueStatus(string.format("✅ Đã cứu hết trẻ · Tổng: %d", totalChildrenSaved))
		return
	end

	rescueSingleChild(nearestChild)
end

task.spawn(function()
	while true do
		if CFG.AutoRescueChild then
			pcall(processNextChildRescue)
			task.wait(1.0)
		else
			task.wait(0.5)
		end
	end
end)

--========================================================
-- ZERO-LAG AUTO OPEN CHEST & LOOT (EVENT-CACHED, NO WORKSPACE SCAN)
--========================================================

local chestLootStatusText = "Chờ bật tự động mở & nhặt rương..."
local chestLootStatusLbl  = nil

local cachedChests    = {}
local cachedAmmo      = {}
local openedChests    = setmetatable({}, { __mode = "k" })
local lootedItems     = setmetatable({}, { __mode = "k" })
local fireSentItems   = setmetatable({}, { __mode = "k" })
local claimedAmmo     = setmetatable({}, { __mode = "k" })

local STEP_WAIT_SECONDS = 0.35

local totalChestsOpened  = 0
local totalItemsLooted   = 0
local totalSentToFire    = 0
local totalAmmoCollected = 0

local function updateChestLootStatus(txt)
	chestLootStatusText = txt
	if chestLootStatusLbl and chestLootStatusLbl.Parent then
		chestLootStatusLbl.Text = txt
	end
end

local function isChestObject(o)
	return (o:IsA("Model") or o:IsA("BasePart")) and hasKey(o.Name, CHEST_KEYS)
end

local function isAmmoObject(obj)
	if not obj then return false end
	local okName, name = pcall(function() return obj.Name end)
	if not okName or type(name) ~= "string" then return false end
	if hasKey(name, IGNORE_LOOT_KEYS) or hasKey(name, CHEST_KEYS) or hasKey(name, COIN_KEYS) then
		return false
	end
	return hasKey(name, AMMO_KEYS)
end

local itemsCacheInitialized = false
local function initItemsAndChestCache()
	if itemsCacheInitialized then return end
	itemsCacheInitialized = true

	local itemsFolder = Workspace:FindFirstChild("Items")
	local targetRoot  = itemsFolder or Workspace

	task.spawn(function()
		local all = targetRoot:GetDescendants()
		for i = 1, #all do
			local o = all[i]
			if isChestObject(o) then
				cachedChests[o] = true
			elseif isAmmoObject(o) then
				cachedAmmo[o] = true
			end
			if i % 600 == 0 then task.wait() end
		end
	end)

	targetRoot.DescendantAdded:Connect(function(o)
		if isChestObject(o) then
			cachedChests[o] = true
		elseif isAmmoObject(o) then
			cachedAmmo[o] = true
		end
	end)

	targetRoot.DescendantRemoving:Connect(function(o)
		cachedChests[o] = nil
		cachedAmmo[o] = nil
	end)
end

local function getPlayerBagNameSet()
	local names = {}
	local containers = {
		Player:FindFirstChild("Inventory"),
		Player:FindFirstChild("ItemBag"),
		Player:FindFirstChild("Backpack"),
		Player:FindFirstChild("Bag"),
		Player:FindFirstChild("Hotbar"),
		Player.Character,
	}

	for _, cont in ipairs(containers) do
		if cont then
			for _, obj in ipairs(cont:GetChildren()) do
				local okN, n = pcall(function() return obj.Name end)
				if okN and type(n) == "string" and not isStackableBlueprint(n) then
					names[string.lower(n)] = true
				end
			end
		end
	end
	return names
end

local function isItemAlreadyInPlayerBag(item, bagNameSet)
	if not item then return false end
	local okN, n = pcall(function() return item.Name end)
	if okN and type(n) == "string" and isStackableBlueprint(n) then
		return false
	end

	local containers = {
		Player:FindFirstChild("Inventory"),
		Player:FindFirstChild("ItemBag"),
		Player:FindFirstChild("Backpack"),
		Player:FindFirstChild("Bag"),
		Player.Character,
	}
	for _, cont in ipairs(containers) do
		if cont and item:IsDescendantOf(cont) then
			return true
		end
	end
	if okN and type(n) == "string" then
		return bagNameSet[string.lower(n)] == true
	end
	return false
end

local function tpItemToCampfire(item, idx)
	if not item or not item.Parent then return false end
	if fireSentItems[item] then return true end
	local fp = getFirePart()
	if not fp or not fp.Parent then return false end

	local spread = Vector3.new(
		math.random(-25, 25) / 10,
		10 + ((idx or 1) % 6) * 0.6,
		math.random(-25, 25) / 10
	)
	local moved = moveItemToCFrame(item, CFrame.new(fp.Position + spread))
	if moved then
		fireSentItems[item] = true
		totalSentToFire += 1
	end
	return moved
end

local function collectCachedAmmoBatch()
	if not ConsumeRF then return 0 end
	local claimed = 0
	for ammoObj, _ in pairs(cachedAmmo) do
		if not CFG.AutoChestAndLoot or claimed >= 8 then break end
		if ammoObj and ammoObj.Parent and not claimedAmmo[ammoObj] then
			local ok = pcall(ConsumeRF.InvokeServer, ConsumeRF, ammoObj)
			if ok then
				claimedAmmo[ammoObj] = true
				cachedAmmo[ammoObj] = nil
				claimed += 1
				totalAmmoCollected += 1
			end
		else
			cachedAmmo[ammoObj] = nil
		end
	end
	return claimed
end

local function isValidChestLoot(obj, targetChest)
	if not obj or not obj.Parent then return false end
	if cachedChests[obj] or obj == targetChest or obj:IsDescendantOf(targetChest) then
		return false
	end
	if isWorldArchitecture(obj) then return false end

	local ch = Player.Character
	if ch and obj:IsDescendantOf(ch) then return false end
	if Players:GetPlayerFromCharacter(obj) then return false end

	local name = obj.Name
	if hasKey(name, CHEST_KEYS) or hasKey(name, COIN_KEYS) or hasKey(name, IGNORE_LOOT_KEYS) then
		return false
	end

	return matchesExact(name, CHEST_LOOT_WHITELIST)
end

local overlapParams = OverlapParams.new()
overlapParams.FilterType = Enum.RaycastFilterType.Exclude

local function scanLootInsideChest(targetChest)
	local boxCF, boxSize = getChestBounds(targetChest)
	if not boxCF or not boxSize then return {} end

	local excludeList = { targetChest }
	if Player.Character then table.insert(excludeList, Player.Character) end
	overlapParams.FilterDescendantsInstances = excludeList

	local insideParts = Workspace:GetPartBoundsInBox(boxCF, boxSize, overlapParams)
	local out, seen = {}, {}

	for _, part in ipairs(insideParts) do
		local candidate = part:FindFirstAncestorOfClass("Tool")
			or part:FindFirstAncestorOfClass("Model")
			or part

		if candidate and not seen[candidate] and not fireSentItems[candidate] then
			seen[candidate] = true
			if isValidChestLoot(candidate, targetChest) then
				table.insert(out, candidate)
			end
		end
	end
	return out
end

local function tryTakeIntoBag(item)
	if not HotbarItemRF or not item or not item.Parent then return false end
	local inv = Player:FindFirstChild("Inventory")
	local bag = Player:FindFirstChild("ItemBag")
	local beforeInv = inv and #inv:GetChildren() or 0
	local beforeBag = bag and #bag:GetChildren() or 0

	local ok = pcall(HotbarItemRF.InvokeServer, HotbarItemRF, item)
	if not ok then return false end

	local afterInv = inv and #inv:GetChildren() or 0
	local afterBag = bag and #bag:GetChildren() or 0

	if isStackableBlueprint(item.Name) then
		return (afterInv > beforeInv) or (afterBag > beforeBag) or (item.Parent == Player.Character) or (not item.Parent)
	end

	local nowInInv = (inv and item.Parent == inv) or (bag and item.Parent == bag) or (item.Parent == Player.Character)
	return nowInInv or (afterInv > beforeInv) or (afterBag > beforeBag) or (not item.Parent)
end

local function processChestLootSmooth(chest)
	local items = scanLootInsideChest(chest)
	if #items == 0 then return 0, 0 end

	local bagNameSet = getPlayerBagNameSet()
	local grabbed, toFire = 0, 0

	for idx, item in ipairs(items) do
		if not CFG.AutoChestAndLoot then break end
		if not item or not item.Parent or fireSentItems[item] then continue end

		if isItemAlreadyInPlayerBag(item, bagNameSet) then
			if tpItemToCampfire(item, idx) then
				toFire += 1
			end
		else
			local isBagEligible = item:IsA("Tool") or item:IsA("Model")
			local took = isBagEligible and tryTakeIntoBag(item) or false

			if took then
				lootedItems[item] = true
				grabbed += 1
				totalItemsLooted += 1
				local okN, n = pcall(function() return item.Name end)
				if okN and type(n) == "string" and not isStackableBlueprint(n) then
					bagNameSet[string.lower(n)] = true
				end
			else
				if tpItemToCampfire(item, idx) then
					toFire += 1
				end
			end
		end
	end

	return grabbed, toFire
end

local function processNextChestStepSmooth()
	if not OpenChestRE then
		updateChestLootStatus("❌ Thiếu remote RequestOpenItemChest")
		return
	end

	initItemsAndChestCache()

	local targetChest = nil
	local r = root()
	local rPos = r and r.Position
	local bestDist = math.huge

	for chest, _ in pairs(cachedChests) do
		if chest and chest.Parent then
			local p = partOf(chest)
			if p then
				local d = rPos and (p.Position - rPos).Magnitude or 0
				local priorityPenalty = openedChests[chest] and 5000 or 0
				if (d + priorityPenalty) < bestDist then
					bestDist = d + priorityPenalty
					targetChest = chest
				end
			end
		else
			cachedChests[chest] = nil
		end
	end

	if not targetChest then
		local ammoGot = collectCachedAmmoBatch()
		updateChestLootStatus(
			string.format("⚡ Nhặt:%d | →Lửa:%d | Đạn:%d (+%d)",
				totalItemsLooted, totalSentToFire, totalAmmoCollected, ammoGot)
		)
		return
	end

	if not openedChests[targetChest] then
		pcall(OpenChestRE.FireServer, OpenChestRE, targetChest)
		openedChests[targetChest] = true
		totalChestsOpened += 1
	end

	local grabbed, toFire = processChestLootSmooth(targetChest)
	local ammoGot = collectCachedAmmoBatch()

	updateChestLootStatus(
		string.format("⚡ Rương:%d | Nhặt:%d (+%d) | →Lửa:%d (+%d) | Đạn:%d",
			totalChestsOpened, totalItemsLooted, grabbed, totalSentToFire, toFire, totalAmmoCollected)
	)
end

task.spawn(function()
	while true do
		if CFG.AutoChestAndLoot then
			pcall(processNextChestStepSmooth)
			task.wait(STEP_WAIT_SECONDS)
		else
			task.wait(0.4)
		end
	end
end)

--========================================================
-- EVENT-CACHED AUTO COLLECT ALL COINS (ZERO LAG)
--========================================================

local coinStatusText = "Chờ bật tự động nhặt xu..."
local coinStatusLbl  = nil
local totalCollectedCoins = 0
local cachedCoins = {}

local function updateCoinStatus(txt)
	coinStatusText = txt
	if coinStatusLbl and coinStatusLbl.Parent then
		coinStatusLbl.Text = txt
	end
end

local function isCoinObject(obj)
	if not obj then return false end
	local okName, name = pcall(function() return obj.Name end)
	return okName and hasKey(name, COIN_KEYS)
end

local coinCacheInitialized = false
local function initCoinCache()
	if coinCacheInitialized then return end
	coinCacheInitialized = true

	local itemsFolder = Workspace:FindFirstChild("Items")
	local targetRoot  = itemsFolder or Workspace

	task.spawn(function()
		local all = targetRoot:GetDescendants()
		for i = 1, #all do
			local o = all[i]
			if isCoinObject(o) then cachedCoins[o] = true end
			if i % 800 == 0 then task.wait() end
		end
	end)

	targetRoot.DescendantAdded:Connect(function(o)
		if isCoinObject(o) then cachedCoins[o] = true end
	end)

	targetRoot.DescendantRemoving:Connect(function(o)
		cachedCoins[o] = nil
	end)
end

local function collectAllCoinsOnce()
	if not CollectCoinRF then
		updateCoinStatus("❌ Thiếu remote RequestCollectCoints")
		return 0
	end

	initCoinCache()

	local toCollect = {}
	for coin, _ in pairs(cachedCoins) do
		if coin and coin.Parent then
			table.insert(toCollect, coin)
		else
			cachedCoins[coin] = nil
		end
	end

	if #toCollect == 0 then
		updateCoinStatus("⚠️ Chưa thấy xu (Tổng: " .. totalCollectedCoins .. ")")
		return 0
	end

	local collected = 0
	for _, coin in ipairs(toCollect) do
		if not CFG.AutoCollectCoins then break end
		local ok = pcall(CollectCoinRF.InvokeServer, CollectCoinRF, coin)
		if ok then
			cachedCoins[coin] = nil
			collected += 1
			totalCollectedCoins += 1
		end
		task.wait(0.05)
	end

	updateCoinStatus(
		string.format("🪙 Đã nhặt +%d xu (Tổng: %d)", collected, totalCollectedCoins)
	)
	return collected
end

task.spawn(function()
	while true do
		task.wait(1.2)
		if CFG.AutoCollectCoins then
			pcall(collectAllCoinsOnce)
		end
	end
end)

--========================================================
-- COUNTER, KILL AURA & TP AUTO CHOP (INDEPENDENT LOOPS)
--========================================================

local hitCounter = 0
local function resetCounter() hitCounter = 0 end
Workspace.ChildAdded:Connect(function(c)
	if c.Name == "Map" then
		resetCounter()
		cachedFirePart = nil
		cachedScrapperPart = nil
	end
end)
Workspace.ChildRemoved:Connect(function(c)
	if c.Name == "Map" then
		resetCounter()
		cachedFirePart = nil
		cachedScrapperPart = nil
	end
end)

local function nextId()
	hitCounter += 1
	return hitCounter .. "_" .. TOOL_SUFFIX
end

local function hitOnce(tool, target, p)
	if not DamageRF or not target or not target.Parent or not p or not p.Parent then
		return false
	end
	local ok = pcall(DamageRF.InvokeServer, DamageRF,
		target, tool, nextId(), CFrame.new(p.Position), false)
	if HitSoundRE then
		pcall(HitSoundRE.FireServer, HitSoundRE, "FireAllClients", target, tool)
	end
	return ok == true
end

local function equipToolSafe(tool)
	if EquipRE and tool then
		pcall(EquipRE.FireServer, EquipRE, "FireAllClients", tool)
		task.wait(0.03)
	end
end

local function unequipToolSafe(tool)
	if UnequipRE and tool then
		pcall(UnequipRE.FireServer, UnequipRE, "FireAllClients", tool)
		task.wait(0.025)
	end
end

local function swingBatch(tool, targets)
	if not (EquipRE and UnequipRE and DamageRF) or #targets == 0 then return end
	equipToolSafe(tool)
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
		if i < limit then task.wait(0.05) end
	end
	unequipToolSafe(tool)
end

local SCAN_FOLDERS = { "Characters", "Enemies", "Mobs", "NPCs" }
local function getAnimals(r)
	local out, ch, seen = {}, Player.Character, {}
	local maxDSq = CFG.KillRadius * CFG.KillRadius
	local rPos   = r.Position

	local function tryAdd(o)
		if seen[o] or o == ch or childSet[o] then return end
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
local TREE_KEYS = { "Tree", "Pine", "Oak", "Birch", "Fir" }

local function isValidTreeModel(o)
	if not o or not o.Parent or not o:IsA("Model") then return false end
	if not hasKey(o.Name, TREE_KEYS) then return false end
	if hasKey(o.Name, { "Sapling", "Log", "Plank", "Scrap", "Chair" }) then return false end
	return partOf(o) ~= nil
end

local function getTrees(r, maxRadius)
	local out = {}
	local useLimit = type(maxRadius) == "number" and maxRadius > 0
	local maxDSq = useLimit and (maxRadius * maxRadius) or math.huge
	local rPos   = r.Position
	local now    = os.clock()

	local function tryAddTree(t)
		if skipTree[t] and now < skipTree[t] then return end
		if not isValidTreeModel(t) then return end
		local p = partOf(t); if not p then return end
		local d = p.Position - rPos
		local dSq = d.X*d.X + d.Y*d.Y + d.Z*d.Z
		if dSq <= maxDSq then
			table.insert(out, { m = t, p = p, dSq = dSq })
		end
	end

	local map = Workspace:FindFirstChild("Map")
	local folders = {
		map and map:FindFirstChild("Foliage"),
		map and map:FindFirstChild("Trees"),
		Workspace:FindFirstChild("Foliage"),
		Workspace:FindFirstChild("Trees"),
	}

	for _, folder in ipairs(folders) do
		if folder then
			for _, t in ipairs(folder:GetChildren()) do
				tryAddTree(t)
			end
		end
	end

	if #out == 0 then
		local scanRoot = map or Workspace
		for _, o in ipairs(scanRoot:GetDescendants()) do
			if o:IsA("Model") then
				tryAddTree(o)
			end
		end
	end

	table.sort(out, function(a, b) return a.dSq < b.dSq end)
	return out
end

local function tpToTreeAndChop(treeModel, treePart, tool)
	local r = root()
	if not (r and treeModel and treeModel.Parent and treePart and treePart.Parent) then
		return false
	end

	local targetPos = treePart.Position
	r.CFrame = CFrame.new(targetPos + Vector3.new(0, 3, -3.5), targetPos)
	task.wait(0.12)

	equipToolSafe(tool)
	local anyHit = false
	for _ = 1, 4 do
		if not CFG.AutoChop or not treeModel.Parent or not treePart.Parent then
			break
		end
		local rr = root()
		if rr then
			if (rr.Position - targetPos).Magnitude > 14 then
				rr.CFrame = CFrame.new(targetPos + Vector3.new(0, 3, -3.5), targetPos)
			end
			if hitOnce(tool, treeModel, treePart) then
				anyHit = true
			end
		end
		task.wait(math.max(CFG.Delay, 0.12))
	end
	unequipToolSafe(tool)

	return anyHit or (not treeModel.Parent)
end

task.spawn(function()
	while true do
		if CFG.KillAura then
			local r, tool = root(), getKillTool()
			if r and tool then
				local targets = getAnimals(r)
				if #targets > 0 then
					pcall(swingBatch, tool, targets)
				end
			end
			task.wait(CFG.Delay)
		else
			task.wait(0.25)
		end
	end
end)

task.spawn(function()
	while true do
		if CFG.AutoChop then
			local r, tool = root(), getChopTool()
			if r and tool then
				local trees = getTrees(r, CFG.ChopRadius)
				if #trees == 0 then
					trees = getTrees(r, nil)
				end
				if #trees > 0 then
					local chosen = trees[1]
					local ok = false
					pcall(function()
						ok = tpToTreeAndChop(chosen.m, chosen.p, tool)
					end)
					skipTree[chosen.m] = os.clock() + (ok and 3.5 or 1.5)
				end
			end
			task.wait(0.25)
		else
			task.wait(0.25)
		end
	end
end)

--========================================================
-- MOVEMENT, NOCLIP, FLY, GOD MODE (CAP 20) & BOUNDARIES ORBIT
--========================================================

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
	local c = Player.Character; if not c then return end
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

-- =====================================================
-- GOD MODE: DI CHUYỂN BÌNH THƯỜNG (KHÔNG BẮT) & GIỚI HẠN ĐỘ CAO = 20
-- =====================================================

local GOD_MAX_HEIGHT = 20
local godHeight      = GOD_MAX_HEIGHT -- giới hạn tối đa 20 studs
local godConn        = nil
local godBV, godBG

local function cleanupGodInstances()
	if godConn then godConn:Disconnect(); godConn = nil end
	if godBV and godBV.Parent then godBV:Destroy() end
	if godBG and godBG.Parent then godBG:Destroy() end
	godBV, godBG = nil, nil
end

local function stopGodMode()
	CFG.GodMode = false
	cleanupGodInstances()
	local h = hum()
	if h then
		h.PlatformStand = false
		h.AutoRotate    = true
	end
end

local function startGodMode()
	cleanupGodInstances()
	godHeight = math.clamp(godHeight, 5, GOD_MAX_HEIGHT)
	CFG.GodMode = true

	local r, h = root(), hum()
	if not (r and h) then return end

	-- Không khóa di chuyển (không bật PlatformStand / không bắt buộc đứng yên)
	h.PlatformStand = false
	h.AutoRotate    = true

	-- Chỉ giới hạn độ cao tối đa khi vượt quá groundY + godHeight (tối đa 20)
	godBV = Instance.new("BodyVelocity")
	godBV.MaxForce = Vector3.new(0, 1e6, 0) -- chỉ can thiệp trục Y nếu vượt độ cao giới hạn
	godBV.Velocity = Vector3.zero
	godBV.Parent   = r

	local godRayParams = RaycastParams.new()
	godRayParams.FilterType = Enum.RaycastFilterType.Exclude

	local groundY = 0
	if Player.Character then
		godRayParams.FilterDescendantsInstances = { Player.Character }
	end
	local initRay = Workspace:Raycast(r.Position, Vector3.new(0, -500, 0), godRayParams)
	if initRay then groundY = initRay.Position.Y end

	local maxAllowedY = groundY + math.min(godHeight, GOD_MAX_HEIGHT)
	if r.Position.Y > maxAllowedY then
		r.CFrame = CFrame.new(r.Position.X, maxAllowedY, r.Position.Z) * (r.CFrame - r.CFrame.Position)
	end

	godConn = RunService.Heartbeat:Connect(function()
		local rr, hh = root(), hum()
		if not (rr and hh and godBV and godBV.Parent) then
			stopGodMode(); return
		end
		if not CFG.GodMode then stopGodMode(); return end

		if Player.Character then
			godRayParams.FilterDescendantsInstances = { Player.Character }
		end
		local ray = Workspace:Raycast(rr.Position, Vector3.new(0, -500, 0), godRayParams)
		if ray then groundY = ray.Position.Y end

		local capY = groundY + math.min(godHeight, GOD_MAX_HEIGHT)
		if rr.Position.Y > capY + 0.5 then
			godBV.MaxForce = Vector3.new(0, 1e6, 0)
			godBV.Velocity = Vector3.new(0, -25, 0)
		elseif rr.Position.Y > capY then
			rr.CFrame = CFrame.new(rr.Position.X, capY, rr.Position.Z) * (rr.CFrame - rr.CFrame.Position)
			godBV.MaxForce = Vector3.new(0, 0, 0)
			godBV.Velocity = Vector3.zero
		else
			-- Cho phép di chuyển & nhảy tự do dưới giới hạn độ cao 20
			godBV.MaxForce = Vector3.new(0, 0, 0)
			godBV.Velocity = Vector3.zero
		end

		-- Tự động giữ máu tối đa
		if hh.Health < hh.MaxHealth then
			hh.Health = hh.MaxHealth
		end
	end)
end

-- =====================================================
-- QUÉT BOUNDARIES & BAY VÒNG TRÒN NHANH Ở ĐỘ CAO CAO TRONG BOUNDARIES
-- =====================================================

local circleAltitude = 55 -- độ cao bay (cao)
local circleSpeed    = 65 -- tốc độ bay vòng tròn nhanh (studs/s)
local circleStatusText = "Chờ bật bay vòng tròn trong Boundaries..."
local circleStatusLbl  = nil

local circleConn
local circleBV, circleBG
local cachedBounds = nil

local function updateCircleStatus(txt)
	circleStatusText = txt
	if circleStatusLbl and circleStatusLbl.Parent then
		circleStatusLbl.Text = txt
	end
end

local function scanBoundariesScope()
	local mapFolder = Workspace:FindFirstChild("Map")
	local searchTargets = {}

	local function collectFrom(container)
		if not container then return end
		for _, obj in ipairs(container:GetDescendants()) do
			local okN, n = pcall(function() return obj.Name end)
			if okN and type(n) == "string" and string.find(string.lower(n), "boundar", 1, true) then
				if obj:IsA("BasePart") then
					table.insert(searchTargets, obj)
				elseif obj:IsA("Model") then
					local p = partOf(obj)
					if p then table.insert(searchTargets, p) end
				end
			end
		end
	end

	collectFrom(mapFolder)
	if #searchTargets == 0 then
		for _, child in ipairs(Workspace:GetChildren()) do
			local okN, n = pcall(function() return child.Name end)
			if okN and type(n) == "string" and string.find(string.lower(n), "boundar", 1, true) then
				if child:IsA("BasePart") then
					table.insert(searchTargets, child)
				elseif child:IsA("Model") or child:IsA("Folder") then
					collectFrom(child)
				end
			end
		end
	end

	if #searchTargets == 0 then
		-- Fallback: dùng tâm lửa trại hoặc vị trí hiện tại
		local fp = getFirePart()
		local r = root()
		local center = fp and fp.Position or (r and r.Position or Vector3.zero)
		return {
			centerX = center.X,
			centerZ = center.Z,
			groundY = center.Y,
			radius  = 110,
			minX    = center.X - 110,
			maxX    = center.X + 110,
			minZ    = center.Z - 110,
			maxZ    = center.Z + 110,
			count   = 0,
		}
	end

	local minX, maxX = math.huge, -math.huge
	local minZ, maxZ = math.huge, -math.huge
	local sumY, countY = 0, 0

	for _, part in ipairs(searchTargets) do
		local pos = part.Position
		local halfX = part.Size.X * 0.5
		local halfZ = part.Size.Z * 0.5
		minX = math.min(minX, pos.X - halfX)
		maxX = math.max(maxX, pos.X + halfX)
		minZ = math.min(minZ, pos.Z - halfZ)
		maxZ = math.max(maxZ, pos.Z + halfZ)
		sumY += pos.Y
		countY += 1
	end

	local cx = (minX + maxX) * 0.5
	local cz = (minZ + maxZ) * 0.5
	local halfSpanX = math.max((maxX - minX) * 0.5, 25)
	local halfSpanZ = math.max((maxZ - minZ) * 0.5, 25)
	local safeRadius = math.max(math.min(halfSpanX, halfSpanZ) - 6, 15)
	local baseGroundY = countY > 0 and (sumY / countY) or 0

	return {
		centerX = cx,
		centerZ = cz,
		groundY = baseGroundY,
		radius  = safeRadius,
		minX    = minX + 4,
		maxX    = maxX - 4,
		minZ    = minZ + 4,
		maxZ    = maxZ - 4,
		count   = #searchTargets,
	}
end

local function clampPointInsideBounds(x, z, b)
	local dx = x - b.centerX
	local dz = z - b.centerZ
	local dist = math.sqrt(dx * dx + dz * dz)
	local maxR = math.max(b.radius, 10)

	if dist > maxR and dist > 0 then
		local scale = maxR / dist
		x = b.centerX + dx * scale
		z = b.centerZ + dz * scale
	end

	x = math.clamp(x, b.minX, b.maxX)
	z = math.clamp(z, b.minZ, b.maxZ)
	return x, z
end

local function cleanupCircleInstances()
	if circleConn then circleConn:Disconnect(); circleConn = nil end
	if circleBV and circleBV.Parent then circleBV:Destroy() end
	if circleBG and circleBG.Parent then circleBG:Destroy() end
	circleBV, circleBG = nil, nil
end

local function stopCircleBoundaries()
	CFG.CircleBoundaries = false
	cleanupCircleInstances()
	local h = hum()
	if h then
		h.PlatformStand = false
		h.AutoRotate    = true
	end
	updateCircleStatus("Tắt bay vòng tròn Boundaries")
end

local function startCircleBoundaries()
	cleanupCircleInstances()
	CFG.CircleBoundaries = true

	local r, h = root(), hum()
	if not (r and h) then
		updateCircleStatus("❌ Không tìm thấy nhân vật")
		return
	end

	cachedBounds = scanBoundariesScope()
	local b = cachedBounds

	h.PlatformStand = true
	h.AutoRotate    = false

	circleBV = Instance.new("BodyVelocity")
	circleBV.MaxForce = Vector3.new(1e6, 1e6, 1e6)
	circleBV.Velocity = Vector3.zero
	circleBV.Parent   = r

	circleBG = Instance.new("BodyGyro")
	circleBG.MaxTorque = Vector3.new(1e6, 1e6, 1e6)
	circleBG.P         = 1e4
	circleBG.Parent    = r

	local startDX = r.Position.X - b.centerX
	local startDZ = r.Position.Z - b.centerZ
	local angle = math.atan2(startDZ, startDX)
	local orbitRadius = math.min(math.max(b.radius * 0.78, 12), b.radius)

	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude

	local lastScan = os.clock()
	local lastStatus = 0

	updateCircleStatus(string.format("🌀 Quét %d Boundaries · R:%.0f · Cao:%d", b.count, orbitRadius, circleAltitude))

	circleConn = RunService.Heartbeat:Connect(function(dt)
		local rr, hh = root(), hum()
		if not (rr and hh and circleBV and circleBV.Parent and circleBG and circleBG.Parent) then
			stopCircleBoundaries(); return
		end
		if not CFG.CircleBoundaries then
			stopCircleBoundaries(); return
		end

		if os.clock() - lastScan > 4 then
			lastScan = os.clock()
			cachedBounds = scanBoundariesScope()
			b = cachedBounds
			orbitRadius = math.min(math.max(b.radius * 0.78, 12), b.radius)
		end

		local angularVel = circleSpeed / math.max(orbitRadius, 8)
		angle += angularVel * dt

		local rawX = b.centerX + math.cos(angle) * orbitRadius
		local rawZ = b.centerZ + math.sin(angle) * orbitRadius
		local goalX, goalZ = clampPointInsideBounds(rawX, rawZ, b)

		if Player.Character then
			rayParams.FilterDescendantsInstances = { Player.Character }
		end
		local ray = Workspace:Raycast(Vector3.new(goalX, rr.Position.Y + 20, goalZ), Vector3.new(0, -500, 0), rayParams)
		local baseGround = ray and ray.Position.Y or b.groundY
		local goalY = baseGround + circleAltitude

		local goalPos = Vector3.new(goalX, goalY, goalZ)
		local delta = goalPos - rr.Position
		local desiredVel = delta * 12

		if desiredVel.Magnitude > circleSpeed * 1.4 then
			desiredVel = desiredVel.Unit * (circleSpeed * 1.4)
		end

		circleBV.Velocity = desiredVel
		local lookTarget = Vector3.new(
			goalX - math.sin(angle) * 10,
			goalY,
			goalZ + math.cos(angle) * 10
		)
		circleBG.CFrame = CFrame.lookAt(rr.Position, lookTarget)

		if hh.Health < hh.MaxHealth then
			hh.Health = hh.MaxHealth
		end

		if os.clock() - lastStatus > 0.8 then
			lastStatus = os.clock()
			updateCircleStatus(string.format("🌀 Bay cao %d · R:%.0f · Tốc:%d", circleAltitude, orbitRadius, circleSpeed))
		end
	end)
end

-- =====================================================
-- AUTO MỞ MAP ĐỊNH KỲ
-- =====================================================

local autoMapStatusText = "Chờ bật Auto Mở Map..."
local autoMapStatusLbl  = nil
local totalMapReveals   = 0

local function updateAutoMapStatus(txt)
	autoMapStatusText = txt
	if autoMapStatusLbl and autoMapStatusLbl.Parent then
		autoMapStatusLbl.Text = txt
	end
end

local function revealMapOnce()
	if not MapRE then
		updateAutoMapStatus("❌ Thiếu remote MapCellsDiscovered")
		return false
	end
	local cells = {}
	for row = 1, 64 do
		for col = 1, 64 do table.insert(cells, {Row=row, Col=col}) end
	end
	for i = 1, #cells, 200 do
		local b = {}
		for j = i, math.min(i+199, #cells) do table.insert(b, cells[j]) end
		pcall(MapRE.FireServer, MapRE, b, {})
		task.wait(0.08)
	end
	totalMapReveals += 1
	updateAutoMapStatus(string.format("🗺️ Đã mở Map (Lần: %d)", totalMapReveals))
	return true
end

task.spawn(function()
	while true do
		if CFG.AutoMap then
			pcall(revealMapOnce)
			task.wait(6)
		else
			task.wait(0.5)
		end
	end
end)

Player.CharacterAdded:Connect(function()
	task.wait(0.8)
	resetCounter()
	if CFG.Fly then startFly() end
	if CFG.GodMode then startGodMode() end
	if CFG.CircleBoundaries then startCircleBoundaries() end
end)

--========================================================
-- FULLBRIGHT & FIX LAG PRO
--========================================================

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

--========================================================
-- AUTO EAT CARROT & ESP TRẺ (EVENT-DRIVEN)
--========================================================

local eatStatusText = "Chờ bật ăn carrot..."
local eatStatusLbl  = nil

local function updateEatStatus(txt)
	eatStatusText = txt
	if eatStatusLbl and eatStatusLbl.Parent then
		eatStatusLbl.Text = txt
	end
end

task.spawn(function()
	while true do
		task.wait(2)
		if CFG.AutoEat then
			if not ConsumeRF then
				updateEatStatus("❌ Thiếu remote RequestConsumeItem")
				continue
			end
			if not getnilinstances then
				updateEatStatus("❌ Executor thiếu getnilinstances")
				continue
			end
			local carrots = getNilByName("Carrot")
			if #carrots == 0 then
				updateEatStatus("⚠️ Không tìm thấy Carrot")
				continue
			end
			local ate = 0
			for _, carrot in ipairs(carrots) do
				if not CFG.AutoEat then break end
				local ok = pcall(ConsumeRF.InvokeServer, ConsumeRF, carrot)
				if ok then
					ate += 1
					updateEatStatus(string.format("✅ Đã ăn %d carrot", ate))
				end
				task.wait(0.3)
			end
		end
	end
end)

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
		task.wait(0.6)
		if CFG.ESPChild then
			for m, pair in pairs(espTag) do
				if not m.Parent then
					if pair.hl  and pair.hl.Parent  then pair.hl:Destroy()  end
					if pair.bb  and pair.bb.Parent  then pair.bb:Destroy()  end
					if pair.conn then pair.conn:Disconnect() end
					espTag[m] = nil
				end
			end
			for m, _ in pairs(childSet) do
				if m.Parent and not espTag[m] then
					local saved = isChildAlreadyRescued(m)
					local espColor = saved and Color3.fromRGB(100, 255, 130) or Color3.fromRGB(255, 220, 80)

					local hl = Instance.new("Highlight")
					hl.FillColor        = espColor
					hl.OutlineColor     = espColor
					hl.FillTransparency = 0.45
					hl.Adornee = m; hl.Parent = m

					local adornPart = partOf(m)
					local bb, lblConn
					if adornPart then
						bb = Instance.new("BillboardGui")
						bb.Adornee     = adornPart
						bb.Size        = UDim2.new(0,170,0,46)
						bb.StudsOffset = Vector3.new(0,3,0)
						bb.AlwaysOnTop = true; bb.Parent = adornPart

						local lbl = Instance.new("TextLabel")
						lbl.Size               = UDim2.new(1,0,1,0)
						lbl.BackgroundTransparency = 1
						lbl.TextColor3         = espColor
						lbl.TextStrokeColor3   = Color3.new(0,0,0)
						lbl.TextStrokeTransparency = 0.3
						lbl.Font               = Enum.Font.GothamBold
						lbl.TextSize           = 13; lbl.Parent = bb

						lblConn = RunService.Heartbeat:Connect(function()
							if not m.Parent or not CFG.ESPChild then
								lblConn:Disconnect(); return
							end
							local rr = root(); local pp = partOf(m)
							local statusTag = isChildAlreadyRescued(m) and " [Đã cứu]" or ""
							if rr and pp then
								local dist = math.floor((pp.Position - rr.Position).Magnitude)
								lbl.Text = m.Name .. statusTag .. "\n📍 " .. dist .. " studs"
							else
								lbl.Text = m.Name .. statusTag
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

--========================================================
-- TP, PULL, WIDE ONE-BY-ONE FIRE FUEL & CHECK-FIRST SCRAPPER
--========================================================

local function tpTo(m)
	local r, p = root(), partOf(m)
	if r and p then r.CFrame = CFrame.new(p.Position + Vector3.new(0,4,0)) end
end

local function tpCampfire()
	local fp = getFirePart(); local r = root()
	if fp and r then r.CFrame = CFrame.new(fp.Position + Vector3.new(0,4,0)) end
end

local function tpScrapper()
	local sp = getScrapperPart(); local r = root()
	if sp and r then r.CFrame = CFrame.new(sp.Position + Vector3.new(0,4,0)) end
end

local function pullPlayerToMe(plr)
	if not plr or plr == Player then return false end
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
	local ch = Player.Character
	local found = {}
	local itemsFolder = Workspace:FindFirstChild("Items")
	local searchList  = itemsFolder and itemsFolder:GetChildren() or Workspace:GetChildren()

	for _, o in ipairs(searchList) do
		if (ch and o:IsDescendantOf(ch)) or Players:GetPlayerFromCharacter(o) or isWorldArchitecture(o) then
			continue
		end

		local okName, oName = pcall(function() return o.Name end)
		if okName and (o:IsA("Model") or o:IsA("BasePart")) and matchesExact(oName, nameList) then
			local p = partOf(o)
			if p then
				local d = (p.Position - r.Position).Magnitude
				table.insert(found, { obj=o, dist=d })
			end
		end
	end

	table.sort(found, function(a,b) return a.dist < b.dist end)
	local count = 0
	for i = 1, #found do
		local o = found[i].obj
		local rr = root(); if not rr then break end
		local spreadX = ((count % 3) - 1) * 1.4
		local liftY   = 1.2 + math.floor(count / 3) * 0.6
		local goalCF  = rr.CFrame * CFrame.new(spreadX, liftY, -3)
		if moveItemToCFrame(o, goalCF) then
			count += 1
		end
		if count % 15 == 0 then task.wait(0.03) end
	end
	return count
end

-- WIDE CONTINUOUS CAMPFIRE AUTO FUEL (ONE ITEM AT A TIME TO FIRE)
local fireStatusText = "Chờ bật auto dồn lửa trại..."
local fireStatusLbl  = nil
local isDumpingFuel  = false
local totalFuelMoved = 0

local function updateFireStatus(txt)
	fireStatusText = txt
	if fireStatusLbl and fireStatusLbl.Parent then
		fireStatusLbl.Text = txt
	end
end

local function dumpFuelToFire()
	if isDumpingFuel then return 0 end
	isDumpingFuel = true

	local okRun, moved = pcall(function()
		local fp = getFirePart()
		if not fp or not fp.Parent then
			updateFireStatus("❌ Không tìm thấy Lửa trại")
			return 0
		end

		local ch = Player.Character
		local itemsFolder = Workspace:FindFirstChild("Items")
		local scanList = itemsFolder and itemsFolder:GetChildren() or Workspace:GetChildren()
		local count = 0

		for i = 1, #scanList do
			if not CFG.AutoDrop then break end
			local o = scanList[i]
			if o and o.Parent and (o:IsA("Model") or o:IsA("BasePart")) then
				local skip = (ch and o:IsDescendantOf(ch))
					or Players:GetPlayerFromCharacter(o) ~= nil
					or isWorldArchitecture(o)
				if not skip then
					local okN, oName = pcall(function() return o.Name end)
					if okN and matchesExact(oName, FUEL_EXACT) then
						local p = partOf(o)
						if p and (p.Position - fp.Position).Magnitude > 14 then
							local dropPos = fp.Position + Vector3.new(
								math.random(-20, 20) / 10,
								9 + (count % 5) * 0.6,
								math.random(-20, 20) / 10
							)
							if moveItemToCFrame(o, CFrame.new(dropPos)) then
								count += 1
								totalFuelMoved += 1
								updateFireStatus(string.format("🔥 Đang TP từng món: %s (Tổng: %d)", tostring(oName), totalFuelMoved))
								task.wait(0.05)
							end
						end
					end
				end
			end
		end

		if count == 0 then
			updateFireStatus(string.format("🔥 Quét liên tục · Tổng: %d", totalFuelMoved))
		end
		return count
	end)

	isDumpingFuel = false
	if not okRun then
		cachedFirePart = nil
		updateFireStatus("⚠️ Đang làm mới vị trí lửa trại...")
		return 0
	end
	return moved or 0
end

task.spawn(function()
	while true do
		if CFG.AutoDrop then
			pcall(dumpFuelToFire)
			task.wait(0.1)
		else
			task.wait(0.3)
		end
	end
end)

-- =====================================================
-- FIX SCRAPPER: CHECK TRƯỚC, DRAG SAU
-- =====================================================

local scrapStatusText = "Chờ bật auto TP Scrapper..."
local scrapStatusLbl  = nil
local isMovingScrap   = false
local totalScrapMoved = 0

local function updateScrapStatus(txt)
	scrapStatusText = txt
	if scrapStatusLbl and scrapStatusLbl.Parent then
		scrapStatusLbl.Text = txt
	end
end

local function isValidScrapItem(obj)
	if not obj then return false end

	local okAlive = pcall(function() return obj.Parent end)
	if not okAlive or not obj.Parent then return false end

	if not (obj:IsA("Model") or obj:IsA("BasePart")) then return false end

	local okN, name = pcall(function() return obj.Name end)
	if not okN or type(name) ~= "string" then return false end
	if not SCRAP_EXACT_SET[name] then return false end

	local mapFolder = Workspace:FindFirstChild("Map")
	if mapFolder and obj:IsDescendantOf(mapFolder) then return false end

	local ch = Player.Character
	if ch and obj:IsDescendantOf(ch) then return false end
	if Players:GetPlayerFromCharacter(obj) then return false end

	if obj:IsA("BasePart") then
		if obj.Anchored then return false end
		local sz = obj.Size
		if sz.X > 5 or sz.Y > 5 or sz.Z > 5 then return false end
	end

	if obj:IsA("Model") then
		local ok, _, sz = pcall(function() return obj:GetBoundingBox() end)
		if ok and sz and (sz.X > 7 or sz.Y > 7 or sz.Z > 7) then return false end
		if not partOf(obj) then return false end
	end

	return true
end

local function moveScrapItem(obj, goalCF)
	if not obj or not obj.Parent then return false end
	if not isValidScrapItem(obj) then return false end

	local ok = pcall(function()
		if DragRE then pcall(DragRE.FireServer, DragRE, obj) end
		if obj:IsA("Model") then
			obj:PivotTo(goalCF)
		elseif obj:IsA("BasePart") then
			obj.CFrame = goalCF
		end
	end)
	if StopDragRE then pcall(StopDragRE.FireServer, StopDragRE, obj) end
	return ok == true
end

local function sendScrapToScrapper()
	if isMovingScrap then return 0 end
	isMovingScrap = true

	local okRun, moved = pcall(function()
		local sp = getScrapperPart()
		if not sp or not sp.Parent then
			updateScrapStatus("❌ Không tìm thấy Scrapper")
			return 0
		end

		local itemsFolder = Workspace:FindFirstChild("Items")
		if not itemsFolder then
			local SKIP = { Map=true, Characters=true, Terrain=true,
						   Enemies=true, Mobs=true, NPCs=true, Campground=true }
			local count = 0
			for _, o in ipairs(Workspace:GetChildren()) do
				if not CFG.AutoScrapper then break end
				if SKIP[o.Name] then continue end
				if isValidScrapItem(o) then
					local p = partOf(o)
					if p and (p.Position - sp.Position).Magnitude > 11 then
						local dropCF = CFrame.new(sp.Position + Vector3.new(
							math.random(-10,10)/10, 8+(count%4)*0.7, math.random(-10,10)/10))
						if moveScrapItem(o, dropCF) then
							count += 1; totalScrapMoved += 1
							updateScrapStatus(string.format("⚙️ %s → Scrapper (Tổng: %d)", o.Name, totalScrapMoved))
							task.wait(0.06)
						end
					end
				end
			end
			return count
		end

		local count = 0
		for _, o in ipairs(itemsFolder:GetChildren()) do
			if not CFG.AutoScrapper then break end
			if isValidScrapItem(o) then
				local p = partOf(o)
				if p and (p.Position - sp.Position).Magnitude > 11 then
					local dropCF = CFrame.new(sp.Position + Vector3.new(
						math.random(-10,10)/10, 8+(count%4)*0.7, math.random(-10,10)/10))
					if moveScrapItem(o, dropCF) then
						count += 1; totalScrapMoved += 1
						updateScrapStatus(string.format("⚙️ %s → Scrapper (Tổng: %d)", o.Name, totalScrapMoved))
						task.wait(0.06)
					end
				end
			end
		end

		if count == 0 then
			updateScrapStatus(string.format("⚙️ Đang quét · Đã rớt: %d", totalScrapMoved))
		end
		return count
	end)

	isMovingScrap = false
	if not okRun then
		cachedScrapperPart = nil
		updateScrapStatus("⚠️ Lỗi — làm mới Scrapper...")
		return 0
	end
	return moved or 0
end

task.spawn(function()
	while true do
		if CFG.AutoScrapper then
			pcall(sendScrapToScrapper)
			task.wait(0.1)
		else
			task.wait(0.3)
		end
	end
end)

local function plantAllSaplings(statusLbl)
	local function setStatus(txt)
		if statusLbl and statusLbl.Parent then
			statusLbl.Text = txt
		end
	end
	if not PlantRE then
		setStatus("❌ Thiếu remote RequestPlantItem"); return 0
	end
	if not getnilinstances then
		setStatus("❌ Executor thiếu getnilinstances"); return 0
	end
	setStatus("🔍 Đang quét mầm cây...")
	local saplings = getNilByName("Sapling")
	if #saplings == 0 then
		setStatus("⚠️ Không tìm thấy mầm cây nào"); return 0
	end
	setStatus(string.format("🌱 Tìm thấy %d mầm — đang trồng...", #saplings))
	local r = root()
	if not r then
		setStatus("❌ Không tìm thấy nhân vật"); return 0
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
		setStatus(string.format("✅ Đã trồng %d/%d mầm cây", count, #saplings))
	else
		setStatus("⚠️ Trồng thất bại — thử đứng sát đất")
	end
	return count
end

local function revealMap()
	revealMapOnce()
end

--========================================================
-- SUNSET UI LIBRARY
--========================================================

local Library = {}

function Library:CreateWindow(title)
	local gui = Instance.new("ScreenGui")
	gui.Name = "SunsetUI"
	gui.Parent = CoreGui.Parent and CoreGui or PlayerGui
	pcall(function() gui.Parent = CoreGui end)
	if gui.Parent ~= CoreGui then
		gui.Parent = PlayerGui
	end
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 100

	local currentColor = Color3.fromRGB(255, 128, 0)
	local toggleButton = nil
	local toggleButtonSize = 40
	local mainFrame = nil
	local sidebarFrame = nil
	local titleLabel = nil
	local contentFrame = nil

	local function updateThemeColor(newColor)
		currentColor = newColor
		if mainFrame and mainFrame:FindFirstChild("UIStroke") then
			mainFrame.UIStroke.Color = currentColor
		end
		if sidebarFrame and sidebarFrame:FindFirstChild("UIStroke") then
			sidebarFrame.UIStroke.Color = currentColor
		end
		if titleLabel then
			titleLabel.TextColor3 = currentColor
		end
		if toggleButton then
			toggleButton.BackgroundColor3 = currentColor
		end
		if contentFrame then
			for _, tab in ipairs(contentFrame:GetChildren()) do
				if tab:IsA("ScrollingFrame") then
					tab.ScrollBarImageColor3 = currentColor
				end
			end
		end
	end

	local function updateToggleButtonSize(newSize)
		toggleButtonSize = newSize
		if toggleButton then
			toggleButton.Size = UDim2.new(0, newSize, 0, newSize)
			toggleButton.Position = UDim2.new(0, 10, 0.5, -(newSize / 2))
		end
	end

	local function Notify(titulo, texto, duracao)
		pcall(function()
			game:GetService("StarterGui"):SetCore("SendNotification", {
				Title = titulo,
				Text = texto,
				Duration = duracao or 5,
			})
		end)
	end

	toggleButton = Instance.new("ImageButton")
	toggleButton.Size = UDim2.new(0, toggleButtonSize, 0, toggleButtonSize)
	toggleButton.Position = UDim2.new(0, 10, 0.5, -(toggleButtonSize / 2))
	toggleButton.BackgroundColor3 = currentColor
	toggleButton.Image = "rbxassetid://97939372251102"
	toggleButton.ZIndex = 20
	toggleButton.Parent = gui
	Instance.new("UICorner", toggleButton).CornerRadius = UDim.new(1, 0)

	local draggingBtn, dragStartBtn, startPosBtn, movedBtn = false, nil, nil, false
	toggleButton.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			draggingBtn = true
			movedBtn = false
			dragStartBtn = input.Position
			startPosBtn = toggleButton.Position
		end
	end)
	toggleButton.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			draggingBtn = false
		end
	end)
	UIS.InputChanged:Connect(function(input)
		if draggingBtn and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
			local delta = input.Position - dragStartBtn
			if delta.Magnitude > 5 then movedBtn = true end
			toggleButton.Position = UDim2.new(startPosBtn.X.Scale, startPosBtn.X.Offset + delta.X, startPosBtn.Y.Scale, startPosBtn.Y.Offset + delta.Y)
		end
	end)

	mainFrame = Instance.new("Frame")
	mainFrame.Size = UDim2.new(0, 450, 0, 380)
	mainFrame.Position = UDim2.new(0.5, -225, 0.5, -190)
	mainFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	mainFrame.BackgroundTransparency = 0.2
	mainFrame.Parent = gui
	Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 8)

	local draggingMain, dragStart, startPos = false, nil, nil
	mainFrame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			draggingMain = true
			dragStart = input.Position
			startPos = mainFrame.Position
		end
	end)
	mainFrame.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			draggingMain = false
		end
	end)
	UIS.InputChanged:Connect(function(input)
		if draggingMain and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
			local delta = input.Position - dragStart
			mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)

	local strokeMain = Instance.new("UIStroke")
	strokeMain.Color = currentColor
	strokeMain.Thickness = 1
	strokeMain.Parent = mainFrame

	sidebarFrame = Instance.new("Frame")
	sidebarFrame.Size = UDim2.new(0, 90, 1, 0)
	sidebarFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	sidebarFrame.BackgroundTransparency = 0.2
	sidebarFrame.Parent = mainFrame
	Instance.new("UICorner", sidebarFrame).CornerRadius = UDim.new(0, 8)

	local strokeSidebar = Instance.new("UIStroke")
	strokeSidebar.Color = currentColor
	strokeSidebar.Parent = sidebarFrame

	titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, 0, 0, 30)
	titleLabel.Text = title
	titleLabel.TextColor3 = currentColor
	titleLabel.BackgroundTransparency = 1
	titleLabel.TextSize = 14
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.Parent = sidebarFrame

	contentFrame = Instance.new("Frame")
	contentFrame.Size = UDim2.new(1, -90, 1, 0)
	contentFrame.Position = UDim2.new(0, 90, 0, 0)
	contentFrame.BackgroundTransparency = 1
	contentFrame.Parent = mainFrame

	local currentTab
	local tabY = 35
	local tabOrderList = {}

	local windowFunctions = {}

	function windowFunctions:CreateTab(name)
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1, -10, 0, 28)
		btn.Position = UDim2.new(0, 5, 0, tabY)
		btn.Text = name
		btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
		btn.TextColor3 = currentColor
		btn.Font = Enum.Font.GothamBold
		btn.TextSize = 11
		btn.Parent = sidebarFrame
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
		tabY = tabY + 33
		table.insert(tabOrderList, btn)

		local Tab = Instance.new("ScrollingFrame")
		Tab.Size = UDim2.new(1, 0, 1, 0)
		Tab.Visible = false
		Tab.Parent = contentFrame
		Tab.ScrollBarThickness = 4
		Tab.ScrollBarImageColor3 = currentColor
		Tab.BackgroundTransparency = 1
		Tab.BorderSizePixel = 0
		Tab.CanvasSize = UDim2.new(0, 0, 0, 0)
		Tab.ScrollingEnabled = true
		Tab.AutomaticCanvasSize = Enum.AutomaticSize.Y

		local layout = Instance.new("UIListLayout", Tab)
		layout.Padding = UDim.new(0, 8)
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.HorizontalAlignment = Enum.HorizontalAlignment.Center

		local pad = Instance.new("UIPadding", Tab)
		pad.PaddingTop = UDim.new(0, 8)
		pad.PaddingBottom = UDim.new(0, 10)

		btn.MouseButton1Click:Connect(function()
			for _, child in ipairs(sidebarFrame:GetChildren()) do
				if child:IsA("TextButton") then
					child.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
					child.TextColor3 = currentColor
				end
			end
			btn.BackgroundColor3 = currentColor
			btn.TextColor3 = Color3.fromRGB(0, 0, 0)
			if currentTab then currentTab.Visible = false end
			currentTab = Tab
			Tab.Visible = true
		end)

		local Elements = {}

		function Elements:AddSection(sectionTitle)
			local Section = {}
			local sectionFrame = Instance.new("Frame")
			sectionFrame.Size = UDim2.new(1, -12, 0, 0)
			sectionFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
			sectionFrame.BackgroundTransparency = 0.3
			sectionFrame.Parent = Tab
			sectionFrame.AutomaticSize = Enum.AutomaticSize.Y
			Instance.new("UICorner", sectionFrame).CornerRadius = UDim.new(0, 6)

			local stroke = Instance.new("UIStroke", sectionFrame)
			stroke.Color = currentColor
			stroke.Thickness = 1

			local sectionLayout = Instance.new("UIListLayout", sectionFrame)
			sectionLayout.Padding = UDim.new(0, 4)

			local titleLabelSection = Instance.new("TextLabel")
			titleLabelSection.Size = UDim2.new(1, 0, 0, 22)
			titleLabelSection.Text = " " .. sectionTitle
			titleLabelSection.BackgroundTransparency = 1
			titleLabelSection.TextColor3 = currentColor
			titleLabelSection.TextSize = 12
			titleLabelSection.Font = Enum.Font.GothamBold
			titleLabelSection.TextXAlignment = Enum.TextXAlignment.Left
			titleLabelSection.Parent = sectionFrame

			local container = Instance.new("Frame")
			container.Size = UDim2.new(1, 0, 0, 0)
			container.BackgroundTransparency = 1
			container.Parent = sectionFrame
			container.AutomaticSize = Enum.AutomaticSize.Y

			local clayout = Instance.new("UIListLayout", container)
			clayout.Padding = UDim.new(0, 6)
			clayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

			local cpad = Instance.new("UIPadding", container)
			cpad.PaddingBottom = UDim.new(0, 6)

			function Section:AddLabel(text)
				local l = Instance.new("TextLabel")
				l.Size = UDim2.new(1, -12, 0, 20)
				l.Text = text
				l.BackgroundTransparency = 1
				l.TextColor3 = Color3.fromRGB(220, 220, 220)
				l.Font = Enum.Font.Gotham
				l.TextSize = 11
				l.TextXAlignment = Enum.TextXAlignment.Left
				l.TextTruncate = Enum.TextTruncate.AtEnd
				l.Parent = container
				return l
			end

			function Section:AddButton(text, callback)
				local b = Instance.new("TextButton")
				b.Size = UDim2.new(1, -12, 0, 32)
				b.Text = text
				b.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
				b.TextColor3 = currentColor
				b.Font = Enum.Font.GothamBold
				b.TextSize = 11
				b.Parent = container
				Instance.new("UICorner", b).CornerRadius = UDim.new(0, 4)
				b.MouseButton1Click:Connect(function()
					if callback then pcall(callback) end
				end)
				return b
			end

			function Section:AddToggle(text, defaultOrCb, maybeCb)
				local default = false
				local callback = nil
				if type(defaultOrCb) == "boolean" then
					default = defaultOrCb
					callback = maybeCb
				else
					callback = defaultOrCb
				end

				local state = default == true
				local f = Instance.new("Frame")
				f.Size = UDim2.new(1, -12, 0, 36)
				f.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
				f.Parent = container
				Instance.new("UICorner", f).CornerRadius = UDim.new(0, 4)

				local label = Instance.new("TextLabel")
				label.Size = UDim2.new(1, -55, 1, 0)
				label.Position = UDim2.new(0, 10, 0, 0)
				label.Text = text
				label.BackgroundTransparency = 1
				label.TextColor3 = currentColor
				label.Font = Enum.Font.Gotham
				label.TextSize = 11
				label.TextXAlignment = Enum.TextXAlignment.Left
				label.TextTruncate = Enum.TextTruncate.AtEnd
				label.Parent = f

				local toggle = Instance.new("Frame")
				toggle.Size = UDim2.new(0, 40, 0, 20)
				toggle.Position = UDim2.new(1, -50, 0.5, -10)
				toggle.BackgroundColor3 = state and currentColor or Color3.fromRGB(50, 50, 50)
				toggle.Parent = f
				Instance.new("UICorner", toggle).CornerRadius = UDim.new(1, 0)

				local circle = Instance.new("Frame")
				circle.Size = UDim2.new(0, 16, 0, 16)
				circle.Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
				circle.BackgroundColor3 = state and Color3.fromRGB(0, 0, 0) or currentColor
				circle.Parent = toggle
				Instance.new("UICorner", circle).CornerRadius = UDim.new(1, 0)

				f.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
						state = not state
						local bgColor = state and currentColor or Color3.fromRGB(50, 50, 50)
						TweenService:Create(toggle, TweenInfo.new(0.2), { BackgroundColor3 = bgColor }):Play()
						TweenService:Create(circle, TweenInfo.new(0.2), {
							Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8),
							BackgroundColor3 = state and Color3.fromRGB(0, 0, 0) or currentColor
						}):Play()
						if callback then pcall(callback, state) end
					end
				end)

				return f
			end

			function Section:AddSlider(text, min, max, defaultOrCb, maybeCb)
				local default = min
				local callback = nil
				if type(defaultOrCb) == "number" then
					default = math.clamp(defaultOrCb, min, max)
					callback = maybeCb
				else
					callback = defaultOrCb
				end

				local value = default
				local dragging = false
				local initAlpha = math.clamp((value - min) / math.max(max - min, 1), 0, 1)

				local frame = Instance.new("Frame")
				frame.Size = UDim2.new(1, -12, 0, 55)
				frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
				frame.Parent = container
				Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 4)

				local label = Instance.new("TextLabel")
				label.Size = UDim2.new(1, -10, 0, 20)
				label.Position = UDim2.new(0, 5, 0, 5)
				label.Text = text .. " (" .. value .. ")"
				label.BackgroundTransparency = 1
				label.TextColor3 = currentColor
				label.Font = Enum.Font.Gotham
				label.TextSize = 11
				label.Parent = frame

				local bar = Instance.new("Frame")
				bar.Size = UDim2.new(1, -20, 0, 5)
				bar.Position = UDim2.new(0, 10, 1, -15)
				bar.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
				bar.Parent = frame
				Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)

				local fill = Instance.new("Frame")
				fill.Size = UDim2.new(initAlpha, 0, 1, 0)
				fill.BackgroundColor3 = currentColor
				fill.Parent = bar
				Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

				local function update(input)
					if bar.AbsoluteSize.X <= 0 then return end
					local pos = math.clamp((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
					fill.Size = UDim2.new(pos, 0, 1, 0)
					value = math.floor(min + (max - min) * pos + 0.5)
					label.Text = text .. " (" .. value .. ")"
					if callback then pcall(callback, value) end
				end

				bar.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
						dragging = true
						update(input)
					end
				end)
				UIS.InputChanged:Connect(function(input)
					if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
						update(input)
					end
				end)
				UIS.InputEnded:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
						dragging = false
					end
				end)

				return frame
			end

			return Section
		end

		return Elements
	end

	function windowFunctions:SetThemeColor(color)
		updateThemeColor(color)
	end
	function windowFunctions:SetToggleIcon(iconAssetId)
		if toggleButton then
			toggleButton.Image = "rbxassetid://" .. iconAssetId
		end
	end
	function windowFunctions:SetToggleColor(color)
		if toggleButton then
			toggleButton.BackgroundColor3 = color
		end
	end
	function windowFunctions:SetToggleSize(size)
		updateToggleButtonSize(size)
	end
	function windowFunctions:Notify(titulo, texto, duracao)
		Notify(titulo, texto, duracao)
	end

	local open = true
	local notified = false
	toggleButton.MouseButton1Click:Connect(function()
		if movedBtn then return end
		open = not open
		mainFrame.Visible = open
		if open and not notified then
			Notify("Welcome Sunset 🌞", "99 Nights Loaded 🌞", 4)
			notified = true
		end
	end)

	task.defer(function()
		if tabOrderList[1] then
			pcall(function()
				if firesignal then
					firesignal(tabOrderList[1].MouseButton1Click)
				end
			end)
		end
	end)

	return windowFunctions
end

--========================================================
-- MOBILE FLY PAD
--========================================================

local flyPad = Instance.new("Frame")
flyPad.Size = UDim2.fromOffset(60, 124)
flyPad.Position = UDim2.new(1, -70, 1, -132)
flyPad.BackgroundTransparency = 1
flyPad.Visible = false
flyPad.Parent = CoreGui.Parent and CoreGui or PlayerGui
pcall(function() flyPad.Parent = CoreGui end)
if flyPad.Parent ~= CoreGui then
	flyPad.Parent = PlayerGui
end

local function holdBtn(yOff, text, onState)
	local b = Instance.new("TextButton")
	b.Size = UDim2.fromOffset(56, 56)
	b.Position = UDim2.fromOffset(0, yOff)
	b.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
	b.Text = text
	b.TextColor3 = Color3.fromRGB(255, 128, 0)
	b.Font = Enum.Font.GothamBold
	b.TextSize = 20
	b.Parent = flyPad
	Instance.new("UICorner", b).CornerRadius = UDim.new(1, 0)
	local st = Instance.new("UIStroke", b)
	st.Color = Color3.fromRGB(255, 128, 0)
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

--========================================================
-- BUILD MENU
--========================================================

local Win = Library:CreateWindow("SUNSET")

-- TAB 1: CHÍNH
local TabMain = Win:CreateTab("Chính")
do
	local sCombat = TabMain:AddSection("COMBAT & FARM")
	local tool = getKillTool()
	sCombat:AddLabel("🗡 Vũ khí: " .. (tool and tool.Name or "Không có"))

	sCombat:AddToggle("Kill Aura", CFG.KillAura, function(v) CFG.KillAura = v end)
	sCombat:AddSlider("Kill Radius", 10, 500, CFG.KillRadius, function(v) CFG.KillRadius = v end)

	sCombat:AddToggle("TP Auto Chop (Chặt cây)", CFG.AutoChop, function(v) CFG.AutoChop = v end)
	sCombat:AddSlider("Chop Radius", 10, 500, CFG.ChopRadius, function(v) CFG.ChopRadius = v end)

	sCombat:AddSlider("Delay (x10ms)", 5, 60, math.floor(CFG.Delay * 100), function(v) CFG.Delay = v / 100 end)

	local sChest = TabMain:AddSection("RƯƠNG, ĐẠN & ĐỒNG XU")
	sChest:AddToggle("Auto Rương & Nhặt Đồ (Mượt)", CFG.AutoChestAndLoot, function(v)
		CFG.AutoChestAndLoot = v
		if not v then
			updateChestLootStatus(
				string.format("Tắt · Nhặt:%d | →Lửa:%d | Đạn:%d",
					totalItemsLooted, totalSentToFire, totalAmmoCollected)
			)
		end
	end)
	chestLootStatusLbl = sChest:AddLabel(chestLootStatusText)

	sChest:AddToggle("Tự động nhặt toàn bộ xu", CFG.AutoCollectCoins, function(v)
		CFG.AutoCollectCoins = v
		if v then
			task.spawn(collectAllCoinsOnce)
		else
			updateCoinStatus("Tắt (Tổng: " .. totalCollectedCoins .. ")")
		end
	end)
	coinStatusLbl = sChest:AddLabel(coinStatusText)

	local sSurv = TabMain:AddSection("SINH TỒN & TRỒNG CÂY")
	sSurv:AddToggle("Auto Eat Carrot", CFG.AutoEat, function(v)
		CFG.AutoEat = v
		if not v then updateEatStatus("Tắt") end
	end)
	eatStatusLbl = sSurv:AddLabel(eatStatusText)

	local plantLbl = sSurv:AddLabel("Đứng chỗ trồng → bấm nút")
	sSurv:AddButton("🌱 Trồng tất cả mầm cây", function()
		task.spawn(function() plantAllSaplings(plantLbl) end)
	end)
end

-- TAB 2: DI CHUYỂN
local TabMove = Win:CreateTab("Di chuyển")
do
	local sMove = TabMove:AddSection("MOVEMENT")
	sMove:AddToggle("Speed", CFG.Speed, function(v)
		CFG.Speed = v
		if not v then local h = hum(); if h then h.WalkSpeed = 16 end end
	end)
	sMove:AddSlider("Walk Speed", 16, 300, CFG.WalkSpeed, function(v) CFG.WalkSpeed = v end)

	sMove:AddToggle("High Jump", CFG.Jump, function(v)
		CFG.Jump = v
		if not v then local h = hum(); if h then h.JumpPower = 50 end end
	end)
	sMove:AddSlider("Jump Power", 50, 500, CFG.JumpPower, function(v) CFG.JumpPower = v end)

	sMove:AddToggle("Fly", CFG.Fly, function(v)
		CFG.Fly = v
		flyPad.Visible = v
		if v then startFly() else stopFly() end
	end)
	sMove:AddSlider("Fly Speed", 10, 200, CFG.FlySpeed, function(v) CFG.FlySpeed = v end)

	sMove:AddToggle("Noclip", CFG.Noclip, function(v)
		CFG.Noclip = v
		if not v then restoreNoclip() end
	end)

	sMove:AddToggle("🛡 God Mode (Di chuyển thường · Cao max 20)", CFG.GodMode, function(v)
		if v then startGodMode() else stopGodMode() end
	end)
	sMove:AddSlider("God Height Cap (max 20)", 5, 20, godHeight, function(v)
		godHeight = math.clamp(v, 5, GOD_MAX_HEIGHT)
		if CFG.GodMode then startGodMode() end
	end)

	local sBounds = TabMove:AddSection("BOUNDARIES ORBIT (BAY CAO · NHANH · TRONG BOUNDARIES)")
	sBounds:AddToggle("🌀 Bay vòng tròn trong Boundaries", CFG.CircleBoundaries, function(v)
		if v then startCircleBoundaries() else stopCircleBoundaries() end
	end)
	sBounds:AddSlider("Độ cao bay vòng tròn (studs)", 20, 180, circleAltitude, function(v)
		circleAltitude = v
	end)
	sBounds:AddSlider("Tốc độ bay vòng tròn", 20, 160, circleSpeed, function(v)
		circleSpeed = v
	end)
	circleStatusLbl = sBounds:AddLabel(circleStatusText)
end

-- TAB 3: TRẺ EM
local TabChild = Win:CreateTab("Trẻ em")
do
	local sAutoRescue = TabChild:AddSection("AUTO CỨU TRẺ VỀ LỬA TRẠI")
	local sack = getSackTool()
	sAutoRescue:AddLabel("🎒 Túi hiện tại: " .. (sack and sack.Name or "Chưa có túi"))

	sAutoRescue:AddToggle("Auto cứu trẻ (TP → Balo → Lửa)", CFG.AutoRescueChild, function(v)
		CFG.AutoRescueChild = v
		if not v then
			updateRescueStatus(string.format("Tắt · Đã cứu: %d", totalChildrenSaved))
		end
	end)
	rescueStatusLbl = sAutoRescue:AddLabel(rescueStatusText)

	sAutoRescue:AddButton("🔄 Reset danh sách trẻ đã cứu", function()
		rescuedChildren  = setmetatable({}, { __mode = "k" })
		rescuedChildKeys = {}
		updateRescueStatus("🔄 Đã reset danh sách trẻ đã cứu")
	end)

	local sChild = TabChild:AddSection("ESP & TP THỦ CÔNG")
	sChild:AddToggle("ESP Trẻ em", CFG.ESPChild, function(v)
		CFG.ESPChild = v
		if not v then clearESPChild() end
	end)

	local r, list = root(), {}
	for m, _ in pairs(childSet) do
		if m and m.Parent then
			local p = partOf(m)
			if p then
				local d = r and math.floor((p.Position - r.Position).Magnitude) or 0
				table.insert(list, {m=m, p=p, d=d})
			end
		end
	end
	table.sort(list, function(a, b) return a.d < b.d end)

	if #list == 0 then
		sChild:AddLabel("Không tìm thấy trẻ nào")
	else
		for i, item in ipairs(list) do
			sChild:AddButton(string.format("TP %d. %s (%d studs)", i, item.m.Name, item.d), function()
				tpTo(item.m)
			end)
		end
	end
end

-- TAB 4: TP & ĐỒ
local TabItems = Win:CreateTab("TP & Đồ")
do
	local sFire = TabItems:AddSection("LỬA TRẠI (QUÉT RỘNG · TP TỪNG MÓN)")
	sFire:AddButton("🔥 TP Lửa trại", tpCampfire)
	sFire:AddToggle("Auto TP nhiên liệu → Lửa (Từng món)", CFG.AutoDrop, function(v)
		CFG.AutoDrop = v
		if v then
			task.spawn(dumpFuelToFire)
		else
			updateFireStatus(string.format("Tắt · Đã dồn: %d", totalFuelMoved))
		end
	end)
	fireStatusLbl = sFire:AddLabel(fireStatusText)
	sFire:AddButton("🪵 Dồn nhiên liệu → Lửa ngay", function()
		task.spawn(dumpFuelToFire)
	end)

	local sScrap = TabItems:AddSection("SCRAPPER (CHECK TRƯỚC · DRAG SAU)")
	sScrap:AddButton("⚙️ TP Scrapper", tpScrapper)
	sScrap:AddToggle("Auto TP phế liệu → Scrapper (Rớt trên)", CFG.AutoScrapper, function(v)
		CFG.AutoScrapper = v
		if v then
			task.spawn(sendScrapToScrapper)
		else
			updateScrapStatus(string.format("Tắt · Đã đưa: %d", totalScrapMoved))
		end
	end)
	scrapStatusLbl = sScrap:AddLabel(scrapStatusText)
	sScrap:AddButton("🔩 Đưa phế liệu → Scrapper ngay", function()
		task.spawn(sendScrapToScrapper)
	end)

	local sPull = TabItems:AddSection("KÉO VẬT PHẨM VỀ NGƯỜI")
	sPull:AddButton("🍎 Kéo thức ăn", function()
		task.spawn(function() pullAllExact(FOOD_ITEMS) end)
	end)
	sPull:AddButton("⚙️ Kéo phế liệu sắt", function()
		task.spawn(function() pullAllExact(SCRAP_ITEMS) end)
	end)

	local sPlr = TabItems:AddSection("NGƯỜI CHƠI")
	local r = root()
	local hasOther = false
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= Player then
			hasOther = true
			local pRoot = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
			local dist = (r and pRoot) and math.floor((pRoot.Position - r.Position).Magnitude) or 0
			sPlr:AddButton(string.format("Kéo %s (%d studs)", plr.Name, dist), function()
				pullPlayerToMe(plr)
			end)
		end
	end
	if not hasOther then
		sPlr:AddLabel("Không có người chơi khác")
	end
end

-- TAB 5: CÀI ĐẶT
local TabSet = Win:CreateTab("Cài đặt")
do
	local sPerf = TabSet:AddSection("HIỆU NĂNG & ÁNH SÁNG")
	sPerf:AddToggle("Fix Lag Pro", CFG.FixLag, function(v) setFixLag(v) end)
	sPerf:AddToggle("Nhìn trong bóng tối (Fullbright)", CFG.Fullbright, function(v)
		CFG.Fullbright = v
		setFullbright(v)
	end)

	local sMap = TabSet:AddSection("BẢN ĐỒ & GIAO DIỆN")
	sMap:AddToggle("🗺️ Auto Mở Map", CFG.AutoMap, function(v)
		CFG.AutoMap = v
		if v then
			task.spawn(revealMapOnce)
		else
			updateAutoMapStatus(string.format("Tắt Auto Mở Map (Đã mở: %d)", totalMapReveals))
		end
	end)
	autoMapStatusLbl = sMap:AddLabel(autoMapStatusText)
	sMap:AddButton("🗺️ Reveal Map ngay", function()
		task.spawn(revealMap)
	end)
	sMap:AddSlider("Kích thước nút bật/tắt", 32, 70, 40, function(v)
		Win:SetToggleSize(v)
	end)
end

print("========================================")
print(" SUNSET UI + 99 NIGHTS GOD20 & ORBIT ✓")
print("========================================")
