local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local ESP_Enabled = false
local AutoPick_Enabled = false
local LocalPlayer = Players.LocalPlayer

-- 1. ЛОГІКА ROLE ESP
local function getPlayerRole(player)
    local playerData = ReplicatedStorage:FindFirstChild("GetPlayerData", true)
    if playerData and playerData:IsA("RemoteFunction") then
        local success, data = pcall(function() return playerData:InvokeServer() end)
        if success and data and data[player.Name] then
            return data[player.Name].Role
        end
    end
    local roleFolder = player:FindFirstChild("Role") or player:FindFirstChild("temp")
    if roleFolder then return roleFolder.Value end
    return "Innocent"
end

local function removeESP(player)
    if player.Character then
        local highlight = player.Character:FindFirstChild("Xeno_MM2_Highlight")
        if highlight then highlight:Destroy() end
    end
end

local function manageESP(player)
    if player == LocalPlayer then return end
    
    local function setupHighlight()
        local char = player.Character or player.CharacterAdded:Wait()
        if not char then return end
        if not ESP_Enabled then removeESP(player) return end
        
        local highlight = char:FindFirstChild("Xeno_MM2_Highlight") or Instance.new("Highlight")
        highlight.Name = "Xeno_MM2_Highlight"
        highlight.Parent = char
        highlight.FillTransparency = 0.4
        highlight.OutlineTransparency = 0.1
        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
        
        task.spawn(function()
            while char:IsDescendantOf(workspace) and ESP_Enabled do
                local role = getPlayerRole(player)
                if role == "Murderer" or role == "Murder" then
                    highlight.FillColor = Color3.fromRGB(255, 0, 0)
                elseif role == "Sheriff" or role == "Hero" then
                    highlight.FillColor = Color3.fromRGB(0, 0, 255)
                else
                    highlight.FillColor = Color3.fromRGB(0, 255, 0)
                end
                task.wait(0.5)
            end
            if not ESP_Enabled then removeESP(player) end
        end)
    end
    
    setupHighlight()
    player.CharacterAdded:Connect(setupHighlight)
end

local function updateESPState()
    for _, p in pairs(Players:GetPlayers()) do
        if ESP_Enabled then manageESP(p) else removeESP(p) end
    end
end

-- 2. ЛОГІКА АВТОПІДБОРУ ПІСТОЛЕТА (AUTO-PICK GUN)
task.spawn(function()
    while true do
        task.wait(0.1)
        if AutoPick_Enabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            -- Шукаємо пістолет, який випав на карті MM2
            local gunDrop = Workspace:FindFirstChild("GunDrop")
            if gunDrop and gunDrop:IsA("Part") then
                local hrp = LocalPlayer.Character.HumanoidRootPart
                local oldCFrame = hrp.CFrame -- Запам'ятовуємо, де ми стояли
                
                -- Швидкий телепорт до пістолета і назад
                local startTime = tick()
                while gunDrop and gunDrop.Parent == Workspace and (tick() - startTime) < 1 do
                    hrp.CFrame = gunDrop.CFrame
                    task.wait()
                end
                hrp.CFrame = oldCFrame -- Повертаємося на місце
            end
        end
    end
end)

-- 3. СТВОРЕННЯ ЮІШКИ (UI ГРАФІЧНОГО МЕНЮ)
local ScreenGui = Instance.new("ScreenGui")
if syn and syn.protect_gui then syn.protect_gui(ScreenGui) end
ScreenGui.Parent = CoreGui

local MainFrame = Instance.new("Frame")
MainFrame.Name = "XenoMenu"
MainFrame.Size = UDim2.new(0, 240, 0, 90) -- Збільшили розмір під дві кнопки
MainFrame.Position = UDim2.new(0.5, -120, 0.8, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = MainFrame

local UIStroke = Instance.new("UIStroke")
UIStroke.Color = Color3.fromRGB(50, 50, 50)
UIStroke.Thickness = 1.5
UIStroke.Parent = MainFrame

-- Рядок 1: ROLE ESP
local TitleESP = Instance.new("TextLabel")
TitleESP.Size = UDim2.new(0, 130, 0, 45)
TitleESP.Position = UDim2.new(0, 15, 0, 0)
TitleESP.BackgroundTransparency = 1
TitleESP.Text = "Role ESP"
TitleESP.TextColor3 = Color3.fromRGB(240, 240, 240)
TitleESP.TextSize = 14
TitleESP.Font = Enum.Font.SourceSansBold
TitleESP.TextXAlignment = Enum.TextXAlignment.Left
TitleESP.Parent = MainFrame

local ToggleESP = Instance.new("TextButton")
ToggleESP.Size = UDim2.new(0, 65, 0, 24)
ToggleESP.Position = UDim2.new(1, -80, 0, 10)
ToggleESP.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
ToggleESP.Text = "OFF"
ToggleESP.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleESP.TextSize = 12
ToggleESP.Font = Enum.Font.SourceSansBold
ToggleESP.Parent = MainFrame

local CornerESP = Instance.new("UICorner")
CornerESP.CornerRadius = UDim.new(0, 6)
CornerESP.Parent = ToggleESP

ToggleESP.MouseButton1Click:Connect(function()
    ESP_Enabled = not ESP_Enabled
    if ESP_Enabled then
        ToggleESP.Text = "ON"
        TweenService:Create(ToggleESP, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(50, 180, 50)}):Play()
        updateESPState()
    else
        ToggleESP.Text = "OFF"
        TweenService:Create(ToggleESP, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(180, 50, 50)}):Play()
        updateESPState()
    end
end)

-- Рядок 2: AUTO-PICK GUN
local TitlePick = Instance.new("TextLabel")
TitlePick.Size = UDim2.new(0, 130, 0, 45)
TitlePick.Position = UDim2.new(0, 15, 0, 45)
TitlePick.BackgroundTransparency = 1
TitlePick.Text = "Auto-Pick Gun"
TitlePick.TextColor3 = Color3.fromRGB(240, 240, 240)
TitlePick.TextSize = 14
TitlePick.Font = Enum.Font.SourceSansBold
TitlePick.TextXAlignment = Enum.TextXAlignment.Left
TitlePick.Parent = MainFrame

local TogglePick = Instance.new("TextButton")
TogglePick.Size = UDim2.new(0, 65, 0, 24)
TogglePick.Position = UDim2.new(1, -80, 0, 55)
TogglePick.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
TogglePick.Text = "OFF"
TogglePick.TextColor3 = Color3.fromRGB(255, 255, 255)
TogglePick.TextSize = 12
TogglePick.Font = Enum.Font.SourceSansBold
TogglePick.Parent = MainFrame

local CornerPick = Instance.new("UICorner")
CornerPick.CornerRadius = UDim.new(0, 6)
CornerPick.Parent = TogglePick

TogglePick.MouseButton1Click:Connect(function()
    AutoPick_Enabled = not AutoPick_Enabled
    if AutoPick_Enabled then
        TogglePick.Text = "ON"
        TweenService:Create(TogglePick, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(50, 180, 50)}):Play()
    else
        TogglePick.Text = "OFF"
        TweenService:Create(TogglePick, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(180, 50, 50)}):Play()
    end
end)

Players.PlayerAdded:Connect(function(p)
    if ESP_Enabled then manageESP(p) end
end)
