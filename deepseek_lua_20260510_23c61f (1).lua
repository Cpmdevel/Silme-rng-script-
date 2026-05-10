--[[
    SHADOW HUB | SLIME RNG
    ULTIMATE UPDATE - FULLY REWORKED
    No external dependencies, works on ALL executors
    Version 7.0.0 - The Final & Most Stable Release
    Compatible with all Slime RNG updates as of 2026
]]

-- ================================
-- SERVICES & GLOBALS
-- ================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local VirtualInput = game:GetService("VirtualInputManager")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- Executor detection (for watermark)
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

-- Global variables
local Toggles = {}
local Loops = {}
local Stats = {
    Rolls = 0,
    RareRolls = 0,
    StartTime = tick(),
    LastRollTime = 0
}
local HubActive = true

-- Safe call wrapper
local function SafeCall(func, ...)
    local ok, res = pcall(func, ...)
    if not ok then
        warn("[Shadow Hub] Error: " .. tostring(res))
    end
    return ok, res
end

-- Notification (Roblox built-in)
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
-- BUTTON CLICKER - UNIVERSAL
-- ================================
local function ClickButton(button)
    if not button or not (button:IsA("TextButton") or button:IsA("ImageButton")) then
        return false
    end
    local success = false

    -- Method 1: :Click()
    pcall(function() button:Click(); success = true end)

    -- Method 2: Fire MouseButton1Click
    if not success then
        pcall(function()
            if button.MouseButton1Click then
                button.MouseButton1Click:Fire()
                success = true
            end
        end)
    end

    -- Method 3: VirtualInput simulation
    if not success then
        pcall(function()
            local pos = button.AbsolutePosition
            local size = button.AbsoluteSize
            if pos.X > 0 and pos.Y > 0 then
                local x = pos.X + size.X / 2
                local y = pos.Y + size.Y / 2
                VirtualInput:SendMouseButtonEvent(x, y, 0, true, game, 0)
                task.wait(0.05)
                VirtualInput:SendMouseButtonEvent(x, y, 0, false, game, 0)
                success = true
            end
        end)
    end

    -- Method 4: Legacy mouse simulation
    if not success then
        pcall(function()
            local mouse = LocalPlayer:GetMouse()
            local oldX, oldY = mouse.X, mouse.Y
            local pos = button.AbsolutePosition
            local size = button.AbsoluteSize
            mouse.X = pos.X + size.X / 2
            mouse.Y = pos.Y + size.Y / 2
            mouse:Click()
            mouse.X, mouse.Y = oldX, oldY
            success = true
        end)
    end

    return success
end

-- Find GUI button by pattern (name/text)
local function FindButton(pattern)
    pattern = pattern:lower()
    local sources = {
        game:GetService("CoreGui"),
        LocalPlayer:FindFirstChild("PlayerGui")
    }
    for _, src in ipairs(sources) do
        if src then
            for _, v in ipairs(src:GetDescendants()) do
                if v:IsA("TextButton") or v:IsA("ImageButton") then
                    local name = (v.Name or ""):lower()
                    local text = (v.Text or ""):lower()
                    if name:find(pattern) or text:find(pattern) then
                        return v
                    end
                end
            end
        end
    end
    return nil
end

-- ================================
-- CORE AUTOMATION FUNCTIONS
-- ================================
local function DoRoll()
    local btn = FindButton("roll") or FindButton("spin") or FindButton("click")
    if btn and ClickButton(btn) then
        Stats.Rolls = Stats.Rolls + 1
        Stats.LastRollTime = tick()
        return true
    end
    -- Fallback: simulate E key press
    pcall(function()
        VirtualInput:SendKeyEvent(true, "E", false, game)
        task.wait(0.05)
        VirtualInput:SendKeyEvent(false, "E", false, game)
        Stats.Rolls = Stats.Rolls + 1
    end)
    return false
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
                if posPart then
                    local dist = (posPart.Position - hrp.Position).Magnitude
                    if dist < 12 then
                        hrp.CFrame = CFrame.new(posPart.Position)
                        task.wait(0.1)
                    end
                end
            end
        end
    end
end

