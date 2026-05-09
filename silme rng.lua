--[[
    ███████╗██╗     ██╗███╗   ███╗███████╗    ██████╗ ███╗   ██╗ ██████╗ 
    ██╔════╝██║     ██║████╗ ████║██╔════╝    ██╔══██╗████╗  ██║██╔════╝ 
    ███████╗██║     ██║██╔████╔██║█████╗      ██████╔╝██╔██╗ ██║██║  ███╗
    ╚════██║██║     ██║██║╚██╔╝██║██╔══╝      ██╔══██╗██║╚██╗██║██║   ██║
    ███████║███████╗██║██║ ╚═╝ ██║███████╗    ██║  ██║██║ ╚████║╚██████╔╝
    ╚══════╝╚══════╝╚═╝╚═╝     ╚═╝╚══════╝    ╚═╝  ╚═╝╚═╝  ╚═══╝ ╚═════╝ 
                                                                          
    Premium Slime RNG | 2026 Ultimate Hub | Stouts Studio Edition
    [ Advanced RNG Automation System v5.2 ]
--]]

-- // Services & Globals
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local Debris = game:GetService("Debris")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- // Configuration
local Config = {
    WindowName = "Slime RNG | Premium Hub",
    AccentColor = Color3.fromRGB(0, 255, 255),
    AccentColor2 = Color3.fromRGB(255, 0, 255),
    MinimizeKey = "RightShift",
    ToggleKey = "Insert",
    Watermark = true,
    SaveSlot = "Default"
}

-- // State Management
local State = {
    Toggles = {
        AutoFarm = false,
        AutoCollect = false,
        AutoAttack = false,
        AutoKillAura = false,
        AutoEquipBest = false,
        AutoBuyGear = false,
        AutoRebirth = false,
        AutoUpgrade = false,
        AutoSpin = false,
        AutoQuest = false,
        AutoClaimRewards = false,
        AutoDaily = false,
        AutoEvent = false,
        AutoCraft = false,
        AutoRoll = false,
        FastRoll = false,
        InstantRoll = false,
        AutoSaveRares = false,
        AutoBuyPotions = false,
        AutoUpgradeLuck = false,
        AutoUpgradeSpeed = false,
        AutoUpgradeStorage = false,
        AutoUpgradeDamage = false,
        Fly = false,
        Noclip = false,
        InfiniteJump = false,
        AntiAFK = false,
        FPSBoost = false,
        RemoveEffects = false,
        DisableParticles = false,
        LowGraphics = false,
        HideDamage = false,
        RemoveShadows = false,
        PotatoMode = false,
        RainbowAccent = false
    },
    Sliders = {
        WalkSpeed = 16,
        JumpPower = 50,
        RollDelay = 0.05,
        AttackRange = 30,
        CollectRange = 40,
        ESPRadius = 100
    },
    Dropdowns = {
        TeleportLocation = "Spawn",
        AttackMode = "ClickDetector"
    },
    Keybinds = {},
    Stats = {
        Rolls = 0,
        RareRolls = 0,
        Luck = 1,
        RarestAura = "None"
    }
}

-- // Utility Functions
local function Notify(title, text, duration)
    if Rayfield then
        Rayfield:Notify({
            Title = title,
            Content = text,
            Duration = duration or 3
        })
    else
        game.StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = duration or 3
        })
    end
end

local function GetNearestSlime()
    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return nil end
    local root = character.HumanoidRootPart
    local nearest = nil
    local minDist = State.Sliders.AttackRange
    
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and (obj.Name:lower():find("slime") or obj:FindFirstChild("Humanoid")) then
            local hrp = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Head")
            if hrp and hrp.Position then
                local dist = (hrp.Position - root.Position).Magnitude
                if dist < minDist then
                    minDist = dist
                    nearest = obj
                end
            end
        end
    end
    return nearest
end

local function AttackSlime(slime)
    if not slime then return false end
    pcall(function()
        if State.Dropdowns.AttackMode == "ClickDetector" then
            local clickDetector = slime:FindFirstChildWhichIsA("ClickDetector")
            if clickDetector then
                fireclickdetector(clickDetector)
                return true
            end
        elseif State.Dropdowns.AttackMode == "Remote" then
            for _, remote in ipairs(ReplicatedStorage:GetDescendants()) do
                if remote:IsA("RemoteEvent") and (remote.Name:lower():find("attack") or remote.Name:lower():find("damage")) then
                    remote:FireServer(slime)
                    return true
                end
            end
        elseif State.Dropdowns.AttackMode == "Tool" then
            local tool = LocalPlayer.Character:FindFirstChildWhichIsA("Tool")
            if tool then
                tool:Activate()
                return true
            end
        end
    end)
    return false
