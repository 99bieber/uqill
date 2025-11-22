--[[ 
    FILE: fishing.lua
    FINAL VERSION: SAFE CLEANUP (Protects Executor GUI)
]]

-- =====================================================
-- 🧹 BAGIAN 1: SMART CLEANUP (HANYA HAPUS GUI KITA)
-- =====================================================
-- Nama unik untuk GUI kita agar mudah dicari dan dihapus
local MyGuiName = "UQiLL_Fishing_UI"
local MobileGuiName = "UQiLL_Mobile_Button"

if getgenv().fishingStart then
    getgenv().fishingStart = false
    task.wait(0.5)
end

local CoreGui = game:GetService("CoreGui")

-- Hapus Window Utama Lama
for _, v in pairs(CoreGui:GetChildren()) do
    if v.Name == MyGuiName then
        v:Destroy()
    end
end

-- Hapus Tombol Mobile Lama
for _, v in pairs(CoreGui:GetChildren()) do
    if v.Name == MobileGuiName then
        v:Destroy()
    end
end

-- (Opsional) Hapus sisa-sisa WindUI yang mungkin pakai nama random
-- Kita filter agar tidak menghapus GUI Executor (Delta biasanya bernama "Delta" atau "RobloxGui")
for _, v in pairs(CoreGui:GetChildren()) do
    if v:IsA("ScreenGui") then
        -- Cek apakah di dalamnya ada TextLabel "UQiLL"
        local label = v:FindFirstChild("Title", true) -- WindUI biasanya punya Title
        if label and label:IsA("TextLabel") and label.Text == "UQiLL" then
            v:Destroy()
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
local delayTime = 0.56   -- Instant (Delay Catch)
local delayCharge = 1.15 -- Blatan (Delay Fishing/Wait Fish)
local delayReset = 0.2   -- Blatan (Delay Reset/Micro Reset) <--- VARIABEL BARU

local rs = game:GetService("ReplicatedStorage")
local net = rs.Packages["_Index"]["sleitnick_net@0.2.0"].net
local ChargeRod    = net["RF/ChargeFishingRod"]
local RequestGame  = net["RF/RequestFishingMinigameStarted"]
local CompleteGame = net["RE/FishingCompleted"]
local CancelInput  = net["RF/CancelFishingInputs"]
local SellAll      = net["RF/SellAllItems"] 

local SettingsState = { 
    FPSBoost = { Active = false, BackupLighting = {} }, 
    VFXRemoved = false,
    DestroyerActive = false,
    PopupDestroyed = false,
    AutoSell = {
        TimeActive = false,
        TimeInterval = 60,
        IsSelling = false
    }
}

-- =====================================================
-- 💰 BAGIAN 3: AUTO SELL (BACKGROUND PAUSER)
-- =====================================================
local function StartAutoSellLoop()
    task.spawn(function()
        print("💰 Auto Sell Service: STARTED")
        
        while SettingsState.AutoSell.TimeActive do
            for i = 1, SettingsState.AutoSell.TimeInterval do
                if not SettingsState.AutoSell.TimeActive then return end
                task.wait(1)
            end

            SettingsState.AutoSell.IsSelling = true 
            task.wait(0.5) 
            
            local success, err = pcall(function()
                SellAll:InvokeServer()
            end)
            
            if success then print("💰 Sold Items!") end
            
            pcall(function() CancelInput:InvokeServer() end)
            task.wait(0.5)
            
            SettingsState.AutoSell.IsSelling = false
        end
    end)
end

-- =====================================================
-- 🎣 BAGIAN 4: LOGIKA FISHING (TURBO + SLIDER UPDATE)
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
        
        while SettingsState.AutoSell.IsSelling do
            task.wait(0.1) 
        end

        -- 1. Lanjut Mancing
        pcall(function() CancelInput:InvokeServer() end)
        task.wait(0.05)

        task.spawn(function() pcall(function() ChargeRod:InvokeServer() end) end)
        task.wait(0.03)
        task.spawn(function() pcall(function() RequestGame:InvokeServer(unpack(args)) end) end)

        task.wait(delayCharge) -- Slider: Delay Fishing

        pcall(function() CompleteGame:FireServer() end)

        -- 2. Reset Akhir (UPDATED)
        -- Menggunakan delayReset dari slider baru
        task.wait(delayReset) 
        
        pcall(function() CancelInput:InvokeServer() end)
        task.wait(0.05)
    end
    print("🛑 TURBO Loop Stopped")
