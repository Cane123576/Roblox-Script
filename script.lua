local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local ESP_Enabled, AutoPick_Enabled = false, false
local LocalPlayer = Players.LocalPlayer

-- ==========================================
-- 1. РОЗУМНА ЛОГІКА ESP ТА ПОШУКУ ПІСТОЛЕТА ПО КАРТІ
-- ==========================================
local function getPlayerRole(player)
    local playerData = ReplicatedStorage:FindFirstChild("GetPlayerData", true)
    if playerData and playerData:IsA("RemoteFunction") then
        local success, data = pcall(function() return playerData:InvokeServer() end)
        if success and data and data[player.Name] then return data[player.Name].Role end
    end
    local rf = player:FindFirstChild("Role") or player:FindFirstChild("temp")
    return rf and rf.Value or "Innocent"
end

local function removeESP(player)
    if player.Character and player.Character:FindFirstChild("Xeno_MM2_Highlight") then 
        player.Character.Xeno_MM2_Highlight:Destroy() 
    end
end

local function manageESP(player)
    if player == LocalPlayer then return end
    local function setupHighlight()
        local char = player.Character or player.CharacterAdded:Wait()
        if not char or not ESP_Enabled then removeESP(player) return end
        local hl = char:FindFirstChild("Xeno_MM2_Highlight") or Instance.new("Highlight")
        hl.Name = "Xeno_MM2_Highlight"
        hl.Parent, hl.FillTransparency, hl.OutlineTransparency = char, 0.4, 0.1
        hl.OutlineColor = Color3.fromRGB(255, 255, 255)
        task.spawn(function()
            while char:IsDescendantOf(workspace) and ESP_Enabled do
                local role = getPlayerRole(player)
                hl.FillColor = (role == "Murderer" or role == "Murder") and Color3.fromRGB(235, 60, 60) 
                            or (role == "Sheriff" or role == "Hero") and Color3.fromRGB(60, 120, 235) 
                            or Color3.fromRGB(60, 235, 120)
                task.wait(0.5)
            end
            if not ESP_Enabled then removeESP(player) end
        end)
    end
    setupHighlight()
    player.CharacterAdded:Connect(setupHighlight)
end

local function updateESPState()
    for _, p in pairs(Players:GetPlayers()) do if ESP_Enabled then manageESP(p) else removeESP(p) end end
end

-- ФУНКЦІЯ АВТОМАТИЧНОГО СКАНИКА КАРТИ НА ПІСТОЛЕТ, ЩО ВИПАВ
local function findDroppedGun()
    -- Шукаємо будь-яку деталь на карті, яка має триггер дотику і схожа на зброю шерифа
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("TouchTransmitter") and obj.Parent then
            local parent = obj.Parent
            -- Перевіряємо за класичними ознаками випавшої зброї в MM2
            if parent.Name == "GunDrop" or parent:FindFirstChild("Knife") == nil and (parent:IsA("Part") or parent:IsA("MeshPart")) and parent.Parent == Workspace then
                return parent
            elseif parent.Parent and parent.Parent.Name == "GunDrop" then
                return parent.Parent
            end
        end
    end
    return nil
end

-- НАДІЙНИЙ TWEEN-ПІДБІР З ОБХОДОМ СЕРВЕРНОГО ЗАХИСТУ
task.spawn(function()
    while true do
        task.wait(0.2)
        if AutoPick_Enabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            -- Викликаємо наш новий розумний пошук
            local targetGun = findDroppedGun()
            
            if targetGun and not LocalPlayer.Backpack:FindFirstChild("Gun") and not LocalPlayer.Character:FindFirstChild("Gun") then
                local hrp = LocalPlayer.Character.HumanoidRootPart
                local oldCF = hrp.CFrame
                
                -- Розрахунок швидкості підльоту
                local distance = (hrp.Position - targetGun.Position).Magnitude
                local speed = 130
                local tweenInfo = TweenInfo.new(distance / speed, Enum.EasingStyle.Linear)
                
                -- Летимо безпосередньо в координати знайденого об'єкта
                local flyTo = TweenService:Create(hrp, tweenInfo, {CFrame = targetGun.CFrame})
                flyTo:Play()
                flyTo.Completed:Wait()
                
                -- Стоїмо на пістолеті та спамимо дотиками під твій пінг
                local startT = tick()
                while targetGun Pin targetGun.Parent and (tick() - startT) < 0.8 do
                    hrp.CFrame = targetGun.CFrame
                    if firetouchinterest then
                        firetouchinterest(hrp, targetGun, 0)
                        firetouchinterest(hrp, targetGun, 1)
                    end
                    task.wait(0.05)
                end
                
                -- Повертаємося назад на початкове місце
                local flyBack = TweenService:Create(hrp, tweenInfo, {CFrame = oldCF})
                flyBack:Play()
                flyBack.Completed:Wait()
            end
        end
    end
end)

-- ==========================================
-- 2. СТВОРЕННЯ СУЧАСНОЇ ЮІШКИ (ПОЧАТОК)
-- ==========================================
local ScreenGui = Instance.new("ScreenGui")
if syn and syn.protect_gui then syn.protect_gui(ScreenGui) end
ScreenGui.Parent = CoreGui

