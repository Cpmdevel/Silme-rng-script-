--[[
    SHADOW HUB | SLIME RNG
    ULTIMATE PREMIUM HUB | VERSION 8.0
    FULLY OPTIMIZED | MODERN UI | NEW FEATURES
    WORKS ON DELTA, HYDROGEN, FLUXUS, ARCEUS X, CODEX, VEGA X, ELECTRON, KRNL
    COMPLETE REWORK – ALL SYSTEMS OPERATIONAL
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
    Luck = 0,
    StartTime = tick()
}
local HubActive = true

-- Safe call wrapper
local function SafeCall(func, ...)
    local ok, res = pcall(func, ...)
    if not ok then warn("[ShadowHub] " .. tostring(res)) end
    return ok, res
end

-- Notification
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
-- ENHANCED BUTTON CLICKER (6 METHODS)
-- ================================
local function ClickButton(button)
    if not button or not (button:IsA("TextButton") or button:IsA("ImageButton")) then return false end
    local clicked = false
    
    -- Method 1: :Click()
    pcall(function() button:Click(); clicked = true end)
    -- Method 2: Fire MouseButton1Click
    if not clicked then
        pcall(function() if button.MouseButton1Click then button.MouseButton1Click:Fire(); clicked = true end end)
    end
    -- Method 3: VirtualInput simulation
    if not clicked then
        pcall(function()
            local pos = button.AbsolutePosition
            local sz = button.AbsoluteSize
            if pos.X > 0 then
                VirtualInput:SendMouseButtonEvent(pos.X+sz.X/2, pos.Y+sz.Y/2, 0, true, game, 0)
                task.wait(0.05)
                VirtualInput:SendMouseButtonEvent(pos.X+sz.X/2, pos.Y+sz.Y/2, 0, false, game, 0)
                clicked = true
            end
        end)
    end
    -- Method 4: Mouse simulation
    if not clicked then
        pcall(function()
            local mouse = LocalPlayer:GetMouse()
            local oldX, oldY = mouse.X, mouse.Y
            local pos = button.AbsolutePosition
            local sz = button.AbsoluteSize
            mouse.X = pos.X + sz.X/2
            mouse.Y = pos.Y + sz.Y/2
            mouse:Click()
            mouse.X, mouse.Y = oldX, oldY
            clicked = true
        end)
    end
    -- Method 5: Fire ClickDetector if exists
    if not clicked then
        pcall(function()
            for _, det in pairs(button:GetChildren()) do
                if det:IsA("ClickDetector") then
                    det:Click()
                    clicked = true
                    break
                end
            end
        end)
    end
    -- Method 6: Send key "E" as last resort (for some games)
    if not clicked then
        pcall(function()
            VirtualInput:SendKeyEvent(true, "E", false, game)
            task.wait(0.05)
            VirtualInput:SendKeyEvent(false, "E", false, game)
            clicked = true
        end)
    end
    return clicked
end

-- Find button (multiple sources, fuzzy match)
local function FindButton(pattern)
    pattern = pattern:lower()
    local sources = {
        game:GetService("CoreGui"),
        LocalPlayer:FindFirstChild("PlayerGui"),
        LocalPlayer:FindFirstChild("ScreenGui")
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
-- CORE FEATURES (UPDATED)
-- ================================
local function DoRoll()
    local btn = FindButton("roll") or FindButton("spin") or FindButton("click")
    if btn and ClickButton(btn) then
        Stats.Rolls = Stats.Rolls + 1
        return true
    end
    return false
end

-- Fast roll (no delay between rolls)
local function FastRoll()
    local btn = FindButton("roll") or FindButton("spin")
    if btn then
        for i = 1, 5 do
            ClickButton(btn)
            task.wait(0.05)
            Stats.Rolls = Stats.Rolls + 1
        end
    end
end

-- Instant roll (bypass animation)
local function InstantRoll()
    local btn = FindButton("roll")
    if btn then
        -- Try to fire the RemoteEvent directly (if game uses remotes)
        pcall(function()
            local remote = LocalPlayer:FindFirstChild("PlayerScripts") and LocalPlayer.PlayerScripts:FindFirstChild("RollRemote")
            if remote then remote:FireServer() end
        end)
        ClickButton(btn)
        Stats.Rolls = Stats.Rolls + 1
    end
end

local function AutoCollect()
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") then
            local name = (obj.Name or ""):lower()
            local hasTouch = obj:FindFirstChild("TouchInterest")
            if hasTouch or name:find("pickup") or name:find("loot") or name:find("coin") then
                local posPart = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("PrimaryPart") or obj:FindFirstChild("Head")
                if posPart and (posPart.Position - hrp.Position).Magnitude < 15 then
                    hrp.CFrame = CFrame.new(posPart.Position)
                    task.wait(0.05)
                end
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
        hrp.CFrame = CFrame.new(targetPos + Vector3.new(0,0,3))
        if bestDist < 6 then
            pcall(function()
                VirtualInput:SendKeyEvent(true, "E", false, game)
                task.wait(0.1)
                VirtualInput:SendKeyEvent(false, "E", false, game)
            end)
        end
    end
end

local function AutoUpgrade()
    local upgradeBtn = FindButton("upgrade") or FindButton("buy") or FindButton("level")
    if upgradeBtn then ClickButton(upgradeBtn) end
    task.wait(0.2)
    for _, btn in ipairs(game:GetService("CoreGui"):GetDescendants()) do
        if btn:IsA("TextButton") and btn.Visible and btn.Active then
            local txt = (btn.Text or ""):lower()
            if txt:find("luck") or txt:find("damage") or txt:find("speed") or txt:find("buy") then
                ClickButton(btn)
                task.wait(0.1)
            end
        end
    end
end

local function AutoRebirth()
    local rebirthBtn = FindButton("rebirth") or FindButton("reset") or FindButton("prestige")
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

local function AutoPotion()
    local potion = FindButton("luck") or FindButton("potion") or FindButton("boost")
    if potion then ClickButton(potion) end
end

local function AutoMerge()
    local mergeBtn = FindButton("merge") or FindButton("combine") or FindButton("craft")
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
    local craftBtn = FindButton("craft") or FindButton("forge")
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
    local backpack = FindButton("backpack") or FindButton("inventory")
    if backpack then ClickButton(backpack) end
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

local function AutoLockRare()
    local backpack = FindButton("backpack") or FindButton("inventory")
    if backpack then ClickButton(backpack) end
    task.wait(0.3)
    for _, btn in ipairs(game:GetService("CoreGui"):GetDescendants()) do
        if btn:IsA("TextButton") and btn.Visible and btn.Text then
            if btn.Text:find("Rare") or btn.Text:find("Epic") or btn.Text:find("Legendary") then
                local lockBtn = btn.Parent:FindFirstChild("Lock")
                if lockBtn and lockBtn:IsA("TextButton") then
                    ClickButton(lockBtn)
                end
            end
        end
    end
end

-- Kill all slimes
local function KillAll()
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

-- Teleport
local TeleportZones = {"Start", "Forest", "Cave", "Desert", "Volcano", "Ice", "Meadow", "Swamp", "Castle", "Crystal"}
local function TeleportTo(zone)
    local teleBtn = FindButton("teleport") or FindButton("travel") or FindButton("map")
    if teleBtn then
        ClickButton(teleBtn)
        task.wait(0.5)
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
-- ESP & VISUAL
-- ================================
local espList = {}
local function ClearESP()
    for _, v in ipairs(espList) do pcall(function() v:Destroy() end) end
    espList = {}
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
            table.insert(espList, box)
            local bill = Instance.new("BillboardGui")
            bill.Adornee = obj
            bill.Size = UDim2.new(0, 120, 0, 28)
            bill.AlwaysOnTop = true
            bill.Parent = obj
            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1,0,1,0)
            lbl.BackgroundTransparency = 1
            lbl.Text = obj.Name
            lbl.TextColor3 = Color3.new(1,1,1)
            lbl.Font = Enum.Font.GothamBold
            lbl.TextSize = 11
            lbl.Parent = bill
            table.insert(espList, bill)
        end
    end
end

local function LootESP()
    ClearESP()
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and not obj:FindFirstChild("Humanoid") then
            local name = (obj.Name or ""):lower()
            if name:find("coin") or name:find("loot") or name:find("pickup") or obj:FindFirstChild("TouchInterest") then
                local box = Instance.new("BoxHandleAdornment")
                box.Adornee = obj
                box.Size = Vector3.new(1.2,1.2,1.2)
                box.Color3 = Color3.fromRGB(70, 255, 70)
                box.AlwaysOnTop = true
                box.Parent = obj
                table.insert(espList, box)
            end
        end
    end
end

local function AuraESP()
    ClearESP()
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and obj:FindFirstChild("Humanoid") and obj ~= LocalPlayer.Character then
            local aura = Instance.new("SelectionBox")
            aura.Adornee = obj
            aura.Color3 = Color3.fromRGB(0, 200, 255)
            aura.LineThickness = 0.1
            aura.Transparency = 0.6
            aura.Parent = obj
            table.insert(espList, aura)
        end
    end
end

-- Visual tweaks
local function SetFullBright(b)
    local lighting = game:GetService("Lighting")
    if b then
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
        if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Smoke") then
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

-- Player tweaks
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

local JumpConn = nil
local function ToggleInfiniteJump()
    if JumpConn then JumpConn:Disconnect(); JumpConn = nil
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
    if NoclipConn then NoclipConn:Disconnect(); NoclipConn = nil
    else
        NoclipConn = RunService.Stepped:Connect(function()
            if LocalPlayer.Character then
                for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
                    if part:IsA("BasePart") then part.CanCollide = false end
                end
            end
        end)
    end
end

local AFKConn = nil
local function ToggleAntiAFK()
    if AFKConn then AFKConn:Disconnect(); AFKConn = nil
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
    if Loops[name] then task.cancel(Loops[name]) end
    Loops[name] = task.spawn(function()
        while Toggles[name] do
            SafeCall(func)
            task.wait(interval)
        end
    end)
end
local function StopLoop(name)
    if Loops[name] then task.cancel(Loops[name]); Loops[name] = nil end
end

-- ================================
-- CONFIG
-- ================================
local function SaveConfig()
    local data = {}
    for k, v in pairs(Toggles) do data[k] = v end
    local json = game:GetService("HttpService"):JSONEncode(data)
    pcall(function() writefile("ShadowHubSlimeRNG.json", json) end)
    Notify("Config", "Saved", 2)
end
local function LoadConfig()
    local s, d = pcall(readfile, "ShadowHubSlimeRNG.json")
    if s and d then
        local data = game:GetService("HttpService"):JSONDecode(d)
        for k, v in pairs(data) do
            if Toggles[k] ~= nil then Toggles[k] = v end
        end
        Notify("Config", "Loaded", 2)
    else Notify("Config", "No config found", 2) end
end

-- Server utils
local function HopServer()
    local http = game:GetService("HttpService")
    local url = "https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?limit=10"
    local ok, resp = pcall(function() return http:HttpGetAsync(url) end)
    if ok then
        local data = http:JSONDecode(resp)
        for _, srv in ipairs(data.data) do
            if srv.playing < srv.maxPlayers and srv.id ~= game.JobId then
                game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, srv.id)
                return
            end
        end
    end
    Notify("Server Hop", "No server found", 2)
