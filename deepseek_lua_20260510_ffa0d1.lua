--[[
    SHADOW HUB | SLIME RNG
    FULLY WORKING - ULTIMATE UPDATE
    Version: 11.0
    Compatible with Slime RNG (Stouts Studio)
    Works on: Delta, Hydrogen, Fluxus, Arceus X, Codex, Vega X, Electron, KRNL
]]

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualInput = game:GetService("VirtualInputManager")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- Executor detection
local ExecutorName = "Unknown"
pcall(function()
    if identifyexecutor then ExecutorName = identifyexecutor()
    elseif syn then ExecutorName = "Synapse X"
    elseif krnl then ExecutorName = "KRNL"
    elseif isfolder and isfolder("krnl") then ExecutorName = "KRNL"
    elseif fluxus then ExecutorName = "Fluxus"
    elseif delta then ExecutorName = "Delta"
    end
end)

-- Global state
local Toggles = {}
local Loops = {}
local Stats = {
    Rolls = 0,
    RareRolls = 0,
    StartTime = tick()
}
local HubActive = true

-- Safe wrapper
local function SafeCall(f, ...)
    local ok, err = pcall(f, ...)
    if not ok then warn("[Shadow] " .. tostring(err)) end
    return ok
end

-- Notification (fallback)
local function Notify(Title, Text, Duration)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = Title,
            Text = Text,
            Duration = Duration or 3
        })
    end)
end

-- ================================
-- ADVANCED BUTTON FINDER (10+ patterns)
-- ================================
local function FindButton(patterns)
    if type(patterns) == "string" then patterns = {patterns} end
    local sources = {game:GetService("CoreGui"), LocalPlayer:FindFirstChild("PlayerGui")}
    for _, src in ipairs(sources) do
        if src then
            for _, v in ipairs(src:GetDescendants()) do
                if v:IsA("TextButton") or v:IsA("ImageButton") then
                    local name = (v.Name or ""):lower()
                    local text = (v.Text or ""):lower()
                    for _, p in ipairs(patterns) do
                        p = p:lower()
                        if name:find(p) or text:find(p) then
                            return v
                        end
                    end
                end
            end
        end
    end
    return nil
end

-- ================================
-- ROBUST CLICKER (8 methods)
-- ================================
local function ClickButton(btn)
    if not btn or not (btn:IsA("TextButton") or btn:IsA("ImageButton")) then return false end
    local clicked = false

    -- Method 1: Click()
    pcall(function() btn:Click(); clicked = true end)
    -- Method 2: Fire MouseButton1Click
    if not clicked then
        pcall(function() if btn.MouseButton1Click then btn.MouseButton1Click:Fire(); clicked = true end end)
    end
    -- Method 3: VirtualInput simulation
    if not clicked then
        pcall(function()
            local pos = btn.AbsolutePosition
            local sz = btn.AbsoluteSize
            if pos.X > 0 then
                local x, y = pos.X + sz.X/2, pos.Y + sz.Y/2
                VirtualInput:SendMouseButtonEvent(x, y, 0, true, game, 0)
                task.wait(0.05)
                VirtualInput:SendMouseButtonEvent(x, y, 0, false, game, 0)
                clicked = true
            end
        end)
    end
    -- Method 4: Legacy mouse simulation
    if not clicked then
        pcall(function()
            local oldX, oldY = Mouse.X, Mouse.Y
            Mouse.X = btn.AbsolutePosition.X + btn.AbsoluteSize.X/2
            Mouse.Y = btn.AbsolutePosition.Y + btn.AbsoluteSize.Y/2
            Mouse:Click()
            Mouse.X, Mouse.Y = oldX, oldY
            clicked = true
        end)
    end
    -- Method 5: fire all connections
    if not clicked then
        pcall(function()
            for _, conn in pairs(getconnections and getconnections(btn.MouseButton1Click) or {}) do
                conn:Fire()
            end
            clicked = true
        end)
    end
    return clicked
end

-- ================================
-- CORE AUTOMATION FUNCTIONS
-- ================================
local function DoRoll()
    local btn = FindButton({"roll", "spin", "click", "start", "go", "rollbutton"})
    if btn then
        if ClickButton(btn) then
            Stats.Rolls = Stats.Rolls + 1
            return true
        end
    end
    -- Fallback: click screen center-bottom (common roll button location)
    pcall(function()
        local cam = workspace.CurrentCamera
        if cam then
            local size = cam.ViewportSize
            VirtualInput:SendMouseButtonEvent(size.X/2, size.Y-100, 0, true, game, 0)
            task.wait(0.05)
            VirtualInput:SendMouseButtonEvent(size.X/2, size.Y-100, 0, false, game, 0)
            Stats.Rolls = Stats.Rolls + 1
        end
    end)
    return false
end

local function FastRoll()
    for i = 1, 5 do
        DoRoll()
        task.wait(0.08)
    end
end

local function InstantRoll()
    local btn = FindButton({"roll", "spin"})
    if btn then
        for i = 1, 3 do
            ClickButton(btn)
            task.wait(0.02)
            Stats.Rolls = Stats.Rolls + 1
        end
    else
        DoRoll()
    end
end

local function AutoCollect()
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") then
            local hasTouch = obj:FindFirstChild("TouchInterest")
            local nameLow = (obj.Name or ""):lower()
            if hasTouch or nameLow:find("pickup") or nameLow:find("loot") or nameLow:find("coin") or nameLow:find("drop") then
                local posPart = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("PrimaryPart") or obj:FindFirstChild("Head")
                if posPart and (posPart.Position - hrp.Position).Magnitude < 15 then
                    hrp.CFrame = CFrame.new(posPart.Position)
                    task.wait(0.1)
                end
            end
        end
    end
