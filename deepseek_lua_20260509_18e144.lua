--[[
    ███████╗██╗     ██╗███╗   ███╗███████╗    ██████╗ ███╗   ██╗ ██████╗ 
    ██╔════╝██║     ██║████╗ ████║██╔════╝    ██╔══██╗████╗  ██║██╔════╝ 
    ███████╗██║     ██║██╔████╔██║█████╗      ██████╔╝██╔██╗ ██║██║  ███╗
    ╚════██║██║     ██║██║╚██╔╝██║██╔══╝      ██╔══██╗██║╚██╗██║██║   ██║
    ███████║███████╗██║██║ ╚═╝ ██║███████╗    ██║  ██║██║ ╚████║╚██████╔╝
    ╚══════╝╚══════╝╚═╝╚═╝     ╚═╝╚══════╝    ╚═╝  ╚═╝╚═╝  ╚═══╝ ╚═════╝ 
                                                                          
    Premium Slime RNG Hub | Mobile + PC Optimized | Stouts Studio Edition
    Ultimate RNG Automation System | Touch-Friendly Interface | v7.0
--]]

-- // Services
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
    WindowName = "Slime RNG Hub",
    AccentColor = Color3.fromRGB(0, 255, 255),
    MobileMode = UserInputService.TouchEnabled,
    MinimizeKey = "RightShift",
    ToggleKey = "Insert",
    Watermark = true
}

-- // State
local State = {
    Toggles = {
        AutoFarm = false, AutoCollect = false, AutoAttack = false, AutoKillAura = false,
        AutoEquipBest = false, AutoBuyGear = false, AutoRebirth = false, AutoUpgrade = false,
        AutoSpin = false, AutoQuest = false, AutoClaimRewards = false, AutoDaily = false,
        AutoEvent = false, AutoCraft = false, AutoRoll = false, FastRoll = false,
        InstantRoll = false, AutoSaveRares = false, AutoBuyPotions = false,
        AutoUpgradeLuck = false, AutoUpgradeSpeed = false, AutoUpgradeStorage = false,
        AutoUpgradeDamage = false, Fly = false, Noclip = false, InfiniteJump = false,
        AntiAFK = false, FPSBoost = false, RemoveEffects = false, DisableParticles = false,
        LowGraphics = false, HideDamage = false, RemoveShadows = false, PotatoMode = false,
        RainbowAccent = false
    },
    Sliders = {
        WalkSpeed = 16, JumpPower = 50, RollDelay = 0.05, AttackRange = 30, CollectRange = 40
    },
    Dropdowns = { AttackMode = "ClickDetector", TeleportLocation = "Spawn" },
    Stats = { Rolls = 0, RareRolls = 0, Luck = 1, RarestAura = "None" }
}

-- // Notify (Mobile compatible)
local function Notify(title, text, duration)
    pcall(function()
        game.StarterGui:SetCore("SendNotification", {
            Title = title, Text = text, Duration = duration or 3, Icon = ""
        })
    end)
end

-- // Utility Functions
local function GetNearestSlime()
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return nil end
    local root = char.HumanoidRootPart
    local nearest, minDist = nil, State.Sliders.AttackRange
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and (obj.Name:lower():find("slime") or obj:FindFirstChild("Humanoid")) then
            local hrp = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Head")
            if hrp and hrp.Position then
                local dist = (hrp.Position - root.Position).Magnitude
                if dist < minDist then nearest, minDist = obj, dist end
            end
        end
    end
    return nearest
end

local function AttackSlime(slime)
    if not slime then return false end
    pcall(function()
        if State.Dropdowns.AttackMode == "ClickDetector" then
            local cd = slime:FindFirstChildWhichIsA("ClickDetector")
            if cd then fireclickdetector(cd); return true end
        elseif State.Dropdowns.AttackMode == "Remote" then
            for _, r in ipairs(ReplicatedStorage:GetDescendants()) do
                if r:IsA("RemoteEvent") and (r.Name:lower():find("attack") or r.Name:lower():find("damage")) then
                    r:FireServer(slime); return true
                end
            end
        elseif State.Dropdowns.AttackMode == "Tool" then
            local tool = LocalPlayer.Character:FindFirstChildWhichIsA("Tool")
            if tool then tool:Activate(); return true end
        end
    end)
    return false
end

local function TeleportTo(pos)
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        local tween = TweenService:Create(char.HumanoidRootPart, TweenInfo.new(0.4, Enum.EasingStyle.Quad), {CFrame = CFrame.new(pos)})
        tween:Play()
        tween.Completed:Wait()
    end
end

local function GetCollectibles()
    local list = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") and (obj.Name:lower():find("loot") or obj.Name:lower():find("drop") or obj.Name:lower():find("orb") or obj.Name:lower():find("gem")) then
            table.insert(list, obj)
        end
    end
    return list
end

