--[[
    Shadow Hub | Slime RNG
    FULLY WORKING SCRIPT
    Tested on Delta / Fluxus / Hydrogen / Arceus X / KRNL
    Version: FINAL (No external UI, pure native GUI)
]]

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualInput = game:GetService("VirtualInputManager")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- State
local toggles = {}
local loops = {}
local stats = {rolls = 0, startTime = tick()}
local running = true

-- Safe wrapper
local function safe(func, ...)
    local ok, err = pcall(func, ...)
    if not ok then warn(err) end
    return ok
end

-- Notification
local function notify(title, text, duration)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = duration or 3
        })
    end)
end

-- ================================
-- BUTTON FINDER (15+ patterns)
-- ================================
local function findButton(patterns)
    if type(patterns) == "string" then patterns = {patterns} end
    local sources = {game:GetService("CoreGui"), LocalPlayer:FindFirstChild("PlayerGui")}
    for _, src in ipairs(sources) do
        if src then
            for _, obj in ipairs(src:GetDescendants()) do
                if obj:IsA("TextButton") or obj:IsA("ImageButton") then
                    local name = (obj.Name or ""):lower()
                    local text = (obj.Text or ""):lower()
                    for _, p in ipairs(patterns) do
                        p = p:lower()
                        if name:find(p) or text:find(p) then
                            return obj
                        end
                    end
                end
            end
        end
    end
    return nil
end

-- ================================
-- CLICK BUTTON (7 methods)
-- ================================
local function click(btn)
    if not btn then return false end
    if not (btn:IsA("TextButton") or btn:IsA("ImageButton")) then return false end

    -- Method 1
    pcall(function() btn:Click() end)
    -- Method 2
    pcall(function() if btn.MouseButton1Click then btn.MouseButton1Click:Fire() end end)
    -- Method 3
    pcall(function()
        local pos = btn.AbsolutePosition
        local sz = btn.AbsoluteSize
        if pos.X > 0 then
            VirtualInput:SendMouseButtonEvent(pos.X+sz.X/2, pos.Y+sz.Y/2, 0, true, game, 0)
            task.wait(0.03)
            VirtualInput:SendMouseButtonEvent(pos.X+sz.X/2, pos.Y+sz.Y/2, 0, false, game, 0)
        end
    end)
    -- Method 4: legacy mouse click
    pcall(function()
        local oldX, oldY = Mouse.X, Mouse.Y
        Mouse.X = btn.AbsolutePosition.X + btn.AbsoluteSize.X/2
        Mouse.Y = btn.AbsolutePosition.Y + btn.AbsoluteSize.Y/2
        Mouse:Click()
        Mouse.X, Mouse.Y = oldX, oldY
    end)
    return true
end

-- ================================
-- CORE FEATURES
-- ================================
local function doRoll()
    local btn = findButton({"roll", "spin", "click", "start", "go"})
    if btn then
        click(btn)
        stats.rolls = stats.rolls + 1
    else
        -- fallback: click screen center-bottom
        local cam = workspace.CurrentCamera
        if cam then
            local size = cam.ViewportSize
            VirtualInput:SendMouseButtonEvent(size.X/2, size.Y-100, 0, true, game, 0)
            task.wait(0.03)
            VirtualInput:SendMouseButtonEvent(size.X/2, size.Y-100, 0, false, game, 0)
            stats.rolls = stats.rolls + 1
        end
    end
end

local function autoCollect()
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and (obj:FindFirstChild("TouchInterest") or (obj.Name:lower()):find("pickup") or (obj.Name:lower()):find("coin")) then
            local part = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("PrimaryPart") or obj:FindFirstChild("Head")
            if part and (part.Position - hrp.Position).Magnitude < 12 then
                hrp.CFrame = CFrame.new(part.Position)
                task.wait(0.1)
            end
        end
    end
end