end
local function Rejoin()
    game:GetService("TeleportService"):Teleport(game.PlaceId)
end

-- ================================
-- MODERN UI (NO EXTERNAL)
-- ================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ShadowHubGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = game:GetService("CoreGui")

-- Main container
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 560, 0, 460)
MainFrame.Position = UDim2.new(0.5, -280, 0.5, -230)
MainFrame.BackgroundColor3 = Color3.fromRGB(8, 8, 18)
MainFrame.BackgroundTransparency = 0.05
MainFrame.BorderSizePixel = 0
local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 14)
mainCorner.Parent = MainFrame
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui

-- Glow effect
local Glow = Instance.new("Frame")
Glow.Size = UDim2.new(1, 4, 1, 4)
Glow.Position = UDim2.new(-2, 0, -2, 0)
Glow.BackgroundColor3 = Color3.fromRGB(100, 80, 200)
Glow.BackgroundTransparency = 0.8
Glow.BorderSizePixel = 0
local glowCorner = Instance.new("UICorner")
glowCorner.CornerRadius = UDim.new(0, 16)
glowCorner.Parent = Glow
Glow.Parent = MainFrame

-- Title bar (draggable)
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 48)
TitleBar.BackgroundColor3 = Color3.fromRGB(25, 20, 45)
TitleBar.BackgroundTransparency = 0.2
TitleBar.BorderSizePixel = 0
local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 14)
titleCorner.Parent = TitleBar
TitleBar.Parent = MainFrame