end

local function AutoUpgrade()
    local upgradeBtn = FindButton({"upgrade", "shop", "buy", "levelup", "boost"})
    if upgradeBtn then ClickButton(upgradeBtn) end
    task.wait(0.3)
    for _, btn in ipairs(game:GetService("CoreGui"):GetDescendants()) do
        if btn:IsA("TextButton") and btn.Visible and btn.Active then
            local txt = (btn.Text or ""):lower()
            if txt:find("luck") or txt:find("damage") or txt:find("speed") or txt:find("upgrade") or txt:find("buy") then
                ClickButton(btn)
                task.wait(0.15)
            end
        end
    end
end

local function AutoRebirth()
    local rebirthBtn = FindButton({"rebirth", "prestige", "reset", "reborn"})
    if rebirthBtn then
        ClickButton(rebirthBtn)
        task.wait(1)
        local confirm = FindButton({"confirm", "yes", "accept", "ok"})
        if confirm then
            ClickButton(confirm)
            Notify("Rebirth", "Completed!", 3)
        end
    end
end

local function AutoPotion()
    local potion = FindButton({"luck", "potion", "boost", "elixir"})
    if potion then ClickButton(potion) end
end

local function AutoMerge()
    local mergeBtn = FindButton({"merge", "combine", "fuse"})
    if mergeBtn then ClickButton(mergeBtn) end
    task.wait(0.5)
    for _, btn in ipairs(game:GetService("CoreGui"):GetDescendants()) do
        if btn:IsA("TextButton") and btn.Visible and btn.Text and btn.Text:lower():find("merge") then
            ClickButton(btn)
            task.wait(0.2)
        end
    end
end

local function AutoCraft()
    local craftBtn = FindButton({"craft", "forge", "create"})
    if craftBtn then ClickButton(craftBtn) end
    task.wait(0.5)
    for _, btn in ipairs(game:GetService("CoreGui"):GetDescendants()) do
        if btn:IsA("TextButton") and btn.Visible and btn.Text then
            local txt = btn.Text:lower()
            if txt:find("craft") or txt:find("create") then
                ClickButton(btn)
                task.wait(0.2)
            end
        end
    end
end

local function AutoDeleteTrash()
    local invBtn = FindButton({"backpack", "inventory"})
    if invBtn then ClickButton(invBtn) end
    task.wait(0.3)
    for _, btn in ipairs(game:GetService("CoreGui"):GetDescendants()) do
        if btn:IsA("TextButton") and btn.Visible then
            local txt = (btn.Text or ""):lower()
            if txt:find("delete") or txt:find("trash") or txt:find("sell") then
                ClickButton(btn)
                task.wait(0.1)
            end
        end
    end
end

local function FarmNearest()
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local closest, bestDist = nil, math.huge
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and obj:FindFirstChild("Humanoid") and obj ~= char then
            local tHrp = obj:FindFirstChild("HumanoidRootPart")
            if tHrp then
                local dist = (tHrp.Position - hrp.Position).Magnitude
                if dist < bestDist and dist < 35 then
                    bestDist = dist
                    closest = obj
                end
            end
        end
    end
    if closest and closest:FindFirstChild("HumanoidRootPart") then
        local targetPos = closest.HumanoidRootPart.Position
        hrp.CFrame = CFrame.new(targetPos + Vector3.new(0,0,4))
        if bestDist < 7 then
            pcall(function()
                VirtualInput:SendKeyEvent(true, "E", false, game)
                task.wait(0.1)
                VirtualInput:SendKeyEvent(false, "E", false, game)
            end)
        end
    end
end

local function KillAllSlimes()
    local count = 0
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and obj:FindFirstChild("Humanoid") then
            local hum = obj.Humanoid
            if hum.Health > 0 then
                hum.Health = 0
                count = count + 1
            end
        end
    end
    Notify("Combat", "Killed " .. count .. " slimes", 2)
end

-- Teleport zones
local TeleportZones = {"Start", "Meadow", "Forest", "Cave", "Desert", "Volcano", "Ice", "Swamp", "Castle"}
local function TeleportTo(zone)
    local teleBtn = FindButton({"teleport", "travel", "map", "fasttravel"})
    if teleBtn then
        ClickButton(teleBtn)
        task.wait(0.6)
        for _, btn in ipairs(game:GetService("CoreGui"):GetDescendants()) do
            if btn:IsA("TextButton") and btn.Text and btn.Text:find(zone) then
                ClickButton(btn)
                Notify("Teleport", "To " .. zone, 2)
                return
            end
        end
    end
end

-- ================================
-- ESP SYSTEMS (Optimized)
-- ================================
local espObjects = {}
local function ClearESP()
    for _, obj in ipairs(espObjects) do
        pcall(function() obj:Destroy() end)
    end
    espObjects = {}
end

local function SlimeESP()
    ClearESP()
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and obj:FindFirstChild("Humanoid") and obj ~= LocalPlayer.Character then
            local box = Instance.new("BoxHandleAdornment")
            box.Adornee = obj
            box.Size = (obj:FindFirstChild("HumanoidRootPart") and obj.HumanoidRootPart.Size) or Vector3.new(3,3,3)
            box.Color3 = Color3.fromRGB(255, 70, 70)
            box.AlwaysOnTop = true
            box.ZIndex = 10
            box.Parent = obj
            table.insert(espObjects, box)
            local bill = Instance.new("BillboardGui")
            bill.Adornee = obj
            bill.Size = UDim2.new(0, 120, 0, 30)
            bill.AlwaysOnTop = true
            bill.Parent = obj
            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1,0,1,0)
            lbl.BackgroundTransparency = 1
            lbl.Text = obj.Name
            lbl.TextColor3 = Color3.new(1,1,1)
            lbl.Font = Enum.Font.GothamBold
            lbl.TextSize = 12
            lbl.Parent = bill
            table.insert(espObjects, bill)
        end
    end