-- // Core Loops
local function AutoFarmLoop()
    while State.Toggles.AutoFarm and task.wait(0.1) do
        pcall(function()
            if State.Toggles.AutoAttack then
                local slime = GetNearestSlime()
                if slime then AttackSlime(slime) end
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
                    if slime:IsA("Model") and slime.Name:lower():find("slime") then
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
            local rollRemote
            for _, r in ipairs(ReplicatedStorage:GetDescendants()) do
                if r:IsA("RemoteEvent") and (r.Name:lower():find("roll") or r.Name:lower():find("spin")) then
                    rollRemote = r; break
                end
            end
            if rollRemote then
                if State.Toggles.InstantRoll then
                    for i = 1, 10 do rollRemote:FireServer(); State.Stats.Rolls = State.Stats.Rolls + 1 end
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
            for _, btn in ipairs(LocalPlayer.PlayerGui:GetDescendants()) do
                if btn:IsA("TextButton") and (btn.Name:lower():find("upgrade") or (btn.Text and btn.Text:lower():find("upgrade"))) then
                    btn:Activate()
                    task.wait(0.2)
                end
            end
            if State.Toggles.AutoUpgradeLuck then
                local remote = ReplicatedStorage:FindFirstChild("UpgradeLuck")
                if remote then remote:FireServer() end
            end
            if State.Toggles.AutoUpgradeSpeed then
                local remote = ReplicatedStorage:FindFirstChild("UpgradeSpeed")
                if remote then remote:FireServer() end
            end
            if State.Toggles.AutoUpgradeStorage then
                local remote = ReplicatedStorage:FindFirstChild("UpgradeStorage")
                if remote then remote:FireServer() end
            end
            if State.Toggles.AutoUpgradeDamage then
                local remote = ReplicatedStorage:FindFirstChild("UpgradeDamage")
                if remote then remote:FireServer() end
            end
        end)
    end
end

local function QuestLoop()
    while State.Toggles.AutoQuest and task.wait(2) do
        pcall(function()
            local claim = ReplicatedStorage:FindFirstChild("ClaimQuest")
            if claim then claim:FireServer() end
            local start = ReplicatedStorage:FindFirstChild("StartQuest")
            if start then start:FireServer() end
        end)
    end
end

local function CraftLoop()
    while State.Toggles.AutoCraft and task.wait(1) do
        pcall(function()
            local craft = ReplicatedStorage:FindFirstChild("CraftItem")
            if craft then craft:FireServer() end
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
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then
        char.Humanoid.WalkSpeed = State.Sliders.WalkSpeed
    end
end

local function JumpPowerUpdate()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then
        char.Humanoid.JumpPower = State.Sliders.JumpPower
    end
end

local flyConnection = nil
local function FlyUpdate()
    local char = LocalPlayer.Character
    if not char then return end
    local humanoid = char:FindFirstChild("Humanoid")
    local rootPart = char:FindFirstChild("HumanoidRootPart")
    if not humanoid or not rootPart then return end
    
    if State.Toggles.Fly then
        if flyConnection then flyConnection:Disconnect() end
        humanoid.PlatformStand = true
        local bv = Instance.new("BodyVelocity")
        bv.MaxForce = Vector3.new(1e6, 1e6, 1e6)
        bv.Velocity = Vector3.new(0,0,0)
        bv.Parent = rootPart
        flyConnection = RunService.RenderStepped:Connect(function()
            if not State.Toggles.Fly then
                bv:Destroy()
                if flyConnection then flyConnection:Disconnect() end
                flyConnection = nil
                humanoid.PlatformStand = false
                return
            end
            local move = Vector3.new(
                (UserInputService:IsKeyDown(Enum.KeyCode.D) and 1 or 0) - (UserInputService:IsKeyDown(Enum.KeyCode.A) and 1 or 0),
                (UserInputService:IsKeyDown(Enum.KeyCode.Space) and 1 or 0) - (UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) and 1 or 0),
                (UserInputService:IsKeyDown(Enum.KeyCode.W) and 1 or 0) - (UserInputService:IsKeyDown(Enum.KeyCode.S) and 1 or 0)
            )
            local cam = workspace.CurrentCamera.CFrame
            move = cam:VectorToWorldSpace(move)
            bv.Velocity = move * (Config.MobileMode and 80 or 100)
        end)
    else
        if flyConnection then flyConnection:Disconnect(); flyConnection = nil end
        if rootPart and rootPart:FindFirstChild("BodyVelocity") then rootPart.BodyVelocity:Destroy() end
        humanoid.PlatformStand = false
    end
end

local function NoclipUpdate()
    local char = LocalPlayer.Character
    if char then
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = not State.Toggles.Noclip
            end
        end
    end
end