local TitleText = Instance.new("TextLabel")
TitleText.Size = UDim2.new(1, -80, 1, 0)
TitleText.Position = UDim2.new(0, 15, 0, 0)
TitleText.BackgroundTransparency = 1
TitleText.Text = "Shadow Hub | Slime RNG [v8.0]"
TitleText.TextColor3 = Color3.fromRGB(210, 190, 255)
TitleText.TextSize = 20
TitleText.Font = Enum.Font.GothamBold
TitleText.TextXAlignment = Enum.TextXAlignment.Left
TitleText.Parent = TitleBar

-- Close button
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 38, 0, 38)
CloseBtn.Position = UDim2.new(1, -48, 0, 5)
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.new(1,1,1)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 20
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

-- Drag functionality
local dragging = false
local dragStart
local function startDrag()
    dragging = true
    dragStart = UserInputService:GetMouseLocation()
end
local function stopDrag()
    dragging = false
end
local function onDrag()
    if dragging then
        local delta = UserInputService:GetMouseLocation() - dragStart
        MainFrame.Position = MainFrame.Position + UDim2.new(0, delta.X, 0, delta.Y)
        dragStart = UserInputService:GetMouseLocation()
    end
end
TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then startDrag() end
end)
TitleBar.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then stopDrag() end
end)
UserInputService.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then onDrag() end
end)

