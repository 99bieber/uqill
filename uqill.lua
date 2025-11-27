--[[ 
    FILE: fishing_uqill_v3.1.lua (MOD Auto Favorite v4.0)
    VERSION: 3.1 (Update: Auto Join Classic Event + Auto Favorite Inventory Based)
]]

-- =====================================================
-- 🧹 BAGIAN 1: CLEANUP SYSTEM
-- =====================================================
if getgenv().fishingStart then
    getgenv().fishingStart = false
    task.wait(0.5)
end

local CoreGui = game:GetService("CoreGui")
local GUI_NAMES = {
    Main = "UQiLL_Fishing_UI",
    Mobile = "UQiLL_Mobile_Button",
    Coords = "UQiLL_Coords_HUD"
}

for _, v in pairs(CoreGui:GetChildren()) do
    for _, name in pairs(GUI_NAMES) do
        if v.Name == name then v:Destroy() end
    end
end

for _, v in pairs(CoreGui:GetDescendants()) do
    if v:IsA("TextLabel") and v.Text == "UQiLL" then
        
        local container = v
        
        for i = 1, 10 do
            -- Cegah nil edge cases
            if typeof(container) ~= "Instance" then 
                break 
            end

            local parent = container.Parent
            if not parent then 
                break 
            end

            container = parent

            if typeof(container) == "Instance" and container:IsA("ScreenGui") then
                container:Destroy()
                break
            end
        end
    end
end


-- =====================================================
-- 🎣 BAGIAN 2: VARIABEL & REMOTE
-- =====================================================
getgenv().fishingStart = false
local legit = false
local instant = false
local superInstant = true 

local args = { -1.115296483039856, 0.5, 1763651451.636425 }
local delayTime = 0.56   
local delayCharge = 1.15 
local delayReset = 0.2 

local rs = game:GetService("ReplicatedStorage")
local net = rs.Packages["_Index"]["sleitnick_net@0.2.0"].net

-- Remote Definitions
local ChargeRod    = net["RF/ChargeFishingRod"]
local RequestGame  = net["RF/RequestFishingMinigameStarted"]
local CompleteGame = net["RE/FishingCompleted"]
local CancelInput  = net["RF/CancelFishingInputs"]
local SellAll      = net["RF/SellAllItems"] 
local EquipTank    = net["RF/EquipOxygenTank"]
local UpdateRadar  = net["RF/UpdateFishingRadar"]

local SettingsState = { 
    FPSBoost = { Active = false, BackupLighting = {} }, 
    VFXRemoved = false,
    DestroyerActive = false,
    PopupDestroyed = false,
    AutoSell = {
        TimeActive = false,
        TimeInterval = 60,
        IsSelling = false
    },
    AutoWeather = {
        Active = false,
        Targets = {} 
    },
    PosWatcher = { Active = false, Connection = nil },
    WaterWalk = { Active = false, Part = nil, Connection = nil },
    AnimsDisabled = { Active = false, Connections = {} },
    AutoEventDisco = { Active = false },
    AutoFavorite = {
        Active = false,
        Rarities = {}
    },
}

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local RunService = game:GetService("RunService")

---------------------------------------------------------------------
-- AUTO DISCO v13 — FINAL PRODUCTION VERSION
-- Clean, Efisien, Stabil, dan Terintegrasi dengan Event Asli (Replion)
---------------------------------------------------------------------

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Replion = require(RS.Packages.Replion)

local LP = Players.LocalPlayer

---------------------------------------------------------------------
-- KONFIGURASI TELEPORT
---------------------------------------------------------------------
local DISCO_POSITION     = Vector3.new(-8628, -548, 161)
local HEIGHT_OFFSET      = Vector3.new(0, 2, 0)

---------------------------------------------------------------------
-- INTERNAL STATE
---------------------------------------------------------------------
local eventActive        = false
local savedPosition      = nil
local listener           = nil

---------------------------------------------------------------------
-- UTILITY: Ambil HRP
---------------------------------------------------------------------
local function HRP()
    local char = LP.Character
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart")
end

---------------------------------------------------------------------
-- UTILITY: Safe Teleport v5
-- 5 attempt, hard-velocity kill, CFrame override
---------------------------------------------------------------------
local function SafeTeleport(destination)
    for _ = 1, 5 do
        local hrp = HRP()
        if hrp then
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.CFrame = CFrame.new(destination)
        end
        task.wait(0.08)
    end
end

---------------------------------------------------------------------
-- EVENT HANDLER: MULAI EVENT
-- Save posisi dan teleport masuk
---------------------------------------------------------------------
local function HandleEventStart()
    if eventActive then return end
    eventActive = true

    local hrp = HRP()
    if hrp then
        savedPosition = hrp.Position
    end

    print("[AutoDisco v13] Teleporting IN →", DISCO_POSITION)

    SafeTeleport(DISCO_POSITION + HEIGHT_OFFSET)
end

---------------------------------------------------------------------
-- EVENT HANDLER: AKHIR EVENT
-- Teleport balik ke posisi asal
---------------------------------------------------------------------
local function HandleEventEnd()
    if not eventActive then return end
    eventActive = false

    if savedPosition then
        print("[AutoDisco v13] Teleporting OUT →", savedPosition)
        SafeTeleport(savedPosition + HEIGHT_OFFSET)
    end

    savedPosition = nil
end

---------------------------------------------------------------------
-- PUBLIC API: Aktifkan AutoDisco
---------------------------------------------------------------------
function StartAutoDisco()
    print("[AutoDisco v13] ENABLED")

    local CGE = Replion.Client:WaitReplion("ClassicGroupEvent")

    -- Pastikan listener tidak ganda
    if listener then
        listener:Disconnect()
        listener = nil
    end

    -- Daftarkan listener baru
    listener = CGE:OnChange("Active", function(state)
        if state == true then
            HandleEventStart()
        else
            HandleEventEnd()
        end
    end)

    -- Jika event sedang aktif ketika script hidup
    if CGE:Get("Active") == true then
        HandleEventStart()
    end
end

---------------------------------------------------------------------
-- PUBLIC API: Matikan AutoDisco
---------------------------------------------------------------------
function StopAutoDisco()
    print("[AutoDisco v13] DISABLED")

    if listener then
        listener:Disconnect()
        listener = nil
    end

    eventActive   = false
    savedPosition = nil
end

---------------------------------------------------------------------
-- GLOBAL EXPORT (untuk SimMode atau script eksternal)
---------------------------------------------------------------------
_G.StartAutoDisco = StartAutoDisco
_G.StopAutoDisco  = StopAutoDisco

print("[AutoDisco v13] Loaded.")



local Waypoints = {
    ["Fisherman Island"]    = Vector3.new(-33, 10, 2770),
    ["Traveling Merchant"]  = Vector3.new(-135, 2, 2764),
    ["Kohana"]              = Vector3.new(-626, 16, 588),
    ["Kohana Lava"]         = Vector3.new(-594, 59, 112),
    ["Esoteric Island"]     = Vector3.new(1991, 6, 1390),
    ["Esoteric Depths"]     = Vector3.new(3240, -1302, 1404),
    ["Tropical Grove"]      = Vector3.new(-2132, 53, 3630),
    ["Coral Reef"]          = Vector3.new(-3138, 4, 2132),
    ["Weather Machine"]     = Vector3.new(-1517, 3, 1910),
    ["Sisyphus Statue"]     = Vector3.new(-3657, -134, -963),
    ["Treasure Room"]       = Vector3.new(-3604, -284, -1632),
    ["Ancient Jungle"]      = Vector3.new(1463, 8, -358),
    ["Ancient Ruin"]        = Vector3.new(6021, -586, 4633),
    ["Sacred Temple"]       = Vector3.new(1476, -22, -632),
    ["Classic Island"]      = Vector3.new(1433, 44, 2755),
    ["Iron Cavern"]         = Vector3.new(-8798, -585, 241),
    ["Iron Cafe"]           = Vector3.new(-8647, -548, 160),
    ["Crater Island"]           = Vector3.new(1070, 2, 5102)
}