local function FarmNearestSlime()
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local closest = nil
    local closestDist = math.huge

    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and obj:FindFirstChild("Humanoid") and obj ~= char then
            local targetHrp = obj:FindFirstChild("HumanoidRootPart")
            if targetHrp then
                local dist = (targetHrp.Position - hrp.Position).Magnitude
                if dist < closestDist and dist < 40 then
                    closestDist = dist
                    closest = obj
                end
            end
        end
    end

    if closest and closest:FindFirstChild("HumanoidRootPart") then
        local targetPos = closest.HumanoidRootPart.Position
        hrp.CFrame = CFrame.new(targetPos + Vector3.new(0, 0, 4))
        if closestDist < 8 then
            pcall(function()
                VirtualInput:SendKeyEvent(true, "E", false, game)
                task.wait(0.1)
                VirtualInput:SendKeyEvent(false, "E", false, game)
            end)
        end
    end
end

local function AutoUpgrade()
    local upgradeBtn = FindButton("upgrade") or FindButton("buy") or FindButton("level") or FindButton("shop")
    if upgradeBtn then ClickButton(upgradeBtn) end
    task.wait(0.3)
    -- Scan for upgrade buttons inside UI
    for _, btn in ipairs(game:GetService("CoreGui"):GetDescendants()) do
        if btn:IsA("TextButton") and btn.Visible and btn.Active then
            local txt = (btn.Text or ""):lower()
            if txt:find("luck") or txt:find("damage") or txt:find("speed") or txt:find("buy") or txt:find("level") then
                ClickButton(btn)
                task.wait(0.2)
            end
        end
    end
end

local function AutoRebirth()
    local rebirthBtn = FindButton("rebirth") or FindButton("reset") or FindButton("prestige") or FindButton("reborn")
    if rebirthBtn then
        ClickButton(rebirthBtn)
        task.wait(1)
        local confirm = FindButton("confirm") or FindButton("yes") or FindButton("accept")
        if confirm then
            ClickButton(confirm)
            Notify("Rebirth", "Rebirth completed!", 3)
        end
    end
end

local function UseLuckPotion()
    local potion = FindButton("luck") or FindButton("potion") or FindButton("boost")
    if potion then
        ClickButton(potion)
        return true
    end
    return false
end

local function OpenAreas()
    local areaBtn = FindButton("area") or FindButton("unlock") or FindButton("new")
    if areaBtn then ClickButton(areaBtn) end
    task.wait(0.5)
    for _, btn in ipairs(game:GetService("CoreGui"):GetDescendants()) do
        if btn:IsA("TextButton") and btn.Visible and btn.Active then
            local txt = (btn.Text or ""):lower()
            if txt:find("unlock") or txt:find("buy") then
                ClickButton(btn)
                task.wait(0.3)
            end
        end
    end
end

local function DeleteTrashSlimes()
    local backpack = FindButton("backpack") or FindButton("inventory")
    if backpack then ClickButton(backpack) end
    task.wait(0.5)
    for _, btn in ipairs(game:GetService("CoreGui"):GetDescendants()) do
        if btn:IsA("TextButton") and btn.Visible and btn.Active then
            local txt = (btn.Text or ""):lower()
            if txt:find("delete") or txt:find("trash") or txt:find("sell") then
                ClickButton(btn)
                task.wait(0.1)
            end
        end
    end
end

-- Kill all slimes (combat)
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
    Notify("Combat", "Killed " .. count .. " slime(s)", 2)
end

-- Teleport system (dynamic zones)
local TeleportZones = {
    "Start", "Forest", "Cave", "Desert", "Volcano", "Ice", "Meadow", 
    "Swamp", "Castle", "Sky", "Underworld", "Crystal", "Magma", "Tundra"
}
local function TeleportTo(zone)
    local teleBtn = FindButton("teleport") or FindButton("travel") or FindButton("map")
    if teleBtn then
        ClickButton(teleBtn)
        task.wait(0.5)
        for _, btn in ipairs(game:GetService("CoreGui"):GetDescendants()) do
            if btn:IsA("TextButton") and btn.Text and btn.Text:find(zone) then
                ClickButton(btn)
                Notify("Teleport", "Teleported to " .. zone, 2)
                return true
            end
        end
    end
    return false
end

