--========================================================
-- OLLIE UI V10 | DARK BLUE (DEEP CHEST + LOOT FLOW & COINS)
-- Two Column | Smooth Animation | Image Support
-- PC + MOBILE
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

--========================================================
-- [NƠI ĐẶT ID ẢNH TỐT NHẤT]
-- Điền số ID (vd: "1234567890") hoặc "rbxassetid://1234567890"
-- Để "" hoặc "0" nếu chưa dùng ảnh đó
--========================================================

local Images = {
    Logo       = "rbxassetid://0",
    Banner     = "rbxassetid://0",
    Background = "rbxassetid://0",
}

local function normalizeAssetId(id)
    if type(id) ~= "string" then return "" end
    local trimmed = id:match("^%s*(.-)%s*$")
    if trimmed == "" or trimmed == "0" or trimmed == "rbxassetid://0" then
        return ""
    end
    if tonumber(trimmed) then
        return "rbxassetid://" .. trimmed
    end
    return trimmed
end

local ResolvedImages = {
    Logo       = normalizeAssetId(Images.Logo),
    Banner     = normalizeAssetId(Images.Banner),
    Background = normalizeAssetId(Images.Background),
}

--========================================================
-- THEME
--========================================================

local Theme = {
    Background  = Color3.fromRGB(15, 20, 32),
    Sidebar     = Color3.fromRGB(20, 28, 43),
    Panel       = Color3.fromRGB(24, 34, 52),
    Element     = Color3.fromRGB(33, 46, 67),
    Accent      = Color3.fromRGB(72, 128, 235),
    AccentLight = Color3.fromRGB(120, 169, 255),
    Text        = Color3.fromRGB(238, 243, 255),
    SubText     = Color3.fromRGB(153, 171, 199),
    Green       = Color3.fromRGB(55, 180, 120),
    Red         = Color3.fromRGB(190, 65, 75),
    Amber       = Color3.fromRGB(245, 185, 70),
}

local ANIMATION   = 0.2
local WINDOW_SIZE = UDim2.fromOffset(570, 405)
local CLOSED_SIZE = UDim2.fromOffset(480, 340)

--========================================================
-- CLEANUP OLD GUI
--========================================================

for _, name in ipairs({"OllieUI", "OllieMenu", "ollie_v9"}) do
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
-- REMOTES & GAME DATA
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
    "Log","Chair","Bolt","Sheet Metal","Broken Fan","Broken Radio",
    "Broken Microwave","Washing Machine","Tires & Engines",
}
local FUEL_EXACT = {
    "Log","Chair","Biofuel","Coal",
    "Purple Fur Tuft","Fuel Canister","Oil Barrel",
}
local CHEST_KEYS = { "Chest", "Crate", "Supply", "Loot" }
local COIN_KEYS  = { "Coin" }
local IGNORE_LOOT_KEYS = {
    "Tree","Pine","Oak","Birch","Fir","Bush","Foliage","Wall","Floor","Ground",
    "Terrain","Campfire","MainFire","Spawn","Part","Baseplate","Hitbox"
}

local CFG = {
    Speed=false,            WalkSpeed=40,
    Jump=false,             JumpPower=90,
    Fly=false,              FlySpeed=60,
    Noclip=false,
    KillAura=false,         KillRadius=150,
    AutoChop=false,         ChopRadius=130,
    AutoDrop=false,
    AutoEat=false,
    AutoChestAndLoot=false,
    AutoCollectCoins=false,
    ESPChild=false,
    Fullbright=false,
    FixLag=false,
    Delay=0.35,
}

local MAX_KILL_PER_CYCLE = 6
local TOOL_SUFFIX = "11960515286"
local CHILD_KEY   = "Lost Child"

--========================================================
-- GAME HELPERS
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
    for _, v in ipairs(list) do if name == v then return true end end
    return false
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

--========================================================
-- DEEP AUTO OPEN CHEST -> LOOT THAT CHEST (2s DELAY, SKIP BAD)
--========================================================

local chestLootStatusText = "Chờ bật tự động mở & nhặt rương..."
local chestLootStatusLbl  = nil

local openedChestDone = setmetatable({}, { __mode = "k" })
local failedChestAt   = {}
local lootedItems     = setmetatable({}, { __mode = "k" })
local failedLootAt    = {}

local CHEST_FAIL_COOLDOWN = 45
local LOOT_FAIL_COOLDOWN  = 35
local LOOT_RADIUS_STUDS   = 24
local STEP_WAIT_SECONDS   = 2

local totalChestsOpened = 0
local totalItemsLooted  = 0

local function updateChestLootStatus(txt, col)
    chestLootStatusText = txt
    if chestLootStatusLbl and chestLootStatusLbl.Parent then
        chestLootStatusLbl.Text = txt
        if col then chestLootStatusLbl.TextColor3 = col end
    end
end

local function scanAllChests()
    local chests, seen = {}, {}
    local function tryAdd(o)
        if seen[o] then return end
        if (o:IsA("Model") or o:IsA("BasePart")) and hasKey(o.Name, CHEST_KEYS) then
            seen[o] = true
            table.insert(chests, o)
        end
    end

    local itemsFolder = Workspace:FindFirstChild("Items")
    if itemsFolder then
        for _, o in ipairs(itemsFolder:GetDescendants()) do
            tryAdd(o)
        end
    end
    for _, o in ipairs(Workspace:GetDescendants()) do
        tryAdd(o)
    end
    return chests
end