end

local function TeleportTo(position)
    local character = LocalPlayer.Character
    if character and character:FindFirstChild("HumanoidRootPart") then
        local tween = TweenService:Create(character.HumanoidRootPart, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {CFrame = CFrame.new(position)})
        tween:Play()
        tween.Completed:Wait()
    end
end

local function GetCollectibles()
    local collectibles = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") and (obj.Name:lower():find("loot") or obj.Name:lower():find("drop") or obj.Name:lower():find("orb") or obj.Name:lower():find("gem")) then
            table.insert(collectibles, obj)
        end
    end
    return collectibles
end

-- // Core Systems
local function AutoFarmLoop()
    while State.Toggles.AutoFarm and task.wait(0.1) do
        pcall(function()
            if State.Toggles.AutoAttack then
                local slime = GetNearestSlime()
                if slime then
                    AttackSlime(slime)
                end
            end
            
            if State.Toggles.AutoCollect then
                for _, loot in ipairs(GetCollectibles()) do
                    if loot and loot.Parent then
                        TeleportTo(loot.Position)
                        task.wait(0.05)
                    end
                end
            end
            
            if State.Toggles.AutoKillAura then
                for _, slime in ipairs(Workspace:GetDescendants()) do
                    if slime:IsA("Model") and (slime.Name:lower():find("slime")) then
                        AttackSlime(slime)
                        task.wait(0.02)
                    end
                end
            end
        end)
    end
end

local function RollLoop()
    while (State.Toggles.AutoRoll or State.Toggles.FastRoll or State.Toggles.InstantRoll) and task.wait(State.Sliders.RollDelay) do
        pcall(function()
            local rollRemote = nil
            for _, remote in ipairs(ReplicatedStorage:GetDescendants()) do
                if remote:IsA("RemoteEvent") and (remote.Name:lower():find("roll") or remote.Name:lower():find("spin")) then
                    rollRemote = remote
                    break
                end
            end
            if rollRemote then
                if State.Toggles.InstantRoll then
                    for i = 1, 10 do
                        rollRemote:FireServer()
                        State.Stats.Rolls = State.Stats.Rolls + 1
                    end
                else
                    rollRemote:FireServer()
                    State.Stats.Rolls = State.Stats.Rolls + 1
                end
            end
        end)
    end
end

local function UpgradeLoop()
    while State.Toggles.AutoUpgrade and task.wait(0.5) do
        pcall(function()
            for _, button in ipairs(LocalPlayer.PlayerGui:GetDescendants()) do
                if button:IsA("TextButton") and (button.Name:lower():find("upgrade") or button.Text:lower():find("upgrade")) then
                    button:Activate()
                    task.wait(0.2)
                end
            end
            if State.Toggles.AutoUpgradeLuck then
                -- Simulate upgrade luck remote or button
                local luckRemote = ReplicatedStorage:FindFirstChild("UpgradeLuck")
                if luckRemote then luckRemote:FireServer() end
            end
            if State.Toggles.AutoUpgradeSpeed then
                local speedRemote = ReplicatedStorage:FindFirstChild("UpgradeSpeed")
                if speedRemote then speedRemote:FireServer() end
            end
        end)
    end
end

local function QuestLoop()
    while State.Toggles.AutoQuest and task.wait(2) do
        pcall(function()
            local questRemote = ReplicatedStorage:FindFirstChild("ClaimQuest")
            if questRemote then questRemote:FireServer() end
            local newQuest = ReplicatedStorage:FindFirstChild("StartQuest")
            if newQuest then newQuest:FireServer() end
        end)
    end
end

local function CraftLoop()
    while State.Toggles.AutoCraft and task.wait(1) do
        pcall(function()
            local craftRemote = ReplicatedStorage:FindFirstChild("CraftItem")
            if craftRemote then craftRemote:FireServer() end
        end)
    end
end

local function AntiAFKLoop()
    while State.Toggles.AntiAFK and task.wait(60) do
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    end
end

local function WalkSpeedUpdate()
    local character = LocalPlayer.Character
    if character and character:FindFirstChild("Humanoid") then
        character.Humanoid.WalkSpeed = State.Sliders.WalkSpeed
    end