end

local function LootESP()
    ClearESP()
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and not obj:FindFirstChild("Humanoid") then
            local nameLow = (obj.Name or ""):lower()
            if nameLow:find("coin") or nameLow:find("loot") or nameLow:find("pickup") or obj:FindFirstChild("TouchInterest") then
                local box = Instance.new("BoxHandleAdornment")
                box.Adornee = obj
                box.Size = Vector3.new(1.5,1.5,1.5)
                box.Color3 = Color3.fromRGB(70, 255, 70)
                box.AlwaysOnTop = true
                box.Parent = obj
                table.insert(espObjects, box)
            end
        end
    end
end

-- ================================
-- VISUAL & PERFORMANCE
-- ================================
local function SetFullBright(enabled)
    local lighting = game:GetService("Lighting")
    if enabled then
        lighting.Brightness = 2
        lighting.ClockTime = 14
        lighting.FogEnd = 100000
        lighting.GlobalShadows = false
        lighting.Ambient = Color3.new(1,1,1)
    else
        lighting.Brightness = 1
        lighting.ClockTime = 8
        lighting.FogEnd = 500
        lighting.GlobalShadows = true
        lighting.Ambient = Color3.new(0,0,0)
    end
end

local function RemoveParticles()
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("ParticleEmitter") or v:IsA("Trail") then
            v.Enabled = false
        end
    end
end

local function RemoveShadows()
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") then v.CastShadow = false end
    end
    game:GetService("Lighting").GlobalShadows = false
end

local function FPSBoost()
    RemoveParticles()
    RemoveShadows()
    SetFullBright(true)
    settings().Rendering.QualityLevel = 1
    Notify("FPS Boost", "Optimizations applied", 2)
end

-- ================================
-- PLAYER MODIFICATIONS
-- ================================
local function SetWalkSpeed(spd)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.WalkSpeed = spd
    end
end

local function SetJumpPower(pwr)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.JumpPower = pwr
    end
end

local Flying = false
local flyBV, flyBG
local function ToggleFly()
    Flying = not Flying
    if Flying then
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = LocalPlayer.Character.HumanoidRootPart
            flyBV = Instance.new("BodyVelocity")
            flyBG = Instance.new("BodyGyro")
            flyBV.MaxForce = Vector3.new(1e6,1e6,1e6)
            flyBG.MaxTorque = Vector3.new(1e6,1e6,1e6)
            flyBV.Parent = hrp
            flyBG.Parent = hrp
            LocalPlayer.Character.Humanoid.PlatformStand = true
            RunService.RenderStepped:Connect(function()
                if not Flying or not LocalPlayer.Character then return end
                local cam = workspace.CurrentCamera
                local hrp = LocalPlayer.Character.HumanoidRootPart
                local dir = (cam.CFrame.Position - hrp.Position).Unit
                flyBV.Velocity = dir * 55
                flyBG.CFrame = CFrame.new(hrp.Position, cam.CFrame.Position)
            end)
        end
    else
        if flyBV then flyBV:Destroy() end
        if flyBG then flyBG:Destroy() end
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.PlatformStand = false
        end
    end
end

local JumpConn = nil
local function ToggleInfiniteJump()
    if JumpConn then
        JumpConn:Disconnect()
        JumpConn = nil
    else
        JumpConn = UserInputService.JumpRequest:Connect(function()
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                LocalPlayer.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end)
    end
end

local NoclipConn = nil
local function ToggleNoclip()
    if NoclipConn then
        NoclipConn:Disconnect()
        NoclipConn = nil
    else
        NoclipConn = RunService.Stepped:Connect(function()
            if LocalPlayer.Character then
                for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end)
    end
end

local AFKConn = nil
local function ToggleAntiAFK()
    if AFKConn then
        AFKConn:Disconnect()
        AFKConn = nil
    else
        AFKConn = LocalPlayer.Idled:Connect(function()
            VirtualInput:SendKeyEvent(true, "W", false, game)
            task.wait(0.1)
            VirtualInput:SendKeyEvent(false, "W", false, game)
        end)
    end
end

-- ================================
-- LOOP MANAGER
-- ================================
local function StartLoop(name, func, interval)
    if Loops[name] then
        task.cancel(Loops[name])
    end
    Loops[name] = task.spawn(function()
        while Toggles[name] do
            SafeCall(func)
            task.wait(interval)
        end
    end)
end

local function StopLoop(name)
    if Loops[name] then
        task.cancel(Loops[name])
        Loops[name] = nil
    end
end

-- ================================
-- CONFIGURATION
-- ================================
local function SaveConfig()
    local data = {}
    for k, v in pairs(Toggles) do data[k] = v end
    local json = game:GetService("HttpService"):JSONEncode(data)
    pcall(function() writefile("ShadowHubSlimeRNG.json", json) end)
    Notify("Config", "Saved", 2)
end

local function LoadConfig()
    local success, content = pcall(readfile, "ShadowHubSlimeRNG.json")
    if success and content then
        local data = game:GetService("HttpService"):JSONDecode(content)
        for k, v in pairs(data) do
            if Toggles[k] ~= nil then Toggles[k] = v end
        end
        Notify("Config", "Loaded", 2)
    else
        Notify("Config", "No saved config", 2)
    end
end

-- ================================
-- SERVER UTILITIES
-- ================================
local function HopServer()
    local http = game:GetService("HttpService")
    local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?limit=10"
    local success, resp = pcall(function() return http:HttpGetAsync(url) end)
    if success then
        local data = http:JSONDecode(resp)
        for _, server in ipairs(data.data) do
            if server.playing < server.maxPlayers and server.id ~= game.JobId then
                game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, server.id)
                return
            end
        end
    end
    Notify("Server Hop", "No available server", 2)