-- ================================
-- ESP SYSTEMS (NO LAG)
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
            box.Color3 = Color3.fromRGB(255, 50, 50)
            box.AlwaysOnTop = true
            box.ZIndex = 10
            box.Parent = obj
            table.insert(espObjects, box)

            local bill = Instance.new("BillboardGui")
            bill.Adornee = obj
            bill.Size = UDim2.new(0, 120, 0, 30)
            bill.AlwaysOnTop = true
            bill.Parent = obj
            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1,0,1,0)
            label.BackgroundTransparency = 1
            label.Text = obj.Name
            label.TextColor3 = Color3.fromRGB(255,255,255)
            label.Font = Enum.Font.GothamBold
            label.TextSize = 12
            label.Parent = bill
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
                box.Color3 = Color3.fromRGB(50, 255, 50)
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
        lighting.Ambient = Color3.fromRGB(255,255,255)
    else
        lighting.Brightness = 1
        lighting.ClockTime = 8
        lighting.FogEnd = 500
        lighting.GlobalShadows = true
        lighting.Ambient = Color3.fromRGB(0,0,0)
    end
end

local function RemoveParticles()
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Smoke") or v:IsA("Fire") then
            v.Enabled = false
        end
    end
end

local function RemoveShadows()
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") then
            v.CastShadow = false
        end
    end
    game:GetService("Lighting").GlobalShadows = false
end

local function FPSBoost()
    RemoveParticles()
    RemoveShadows()
    SetFullBright(true)
    settings().Rendering.QualityLevel = 1
    Notify("FPS Boost", "All optimizations applied", 2)
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

-- Fly system
local Flying = false
local flyBV, flyBG
local function ToggleFly()
    Flying = not Flying
    if Flying then
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = LocalPlayer.Character.HumanoidRootPart
            flyBV = Instance.new("BodyVelocity")
            flyBG = Instance.new("BodyGyro")
            flyBV.MaxForce = Vector3.new(1e6, 1e6, 1e6)
            flyBG.MaxTorque = Vector3.new(1e6, 1e6, 1e6)
            flyBV.Parent = hrp
            flyBG.Parent = hrp
            LocalPlayer.Character.Humanoid.PlatformStand = true
            RunService.RenderStepped:Connect(function()
                if not Flying or not LocalPlayer.Character then return end
                local cam = workspace.CurrentCamera
                local hrp = LocalPlayer.Character.HumanoidRootPart
                local dir = (cam.CFrame.Position - hrp.Position).Unit
                flyBV.Velocity = dir * 60
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

-- Infinite jump
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

-- Noclip
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

-- Anti AFK
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
-- CONFIGURATION (SAVE/LOAD)
-- ================================
local function SaveConfig()
    local data = {}
    for k, v in pairs(Toggles) do
        data[k] = v
    end
    local json = game:GetService("HttpService"):JSONEncode(data)
    pcall(function() writefile("ShadowHubSlimeRNG_Config.json", json) end)
    Notify("Config", "Configuration saved", 2)
end

local function LoadConfig()
    local success, content = pcall(readfile, "ShadowHubSlimeRNG_Config.json")
    if success and content then
        local data = game:GetService("HttpService"):JSONDecode(content)
        for k, v in pairs(data) do
            if Toggles[k] ~= nil then
                Toggles[k] = v
            end
        end
        Notify("Config", "Configuration loaded", 2)
    else
        Notify("Config", "No saved config found", 2)
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
    Notify("Server Hop", "No available server found", 2)
end

local function Rejoin()
    game:GetService("TeleportService"):Teleport(game.PlaceId)
end

-- ================================
-- CUSTOM UI (NO EXTERNAL)
-- ================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ShadowHubGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = game:GetService("CoreGui")

-- Main window
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 520, 0, 420)
MainFrame.Position = UDim2.new(0.5, -260, 0.5, -210)
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 20)
MainFrame.BackgroundTransparency = 0.08
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 12)
mainCorner.Parent = MainFrame
MainFrame.Parent = ScreenGui