local function InfiniteJumpUpdate()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then
        local hum = char.Humanoid
        local orig = hum.Jump
        hum.Jump = function(self)
            if State.Toggles.InfiniteJump then orig(self) end
            return orig(self)
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
                for _, e in ipairs(Workspace:GetDescendants()) do
                    if e:IsA("ParticleEmitter") or e:IsA("Fire") or e:IsA("Smoke") then
                        e.Enabled = false
                    end
                end
            end
            if State.Toggles.DisableParticles then
                for _, p in ipairs(Workspace:GetDescendants()) do
                    if p:IsA("ParticleEmitter") then p.Enabled = false end
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
                workspace.DescendantAdded:Connect(function(d)
                    if d:IsA("Decal") or d:IsA("Texture") then d:Destroy() end
                end)
            end
        end)
    end
end

local function ESPLoop()
    while task.wait(0.15) do
        if State.Toggles.AutoSaveRares then
            pcall(function()
                for _, slime in ipairs(Workspace:GetDescendants()) do
                    if slime:IsA("Model") and slime.Name:lower():find("rare") then
                        local hl = Instance.new("Highlight")
                        hl.FillColor = Color3.fromRGB(255,0,255)
                        hl.OutlineColor = Color3.fromRGB(255,255,255)
                        hl.Parent = slime
                        Debris:AddItem(hl, 2)
                        Notify("Rare Aura", slime.Name, 2)
                        State.Stats.RareRolls = State.Stats.RareRolls + 1
                        State.Stats.RarestAura = slime.Name
                    end
                end
            end)
        end
    end
end

-- // Custom UI (Mobile+PC)
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SlimeRNGHub"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = CoreGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, Config.MobileMode and 380 or 450, 0, Config.MobileMode and 500 or 550)
mainFrame.Position = UDim2.new(0.5, -(Config.MobileMode and 190 or 225), 0.5, -(Config.MobileMode and 250 or 275))
mainFrame.BackgroundTransparency = 0.15
mainFrame.BackgroundColor3 = Color3.fromRGB(10,10,10)
mainFrame.BorderSizePixel = 0
mainFrame.ClipsDescendants = true
mainFrame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = mainFrame

local stroke = Instance.new("UIStroke")
stroke.Thickness = 2
stroke.Color = Config.AccentColor
stroke.Transparency = 0.3
stroke.Parent = mainFrame

local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1,0,0, Config.MobileMode and 45 or 35)
titleBar.BackgroundTransparency = 1
titleBar.Parent = mainFrame

local titleText = Instance.new("TextLabel")
titleText.Size = UDim2.new(0.7,0,1,0)
titleText.Position = UDim2.new(0,10,0,0)
titleText.BackgroundTransparency = 1
titleText.Text = Config.WindowName
titleText.TextColor3 = Color3.fromRGB(255,255,255)
titleText.Font = Enum.Font.GothamBold
titleText.TextSize = Config.MobileMode and 18 or 16
titleText.TextXAlignment = Enum.TextXAlignment.Left
titleText.Parent = titleBar

local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Size = UDim2.new(0, Config.MobileMode and 40 or 30, 1, 0)
minimizeBtn.Position = UDim2.new(1, -(Config.MobileMode and 80 or 60), 0, 0)
minimizeBtn.BackgroundTransparency = 1
minimizeBtn.Text = "−"
minimizeBtn.TextColor3 = Color3.fromRGB(255,255,255)
minimizeBtn.Font = Enum.Font.GothamBold
minimizeBtn.TextSize = Config.MobileMode and 24 or 20
minimizeBtn.Parent = titleBar

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, Config.MobileMode and 40 or 30, 1, 0)
closeBtn.Position = UDim2.new(1, -(Config.MobileMode and 40 or 30), 0, 0)
closeBtn.BackgroundTransparency = 1
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(255,100,100)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = Config.MobileMode and 22 or 18
closeBtn.Parent = titleBar

local tabContainer = Instance.new("Frame")
tabContainer.Size = UDim2.new(1,0,0, Config.MobileMode and 50 or 40)
tabContainer.Position = UDim2.new(0,0,0, Config.MobileMode and 45 or 35)
tabContainer.BackgroundTransparency = 1
tabContainer.Parent = mainFrame

local contentContainer = Instance.new("Frame")
contentContainer.Size = UDim2.new(1,-20,1, -(Config.MobileMode and 115 or 95))
contentContainer.Position = UDim2.new(0,10,0, Config.MobileMode and 95 or 75)
contentContainer.BackgroundTransparency = 1
contentContainer.Parent = mainFrame

local tabs = {
    {name="Main", btn=nil, content=nil},
    {name="Auto Farm", btn=nil, content=nil},
    {name="RNG", btn=nil, content=nil},
    {name="Upgrades", btn=nil, content=nil},
    {name="Teleports", btn=nil, content=nil},
    {name="Player", btn=nil, content=nil},
    {name="Visual", btn=nil, content=nil},
    {name="Settings", btn=nil, content=nil},
    {name="Credits", btn=nil, content=nil}
}

