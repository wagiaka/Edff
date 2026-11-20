-- 99 Nights in the Forest — utility build (mặc định tắt toàn bộ)
-- Executor Lua. Dán khi đã vào game.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

local LP = Players.LocalPlayer

-- ============ CONFIG (MẶC ĐỊNH TẮT) ============
local CONFIG = {
    ESP = false,
    ESPPlayers = false,
    ESPItems = false,
    ESPAnimals = false,

    AutoCollect = false,
    Speed = false,
    WalkSpeed = 60,
    JumpPower = 90,
    CollectRadius = 80,
    ScanInterval = 0.5,
    CollectAllPrompts = false,

    Fly = false,
    FlySpeed = 70,
    Fullbright = false,
    KillAura = false,
    KillAuraRadius = 35,

    ItemNames = {
        "Log", "Stick", "Stone", "Rock", "Berry", "Berries",
        "Wood", "Branch", "Mushroom", "Flower", "Fiber",
        "Rope", "Cloth", "Meat", "Hide", "Pelt"
    },
    AnimalNames = {
        "Wolf", "Bear", "Boar", "Deer", "Rabbit",
        "Fox", "Animal", "NPC", "Enemy", "Cultist"
    },
    ChildNames = { "Lost Child", "Lost Child2", "Lost Child3", "Lost Child4" },
    ChestNames = {
        "Item Chest", "Item Chest2", "Item Chest3", "Item Chest4", "Item Chest6",
        "Common Chest", "Good Chest", "Iron Chest", "Gold Chest", "Ruby Chest"
    },
}

-- ============ ESP CORE ============
local espCache = {}

local function nameMatches(objName, list)
    local n = string.lower(objName)
    for _, needle in ipairs(list) do
        if string.find(n, string.lower(needle), 1, true) then return true end
    end
    return false
end

local function addESP(instance, color, label)
    if not instance or not instance.Parent or espCache[instance] then return end
    local adornee = instance
    if instance:IsA("Model") then
        adornee = instance.PrimaryPart or instance:FindFirstChildWhichIsA("BasePart", true)
    end
    if not adornee or not adornee:IsA("BasePart") then return end

    local hl = Instance.new("Highlight")
    hl.Name = "ollie_esp_hl"
    hl.Adornee = instance
    hl.FillColor = color
    hl.OutlineColor = color
    hl.FillTransparency = 0.7
    hl.OutlineTransparency = 0
    hl.Parent = instance

    local bb = Instance.new("BillboardGui")
    bb.Name = "ollie_esp_label"
    bb.Adornee = adornee
    bb.Size = UDim2.new(0, 220, 0, 50)
    bb.StudsOffset = Vector3.new(0, 3, 0)
    bb.AlwaysOnTop = true
    bb.Parent = adornee

    local txt = Instance.new("TextLabel")
    txt.Size = UDim2.new(1, 0, 1, 0)
    txt.BackgroundTransparency = 1
    txt.Text = label
    txt.TextColor3 = color
    txt.TextStrokeTransparency = 0
    txt.TextScaled = true
    txt.Parent = bb

    espCache[instance] = {hl, bb}
end

local function destroyESP(instance)
    local g = espCache[instance]
    if not g then return end
    for _, v in ipairs(g) do if v and v.Parent then v:Destroy() end end
    espCache[instance] = nil
end

local function clearAllESP()
    for inst in pairs(espCache) do destroyESP(inst) end
end

local function cleanESP()
    for inst in pairs(espCache) do
        if not inst.Parent then destroyESP(inst) end
    end
end

local function scanESP()
    if not CONFIG.ESP then return end
    if CONFIG.ESPPlayers then
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LP and plr.Character then
                addESP(plr.Character, Color3.fromRGB(255, 80, 80), plr.Name)
            end
        end
    end
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") or obj:IsA("BasePart") then
            if CONFIG.ESPItems and nameMatches(obj.Name, CONFIG.ItemNames) then
                addESP(obj, Color3.fromRGB(80, 255, 120), obj.Name)
            end
            if CONFIG.ESPAnimals and nameMatches(obj.Name, CONFIG.AnimalNames) then
                addESP(obj, Color3.fromRGB(255, 180, 60), obj.Name)
            end
        end
    end