local function TeleportTo(targetPos)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local HRP = LocalPlayer.Character.HumanoidRootPart
        HRP.AssemblyLinearVelocity = Vector3.new(0,0,0) 
        HRP.CFrame = CFrame.new(targetPos + Vector3.new(0, 3, 0))
    end
end

---------------------------------------------------------
-- AUTO WEATHER — ULTRA LIGHT (FINAL PATCH)
---------------------------------------------------------
---
---

task.defer(function()
    print("====== WEATHER SNIFFER ARMED v3 (SAFE) ======")

    local RS = game:GetService("ReplicatedStorage")
    local Replion = require(RS.Packages.Replion)
    local Events = Replion.Client:WaitReplion("Events")

    -- Coba sekali Get("WeatherMachine")
    local ok, result = pcall(function()
        return Events:Get("WeatherMachine")
    end)

    print("[SNIFF] First WeatherMachine value =", ok and result or "ERROR:", result)

    -- Start light polling
    task.spawn(function()
        local lastJson = ""

        while true do
            task.wait(1)

            local current = nil
            local ok2, res2 = pcall(function()
                return Events:Get("WeatherMachine")
            end)

            if ok2 then
                current = res2
            end

            -- Convert ke string buat deteksi perubahan
            local asJson = game:GetService("HttpService"):JSONEncode(current or {})

            if asJson ~= lastJson then
                warn("[SNIFF] WeatherMachine CHANGED →", current)
                lastJson = asJson
            end
        end
    end)
end)
-- ==========================================
-- AUTO WEATHER v4 — Ultra Light + Stable
-- ==========================================

local RS = game:GetService("ReplicatedStorage")
local Replion = require(RS.Packages.Replion)

local EventsReplion = Replion.Client:WaitReplion("Events")

local PurchaseWeather = RS
	:WaitForChild("Packages")
	:WaitForChild("_Index")
	:WaitForChild("sleitnick_net@0.2.0")
	:WaitForChild("net")
	:WaitForChild("RF/PurchaseWeatherEvent")

-- cache connection
local WeatherConn

-- cek apakah weather masih aktif di WeatherMachine
local function IsWeatherActive(name)
	local list = EventsReplion:Get("WeatherMachine")
	if not list then return false end

	for _, v in ipairs(list) do
		if v == name then
			return true
		end
	end
	return false
end

-- beli ulang jika cuaca habis
local function WeatherUpdated()
	local selected = SettingsState.AutoWeather.SelectedList
	if not selected then return end

	local activeList = EventsReplion:Get("WeatherMachine") or {}

	for _, weather in ipairs(selected) do
		if not IsWeatherActive(weather) then
			warn("[AUTO WEATHER] Purchasing:", weather)
			pcall(function()
				PurchaseWeather:InvokeServer(weather)
			end)
			task.wait(0.2)
		end
	end
end

-- start mode
function StartAutoWeather()
	if not SettingsState.AutoWeather.Active then return end

	warn("===== WEATHER SNIFFER ARMED v4 =====")

	-- disconnect old
	if WeatherConn then
		WeatherConn:Disconnect()
	end

	-- listen perubahan state replion WeatherMachine
	WeatherConn = EventsReplion:OnChange("WeatherMachine", function(newValue)
		warn("[SNIFF] WeatherMachine Changed =", newValue)
		task.defer(WeatherUpdated)
	end)

	-- initial scan
	task.defer(WeatherUpdated)
end

-- stop mode
function StopAutoWeather()
	if WeatherConn then
		WeatherConn:Disconnect()
		WeatherConn = nil
	end

	warn("[AUTO WEATHER] Disabled")
end


-- -- [[ UPDATED: AUTO EVENT LOGIC (V3.4 - ROTATION CHECK) ]]
-- local function IsDiscoEventActive()
--     local ClassicEvent = Workspace:FindFirstChild("ClassicEvent")
--     if not ClassicEvent then return false end 

--     local DiscoEvent = ClassicEvent:FindFirstChild("DiscoEvent")
--     if not DiscoEvent then return false end

--     local BallModel = DiscoEvent:FindFirstChild("DiscoBall")
--     if not BallModel then return false end

--     local BallPart = BallModel:FindFirstChild("DiscoBall")
--     if not BallPart then return false end

--     local rot1 = BallPart.Orientation
--     task.wait(0.1)
--     local rot2 = BallPart.Orientation

--     if (rot1 - rot2).Magnitude > 0.1 then
--         return true
--     end

--     return false
-- end

-- local function StartAutoEventMonitor()
--     task.spawn(function()
--         print("🎉 Event Monitor v3.4: STARTED (Rotation Mode)")
--         local isInEvent = false
--         local savedPosition = nil
        
--         while SettingsState.AutoEvent.Active do
--             pcall(function()
--                 local eventActive = IsDiscoEventActive()
--                 local char = LocalPlayer.Character
                
--                 if eventActive then
--                     if not isInEvent then
--                         if char and char:FindFirstChild("HumanoidRootPart") then
--                             savedPosition = char.HumanoidRootPart.Position
--                             print("📍 Position Saved: " .. tostring(savedPosition))
--                             TeleportTo(Vector3.new(-8629, -549, 163))
--                             isInEvent = true
                            
--                             local StarterGui = game:GetService("StarterGui")
--                             StarterGui:SetCore("SendNotification", {
--                                 Title = "🎉 EVENT STARTED!";
--                                 Text = "Bola Disko Berputar! OTW...";
--                                 Duration = 5;
--                             })
--                         end
--                     end
--                 else
--                     if isInEvent then
--                         print("🏁 Event Finished. Returning...")
--                         if savedPosition then
--                             TeleportTo(savedPosition)
--                         else
--                             TeleportTo(Waypoints["Traveling Merchant"])
--                         end
--                         isInEvent = false
--                         savedPosition = nil
                        
--                         local StarterGui = game:GetService("StarterGui")
--                         StarterGui:SetCore("SendNotification", {
--                             Title = "🏁 EVENT ENDED";
--                             Text = "Bola berhenti. Pulang...";
--                             Duration = 5;
--                         })
--                     end
--                 end
--             end)
--             task.wait(1.5) 
--         end
--     end)
-- end

-- =====================================================
-- 💰 BAGIAN 4: AUTO SELL
-- =====================================================
local function StartAutoSellLoop()
    task.spawn(function()
        print("💰 Auto Sell: BACKGROUND MODE STARTED")
        while SettingsState.AutoSell.TimeActive do
            for i = 1, SettingsState.AutoSell.TimeInterval do
                if not SettingsState.AutoSell.TimeActive then return end
                task.wait(1)
            end
            task.spawn(function()
                pcall(function() SellAll:InvokeServer() end)
            end)
        end
    end)