local function CreateTab(tabName, idx)
    local btn = Instance.new("TextButton")
    local btnWidth = Config.MobileMode and 80 or 90
    btn.Size = UDim2.new(0, btnWidth, 1, 0)
    btn.Position = UDim2.new(0, 5 + (idx-1)*(btnWidth+5), 0, 0)
    btn.BackgroundTransparency = 1
    btn.Text = tabName
    btn.TextColor3 = Color3.fromRGB(200,200,200)
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = Config.MobileMode and 12 or 14
    btn.Parent = tabContainer
    
    local content = Instance.new("ScrollingFrame")
    content.Size = UDim2.new(1,0,1,0)
    content.BackgroundTransparency = 1
    content.BorderSizePixel = 0
    content.ScrollBarThickness = Config.MobileMode and 8 or 6
    content.ScrollBarImageTransparency = 0.5
    content.CanvasSize = UDim2.new(0,0,0,0)
    content.AutomaticCanvasSize = Enum.AutomaticSize.Y
    content.Parent = contentContainer
    content.Visible = false
    
    return btn, content
end

for i, tab in ipairs(tabs) do
    local btn, content = CreateTab(tab.name, i)
    tab.btn = btn
    tab.content = content
    btn.MouseButton1Click:Connect(function()
        for _, t in ipairs(tabs) do
            t.content.Visible = false
            t.btn.TextColor3 = Color3.fromRGB(200,200,200)
        end
        content.Visible = true
        btn.TextColor3 = Config.AccentColor
    end)
    if i == 1 then
        content.Visible = true
        btn.TextColor3 = Config.AccentColor
    end
end

-- UI Helpers
local function CreateToggle(parent, name, flag, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -20, 0, Config.MobileMode and 45 or 35)
    frame.Position = UDim2.new(0, 10, 0, #parent:GetChildren() * (Config.MobileMode and 50 or 40) + 10)
    frame.BackgroundTransparency = 0.8
    frame.BackgroundColor3 = Color3.fromRGB(30,30,30)
    frame.BorderSizePixel = 0
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 6)
    c.Parent = frame
    frame.Parent = parent
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.7,0,1,0)
    label.Position = UDim2.new(0,10,0,0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Color3.fromRGB(255,255,255)
    label.Font = Enum.Font.Gotham
    label.TextSize = Config.MobileMode and 15 or 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame
    
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0, Config.MobileMode and 70 or 50, 0, Config.MobileMode and 35 or 25)
    toggleBtn.Position = UDim2.new(1, -(Config.MobileMode and 80 or 60), 0, (frame.Size.Y.Offset - (Config.MobileMode and 35 or 25))/2)
    toggleBtn.BackgroundColor3 = Color3.fromRGB(80,80,80)
    toggleBtn.Text = "OFF"
    toggleBtn.TextColor3 = Color3.fromRGB(255,255,255)
    toggleBtn.Font = Enum.Font.GothamBold
    toggleBtn.TextSize = Config.MobileMode and 14 or 12
    local btnCr = Instance.new("UICorner")
    btnCr.CornerRadius = UDim.new(0, 12)
    btnCr.Parent = toggleBtn
    toggleBtn.Parent = frame
    
    local active = false
    toggleBtn.MouseButton1Click:Connect(function()
        active = not active
        if active then
            toggleBtn.BackgroundColor3 = Config.AccentColor
            toggleBtn.Text = "ON"
        else
            toggleBtn.BackgroundColor3 = Color3.fromRGB(80,80,80)
            toggleBtn.Text = "OFF"
        end
        callback(active)
        State.Toggles[flag] = active
    end)
end