local ToggleGuiBtn = Instance.new("TextButton")
ToggleGuiBtn.Name, ToggleGuiBtn.Size, ToggleGuiBtn.Position = "CaneHubToggle", UDim2.new(0, 45, 0, 45), UDim2.new(0, 20, 0.4, 0)
ToggleGuiBtn.BackgroundColor3, ToggleGuiBtn.Text, ToggleGuiBtn.TextColor3 = Color3.fromRGB(25, 25, 28), "C", Color3.fromRGB(85, 136, 255)
ToggleGuiBtn.TextSize, ToggleGuiBtn.Font, ToggleGuiBtn.Active, ToggleGuiBtn.Draggable = 20, Enum.Font.SourceSansBold, true, true
ToggleGuiBtn.Parent = ScreenGui
Instance.new("UICorner", ToggleGuiBtn).CornerRadius = UDim.new(1, 0)
local tStrik = Instance.new("UIStroke", ToggleGuiBtn)
tStrik.Color, tStrik.Thickness = Color3.fromRGB(50, 50, 55), 1.5

local MainFrame = Instance.new("Frame")
MainFrame.Name, MainFrame.Size, MainFrame.Position = "CustomPulseHub", UDim2.new(0, 520, 0, 340), UDim2.new(0.5, -260, 0.5, -170)
MainFrame.BackgroundColor3, MainFrame.BorderSizePixel, MainFrame.Active, MainFrame.Draggable, MainFrame.Visible = Color3.fromRGB(20, 20, 22), 0, true, true, false
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)
local mStrik = Instance.new("UIStroke", MainFrame)
mStrik.Color, mStrik.Thickness = Color3.fromRGB(35, 35, 38), 1.2
local TopBar = Instance.new("Frame")
TopBar.Size, TopBar.BackgroundTransparency, TopBar.Parent = UDim2.new(1, 0, 0, 40), 1, MainFrame

local HubTitle = Instance.new("TextLabel")
HubTitle.Size, HubTitle.Position, HubTitle.BackgroundTransparency = UDim2.new(0, 200, 1, 0), UDim2.new(0, 15, 0, 0), 1
HubTitle.Text, HubTitle.RichText, HubTitle.TextColor3 = "Cane Hub <font color='#5588ff'>| MM2</font>", true, Color3.fromRGB(255, 255, 255)
HubTitle.TextSize, HubTitle.Font, HubTitle.TextXAlignment = 16, Enum.Font.SourceSansBold, Enum.TextXAlignment.Left
HubTitle.Parent = TopBar

-- НАДІЙНА КНОПКА ЗАКРИТТЯ У ВИГЛЯДІ ЛІТЕРИ X
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size, CloseBtn.Position, CloseBtn.BackgroundTransparency = UDim2.new(0, 30, 0, 30), UDim2.new(1, -35, 0.5, -15), 1
CloseBtn.Text, CloseBtn.TextColor3, CloseBtn.TextSize, CloseBtn.Font = "X", Color3.fromRGB(150, 150, 155), 16, Enum.Font.SourceSansBold
CloseBtn.Parent = TopBar

ToggleGuiBtn.MouseButton1Click:Connect(function() MainFrame.Visible = not MainFrame.Visible end)
CloseBtn.MouseButton1Click:Connect(function() MainFrame.Visible = not MainFrame.Visible end)

local Sidebar = Instance.new("Frame")
Sidebar.Size, Sidebar.Position, Sidebar.BackgroundColor3, Sidebar.BorderSizePixel = UDim2.new(0, 130, 1, -40), UDim2.new(0, 0, 0, 40), Color3.fromRGB(16, 16, 18), 0
Sidebar.Parent = MainFrame
Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0, 10)

local SidebarFix = Instance.new("Frame")
SidebarFix.Size, SidebarFix.Position, SidebarFix.BackgroundColor3, SidebarFix.BorderSizePixel = UDim2.new(0, 10, 1, 0), UDim2.new(1, -10, 0, 0), Color3.fromRGB(16, 16, 18), 0
SidebarFix.Parent = Sidebar

local TabContainer = Instance.new("Frame")
TabContainer.Size, TabContainer.Position, TabContainer.BackgroundTransparency, TabContainer.Parent = UDim2.new(1, -20, 1, -20), UDim2.new(0, 10, 0, 10), 1, Sidebar
local TabList = Instance.new("UIListLayout", TabContainer)
TabList.Padding = UDim.new(0, 6)

local PagesContainer = Instance.new("Frame")
PagesContainer.Size, PagesContainer.Position, PagesContainer.BackgroundTransparency, PagesContainer.Parent = UDim2.new(1, -145, 1, -55), UDim2.new(0, 140, 0, 45), 1, MainFrame