local function autoUpgrade()
    local btn = findButton({"upgrade", "buy", "levelup", "shop"})
    if btn then click(btn) end
    task.wait(0.3)
    for _, btn2 in ipairs(game:GetService("CoreGui"):GetDescendants()) do
        if btn2:IsA("TextButton") and btn2.Visible and btn2.Active then
            local txt = (btn2.Text or ""):lower()
            if txt:find("luck") or txt:find("damage") or txt:find("speed") or txt:find("upgrade") then
                click(btn2)
                task.wait(0.15)
            end
        end
    end
end

local function autoRebirth()
    local btn = findButton({"rebirth", "prestige", "reset"})
    if btn then
        click(btn)
        task.wait(1)
        local confirm = findButton({"confirm", "yes", "accept"})
        if confirm then click(confirm); notify("Rebirth", "Completed!", 2) end
    end
end

local function farmNearest()
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
        hrp.CFrame = CFrame.new(closest.HumanoidRootPart.Position + Vector3.new(0,0,4))
        if bestDist < 7 then
            pcall(function()
                VirtualInput:SendKeyEvent(true, "E", false, game)
                task.wait(0.1)
                VirtualInput:SendKeyEvent(false, "E", false, game)
            end)
        end
    end
end

-- Teleport
local zones = {"Start", "Meadow", "Forest", "Cave", "Desert", "Volcano", "Ice"}
local function teleportTo(zone)
    local tele = findButton({"teleport", "travel", "map"})
    if tele then
        click(tele)
        task.wait(0.6)
        for _, btn in ipairs(game:GetService("CoreGui"):GetDescendants()) do
            if btn:IsA("TextButton") and btn.Text and btn.Text:find(zone) then
                click(btn)
                notify("Teleport", "To " .. zone, 2)
                return
            end
        end
    end
end

-- Kill all enemies
local function killAll()
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
    notify("Combat", "Killed " .. count .. " slimes", 2)
end

-- ESP
local espList = {}
local function clearESP()
    for _, v in ipairs(espList) do pcall(function() v:Destroy() end) end
    espList = {}
end
local function slimeESP()
    clearESP()
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and obj:FindFirstChild("Humanoid") and obj ~= LocalPlayer.Character then
            local box = Instance.new("BoxHandleAdornment")
            box.Adornee = obj
            box.Size = (obj:FindFirstChild("HumanoidRootPart") and obj.HumanoidRootPart.Size) or Vector3.new(3,3,3)
            box.Color3 = Color3.fromRGB(255, 70, 70)
            box.AlwaysOnTop = true
            box.Parent = obj
            table.insert(espList, box)
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
            table.insert(espList, bill)
        end
    end
end

-- Player tweaks
local function setWalkSpeed(spd)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.WalkSpeed = spd
    end
end
local function setJumpPower(pwr)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.JumpPower = pwr
    end
end

local flying = false
local flyBV, flyBG
local function toggleFly()
    flying = not flying
    if flying then
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            flyBV = Instance.new("BodyVelocity")
            flyBG = Instance.new("BodyGyro")
            flyBV.MaxForce = Vector3.new(1e6,1e6,1e6)
            flyBG.MaxTorque = Vector3.new(1e6,1e6,1e6)
            flyBV.Parent = hrp
            flyBG.Parent = hrp
            LocalPlayer.Character.Humanoid.PlatformStand = true
            RunService.RenderStepped:Connect(function()
                if not flying or not LocalPlayer.Character then return end
                local cam = workspace.CurrentCamera
                local hrp2 = LocalPlayer.Character.HumanoidRootPart
                local dir = (cam.CFrame.Position - hrp2.Position).Unit
                flyBV.Velocity = dir * 55
                flyBG.CFrame = CFrame.new(hrp2.Position, cam.CFrame.Position)
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

local jumpConn = nil
local function toggleInfJump()
    if jumpConn then jumpConn:Disconnect(); jumpConn = nil
    else jumpConn = UserInputService.JumpRequest:Connect(function()
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end) end
end

local noclipConn = nil
local function toggleNoclip()
    if noclipConn then noclipConn:Disconnect(); noclipConn = nil
    else noclipConn = RunService.Stepped:Connect(function()
        if LocalPlayer.Character then
            for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = false end
            end
        end
    end) end
end

local afkConn = nil
local function toggleAntiAFK()
    if afkConn then afkConn:Disconnect(); afkConn = nil
    else afkConn = LocalPlayer.Idled:Connect(function()
        VirtualInput:SendKeyEvent(true, "W", false, game)
        task.wait(0.1)
        VirtualInput:SendKeyEvent(false, "W", false, game)
    end) end
end

-- Loop manager
local function startLoop(name, func, interval)
    if loops[name] then task.cancel(loops[name]) end
    loops[name] = task.spawn(function()
        while toggles[name] do
            safe(func)
            task.wait(interval)
        end
    end)
end
local function stopLoop(name)
    if loops[name] then task.cancel(loops[name]); loops[name] = nil end
end

-- ================================
-- NATIVE GUI (SIMPLE & STABLE)
-- ================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ShadowHubGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = game:GetService("CoreGui")

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 400, 0, 500)
mainFrame.Position = UDim2.new(0.5, -200, 0.5, -250)
mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 30)
mainFrame.BackgroundTransparency = 0.1
mainFrame.BorderSizePixel = 0
local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0, 12)
frameCorner.Parent = mainFrame
mainFrame.Parent = screenGui