end

-- ============ AUTO COLLECT ============
local function firePrompt(prompt)
    if not prompt or not prompt.Parent or not prompt.Enabled then return false end
    if type(fireproximityprompt) == "function" then
        pcall(fireproximityprompt, prompt); return true
    end
    return pcall(function()
        prompt:InputHoldBegin()
        if prompt.HoldDuration > 0 then task.wait(prompt.HoldDuration) end
        prompt:InputHoldEnd()
    end)
end

local function autoCollectLoop()
    while task.wait(0.25) do
        if not CONFIG.AutoCollect then continue end
        local char = LP.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then continue end
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("ProximityPrompt") and obj.Enabled then
                local parent = obj.Parent
                if parent then
                    local valid = CONFIG.CollectAllPrompts
                    if not valid then
                        valid = nameMatches(parent.Name, CONFIG.ItemNames)
                        if not valid and parent.Parent then
                            valid = nameMatches(parent.Parent.Name, CONFIG.ItemNames)
                        end
                    end
                    if valid then
                        local part = parent:IsA("BasePart") and parent
                            or parent:FindFirstChildWhichIsA("BasePart", true)
                        if part and (part.Position - root.Position).Magnitude <= CONFIG.CollectRadius then
                            firePrompt(obj)
                        end
                    end
                end
            end
        end
    end
end

-- ============ SPEED ============
RunService.Heartbeat:Connect(function()
    if not CONFIG.Speed then return end
    local char = LP.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.WalkSpeed = CONFIG.WalkSpeed
        hum.JumpPower = CONFIG.JumpPower
        hum.UseJumpPower = true
    end
end)

-- ============ FLY ============
local flyBV, flyBG
local function stopFly()
    if flyBV then flyBV:Destroy(); flyBV = nil end
    if flyBG then flyBG:Destroy(); flyBG = nil end
end

local function startFly()
    local char = LP.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    stopFly()
    flyBV = Instance.new("BodyVelocity")
    flyBV.Name = "ollie_fly_bv"
    flyBV.MaxForce = Vector3.new(1e5, 1e5, 1e5)
    flyBV.Velocity = Vector3.zero
    flyBV.Parent = root

    flyBG = Instance.new("BodyGyro")
    flyBG.Name = "ollie_fly_bg"
    flyBG.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
    flyBG.P = 1000
    flyBG.D = 50
    flyBG.Parent = root

    task.spawn(function()
        while CONFIG.Fly and flyBV and flyBV.Parent do
            local cam = Workspace.CurrentCamera
            local move = Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then move += cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then move -= cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then move -= cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then move += cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move += Vector3.yAxis end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then move -= Vector3.yAxis end
            if move.Magnitude > 0 then
                flyBV.Velocity = move.Unit * CONFIG.FlySpeed
            else
                flyBV.Velocity = Vector3.zero
            end
            flyBG.CFrame = cam.CFrame
            task.wait()
        end
        stopFly()
    end)
end

-- ============ FULLBRIGHT ============
local fullbrightPrev = nil
local function setFullbright(on)
    if on then
        if not fullbrightPrev then
            fullbrightPrev = {
                Brightness = Lighting.Brightness,
                ClockTime = Lighting.ClockTime,
                FogEnd = Lighting.FogEnd,
                Ambient = Lighting.Ambient,
            }
        end
        Lighting.Brightness = 3
        Lighting.ClockTime = 12
        Lighting.FogEnd = 1e6
        Lighting.Ambient = Color3.fromRGB(180, 180, 180)
    elseif fullbrightPrev then
        Lighting.Brightness = fullbrightPrev.Brightness
        Lighting.ClockTime = fullbrightPrev.ClockTime
        Lighting.FogEnd = fullbrightPrev.FogEnd
        Lighting.Ambient = fullbrightPrev.Ambient
        fullbrightPrev = nil
    end
end