end

-- =====================================================
-- ⚙️ BAGIAN 5: FITUR LAIN
-- =====================================================
local Lighting = game:GetService("Lighting")
local Terrain = workspace:FindFirstChildWhichIsA("Terrain")
local Players = game:GetService("Players")
local PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
local RunService = game:GetService("RunService")

local function SaveLighting()
    if not SettingsState.FPSBoost.BackupLighting.GlobalShadows then
        SettingsState.FPSBoost.BackupLighting = {
            GlobalShadows = Lighting.GlobalShadows, FogStart = Lighting.FogStart, FogEnd = Lighting.FogEnd,
            Brightness = Lighting.Brightness, ExposureCompensation = Lighting.ExposureCompensation
        }
    end
end

local function ToggleFPSBoost(state)
    SettingsState.FPSBoost.Active = state
    if state then
        SaveLighting()
        pcall(function()
            settings().Rendering.QualityLevel = 1
            Lighting.GlobalShadows = false
            Lighting.FogStart = 9e9; Lighting.FogEnd = 9e9; Lighting.Brightness = 2
        end)
        if Terrain then Terrain.WaterWaveSize = 0; Terrain.WaterWaveSpeed = 0; Terrain.WaterTransparency = 1 end
        for _, v in pairs(game:GetDescendants()) do
            if v:IsA("BasePart") and not v:IsA("MeshPart") then v.Material = Enum.Material.Plastic; v.CastShadow = false end
        end
    else
        local bk = SettingsState.FPSBoost.BackupLighting
        pcall(function()
            Lighting.GlobalShadows = bk.GlobalShadows; Lighting.FogStart = bk.FogStart; Lighting.FogEnd = bk.FogEnd
            Lighting.Brightness = bk.Brightness; Lighting.ExposureCompensation = bk.ExposureCompensation
        end)
        if Terrain then Terrain.WaterWaveSize = 0.15; Terrain.WaterWaveSpeed = 10; Terrain.WaterTransparency = 0.3 end
    end
end

local function ExecuteRemoveVFX()
    local function KillVFX(obj)
        if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") then
            obj.Enabled = false
            if obj:IsA("Beam") or obj:IsA("Trail") or obj:IsA("ParticleEmitter") then obj.Transparency = NumberSequence.new(1) end
        elseif obj:IsA("PointLight") or obj:IsA("SpotLight") or obj:IsA("SurfaceLight") then obj.Enabled = false
        elseif obj:IsA("Explosion") then obj.Visible = false
        elseif obj:IsA("Highlight") then obj.Enabled = false
        end
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
    local LocalPlayer = Players.LocalPlayer
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

-- =====================================================
-- 🎨 BAGIAN 6: WIND UI SETUP
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
Window:Tag({ Title = "v.1.0.0", Icon = "github", Color = Color3.fromHex("#30ff6a"), Radius = 0 })
Window:SetToggleKey(Enum.KeyCode.H)

local TabFishing = Window:Tab({ Title = "Auto Fishing", Icon = "fish" })
local TabSell = Window:Tab({ Title = "Auto Sell", Icon = "shopping-bag" })
local TabSettings = Window:Tab({ Title = "Settings", Icon = "settings" })