local Pages, Tabs = {}, {}
local function createPage(name)
    local Page = Instance.new("Frame")
    Page.Name, Page.Size, Page.BackgroundTransparency, Page.Visible, Page.Parent = name .. "Page", UDim2.new(1, 0, 1, 0), 1, false, PagesContainer
    local pList = Instance.new("UIListLayout", Page)
    pList.Padding = UDim.new(0, 10)
    Pages[name] = Page
end
createPage("Main") createPage("Murder") createPage("Sheriff")

local function switchTab(tabName)
    for name, page in pairs(Pages) do page.Visible = (name == tabName) end
    for name, button in pairs(Tabs) do
        if name == tabName then
            button.BackgroundColor3, button.TextColor3 = Color3.fromRGB(30, 30, 35), Color3.fromRGB(255, 255, 255)
        else
            button.BackgroundColor3, button.TextColor3 = Color3.fromRGB(22, 22, 24), Color3.fromRGB(140, 140, 145)
        end
    end
end

local function createTabButton(name)
    local Btn = Instance.new("TextButton")
    Btn.Size, Btn.BackgroundColor3, Btn.BorderSizePixel = UDim2.new(1, 0, 0, 32), Color3.fromRGB(22, 22, 24), 0
    Btn.Text, Btn.TextColor3, Btn.TextSize, Btn.Font, Btn.TextXAlignment = "  " .. name, Color3.fromRGB(140, 140, 145), 14, Enum.Font.SourceSansBold, Enum.TextXAlignment.Left
    Btn.Parent = TabContainer
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 6)
    Btn.MouseButton1Click:Connect(function() switchTab(name) end)
    Tabs[name] = Btn
end
createTabButton("Main") createTabButton("Murder") createTabButton("Sheriff")
switchTab("Main")

local function createToggle(parentPage, text, defaultState, callback)
    local tFrame = Instance.new("Frame")
    tFrame.Size, tFrame.BackgroundColor3, tFrame.BorderSizePixel, tFrame.Parent = UDim2.new(1, 0, 0, 40), Color3.fromRGB(24, 24, 27), 0, parentPage
    Instance.new("UICorner", tFrame).CornerRadius = UDim.new(0, 6)
    local tSt = Instance.new("UIStroke", tFrame)
    tSt.Color, tSt.Thickness = Color3.fromRGB(35, 35, 38), 1
    
    local Label = Instance.new("TextLabel")
    Label.Size, Label.Position, Label.BackgroundTransparency = UDim2.new(1, -70, 1, 0), UDim2.new(0, 12, 0, 0), 1
    Label.Text, Label.TextColor3, Label.TextSize, Label.Font, Label.TextXAlignment = text, Color3.fromRGB(220, 220, 225), 14, Enum.Font.SourceSans, Enum.TextXAlignment.Left
    Label.Parent = tFrame
    
    local Button = Instance.new("TextButton")
    Button.Size, Button.Position, Button.Text = UDim2.new(0, 45, 0, 22), UDim2.new(1, -57, 0.5, -11), ""
    Button.BackgroundColor3 = defaultState and Color3.fromRGB(80, 140, 240) or Color3.fromRGB(45, 45, 48)
    Button.Parent = tFrame
    Instance.new("UICorner", Button).CornerRadius = UDim.new(0, 11)
    
    local Circle = Instance.new("Frame")
    Circle.Size, Circle.Position = UDim2.new(0, 16, 0, 16), defaultState and UDim2.new(1, -20, 0.5, -8) or UDim2.new(0, 4, 0.5, -8)
    Circle.BackgroundColor3, Circle.BorderSizePixel, Circle.Parent = Color3.fromRGB(255, 255, 255), 0, Button
    Instance.new("UICorner", Circle).CornerRadius = UDim.new(1, 0)
    
    local state = defaultState
    Button.MouseButton1Click:Connect(function()
        state = not state
        callback(state)
        if state then
            TweenService:Create(Button, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(80, 140, 240)}):Play()
            TweenService:Create(Circle, TweenInfo.new(0.2), {Position = UDim2.new(1, -20, 0.5, -8)}):Play()
        else
            TweenService:Create(Button, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(45, 45, 48)}):Play()
            TweenService:Create(Circle, TweenInfo.new(0.2), {Position = UDim2.new(0, 4, 0.5, -8)}):Play()
        end
    end)
end

createToggle(Pages["Main"], "Enable Role ESP", false, function(v) ESP_Enabled = v updateESPState() end)
createToggle(Pages["Main"], "Auto-Pick Gun", false, function(v) AutoPick_Enabled = v end)

local function makeLabel(p, txt)
    local lbl = Instance.new("TextLabel")
    lbl.Size, lbl.BackgroundTransparency, lbl.Text = UDim2.new(1, 0, 0, 30), 1, txt
    lbl.TextColor3, lbl.TextSize, lbl.Font, lbl.Parent = Color3.fromRGB(100, 100, 105), 14, Enum.Font.SourceSansItalic, p
end
makeLabel(Pages["Murder"], "Murder functions will be here soon...")
makeLabel(Pages["Sheriff"], "Sheriff functions will be here soon...")

Players.PlayerAdded:Connect(function(p) if ESP_Enabled then manageESP(p) end end)