local function isChestSkipped(chest, now)
    if not chest or not chest.Parent then return true end
    if openedChestDone[chest] then return true end
    local failT = failedChestAt[chest]
    if failT and (now - failT) < CHEST_FAIL_COOLDOWN then
        return true
    end
    return false
end

local function isLootSkipped(item, now)
    if not item or not item.Parent then return true end
    if lootedItems[item] then return true end
    local failT = failedLootAt[item]
    if failT and (now - failT) < LOOT_FAIL_COOLDOWN then
        return true
    end
    return false
end

local function isValidChestLoot(obj, targetChest, allChests)
    if not obj or not obj.Parent then return false end
    local ch = Player.Character
    if ch and obj:IsDescendantOf(ch) then return false end
    local inv = Player:FindFirstChild("Inventory")
    if inv and obj:IsDescendantOf(inv) then return false end
    if Players:GetPlayerFromCharacter(obj) then return false end

    for _, c in ipairs(allChests) do
        if obj == c or obj:IsDescendantOf(c) then
            return false
        end
    end
    if obj == targetChest or obj:IsDescendantOf(targetChest) then
        return false
    end

    local name = obj.Name
    if hasKey(name, CHEST_KEYS) or hasKey(name, COIN_KEYS) or hasKey(name, IGNORE_LOOT_KEYS) then
        return false
    end

    if obj:IsA("Tool") then return true end
    if obj:IsA("Model") then
        local hasInteract = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
            or obj:FindFirstChildWhichIsA("ClickDetector", true)
            or obj:FindFirstChildWhichIsA("BasePart", true)
        return hasInteract ~= nil
    end
    return false
end

local function scanLootForChest(targetChest, allChests, now)
    local chestPart = partOf(targetChest)
    if not chestPart then return {} end
    local cPos = chestPart.Position

    local out, seen = {}, {}
    local scanRoots = {}
    local itemsFolder = Workspace:FindFirstChild("Items")
    if itemsFolder then table.insert(scanRoots, itemsFolder) end
    table.insert(scanRoots, Workspace)

    for _, rootFolder in ipairs(scanRoots) do
        for _, o in ipairs(rootFolder:GetDescendants()) do
            if seen[o] then continue end
            if isLootSkipped(o, now) then continue end
            if not isValidChestLoot(o, targetChest, allChests) then continue end

            local p = partOf(o)
            if p and (p.Position - cPos).Magnitude <= LOOT_RADIUS_STUDS then
                seen[o] = true
                table.insert(out, o)
            end
        end
        if #out > 0 then break end
    end

    table.sort(out, function(a, b)
        local pa, pb = partOf(a), partOf(b)
        if not pa then return false end
        if not pb then return true end
        return (pa.Position - cPos).Magnitude < (pb.Position - cPos).Magnitude
    end)

    return out
end

local function tryLootSingleItem(item)
    if not HotbarItemRF then return false end
    local inv = Player:FindFirstChild("Inventory")
    local beforeCount = inv and #inv:GetChildren() or 0

    local ok, res = pcall(HotbarItemRF.InvokeServer, HotbarItemRF, item)
    if not ok or res == false then
        return false
    end

    task.wait(0.08)
    local nowInInv = (inv and item.Parent == inv) or (item.Parent == Player.Character)
    local afterCount = inv and #inv:GetChildren() or 0

    if nowInInv or afterCount > beforeCount or not item.Parent then
        return true
    end
    return false
end

local function openSingleChest(chest)
    if not OpenChestRE or not chest or not chest.Parent then return false end
    local ok = pcall(OpenChestRE.FireServer, OpenChestRE, chest)
    return ok == true
end