local function CreateSlider(parent, name, minV, maxV, default, flag, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -20, 0, Config.MobileMode and 70 or 60)
    frame.Position = UDim2.new(0, 10, 0, #parent:GetChildren() * (Config.MobileMode and 80 or 45) + 10)
    frame.BackgroundTransparency = 0.8
    frame.BackgroundColor3 = Color3.fromRGB(30,30,30)
    frame.BorderSizePixel = 0
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 6)
    c.Parent = frame
    frame.Parent = parent
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.6,0,0.4,0)
    label.Position = UDim2.new(0,10,0,0)
    label.BackgroundTransparency = 1
    label.Text = name .. ": " .. tostring(default)
    label.TextColor3 = Color3.fromRGB(255,255,255)
    label.Font = Enum.Font.Gotham
    label.TextSize = Config.MobileMode and 15 or 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame
    
    local slider = Instance.new("Frame")
    slider.Size = UDim2.new(0.75, 0, 0, Config.MobileMode and 12 or 8)
    slider.Position = UDim2.new(0,10,0.55,0)
    slider.BackgroundColor3 = Color3.fromRGB(60,60,60)
    slider.BorderSizePixel = 0
    local sCorner = Instance.new("UICorner")
    sCorner.CornerRadius = UDim.new(0, 4)
    sCorner.Parent = slider
    slider.Parent = frame
    
    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((default-minV)/(maxV-minV), 0, 1, 0)
    fill.BackgroundColor3 = Config.AccentColor
    fill.BorderSizePixel = 0
    local fCorner = Instance.new("UICorner")
    fCorner.CornerRadius = UDim.new(0, 4)
    fCorner.Parent = fill
    fill.Parent = slider
    
    local valueLabel = Instance.new("TextLabel")
    valueLabel.Size = UDim2.new(0.2,0,0.4,0)
    valueLabel.Position = UDim2.new(0.78,0,0,0)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = tostring(default)
    valueLabel.TextColor3 = Config.AccentColor
    valueLabel.Font = Enum.Font.GothamBold
    valueLabel.TextSize = Config.MobileMode and 15 or 14
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.Parent = frame
    
    local dragging = false
    local function update(input)
        local pos = math.clamp((input.Position.X - slider.AbsolutePosition.X) / slider.AbsoluteSize.X, 0, 1)
        local val = minV + (maxV-minV) * pos
        val = math.floor(val)
        fill.Size = UDim2.new(pos, 0, 1, 0)
        valueLabel.Text = tostring(val)
        label.Text = name .. ": " .. tostring(val)
        callback(val)
        State.Sliders[flag] = val
    end
    
    slider.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            update(input)
        end
    end)
    slider.InputEnded:Connect(function() dragging = false end)
    slider.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            update(input)
        end
    end)
end

local function CreateButton(parent, name, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -20, 0, Config.MobileMode and 45 or 35)
    btn.Position = UDim2.new(0, 10, 0, #parent:GetChildren() * (Config.MobileMode and 50 or 40) + 10)
    btn.BackgroundColor3 = Config.AccentColor
    btn.Text = name
    btn.TextColor3 = Color3.fromRGB(0,0,0)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = Config.MobileMode and 16 or 14
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 6)
    c.Parent = btn
    btn.Parent = parent
    btn.MouseButton1Click:Connect(callback)
end