-- [[ TAB 1: FISHING ]]
local Dropdown = TabFishing:Dropdown({
    Title = "Category Fishing", Desc = "Select Mode",
    Values = {"Instant", "Blatan"}, Value = "Instant",
    Callback = function(option)
        instant, superInstant = (option == "Instant"), (option == "Blatan")
        
        -- Reset semua slider
        setElementVisible("Delay Fishing", false)
        setElementVisible("Delay Catch", false)
        setElementVisible("Reset Delay", false) -- Reset Delay juga dihide dulu

        if instant then
            setElementVisible("Delay Catch", true)
        elseif superInstant then
            setElementVisible("Delay Fishing", true)
            setElementVisible("Reset Delay", true) -- Munculkan di mode Blatan
            delayCharge = 1.15 
        end
    end
})

local ChargeSlider = TabFishing:Slider({
    Title = "Delay Fishing", Desc = "Wait Fish (Blatan)", Step = 0.01,
    Value = { Min = 0, Max = 3, Default = 1.15 },
    Callback = function(value) delayCharge = value end
})

-- SLIDER BARU: Reset Delay
local ResetSlider = TabFishing:Slider({
    Title = "Reset Delay", 
    Desc = "After Catch Delay (Blatan)", 
    Step = 0.01,
    Value = { Min = 0, Max = 1, Default = 0.2 }, -- Default 0.2 sesuai request
    Callback = function(value) 
        delayReset = value 
    end
})

local CatchSlider = TabFishing:Slider({
    Title = "Delay Catch", Desc = "Instant Speed", Step = 0.01,
    Value = { Min = 0.1, Max = 3, Default = 0.56 },
    Callback = function(value) delayTime = value end
})

local Toggle = TabFishing:Toggle({
    Title = "Activate Fishing", Desc = "Start/Stop Loop", Icon = "check", Value = false,
    Callback = function(state)
        getgenv().fishingStart = state 
        if state then
            pcall(function() CancelInput:InvokeServer() end)
            if superInstant then task.spawn(startFishingSuperInstantLoop)
            else task.spawn(startFishingLoop) end
            WindUI:Notify({Title = "Fishing", Content = "Started!", Duration = 2})
        else
            pcall(function() CompleteGame:FireServer() end)
            pcall(function() CancelInput:InvokeServer() end)
            WindUI:Notify({Title = "Fishing", Content = "Stopped", Duration = 2})
        end
    end
})

-- [[ TAB 2: AUTO SELL ]]
TabSell:Toggle({
    Title = "Auto Sell (Time)", Desc = "Pauses fishing to sell", Icon = "timer", Value = false,
    Callback = function(state)
        SettingsState.AutoSell.TimeActive = state
        if state then
            StartAutoSellLoop() 
            WindUI:Notify({Title = "Auto Sell", Content = "Loop Started", Duration = 2})
        else
            SettingsState.AutoSell.IsSelling = false 
            WindUI:Notify({Title = "Auto Sell", Content = "Loop Stopped", Duration = 2})
        end
    end
})

TabSell:Slider({
    Title = "Sell Interval (Seconds)", Desc = "Time between sells", Step = 1,
    Value = { Min = 10, Max = 300, Default = 60 }, 
    Callback = function(value) SettingsState.AutoSell.TimeInterval = value end
})

TabSell:Button({ Title = "Sell Now", Desc = "Sell All Items Immediately", Icon = "trash-2", Callback = function()
    task.spawn(function()
        SettingsState.AutoSell.IsSelling = true -- Pause Fishing
        task.wait(0.2)
        pcall(function() SellAll:InvokeServer() end)
        WindUI:Notify({Title = "Sell All", Content = "Sold!", Duration = 2})
        task.wait(0.5)
        SettingsState.AutoSell.IsSelling = false -- Resume Fishing
    end)
end })

-- [[ TAB 3: SETTINGS ]]
TabSettings:Button({ Title = "Anti-AFK", Desc = "Status: Active (Always On)", Icon = "clock", Callback = function() WindUI:Notify({ Title = "Anti-AFK", Content = "Permanently Active", Duration = 2 }) end })

TabSettings:Button({ Title = "Destroy Fish Popup", Desc = "Permanently removes 'Small Notification' UI", Icon = "trash-2", Callback = function()
    if SettingsState.PopupDestroyed then WindUI:Notify({Title = "UI", Content = "Already Destroyed!", Duration = 2}) return end
    SettingsState.PopupDestroyed = true
    ExecuteDestroyPopup()
    WindUI:Notify({Title = "UI", Content = "Popup Destroyed!", Duration = 3})
end })