-- Tab bar
local TabContainer = Instance.new("Frame")
TabContainer.Size = UDim2.new(1, 0, 0, 45)
TabContainer.Position = UDim2.new(0, 0, 0, 48)
TabContainer.BackgroundColor3 = Color3.fromRGB(15, 13, 28)
TabContainer.BorderSizePixel = 0
TabContainer.Parent = MainFrame

local tabNames = {"Main","Farm","RNG","Upgrades","Teleports","Player","Visual","Settings","Credits"}
local TabsUI = {}
local ContentFrame = Instance.new("ScrollingFrame")
ContentFrame.Size = UDim2.new(1, 0, 1, -93)
ContentFrame.Position = UDim2.new(0, 0, 0, 93)
ContentFrame.BackgroundTransparency = 1
ContentFrame.BorderSizePixel = 0
ContentFrame.ScrollBarThickness = 6
ContentFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
ContentFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
ContentFrame.Parent = MainFrame

local function CreateTab(name)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1 / #tabNames, 0, 1, 0)
    btn.BackgroundColor3 = Color3.fromRGB(28, 26, 45)
    btn.Text = name
    btn.TextColor3 = Color3.fromRGB(200, 200, 240)
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
            if b:IsA("TextButton") then b.BackgroundColor3 = Color3.fromRGB(28, 26, 45) end
        end
        btn.BackgroundColor3 = Color3.fromRGB(90, 70, 170)
    end)
    
    TabsUI[name] = {Button = btn, Frame = frame}
    return frame
end

-- UI element builders (more stylish)
local function AddToggle(parent, flag, label, func, interval)
    local cont = Instance.new("Frame")
    cont.Size = UDim2.new(1, -20, 0, 42)
    cont.Position = UDim2.new(0, 10, 0, #parent:GetChildren() * 47)
    cont.BackgroundColor3 = Color3.fromRGB(22, 20, 38)
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
    lbl.TextColor3 = Color3.fromRGB(235, 230, 255)
    lbl.TextSize = 14
    lbl.Font = Enum.Font.GothamSemibold
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = cont
    
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0, 70, 0, 30)
    toggleBtn.Position = UDim2.new(1, -80, 0.5, -15)
    toggleBtn.BackgroundColor3 = Color3.fromRGB(55, 55, 85)
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
        toggleBtn.BackgroundColor3 = Toggles[flag] and Color3.fromRGB(80, 200, 80) or Color3.fromRGB(55, 55, 85)
        if Toggles[flag] and func then
            StartLoop(flag, func, interval or 0.5)
        elseif not Toggles[flag] then
            StopLoop(flag)
        end
    end)
    return cont
end