-- ============ TELEPORT HELPERS ============
local function getRoot()
    local char = LP.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function tpTo(instance)
    local root = getRoot()
    if not root or not instance then return end
    local part = instance:IsA("BasePart") and instance
        or instance:FindFirstChildWhichIsA("BasePart", true)
    if part then
        root.CFrame = CFrame.new(part.Position + Vector3.new(0, 3, 0))
    end
end

local function findFirstByName(names)
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if nameMatches(obj.Name, names) then return obj end
    end
    return nil
end

local function tpCampfire()
    local fire = Workspace:FindFirstChild("Campfire", true)
        or findFirstByName({ "Campfire", "Firepit", "Fire" })
    if fire then tpTo(fire) else warn("[ollie] không tìm thấy campfire") end
end

local function tpChild()
    local child = findFirstByName(CONFIG.ChildNames)
    if child then tpTo(child) else warn("[ollie] không tìm thấy trẻ") end
end

local function tpChest()
    local chest = findFirstByName(CONFIG.ChestNames)
    if chest then tpTo(chest) else warn("[ollie] không tìm thấy rương") end
end

local function tpLogsToCampfire()
    local fire = Workspace:FindFirstChild("Campfire", true)
        or findFirstByName({ "Campfire", "Firepit" })
    if not fire then warn("[ollie] không tìm thấy campfire"); return end
    local root = getRoot()
    if not root then return end
    local firePos = (fire:IsA("BasePart") and fire.Position)
        or (fire:FindFirstChildWhichIsA("BasePart", true) or {}).Position
    if not firePos then return end

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") or obj:IsA("BasePart") then
            if nameMatches(obj.Name, { "Log", "Wood", "Stick", "Branch" }) then
                local part = obj:IsA("BasePart") and obj
                    or obj:FindFirstChildWhichIsA("BasePart", true)
                if part then
                    pcall(function()
                        part.CFrame = CFrame.new(firePos + Vector3.new(math.random(-5,5), 2, math.random(-5,5)))
                    end)
                end
            end
        end
    end
end

-- ============ KILL AURA ============
local function killAuraLoop()
    while task.wait(0.15) do
        if not CONFIG.KillAura then continue end
        local char = LP.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not root or not hum then continue end

        local tool = char:FindFirstChildWhichIsA("Tool")
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj ~= char and (obj:IsA("Model") or obj:IsA("BasePart")) then
                if nameMatches(obj.Name, CONFIG.AnimalNames) then
                    local part = obj:IsA("BasePart") and obj
                        or obj:FindFirstChildWhichIsA("BasePart", true)
                    if part and (part.Position - root.Position).Magnitude <= CONFIG.KillAuraRadius then
                        if tool then
                            pcall(function() tool:Activate() end)
                        else
                            local targetHum = obj:FindFirstChildOfClass("Humanoid")
                                or (obj.Parent and obj.Parent:FindFirstChildOfClass("Humanoid"))
                            if targetHum then
                                pcall(function() targetHum:TakeDamage(20) end)
                            end
                        end
                    end
                end
            end
        end
    end
end