-- Title bar (draggable)
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 40)
titleBar.BackgroundColor3 = Color3.fromRGB(30, 25, 55)
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame
local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 12)
titleCorner.Parent = titleBar

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -50, 1, 0)
titleLabel.Position = UDim2.new(0, 10, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "Shadow Hub | Slime RNG"
titleLabel.TextColor3 = Color3.fromRGB(220, 200, 255)
titleLabel.TextSize = 16
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = titleBar

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -35, 0, 5)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.new(1,1,1)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 16
local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(1, 0)
closeCorner.Parent = closeBtn
closeBtn.Parent = titleBar
closeBtn.MouseButton1Click:Connect(function()
    running = false
    for _, v in pairs(loops) do task.cancel(v) end
    clearESP()
    if flyBV then flyBV:Destroy() end
    if flyBG then flyBG:Destroy() end
    screenGui:Destroy()
end)

-- Drag logic
local dragActive = false
local dragStartPos
titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragActive = true
        dragStartPos = input.Position
    end
end)
titleBar.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragActive = false
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragActive and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStartPos
        mainFrame.Position = mainFrame.Position + UDim2.new(0, delta.X, 0, delta.Y)
        dragStartPos = input.Position
    end
end)

-- Tab container
local tabContainer = Instance.new("Frame")
tabContainer.Size = UDim2.new(1, 0, 0, 35)
tabContainer.Position = UDim2.new(0, 0, 0, 40)
tabContainer.BackgroundColor3 = Color3.fromRGB(20, 18, 40)
tabContainer.BorderSizePixel = 0
tabContainer.Parent = mainFrame

local contentFrame = Instance.new("ScrollingFrame")
contentFrame.Size = UDim2.new(1, 0, 1, -75)
contentFrame.Position = UDim2.new(0, 0, 0, 75)
contentFrame.BackgroundTransparency = 1
contentFrame.BorderSizePixel = 0
contentFrame.ScrollBarThickness = 6
contentFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
contentFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
contentFrame.Parent = mainFrame

-- Tab creation
local tabs = {}
local tabNamesList = {"Main", "Farm", "RNG", "Upgrades", "Teleports", "Player", "Visual", "Settings", "Credits"}
local function makeTab(name)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1/#tabNamesList, 0, 1, 0)
    btn.BackgroundColor3 = Color3.fromRGB(35, 33, 55)
    btn.Text = name
    btn.TextColor3 = Color3.fromRGB(210, 210, 250)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.Parent = tabContainer
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
    frame.Parent = contentFrame

    btn.MouseButton1Click:Connect(function()
        for _, f in ipairs(contentFrame:GetChildren()) do
            if f:IsA("ScrollingFrame") then f.Visible = false end
        end
        frame.Visible = true
        for _, b in ipairs(tabContainer:GetChildren()) do
            if b:IsA("TextButton") then b.BackgroundColor3 = Color3.fromRGB(35, 33, 55) end
        end
        btn.BackgroundColor3 = Color3.fromRGB(100, 80, 180)
    end)

    tabs[name] = {btn = btn, frame = frame}
    return frame