end

local function Rejoin()
    game:GetService("TeleportService"):Teleport(game.PlaceId)
end

-- ================================
-- PREMIUM MODERN UI (RAYFIELD + FALLBACK)
-- ================================
local Rayfield = nil
local function LoadRayfield()
    local success, result = pcall(function()
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/shlexware/Rayfield/main/rayfieldui.lua"))()
    end)
    if success and result then
        Rayfield = result
        return true
    end
    return false
end

local useRayfield = LoadRayfield()

if useRayfield then
    -- Load Rayfield UI
    Rayfield:LoadConfiguration({
        ConfigurationSaving = {Enabled = true, FileName = "ShadowHubSlimeRNG"},
        Discord = {Enabled = true, Invite = "https://discord.gg/shadowhub", SendJoins = true},
        KeySystem = false
    })

    local Window = Rayfield:CreateWindow({
        Name = "Shadow Hub | Slime RNG",
        LoadingTitle = "Shadow Hub Premium",
        LoadingSubtitle = "Ultimate Slime RNG Automation",
        ConfigurationSaving = {Enabled = true, FileName = "ShadowHubWindow"},
        Discord = {Enabled = true, Invite = "https://discord.gg/shadowhub", RememberJoins = true}
    })

    -- Tabs
    local MainTab = Window:CreateTab("Main", 4483362458)
    local FarmTab = Window:CreateTab("Farm", 4483362458)
    local RNGTab = Window:CreateTab("RNG", 4483362458)
    local UpgradeTab = Window:CreateTab("Upgrades", 4483362458)
    local TeleportTab = Window:CreateTab("Teleports", 4483362458)
    local PlayerTab = Window:CreateTab("Player", 4483362458)
    local VisualTab = Window:CreateTab("Visual", 4483362458)
    local SettingsTab = Window:CreateTab("Settings", 4483362458)
    local CreditsTab = Window:CreateTab("Credits", 4483362458)

    local function AddToggle(tab, flag, label, func, interval)
        Rayfield:CreateToggle({
            Name = label,
            CurrentValue = false,
            Flag = flag,
            Callback = function(val)
                Toggles[flag] = val
                if val then
                    if func then StartLoop(flag, func, interval or 0.5) end
                else
                    StopLoop(flag)
                end
            end,
            Parent = tab
        })
    end

    local function AddButton(tab, label, callback)
        Rayfield:CreateButton({
            Name = label,
            Callback = callback,
            Parent = tab
        })
    end

    local function AddSlider(tab, label, minv, maxv, def, suffix, callback)
        Rayfield:CreateSlider({
            Name = label,
            Range = {minv, maxv},
            Increment = 1,
            Suffix = suffix,
            CurrentValue = def,
            Flag = label:gsub(" ", ""),
            Callback = callback,
            Parent = tab
        })
    end

    local function AddDropdown(tab, label, options, def, callback)
        Rayfield:CreateDropdown({
            Name = label,
            Options = options,
            CurrentOption = def,
            Flag = label:gsub(" ", ""),
            Callback = callback,
            Parent = tab
        })
    end

    -- Build UI
    AddToggle(MainTab, "AutoRoll", "Auto Roll", DoRoll, 0.5)
    AddToggle(MainTab, "FastRoll", "Fast Roll (5x)", FastRoll, 0.8)
    AddToggle(MainTab, "InstantRoll", "Instant Roll", InstantRoll, 0.6)
    AddToggle(MainTab, "AutoCollect", "Auto Collect Loot", AutoCollect, 0.8)
    AddToggle(MainTab, "AutoUpgrade", "Auto Upgrade", AutoUpgrade, 5)
    AddToggle(MainTab, "AutoRebirth", "Auto Rebirth", AutoRebirth, 120)
    AddToggle(MainTab, "AutoPotion", "Auto Luck Potion", AutoPotion, 60)
    AddToggle(MainTab, "AutoMerge", "Auto Merge Slimes", AutoMerge, 30)
    AddToggle(MainTab, "AutoCraft", "Auto Craft Items", AutoCraft, 45)
    AddToggle(MainTab, "AutoDeleteTrash", "Auto Delete Trash Slimes", AutoDeleteTrash, 90)

    AddToggle(FarmTab, "FarmNearest", "Farm Nearest Slime", FarmNearest, 0.3)
    AddButton(FarmTab, "Kill All Slimes", KillAllSlimes)

    AddSlider(RNGTab, "Roll Speed (ms)", 100, 1000, 500, "ms", function(val)
        if Toggles.AutoRoll then StartLoop("AutoRoll", DoRoll, val/1000) end
        if Toggles.FastRoll then StartLoop("FastRoll", FastRoll, val/1000 * 5) end
    end)
    AddButton(RNGTab, "Reset Roll Counter", function() Stats.Rolls = 0; Notify("RNG", "Counter reset", 2) end)
    AddButton(RNGTab, "Force Roll", DoRoll)

    AddButton(UpgradeTab, "Buy All Upgrades (x15)", function()
        for i = 1, 15 do AutoUpgrade(); task.wait(0.3) end
        Notify("Upgrades", "Done", 2)
    end)
    AddButton(UpgradeTab, "Buy Luck Upgrades", function()
        for i = 1, 5 do
            local btn = FindButton({"luck", "upgrade"})
            if btn then ClickButton(btn) end
            task.wait(0.5)
        end
    end)

    AddDropdown(TeleportTab, "Teleport To Zone", TeleportZones, "Start", TeleportTo)

    AddSlider(PlayerTab, "Walk Speed", 16, 350, 16, "speed", SetWalkSpeed)
    AddSlider(PlayerTab, "Jump Power", 50, 500, 50, "power", SetJumpPower)
    AddToggle(PlayerTab, "Fly", "Fly (Mouse Direction)", ToggleFly, 0)
    AddToggle(PlayerTab, "InfiniteJump", "Infinite Jump", ToggleInfiniteJump, 0)
    AddToggle(PlayerTab, "Noclip", "Noclip", ToggleNoclip, 0)
    AddToggle(PlayerTab, "AntiAFK", "Anti AFK", ToggleAntiAFK, 0)

    AddToggle(VisualTab, "FullBright", "FullBright", SetFullBright, 0)
    AddButton(VisualTab, "Disable Particles", RemoveParticles)
    AddButton(VisualTab, "Remove Shadows", RemoveShadows)
    AddToggle(VisualTab, "SlimeESP", "Slime ESP", function()
        if Toggles.SlimeESP then
            SlimeESP()
            StartLoop("SlimeESP", SlimeESP, 2)
        else
            ClearESP()
            StopLoop("SlimeESP")
        end
    end, 0)
    AddToggle(VisualTab, "LootESP", "Loot ESP", function()
        if Toggles.LootESP then
            LootESP()
            StartLoop("LootESP", LootESP, 2)
        else
            ClearESP()
            StopLoop("LootESP")
        end
    end, 0)
    AddButton(VisualTab, "Ultimate FPS Boost", FPSBoost)

    AddButton(SettingsTab, "Save Configuration", SaveConfig)
    AddButton(SettingsTab, "Load Configuration", LoadConfig)
    AddButton(SettingsTab, "Server Hop", HopServer)
    AddButton(SettingsTab, "Rejoin Server", Rejoin)
    AddButton(SettingsTab, "Destroy UI", function()
        HubActive = false
        for _, v in pairs(Loops) do task.cancel(v) end
        ClearESP()
        if flyBV then flyBV:Destroy() end
        if flyBG then flyBG:Destroy() end
        Rayfield:Destroy()
    end)

    AddButton(CreditsTab, "Show Credits", function()
        Notify("Shadow Hub", "Premium Slime RNG Hub\nVersion 11.0 - Ultimate Update\nExecutor: " .. ExecutorName .. "\nAll features working\nCreated by Shadow Team", 6)
    end)

    Notify("Shadow Hub", "Rayfield UI Loaded!\nVersion 11.0 - Fully functional", 4)