TabSettings:Toggle({ Title = "FPS Boost (Potato)", Desc = "Low Graphics", Icon = "monitor", Value = false, Callback = function(state) ToggleFPSBoost(state) end })

TabSettings:Button({ Title = "Remove VFX (Permanent)", Desc = "Delete Effects", Icon = "trash-2", Callback = function()
    if SettingsState.VFXRemoved then WindUI:Notify({Title = "VFX", Content = "Already Removed!", Duration = 2}) return end
    SettingsState.VFXRemoved = true
    ExecuteRemoveVFX()
    WindUI:Notify({Title = "VFX", Content = "Deleted!", Duration = 2})
end })

-- -- =====================================================
-- -- 📱 7. MOBILE TOGGLE BUTTON (DRAGGABLE)
-- -- =====================================================
-- local Vim = game:GetService("VirtualInputManager")
-- local MobileScreen = Instance.new("ScreenGui")
-- MobileScreen.Name = "MobileToggleUI"
-- MobileScreen.Parent = CoreGui

-- local MobileBtn = Instance.new("TextButton")
-- MobileBtn.Name = "ToggleBtn"
-- MobileBtn.Parent = MobileScreen
-- MobileBtn.BackgroundColor3 = Color3.fromHex("#30ff6a")
-- MobileBtn.Position = UDim2.new(0.8, 0, 0.2, 0)
-- MobileBtn.Size = UDim2.new(0, 50, 0, 50)
-- MobileBtn.Text = "U"
-- MobileBtn.TextColor3 = Color3.new(0, 0, 0)
-- MobileBtn.TextSize = 20
-- MobileBtn.Font = Enum.Font.GothamBold
-- MobileBtn.AutoButtonColor = true

-- local UICorner = Instance.new("UICorner")
-- UICorner.CornerRadius = UDim.new(1, 0)
-- UICorner.Parent = MobileBtn

-- local UIStroke = Instance.new("UIStroke")
-- UIStroke.Thickness = 2
-- UIStroke.Color = Color3.new(0, 0, 0)
-- UIStroke.Parent = MobileBtn

-- -- [[ DRAGGABLE LOGIC ]] --
-- local function MakeDraggable(gui)
--     local UserInputService = game:GetService("UserInputService")
--     local dragging, dragInput, dragStart, startPos

--     local function update(input)
--         local delta = input.Position - dragStart
--         gui.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
--     end

--     gui.InputBegan:Connect(function(input)
--         if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
--             dragging = true
--             dragStart = input.Position
--             startPos = gui.Position
            
--             input.Changed:Connect(function()
--                 if input.UserInputState == Enum.UserInputState.End then
--                     dragging = false
--                 end
--             end)
--         end
--     end)

--     gui.InputChanged:Connect(function(input)
--         if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
--             dragInput = input
--         end
--     end)

--     UserInputService.InputChanged:Connect(function(input)
--         if input == dragInput and dragging then
--             update(input)
--         end
--     end)
-- end

-- MakeDraggable(MobileBtn) -- Aktifkan fitur geser

-- MobileBtn.MouseButton1Click:Connect(function()
--     Vim:SendKeyEvent(true, Enum.KeyCode.H, false, game)
--     task.wait()
--     Vim:SendKeyEvent(false, Enum.KeyCode.H, false, game)
-- end)

-- Init
task.delay(1, function()
    setElementVisible("Delay Fishing", false)
    setElementVisible("Delay Catch", false)
    setElementVisible("Reset Delay", false) -- Hide default

    if instant then
        setElementVisible("Delay Catch", true)
    elseif superInstant then
        setElementVisible("Delay Fishing", true)
        setElementVisible("Reset Delay", true) -- Show in Blatan
    end
end)

task.spawn(StartAntiAFK)
print("✅ Script Loaded!")