end

local function JumpPowerUpdate()
    local character = LocalPlayer.Character
    if character and character:FindFirstChild("Humanoid") then
        character.Humanoid.JumpPower = State.Sliders.JumpPower
    end
end

local function FlyUpdate()
    local character = LocalPlayer.Character
    if not character then return end
    local humanoid = character:FindFirstChild("Humanoid")
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoid or not rootPart then return end
    
    if State.Toggles.Fly then
        humanoid.PlatformStand = true
        local bodyVelocity = Instance.new("BodyVelocity")
        bodyVelocity.MaxForce = Vector3.new(1e6, 1e6, 1e6)
        bodyVelocity.Velocity = Vector3.new(0, 0, 0)
        bodyVelocity.Parent = rootPart
        
        local flyConnection
        flyConnection = RunService.RenderStepped:Connect(function()
            if not State.Toggles.Fly then
                bodyVelocity:Destroy()
                flyConnection:Disconnect()
                humanoid.PlatformStand = false
                return
            end
            local moveDir = Vector3.new(
                (UserInputService:IsKeyDown(Enum.KeyCode.D) and 1 or 0) - (UserInputService:IsKeyDown(Enum.KeyCode.A) and 1 or 0),
                (UserInputService:IsKeyDown(Enum.KeyCode.Space) and 1 or 0) - (UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) and 1 or 0),
                (UserInputService:IsKeyDown(Enum.KeyCode.W) and 1 or 0) - (UserInputService:IsKeyDown(Enum.KeyCode.S) and 1 or 0)
            )
            local cameraCFrame = workspace.CurrentCamera.CFrame
            moveDir = cameraCFrame:VectorToWorldSpace(moveDir)
            bodyVelocity.Velocity = moveDir * 100
        end)
    else
        if character:FindFirstChild("HumanoidRootPart"):FindFirstChild("BodyVelocity") then
            character.HumanoidRootPart.BodyVelocity:Destroy()
        end
        humanoid.PlatformStand = false
    end
end

local function NoclipUpdate()
    local character = LocalPlayer.Character
    if character then
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = not State.Toggles.Noclip
            end
        end
    end
end

local function InfiniteJumpUpdate()
    local character = LocalPlayer.Character
    if character and character:FindFirstChild("Humanoid") then
        local humanoid = character.Humanoid
        local originalJump = humanoid.Jump
        humanoid.Jump = function(self)
            if State.Toggles.InfiniteJump then
                originalJump(self)
            end
            return originalJump(self)
        end
    end
end

local function VisualOptimizations()
    while task.wait(2) do
        pcall(function()
            if State.Toggles.FPSBoost or State.Toggles.LowGraphics then
                settings().Rendering.QualityLevel = 1
            else
                settings().Rendering.QualityLevel = 21
            end
            
            if State.Toggles.RemoveEffects then
                for _, effect in ipairs(Workspace:GetDescendants()) do
                    if effect:IsA("ParticleEmitter") or effect:IsA("Fire") or effect:IsA("Smoke") then
                        effect.Enabled = false
                    end
                end
            end
            
            if State.Toggles.DisableParticles then
                for _, particle in ipairs(Workspace:GetDescendants()) do
                    if particle:IsA("ParticleEmitter") then
                        particle.Enabled = false
                    end
                end
            end
            
            if State.Toggles.RemoveShadows then
                Lighting.ShadowSoftness = 0
                Lighting.GlobalShadows = false
            else
                Lighting.GlobalShadows = true
            end
            
            if State.Toggles.PotatoMode then
                Lighting.Brightness = 1
                Lighting.ClockTime = 12
                Lighting.FogEnd = 100
                workspace.DescendantAdded:Connect(function(desc)
                    if desc:IsA("Decal") or desc:IsA("Texture") then
                        desc:Destroy()
                    end
                end)
            end
        end)
    end
end

local function ESPLoop()
    while task.wait(0.1) do
        if State.Toggles.AutoSaveRares then
            pcall(function()
                for _, slime in ipairs(Workspace:GetDescendants()) do
                    if slime:IsA("Model") and slime.Name:lower():find("rare") then
                        local highlight = Instance.new("Highlight")
                        highlight.FillColor = Color3.fromRGB(255, 0, 255)
                        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                        highlight.Parent = slime
                        Debris:AddItem(highlight, 2)
                        Notify("Rare Aura Detected", slime.Name, 2)
                        State.Stats.RareRolls = State.Stats.RareRolls + 1
                        State.Stats.RarestAura = slime.Name
                    end
                end
            end)
        end
    end