-- Title bar
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 45)
TitleBar.BackgroundColor3 = Color3.fromRGB(25, 20, 45)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame
local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 12)
titleCorner.Parent = TitleBar

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -80, 1, 0)
TitleLabel.Position = UDim2.new(0, 10, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "Shadow Hub | Slime RNG [v7.0]"
TitleLabel.TextColor3 = Color3.fromRGB(200, 180, 255)
TitleLabel.TextSize = 18
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TitleBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 35, 1, 0)
CloseBtn.Position = UDim2.new(1, -40, 0, 0)
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.new(1, 1, 1)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 18
local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 6)
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

-- Tab bar
local TabContainer = Instance.new("Frame")
TabContainer.Size = UDim2.new(1, 0, 0, 38)
TabContainer.Position = UDim2.new(0, 0, 0, 45)
TabContainer.BackgroundColor3 = Color3.fromRGB(20, 18, 35)
TabContainer.BorderSizePixel = 0
TabContainer.Parent = MainFrame

local tabNames = {"Main","Farm","RNG","Upgrades","Teleports","Player","Visual","Settings","Credits"}
local Tabs = {}
local ContentFrame = Instance.new("ScrollingFrame")
ContentFrame.Size = UDim2.new(1, 0, 1, -83)
ContentFrame.Position = UDim2.new(0, 0, 0, 83)
ContentFrame.BackgroundTransparency = 1
ContentFrame.BorderSizePixel = 0
ContentFrame.ScrollBarThickness = 6
ContentFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
ContentFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
ContentFrame.Parent = MainFrame

local function CreateTab(name)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1 / #tabNames, 0, 1, 0)
    btn.BackgroundColor3 = Color3.fromRGB(30, 28, 45)
    btn.Text = name
    btn.TextColor3 = Color3.fromRGB(200, 200, 255)
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
        for _, f in pairs(ContentFrame:GetChildren()) do
            if f:IsA("ScrollingFrame") then f.Visible = false end
        end
        frame.Visible = true
        for _, b in pairs(TabContainer:GetChildren()) do
            if b:IsA("TextButton") then b.BackgroundColor3 = Color3.fromRGB(30, 28, 45) end
        end
        btn.BackgroundColor3 = Color3.fromRGB(80, 70, 150)
    end)

    Tabs[name] = {Button = btn, Frame = frame}
    return frame
end

-- UI element builders
local function AddToggle(parent, flag, label, func, interval)
    local cont = Instance.new("Frame")
    cont.Size = UDim2.new(1, -20, 0, 38)
    cont.Position = UDim2.new(0, 10, 0, #parent:GetChildren() * 43)
    cont.BackgroundColor3 = Color3.fromRGB(25, 23, 45)
    cont.BackgroundTransparency = 0.4
    local contCorner = Instance.new("UICorner")
    contCorner.CornerRadius = UDim.new(0, 8)
    contCorner.Parent = cont
    cont.Parent = parent

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0.7, 0, 1, 0)
    lbl.Position = UDim2.new(0, 12, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.TextColor3 = Color3.fromRGB(230, 230, 255)
    lbl.TextSize = 14
    lbl.Font = Enum.Font.Gotham
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = cont

    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0, 65, 0, 28)
    toggleBtn.Position = UDim2.new(1, -75, 0.5, -14)
    toggleBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 85)
    toggleBtn.Text = "OFF"
    toggleBtn.TextColor3 = Color3.new(1, 1, 1)
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
        toggleBtn.BackgroundColor3 = Toggles[flag] and Color3.fromRGB(80, 200, 80) or Color3.fromRGB(60, 60, 85)
        if Toggles[flag] then
            if func then StartLoop(flag, func, interval or 0.5) end
        else
            StopLoop(flag)
        end
    end)
    return cont
end