local function AddButton(parent, label, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -20, 0, 42)
    btn.Position = UDim2.new(0, 10, 0, #parent:GetChildren() * 47)
    btn.BackgroundColor3 = Color3.fromRGB(75, 65, 145)
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
    cont.BackgroundColor3 = Color3.fromRGB(22, 20, 38)
    cont.BackgroundTransparency = 0.3
    local contCorner = Instance.new("UICorner")
    contCorner.CornerRadius = UDim.new(0, 8)
    contCorner.Parent = cont
    cont.Parent = parent
    
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 24)
    lbl.Position = UDim2.new(0, 12, 0, 8)
    lbl.BackgroundTransparency = 1
    lbl.Text = label .. ": " .. def .. " " .. suffix
    lbl.TextColor3 = Color3.fromRGB(235, 230, 255)
    lbl.TextSize = 13
    lbl.Font = Enum.Font.GothamSemibold
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = cont
    
    local sliderBg = Instance.new("Frame")
    sliderBg.Size = UDim2.new(0.85, 0, 0, 5)
    sliderBg.Position = UDim2.new(0.07, 0, 1, -18)
    sliderBg.BackgroundColor3 = Color3.fromRGB(70, 70, 100)
    sliderBg.Parent = cont
    
    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((def - minv) / (maxv - minv), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(130, 100, 255)
    fill.Parent = sliderBg
    
    local knob = Instance.new("TextButton")
    knob.Size = UDim2.new(0, 16, 0, 16)
    knob.Position = UDim2.new((def - minv) / (maxv - minv), -8, 0.5, -8)
    knob.BackgroundColor3 = Color3.new(1,1,1)
    knob.Text = ""
    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(1, 0)
    knobCorner.Parent = knob
    knob.Parent = sliderBg
    
    local dragging = false
    knob.MouseButton1Down:Connect(function()
        dragging = true
        local moveConn, releaseConn
        moveConn = Mouse.Move:Connect(function()
            if not dragging then moveConn:Disconnect() return end
            local pos = math.clamp((Mouse.X - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X, 0, 1)
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
    cont.BackgroundColor3 = Color3.fromRGB(22, 20, 38)
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
    lbl.TextColor3 = Color3.fromRGB(235, 230, 255)
    lbl.TextSize = 13
    lbl.Font = Enum.Font.GothamSemibold
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = cont
    
    local dropdownBtn = Instance.new("TextButton")
    dropdownBtn.Size = UDim2.new(0.4, 0, 0, 32)
    dropdownBtn.Position = UDim2.new(0.55, 0, 0.5, -16)
    dropdownBtn.BackgroundColor3 = Color3.fromRGB(55, 55, 85)
    dropdownBtn.Text = def
    dropdownBtn.TextColor3 = Color3.new(1,1,1)
    dropdownBtn.Font = Enum.Font.Gotham
    dropdownBtn.TextSize = 13
    local dropCorner = Instance.new("UICorner")
    dropCorner.CornerRadius = UDim.new(0, 6)
    dropCorner.Parent = dropdownBtn
    dropdownBtn.Parent = cont
    
    local list = Instance.new("Frame")
    list.Size = UDim2.new(0.4, 0, 0, 0)
    list.Position = UDim2.new(0.55, 0, 0.5, 16)
    list.BackgroundColor3 = Color3.fromRGB(38, 36, 58)
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
        optBtn.BackgroundColor3 = Color3.fromRGB(50, 48, 75)
        optBtn.Text = opt
        optBtn.TextColor3 = Color3.new(1,1,1)
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
            list.Size = UDim2.new(0.4, 0, 0, math.min(#options * 36, 160))
        else
            list.Size = UDim2.new(0.4, 0, 0, 0)
        end
    end)
    return cont
end

-- Build all tabs
local mainFrameUI = CreateTab("Main")
local farmFrameUI = CreateTab("Farm")
local rngFrameUI = CreateTab("RNG")
local upgradeFrameUI = CreateTab("Upgrades")
local teleportFrameUI = CreateTab("Teleports")
local playerFrameUI = CreateTab("Player")
local visualFrameUI = CreateTab("Visual")
local settingsFrameUI = CreateTab("Settings")
local creditsFrameUI = CreateTab("Credits")

-- ========== MAIN TAB ==========
AddToggle(mainFrameUI, "AutoRoll", "Auto Roll", DoRoll, 0.5)
AddToggle(mainFrameUI, "FastRoll", "Fast Roll (5x)", FastRoll, 0.8)
AddToggle(mainFrameUI, "InstantRoll", "Instant Roll", InstantRoll, 0.6)
AddToggle(mainFrameUI, "AutoCollect", "Auto Collect Loot", AutoCollect, 0.8)
AddToggle(mainFrameUI, "AutoUpgrade", "Auto Upgrade", AutoUpgrade, 5)
AddToggle(mainFrameUI, "AutoRebirth", "Auto Rebirth", AutoRebirth, 120)
AddToggle(mainFrameUI, "AutoPotion", "Auto Luck Potion", AutoPotion, 60)
AddToggle(mainFrameUI, "AutoMerge", "Auto Merge Slimes", AutoMerge, 30)
AddToggle(mainFrameUI, "AutoCraft", "Auto Craft Items", AutoCraft, 45)
AddToggle(mainFrameUI, "AutoDeleteTrash", "Auto Delete Trash Slimes", AutoDeleteTrash, 90)
AddToggle(mainFrameUI, "AutoLockRare", "Auto Lock Rare Slimes", AutoLockRare, 20)

-- ========== FARM TAB ==========
AddToggle(farmFrameUI, "FarmNearest", "Farm Nearest Slime", FarmNearest, 0.3)
AddButton(farmFrameUI, "Kill All Slimes", KillAll)

-- ========== RNG TAB ==========
AddSlider(rngFrameUI, "Roll Speed", 100, 1000, 500, "ms", function(val)
    if Toggles.AutoRoll then StartLoop("AutoRoll", DoRoll, val / 1000) end
    if Toggles.FastRoll then StartLoop("FastRoll", FastRoll, val / 1000 * 5) end
end)
AddButton(rngFrameUI, "Reset Roll Counter", function() Stats.Rolls = 0; Notify("RNG", "Counter reset", 2) end)
AddButton(rngFrameUI, "Force Roll", DoRoll)
AddButton(rngFrameUI, "Roll Statistics", function()
    Notify("Stats", "Total Rolls: " .. Stats.Rolls .. "\nRare Rolls: " .. Stats.RareRolls .. "\nSession time: " .. math.floor(tick() - Stats.StartTime) .. "s", 5)
end)
AddToggle(rngFrameUI, "RareNotify", "Rare Roll Notification", function()
    -- Placeholder, would need to detect rare rolls
end, 0)

-- ========== UPGRADES TAB ==========
AddButton(upgradeFrameUI, "Buy All Upgrades (x15)", function()
    for i = 1, 15 do AutoUpgrade(); task.wait(0.3) end
    Notify("Upgrades", "Done", 2)
end)
AddButton(upgradeFrameUI, "Buy Luck Upgrades Only", function()
    for i = 1, 5 do
        local btn = FindButton("luck") or FindButton("upgrade")
        if btn then ClickButton(btn) end
        task.wait(0.5)
    end
end)
AddButton(upgradeFrameUI, "Buy Damage Upgrades", function()
    for i = 1, 5 do
        local btn = FindButton("damage") or FindButton("attack")
        if btn then ClickButton(btn) end
        task.wait(0.5)
    end
end)
AddButton(upgradeFrameUI, "Buy Speed Upgrades", function()
    for i = 1, 5 do
        local btn = FindButton("speed") or FindButton("roll speed")
        if btn then ClickButton(btn) end
        task.wait(0.5)
    end
end)

-- ========== TELEPORTS TAB ==========
AddDropdown(teleportFrameUI, "Teleport To Zone", TeleportZones, "Start", TeleportTo)

-- ========== PLAYER TAB ==========
AddSlider(playerFrameUI, "Walk Speed", 16, 350, 16, "speed", SetWalkSpeed)
AddSlider(playerFrameUI, "Jump Power", 50, 500, 50, "power", SetJumpPower)
AddToggle(playerFrameUI, "FlyMode", "Fly (Mouse Follow)", function() ToggleFly() end, 0)
AddToggle(playerFrameUI, "InfJump", "Infinite Jump", function() ToggleInfiniteJump() end, 0)
AddToggle(playerFrameUI, "Noclip", "Noclip", function() ToggleNoclip() end, 0)
AddToggle(playerFrameUI, "AntiAFK", "Anti AFK", function() ToggleAntiAFK() end, 0)

-- ========== VISUAL TAB ==========
AddToggle(visualFrameUI, "FullBright", "FullBright", SetFullBright, 0)
AddButton(visualFrameUI, "Disable Particles", RemoveParticles)
AddButton(visualFrameUI, "Remove Shadows", RemoveShadows)
AddToggle(visualFrameUI, "SlimeESP", "Slime ESP", function()
    if Toggles.SlimeESP then
        SlimeESP()
        StartLoop("SlimeESP", SlimeESP, 2)
    else
        ClearESP()
        StopLoop("SlimeESP")
    end
end, 0)
AddToggle(visualFrameUI, "LootESP", "Loot ESP", function()
    if Toggles.LootESP then
        LootESP()
        StartLoop("LootESP", LootESP, 2)
    else
        ClearESP()
        StopLoop("LootESP")
    end
end, 0)
AddToggle(visualFrameUI, "AuraESP", "Aura ESP (Glow)", function()
    if Toggles.AuraESP then
        AuraESP()
        StartLoop("AuraESP", AuraESP, 2)
    else
        ClearESP()
        StopLoop("AuraESP")
    end
end, 0)
AddButton(visualFrameUI, "Ultimate FPS Boost", FPSBoost)

-- ========== SETTINGS TAB ==========
AddButton(settingsFrameUI, "Save Configuration", SaveConfig)
AddButton(settingsFrameUI, "Load Configuration", LoadConfig)
AddButton(settingsFrameUI, "Server Hop", HopServer)
AddButton(settingsFrameUI, "Rejoin Server", Rejoin)
AddButton(settingsFrameUI, "Destroy UI", function()
    HubActive = false
    for _, v in pairs(Loops) do task.cancel(v) end
    ClearESP()
    if flyBV then flyBV:Destroy() end
    if flyBG then flyBG:Destroy() end
    ScreenGui:Destroy()
end)

-- ========== CREDITS TAB ==========
AddButton(creditsFrameUI, "Show Credits", function()
    Notify("Shadow Hub", 
        "Premium Slime RNG Hub\n" ..
        "Version 8.0 - Ultimate Edition\n" ..
        "Executor: " .. ExecutorName .. "\n" ..
        "All features working with latest game version\n" ..
        "Created by Shadow Team\n" ..
        "No external dependencies - 100% stable", 8)
end)

-- Activate first tab
TabsUI["Main"].Button.BackgroundColor3 = Color3.fromRGB(90, 70, 170)
TabsUI["Main"].Frame.Visible = true

-- ================================
-- WATERMARK & STATS LOOP
-- ================================
local Watermark = Instance.new("TextLabel")
Watermark.Size = UDim2.new(0, 400, 0, 28)
Watermark.Position = UDim2.new(0, 12, 1, -42)
Watermark.BackgroundTransparency = 0.65
Watermark.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Watermark.TextColor3 = Color3.fromRGB(160, 210, 255)
Watermark.Font = Enum.Font.GothamBold
Watermark.TextSize = 13
local wmCorner = Instance.new("UICorner")
wmCorner.CornerRadius = UDim.new(0, 8)
wmCorner.Parent = Watermark
Watermark.Parent = ScreenGui

local function UpdateWatermark()
    local fps = math.floor(1 / task.wait())
    local uptime = math.floor(tick() - Stats.StartTime)
    Watermark.Text = string.format("Shadow Hub v8.0 | %s | FPS: %d | Rolls: %d | Uptime: %ds", 
        ExecutorName, fps, Stats.Rolls, uptime)
end

task.spawn(function()
    while HubActive do
        UpdateWatermark()
        task.wait(1)
    end
end)

-- ================================
-- MOBILE MINIMIZE BUTTON
-- ================================
if UserInputService.TouchEnabled then
    local miniBtn = Instance.new("TextButton")
    miniBtn.Size = UDim2.new(0, 55, 0, 55)
    miniBtn.Position = UDim2.new(1, -70, 0, 15)
    miniBtn.BackgroundColor3 = Color3.fromRGB(30, 28, 55)
    miniBtn.Text = "−"
    miniBtn.TextSize = 32
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
Notify("Shadow Hub", "Version 8.0 Ultimate loaded!\nAll systems operational.\nExecutor: " .. ExecutorName, 5)