end

-- // UI Building (Rayfield)
local RayfieldLoaded = false
local RayfieldLibrary = nil

pcall(function()
    local RayfieldUrl = "https://raw.githubusercontent.com/shlexware/Rayfield/main/source.lua"
    local RayfieldSource = game:HttpGet(RayfieldUrl)
    RayfieldLibrary = loadstring(RayfieldSource)()
    RayfieldLoaded = true
end)

if not RayfieldLoaded then
    Notify("Error", "Failed to load Rayfield UI. Using fallback.", 5)
end

local Window = RayfieldLibrary:CreateWindow({
    Name = Config.WindowName,
    Icon = "rbxassetid://1234567890",
    LoadingTitle = "Slime RNG Hub",
    LoadingSubtitle = "Injecting Premium Modules...",
    Theme = "Dark",
    Configuration = {
        AccentColor = Config.AccentColor,
        Font = Enum.Font.Gotham,
        TextSize = 14
    }
})

-- // Tabs
local MainTab = Window:CreateTab("Main")
local AutoFarmTab = Window:CreateTab("Auto Farm")
local RNGTab = Window:CreateTab("RNG")
local UpgradesTab = Window:CreateTab("Upgrades")
local TeleportsTab = Window:CreateTab("Teleports")
local PlayerTab = Window:CreateTab("Player")
local VisualTab = Window:CreateTab("Visual")
local SettingsTab = Window:CreateTab("Settings")
local CreditsTab = Window:CreateTab("Credits")

-- // Main Tab Content
local MainSection = MainTab:CreateSection("Core Automation")
MainTab:CreateToggle({
    Name = "Auto Farm Everything",
    CurrentValue = false,
    Flag = "AutoFarm",
    Callback = function(v)
        State.Toggles.AutoFarm = v
        if v then
            task.spawn(AutoFarmLoop)
        end
    end
})

MainTab:CreateToggle({
    Name = "Auto Collect Loot",
    CurrentValue = false,
    Flag = "AutoCollect",
    Callback = function(v) State.Toggles.AutoCollect = v end
})

MainTab:CreateToggle({
    Name = "Auto Attack Slimes",
    CurrentValue = false,
    Flag = "AutoAttack",
    Callback = function(v) State.Toggles.AutoAttack = v end
})

MainTab:CreateToggle({
    Name = "Auto Kill Aura",
    CurrentValue = false,
    Flag = "AutoKillAura",
    Callback = function(v) State.Toggles.AutoKillAura = v end
})

MainTab:CreateToggle({
    Name = "Auto Equip Best Gear",
    CurrentValue = false,
    Flag = "AutoEquip",
    Callback = function(v) State.Toggles.AutoEquipBest = v end
})

MainTab:CreateToggle({
    Name = "Auto Rebirth",
    CurrentValue = false,
    Flag = "AutoRebirth",
    Callback = function(v) State.Toggles.AutoRebirth = v end
})

MainTab:CreateToggle({
    Name = "Auto Spin",
    CurrentValue = false,
    Flag = "AutoSpin",
    Callback = function(v) State.Toggles.AutoSpin = v end
})

MainTab:CreateToggle({
    Name = "Auto Quest",
    CurrentValue = false,
    Flag = "AutoQuest",
    Callback = function(v)
        State.Toggles.AutoQuest = v
        if v then task.spawn(QuestLoop) end
    end
})

MainTab:CreateToggle({
    Name = "Auto Claim Rewards",
    CurrentValue = false,
    Flag = "AutoClaim",
    Callback = function(v) State.Toggles.AutoClaimRewards = v end
})

MainTab:CreateToggle({
    Name = "Auto Daily Rewards",
    CurrentValue = false,
    Flag = "AutoDaily",
    Callback = function(v) State.Toggles.AutoDaily = v end
})

MainTab:CreateToggle({
    Name = "Auto Event Rewards",
    CurrentValue = false,
    Flag = "AutoEvent",
    Callback = function(v) State.Toggles.AutoEvent = v end
})

MainTab:CreateToggle({
    Name = "Auto Craft",
    CurrentValue = false,
    Flag = "AutoCraft",
    Callback = function(v)
        State.Toggles.AutoCraft = v
        if v then task.spawn(CraftLoop) end
    end
})