end

-- =====================================================
-- 🎣 BAGIAN 5: LOGIKA FISHING (TURBO)
-- =====================================================
local function startFishingLoop()
    print("🎣 Standard Loop")
    while getgenv().fishingStart do
        game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("_Index"):WaitForChild("sleitnick_net@0.2.0"):WaitForChild("net"):WaitForChild("RF/ChargeFishingRod"):InvokeServer()
        -- task.wait(delayCharge)
        if not getgenv().fishingStart then break end
        
        game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("_Index"):WaitForChild("sleitnick_net@0.2.0"):WaitForChild("net"):WaitForChild("RF/RequestFishingMinigameStarted"):InvokeServer(unpack(args))
        task.wait(delayTime)
        if not getgenv().fishingStart then break end 
        
        game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("_Index"):WaitForChild("sleitnick_net@0.2.0"):WaitForChild("net"):WaitForChild("RE/FishingCompleted"):FireServer()
        
        -- task.wait(1)
        game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("_Index"):WaitForChild("sleitnick_net@0.2.0"):WaitForChild("net"):WaitForChild("RE/FishingStopped"):FireServer()
        task.wait(0.05)
    end
end

local function startFishingSuperInstantLoop()
    print("⚡ TURBO Loop Started")
    local _Charge = ChargeRod
    local _Request = RequestGame
    local _Complete = CompleteGame
    local _Cancel = CancelInput
    while getgenv().fishingStart do
        pcall(function() _Cancel:InvokeServer() end)
        task.wait(0.05)
        task.spawn(function() pcall(function() _Charge:InvokeServer() end) end)
        task.wait(0.03)
        task.spawn(function() pcall(function() _Request:InvokeServer(unpack(args)) end) end)
        task.wait(delayCharge) 
        pcall(function() _Complete:FireServer() end)
        task.wait(delayReset) 
        pcall(function() _Cancel:InvokeServer() end)
        task.wait(0.05)
    end
    print("🛑 TURBO Loop Stopped")
end

-- =====================================================
-- ⚙️ BAGIAN 6: FITUR LAIN
-- =====================================================
local function ToggleFPSBoost(state)
    if state then
        pcall(function()
            settings().Rendering.QualityLevel = 1
            game:GetService("Lighting").GlobalShadows = false
        end)
        for _, v in pairs(game:GetDescendants()) do
            if v:IsA("BasePart") then v.Material = Enum.Material.Plastic; v.CastShadow = false end
        end
    end
end

local function ExecuteRemoveVFX()
    local function KillVFX(obj)
        if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") then
            obj.Enabled = false
            obj.Transparency = NumberSequence.new(1)
        elseif obj:IsA("Explosion") then obj.Visible = false end
    end
    for _, v in pairs(game:GetDescendants()) do pcall(function() KillVFX(v) end) end
    workspace.DescendantAdded:Connect(function(child)
        task.wait()
        pcall(function() 
            KillVFX(child) 
            for _, gc in pairs(child:GetDescendants()) do KillVFX(gc) end 
        end)
    end)
end

local function ExecuteDestroyPopup()
    local target = PlayerGui:FindFirstChild("Small Notification")
    if target then target:Destroy() end
    PlayerGui.ChildAdded:Connect(function(child)
        if child.Name == "Small Notification" then
            task.wait() 
            child:Destroy()
        end
    end)
end