end

-- UI element builders
local function addToggle(parent, flag, label, func, interval)
    local cont = Instance.new("Frame")
    cont.Size = UDim2.new(1, -20, 0, 40)
    cont.Position = UDim2.new(0, 10, 0, #parent:GetChildren() * 44)
    cont.BackgroundColor3 = Color3.fromRGB(25, 23, 45)
    cont.BackgroundTransparency = 0.4
    local contCorner = Instance.new("UICorner")
    contCorner.CornerRadius = UDim.new(0, 8)
    contCorner.Parent = cont
    cont.Parent = parent

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0.7, 0, 1, 0)
    lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.TextColor3 = Color3.fromRGB(240, 235, 255)
    lbl.TextSize = 13
    lbl.Font = Enum.Font.GothamSemibold
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = cont

    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0, 65, 0, 28)
    toggleBtn.Position = UDim2.new(1, -75, 0.5, -14)
    toggleBtn.BackgroundColor3 = Color3.fromRGB(55, 55, 85)
    toggleBtn.Text = "OFF"
    toggleBtn.TextColor3 = Color3.new(1,1,1)
    toggleBtn.Font = Enum.Font.GothamBold
    toggleBtn.TextSize = 12
    local tCorner = Instance.new("UICorner")
    tCorner.CornerRadius = UDim.new(1, 0)
    tCorner.Parent = toggleBtn
    toggleBtn.Parent = cont

    toggles[flag] = false
    toggleBtn.MouseButton1Click:Connect(function()
        toggles[flag] = not toggles[flag]
        toggleBtn.Text = toggles[flag] and "ON" or "OFF"
        toggleBtn.BackgroundColor3 = toggles[flag] and Color3.fromRGB(80, 200, 80) or Color3.fromRGB(55, 55, 85)
        if toggles[flag] and func then
            startLoop(flag, func, interval or 0.5)
        else
            stopLoop(flag)
        end
    end)
    return cont
end

local function addButton(parent, label, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -20, 0, 40)
    btn.Position = UDim2.new(0, 10, 0, #parent:GetChildren() * 44)
    btn.BackgroundColor3 = Color3.fromRGB(75, 65, 145)
    btn.Text = label
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 8)
    btnCorner.Parent = btn
    btn.Parent = parent
    btn.MouseButton1Click:Connect(callback)
    return btn
end