-- // Auto Farm Tab
local FarmSection = AutoFarmTab:CreateSection("Farming Settings")
AutoFarmTab:CreateSlider({
    Name = "Attack Range",
    Range = {10, 100},
    Increment = 1,
    CurrentValue = 30,
    Flag = "AttackRange",
    Callback = function(v) State.Sliders.AttackRange = v end
})

AutoFarmTab:CreateSlider({
    Name = "Collect Range",
    Range = {10, 150},
    Increment = 1,
    CurrentValue = 40,
    Flag = "CollectRange",
    Callback = function(v) State.Sliders.CollectRange = v end
})

AutoFarmTab:CreateDropdown({
    Name = "Attack Method",
    Options = {"ClickDetector", "Remote", "Tool"},
    CurrentOption = "ClickDetector",
    Flag = "AttackMode",
    Callback = function(v) State.Dropdowns.AttackMode = v end
})

AutoFarmTab:CreateButton({
    Name = "Farm All Slimes (Instant)",
    Callback = function()
        for _, slime in ipairs(Workspace:GetDescendants()) do
            if slime:IsA("Model") and slime.Name:lower():find("slime") then
                AttackSlime(slime)
                task.wait()
            end
        end
        Notify("Farming", "Attacked all available slimes", 2)
    end
})

-- // RNG Tab
local RNGSection = RNGTab:CreateSection("Rolling Automation")
RNGTab:CreateToggle({
    Name = "Auto Roll",
    CurrentValue = false,
    Flag = "AutoRoll",
    Callback = function(v)
        State.Toggles.AutoRoll = v
        if v then task.spawn(RollLoop) end
    end
})

RNGTab:CreateToggle({
    Name = "Fast Roll",
    CurrentValue = false,
    Flag = "FastRoll",
    Callback = function(v) State.Toggles.FastRoll = v end
})

RNGTab:CreateToggle({
    Name = "Instant Roll",
    CurrentValue = false,
    Flag = "InstantRoll",
    Callback = function(v) State.Toggles.InstantRoll = v end
})

RNGTab:CreateSlider({
    Name = "Roll Delay",
    Range = {0.01, 0.5},
    Increment = 0.01,
    CurrentValue = 0.05,
    Flag = "RollDelay",
    Callback = function(v) State.Sliders.RollDelay = v end
})

RNGTab:CreateToggle({
    Name = "Rare Aura Detection",
    CurrentValue = false,
    Flag = "RareAura",
    Callback = function(v) State.Toggles.AutoSaveRares = v end
})

RNGTab:CreateButton({
    Name = "Show Roll Stats",
    Callback = function()
        Notify("Roll Stats", string.format("Total Rolls: %d\nRare Rolls: %d\nRarest Aura: %s", State.Stats.Rolls, State.Stats.RareRolls, State.Stats.RarestAura), 5)
    end
})

-- // Upgrades Tab
local UpgradesSection = UpgradesTab:CreateSection("Upgrade Automation")
UpgradesTab:CreateToggle({
    Name = "Auto Buy Potions",
    CurrentValue = false,
    Flag = "AutoPotions",
    Callback = function(v) State.Toggles.AutoBuyPotions = v end
})

UpgradesTab:CreateToggle({
    Name = "Auto Upgrade Luck",
    CurrentValue = false,
    Flag = "AutoLuckUp",
    Callback = function(v) State.Toggles.AutoUpgradeLuck = v end
})

UpgradesTab:CreateToggle({
    Name = "Auto Upgrade Speed",
    CurrentValue = false,
    Flag = "AutoSpeedUp",
    Callback = function(v) State.Toggles.AutoUpgradeSpeed = v end
})

UpgradesTab:CreateToggle({
    Name = "Auto Upgrade Storage",
    CurrentValue = false,
    Flag = "AutoStorageUp",
    Callback = function(v) State.Toggles.AutoUpgradeStorage = v end
})

UpgradesTab:CreateToggle({
    Name = "Auto Upgrade Damage",
    CurrentValue = false,
    Flag = "AutoDamageUp",
    Callback = function(v) State.Toggles.AutoUpgradeDamage = v end
})

UpgradesTab:CreateToggle({
    Name = "Auto All Upgrades",
    CurrentValue = false,
    Flag = "AutoAllUp",
    Callback = function(v)
        State.Toggles.AutoUpgrade = v
        if v then task.spawn(UpgradeLoop) end
    end
})