local function AddButton(parent, label, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -20, 0, 38)
    btn.Position = UDim2.new(0, 10, 0, #parent:GetChildren() * 43)
    btn.BackgroundColor3 = Color3.fromRGB(65, 55, 130)
    btn.Text = label
    btn.TextColor3 = Color3.new(1, 1, 1)
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
    cont.Size = UDim2.new(1, -20, 0, 55)
    cont.Position = UDim2.new(0, 10, 0, #parent:GetChildren() * 48)
    cont.BackgroundColor3 = Color3.fromRGB(25, 23, 45)
    cont.BackgroundTransparency = 0.4
    local contCorner = Instance.new("UICorner")
    contCorner.CornerRadius = UDim.new(0, 8)
    contCorner.Parent = cont
    cont.Parent = parent

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 22)
    lbl.Position = UDim2.new(0, 12, 0, 5)
    lbl.BackgroundTransparency = 1
    lbl.Text = label .. ": " .. def .. " " .. suffix
    lbl.TextColor3 = Color3.fromRGB(230, 230, 255)
    lbl.TextSize = 13
    lbl.Font = Enum.Font.Gotham
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = cont

    local sliderBg = Instance.new("Frame")
    sliderBg.Size = UDim2.new(0.85, 0, 0, 4)
    sliderBg.Position = UDim2.new(0.07, 0, 1, -15)
    sliderBg.BackgroundColor3 = Color3.fromRGB(80, 80, 100)
    sliderBg.Parent = cont

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((def - minv) / (maxv - minv), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(150, 120, 255)
    fill.Parent = sliderBg

    local knob = Instance.new("TextButton")
    knob.Size = UDim2.new(0, 14, 0, 14)
    knob.Position = UDim2.new((def - minv) / (maxv - minv), -7, 0.5, -7)
    knob.BackgroundColor3 = Color3.new(1, 1, 1)
    knob.Text = ""
    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(1, 0)
    knobCorner.Parent = knob
    knob.Parent = sliderBg

    local dragging = false
    knob.MouseButton1Down:Connect(function()
        dragging = true
        local moveConn
        local releaseConn
        moveConn = Mouse.Move:Connect(function()
            if not dragging then moveConn:Disconnect() return end
            local pos = math.clamp((Mouse.X - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X, 0, 1)
            local val = minv + pos * (maxv - minv)
            val = math.floor(val)
            lbl.Text = label .. ": " .. val .. " " .. suffix
            fill.Size = UDim2.new(pos, 0, 1, 0)
            knob.Position = UDim2.new(pos, -7, 0.5, -7)
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
    cont.Size = UDim2.new(1, -20, 0, 48)
    cont.Position = UDim2.new(0, 10, 0, #parent:GetChildren() * 48)
    cont.BackgroundColor3 = Color3.fromRGB(25, 23, 45)
    cont.BackgroundTransparency = 0.4
    local contCorner = Instance.new("UICorner")
    contCorner.CornerRadius = UDim.new(0, 8)
    contCorner.Parent = cont
    cont.Parent = parent

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0.5, 0, 0, 22)
    lbl.Position = UDim2.new(0, 12, 0, 13)
    lbl.BackgroundTransparency = 1
    lbl.Text = label .. ": "
    lbl.TextColor3 = Color3.fromRGB(230, 230, 255)
    lbl.TextSize = 13
    lbl.Font = Enum.Font.Gotham
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = cont

    local dropdownBtn = Instance.new("TextButton")
    dropdownBtn.Size = UDim2.new(0.4, 0, 0, 30)
    dropdownBtn.Position = UDim2.new(0.55, 0, 0.5, -15)
    dropdownBtn.BackgroundColor3 = Color3.fromRGB(55, 55, 80)
    dropdownBtn.Text = def
    dropdownBtn.TextColor3 = Color3.new(1, 1, 1)
    dropdownBtn.Font = Enum.Font.Gotham
    dropdownBtn.TextSize = 13
    local dropCorner = Instance.new("UICorner")
    dropCorner.CornerRadius = UDim.new(0, 6)
    dropCorner.Parent = dropdownBtn
    dropdownBtn.Parent = cont

    local list = Instance.new("Frame")
    list.Size = UDim2.new(0.4, 0, 0, 0)
    list.Position = UDim2.new(0.55, 0, 0.5, 15)
    list.BackgroundColor3 = Color3.fromRGB(40, 38, 60)
    list.ClipsDescendants = true
    list.Visible = false
    local listCorner = Instance.new("UICorner")
    listCorner.CornerRadius = UDim.new(0, 6)
    listCorner.Parent = list
    list.Parent = cont

    local listLayout = Instance.new("UIListLayout")
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = list

    for _, opt in ipairs(options) do
        local optBtn = Instance.new("TextButton")
        optBtn.Size = UDim2.new(1, 0, 0, 32)
        optBtn.BackgroundColor3 = Color3.fromRGB(50, 48, 70)
        optBtn.Text = opt
        optBtn.TextColor3 = Color3.new(1, 1, 1)
        optBtn.Font = Enum.Font.Gotham
        optBtn.TextSize = 13
        optBtn.Parent = list
        optBtn.MouseButton1Click:Connect(function()
            dropdownBtn.Text = opt
            list.Visible = false
            list.Size = UDim2.new(0.4, 0, 0, 0)
            callback(opt)
        end)
    end

    dropdownBtn.MouseButton1Click:Connect(function()
        list.Visible = not list.Visible
        if list.Visible then
            local itemCount = #options
            list.Size = UDim2.new(0.4, 0, 0, math.min(itemCount * 34, 160))
        else
            list.Size = UDim2.new(0.4, 0, 0, 0)
        end
    end)
    return cont
end

-- Build all tabs
local mainFrame = CreateTab("Main")
local farmFrame = CreateTab("Farm")
local rngFrame = CreateTab("RNG")
local upgradeFrame = CreateTab("Upgrades")
local teleportFrame = CreateTab("Teleports")
local playerFrame = CreateTab("Player")
local visualFrame = CreateTab("Visual")
local settingsFrame = CreateTab("Settings")
local creditsFrame = CreateTab("Credits")

-- Main Tab
AddToggle(mainFrame, "AutoRoll", "Auto Roll", DoRoll, 0.5)
AddToggle(mainFrame, "AutoCollect", "Auto Collect Loot", AutoCollect, 0.8)
AddToggle(mainFrame, "AutoUpgrade", "Auto Upgrade", AutoUpgrade, 5)
AddToggle(mainFrame, "AutoRebirth", "Auto Rebirth", AutoRebirth, 120)
AddToggle(mainFrame, "AutoPotion", "Auto Luck Potion", UseLuckPotion, 60)
AddToggle(mainFrame, "AutoOpenAreas", "Auto Open Areas", OpenAreas, 30)
AddToggle(mainFrame, "AutoDeleteTrash", "Auto Delete Trash Slimes", DeleteTrashSlimes, 60)

-- Farm Tab
AddToggle(farmFrame, "FarmNearest", "Farm Nearest Slime", FarmNearestSlime, 0.3)
AddButton(farmFrame, "Kill All Slimes", KillAllSlimes)

-- RNG Tab
AddSlider(rngFrame, "Roll Speed", 100, 1000, 500, "ms", function(val)
    if Toggles.AutoRoll then StartLoop("AutoRoll", DoRoll, val / 1000) end
end)
AddButton(rngFrame, "Reset Roll Counter", function() Stats.Rolls = 0; Notify("RNG", "Counter reset", 2) end)
AddButton(rngFrame, "Force Roll", DoRoll)

-- Upgrades Tab
AddButton(upgradeFrame, "Buy All Upgrades (x15)", function()
    for i = 1, 15 do AutoUpgrade(); task.wait(0.3) end
    Notify("Upgrades", "Upgrade cycle complete", 2)
end)
AddButton(upgradeFrame, "Buy Luck Upgrades Only", function()
    for i = 1, 5 do
        local btn = FindButton("luck") or FindButton("upgrade")
        if btn then ClickButton(btn) end
        task.wait(0.5)
    end
end)

-- Teleports Tab
AddDropdown(teleportFrame, "Teleport To Zone", TeleportZones, "Start", TeleportTo)

-- Player Tab
AddSlider(playerFrame, "Walk Speed", 16, 350, 16, "speed", SetWalkSpeed)
AddSlider(playerFrame, "Jump Power", 50, 500, 50, "power", SetJumpPower)
AddToggle(playerFrame, "FlyMode", "Fly (Mouse Direction)", function() ToggleFly() end, 0)
AddToggle(playerFrame, "InfJump", "Infinite Jump", function() ToggleInfiniteJump() end, 0)
AddToggle(playerFrame, "Noclip", "Noclip", function() ToggleNoclip() end, 0)
AddToggle(playerFrame, "AntiAFK", "Anti AFK", function() ToggleAntiAFK() end, 0)

-- Visual Tab
AddToggle(visualFrame, "FullBright", "FullBright", SetFullBright, 0)
AddButton(visualFrame, "Disable Particles", RemoveParticles)
AddButton(visualFrame, "Remove Shadows", RemoveShadows)
AddToggle(visualFrame, "SlimeESP", "Slime ESP", function()
    if Toggles.SlimeESP then
        SlimeESP()
        StartLoop("SlimeESP", SlimeESP, 2)
    else
        ClearESP()
        StopLoop("SlimeESP")
    end
end, 0)
AddToggle(visualFrame, "LootESP", "Loot ESP", function()
    if Toggles.LootESP then
        LootESP()
        StartLoop("LootESP", LootESP, 2)
    else
        ClearESP()
        StopLoop("LootESP")
    end
end, 0)
AddButton(visualFrame, "Ultimate FPS Boost", FPSBoost)

-- Settings Tab
AddButton(settingsFrame, "Save Configuration", SaveConfig)
AddButton(settingsFrame, "Load Configuration", LoadConfig)
AddButton(settingsFrame, "Server Hop", HopServer)
AddButton(settingsFrame, "Rejoin Server", Rejoin)
AddButton(settingsFrame, "Destroy UI", function()
    HubActive = false
    for _, v in pairs(Loops) do task.cancel(v) end
    ClearESP()
    if flyBV then flyBV:Destroy() end
    if flyBG then flyBG:Destroy() end
    ScreenGui:Destroy()
end)

-- Credits Tab
AddButton(creditsFrame, "Show Credits", function()
    Notify("Shadow Hub", 
        "Premium Slime RNG Hub\n" ..
        "Version 7.0.0 - Ultimate Update\n" ..
        "Executor: " .. ExecutorName .. "\n" ..
        "All features work with latest game version\n" ..
        "Created by Shadow Team\n" ..
        "No external dependencies", 8)
end)

-- Activate first tab
Tabs["Main"].Button.BackgroundColor3 = Color3.fromRGB(80, 70, 150)
Tabs["Main"].Frame.Visible = true

-- Watermark
local Watermark = Instance.new("TextLabel")
Watermark.Size = UDim2.new(0, 380, 0, 26)
Watermark.Position = UDim2.new(0, 12, 1, -38)
Watermark.BackgroundTransparency = 0.6
Watermark.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Watermark.TextColor3 = Color3.fromRGB(150, 200, 255)
Watermark.Font = Enum.Font.GothamBold
Watermark.TextSize = 12
local wmCorner = Instance.new("UICorner")
wmCorner.CornerRadius = UDim.new(0, 6)
wmCorner.Parent = Watermark
Watermark.Parent = ScreenGui

local function UpdateWatermark()
    local fps = math.floor(1 / task.wait())
    local uptime = math.floor(tick() - Stats.StartTime)
    Watermark.Text = string.format("Shadow Hub v7.0 | %s | FPS: %d | Rolls: %d | Uptime: %ds", 
        ExecutorName, fps, Stats.Rolls, uptime)
end

task.spawn(function()
    while HubActive do
        UpdateWatermark()
        task.wait(1)
    end
end)

-- Mobile minimize button
if UserInputService.TouchEnabled then
    local miniBtn = Instance.new("TextButton")
    miniBtn.Size = UDim2.new(0, 50, 0, 50)
    miniBtn.Position = UDim2.new(1, -60, 0, 10)
    miniBtn.BackgroundColor3 = Color3.fromRGB(30, 28, 50)
    miniBtn.Text = "−"
    miniBtn.TextSize = 30
    miniBtn.Font = Enum.Font.GothamBold
    local miniCorner = Instance.new("UICorner")
    miniCorner.CornerRadius = UDim.new(1, 0)
    miniCorner.Parent = miniBtn
    miniBtn.Parent = ScreenGui
    miniBtn.MouseButton1Click:Connect(function()
        MainFrame.Visible = not MainFrame.Visible
        Watermark.Visible = MainFrame.Visible
        miniBtn.Text = MainFrame.Visible and "−" or "+"
    end)
end

-- Startup notification
Notify("Shadow Hub", "Version 7.0.0 loaded successfully!\nAll systems operational.\nExecutor: " .. ExecutorName, 5)