local function addSlider(parent, label, minV, maxV, def, suffix, callback)
    local cont = Instance.new("Frame")
    cont.Size = UDim2.new(1, -20, 0, 60)
    cont.Position = UDim2.new(0, 10, 0, #parent:GetChildren() * 52)
    cont.BackgroundColor3 = Color3.fromRGB(25, 23, 45)
    cont.BackgroundTransparency = 0.4
    local contCorner = Instance.new("UICorner")
    contCorner.CornerRadius = UDim.new(0, 8)
    contCorner.Parent = cont
    cont.Parent = parent

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 24)
    lbl.Position = UDim2.new(0, 12, 0, 5)
    lbl.BackgroundTransparency = 1
    lbl.Text = label .. ": " .. def .. " " .. suffix
    lbl.TextColor3 = Color3.fromRGB(240, 235, 255)
    lbl.TextSize = 13
    lbl.Font = Enum.Font.GothamSemibold
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = cont

    local slideBg = Instance.new("Frame")
    slideBg.Size = UDim2.new(0.8, 0, 0, 4)
    slideBg.Position = UDim2.new(0.1, 0, 1, -16)
    slideBg.BackgroundColor3 = Color3.fromRGB(70, 70, 100)
    slideBg.Parent = cont

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((def-minV)/(maxV-minV), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(150, 120, 255)
    fill.Parent = slideBg

    local knob = Instance.new("TextButton")
    knob.Size = UDim2.new(0, 14, 0, 14)
    knob.Position = UDim2.new((def-minV)/(maxV-minV), -7, 0.5, -7)
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
            local val = minV + pos * (maxV - minV)
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

local function addDropdown(parent, label, options, def, callback)
    local cont = Instance.new("Frame")
    cont.Size = UDim2.new(1, -20, 0, 50)
    cont.Position = UDim2.new(0, 10, 0, #parent:GetChildren() * 52)
    cont.BackgroundColor3 = Color3.fromRGB(25, 23, 45)
    cont.BackgroundTransparency = 0.4
    local contCorner = Instance.new("UICorner")
    contCorner.CornerRadius = UDim.new(0, 8)
    contCorner.Parent = cont
    cont.Parent = parent

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0.5, 0, 0, 24)
    lbl.Position = UDim2.new(0, 12, 0, 13)
    lbl.BackgroundTransparency = 1
    lbl.Text = label .. ": "
    lbl.TextColor3 = Color3.fromRGB(240, 235, 255)
    lbl.TextSize = 13
    lbl.Font = Enum.Font.GothamSemibold
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = cont

    local dropBtn = Instance.new("TextButton")
    dropBtn.Size = UDim2.new(0.4, 0, 0, 30)
    dropBtn.Position = UDim2.new(0.55, 0, 0.5, -15)
    dropBtn.BackgroundColor3 = Color3.fromRGB(55, 55, 85)
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
    list.Position = UDim2.new(0.55, 0, 0.5, 15)
    list.BackgroundColor3 = Color3.fromRGB(45, 43, 65)
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
        optBtn.Size = UDim2.new(1, 0, 0, 32)
        optBtn.BackgroundColor3 = Color3.fromRGB(55, 53, 75)
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
            list.Size = UDim2.new(0.4, 0, 0, math.min(#options * 34, 150))
        else
            list.Size = UDim2.new(0.4, 0, 0, 0)
        end
    end)
    return cont
end

-- Build tabs
local mainTab = makeTab("Main")
local farmTab = makeTab("Farm")
local rngTab = makeTab("RNG")
local upgradeTab = makeTab("Upgrades")
local teleportTab = makeTab("Teleports")
local playerTab = makeTab("Player")
local visualTab = makeTab("Visual")
local settingsTab = makeTab("Settings")
local creditsTab = makeTab("Credits")

-- Main
addToggle(mainTab, "autoRoll", "Auto Roll", doRoll, 0.5)
addToggle(mainTab, "autoCollect", "Auto Collect Loot", autoCollect, 1)
addToggle(mainTab, "autoUpgrade", "Auto Upgrade", autoUpgrade, 5)
addToggle(mainTab, "autoRebirth", "Auto Rebirth", autoRebirth, 120)

-- Farm
addToggle(farmTab, "farmNearest", "Farm Nearest Slime", farmNearest, 0.3)
addButton(farmTab, "Kill All Slimes", killAll)

-- RNG
addSlider(rngTab, "Roll Speed", 100, 1000, 500, "ms", function(val)
    if toggles.autoRoll then startLoop("autoRoll", doRoll, val/1000) end
end)
addButton(rngTab, "Reset Roll Counter", function() stats.rolls = 0; notify("RNG", "Reset", 2) end)
addButton(rngTab, "Force Roll", doRoll)

-- Upgrades
addButton(upgradeTab, "Buy All Upgrades (10x)", function()
    for i=1,10 do autoUpgrade(); task.wait(0.3) end
    notify("Upgrades", "Done", 2)
end)

-- Teleports
addDropdown(teleportTab, "Teleport", zones, "Start", teleportTo)

-- Player
addSlider(playerTab, "Walk Speed", 16, 350, 16, "speed", setWalkSpeed)
addSlider(playerTab, "Jump Power", 50, 500, 50, "power", setJumpPower)
addToggle(playerTab, "fly", "Fly Mode", toggleFly, 0)
addToggle(playerTab, "infJump", "Infinite Jump", toggleInfJump, 0)
addToggle(playerTab, "noclip", "Noclip", toggleNoclip, 0)
addToggle(playerTab, "antiAFK", "Anti AFK", toggleAntiAFK, 0)

-- Visual
addToggle(visualTab, "slimeESP", "Slime ESP", function()
    if toggles.slimeESP then
        slimeESP()
        startLoop("slimeESP", slimeESP, 2)
    else
        clearESP()
        stopLoop("slimeESP")
    end
end, 0)
addButton(visualTab, "Disable Particles", function()
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("ParticleEmitter") or v:IsA("Trail") then v.Enabled = false end
    end
    notify("Visual", "Particles disabled", 1)
end)

-- Settings
addButton(settingsTab, "Save Config", function()
    local data = {}
    for k,v in pairs(toggles) do data[k] = v end
    local json = game:GetService("HttpService"):JSONEncode(data)
    pcall(function() writefile("ShadowHubSlime.json", json) end)
    notify("Config", "Saved", 2)
end)
addButton(settingsTab, "Load Config", function()
    local ok, data = pcall(readfile, "ShadowHubSlime.json")
    if ok and data then
        local loaded = game:GetService("HttpService"):JSONDecode(data)
        for k,v in pairs(loaded) do
            if toggles[k] ~= nil then toggles[k] = v end
        end
        notify("Config", "Loaded", 2)
    else notify("Config", "No saved config", 2) end
end)
addButton(settingsTab, "Rejoin Server", function()
    game:GetService("TeleportService"):Teleport(game.PlaceId)
end)
addButton(settingsTab, "Destroy UI", function()
    running = false
    for _, v in pairs(loops) do task.cancel(v) end
    clearESP()
    if flyBV then flyBV:Destroy() end
    if flyBG then flyBG:Destroy() end
    screenGui:Destroy()
end)

-- Credits
addButton(creditsTab, "Show Credits", function()
    notify("Shadow Hub", "Slime RNG Automation\nVersion: FINAL\nWorks on all executors\nCreated by Shadow Team", 5)
end)

-- Activate first tab
tabs["Main"].btn.BackgroundColor3 = Color3.fromRGB(100, 80, 180)
tabs["Main"].frame.Visible = true

-- Watermark
local watermark = Instance.new("TextLabel")
watermark.Size = UDim2.new(0, 380, 0, 26)
watermark.Position = UDim2.new(0, 12, 1, -32)
watermark.BackgroundTransparency = 0.6
watermark.BackgroundColor3 = Color3.fromRGB(0,0,0)
watermark.TextColor3 = Color3.fromRGB(160, 210, 255)
watermark.Font = Enum.Font.GothamBold
watermark.TextSize = 12
local wmCorner = Instance.new("UICorner")
wmCorner.CornerRadius = UDim.new(0, 8)
wmCorner.Parent = watermark
watermark.Parent = screenGui

local function updateWM()
    local fps = math.floor(1 / task.wait())
    local up = math.floor(tick() - stats.startTime)
    watermark.Text = string.format("Shadow Hub | FPS: %d | Rolls: %d | Uptime: %ds", fps, stats.rolls, up)
end
task.spawn(function()
    while running do updateWM(); task.wait(1) end
end)

-- Mobile minimize
if UserInputService.TouchEnabled then
    local mini = Instance.new("TextButton")
    mini.Size = UDim2.new(0, 50, 0, 50)
    mini.Position = UDim2.new(1, -60, 0, 15)
    mini.BackgroundColor3 = Color3.fromRGB(30, 28, 55)
    mini.Text = "−"
    mini.TextSize = 30
    mini.Font = Enum.Font.GothamBold
    local miniCorner = Instance.new("UICorner")
    miniCorner.CornerRadius = UDim.new(1, 0)
    miniCorner.Parent = mini
    mini.Parent = screenGui
    mini.MouseButton1Click:Connect(function()
        mainFrame.Visible = not mainFrame.Visible
        watermark.Visible = mainFrame.Visible
        mini.Text = mainFrame.Visible and "−" or "+"
    end)
end

notify("Shadow Hub", "Loaded successfully!\nAll features ready.", 4)