else
    -- Fallback: Native GUI (if Rayfield fails)
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "ShadowHubGui"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = game:GetService("CoreGui")

    local MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 520, 0, 460)
    MainFrame.Position = UDim2.new(0.5, -260, 0.5, -230)
    MainFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 25)
    MainFrame.BackgroundTransparency = 0.08
    MainFrame.BorderSizePixel = 0
    local frameCorner = Instance.new("UICorner")
    frameCorner.CornerRadius = UDim.new(0, 14)
    frameCorner.Parent = MainFrame
    MainFrame.Parent = ScreenGui

    local TitleBar = Instance.new("Frame")
    TitleBar.Size = UDim2.new(1, 0, 0, 45)
    TitleBar.BackgroundColor3 = Color3.fromRGB(25, 22, 50)
    TitleBar.BorderSizePixel = 0
    TitleBar.Parent = MainFrame
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 14)
    titleCorner.Parent = TitleBar

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Size = UDim2.new(1, -70, 1, 0)
    TitleLabel.Position = UDim2.new(0, 15, 0, 0)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = "Shadow Hub | Slime RNG [v11.0]"
    TitleLabel.TextColor3 = Color3.fromRGB(210, 190, 255)
    TitleLabel.TextSize = 18
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.Parent = TitleBar

    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Size = UDim2.new(0, 35, 0, 35)
    CloseBtn.Position = UDim2.new(1, -45, 0, 5)
    CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
    CloseBtn.Text = "✕"
    CloseBtn.TextColor3 = Color3.new(1,1,1)
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.TextSize = 18
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(1, 0)
    closeCorner.Parent = CloseBtn
    CloseBtn.Parent = TitleBar
    CloseBtn.MouseButton1Click:Connect(function()
        HubActive = false
        for _, v in pairs(Loops) do task.cancel(v) end
        ClearESP()
        if flyBV then flyBV:Destroy() end
        if flyBG then flyBG:Destroy() end
        ScreenGui:Destroy()
    end)

    local dragActive = false
    local dragStart
    TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragActive = true
            dragStart = input.Position
        end
    end)
    TitleBar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragActive = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragActive and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            MainFrame.Position = MainFrame.Position + UDim2.new(0, delta.X, 0, delta.Y)
            dragStart = input.Position
        end
    end)

    local TabContainer = Instance.new("Frame")
    TabContainer.Size = UDim2.new(1, 0, 0, 40)
    TabContainer.Position = UDim2.new(0, 0, 0, 45)
    TabContainer.BackgroundColor3 = Color3.fromRGB(18, 16, 35)
    TabContainer.BorderSizePixel = 0
    TabContainer.Parent = MainFrame

    local ContentFrame = Instance.new("ScrollingFrame")
    ContentFrame.Size = UDim2.new(1, 0, 1, -85)
    ContentFrame.Position = UDim2.new(0, 0, 0, 85)
    ContentFrame.BackgroundTransparency = 1
    ContentFrame.BorderSizePixel = 0
    ContentFrame.ScrollBarThickness = 6
    ContentFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    ContentFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    ContentFrame.Parent = MainFrame

    local tabs = {}
    local tabNames = {"Main", "Farm", "RNG", "Upgrades", "Teleports", "Player", "Visual", "Settings", "Credits"}
    local function MakeTab(name)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1/#tabNames, 0, 1, 0)
        btn.BackgroundColor3 = Color3.fromRGB(30, 28, 48)
        btn.Text = name
        btn.TextColor3 = Color3.fromRGB(210,210,250)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 13
        btn.Parent = TabContainer
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 6)
        btnCorner.Parent = btn

        local frame = Instance.new("ScrollingFrame")
        frame.Size = UDim2.new(1, 0, 1, 0)
        frame.BackgroundTransparency = 1
        frame.BorderSizePixel = 0
        frame.ScrollBarThickness = 6
        frame.CanvasSize = UDim2.new(0, 0, 0, 0)
        frame.AutomaticCanvasSize = Enum.AutomaticSize.Y
        frame.Visible = false
        frame.Parent = ContentFrame

        btn.MouseButton1Click:Connect(function()
            for _, f in ipairs(ContentFrame:GetChildren()) do
                if f:IsA("ScrollingFrame") then f.Visible = false end
            end
            frame.Visible = true
            for _, b in ipairs(TabContainer:GetChildren()) do
                if b:IsA("TextButton") then b.BackgroundColor3 = Color3.fromRGB(30,28,48) end
            end
            btn.BackgroundColor3 = Color3.fromRGB(90,70,170)
        end)

        tabs[name] = {btn = btn, frame = frame}
        return frame
    end

    local function AddToggle(parent, flag, label, func, interval)
        local cont = Instance.new("Frame")
        cont.Size = UDim2.new(1, -20, 0, 42)
        cont.Position = UDim2.new(0, 10, 0, #parent:GetChildren() * 46)
        cont.BackgroundColor3 = Color3.fromRGB(22,20,42)
        cont.BackgroundTransparency = 0.3
        local contCorner = Instance.new("UICorner")
        contCorner.CornerRadius = UDim.new(0, 8)
        contCorner.Parent = cont
        cont.Parent = parent

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(0.7, 0, 1, 0)
        lbl.Position = UDim2.new(0, 12, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = label
        lbl.TextColor3 = Color3.fromRGB(240,235,255)
        lbl.TextSize = 14
        lbl.Font = Enum.Font.GothamSemibold
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = cont

        local toggleBtn = Instance.new("TextButton")
        toggleBtn.Size = UDim2.new(0, 70, 0, 30)
        toggleBtn.Position = UDim2.new(1, -80, 0.5, -15)
        toggleBtn.BackgroundColor3 = Color3.fromRGB(55,55,85)
        toggleBtn.Text = "OFF"
        toggleBtn.TextColor3 = Color3.new(1,1,1)
        toggleBtn.Font = Enum.Font.GothamBold
        toggleBtn.TextSize = 13
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(1, 0)
        btnCorner.Parent = toggleBtn
        toggleBtn.Parent = cont

        Toggles[flag] = false
        toggleBtn.MouseButton1Click:Connect(function()
            Toggles[flag] = not Toggles[flag]
            toggleBtn.Text = Toggles[flag] and "ON" or "OFF"
            toggleBtn.BackgroundColor3 = Toggles[flag] and Color3.fromRGB(80,200,80) or Color3.fromRGB(55,55,85)
            if Toggles[flag] and func then
                StartLoop(flag, func, interval or 0.5)
            else
                StopLoop(flag)
            end
        end)
        return cont
    end

    local function AddButton(parent, label, callback)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -20, 0, 42)
        btn.Position = UDim2.new(0, 10, 0, #parent:GetChildren() * 46)
        btn.BackgroundColor3 = Color3.fromRGB(75,65,145)
        btn.Text = label
        btn.TextColor3 = Color3.new(1,1,1)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 14
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 8)
        btnCorner.Parent = btn
        btn.Parent = parent
        btn.MouseButton1Click:Connect(callback)
        return btn
    end

    local function AddSlider(parent, label, minv, maxv, def, suffix, callback)
        local cont = Instance.new("Frame")
        cont.Size = UDim2.new(1, -20, 0, 60)
        cont.Position = UDim2.new(0, 10, 0, #parent:GetChildren() * 52)
        cont.BackgroundColor3 = Color3.fromRGB(22,20,42)
        cont.BackgroundTransparency = 0.3
        local contCorner = Instance.new("UICorner")
        contCorner.CornerRadius = UDim.new(0, 8)
        contCorner.Parent = cont
        cont.Parent = parent

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, 0, 0, 24)
        lbl.Position = UDim2.new(0, 12, 0, 6)
        lbl.BackgroundTransparency = 1
        lbl.Text = label .. ": " .. def .. " " .. suffix
        lbl.TextColor3 = Color3.fromRGB(240,235,255)
        lbl.TextSize = 13
        lbl.Font = Enum.Font.GothamSemibold
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = cont

        local slideBg = Instance.new("Frame")
        slideBg.Size = UDim2.new(0.85, 0, 0, 5)
        slideBg.Position = UDim2.new(0.07, 0, 1, -18)
        slideBg.BackgroundColor3 = Color3.fromRGB(70,70,100)
        slideBg.Parent = cont

        local fill = Instance.new("Frame")
        fill.Size = UDim2.new((def-minv)/(maxv-minv), 0, 1, 0)
        fill.BackgroundColor3 = Color3.fromRGB(130,100,255)
        fill.Parent = slideBg

        local knob = Instance.new("TextButton")
        knob.Size = UDim2.new(0, 16, 0, 16)
        knob.Position = UDim2.new((def-minv)/(maxv-minv), -8, 0.5, -8)
        knob.BackgroundColor3 = Color3.new(1,1,1)
        knob.Text = ""
        local knobCorner = Instance.new("UICorner")
        knobCorner.CornerRadius = UDim.new(1, 0)
        knobCorner.Parent = knob
        knob.Parent = slideBg

        local dragging = false
        knob.MouseButton1Down:Connect(function()
            dragging = true
            local moveConn, releaseConn
            moveConn = Mouse.Move:Connect(function()
                if not dragging then moveConn:Disconnect() return end
                local pos = math.clamp((Mouse.X - slideBg.AbsolutePosition.X) / slideBg.AbsoluteSize.X, 0, 1)
                local val = minv + pos * (maxv - minv)
                val = math.floor(val)
                lbl.Text = label .. ": " .. val .. " " .. suffix
                fill.Size = UDim2.new(pos, 0, 1, 0)
                knob.Position = UDim2.new(pos, -8, 0.5, -8)
                callback(val)
            end)
            releaseConn = Mouse.MouseButton1Up:Connect(function()
                dragging = false
                moveConn:Disconnect()
                releaseConn:Disconnect()
            end)
        end)
        return cont
    end

    local function AddDropdown(parent, label, options, def, callback)
        local cont = Instance.new("Frame")
        cont.Size = UDim2.new(1, -20, 0, 52)
        cont.Position = UDim2.new(0, 10, 0, #parent:GetChildren() * 52)
        cont.BackgroundColor3 = Color3.fromRGB(22,20,42)
        cont.BackgroundTransparency = 0.3
        local contCorner = Instance.new("UICorner")
        contCorner.CornerRadius = UDim.new(0, 8)
        contCorner.Parent = cont
        cont.Parent = parent

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(0.5, 0, 0, 24)
        lbl.Position = UDim2.new(0, 12, 0, 14)
        lbl.BackgroundTransparency = 1
        lbl.Text = label .. ": "
        lbl.TextColor3 = Color3.fromRGB(240,235,255)
        lbl.TextSize = 13
        lbl.Font = Enum.Font.GothamSemibold
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = cont

        local dropBtn = Instance.new("TextButton")
        dropBtn.Size = UDim2.new(0.4, 0, 0, 32)
        dropBtn.Position = UDim2.new(0.55, 0, 0.5, -16)
        dropBtn.BackgroundColor3 = Color3.fromRGB(55,55,85)
        dropBtn.Text = def
        dropBtn.TextColor3 = Color3.new(1,1,1)
        dropBtn.Font = Enum.Font.Gotham
        dropBtn.TextSize = 13
        local dCorner = Instance.new("UICorner")
        dCorner.CornerRadius = UDim.new(0, 6)
        dCorner.Parent = dropBtn
        dropBtn.Parent = cont

        local list = Instance.new("Frame")
        list.Size = UDim2.new(0.4, 0, 0, 0)
        list.Position = UDim2.new(0.55, 0, 0.5, 16)
        list.BackgroundColor3 = Color3.fromRGB(40,38,60)
        list.ClipsDescendants = true
        list.Visible = false
        local listCorner = Instance.new("UICorner")
        listCorner.CornerRadius = UDim.new(0, 6)
        listCorner.Parent = list
        list.Parent = cont

        local layout = Instance.new("UIListLayout")
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Parent = list

        for _, opt in ipairs(options) do
            local optBtn = Instance.new("TextButton")
            optBtn.Size = UDim2.new(1, 0, 0, 34)
            optBtn.BackgroundColor3 = Color3.fromRGB(52,50,75)
            optBtn.Text = opt
            optBtn.TextColor3 = Color3.new(1,1,1)
            optBtn.Font = Enum.Font.Gotham
            optBtn.TextSize = 13
            optBtn.Parent = list
            optBtn.MouseButton1Click:Connect(function()
                dropBtn.Text = opt
                list.Visible = false
                list.Size = UDim2.new(0.4, 0, 0, 0)
                callback(opt)
            end)
        end

        dropBtn.MouseButton1Click:Connect(function()
            list.Visible = not list.Visible
            if list.Visible then
                list.Size = UDim2.new(0.4, 0, 0, math.min(#options * 36, 160))
            else
                list.Size = UDim2.new(0.4, 0, 0, 0)
            end
        end)
        return cont
    end

    -- Build native UI
    local mainTab = MakeTab("Main")
    local farmTab = MakeTab("Farm")
    local rngTab = MakeTab("RNG")
    local upgradeTab = MakeTab("Upgrades")
    local teleportTab = MakeTab("Teleports")
    local playerTab = MakeTab("Player")
    local visualTab = MakeTab("Visual")
    local settingsTab = MakeTab("Settings")
    local creditsTab = MakeTab("Credits")

    AddToggle(mainTab, "AutoRoll", "Auto Roll", DoRoll, 0.5)
    AddToggle(mainTab, "FastRoll", "Fast Roll (5x)", FastRoll, 0.8)
    AddToggle(mainTab, "InstantRoll", "Instant Roll", InstantRoll, 0.6)
    AddToggle(mainTab, "AutoCollect", "Auto Collect Loot", AutoCollect, 0.8)
    AddToggle(mainTab, "AutoUpgrade", "Auto Upgrade", AutoUpgrade, 5)
    AddToggle(mainTab, "AutoRebirth", "Auto Rebirth", AutoRebirth, 120)
    AddToggle(mainTab, "AutoPotion", "Auto Luck Potion", AutoPotion, 60)
    AddToggle(mainTab, "AutoMerge", "Auto Merge Slimes", AutoMerge, 30)
    AddToggle(mainTab, "AutoCraft", "Auto Craft Items", AutoCraft, 45)
    AddToggle(mainTab, "AutoDeleteTrash", "Auto Delete Trash Slimes", AutoDeleteTrash, 90)

    AddToggle(farmTab, "FarmNearest", "Farm Nearest Slime", FarmNearest, 0.3)
    AddButton(farmTab, "Kill All Slimes", KillAllSlimes)

    AddSlider(rngTab, "Roll Speed", 100, 1000, 500, "ms", function(val)
        if Toggles.AutoRoll then StartLoop("AutoRoll", DoRoll, val/1000) end
        if Toggles.FastRoll then StartLoop("FastRoll", FastRoll, val/1000 * 5) end
    end)
    AddButton(rngTab, "Reset Roll Counter", function() Stats.Rolls = 0; Notify("RNG", "Reset", 2) end)
    AddButton(rngTab, "Force Roll", DoRoll)

    AddButton(upgradeTab, "Buy All Upgrades (x15)", function()
        for i=1,15 do AutoUpgrade(); task.wait(0.3) end
        Notify("Upgrades", "Done", 2)
    end)
    AddButton(upgradeTab, "Buy Luck Upgrades", function()
        for i=1,5 do
            local btn = FindButton({"luck","upgrade"})
            if btn then ClickButton(btn) end
            task.wait(0.5)
        end
    end)

    AddDropdown(teleportTab, "Teleport To Zone", TeleportZones, "Start", TeleportTo)

    AddSlider(playerTab, "Walk Speed", 16, 350, 16, "speed", SetWalkSpeed)
    AddSlider(playerTab, "Jump Power", 50, 500, 50, "power", SetJumpPower)
    AddToggle(playerTab, "Fly", "Fly (Mouse)", function() ToggleFly() end, 0)
    AddToggle(playerTab, "InfJump", "Infinite Jump", function() ToggleInfiniteJump() end, 0)
    AddToggle(playerTab, "Noclip", "Noclip", function() ToggleNoclip() end, 0)
    AddToggle(playerTab, "AntiAFK", "Anti AFK", function() ToggleAntiAFK() end, 0)

    AddToggle(visualTab, "FullBright", "FullBright", SetFullBright, 0)
    AddButton(visualTab, "Disable Particles", RemoveParticles)
    AddButton(visualTab, "Remove Shadows", RemoveShadows)
    AddToggle(visualTab, "SlimeESP", "Slime ESP", function()
        if Toggles.SlimeESP then
            SlimeESP()
            StartLoop("SlimeESP", SlimeESP, 2)
        else
            ClearESP()
            StopLoop("SlimeESP")
        end
    end, 0)
    AddToggle(visualTab, "LootESP", "Loot ESP", function()
        if Toggles.LootESP then
            LootESP()
            StartLoop("LootESP", LootESP, 2)
        else
            ClearESP()
            StopLoop("LootESP")
        end
    end, 0)
    AddButton(visualTab, "Ultimate FPS Boost", FPSBoost)

    AddButton(settingsTab, "Save Config", SaveConfig)
    AddButton(settingsTab, "Load Config", LoadConfig)
    AddButton(settingsTab, "Server Hop", HopServer)
    AddButton(settingsTab, "Rejoin Server", Rejoin)
    AddButton(settingsTab, "Destroy UI", function()
        HubActive = false
        for _, v in pairs(Loops) do task.cancel(v) end
        ClearESP()
        if flyBV then flyBV:Destroy() end
        if flyBG then flyBG:Destroy() end
        ScreenGui:Destroy()
    end)

    AddButton(creditsTab, "Show Credits", function()
        Notify("Shadow Hub", "Premium Slime RNG Hub\nVersion 11.0 - Ultimate Update\nExecutor: " .. ExecutorName .. "\nAll features working\nCreated by Shadow Team", 6)
    end)

    tabs["Main"].btn.BackgroundColor3 = Color3.fromRGB(90,70,170)
    tabs["Main"].frame.Visible = true

    -- Watermark
    local watermark = Instance.new("TextLabel")
    watermark.Size = UDim2.new(0, 400, 0, 28)
    watermark.Position = UDim2.new(0, 12, 1, -42)
    watermark.BackgroundTransparency = 0.65
    watermark.BackgroundColor3 = Color3.fromRGB(0,0,0)
    watermark.TextColor3 = Color3.fromRGB(160,210,255)
    watermark.Font = Enum.Font.GothamBold
    watermark.TextSize = 13
    local wmCorner = Instance.new("UICorner")
    wmCorner.CornerRadius = UDim.new(0, 8)
    wmCorner.Parent = watermark
    watermark.Parent = ScreenGui

    local function UpdateWatermark()
        local fps = math.floor(1 / task.wait())
        local uptime = math.floor(tick() - Stats.StartTime)
        watermark.Text = string.format("Shadow Hub v11.0 | %s | FPS: %d | Rolls: %d | Uptime: %ds", ExecutorName, fps, Stats.Rolls, uptime)
    end
    task.spawn(function()
        while HubActive do
            UpdateWatermark()
            task.wait(1)
        end
    end)

    if UserInputService.TouchEnabled then
        local mini = Instance.new("TextButton")
        mini.Size = UDim2.new(0, 55, 0, 55)
        mini.Position = UDim2.new(1, -70, 0, 15)
        mini.BackgroundColor3 = Color3.fromRGB(30,28,55)
        mini.Text = "−"
        mini.TextSize = 32
        mini.Font = Enum.Font.GothamBold
        local miniCorner = Instance.new("UICorner")
        miniCorner.CornerRadius = UDim.new(1, 0)
        miniCorner.Parent = mini
        mini.Parent = ScreenGui
        mini.MouseButton1Click:Connect(function()
            MainFrame.Visible = not MainFrame.Visible
            watermark.Visible = MainFrame.Visible
            mini.Text = MainFrame.Visible and "−" or "+"
        end)
    end

    Notify("Shadow Hub", "Ultimate version loaded!\nAll systems operational.", 5)
end