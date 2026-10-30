-- RT3_Hub_v11.lua
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local LocalPlayer = Players.LocalPlayer

if game.PlaceId ~= 119048529960596 then
    return warn("[hub] Bukan Restaurant Tycoon 3")
end

-- UI Setup
local gui = Instance.new("ScreenGui")
gui.Name = "RT3Hub_" .. math.random(1e5)
gui.ResetOnSpawn = false
gui.Parent = (gethui and gethui()) or game:GetService("CoreGui")

-- Main Frame
local main = Instance.new("Frame")
main.Size = UDim2.new(0, 220, 0, 360)
main.Position = UDim2.new(0, 20, 0, 50)
main.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
main.BorderSizePixel = 0
main.Active = true
main.Draggable = true
main.Parent = gui

-- Title Bar
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -30, 0, 30)
title.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
title.Text = "RT3 Blink & Farm v11"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.Parent = main

-- Minimize Button
local minBtn = Instance.new("TextButton")
minBtn.Size = UDim2.new(0, 30, 0, 30)
minBtn.Position = UDim2.new(1, -30, 0, 0)
minBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
minBtn.Text = "-"
minBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
minBtn.Font = Enum.Font.GothamBold
minBtn.TextSize = 20
minBtn.Parent = main

-- Content Frame
local content = Instance.new("Frame")
content.Size = UDim2.new(1, 0, 1, -30)
content.Position = UDim2.new(0, 0, 0, 30)
content.BackgroundTransparency = 1
content.Parent = main

local isMinimized = false
minBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    if isMinimized then
        content.Visible = false
        main.Size = UDim2.new(0, 220, 0, 30)
        minBtn.Text = "+"
        minBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
    else
        content.Visible = true
        main.Size = UDim2.new(0, 220, 0, 360)
        minBtn.Text = "-"
        minBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    end
end)

local yPos = 10
local function createToggle(text, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -20, 0, 40)
    btn.Position = UDim2.new(0, 10, 0, yPos)
    btn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    btn.Text = text .. " [OFF]"
    btn.TextColor3 = Color3.fromRGB(200, 200, 200)
    btn.Font = Enum.Font.Gotham
    btn.BorderSizePixel = 0
    btn.Parent = content
    yPos = yPos + 45
    
    local c = Instance.new("UICorner", btn)
    c.CornerRadius = UDim.new(0, 6)
    
    local isOn = false
    btn.MouseButton1Click:Connect(function()
        isOn = not isOn
        if isOn then
            btn.Text = text .. " [ON]"
            btn.BackgroundColor3 = Color3.fromRGB(60, 150, 60)
            callback(true)
        else
            btn.Text = text .. " [OFF]"
            btn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
            callback(false)
        end
    end)
end

-- 1. AUTO BLINK INTERACT (Jeda 3 Detik)
local blinkLoop = nil
createToggle("Auto Blink (3s Delay)", function(state)
    if state then
        blinkLoop = task.spawn(function()
            while state do
                local char = LocalPlayer.Character
                if char then
                    local hrp = char:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        local found = false
                        for _, obj in pairs(workspace:GetDescendants()) do
                            if obj:IsA("ProximityPrompt") and obj.Enabled then
                                local action = string.lower(obj.ActionText)
                                local name = string.lower(obj.Name)
                                
                                -- Filter sampah, toko, pintu
                                local isBlacklisted = string.find(action, "r%$") or action == "locked" or action == "view" or action == "chat" or action == "follow event"
                                local isDoor = (name == "doorprompt")

                                if not isBlacklisted and not isDoor then
                                    local parent = obj.Parent
                                    local targetPos = nil

                                    if parent:IsA("BasePart") then targetPos = parent.Position
                                    elseif parent:IsA("Attachment") then targetPos = parent.WorldPosition
                                    elseif parent:IsA("Model") and parent.PrimaryPart then targetPos = parent.PrimaryPart.Position
                                    elseif parent:IsA("Model") then targetPos = parent:GetPivot().Position end

                                    if targetPos then
                                        local dist = (targetPos - hrp.Position).Magnitude
                                        if dist < 100 then
                                            -- Eksekusi Teleport & Interact
                                            hrp.CFrame = CFrame.new(targetPos + Vector3.new(0, 3, 0))
                                            task.wait(0.1)
                                            fireproximityprompt(obj)
                                            
                                            -- JEDA 3 DETIK SETELAH INTERAKSI
                                            task.wait(3)
                                            
                                            found = true
                                            break -- Keluar dari loop pencarian, ulang dari awal
                                        end
                                    end
                                end
                            end
                        end
                        
                        -- Kalau ga ada target, tunggu bentar sebelum scan lagi
                        if not found then
                            task.wait(0.5)
                        end
                    else
                        task.wait(0.5)
                    end
                else
                    task.wait(0.5)
                end
            end
        end)
    else
        if blinkLoop then task.cancel(blinkLoop) end
    end
end)