local function StartAntiAFK()
    local VirtualUser = game:GetService("VirtualUser")
    if getconnections then
        for _, conn in pairs(getconnections(LocalPlayer.Idled)) do
            if conn.Disable then conn:Disable() elseif conn.Disconnect then conn:Disconnect() end
        end
    end
    pcall(function()
        LocalPlayer.Idled:Connect(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    end)
end

local function ToggleWaterWalk(state)
    if state then
        local p = Instance.new("Part")
        p.Name = "UQiLL_WaterPlatform"
        p.Anchored = true
        p.CanCollide = true
        p.Transparency = 1
        p.Size = Vector3.new(15, 1, 15)
        p.Parent = Workspace
        SettingsState.WaterWalk.Part = p

        SettingsState.WaterWalk.Connection = RunService.Heartbeat:Connect(function()
            local Char = Players.LocalPlayer.Character
            if Char and Char:FindFirstChild("HumanoidRootPart") and SettingsState.WaterWalk.Part then
                local hrpPos = Char.HumanoidRootPart.Position
                SettingsState.WaterWalk.Part.CFrame = CFrame.new(hrpPos.X, -3.1, hrpPos.Z)
            end
        end)
    else
        if SettingsState.WaterWalk.Connection then 
            SettingsState.WaterWalk.Connection:Disconnect() 
            SettingsState.WaterWalk.Connection = nil
        end
        if SettingsState.WaterWalk.Part then 
            SettingsState.WaterWalk.Part:Destroy() 
            SettingsState.WaterWalk.Part = nil
        end
    end
end

local function ToggleAnims(state)
    SettingsState.AnimsDisabled.Active = state
    
    local function StopAll()
        local Char = Players.LocalPlayer.Character
        if Char and Char:FindFirstChild("Humanoid") then
            local Hum = Char.Humanoid
            local Animator = Hum:FindFirstChild("Animator")
            if Animator then
                for _, track in pairs(Animator:GetPlayingAnimationTracks()) do
                    track:Stop()
                end
            end
        end
    end

    if state then
        StopAll()
        local function HookChar(char)
            local hum = char:WaitForChild("Humanoid")
            local animator = hum:WaitForChild("Animator")
            local conn = animator.AnimationPlayed:Connect(function(track)
                if SettingsState.AnimsDisabled.Active then track:Stop() end
            end)
            table.insert(SettingsState.AnimsDisabled.Connections, conn)
        end

        if Players.LocalPlayer.Character then HookChar(Players.LocalPlayer.Character) end
        local conn2 = Players.LocalPlayer.CharacterAdded:Connect(HookChar)
        table.insert(SettingsState.AnimsDisabled.Connections, conn2)
    else
        for _, conn in pairs(SettingsState.AnimsDisabled.Connections) do
            conn:Disconnect()
        end
        SettingsState.AnimsDisabled.Connections = {}
    end
end

-- ============================================================
-- 🎣 AUTO FAVORITE v7 — HYBRID WITH PROPER ON/OFF CONTROL
-- ============================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Replion = require(ReplicatedStorage.Packages.Replion)
local Data = Replion.Client:WaitReplion("Data")

-- Remote
local FavoriteItem = ReplicatedStorage
	:WaitForChild("Packages")
	:WaitForChild("_Index")
	:WaitForChild("sleitnick_net@0.2.0")
	:WaitForChild("net")
	:WaitForChild("RE/FavoriteItem")
	-- :WaitForChild("")

-------------------------------------------------------
-- Load FishDB
-------------------------------------------------------
local FishDB = {}
for _, module in ipairs(ReplicatedStorage.Items:GetChildren()) do
	if module:IsA("ModuleScript") then
		local ok, mod = pcall(require, module)
		if ok and mod and mod.Data and mod.Data.Type == "Fish" then
			FishDB[mod.Data.Id] = mod.Data.Tier
		end
	end
end
warn("[AFv7] FishDB Loaded:", #FishDB)

local function GetTier(id)
	return FishDB[id]
end

-------------------------------------------------------
-- Selected Tier
-------------------------------------------------------
local SelectedTier = {}

function SetSelectedRarities(list)
	SelectedTier = {}

	local map = {
		Common = 1, Uncommon = 2, Rare = 3, Epic = 4,
		Legendary = 5, Mythic = 6, Secret = 7,
		Exotic = 8, Azure = 9
	}

	for _, rarity in ipairs(list) do
		local tier = map[rarity]
		if tier then SelectedTier[tier] = true end
	end

	warn("[AFv7] Selected Tier Updated:", SelectedTier)
end

-------------------------------------------------------
-- FAVORITE LOGIC
-------------------------------------------------------
local KnownUUID = {}

local function FavoriteIfMatch(item)
	if not item then return end
	local uuid = item.UUID
	if KnownUUID[uuid] then return end

	local id = item.Id
	local fav = item.Favorited
	local tier = GetTier(id)

	if tier and SelectedTier[tier] and not fav then
		warn("[AFv7] Favoriting:", uuid, "Tier:", tier)
		pcall(function()
			FavoriteItem:FireServer(uuid)
		end)
	end

	KnownUUID[uuid] = true
end

local function InitialScan()
	local inv = Data:Get("Inventory")
	if inv and inv.Items then
		warn("[AFv7] InitialScan...")
		for _, item in pairs(inv.Items) do
			FavoriteIfMatch(item)
		end
	end
end

-------------------------------------------------------
-- EVENT CONTROL (ON / OFF)
-------------------------------------------------------
-- local InventoryConnection = nil  
local newFishConnection = nil
local AutoFavActive = false
local ObtainedNewFish = net["RE/ObtainedNewFishNotification"]

local function StartAutoFavorite()
	if SettingsState.AutoFavActive then return end
	warn("[AFv7] Auto Favorite ENABLED")

     -- FIX: RESET CACHE SETIAP DI-ON
    KnownUUID = {}

	-- initial scan once
	InitialScan()

	-- attach event
    newFishConnection = ObtainedNewFish.OnClientEvent:Connect(function(...)
        if not SettingsState.AutoFavorite.Active then return end

        warn("[AFv7] New fish obtained → scanning...")

        task.defer(function()
            local inv = Data:Get("Inventory")
            if not inv or not inv.Items then return end

            for _, item in pairs(inv.Items) do
                FavoriteIfMatch(item)
            end
        end)
    end)
end

local function StopAutoFavorite()
	if not AutoFavActive then return end
	AutoFavActive = false
	warn("[AFv7] Auto Favorite DISABLED")
    if newFishConnection then
        newFishConnection:Disconnect()
        newFishConnection = nil
    end

     -- FIX: RESET CACHE SETIAP DI-ON
    KnownUUID = {}
end

-------------------------------------------------------
-- UI toggle wrapper
-------------------------------------------------------
function ToggleAutoFavorite(state)
	if state then StartAutoFavorite()
	else StopAutoFavorite() end
end


local function SetSelectedRarities(list)
    SelectedTier = {}
    for _, rarityName in ipairs(list) do
        local map = {
            Common = 1,
            Uncommon = 2,
            Rare = 3,
            Epic = 4,
            Legendary = 5,
            Mythic = 6,
            Secret = 7,
            Exotic = 8,
            Azure = 9
        }

        local tier = map[rarityName]
        if tier then SelectedTier[tier] = true end
    end
end

-- =====================================================
-- 🌌 BAGIAN 7: TELEPORT UTILS
-- =====================================================
local function TeleportToMegalodon()
    local ringsFolder = Workspace:FindFirstChild("!!! MENU RINGS")
    if not ringsFolder then return end
    local propsFolder = ringsFolder:FindFirstChild("Props")
    if not propsFolder then return end
    local eventModel = propsFolder:FindFirstChild("Megalodon Hunt")
    
    if eventModel then
        local topPart = eventModel:FindFirstChild("Top")
        if topPart and topPart:FindFirstChild("BlackHole") then
            TeleportTo(topPart.BlackHole.Position + Vector3.new(0, 20, 0))
        else
            TeleportTo(eventModel:GetPivot().Position)
        end
    end
end

local CoordDisplay = nil 
local LivePosToggle = nil 

local function TogglePosWatcher(state)
    SettingsState.PosWatcher.Active = state
    if state then
        SettingsState.PosWatcher.Connection = RunService.RenderStepped:Connect(function()
            local Char = Players.LocalPlayer.Character
            if Char and Char:FindFirstChild("HumanoidRootPart") then
                local pos = Char.HumanoidRootPart.Position
                local txt = string.format("X: %.1f | Y: %.1f | Z: %.1f", pos.X, pos.Y, pos.Z)
                if CoordDisplay then pcall(function() CoordDisplay:SetDesc(txt) end) end
                if LivePosToggle then pcall(function() LivePosToggle:SetDesc(txt) end) end
            end
        end)
    else
        if SettingsState.PosWatcher.Connection then SettingsState.PosWatcher.Connection:Disconnect() end
        if CoordDisplay then pcall(function() CoordDisplay:SetDesc("Status: Off") end) end
        if LivePosToggle then pcall(function() LivePosToggle:SetDesc("Click to show coordinates") end) end
    end
end

local function FindPlayer(name)
    name = string.lower(name)
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            if string.find(string.lower(p.Name), name) or string.find(string.lower(p.DisplayName), name) then
                return p
            end
        end
    end
    return nil
end
local function GetPlayerList()
    local names = {}
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then table.insert(names, p.Name) end
    end
    table.sort(names)
    return names
end

local zoneNames = {}
for name, _ in pairs(Waypoints) do table.insert(zoneNames, name) end
table.sort(zoneNames)

---------------------------------------------------------------------
-- 📷 FREECAM v14 ULTIMATE — PURE LUA VERSION (NO += / -=)
---------------------------------------------------------------------

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ContextActionService = game:GetService("ContextActionService")

local LP = Players.LocalPlayer
local Cam = workspace.CurrentCamera

---------------------------------------------------------------------
-- INTERNAL STATE
---------------------------------------------------------------------
local FreecamEnabled = false

local MoveSpeed = 3
local RotSensitivity = 0.22
local CinematicMode = false
local CinematicStrength = 0.15
local FreecamFOV = 70

local rotX, rotY = 0, 0
local joyL = Vector2.new(0,0)
local joyR = Vector2.new(0,0)

local move = {
    W=false, S=false, A=false, D=false,
    Q=false, E=false
}

local humanoid
local savedWS=16
local savedJP=50
local savedAR=true

-- touch state
local draggingLeft = false
local draggingRight = false
local lastTouchPosLeft = nil
local lastTouchPosRight = nil

---------------------------------------------------------------------
-- DISABLE ROBLOX DEFAULT MOBILE CONTROLS
---------------------------------------------------------------------
local function DisableRobloxMobileControls()
    local PlayerGui = LP:WaitForChild("PlayerGui",1)
    if PlayerGui then
        for _,v in ipairs(PlayerGui:GetChildren()) do
            local name = string.lower(v.Name)
            if string.find(name,"touch") or string.find(name,"thumb") then
                v.Enabled = false
            end
        end
    end

    local PM = LP:WaitForChild("PlayerScripts",1):FindFirstChild("PlayerModule")
    if PM then
        local controls = require(PM):GetControls()
        if controls then controls:Disable() end
    end
end

local function EnableRobloxMobileControls()
    local PlayerGui = LP:WaitForChild("PlayerGui",1)
    if PlayerGui then
        for _,v in ipairs(PlayerGui:GetChildren()) do
            local name = string.lower(v.Name)
            if string.find(name,"touch") or string.find(name,"thumb") then
                v.Enabled = true
            end
        end
    end

    local PM = LP:WaitForChild("PlayerScripts",1):FindFirstChild("PlayerModule")
    if PM then
        local controls = require(PM):GetControls()
        if controls then controls:Enable() end
    end
end

---------------------------------------------------------------------
-- CREATE VIRTUAL JOYSTICKS (LEFT & RIGHT)
---------------------------------------------------------------------
local function CreateStickUI(px, py)
    local outer = Instance.new("Frame")
    outer.Size = UDim2.fromOffset(150,150)
    outer.Position = UDim2.new(0,px,1,py)
    outer.AnchorPoint = Vector2.new(0,1)
    outer.BackgroundColor3 = Color3.fromRGB(50,50,50)
    outer.BackgroundTransparency = 0.6
    outer.BorderSizePixel = 0

    local corner1 = Instance.new("UICorner", outer)
    corner1.CornerRadius = UDim.new(1,0)

    local inner = Instance.new("Frame")
    inner.Size = UDim2.fromOffset(60,60)
    inner.Position = UDim2.fromOffset(45,45)
    inner.BackgroundColor3 = Color3.fromRGB(255,255,255)
    inner.BackgroundTransparency = 0.2
    inner.BorderSizePixel = 0
    inner.Parent = outer

    local corner2 = Instance.new("UICorner", inner)
    corner2.CornerRadius = UDim.new(1,0)

    return outer, inner
end

local function CreateJoystickUI()
    local gui = Instance.new("ScreenGui")
    gui.Name = "UQ_Freecam_Sticks"
    gui.ResetOnSpawn = false
    gui.Parent = LP:WaitForChild("PlayerGui")

    local outerL, innerL = CreateStickUI(40, -220)
    local outerR, innerR = CreateStickUI(Cam.ViewportSize.X - 200, -220)

    outerL.Parent = gui
    outerR.Parent = gui

    return {
        gui = gui,
        L = {outer = outerL, inner = innerL},
        R = {outer = outerR, inner = innerR}
    }
end

local sticks = CreateJoystickUI()
sticks.gui.Enabled = false

---------------------------------------------------------------------
-- HELPER: PROCESS JOYSTICK MOVEMENT
---------------------------------------------------------------------
local function ProcessJoystick(outer, inner, input, isRight)
    local center = outer.AbsolutePosition + outer.AbsoluteSize/2

    local rel = Vector2.new(
        input.Position.X - center.X,
        input.Position.Y - center.Y
    )

    local maxDist = 50
    local dist = rel.Magnitude
    local clamped = rel

    if dist > maxDist then
        clamped = rel.Unit * maxDist
    end

    inner.Position = UDim2.fromOffset(outer.AbsoluteSize.X/2 + clamped.X, outer.AbsoluteSize.Y/2 + clamped.Y)

    local vec = clamped / maxDist

    if isRight then
        joyR = vec
    else
        joyL = vec
    end
end

---------------------------------------------------------------------
-- LEFT STICK INPUT
---------------------------------------------------------------------
sticks.L.outer.InputBegan:Connect(function(i)
    if not FreecamEnabled then return end
    if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
        draggingLeft = true
    end
end)

sticks.L.outer.InputChanged:Connect(function(i)
    if FreecamEnabled and draggingLeft then
        ProcessJoystick(sticks.L.outer, sticks.L.inner, i, false)
    end
end)

sticks.L.outer.InputEnded:Connect(function()
    draggingLeft = false
    joyL = Vector2.new(0,0)
    sticks.L.inner.Position = UDim2.fromOffset(45,45)
end)

---------------------------------------------------------------------
-- RIGHT STICK INPUT (Camera Rotation)
---------------------------------------------------------------------
sticks.R.outer.InputBegan:Connect(function(i)
    if not FreecamEnabled then return end
    if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
        draggingRight = true
    end
end)

sticks.R.outer.InputChanged:Connect(function(i)
    if FreecamEnabled and draggingRight then
        ProcessJoystick(sticks.R.outer, sticks.R.inner, i, true)
    end
end)

sticks.R.outer.InputEnded:Connect(function()
    draggingRight = false
    joyR = Vector2.new(0,0)
    sticks.R.inner.Position = UDim2.fromOffset(45,45)
end)

---------------------------------------------------------------------
-- KEYBOARD MOVEMENT (PC)
---------------------------------------------------------------------
UIS.InputBegan:Connect(function(i,g)
    if g or not FreecamEnabled then return end
    local k = i.KeyCode

    if k==Enum.KeyCode.W then move.W=true end
    if k==Enum.KeyCode.S then move.S=true end
    if k==Enum.KeyCode.A then move.A=true end
    if k==Enum.KeyCode.D then move.D=true end
    if k==Enum.KeyCode.E then move.E=true end
    if k==Enum.KeyCode.Q then move.Q=true end
end)

UIS.InputEnded:Connect(function(i)
    local k = i.KeyCode

    if k==Enum.KeyCode.W then move.W=false end
    if k==Enum.KeyCode.S then move.S=false end
    if k==Enum.KeyCode.A then move.A=false end
    if k==Enum.KeyCode.D then move.D=false end
    if k==Enum.KeyCode.E then move.E=false end
    if k==Enum.KeyCode.Q then move.Q=false end
end)

---------------------------------------------------------------------
-- MOUSE MOVE LOOK (PC)
---------------------------------------------------------------------
UIS.InputChanged:Connect(function(i,g)
    if not FreecamEnabled then return end

    if i.UserInputType == Enum.UserInputType.MouseMovement and not UIS.TouchEnabled then
        rotX = rotX - (i.Delta.X * RotSensitivity)
        rotY = math.clamp(rotY - (i.Delta.Y * RotSensitivity), -85, 85)
    end
end)

---------------------------------------------------------------------
-- TOUCH SWIPE LOOK (Mobile/Emulator)
---------------------------------------------------------------------
UIS.TouchMoved:Connect(function(t)
    if not FreecamEnabled then return end

    if draggingRight then return end -- right stick overrides

    if lastTouchPosRight == nil then
        lastTouchPosRight = t.Position
        return
    end

    local delta = t.Position - lastTouchPosRight
    rotX = rotX - (delta.X * RotSensitivity)
    rotY = math.clamp(rotY - (delta.Y * RotSensitivity), -85,85)

    lastTouchPosRight = t.Position
end)

UIS.TouchEnded:Connect(function()
    lastTouchPosRight = nil
end)

---------------------------------------------------------------------
-- MAIN CAMERA LOOP
---------------------------------------------------------------------
RunService.RenderStepped:Connect(function(dt)
    if not FreecamEnabled then return end

    local cf = Cam.CFrame

    -----------------------------------------------------------------
    -- MOVEMENT
    -----------------------------------------------------------------
    local moveVec = Vector3.new(0,0,0)

    -- joystick left
    -- FIX: invert Y for correct joystick forward/back
    moveVec = moveVec + (cf.LookVector * -joyL.Y)
    moveVec = moveVec + (cf.RightVector * joyL.X)


    -- keyboard
    if move.W then moveVec = moveVec + cf.LookVector end
    if move.S then moveVec = moveVec - cf.LookVector end
    if move.A then moveVec = moveVec - cf.RightVector end
    if move.D then moveVec = moveVec + cf.RightVector end
    if move.E then moveVec = moveVec + Vector3.new(0,1,0) end
    if move.Q then moveVec = moveVec - Vector3.new(0,1,0) end

    moveVec = moveVec * (MoveSpeed * dt * 60)

    -----------------------------------------------------------------
    -- ROTATION (from right stick + mouse)
    -----------------------------------------------------------------
    rotX = rotX - (joyR.X * RotSensitivity * 4)
    rotY = rotY - (joyR.Y * RotSensitivity * 4)
    rotY = math.clamp(rotY, -85,85)

    local rotCF =
        CFrame.Angles(0, math.rad(rotX), 0) *
        CFrame.Angles(math.rad(rotY), 0, 0)

    -----------------------------------------------------------------
    -- APPLY CAMERA
    -----------------------------------------------------------------
    local target = CFrame.new(cf.Position + moveVec) * rotCF

    if CinematicMode then
        Cam.CFrame = Cam.CFrame:Lerp(target, CinematicStrength)
    else
        Cam.CFrame = target
    end

    Cam.FieldOfView = FreecamFOV
end)

---------------------------------------------------------------------
-- API: Toggle Freecam
---------------------------------------------------------------------
function ToggleFreecam(state)
    FreecamEnabled = state

    local char = LP.Character
    humanoid = char and char:FindFirstChild("Humanoid")

    if state then
        Cam.CameraType = Enum.CameraType.Scriptable

        if humanoid then
            savedWS = humanoid.WalkSpeed
            savedJP = humanoid.JumpPower
            savedAR = humanoid.AutoRotate
            humanoid.WalkSpeed = 0
            humanoid.JumpPower = 0
            humanoid.AutoRotate = false
        end

        DisableRobloxMobileControls()

        if not UIS.TouchEnabled then
            UIS.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
            UIS.MouseIconEnabled = false
        end

        if char and char:FindFirstChild("HumanoidRootPart") then
            local hrp = char.HumanoidRootPart
            Cam.CFrame = hrp.CFrame
            rotX = hrp.Orientation.Y
        end

        sticks.gui.Enabled = true

        print("[Freecam v14] ENABLED")

    else
        FreecamEnabled = false

        UIS.MouseBehavior = Enum.MouseBehavior.Default
        UIS.MouseIconEnabled = true
        Cam.CameraType = Enum.CameraType.Custom

        sticks.gui.Enabled = false

        if humanoid then
            humanoid.WalkSpeed = savedWS
            humanoid.JumpPower = savedJP
            humanoid.AutoRotate = savedAR
        end

        EnableRobloxMobileControls()

        move = {W=false,S=false,A=false,D=false,Q=false,E=false}
        joyL = Vector2.new(0,0)
        joyR = Vector2.new(0,0)

        print("[Freecam v14] DISABLED")
    end
end

---------------------------------------------------------------------
-- API for UI
---------------------------------------------------------------------
function SetSpeed(v)
    MoveSpeed = v
end

function SetSensitivity(v)
    RotSensitivity = v
end

function SetCinematic(v)
    CinematicMode = v
end

function SetFOV(v)
    FreecamFOV = v
end

function TeleportPlayerToCamera()
    if LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
        LP.Character.HumanoidRootPart.CFrame = Cam.CFrame
    end
end

function ResetCameraAngle()
    rotX = 0
    rotY = 0
end

print("[Freecam v14 ULTIMATE] Pure Lua Engine Loaded")



-- ---------------------------------------------------------------------
-- -- INITIALIZE INFINITE VIEW
-- ---------------------------------------------------------------------
-- EnableInfiniteView()
-- print("[Freecam] Module Loaded")

-- =====================================================
-- 🎨 BAGIAN 8: WIND UI SETUP
-- =====================================================
local function setElementVisible(name, visible)
    task.spawn(function()
        local CoreGui = game:GetService("CoreGui")
        for _, v in pairs(CoreGui:GetDescendants()) do
            if v:IsA("TextLabel") and v.Text == name then
                local current = v
                for i = 1, 6 do
                    if current.Parent then
                        current = current.Parent
                        if current.Parent:IsA("ScrollingFrame") then
                            current.Visible = visible
                            break 
                        end
                    end
                end
                pcall(function()
                    if v.Parent.Parent:IsA("Frame") and v.Parent.Parent.Name ~= "Content" then v.Parent.Parent.Visible = visible end
                    if v.Parent.Parent.Parent:IsA("Frame") then v.Parent.Parent.Parent.Visible = visible end
                end)
                break 
            end
        end
    end)
end

local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
local Window = WindUI:CreateWindow({ Title = "UQiLL", Icon = "door-open", Author = "by UQi", Transparent = true })
Window.Name = GUI_NAMES.Main 
Window:Tag({ Title = "v.3.1", Icon = "github", Color = Color3.fromHex("#30ff6a"), Radius = 0 })
Window:SetToggleKey(Enum.KeyCode.H)

local TabPlayer = Window:Tab({ Title = "Player Setting", Icon = "user" })
local TabFishing = Window:Tab({ Title = "Auto Fishing", Icon = "fish" })
local TabFavorite = Window:Tab({ Title = "Auto Favorite", Icon = "star" })
local TabSell = Window:Tab({ Title = "Auto Sell", Icon = "shopping-bag" })
local TabWeather = Window:Tab({ Title = "Weather", Icon = "cloud-lightning" })
local TabTeleport = Window:Tab({ Title = "Teleport", Icon = "map-pin" })
local TabSettings = Window:Tab({ Title = "Settings", Icon = "settings" })

TabPlayer:Section({ Title = "Freecam Ultimate Controls" })

TabPlayer:Toggle({
	Title = "Enable Freecam",
	Desc = "Freecam v14 Ultimate",
	Icon = "camera",
	Value = false,
	Callback = function(v)
		ToggleFreecam(v)
	end
})

TabPlayer:Toggle({
	Title = "Cinematic Mode",
	Desc = "Smooth camera motion",
	Icon = "film",
	Value = false,
	Callback = function(v)
		SetCinematic(v)
	end
})

TabPlayer:Slider({
	Title = "Freecam Speed",
	Desc = "Adjust fly speed",
	Step = 0.1,
	Value = { Min = 0, Max = 15, Default = 3 },
	Callback = function(v)
		SetSpeed(v)
	end
})

TabPlayer:Slider({
	Title = "Sensitivity",
	Desc = "Camera rotation speed",
	Step = 0.01,
	Value = { Min = 0.05, Max = 1, Default = 0.25 },
	Callback = function(v)
		SetSensitivity(v)
	end
})

TabPlayer:Slider({
	Title = "Camera FOV",
	Desc = "Field of View",
	Step = 1,
	Value = { Min = 30, Max = 120, Default = 70 },
	Callback = function(v)
		SetFOV(v)
	end
})

TabPlayer:Button({
	Title = "Teleport Player To Camera",
	Desc = "Move character to freecam position",
	Icon = "crosshair",
	Callback = function()
		TeleportPlayerToCamera()
	end
})

TabPlayer:Button({
	Title = "Reset Camera",
	Desc = "Reset rotation instantly",
	Icon = "rotate-ccw",
	Callback = function()
		ResetCameraAngle()
	end
})


TabPlayer:Section({ Title = "Players Feature" })
TabPlayer:Toggle({ Title = "Walk on Water", Desc = "Creates a platform below you", Icon = "waves", Value = false, Callback = function(state) ToggleWaterWalk(state); WindUI:Notify({Title = "Movement", Content = state and "Water Walk ON" or "Water Walk OFF", Duration = 2}) end })
TabPlayer:Toggle({ Title = "Disable Animation", Desc = "Stop character anims (T-Pose)", Icon = "user-x", Value = false, Callback = function(state) ToggleAnims(state); WindUI:Notify({Title = "Player", Content = state and "Animations Disabled" or "Animations Enabled", Duration = 2}) end })
-- TabPlayer:Toggle({
--     Title = "Freecam Mode",
--     Desc = "Move camera freely (WASD + Mouse)",
--     Icon = "camera",
--     Value = false,
--     Callback = function(state)
--         ToggleFreecam(state)
--         WindUI:Notify({
--             Title = "Freecam",
--             Content = state and "Freecam Activated" or "Freecam Disabled",
--             Duration = 2
--         })
--     end
-- })


TabPlayer:Section({ Title = "Equipment" })
TabPlayer:Toggle({ Title = "Equip Diving Gear", Desc = "Toggle Oxygen Tank (105)", Icon = "anchor", Value = false, Callback = function(state) if state then pcall(function() EquipTank:InvokeServer(105) end); WindUI:Notify({Title = "Item", Content = "Diving Gear Equipped", Duration = 2}) else local Char = Players.LocalPlayer.Character; local Backpack = Players.LocalPlayer.Backpack; if Char then for _, t in pairs(Char:GetChildren()) do if t:IsA("Tool") and (string.find(t.Name, "Oxygen") or string.find(t.Name, "Tank") or string.find(t.Name, "Diving")) then t.Parent = Backpack end end end; WindUI:Notify({Title = "Item", Content = "Diving Gear Unequipped", Duration = 2}) end end })
TabPlayer:Toggle({ Title = "Equip Radar", Desc = "Toggle Fishing Radar", Icon = "radar", Value = false, Callback = function(state) pcall(function() UpdateRadar:InvokeServer(state) end); WindUI:Notify({Title = "Item", Content = state and "Radar ON" or "Radar OFF", Duration = 2}) end })

-- [[ TAB 1: FISHING ]]
TabFishing:Dropdown({ Title = "Category Fishing", Desc = "Select Mode", Values = {"Instant", "Blatan"}, Value = "Instant", Callback = function(option) instant, superInstant = (option == "Instant"), (option == "Blatan"); setElementVisible("Delay Fishing", false); setElementVisible("Delay Catch", false); setElementVisible("Reset Delay", false); if instant then setElementVisible("Delay Catch", true) elseif superInstant then setElementVisible("Delay Fishing", true); setElementVisible("Reset Delay", true) end end })
TabFishing:Slider({ Title = "Delay Fishing", Desc = "Wait Fish (Blatan)", Step = 0.01, Value = { Min = 0, Max = 3, Default = 1.15 }, Callback = function(value) delayCharge = value end })
TabFishing:Slider({ Title = "Reset Delay", Desc = "After Catch (Blatan)", Step = 0.01, Value = { Min = 0, Max = 1, Default = 0.2 }, Callback = function(value) delayReset = value end })
TabFishing:Slider({ Title = "Delay Catch", Desc = "Instant Speed", Step = 0.01, Value = { Min = 0.1, Max = 3, Default = 0.56 }, Callback = function(value) delayTime = value end })
TabFishing:Toggle({ Title = "Activate Fishing", Desc = "Start/Stop Loop", Icon = "check", Value = false, Callback = function(state) getgenv().fishingStart = state; if state then pcall(function() CancelInput:InvokeServer() end); if superInstant then task.spawn(startFishingSuperInstantLoop) else task.spawn(startFishingLoop) end; WindUI:Notify({Title = "Fishing", Content = "Started!", Duration = 2}) else pcall(function() CompleteGame:FireServer() end); pcall(function() CancelInput:InvokeServer() end); WindUI:Notify({Title = "Fishing", Content = "Stopped", Duration = 2}) end end })

-- [[ TAB 2: AUTO SELL ]]
TabSell:Toggle({ Title = "Auto Sell (Time)", Desc = "Safe Pauses Fishing to Sell", Icon = "timer", Value = false, Callback = function(state) SettingsState.AutoSell.TimeActive = state; if state then StartAutoSellLoop(); WindUI:Notify({Title = "Auto Sell", Content = "Loop Started", Duration = 2}) else SettingsState.AutoSell.IsSelling = false; WindUI:Notify({Title = "Auto Sell", Content = "Loop Stopped", Duration = 2}) end end })
TabSell:Slider({ Title = "Sell Interval (Seconds)", Desc = "Time between sells", Step = 1, Value = { Min = 10, Max = 300, Default = 60 }, Callback = function(value) SettingsState.AutoSell.TimeInterval = value end })
TabSell:Button({ Title = "Sell Now", Desc = "Sell All Items Immediately", Icon = "trash-2", Callback = function() task.spawn(function() SettingsState.AutoSell.IsSelling = true; task.wait(0.2); pcall(function() SellAll:InvokeServer() end); WindUI:Notify({Title = "Sell All", Content = "Sold!", Duration = 2}); task.wait(0.5); SettingsState.AutoSell.IsSelling = false end) end })

-- [[ TAB 3: WEATHER ]]
TabWeather:Dropdown({ Title = "Select Weather(s)", Desc = "Choose multiple weathers to maintain", Values = {"Wind", "Cloudy", "Snow", "Storm", "Radiant"}, Value = {}, Multi = true, AllowNone = true, Callback = function(option) SettingsState.AutoWeather.SelectedList = option end })
TabWeather:Toggle({ Title = "Smart Monitor", Desc = "Checks every 15s", Icon = "cloud-lightning", Value = false, Callback = function(state) SettingsState.AutoWeather.Active = state; if state then StartAutoWeather(); WindUI:Notify({Title = "Weather", Content = "Monitor Started", Duration = 2}) else StopAutoWeather() WindUI:Notify({Title = "Weather", Content = "Monitor Stopped", Duration = 2}) end end })

-- [[ TAB 4: TELEPORT ]]
TabTeleport:Section({ Title = "Auto Event" })
TabTeleport:Toggle({
    Title = "Auto Join Disco",
    Desc = "Warp to Iron Cafe when Active",
    Icon = "music",
    Value = false,
    Callback = function(state)
        SettingsState.AutoEventDisco.Active = state
        if state then 
            StartAutoDisco()
            WindUI:Notify({Title = "Event", Content = "Scanning for Disco...", Duration = 2})
        else 
            StopAutoDisco()
            WindUI:Notify({Title = "Event", Content = "Scanner Stopped", Duration = 2})
        end
    end
})

TabTeleport:Button({ Title = "Teleport to Megalodon", Desc = "Auto find in '!!! MENU RINGS'", Icon = "skull", Callback = function() TeleportToMegalodon() end })

TabTeleport:Section({ Title = "Islands" }) 
local TP_Dropdown = TabTeleport:Dropdown({ Title = "Select Island", Desc = "Fixed GPS Coordinates", Values = zoneNames, Value = zoneNames[1] or "Select", Callback = function(val) selectedZone = val end })
TabTeleport:Button({ Title = "Teleport to Island", Desc = "Warp to selected location", Icon = "navigation", Callback = function() if selectedZone and Waypoints[selectedZone] then TeleportTo(Waypoints[selectedZone]) else WindUI:Notify({Title = "Error", Content = "Coordinates missing", Duration = 2}) end end })
TabTeleport:Button({ Title = "Refresh List", Icon = "refresh-cw", Callback = function() WindUI:Notify({Title = "System", Content = "Static list reloaded", Duration = 1}) end })

TabTeleport:Section({ Title = "Player Teleport" })
local targetPlayerName = ""
local playerNames = GetPlayerList()
local PlayerDropdown = TabTeleport:Dropdown({ Title = "Select Player", Desc = "List of players in server", Values = playerNames, Value = playerNames[1] or "None", Callback = function(val) targetPlayerName = val end })
TabTeleport:Button({ Title = "Teleport to Player", Desc = "Go to target player", Icon = "user", Callback = function() local target = FindPlayer(targetPlayerName); if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then TeleportTo(target.Character.HumanoidRootPart.Position + Vector3.new(3, 0, 0)); WindUI:Notify({Title = "Teleport", Content = "Warped to " .. target.Name, Duration = 2}) else WindUI:Notify({Title = "Error", Content = "Player not found!", Duration = 2}) end end })
TabTeleport:Button({ Title = "Refresh Players", Desc = "Update list", Icon = "refresh-cw", Callback = function() local newPlayers = GetPlayerList(); PlayerDropdown:Refresh(newPlayers, newPlayers[1] or "None"); WindUI:Notify({Title = "System", Content = "List updated!", Duration = 2}) end })

TabTeleport:Section({ Title = "Coordinate Tools" })
LivePosToggle = TabTeleport:Toggle({ Title = "Show Live Pos", Desc = "Click to show coordinates", Icon = "monitor", Value = false, Callback = function(state) TogglePosWatcher(state) end })
CoordDisplay = TabTeleport:Paragraph({ Title = "Current Position", Desc = "Status: Off" })
TabTeleport:Button({ Title = "Copy Position", Desc = "Copy 'Vector3.new(...)'", Icon = "copy", Callback = function() local Char = Players.LocalPlayer.Character; if Char and Char:FindFirstChild("HumanoidRootPart") then local pos = Char.HumanoidRootPart.Position; local str = string.format("Vector3.new(%.0f, %.0f, %.0f)", pos.X, pos.Y, pos.Z); if setclipboard then setclipboard(str); WindUI:Notify({Title = "Copied!", Content = "Saved", Duration = 2}) else print("📍 COPIED: " .. str); WindUI:Notify({Title = "Error", Content = "Check F9", Duration = 2}) end end end })


-- [[ TAB 5: SETTINGS ]]
TabSettings:Section({ Title = "Server" })
TabSettings:Button({ 
    Title = "Server Hop (Low Player)", 
    Desc = "Find server with space", 
    Icon = "server", 
    Callback = function() 
        WindUI:Notify({Title = "Server Hop", Content = "Searching...", Duration = 3})
        local Http = game:GetService("HttpService")
        local TPS = game:GetService("TeleportService")
        local Api = "https://games.roblox.com/v1/games/"
        local PlaceId = game.PlaceId
        local _servers = Api..PlaceId.."/servers/Public?sortOrder=Asc&limit=100"
        
        local function ListServers(cursor)
            local Raw = game:HttpGet(_servers .. ((cursor and "&cursor="..cursor) or ""))
            return Http:JSONDecode(Raw)
        end
        
        local Server, Next; repeat
            local Servers = ListServers(Next)
            Server = Servers.data[1]
            Next = Servers.nextPageCursor
        until Server
        
        TPS:TeleportToPlaceInstance(PlaceId, Server.id, LocalPlayer)
    end 
})

TabSettings:Button({
    Title = "Rejoin Game (Auto-Exec)",
    Desc = "Rejoin & Run Script",
    Icon = "rotate-cw",
    Callback = function()
        local ts = game:GetService("TeleportService")
        local p = game:GetService("Players").LocalPlayer
        
        WindUI:Notify({Title = "System", Content = "Rejoining...", Duration = 3})
        local myScript = 'loadstring(game:HttpGet("https://raw.githubusercontent.com/99bieber/uqill/refs/heads/main/uqill.lua"))()'
        if (syn and syn.queue_on_teleport) then
            syn.queue_on_teleport(myScript)
        elseif queue_on_teleport then
            queue_on_teleport(myScript)
        end
        ts:Teleport(game.PlaceId, p)
    end
})

TabSettings:Section({ Title = "Optimization" })
TabSettings:Button({ Title = "Anti-AFK", Desc = "Status: Active (Always On)", Icon = "clock", Callback = function() WindUI:Notify({ Title = "Anti-AFK", Content = "Permanently Active", Duration = 2 }) end })
TabSettings:Button({ Title = "Destroy Fish Popup", Desc = "Permanently removes 'Small Notification' UI", Icon = "trash-2", Callback = function() if SettingsState.PopupDestroyed then WindUI:Notify({Title = "UI", Content = "Already Destroyed!", Duration = 2}) return end; SettingsState.PopupDestroyed = true; ExecuteDestroyPopup(); WindUI:Notify({Title = "UI", Content = "Popup Destroyed!", Duration = 3}) end })
TabSettings:Toggle({ Title = "FPS Boost (Potato)", Desc = "Low Graphics", Icon = "monitor", Value = false, Callback = function(state) ToggleFPSBoost(state) end })
TabSettings:Button({ Title = "Remove VFX (Permanent)", Desc = "Delete Effects", Icon = "trash-2", Callback = function() if SettingsState.VFXRemoved then WindUI:Notify({Title = "VFX", Content = "Already Removed!", Duration = 2}) return end; SettingsState.VFXRemoved = true; ExecuteRemoveVFX(); WindUI:Notify({Title = "VFX", Content = "Deleted!", Duration = 2}) end })
local RarityList = {"Common","Uncommon","Rare","Epic","Legendary","Mythic","Secret","Exotic","Azure"}

TabFavorite:Dropdown({
    Title = "Select Rarity to Favorite",
    Desc = "Choose rarities",
    Values = RarityList,
    Value = {},
    Multi = true,
    AllowNone = true,
    Callback = function(list)
        SetSelectedRarities(list)
    end
})

TabFavorite:Toggle({
    Title = "Active Auto Favorite",
    Desc = "Automatically favorites selected rarities",
    Icon = "star",
    Value = false,
    Callback = function(state)
        SettingsState.AutoFavorite.Active = state
        ToggleAutoFavorite(state)
        if state then
            WindUI:Notify({Title = "Auto Favorite", Content = "Running...", Duration = 2})
        else
            WindUI:Notify({Title = "Auto Favorite", Content = "Stopped", Duration = 2})
        end
    end
})


-- Init
task.delay(1, function()
    setElementVisible("Delay Fishing", false); setElementVisible("Delay Catch", false); setElementVisible("Reset Delay", false)
    if instant then setElementVisible("Delay Catch", true)
    elseif superInstant then setElementVisible("Delay Fishing", true); setElementVisible("Reset Delay", true) end
end)

task.spawn(StartAntiAFK)
print("✅ Script v3.1 Loaded! (With AutoFavorite v4.0)")
