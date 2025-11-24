--[[ 
    FILE: fishing.lua
    VERSION: 2.7 (Turbo Loop + Player Toggles)
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
            if container.Parent then
                container = container.Parent
                if container:IsA("ScreenGui") then container:Destroy() break end
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
local PurchaseWeather = net["RF/PurchaseWeatherEvent"]
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
    WaterWalk = { Active = false, Part = nil, Connection = nil } 
}

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local RunService = game:GetService("RunService")

-- =====================================================
-- 🌦️ BAGIAN 3: SMART WEATHER
-- =====================================================
local function GetActiveWeathers()
    local activeList = {}
    local PG = Players.LocalPlayer:FindFirstChild("PlayerGui")
    if not PG then return activeList end

    local weatherUI = PG:FindFirstChild("!!! Weather Machine")
    if weatherUI then
        local grid = weatherUI:FindFirstChild("Frame") 
            and weatherUI.Frame:FindFirstChild("Frame") 
            and weatherUI.Frame.Frame:FindFirstChild("Left") 
            and weatherUI.Frame.Frame.Left:FindFirstChild("Frame")
            and weatherUI.Frame.Frame.Left.Frame:FindFirstChild("Grid")
        
        if grid then
            for _, child in pairs(grid:GetChildren()) do
                if child.Name == "ActiveTile" then
                    local content = child:FindFirstChild("Content")
                    if content then
                        for _, item in pairs(content:GetChildren()) do
                            if item:IsA("ImageLabel") then
                                table.insert(activeList, item.Name) 
                            end
                        end
                    end
                end
            end
        end
    end
    return activeList
end

local function StartSmartWeatherLoop()
    task.spawn(function()
        print("🌦️ Smart Weather: STARTED")
        while SettingsState.AutoWeather.Active do
            local currentActive = GetActiveWeathers()
            for _, targetWeather in pairs(SettingsState.AutoWeather.SelectedList) do
                local isAlreadyActive = false
                for _, activeName in pairs(currentActive) do
                    if string.find(string.lower(activeName), string.lower(targetWeather)) then
                        isAlreadyActive = true
                        break
                    end
                end
                if not isAlreadyActive then
                    pcall(function() PurchaseWeather:InvokeServer(targetWeather) end)
                    task.wait(2) 
                end
            end
            for i = 1, 15 do 
                if not SettingsState.AutoWeather.Active then return end
                task.wait(1)
            end
        end
    end)
end

-- =====================================================
-- 💰 BAGIAN 4: AUTO SELL
-- =====================================================
local function StartAutoSellLoop()
    task.spawn(function()
        print("💰 Auto Sell: STARTED")
        while SettingsState.AutoSell.TimeActive do
            for i = 1, SettingsState.AutoSell.TimeInterval do
                if not SettingsState.AutoSell.TimeActive then return end
                task.wait(1)
            end
            SettingsState.AutoSell.IsSelling = true 
            task.wait(0.5) 
            pcall(function() SellAll:InvokeServer() end)
            pcall(function() CancelInput:InvokeServer() end)
            task.wait(0.5)
            SettingsState.AutoSell.IsSelling = false
        end
    end)
end

-- =====================================================
-- 🎣 BAGIAN 5: LOGIKA FISHING (TURBO)
-- =====================================================
local function startFishingLoop()
    print("🎣 Standard Loop Started")
    while getgenv().fishingStart do
        while SettingsState.AutoSell.IsSelling do task.wait(0.1) end
        task.spawn(function() ChargeRod:InvokeServer() end)
        task.spawn(function() RequestGame:InvokeServer(unpack(args)) end)
        task.wait(delayTime)
        CompleteGame:FireServer()
        task.wait(delayCharge)
    end
    print("🛑 Loop Berhenti.")
end

local function startFishingSuperInstantLoop()
    print("⚡ TURBO Loop Started")
    while getgenv().fishingStart do
        while SettingsState.AutoSell.IsSelling do task.wait(0.1) end
        pcall(function() CancelInput:InvokeServer() end)
        task.wait(0.05)
        task.spawn(function() pcall(function() ChargeRod:InvokeServer() end) end)
        task.wait(0.03)
        task.spawn(function() pcall(function() RequestGame:InvokeServer(unpack(args)) end) end)
        task.wait(delayCharge) 
        pcall(function() CompleteGame:FireServer() end)
        task.wait(delayReset) 
        pcall(function() CancelInput:InvokeServer() end)
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
        pcall(function() KillVFX(child); for _, gc in pairs(child:GetDescendants()) do KillVFX(gc) end end)
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

-- WATER WALK (FIXED)
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

-- =====================================================
-- 🌌 BAGIAN 7: TELEPORT SYSTEM
-- =====================================================
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
    ["Creater Island"]      = Vector3.new(1021, 16, 5065),
    ["Classic Island"]      = Vector3.new(1433, 44, 2755),
    ["Iron Cavern"]         = Vector3.new(-8798, -585, 241),
    ["Iron Cafe"]           = Vector3.new(-8647, -548, 160)
}