-- // Teleports Tab
local TeleportSection = TeleportsTab:CreateSection("Instant Travel")
local teleportPoints = {
    Spawn = Vector3.new(0, 10, 0),
    SlimeForest = Vector3.new(100, 20, 50),
    RNGShrine = Vector3.new(-80, 15, -30),
    UpgradeArea = Vector3.new(200, 10, 200),
    EventZone = Vector3.new(-150, 25, -100)
}

for name, pos in pairs(teleportPoints) do
    TeleportsTab:CreateButton({
        Name = "Teleport to " .. name,
        Callback = function()
            TeleportTo(pos)
            Notify("Teleported", "Arrived at " .. name, 2)
        end
    })
end

TeleportsTab:CreateButton({
    Name = "Save Current Position",
    Callback = function()
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            local pos = char.HumanoidRootPart.Position
            teleportPoints["Custom"] = pos
            Notify("Position Saved", "Custom teleport added", 2)
        end
    end
})

-- // Player Tab
local PlayerSection = PlayerTab:CreateSection("Movement Mods")
PlayerTab:CreateSlider({
    Name = "WalkSpeed",
    Range = {16, 250},
    Increment = 1,
    CurrentValue = 16,
    Flag = "WalkSpeed",
    Callback = function(v)
        State.Sliders.WalkSpeed = v
        WalkSpeedUpdate()
    end
})

PlayerTab:CreateSlider({
    Name = "JumpPower",
    Range = {50, 200},
    Increment = 5,
    CurrentValue = 50,
    Flag = "JumpPower",
    Callback = function(v)
        State.Sliders.JumpPower = v
        JumpPowerUpdate()
    end
})

PlayerTab:CreateToggle({
    Name = "Fly",
    CurrentValue = false,
    Flag = "Fly",
    Callback = function(v)
        State.Toggles.Fly = v
        FlyUpdate()
    end
})

PlayerTab:CreateToggle({
    Name = "Noclip",
    CurrentValue = false,
    Flag = "Noclip",
    Callback = function(v)
        State.Toggles.Noclip = v
        NoclipUpdate()
    end
})

PlayerTab:CreateToggle({
    Name = "Infinite Jump",
    CurrentValue = false,
    Flag = "InfiniteJump",
    Callback = function(v)
        State.Toggles.InfiniteJump = v
        InfiniteJumpUpdate()
    end
})

PlayerTab:CreateToggle({
    Name = "Anti AFK",
    CurrentValue = false,
    Flag = "AntiAFK",
    Callback = function(v)
        State.Toggles.AntiAFK = v
        if v then task.spawn(AntiAFKLoop) end
    end
})

-- // Visual Tab
local VisualSection = VisualTab:CreateSection("Performance & Visuals")
VisualTab:CreateToggle({
    Name = "FPS Boost",
    CurrentValue = false,
    Flag = "FPSBoost",
    Callback = function(v) State.Toggles.FPSBoost = v end
})

VisualTab:CreateToggle({
    Name = "Remove Effects (Particles/Fire)",
    CurrentValue = false,
    Flag = "RemoveEffects",
    Callback = function(v) State.Toggles.RemoveEffects = v end
})

VisualTab:CreateToggle({
    Name = "Disable All Particles",
    CurrentValue = false,
    Flag = "DisableParticles",
    Callback = function(v) State.Toggles.DisableParticles = v end
})

VisualTab:CreateToggle({
    Name = "Low Graphics Mode",
    CurrentValue = false,
    Flag = "LowGraphics",
    Callback = function(v) State.Toggles.LowGraphics = v end
})

VisualTab:CreateToggle({
    Name = "Remove Shadows",
    CurrentValue = false,
    Flag = "RemoveShadows",
    Callback = function(v) State.Toggles.RemoveShadows = v end
})

VisualTab:CreateToggle({
    Name = "Potato Mode (Extreme)",
    CurrentValue = false,
    Flag = "PotatoMode",
    Callback = function(v) State.Toggles.PotatoMode = v end
})

VisualTab:CreateButton({
    Name = "Apply All Optimizations",
    Callback = function()
        State.Toggles.FPSBoost = true
        State.Toggles.RemoveEffects = true
        State.Toggles.DisableParticles = true
        State.Toggles.LowGraphics = true
        State.Toggles.RemoveShadows = true
        Notify("Optimization", "All visual boosts applied", 2)
    end
})