-- 2. AUTO TAP QTE (Masak)
local tapLoop = nil
createToggle("Auto Tap (QTE)", function(state)
    if state then
        tapLoop = task.spawn(function()
            while state do
                local isMinigame = false
                for _, v in pairs(LocalPlayer.PlayerGui:GetDescendants()) do
                    if v:IsA("TextLabel") or v:IsA("TextButton") then
                        local txt = v.Text
                        if string.find(txt, "Tekan") or string.find(txt, "Gesek") or string.find(txt, "Tap") then
                            isMinigame = true
                            break
                        end
                    end
                end

                if isMinigame and VirtualUser then
                    pcall(function()
                        VirtualUser:Button1Down(Vector2.new(500, 500))
                        task.wait(0.01)
                        VirtualUser:Button1Up(Vector2.new(500, 500))
                    end)
                end
                task.wait(0.05)
            end
        end)
    else
        if tapLoop then task.cancel(tapLoop) end
    end
end)

-- 3. WALLHACK (Tembus Tembok)
local espHighlight = {}
local espLoop = nil
createToggle("Wallhack (Tembus)", function(state)
    if state then
        for _, hl in pairs(espHighlight) do hl:Destroy() end
        table.clear(espHighlight)

        espLoop = RunService.Heartbeat:Connect(function()
            for _, plr in pairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer and plr.Character then
                    if not espHighlight[plr.Name] or not espHighlight[plr.Name].Parent then
                        local hl = Instance.new("Highlight")
                        hl.FillColor = Color3.fromRGB(255, 50, 50)
                        hl.FillTransparency = 0.5
                        hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop 
                        hl.Adornee = plr.Character
                        hl.Parent = plr.Character
                        espHighlight[plr.Name] = hl
                    end
                end
            end
        end)
    else
        if espLoop then espLoop:Disconnect() end
        for _, hl in pairs(espHighlight) do hl:Destroy() end
        table.clear(espHighlight)
    end
end)

-- 4. AUTO CLAIM CASH (Jeda 1 Detik)
local cashLoop = nil
createToggle("Auto Claim Cash", function(state)
    if state then
        cashLoop = task.spawn(function()
            while state do
                local char = LocalPlayer.Character
                if char and char:FindFirstChild("HumanoidRootPart") then
                    local hrp = char.HumanoidRootPart
                    local foundCash = false
                    for _, obj in pairs(workspace:GetDescendants()) do
                        if obj:IsA("BasePart") then
                            local name = string.lower(obj.Name)
                            if string.find(name, "cash") or string.find(name, "money") or string.find(name, "tip") or string.find(name, "coin") then
                                local dist = (obj.Position - hrp.Position).Magnitude
                                if dist < 100 then
                                    hrp.CFrame = obj.CFrame
                                    foundCash = true
                                    task.wait(1) -- Jeda 1 detik biar ga terlalu ngebut
                                    break
                                end
                            end
                        end
                    end
                    if not foundCash then
                        task.wait(0.5)
                    end
                else
                    task.wait(0.5)
                end
            end
        end)
    else
        if cashLoop then task.cancel(cashLoop) end
    end
end)

print("[Hub] RT3 v11 Loaded.")