local function TeleportTo(targetPos)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local HRP = LocalPlayer.Character.HumanoidRootPart
        HRP.AssemblyLinearVelocity = Vector3.new(0,0,0) 
        HRP.CFrame = CFrame.new(targetPos + Vector3.new(0, 3, 0))
    end
end

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
Window:Tag({ Title = "v.1.1.1", Icon = "github", Color = Color3.fromHex("#30ff6a"), Radius = 0 })
Window:SetToggleKey(Enum.KeyCode.H)

local TabPlayer = Window:Tab({ Title = "Player Setting", Icon = "user" })
local TabFishing = Window:Tab({ Title = "Auto Fishing", Icon = "fish" })
local TabSell = Window:Tab({ Title = "Auto Sell", Icon = "shopping-bag" })
local TabWeather = Window:Tab({ Title = "Weather", Icon = "cloud-lightning" })
local TabTeleport = Window:Tab({ Title = "Teleport", Icon = "map-pin" })
local TabSettings = Window:Tab({ Title = "Settings", Icon = "settings" })

-- [[ TAB PLAYER: UTILITIES (UPDATED TOGGLES) ]]
TabPlayer:Toggle({
    Title = "Walk on Water", Desc = "Creates a platform below you", Icon = "waves", Value = false, 
    Callback = function(state) ToggleWaterWalk(state); WindUI:Notify({Title = "Movement", Content = state and "Water Walk ON" or "Water Walk OFF", Duration = 2}) end
})

TabPlayer:Toggle({
    Title = "Equip Diving Gear", Desc = "Toggle Oxygen Tank (105)", Icon = "anchor", Value = false,
    Callback = function(state)
        if state then
            pcall(function() EquipTank:InvokeServer(105) end)
            WindUI:Notify({Title = "Item", Content = "Diving Gear Equipped", Duration = 2})
        else
            -- Logic unequip manual: Cari tool di karakter, pindah ke backpack
            local Char = Players.LocalPlayer.Character
            local Backpack = Players.LocalPlayer.Backpack
            if Char then
                for _, t in pairs(Char:GetChildren()) do
                    if t:IsA("Tool") and (string.find(t.Name, "Oxygen") or string.find(t.Name, "Tank") or string.find(t.Name, "Diving")) then
                        t.Parent = Backpack
                    end
                end
            end
            WindUI:Notify({Title = "Item", Content = "Diving Gear Unequipped", Duration = 2})
        end
    end
})

TabPlayer:Toggle({
    Title = "Equip Radar", Desc = "Toggle Fishing Radar", Icon = "radar", Value = false,
    Callback = function(state)
        pcall(function() UpdateRadar:InvokeServer(state) end)
        WindUI:Notify({Title = "Item", Content = state and "Radar ON" or "Radar OFF", Duration = 2})
    end
})

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
TabWeather:Toggle({ Title = "Smart Monitor", Desc = "Checks every 15s", Icon = "cloud-lightning", Value = false, Callback = function(state) SettingsState.AutoWeather.Active = state; if state then StartSmartWeatherLoop(); WindUI:Notify({Title = "Weather", Content = "Monitor Started", Duration = 2}) else WindUI:Notify({Title = "Weather", Content = "Monitor Stopped", Duration = 2}) end end })

-- [[ TAB 4: TELEPORT ]]
TabTeleport:Section({ Title = "Event" })
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
TabSettings:Button({ Title = "Anti-AFK", Desc = "Status: Active (Always On)", Icon = "clock", Callback = function() WindUI:Notify({ Title = "Anti-AFK", Content = "Permanently Active", Duration = 2 }) end })
TabSettings:Button({ Title = "Destroy Fish Popup", Desc = "Permanently removes 'Small Notification' UI", Icon = "trash-2", Callback = function() if SettingsState.PopupDestroyed then WindUI:Notify({Title = "UI", Content = "Already Destroyed!", Duration = 2}) return end; SettingsState.PopupDestroyed = true; ExecuteDestroyPopup(); WindUI:Notify({Title = "UI", Content = "Popup Destroyed!", Duration = 3}) end })
TabSettings:Toggle({ Title = "FPS Boost (Potato)", Desc = "Low Graphics", Icon = "monitor", Value = false, Callback = function(state) ToggleFPSBoost(state) end })
TabSettings:Button({ Title = "Remove VFX (Permanent)", Desc = "Delete Effects", Icon = "trash-2", Callback = function() if SettingsState.VFXRemoved then WindUI:Notify({Title = "VFX", Content = "Already Removed!", Duration = 2}) return end; SettingsState.VFXRemoved = true; ExecuteRemoveVFX(); WindUI:Notify({Title = "VFX", Content = "Deleted!", Duration = 2}) end })

-- Init
task.delay(1, function()
    setElementVisible("Delay Fishing", false); setElementVisible("Delay Catch", false); setElementVisible("Reset Delay", false)
    if instant then setElementVisible("Delay Catch", true)
    elseif superInstant then setElementVisible("Delay Fishing", true); setElementVisible("Reset Delay", true) end
end)

task.spawn(StartAntiAFK)
print("✅ Script Loaded!")