local function CreateDropdown(parent, name, options, default, flag, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -20, 0, Config.MobileMode and 55 or 45)
    frame.Position = UDim2.new(0, 10, 0, #parent:GetChildren() * (Config.MobileMode and 60 or 45) + 10)
    frame.BackgroundTransparency = 0.8
    frame.BackgroundColor3 = Color3.fromRGB(30,30,30)
    frame.BorderSizePixel = 0
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 6)
    c.Parent = frame
    frame.Parent = parent
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.4,0,1,0)
    label.Position = UDim2.new(0,10,0,0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Color3.fromRGB(255,255,255)
    label.Font = Enum.Font.Gotham
    label.TextSize = Config.MobileMode and 15 or 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame
    
    local dropdownBtn = Instance.new("TextButton")
    dropdownBtn.Size = UDim2.new(0.45, 0, 0.7, 0)
    dropdownBtn.Position = UDim2.new(0.52, 0, 0.15, 0)
    dropdownBtn.BackgroundColor3 = Color3.fromRGB(50,50,50)
    dropdownBtn.Text = default
    dropdownBtn.TextColor3 = Color3.fromRGB(255,255,255)
    dropdownBtn.Font = Enum.Font.Gotham
    dropdownBtn.TextSize = Config.MobileMode and 13 or 12
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 4)
    btnCorner.Parent = dropdownBtn
    dropdownBtn.Parent = frame
    
    local listFrame = Instance.new("Frame")
    listFrame.Size = UDim2.new(0.45, 0, 0, 0)
    listFrame.Position = UDim2.new(0.52, 0, 0.85, 0)
    listFrame.BackgroundColor3 = Color3.fromRGB(40,40,40)
    listFrame.BackgroundTransparency = 0.1
    listFrame.Visible = false
    listFrame.ClipsDescendants = true
    local lCorner = Instance.new("UICorner")
    lCorner.CornerRadius = UDim.new(0, 4)
    lCorner.Parent = listFrame
    listFrame.Parent = frame
    
    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 2)
    listLayout.Parent = listFrame
    
    local function updateList()
        for _, ch in ipairs(listFrame:GetChildren()) do if ch:IsA("TextButton") then ch:Destroy() end end
        for _, opt in ipairs(options) do
            local optBtn = Instance.new("TextButton")
            optBtn.Size = UDim2.new(1,0,0, Config.MobileMode and 35 or 25)
            optBtn.BackgroundColor3 = Color3.fromRGB(50,50,50)
            optBtn.Text = opt
            optBtn.TextColor3 = Color3.fromRGB(255,255,255)
            optBtn.Font = Enum.Font.Gotham
            optBtn.TextSize = Config.MobileMode and 13 or 12
            optBtn.Parent = listFrame
            optBtn.MouseButton1Click:Connect(function()
                dropdownBtn.Text = opt
                listFrame.Visible = false
                frame.Size = UDim2.new(1, -20, 0, Config.MobileMode and 55 or 45)
                callback(opt)
                State.Dropdowns[flag] = opt
            end)
        end
        listFrame.Size = UDim2.new(0.45, 0, 0, #options * (Config.MobileMode and 37 or 27))
        frame.Size = UDim2.new(1, -20, 0, (Config.MobileMode and 55 or 45) + #options * (Config.MobileMode and 37 or 27))
    end
    
    dropdownBtn.MouseButton1Click:Connect(function()
        listFrame.Visible = not listFrame.Visible
        if listFrame.Visible then
            frame.Size = UDim2.new(1, -20, 0, (Config.MobileMode and 55 or 45) + #options * (Config.MobileMode and 37 or 27))
            updateList()
        else
            frame.Size = UDim2.new(1, -20, 0, Config.MobileMode and 55 or 45)
        end
    end)
end

local function CreateLabel(parent, text, color)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -20, 0, Config.MobileMode and 35 or 30)
    label.Position = UDim2.new(0, 10, 0, #parent:GetChildren() * (Config.MobileMode and 40 or 35) + 10)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = color or Color3.fromRGB(200,200,200)
    label.Font = Enum.Font.Gotham
    label.TextSize = Config.MobileMode and 14 or 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = parent
end

-- Build tabs
local mainC = tabs[1].content
CreateToggle(mainC, "Auto Farm Everything", "AutoFarm", function(v) State.Toggles.AutoFarm = v; if v then task.spawn(AutoFarmLoop) end end)
CreateToggle(mainC, "Auto Collect Loot", "AutoCollect", function(v) State.Toggles.AutoCollect = v end)
CreateToggle(mainC, "Auto Attack Slimes", "AutoAttack", function(v) State.Toggles.AutoAttack = v end)
CreateToggle(mainC, "Auto Kill Aura", "AutoKillAura", function(v) State.Toggles.AutoKillAura = v end)
CreateToggle(mainC, "Auto Equip Best Gear", "AutoEquip", function(v) State.Toggles.AutoEquipBest = v end)
CreateToggle(mainC, "Auto Rebirth", "AutoRebirth", function(v) State.Toggles.AutoRebirth = v end)
CreateToggle(mainC, "Auto Spin", "AutoSpin", function(v) State.Toggles.AutoSpin = v end)
CreateToggle(mainC, "Auto Quest", "AutoQuest", function(v) State.Toggles.AutoQuest = v; if v then task.spawn(QuestLoop) end end)
CreateToggle(mainC, "Auto Claim Rewards", "AutoClaim", function(v) State.Toggles.AutoClaimRewards = v end)
CreateToggle(mainC, "Auto Daily Rewards", "AutoDaily", function(v) State.Toggles.AutoDaily = v end)
CreateToggle(mainC, "Auto Event Rewards", "AutoEvent", function(v) State.Toggles.AutoEvent = v end)
CreateToggle(mainC, "Auto Craft", "AutoCraft", function(v) State.Toggles.AutoCraft = v; if v then task.spawn(CraftLoop) end end)

local farmC = tabs[2].content
CreateSlider(farmC, "Attack Range", 10, 100, 30, "AttackRange", function(v) State.Sliders.AttackRange = v end)
CreateSlider(farmC, "Collect Range", 10, 150, 40, "CollectRange", function(v) State.Sliders.CollectRange = v end)
CreateDropdown(farmC, "Attack Method", {"ClickDetector","Remote","Tool"}, "ClickDetector", "AttackMode", function(v) State.Dropdowns.AttackMode = v end)
CreateButton(farmC, "Farm All Slimes", function()
    for _, s in ipairs(Workspace:GetDescendants()) do
        if s:IsA("Model") and s.Name:lower():find("slime") then AttackSlime(s); task.wait() end
    end
    Notify("Farming", "Attacked all slimes", 2)
end)

local rngC = tabs[3].content
CreateToggle(rngC, "Auto Roll", "AutoRoll", function(v) State.Toggles.AutoRoll = v; if v then task.spawn(RollLoop) end end)
CreateToggle(rngC, "Fast Roll", "FastRoll", function(v) State.Toggles.FastRoll = v end)
CreateToggle(rngC, "Instant Roll", "InstantRoll", function(v) State.Toggles.InstantRoll = v end)
CreateSlider(rngC, "Roll Delay", 0.01, 0.5, 0.05, "RollDelay", function(v) State.Sliders.RollDelay = v end)
CreateToggle(rngC, "Rare Aura Detection + ESP", "RareAura", function(v) State.Toggles.AutoSaveRares = v end)
CreateButton(rngC, "Show Roll Stats", function()
    Notify("Roll Stats", string.format("Total: %d | Rare: %d | Best: %s", State.Stats.Rolls, State.Stats.RareRolls, State.Stats.RarestAura), 5)
end)

local upsC = tabs[4].content
CreateToggle(upsC, "Auto Buy Potions", "AutoPotions", function(v) State.Toggles.AutoBuyPotions = v end)
CreateToggle(upsC, "Auto Upgrade Luck", "AutoLuckUp", function(v) State.Toggles.AutoUpgradeLuck = v end)
CreateToggle(upsC, "Auto Upgrade Speed", "AutoSpeedUp", function(v) State.Toggles.AutoUpgradeSpeed = v end)
CreateToggle(upsC, "Auto Upgrade Storage", "AutoStorageUp", function(v) State.Toggles.AutoUpgradeStorage = v end)
CreateToggle(upsC, "Auto Upgrade Damage", "AutoDamageUp", function(v) State.Toggles.AutoUpgradeDamage = v end)
CreateToggle(upsC, "Auto All Upgrades", "AutoAllUp", function(v) State.Toggles.AutoUpgrade = v; if v then task.spawn(UpgradeLoop) end end)

local teleC = tabs[5].content
local points = {Spawn=Vector3.new(0,10,0), SlimeForest=Vector3.new(100,20,50), RNGShrine=Vector3.new(-80,15,-30), UpgradeArea=Vector3.new(200,10,200), EventZone=Vector3.new(-150,25,-100)}
for name, pos in pairs(points) do
    CreateButton(teleC, "Teleport to " .. name, function() TeleportTo(pos); Notify("Teleport", name, 2) end)
end
CreateButton(teleC, "Save Current Pos", function()
    local ch = LocalPlayer.Character
    if ch and ch:FindFirstChild("HumanoidRootPart") then
        points.Custom = ch.HumanoidRootPart.Position
        Notify("Saved", "Custom teleport added", 2)
    end
end)

local playerC = tabs[6].content
CreateSlider(playerC, "WalkSpeed", 16, 250, 16, "WalkSpeed", function(v) State.Sliders.WalkSpeed = v; WalkSpeedUpdate() end)
CreateSlider(playerC, "JumpPower", 50, 200, 50, "JumpPower", function(v) State.Sliders.JumpPower = v; JumpPowerUpdate() end)
CreateToggle(playerC, "Fly", "Fly", function(v) State.Toggles.Fly = v; FlyUpdate() end)
CreateToggle(playerC, "Noclip", "Noclip", function(v) State.Toggles.Noclip = v; NoclipUpdate() end)
CreateToggle(playerC, "Infinite Jump", "InfiniteJump", function(v) State.Toggles.InfiniteJump = v; InfiniteJumpUpdate() end)
CreateToggle(playerC, "Anti AFK", "AntiAFK", function(v) State.Toggles.AntiAFK = v; if v then task.spawn(AntiAFKLoop) end end)

local visualC = tabs[7].content
CreateToggle(visualC, "FPS Boost", "FPSBoost", function(v) State.Toggles.FPSBoost = v end)
CreateToggle(visualC, "Remove Effects", "RemoveEffects", function(v) State.Toggles.RemoveEffects = v end)
CreateToggle(visualC, "Disable Particles", "DisableParticles", function(v) State.Toggles.DisableParticles = v end)
CreateToggle(visualC, "Low Graphics", "LowGraphics", function(v) State.Toggles.LowGraphics = v end)
CreateToggle(visualC, "Remove Shadows", "RemoveShadows", function(v) State.Toggles.RemoveShadows = v end)
CreateToggle(visualC, "Potato Mode", "PotatoMode", function(v) State.Toggles.PotatoMode = v end)
CreateButton(visualC, "Apply All Optimizations", function()
    State.Toggles.FPSBoost = true; State.Toggles.RemoveEffects = true; State.Toggles.DisableParticles = true
    State.Toggles.LowGraphics = true; State.Toggles.RemoveShadows = true
    Notify("Optimization", "All boosts applied", 2)
end)

local settingsC = tabs[8].content
CreateToggle(settingsC, "Rainbow Accent", "RainbowAccent", function(v)
    State.Toggles.RainbowAccent = v
    if v then
        task.spawn(function()
            while State.Toggles.RainbowAccent do
                local hue = tick() % 2 / 2
                Config.AccentColor = Color3.fromHSV(hue, 1, 1)
                stroke.Color = Config.AccentColor
                for _, t in ipairs(tabs) do
                    if t.content.Visible then t.btn.TextColor3 = Config.AccentColor end
                end
                task.wait(0.05)
            end
        end)
    end
end)
CreateButton(settingsC, "Save Config", function()
    local data = HttpService:JSONEncode(State)
    writefile("SlimeRNG_Config.json", data)
    Notify("Saved", "Configuration saved", 2)
end)
CreateButton(settingsC, "Load Config", function()
    if isfile("SlimeRNG_Config.json") then
        local data = readfile("SlimeRNG_Config.json")
        local loaded = HttpService:JSONDecode(data)
        for k,v in pairs(loaded.Toggles) do State.Toggles[k] = v end
        Notify("Loaded", "Settings restored", 2)
    else
        Notify("Error", "No config found", 2)
    end
end)
CreateButton(settingsC, "Reset All", function()
    for k in pairs(State.Toggles) do State.Toggles[k] = false end
    State.Sliders.WalkSpeed = 16; State.Sliders.JumpPower = 50
    Notify("Reset", "All settings reset", 2)
end)

local credC = tabs[9].content
CreateLabel(credC, "Slime RNG Premium Hub", Config.AccentColor)
CreateLabel(credC, "Version 7.0 | Mobile + PC")
CreateLabel(credC, "Developer: Elite R&D Team")
CreateLabel(credC, "Game: Slime RNG (Stouts Studio)")
CreateLabel(credC, "Executors: Delta, Fluxus, Arceus X, Hydrogen, Codex")
CreateButton(credC, "Copy Discord", function() setclipboard("discord.gg/slimehub"); Notify("Copied", "Discord invite copied", 2) end)

-- Dragging (touch support)
local dragStartPos, dragFrameStart
titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStartPos = input.Position
        dragFrameStart = mainFrame.Position
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStartPos
        mainFrame.Position = UDim2.new(dragFrameStart.X.Scale, dragFrameStart.X.Offset + delta.X, dragFrameStart.Y.Scale, dragFrameStart.Y.Offset + delta.Y)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

local minimized = false
minimizeBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        mainFrame.Size = UDim2.new(0, Config.MobileMode and 380 or 450, 0, Config.MobileMode and 45 or 40)
        contentContainer.Visible = false
        tabContainer.Visible = false
        minimizeBtn.Text = "+"
    else
        mainFrame.Size = UDim2.new(0, Config.MobileMode and 380 or 450, 0, Config.MobileMode and 500 or 550)
        contentContainer.Visible = true
        tabContainer.Visible = true
        minimizeBtn.Text = "−"
    end
end)

closeBtn.MouseButton1Click:Connect(function()
    screenGui.Enabled = false
    Notify("Slime RNG Hub", "UI hidden. Press Insert to show.", 3)
end)

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode[Config.ToggleKey] then
        screenGui.Enabled = not screenGui.Enabled
        if screenGui.Enabled then Notify("Hub", "UI shown", 1) end
    elseif input.KeyCode == Enum.KeyCode[Config.MinimizeKey] then
        minimized = not minimized
        if minimized then
            mainFrame.Size = UDim2.new(0, Config.MobileMode and 380 or 450, 0, Config.MobileMode and 45 or 40)
            contentContainer.Visible = false
            tabContainer.Visible = false
            minimizeBtn.Text = "+"
        else
            mainFrame.Size = UDim2.new(0, Config.MobileMode and 380 or 450, 0, Config.MobileMode and 500 or 550)
            contentContainer.Visible = true
            tabContainer.Visible = true
            minimizeBtn.Text = "−"
        end
    end
end)

if Config.Watermark then
    local wm = Instance.new("Frame")
    wm.Size = UDim2.new(0, 210, 0, 30)
    wm.Position = UDim2.new(0, 10, 1, -40)
    wm.BackgroundTransparency = 0.5
    wm.BackgroundColor3 = Color3.fromRGB(0,0,0)
    wm.BorderSizePixel = 0
    local wmCorner = Instance.new("UICorner")
    wmCorner.CornerRadius = UDim.new(0, 8)
    wmCorner.Parent = wm
    wm.Parent = screenGui
    local wmText = Instance.new("TextLabel")
    wmText.Size = UDim2.new(1,0,1,0)
    wmText.BackgroundTransparency = 1
    wmText.Text = "Slime RNG Hub | Mobile/PC 2026"
    wmText.TextColor3 = Config.AccentColor
    wmText.Font = Enum.Font.GothamBold
    wmText.TextSize = Config.MobileMode and 12 or 14
    wmText.Parent = wm
end

task.spawn(VisualOptimizations)
task.spawn(ESPLoop)

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    WalkSpeedUpdate()
    JumpPowerUpdate()
    NoclipUpdate()
    FlyUpdate()
    if State.Toggles.AutoFarm then task.spawn(AutoFarmLoop) end
    if State.Toggles.AutoRoll then task.spawn(RollLoop) end
    if State.Toggles.AutoUpgrade then task.spawn(UpgradeLoop) end
    Notify("Reconnected", "Modules restarted", 2)
end)

RunService.Heartbeat:Connect(function()
    if not LocalPlayer or not LocalPlayer.Character then return end
    pcall(function()
        if State.Toggles.Noclip then NoclipUpdate() end
        if State.Toggles.Fly then FlyUpdate() end
    end)
end)

Notify("Slime RNG Hub", "Loaded! Press Insert to open | Mobile supported", 5)
print("Slime RNG Premium Hub v7.0 | Mobile + PC Ready")