local function lootItemsOfSingleChest(chest, allChests)
    local now = os.clock()
    local items = scanLootForChest(chest, allChests, now)
    if #items == 0 then
        return 0, 0
    end

    local grabbed, skipped = 0, 0
    for i = 1, math.min(#items, 15) do
        if not CFG.AutoChestAndLoot then break end
        local item = items[i]
        if isLootSkipped(item, os.clock()) then continue end

        if tryLootSingleItem(item) then
            lootedItems[item] = true
            grabbed += 1
            totalItemsLooted += 1
        else
            failedLootAt[item] = os.clock()
            skipped += 1
        end
        task.wait(0.08)
    end
    return grabbed, skipped
end

local function processNextChestStep()
    if not OpenChestRE then
        updateChestLootStatus("❌ Thiếu remote RequestOpenItemChest", Color3.fromRGB(255, 100, 100))
        return
    end
    if not HotbarItemRF then
        updateChestLootStatus("❌ Thiếu remote RequestHotbarItem", Color3.fromRGB(255, 100, 100))
        return
    end

    local allChests = scanAllChests()
    if #allChests == 0 then
        updateChestLootStatus("⚠️ Không thấy rương · Đã mở " .. totalChestsOpened .. " | Nhặt " .. totalItemsLooted, Theme.Amber)
        return
    end

    local now = os.clock()
    local targetChest = nil
    for _, c in ipairs(allChests) do
        if not isChestSkipped(c, now) then
            targetChest = c
            break
        end
    end

    if not targetChest then
        updateChestLootStatus(
            string.format("✅ Hết rương khả dụng · Rương: %d | Đồ: %d", totalChestsOpened, totalItemsLooted),
            Theme.Green
        )
        return
    end

    -- Bước 1: Mở đúng 1 rương
    updateChestLootStatus("📦 Đang mở rương: " .. tostring(targetChest.Name) .. "...", Theme.AccentLight)
    local openedOk = openSingleChest(targetChest)
    if not openedOk or not targetChest.Parent then
        failedChestAt[targetChest] = os.clock()
        updateChestLootStatus("⏭️ Bỏ qua rương lỗi: " .. tostring(targetChest.Name), Theme.Amber)
        return
    end

    -- Chờ ngắn cho rương bật/rơi đồ sau khi mở
    task.wait(0.35)
    if not CFG.AutoChestAndLoot then return end

    -- Bước 2: Chỉ khi mở rương đó mới nhặt đồ của chính rương đó
    updateChestLootStatus("🎒 Đang nhặt đồ trong rương: " .. tostring(targetChest.Name) .. "...", Theme.AccentLight)
    local grabbed, skipped = lootItemsOfSingleChest(targetChest, allChests)

    if grabbed > 0 or targetChest.Parent then
        openedChestDone[targetChest] = true
        totalChestsOpened += 1
        updateChestLootStatus(
            string.format("📦 Mở #%d (%s) · Nhặt +%d (Bỏ %d) · Tổng đồ: %d",
                totalChestsOpened, tostring(targetChest.Name), grabbed, skipped, totalItemsLooted),
            Theme.Green
        )
    else
        failedChestAt[targetChest] = os.clock()
        updateChestLootStatus(
            string.format("⏭️ Bỏ qua rương không nhặt được (%s) · Tổng đồ: %d",
                tostring(targetChest.Name), totalItemsLooted),
            Theme.Amber
        )
    end
end

task.spawn(function()
    while true do
        if CFG.AutoChestAndLoot then
            pcall(processNextChestStep)
            -- Chờ đúng 2s sau mỗi lần mở và nhặt
            task.wait(STEP_WAIT_SECONDS)
        else
            task.wait(0.5)
        end
    end
end)

--========================================================
-- AUTO COLLECT ALL COINS
--========================================================

local coinStatusText = "Chờ bật tự động nhặt xu..."
local coinStatusLbl  = nil
local totalCollectedCoins = 0

local function updateCoinStatus(txt, col)
    coinStatusText = txt
    if coinStatusLbl and coinStatusLbl.Parent then
        coinStatusLbl.Text = txt
        if col then coinStatusLbl.TextColor3 = col end
    end
end

local function scanAllCoins()
    local coins, seen = {}, {}
    local function tryAdd(obj)
        if seen[obj] then return end
        local okName, name = pcall(function() return obj.Name end)
        if okName and hasKey(name, COIN_KEYS) then
            seen[obj] = true
            table.insert(coins, obj)
        end
    end

    for _, o in ipairs(Workspace:GetDescendants()) do
        tryAdd(o)
    end

    if getnilinstances then
        local ok, nilList = pcall(getnilinstances)
        if ok and nilList then
            for _, obj in ipairs(nilList) do
                tryAdd(obj)
            end
        end
    end

    return coins
end

local function collectAllCoinsOnce()
    if not CollectCoinRF then
        updateCoinStatus("❌ Thiếu remote RequestCollectCoints", Color3.fromRGB(255, 100, 100))
        return 0
    end

    local coins = scanAllCoins()
    if #coins == 0 then
        updateCoinStatus("⚠️ Chưa thấy đồng xu nào (Tổng: " .. totalCollectedCoins .. ")", Theme.Amber)
        return 0
    end

    local collected = 0
    for _, coin in ipairs(coins) do
        if not CFG.AutoCollectCoins then break end
        local ok = pcall(CollectCoinRF.InvokeServer, CollectCoinRF, coin)
        if ok then
            collected += 1
            totalCollectedCoins += 1
        end
        task.wait(0.05)
    end

    updateCoinStatus(
        string.format("🪙 Đã nhặt %d đợt này (Tổng: %d)", collected, totalCollectedCoins),
        Theme.Green
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
-- CACHE TRẺ & COUNTER
--========================================================

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

--========================================================
-- SWING, KILL AURA & AUTO CHOP
--========================================================

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

local SCAN_FOLDERS = { "Characters","Enemies","Mobs","NPCs" }
local function getAnimals(r)
    local out, ch, seen = {}, Player.Character, {}
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

--========================================================
-- MOVEMENT, NOCLIP & FLY
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

Player.CharacterAdded:Connect(function()
    task.wait(0.5); resetCounter()
    if CFG.Fly then startFly() end
end)

--========================================================
-- FULLBRIGHT (NHÌN TRONG BÓNG TỐI) & FIX LAG PRO
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
-- AUTO EAT CARROT & ESP TRẺ
--========================================================

local eatStatusText = "Chờ bật để ăn carrot tự động..."
local eatStatusLbl  = nil

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
                    updateEatStatus(string.format("✅ Đã ăn %d carrot", ate), Theme.Green)
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

--========================================================
-- TP, PULL, FUEL & PLANT ACTIONS
--========================================================

local function tpTo(m)
    local r, p = root(), partOf(m)
    if r and p then r.CFrame = CFrame.new(p.Position + Vector3.new(0,4,0)) end
end

local function tpCampfire()
    local fp = getFirePart(); local r = root()
    if fp and r then r.CFrame = CFrame.new(fp.Position + Vector3.new(0,4,0)) end
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
    local ch, count, seen = Player.Character, 0, {}
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
        pcall(DragRE.FireServer, DragRE, o)
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
            statusLbl.TextColor3 = col or Theme.Text
        end
    end
    if not PlantRE then
        setStatus("❌ Không có remote RequestPlantItem", Color3.fromRGB(255,100,100)); return 0
    end
    if not getnilinstances then
        setStatus("❌ Executor không hỗ trợ getnilinstances", Color3.fromRGB(255,100,100)); return 0
    end
    setStatus("🔍 Đang quét mầm cây...", Theme.Amber)
    local saplings = getNilByName("Sapling")
    if #saplings == 0 then
        setStatus("⚠️ Không tìm thấy mầm cây nào", Theme.Amber); return 0
    end
    setStatus(string.format("🌱 Tìm thấy %d mầm — đang trồng...", #saplings), Theme.AccentLight)
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
        setStatus(string.format("✅ Đã trồng %d/%d mầm cây", count, #saplings), Theme.Green)
    else
        setStatus("⚠️ Trồng thất bại — thử đứng sát đất hơn", Theme.Amber)
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

--========================================================
-- UI HELPERS (KHÔNG DÙNG .Completed:Wait() GÂY KẸT)
--========================================================

local activeTweens = setmetatable({}, { __mode = "k" })

local function Tween(obj, time, properties)
    if not obj or not obj.Parent then return nil end
    if activeTweens[obj] then
        pcall(function() activeTweens[obj]:Cancel() end)
        activeTweens[obj] = nil
    end
    local t = TweenService:Create(
        obj,
        TweenInfo.new(time, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
        properties
    )
    activeTweens[obj] = t
    t.Completed:Connect(function()
        if activeTweens[obj] == t then
            activeTweens[obj] = nil
        end
    end)
    t:Play()
    return t
end

local function Corner(obj, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius)
    c.Parent = obj
    return c
end

local function MakeLabel(parent, text, size, color, bold)
    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextSize = size
    label.TextColor3 = color or Theme.Text
    label.Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham
    label.Parent = parent
    return label
end

local function MakeImage(parent, name, image, size, position)
    local obj = Instance.new("ImageLabel")
    obj.Name = name
    obj.Size = size
    obj.Position = position
    obj.BackgroundTransparency = 1
    obj.Image = image
    obj.ScaleType = Enum.ScaleType.Crop
    obj.Parent = parent
    return obj
end

--========================================================
-- ROOT GUI & SCALE
--========================================================

local Gui = Instance.new("ScreenGui")
Gui.Name = "OllieUI"
Gui.ResetOnSpawn = false
Gui.IgnoreGuiInset = true
Gui.DisplayOrder = 100
if not pcall(function() Gui.Parent = CoreGui end) then
    Gui.Parent = PlayerGui
end

local Scale = Instance.new("UIScale")
Scale.Parent = Gui

local function UpdateScale()
    local camera = workspace.CurrentCamera
    if not camera then return end
    local v = camera.ViewportSize
    Scale.Scale = math.clamp(math.min(v.X / 650, v.Y / 480), 0.55, 1)
end

UpdateScale()
if workspace.CurrentCamera then
    workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(UpdateScale)
end

--========================================================
-- MAIN WINDOW
--========================================================

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = WINDOW_SIZE
Main.Position = UDim2.new(0.5, 0, 0.5, 0)
Main.AnchorPoint = Vector2.new(0.5, 0.5)
Main.BackgroundColor3 = Theme.Background
Main.BorderSizePixel = 0
Main.ClipsDescendants = true
Main.Visible = false
Main.Parent = Gui
Corner(Main, 13)

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Theme.Accent
MainStroke.Transparency = 0.55
MainStroke.Thickness = 1
MainStroke.Parent = Main

--========================================================
-- BACKGROUND IMAGE
--========================================================

local Background = MakeImage(
    Main,
    "BackgroundImage",
    ResolvedImages.Background,
    UDim2.fromScale(1, 1),
    UDim2.fromScale(0, 0)
)
Background.Visible = (ResolvedImages.Background ~= "")
Background.ImageTransparency = 0.52
Background.ZIndex = 0

local Overlay = Instance.new("Frame")
Overlay.Size = UDim2.fromScale(1, 1)
Overlay.BackgroundColor3 = Theme.Background
Overlay.BackgroundTransparency = 0.18
Overlay.BorderSizePixel = 0
Overlay.ZIndex = 0
Overlay.Parent = Main

--========================================================
-- HEADER
--========================================================

local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 48)
Header.BackgroundColor3 = Theme.Sidebar
Header.BackgroundTransparency = 0.08
Header.BorderSizePixel = 0
Header.ZIndex = 2
Header.Parent = Main

local Logo = MakeImage(
    Header,
    "Logo",
    ResolvedImages.Logo,
    UDim2.fromOffset(30, 30),
    UDim2.fromOffset(10, 9)
)
Logo.ScaleType = Enum.ScaleType.Fit
Logo.Visible = (ResolvedImages.Logo ~= "")
Logo.ZIndex = 3

local Title = MakeLabel(
    Header,
    "OLLIE  /  99 NIGHTS",
    15,
    Theme.Text,
    true
)
Title.Position = UDim2.fromOffset(ResolvedImages.Logo ~= "" and 48 or 14, 0)
Title.Size = UDim2.new(1, -150, 1, 0)
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.ZIndex = 3

local Version = MakeLabel(
    Header,
    "V10",
    10,
    Theme.SubText,
    true
)
Version.Position = UDim2.new(1, -100, 0, 0)
Version.Size = UDim2.fromOffset(45, 48)
Version.ZIndex = 3

local Close = Instance.new("TextButton")
Close.Size = UDim2.fromOffset(33, 30)
Close.Position = UDim2.new(1, -41, 0, 9)
Close.BackgroundColor3 = Theme.Red
Close.Text = "×"
Close.TextSize = 22
Close.TextColor3 = Theme.Text
Close.Font = Enum.Font.GothamBold
Close.BorderSizePixel = 0
Close.ZIndex = 4
Close.Parent = Header
Corner(Close, 7)

--========================================================
-- SIDEBAR & CONTENT
--========================================================

local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 145, 1, -58)
Sidebar.Position = UDim2.fromOffset(8, 53)
Sidebar.BackgroundColor3 = Theme.Sidebar
Sidebar.BackgroundTransparency = 0.05
Sidebar.BorderSizePixel = 0
Sidebar.ZIndex = 2
Sidebar.Parent = Main
Corner(Sidebar, 9)

local TabLayout = Instance.new("UIListLayout")
TabLayout.Padding = UDim.new(0, 7)
TabLayout.SortOrder = Enum.SortOrder.LayoutOrder
TabLayout.Parent = Sidebar

local TabPadding = Instance.new("UIPadding")
TabPadding.PaddingTop = UDim.new(0, 9)
TabPadding.PaddingLeft = UDim.new(0, 8)
TabPadding.PaddingRight = UDim.new(0, 8)
TabPadding.Parent = Sidebar

local ContentBasePos = UDim2.fromOffset(157, 53)
local Content = Instance.new("ScrollingFrame")
Content.Size = UDim2.new(1, -165, 1, -58)
Content.Position = ContentBasePos
Content.BackgroundColor3 = Theme.Panel
Content.BackgroundTransparency = 0.08
Content.BorderSizePixel = 0
Content.ScrollBarThickness = 3
Content.ScrollBarImageColor3 = Theme.Accent
Content.AutomaticCanvasSize = Enum.AutomaticSize.Y
Content.CanvasSize = UDim2.new()
Content.ZIndex = 2
Content.Parent = Main
Corner(Content, 9)

local ContentLayout = Instance.new("UIListLayout")
ContentLayout.Padding = UDim.new(0, 8)
ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder
ContentLayout.Parent = Content

local Padding = Instance.new("UIPadding")
Padding.PaddingTop = UDim.new(0, 10)
Padding.PaddingLeft = UDim.new(0, 10)
Padding.PaddingRight = UDim.new(0, 10)
Padding.PaddingBottom = UDim.new(0, 10)
Padding.Parent = Content

--========================================================
-- DRAG & OPEN / CLOSE
--========================================================

local dragging = false
local dragStart, startPosition

Header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPosition = Main.Position
    end
end)

UIS.InputChanged:Connect(function(input)
    if dragging and (
        input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch
    ) then
        local delta = input.Position - dragStart
        Main.Position = UDim2.new(
            startPosition.X.Scale,
            startPosition.X.Offset + delta.X,
            startPosition.Y.Scale,
            startPosition.Y.Offset + delta.Y
        )
    end
end)

UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

local isOpen  = false
local openGen = 0

local Reopen = Instance.new("TextButton")
Reopen.Size = UDim2.fromOffset(48, 48)
Reopen.Position = UDim2.new(0, 15, 0.5, 0)
Reopen.AnchorPoint = Vector2.new(0, 0.5)
Reopen.BackgroundColor3 = Theme.Accent
Reopen.Text = "99"
Reopen.TextColor3 = Theme.Text
Reopen.Font = Enum.Font.GothamBold
Reopen.TextSize = 17
Reopen.BorderSizePixel = 0
Reopen.Parent = Gui
Corner(Reopen, 50)

local function OpenMenu()
    openGen += 1
    local gen = openGen
    isOpen = true

    Main.Visible = true
    Main.Size = CLOSED_SIZE
    Main.BackgroundTransparency = 1
    if Background.Visible then Background.ImageTransparency = 1 end
    Overlay.BackgroundTransparency = 1

    Tween(Main, ANIMATION, { Size = WINDOW_SIZE, BackgroundTransparency = 0 })
    if Background.Visible then
        Tween(Background, ANIMATION, { ImageTransparency = 0.52 })
    end
    Tween(Overlay, ANIMATION, { BackgroundTransparency = 0.18 })

    task.delay(ANIMATION + 0.03, function()
        if openGen == gen and isOpen and Main.Parent then
            Main.Size = WINDOW_SIZE
            Main.BackgroundTransparency = 0
        end
    end)
end

local function CloseMenu()
    openGen += 1
    local gen = openGen
    isOpen = false

    Tween(Main, ANIMATION * 0.85, { Size = CLOSED_SIZE, BackgroundTransparency = 1 })
    if Background.Visible then
        Tween(Background, ANIMATION * 0.85, { ImageTransparency = 1 })
    end
    Tween(Overlay, ANIMATION * 0.85, { BackgroundTransparency = 1 })

    task.delay(ANIMATION * 0.85 + 0.02, function()
        if openGen == gen and not isOpen and Main.Parent then
            Main.Visible = false
        end
    end)
end

Close.MouseButton1Click:Connect(CloseMenu)
Reopen.MouseButton1Click:Connect(OpenMenu)

-- Nút bay lên / xuống cho Mobile (Fly Pad)
local flyPad = Instance.new("Frame")
flyPad.Size = UDim2.fromOffset(60, 124)
flyPad.Position = UDim2.new(1, -70, 1, -132)
flyPad.BackgroundTransparency = 1
flyPad.Visible = false
flyPad.Parent = Gui

local function holdBtn(yOff, text, onState)
    local b = Instance.new("TextButton")
    b.Size = UDim2.fromOffset(56, 56)
    b.Position = UDim2.fromOffset(0, yOff)
    b.BackgroundColor3 = Theme.Element
    b.BorderSizePixel = 0
    b.Text = text
    b.TextColor3 = Theme.AccentLight
    b.Font = Enum.Font.GothamBold
    b.TextSize = 20
    b.Parent = flyPad
    Corner(b, 28)
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
-- ELEMENT BUILDERS
--========================================================

local function ClearContent()
    eatStatusLbl       = nil
    chestLootStatusLbl = nil
    coinStatusLbl      = nil
    for _, obj in ipairs(Content:GetChildren()) do
        if obj ~= ContentLayout and obj ~= Padding then
            obj:Destroy()
        end
    end
    Content.CanvasPosition = Vector2.zero
end

local function Section(text)
    local label = MakeLabel(Content, text, 12, Theme.AccentLight, true)
    label.Size = UDim2.new(1, 0, 0, 23)
    label.TextXAlignment = Enum.TextXAlignment.Left
    return label
end

local function InfoBox(text, color)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 30)
    frame.BackgroundColor3 = Theme.Sidebar
    frame.BorderSizePixel = 0
    frame.ZIndex = 3
    frame.Parent = Content
    Corner(frame, 7)

    local label = MakeLabel(frame, text, 11, color or Theme.SubText, false)
    label.Position = UDim2.fromOffset(10, 0)
    label.Size = UDim2.new(1, -20, 1, 0)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextTruncate = Enum.TextTruncate.AtEnd
    label.ZIndex = 4
    return label
end

local function Toggle(text, default, callback)
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, 0, 0, 40)
    Frame.BackgroundColor3 = Theme.Element
    Frame.BorderSizePixel = 0
    Frame.ZIndex = 3
    Frame.Parent = Content
    Corner(Frame, 7)

    local Label = MakeLabel(Frame, text, 12, Theme.Text, true)
    Label.Position = UDim2.fromOffset(10, 0)
    Label.Size = UDim2.new(1, -70, 1, 0)
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.ZIndex = 4

    local Button = Instance.new("TextButton")
    Button.Size = UDim2.fromOffset(43, 23)
    Button.Position = UDim2.new(1, -51, 0.5, -11)
    Button.TextColor3 = Theme.Text
    Button.TextSize = 10
    Button.Font = Enum.Font.GothamBold
    Button.BorderSizePixel = 0
    Button.ZIndex = 4
    Button.Parent = Frame
    Corner(Button, 6)

    local enabled = default == true

    local function Update()
        Button.Text = enabled and "ON" or "OFF"
        Tween(Button, 0.14, {
            BackgroundColor3 = enabled and Theme.Green or Color3.fromRGB(65, 76, 96)
        })
        if callback then callback(enabled) end
    end

    Button.MouseButton1Click:Connect(function()
        enabled = not enabled
        Update()
    end)

    Button.BackgroundColor3 = enabled and Theme.Green or Color3.fromRGB(65, 76, 96)
    Button.Text = enabled and "ON" or "OFF"

    return function(value)
        enabled = value == true
        Update()
    end
end

local function Slider(text, min, max, default, callback)
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, 0, 0, 67)
    Frame.BackgroundColor3 = Theme.Element
    Frame.BorderSizePixel = 0
    Frame.ZIndex = 3
    Frame.Parent = Content
    Corner(Frame, 7)

    local ValueLabel = MakeLabel(Frame, "", 11, Theme.Text, true)
    ValueLabel.Position = UDim2.fromOffset(10, 5)
    ValueLabel.Size = UDim2.new(1, -20, 0, 22)
    ValueLabel.TextXAlignment = Enum.TextXAlignment.Left
    ValueLabel.ZIndex = 4

    local Bar = Instance.new("Frame")
    Bar.Size = UDim2.new(1, -22, 0, 6)
    Bar.Position = UDim2.fromOffset(11, 43)
    Bar.BackgroundColor3 = Color3.fromRGB(60, 73, 96)
    Bar.BorderSizePixel = 0
    Bar.ZIndex = 4
    Bar.Parent = Frame
    Corner(Bar, 6)

    local Fill = Instance.new("Frame")
    Fill.BackgroundColor3 = Theme.Accent
    Fill.BorderSizePixel = 0
    Fill.ZIndex = 5
    Fill.Parent = Bar
    Corner(Fill, 6)

    local Knob = Instance.new("Frame")
    Knob.Size = UDim2.fromOffset(15, 15)
    Knob.AnchorPoint = Vector2.new(0.5, 0.5)
    Knob.BackgroundColor3 = Theme.Text
    Knob.BorderSizePixel = 0
    Knob.ZIndex = 6
    Knob.Parent = Bar
    Corner(Knob, 50)

    local knobStroke = Instance.new("UIStroke")
    knobStroke.Color = Theme.Accent
    knobStroke.Parent = Knob

    local value = math.clamp(default, min, max)
    local sliding = false

    local function SetValue(newValue, smooth, skipCb)
        value = math.clamp(math.floor(newValue + 0.5), min, max)
        local alpha = (value - min) / (max - min)
        ValueLabel.Text = text .. " : " .. tostring(value)

        local fillSize = UDim2.new(alpha, 0, 1, 0)
        local knobPos  = UDim2.new(alpha, 0, 0.5, 0)

        if smooth then
            Tween(Fill, 0.07, {Size = fillSize})
            Tween(Knob, 0.07, {Position = knobPos})
        else
            Fill.Size = fillSize
            Knob.Position = knobPos
        end

        if callback and not skipCb then callback(value) end
    end

    local function FromInput(input)
        local width = Bar.AbsoluteSize.X
        if width <= 0 then return end
        local alpha = math.clamp((input.Position.X - Bar.AbsolutePosition.X) / width, 0, 1)
        SetValue(min + (max - min) * alpha, true, false)
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

    SetValue(value, false, true)

    return function(newValue)
        SetValue(newValue, true, false)
    end
end

local function ActionButton(text, callback)
    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(1, 0, 0, 38)
    Button.BackgroundColor3 = Theme.Element
    Button.Text = text
    Button.TextColor3 = Theme.Text
    Button.TextSize = 12
    Button.Font = Enum.Font.GothamSemibold
    Button.BorderSizePixel = 0
    Button.ZIndex = 3
    Button.Parent = Content
    Corner(Button, 7)

    Button.MouseButton1Click:Connect(function()
        Tween(Button, 0.1, { BackgroundColor3 = Theme.Accent })
        task.delay(0.12, function()
            if Button.Parent then
                Tween(Button, 0.15, { BackgroundColor3 = Theme.Element })
            end
        end)
        if callback then callback() end
    end)

    return Button
end

--========================================================
-- PAGE SYSTEM
--========================================================

local Pages = {}
local TabButtons = {}
local CurrentTab = nil
local tabGen = 0

local function AddPage(name, icon, callback)
    Pages[name] = { icon = icon, callback = callback }
end

local function OpenTab(name, forceRefresh)
    if not forceRefresh and CurrentTab == name then return end
    tabGen += 1
    local gen = tabGen
    CurrentTab = name

    for tabName, button in pairs(TabButtons) do
        Tween(button, 0.14, {
            BackgroundColor3 = tabName == name and Theme.Accent or Theme.Element
        })
    end

    ClearContent()
    local page = Pages[name]
    if page and page.callback then
        page.callback()
    end

    Content.Position = ContentBasePos + UDim2.fromOffset(10, 0)
    Content.BackgroundTransparency = 0.35
    Tween(Content, 0.16, {
        Position = ContentBasePos,
        BackgroundTransparency = 0.08
    })

    task.delay(0.18, function()
        if tabGen == gen and Content.Parent then
            Content.Position = ContentBasePos
            Content.BackgroundTransparency = 0.08
        end
    end)
end

--========================================================
-- PAGES
--========================================================

AddPage("Chính", "HOME", function()
    if ResolvedImages.Banner ~= "" then
        local Banner = MakeImage(
            Content,
            "OllieBanner",
            ResolvedImages.Banner,
            UDim2.new(1, 0, 0, 95),
            UDim2.new()
        )
        Banner.BackgroundColor3 = Theme.Element
        Banner.BackgroundTransparency = 0
        Banner.ZIndex = 3
        Corner(Banner, 8)
    end

    local tool = getKillTool()
    InfoBox("🗡 Vũ khí hiện tại: " .. (tool and tool.Name or "Không có vũ khí"), Theme.AccentLight)

    Section("COMBAT & FARM")

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

    Section("RƯƠNG & ĐỒNG XU")

    Toggle("📦 Tự động mở & nhặt từng rương (2s)", CFG.AutoChestAndLoot, function(enabled)
        CFG.AutoChestAndLoot = enabled
        if not enabled then
            updateChestLootStatus(
                string.format("Tắt · Rương: %d | Đồ: %d", totalChestsOpened, totalItemsLooted),
                Theme.SubText
            )
        end
    end)
    chestLootStatusLbl = InfoBox(chestLootStatusText)

    Toggle("🪙 Tự động nhặt toàn bộ xu", CFG.AutoCollectCoins, function(enabled)
        CFG.AutoCollectCoins = enabled
        if enabled then
            task.spawn(collectAllCoinsOnce)
        else
            updateCoinStatus("Tắt (Tổng: " .. totalCollectedCoins .. ")", Theme.SubText)
        end
    end)
    coinStatusLbl = InfoBox(coinStatusText)

    Section("SINH TỒN & TRỒNG CÂY")

    Toggle("🥕 Auto Eat Carrot", CFG.AutoEat, function(enabled)
        CFG.AutoEat = enabled
        if not enabled then
            updateEatStatus("Tắt", Theme.SubText)
        end
    end)
    eatStatusLbl = InfoBox(eatStatusText)

    local plantLbl = InfoBox("Đứng vào vị trí muốn trồng → bấm nút dưới")
    ActionButton("🌱 Trồng tất cả mầm cây (Sapling)", function()
        task.spawn(function() plantAllSaplings(plantLbl) end)
    end)
end)

AddPage("Di chuyển", "MOVE", function()
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
end)

AddPage("Hiển thị", "VISUAL", function()
    Section("MAP & VISUAL")

    ActionButton("🗺️ Reveal Map (Mở toàn bộ bản đồ)", function()
        task.spawn(revealMap)
    end)
end)

AddPage("Trẻ em", "CHILDREN", function()
    Section("CHILDREN ESP & TELEPORT")

    Toggle("ESP Trẻ em", CFG.ESPChild, function(enabled)
        CFG.ESPChild = enabled
        if not enabled then clearESPChild() end
    end)

    ActionButton("🔍 Quét lại danh sách trẻ em", function()
        OpenTab("Trẻ em", true)
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
        row.BackgroundColor3 = Theme.Element
        row.BorderSizePixel = 0
        row.ZIndex = 3
        row.Parent = Content
        Corner(row, 7)

        local nameLbl = MakeLabel(row, string.format("%d. %s", i, item.m.Name), 12, Theme.Text, true)
        nameLbl.Position = UDim2.fromOffset(10, 4)
        nameLbl.Size = UDim2.new(1, -68, 0, 20)
        nameLbl.TextXAlignment = Enum.TextXAlignment.Left
        nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
        nameLbl.ZIndex = 4

        local distLbl = MakeLabel(row, string.format("📍 %d studs", item.d), 11, Theme.SubText, false)
        distLbl.Position = UDim2.fromOffset(10, 24)
        distLbl.Size = UDim2.new(1, -68, 0, 16)
        distLbl.TextXAlignment = Enum.TextXAlignment.Left
        distLbl.ZIndex = 4

        local tpBtn = Instance.new("TextButton")
        tpBtn.Size = UDim2.fromOffset(44, 24)
        tpBtn.Position = UDim2.new(1, -52, 0.5, -12)
        tpBtn.BackgroundColor3 = Theme.Green
        tpBtn.BorderSizePixel = 0
        tpBtn.Text = "TP"
        tpBtn.TextColor3 = Theme.Text
        tpBtn.Font = Enum.Font.GothamBold
        tpBtn.TextSize = 11
        tpBtn.ZIndex = 4
        tpBtn.Parent = row
        Corner(tpBtn, 5)
        tpBtn.MouseButton1Click:Connect(function() tpTo(item.m) end)
    end
end)

AddPage("TP & Đồ", "ITEMS", function()
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

    ActionButton("⚙️ Kéo nguyên liệu về người (Log, Chair, Bolt, Sheet Metal...)", function()
        task.spawn(function() pullAllExact(SCRAP_ITEMS) end)
    end)

    Section("NGƯỜI CHƠI")

    ActionButton("🔄 Làm mới danh sách người chơi", function()
        OpenTab("TP & Đồ", true)
    end)

    local r = root()
    local others = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= Player then
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
        row.BackgroundColor3 = Theme.Element
        row.BorderSizePixel = 0
        row.ZIndex = 3
        row.Parent = Content
        Corner(row, 7)

        local lbl = MakeLabel(
            row,
            info.hasChar and string.format("%s (%d studs)", info.plr.Name, info.dist)
                or info.plr.Name .. " (chờ spawn)",
            11,
            Theme.Text,
            false
        )
        lbl.Position = UDim2.fromOffset(10, 0)
        lbl.Size = UDim2.new(1, -68, 1, 0)
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.TextTruncate = Enum.TextTruncate.AtEnd
        lbl.ZIndex = 4

        local goBtn = Instance.new("TextButton")
        goBtn.Size = UDim2.fromOffset(52, 24)
        goBtn.Position = UDim2.new(1, -60, 0.5, -12)
        goBtn.BackgroundColor3 = info.hasChar and Theme.Green or Color3.fromRGB(65, 76, 96)
        goBtn.BorderSizePixel = 0
        goBtn.Text = "Kéo về"
        goBtn.TextColor3 = Theme.Text
        goBtn.Font = Enum.Font.GothamBold
        goBtn.TextSize = 10
        goBtn.ZIndex = 4
        goBtn.Parent = row
        Corner(goBtn, 5)
        goBtn.MouseButton1Click:Connect(function() pullPlayerToMe(info.plr) end)
    end
end)

AddPage("Cài đặt", "SETTINGS", function()
    Section("HIỆU NĂNG & ÁNH SÁNG")

    Toggle("⚡ Fix Lag Pro", CFG.FixLag, function(enabled)
        setFixLag(enabled)
    end)

    Toggle("🔦 Nhìn trong bóng tối (Fullbright)", CFG.Fullbright, function(enabled)
        CFG.Fullbright = enabled
        setFullbright(enabled)
    end)

    Section("INTERFACE")

    Slider("Độ trong suốt nền", 0, 80, math.floor(Overlay.BackgroundTransparency * 100), function(value)
        Overlay.BackgroundTransparency = value / 100
    end)

    ActionButton("Đóng menu", function()
        CloseMenu()
    end)

    ActionButton("Mở lại menu", function()
        OpenMenu()
    end)
end)

--========================================================
-- CREATE TABS & START
--========================================================

local TabOrder = {
    "Chính",
    "Di chuyển",
    "Hiển thị",
    "Trẻ em",
    "TP & Đồ",
    "Cài đặt"
}

for index, name in ipairs(TabOrder) do
    local page = Pages[name]
    if page then
        local Button = Instance.new("TextButton")
        Button.Name = name
        Button.Size = UDim2.new(1, 0, 0, 36)
        Button.BackgroundColor3 = Theme.Element
        Button.Text = page.icon .. "   " .. name
        Button.TextColor3 = Theme.Text
        Button.TextSize = 11
        Button.Font = Enum.Font.GothamSemibold
        Button.BorderSizePixel = 0
        Button.ZIndex = 3
        Button.LayoutOrder = index
        Button.Parent = Sidebar
        Corner(Button, 7)

        TabButtons[name] = Button
        Button.MouseButton1Click:Connect(function()
            OpenTab(name, false)
        end)
    end
end

OpenTab("Chính", true)
OpenMenu()

print("================================")
print(" OLLIE UI V10 DEEP CHEST+LOOT ✓")
print("================================")