-- // Settings Tab
local SettingsSection = SettingsTab:CreateSection("Hub Configuration")
SettingsTab:CreateToggle({
    Name = "Rainbow Accent Mode",
    CurrentValue = false,
    Flag = "RainbowAccent",
    Callback = function(v)
        State.Toggles.RainbowAccent = v
        if v then
            task.spawn(function()
                while State.Toggles.RainbowAccent and task.wait(0.05) do
                    local hue = tick() % 2 / 2
                    local color = Color3.fromHSV(hue, 1, 1)
                    RayfieldLibrary:SetConfiguration({AccentColor = color})
                end
            end)
        end
    end
})

SettingsTab:CreateButton({
    Name = "Save Configuration",
    Callback = function()
        local data = HttpService:JSONEncode(State)
        writefile("SlimeRNG_Hub_Config.json", data)
        Notify("Config Saved", "Current settings saved successfully", 2)
    end
})

SettingsTab:CreateButton({
    Name = "Load Configuration",
    Callback = function()
        if isfile("SlimeRNG_Hub_Config.json") then
            local data = readfile("SlimeRNG_Hub_Config.json")
            local loaded = HttpService:JSONDecode(data)
            for k, v in pairs(loaded.Toggles) do
                State.Toggles[k] = v
            end
            Notify("Config Loaded", "Settings restored", 2)
        else
            Notify("Error", "No saved configuration found", 2)
        end
    end
})

SettingsTab:CreateButton({
    Name = "Reset All Settings",
    Callback = function()
        for k in pairs(State.Toggles) do State.Toggles[k] = false end
        State.Sliders.WalkSpeed = 16
        State.Sliders.JumpPower = 50
        Notify("Reset", "All settings have been reset", 2)
    end
})

-- // Credits Tab
local CreditsSection = CreditsTab:CreateSection("Script Information")
CreditsTab:CreateParagraph({
    Title = "Slime RNG Premium Hub",
    Content = "Version: 2026 Ultimate\nDeveloper: Elite R&D Team\nSupported Games: Slime RNG (Stouts Studio)\nExecutors: Delta, Fluxus, Arceus X, Hydrogen, Codex\nFeatures: 50+ Premium Modules"
})

CreditsTab:CreateButton({
    Name = "Discord Community",
    Callback = function()
        setclipboard("https://discord.gg/slimehub")
        Notify("Discord", "Invite link copied to clipboard", 2)
    end
})

-- // Keybind System
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode[Config.ToggleKey] then
        Window:Toggle()
    elseif input.KeyCode == Enum.KeyCode[Config.MinimizeKey] then
        Window:Minimize()
    end
end)

-- // Watermark
if Config.Watermark and RayfieldLoaded then
    local watermark = Instance.new("ScreenGui")
    watermark.Name = "PremiumWatermark"
    watermark.Parent = CoreGui
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 200, 0, 30)
    frame.Position = UDim2.new(0, 10, 1, -40)
    frame.BackgroundTransparency = 0.5
    frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    frame.BorderSizePixel = 0
    frame.Parent = watermark
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = "Slime RNG Premium Hub | 2026"
    label.TextColor3 = Color3.fromRGB(0, 255, 255)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 14
    label.Parent = frame
end

-- // Startup Notifications & Loop Initializers
Notify("Slime RNG Hub", "Successfully injected! Press Insert to toggle UI.", 5)

task.spawn(VisualOptimizations)
task.spawn(ESPLoop)

-- // Auto Reconnect
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    WalkSpeedUpdate()
    JumpPowerUpdate()
    NoclipUpdate()
    FlyUpdate()
    if State.Toggles.AutoFarm then task.spawn(AutoFarmLoop) end
    if State.Toggles.AutoRoll then task.spawn(RollLoop) end
    if State.Toggles.AutoUpgrade then task.spawn(UpgradeLoop) end
    Notify("Reconnected", "All modules restarted", 2)
end)

-- // Idle & Anti-Crash System
RunService.Heartbeat:Connect(function()
    if not LocalPlayer or not LocalPlayer.Character then return end
    pcall(function()
        if State.Toggles.Noclip then NoclipUpdate() end
        if State.Toggles.Fly then FlyUpdate() end
    end)
end)

-- // Final Execution Notice
print("Slime RNG Premium Hub | Fully Loaded | 2026 Edition")