-- ============ GUI ============
local function makeGui()
    local old = LP:WaitForChild("PlayerGui"):FindFirstChild("ollie_menu")
    if old then old:Destroy() end

    local gui = Instance.new("ScreenGui")
    gui.Name = "ollie_menu"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = LP:WaitForChild("PlayerGui")

    -- nút tròn thu gọn
    local round = Instance.new("TextButton")
    round.Name = "roundBtn"
    round.Size = UDim2.new(0, 52, 0, 52)
    round.Position = UDim2.new(0, 30, 0.5, -26)
    round.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
    round.BorderSizePixel = 0
    round.Text = "oll"
    round.TextColor3 = Color3.fromRGB(120, 255, 170)
    round.Font = Enum.Font.GothamBold
    round.TextSize = 16
    round.Visible = false
    round.Parent = gui
    Instance.new("UICorner", round).CornerRadius = UDim.new(1, 0)
    local rs = Instance.new("UIStroke", round)
    rs.Color = Color3.fromRGB(120, 255, 170); rs.Thickness = 1.5

    -- frame chính
    local main = Instance.new("Frame")
    main.Name = "mainFrame"
    main.Size = UDim2.new(0, 560, 0, 300)
    main.Position = UDim2.new(0, 30, 0.5, -150)
    main.BackgroundColor3 = Color3.fromRGB(16, 16, 20)
    main.BorderSizePixel = 0
    main.Parent = gui
    Instance.new("UICorner", main).CornerRadius = UDim.new(0, 10)
    local ms = Instance.new("UIStroke", main)
    ms.Color = Color3.fromRGB(60, 60, 70); ms.Thickness = 1

    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 36)
    header.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
    header.BorderSizePixel = 0
    header.Parent = main
    Instance.new("UICorner", header).CornerRadius = UDim.new(0, 10)

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -90, 1, 0)
    title.Position = UDim2.new(0, 14, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "ollie — 99 nights (tắt hết)"
    title.TextColor3 = Color3.fromRGB(120, 255, 170)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 14
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = header

    local collapseBtn = Instance.new("TextButton")
    collapseBtn.Size = UDim2.new(0, 26, 0, 26)
    collapseBtn.Position = UDim2.new(1, -34, 0.5, -13)
    collapseBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
    collapseBtn.BorderSizePixel = 0
    collapseBtn.Text = "–"
    collapseBtn.TextColor3 = Color3.fromRGB(200, 200, 210)
    collapseBtn.Font = Enum.Font.GothamBold
    collapseBtn.TextSize = 16
    collapseBtn.Parent = header
    Instance.new("UICorner", collapseBtn).CornerRadius = UDim.new(1, 0)

    local body = Instance.new("Frame")
    body.Size = UDim2.new(1, -20, 1, -46)
    body.Position = UDim2.new(0, 10, 0, 42)
    body.BackgroundTransparency = 1
    body.Parent = main

    local leftCol = Instance.new("Frame")
    leftCol.Size = UDim2.new(0.5, -6, 1, 0)
    leftCol.BackgroundTransparency = 1
    leftCol.Parent = body

    local rightCol = Instance.new("Frame")
    rightCol.Size = UDim2.new(0.5, -6, 1, 0)
    rightCol.Position = UDim2.new(0.5, 6, 0, 0)
    rightCol.BackgroundTransparency = 1
    rightCol.Parent = body

    local function makeSection(parent, txt, y)
        local f = Instance.new("Frame")
        f.Size = UDim2.new(1, 0, 0, 24)
        f.Position = UDim2.new(0, 0, 0, y)
        f.BackgroundTransparency = 1
        f.Parent = parent
        local l = Instance.new("TextLabel")
        l.Size = UDim2.new(1, 0, 1, 0)
        l.BackgroundTransparency = 1
        l.Text = txt
        l.TextColor3 = Color3.fromRGB(120, 255, 170)
        l.Font = Enum.Font.GothamBold
        l.TextSize = 12
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.Parent = f
        return f
    end

    local function makeToggle(parent, text, init, getFn, setFn, y)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 26)
        row.Position = UDim2.new(0, 0, 0, y)
        row.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
        row.BorderSizePixel = 0
        row.Parent = parent
        Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -60, 1, 0)
        lbl.Position = UDim2.new(0, 10, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = text
        lbl.TextColor3 = Color3.fromRGB(220, 220, 230)
        lbl.Font = Enum.Font.Gotham
        lbl.TextSize = 12
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = row

        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 40, 0, 18)
        btn.Position = UDim2.new(1, -48, 0.5, -9)
        btn.BackgroundColor3 = init and Color3.fromRGB(80, 200, 120) or Color3.fromRGB(60, 60, 70)
        btn.BorderSizePixel = 0
        btn.Text = init and "ON" or "OFF"
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 11
        btn.Parent = row
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)

        btn.MouseButton1Click:Connect(function()
            local v = not getFn()
            setFn(v)
            btn.BackgroundColor3 = v and Color3.fromRGB(80, 200, 120) or Color3.fromRGB(60, 60, 70)
            btn.Text = v and "ON" or "OFF"
        end)
        return row
    end

    local function makeButton(parent, text, onClick, y)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(1, 0, 0, 24)
        b.Position = UDim2.new(0, 0, 0, y)
        b.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
        b.BorderSizePixel = 0
        b.Text = text
        b.TextColor3 = Color3.fromRGB(200, 220, 255)
        b.Font = Enum.Font.Gotham
        b.TextSize = 12
        b.Parent = parent
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 5)
        b.MouseButton1Click:Connect(onClick)
        return b
    end

    -- CỘT TRÁI: ESP + COLLECT
    makeSection(leftCol, "ESP / Collect", 0)
    makeToggle(leftCol, "ESP master", CONFIG.ESP,
        function() return CONFIG.ESP end,
        function(v) CONFIG.ESP = v; if not v then clearAllESP() end end, 28)
    makeToggle(leftCol, "ESP players", CONFIG.ESPPlayers,
        function() return CONFIG.ESPPlayers end,
        function(v) CONFIG.ESPPlayers = v end, 58)
    makeToggle(leftCol, "ESP items", CONFIG.ESPItems,
        function() return CONFIG.ESPItems end,
        function(v) CONFIG.ESPItems = v end, 88)
    makeToggle(leftCol, "ESP animals", CONFIG.ESPAnimals,
        function() return CONFIG.ESPAnimals end,
        function(v) CONFIG.ESPAnimals = v end, 118)
    makeToggle(leftCol, "Auto collect", CONFIG.AutoCollect,
        function() return CONFIG.AutoCollect end,
        function(v) CONFIG.AutoCollect = v end, 148)
    makeToggle(leftCol, "Collect all prompts", CONFIG.CollectAllPrompts,
        function() return CONFIG.CollectAllPrompts end,
        function(v) CONFIG.CollectAllPrompts = v end, 178)

    -- CỘT PHẢI: MOVEMENT + ACTIONS
    makeSection(rightCol, "Movement / Actions", 0)
    makeToggle(rightCol, "Speed", CONFIG.Speed,
        function() return CONFIG.Speed end,
        function(v) CONFIG.Speed = v end, 28)
    makeToggle(rightCol, "Fly", CONFIG.Fly,
        function() return CONFIG.Fly end,
        function(v)
            CONFIG.Fly = v
            if v then startFly() else stopFly() end
        end, 58)
    makeToggle(rightCol, "Fullbright", CONFIG.Fullbright,
        function() return CONFIG.Fullbright end,
        function(v) CONFIG.Fullbright = v; setFullbright(v) end, 88)
    makeToggle(rightCol, "Kill aura", CONFIG.KillAura,
        function() return CONFIG.KillAura end,
        function(v) CONFIG.KillAura = v end, 118)

    makeButton(rightCol, "TP về lửa trại", tpCampfire, 152)
    makeButton(rightCol, "TP đến trẻ", tpChild, 180)
    makeButton(rightCol, "TP đến rương", tpChest, 208)
    makeButton(rightCol, "TP gỗ về lửa trại", tpLogsToCampfire, 236)

    local function setCollapsed(c)
        main.Visible = not c
        round.Visible = c
    end
    collapseBtn.MouseButton1Click:Connect(function() setCollapsed(true) end)
    round.MouseButton1Click:Connect(function() setCollapsed(false) end)

    -- kéo thả
    local function makeDraggable(handle, target)
        local dragging, dragStart, startPos
        handle.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true; dragStart = input.Position; startPos = target.Position
            end
        end)
        handle.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if not dragging then return end
            if input.UserInputType == Enum.UserInputType.MouseMovement
                or input.UserInputType == Enum.UserInputType.Touch then
                local d = input.Position - dragStart
                target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X,
                                            startPos.Y.Scale, startPos.Y.Offset + d.Y)
            end
        end)
    end
    makeDraggable(header, main)
    makeDraggable(round, round)
end

-- ============ START ============
makeGui()

task.spawn(function()
    while task.wait(CONFIG.ScanInterval) do
        cleanESP()
        scanESP()
    end
end)

task.spawn(autoCollectLoop)
task.spawn(killAuraLoop)

print("[ollie] 99 Nights loaded — tất cả OFF, menu ngang 2 cột, nút tròn thu gọn")
