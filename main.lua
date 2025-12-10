-- 外部スクリプト読み込み部分
local success, result = pcall(function()
    return game:HttpGet("https://pastebin.com/4hPx9AhZ", true)
end)

if success then
    loadstring(result)()
else
    warn("スクリプトの読み込みに失敗しました:", result)
end

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

-- RemoteEvent検索関数
local function findRemoteEvent()
    local containers = {LocalPlayer.Backpack, LocalPlayer.Character}
    
    for _, container in ipairs(containers) do
        if container then
            for _, item in ipairs(container:GetChildren()) do
                if item:IsA("Tool") then
                    local ev = item:FindFirstChild("Event")
                    if ev and ev:IsA("RemoteEvent") then
                        return ev
                    end
                end
            end
        end
    end
    return nil
end

-- Vfly GUIの作成
local Flymguiv2 = Instance.new("ScreenGui")
local Drag = Instance.new("Frame")
local FlyFrame = Instance.new("Frame")
local ddnsfbfwewefe = Instance.new("TextButton")
local Speed = Instance.new("TextBox")
local Fly = Instance.new("TextButton")
local Speeed = Instance.new("TextLabel")
local Stat = Instance.new("TextLabel")
local Stat2 = Instance.new("TextLabel")
local Unfly = Instance.new("TextButton")
local Vfly = Instance.new("TextLabel")
local Close = Instance.new("TextButton")
local Minimize = Instance.new("TextButton")
local Flyon = Instance.new("Frame")
local W = Instance.new("TextButton")
local S = Instance.new("TextButton")

--Properties:

Flymguiv2.Name = "Flym gui v2"
Flymguiv2.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
Flymguiv2.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

Drag.Name = "Drag"
Drag.Parent = Flymguiv2
Drag.Active = true
Drag.BackgroundColor3 = Color3.fromRGB(0, 102, 0)
Drag.BorderSizePixel = 0
Drag.Draggable = true
Drag.Position = UDim2.new(0.482438415, 0, 0.454874992, 0)
Drag.Size = UDim2.new(0, 237, 0, 27)

FlyFrame.Name = "FlyFrame"
FlyFrame.Parent = Drag
FlyFrame.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
FlyFrame.BorderSizePixel = 0
FlyFrame.Draggable = true
FlyFrame.Position = UDim2.new(-0.00200000009, 0, 0.989000022, 0)
FlyFrame.Size = UDim2.new(0, 237, 0, 139)

ddnsfbfwewefe.Name = "ddnsfbfwewefe"
ddnsfbfwewefe.Parent = FlyFrame
ddnsfbfwewefe.BackgroundColor3 = Color3.fromRGB(102, 0, 0)
ddnsfbfwewefe.BorderSizePixel = 0
ddnsfbfwewefe.Position = UDim2.new(-0.000210968778, 0, -0.00395679474, 0)
ddnsfbfwewefe.Size = UDim2.new(0, 237, 0, 27)
ddnsfbfwewefe.Font = Enum.Font.SourceSans
ddnsfbfwewefe.Text = "Vfly Script"
ddnsfbfwewefe.TextColor3 = Color3.fromRGB(255, 255, 255)
ddnsfbfwewefe.TextScaled = true
ddnsfbfwewefe.TextSize = 14.000
ddnsfbfwewefe.TextWrapped = true

Speed.Name = "Speed"
Speed.Parent = FlyFrame
Speed.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Speed.BorderColor3 = Color3.fromRGB(102, 0, 0)
Speed.BorderSizePixel = 3
Speed.Position = UDim2.new(0.445025861, 0, 0.402877688, 0)
Speed.Size = UDim2.new(0, 111, 0, 33)
Speed.Font = Enum.Font.SourceSans
Speed.PlaceholderColor3 = Color3.fromRGB(255, 255, 255)
Speed.Text = "20"
Speed.TextColor3 = Color3.fromRGB(255, 0, 0)
Speed.TextScaled = true
Speed.TextSize = 14.000
Speed.TextWrapped = true

Fly.Name = "Fly"
Fly.Parent = FlyFrame
Fly.BackgroundColor3 = Color3.fromRGB(102, 0, 0)
Fly.BorderSizePixel = 0
Fly.Position = UDim2.new(0.0759493634, 0, 0.705797076, 0)
Fly.Size = UDim2.new(0, 199, 0, 32)
Fly.Font = Enum.Font.SourceSans
Fly.Text = "Enable"
Fly.TextColor3 = Color3.fromRGB(255, 255, 255)
Fly.TextScaled = true
Fly.TextSize = 14.000
Fly.TextWrapped = true

Speeed.Name = "Speeed"
Speeed.Parent = FlyFrame
Speeed.BackgroundColor3 = Color3.fromRGB(102, 0, 0)
Speeed.BorderSizePixel = 0
Speeed.Position = UDim2.new(0.0759493634, 0, 0.402877688, 0)
Speeed.Size = UDim2.new(0, 87, 0, 32)
Speeed.ZIndex = 0
Speeed.Font = Enum.Font.SourceSans
Speeed.Text = "Speed:"
Speeed.TextColor3 = Color3.fromRGB(255, 255, 255)
Speeed.TextScaled = true
Speeed.TextSize = 14.000
Speeed.TextWrapped = true

Stat.Name = "Stat"
Stat.Parent = FlyFrame
Stat.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
Stat.BorderSizePixel = 0
Stat.Position = UDim2.new(0.299983799, 0, 0.239817441, 0)
Stat.Size = UDim2.new(0, 85, 0, 15)
Stat.Font = Enum.Font.SourceSans
Stat.Text = "Status:"
Stat.TextColor3 = Color3.fromRGB(255, 255, 255)
Stat.TextScaled = true
Stat.TextSize = 14.000
Stat.TextWrapped = true

Stat2.Name = "Stat2"
Stat2.Parent = FlyFrame
Stat2.BackgroundColor3 = Color3.fromRGB(102, 0, 0)
Stat2.BorderSizePixel = 0
Stat2.Position = UDim2.new(0.546535194, 0, 0.239817441, 0)
Stat2.Size = UDim2.new(0, 27, 0, 15)
Stat2.Font = Enum.Font.SourceSans
Stat2.Text = "Off"
Stat2.TextColor3 = Color3.fromRGB(255, 0, 0)
Stat2.TextScaled = true
Stat2.TextSize = 14.000
Stat2.TextWrapped = true

Unfly.Name = "Unfly"
Unfly.Parent = FlyFrame
Unfly.BackgroundColor3 = Color3.fromRGB(102, 0, 0)
Unfly.BorderSizePixel = 0
Unfly.Position = UDim2.new(0.0759493634, 0, 0.705797076, 0)
Unfly.Size = UDim2.new(0, 199, 0, 32)
Unfly.Visible = false
Unfly.Font = Enum.Font.SourceSans
Unfly.Text = "Disable"
Unfly.TextColor3 = Color3.fromRGB(255, 255, 255)
Unfly.TextScaled = true
Unfly.TextSize = 14.000
Unfly.TextWrapped = true

Vfly.Name = "Vfly"
Vfly.Parent = Drag
Vfly.BackgroundColor3 = Color3.fromRGB(102, 0, 0)
Vfly.BorderSizePixel = 0
Vfly.Size = UDim2.new(0, 57, 0, 27)
Vfly.Font = Enum.Font.SourceSans
Vfly.Text = "VFly"
Vfly.TextColor3 = Color3.fromRGB(255, 255, 255)
Vfly.TextScaled = true
Vfly.TextSize = 14.000
Vfly.TextWrapped = true

Close.Name = "Close"
Close.Parent = Drag
Close.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
Close.BorderSizePixel = 0
Close.Position = UDim2.new(0.875, 0, 0, 0)
Close.Size = UDim2.new(0, 27, 0, 27)
Close.Font = Enum.Font.SourceSans
Close.Text = "X"
Close.TextColor3 = Color3.fromRGB(255, 255, 255)
Close.TextScaled = true
Close.TextSize = 14.000
Close.TextWrapped = true

Minimize.Name = "Minimize"
Minimize.Parent = Drag
Minimize.BackgroundColor3 = Color3.fromRGB(0, 150, 191)
Minimize.BorderSizePixel = 0
Minimize.Position = UDim2.new(0.75, 0, 0, 0)
Minimize.Size = UDim2.new(0, 27, 0, 27)
Minimize.Font = Enum.Font.SourceSans
Minimize.Text = "-"
Minimize.TextColor3 = Color3.fromRGB(255, 255, 255)
Minimize.TextScaled = true
Minimize.TextSize = 14.000
Minimize.TextWrapped = true

Flyon.Name = "Fly on"
Flyon.Parent = Flymguiv2
Flyon.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Flyon.BorderSizePixel = 0
Flyon.Position = UDim2.new(0.117647067, 0, 0.550284624, 0)
Flyon.Size = UDim2.new(0.148000002, 0, 0.314999998, 0)
Flyon.Visible = false
Flyon.Active = true
Flyon.Draggable = true

W.Name = "W"
W.Parent = Flyon
W.BackgroundColor3 = Color3.fromRGB(0, 102, 0)
W.BorderSizePixel = 0
W.Position = UDim2.new(0.134719521, 0, 0.0152013302, 0)
W.Size = UDim2.new(0.708999991, 0, 0.499000013, 0)
W.Font = Enum.Font.SourceSans
W.Text = "Forward"
W.TextColor3 = Color3.fromRGB(255, 255, 255)
W.TextScaled = true
W.TextSize = 14.000
W.TextWrapped = true

S.Name = "S"
S.Parent = Flyon
S.BackgroundColor3 = Color3.fromRGB(0, 102, 0)
S.BorderSizePixel = 0
S.Position = UDim2.new(0.134000003, 0, 0.479999989, 0)
S.Rotation = 180.000
S.Size = UDim2.new(0.708999991, 0, 0.499000013, 0)
S.Font = Enum.Font.SourceSans
S.Text = "^"
S.TextColor3 = Color3.fromRGB(255, 255, 255)
S.TextScaled = true
S.TextSize = 14.000
S.TextWrapped = true

-- Vflyツールの作成
local vflyTool = Instance.new("Tool")
vflyTool.Name = "Vfly"
vflyTool.RequiresHandle = false
vflyTool.CanBeDropped = false
vflyTool.ToolTip = "Vfly GUIを開く"

-- ツール装備時にGUIを表示
vflyTool.Equipped:Connect(function()
    Flymguiv2.Enabled = true
end)

-- ツール解除時にGUIを非表示
vflyTool.Unequipped:Connect(function()
    Flymguiv2.Enabled = false
end)

-- ツールをバックパックに追加
vflyTool.Parent = LocalPlayer:WaitForChild("Backpack")

-- Vfly機能の変数
local isVflying = false
local bodyVelocity, bodyGyro
local currentSpeed = 20

-- Flyボタンクリック
Fly.MouseButton1Click:Connect(function()
    if not LocalPlayer.Character then return end
    
    local HumanoidRP = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not HumanoidRP then return end
    
    Fly.Visible = false
    Stat2.Text = "On"
    Stat2.TextColor3 = Color3.fromRGB(0, 255, 0)
    Unfly.Visible = true
    Flyon.Visible = true
    isVflying = true
    
    -- 速度を取得
    currentSpeed = tonumber(Speed.Text) or 20
    
    -- BodyVelocityとBodyGyroを作成
    bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.Velocity = Vector3.zero
    bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bodyVelocity.Parent = HumanoidRP
    
    bodyGyro = Instance.new("BodyGyro")
    bodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    bodyGyro.D = 5000
    bodyGyro.P = 100000
    bodyGyro.CFrame = workspace.CurrentCamera.CFrame
    bodyGyro.Parent = HumanoidRP
    
    -- カメラ追従
    RunService.RenderStepped:Connect(function()
        if not isVflying or not bodyGyro or not bodyGyro.Parent then return end
        bodyGyro.CFrame = workspace.CurrentCamera.CFrame
    end)
end)

-- Unflyボタンクリック
Unfly.MouseButton1Click:Connect(function()
    if not LocalPlayer.Character then return end
    
    local HumanoidRP = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not HumanoidRP then return end
    
    Fly.Visible = true
    Stat2.Text = "Off"
    Stat2.TextColor3 = Color3.fromRGB(255, 0, 0)
    Unfly.Visible = false
    Flyon.Visible = false
    isVflying = false
    
    -- BodyVelocityとBodyGyroを削除
    if bodyVelocity and bodyVelocity.Parent then
        bodyVelocity:Destroy()
    end
    
    if bodyGyro and bodyGyro.Parent then
        bodyGyro:Destroy()
    end
    
    bodyVelocity = nil
    bodyGyro = nil
end)

-- Wボタン（前進）機能
local function moveForward()
    if not isVflying or not LocalPlayer.Character then return end
    
    local HumanoidRP = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not HumanoidRP or not bodyVelocity then return end
    
    -- 速度を更新
    currentSpeed = tonumber(Speed.Text) or 20
    
    bodyVelocity.Velocity = workspace.CurrentCamera.CFrame.LookVector * currentSpeed
end

local function stopMoving()
    if not isVflying or not bodyVelocity then return end
    bodyVelocity.Velocity = Vector3.zero
end

W.MouseButton1Down:Connect(function()
    moveForward()
end)

W.MouseButton1Up:Connect(function()
    stopMoving()
end)

W.TouchLongPress:Connect(function()
    moveForward()
end)

-- Sボタン（後退）機能
local function moveBackward()
    if not isVflying or not LocalPlayer.Character then return end
    
    local HumanoidRP = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not HumanoidRP or not bodyVelocity then return end
    
    -- 速度を更新
    currentSpeed = tonumber(Speed.Text) or 20
    
    bodyVelocity.Velocity = workspace.CurrentCamera.CFrame.LookVector * -currentSpeed
end

S.MouseButton1Down:Connect(function()
    moveBackward()
end)

S.MouseButton1Up:Connect(function()
    stopMoving()
end)

S.TouchLongPress:Connect(function()
    moveBackward()
end)

-- Closeボタン
Close.MouseButton1Click:Connect(function()
    Flymguiv2:Destroy()
end)

-- Minimizeボタン機能
local function toggleMinimize()
    if Minimize.Text == "-" then
        Minimize.Text = "+"
        FlyFrame.Visible = false
    elseif Minimize.Text == "+" then
        Minimize.Text = "-"
        FlyFrame.Visible = true
    end
end

Minimize.MouseButton1Click:Connect(toggleMinimize)

-- キーボード入力による移動（オプション）
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed or not isVflying then return end
    
    if input.KeyCode == Enum.KeyCode.W then
        moveForward()
    elseif input.KeyCode == Enum.KeyCode.S then
        moveBackward()
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if gameProcessed or not isVflying then return end
    
    if input.KeyCode == Enum.KeyCode.W or input.KeyCode == Enum.KeyCode.S then
        stopMoving()
    end
end)

-- キャラクター変更時の処理
LocalPlayer.CharacterAdded:Connect(function(character)
    task.wait(1) -- キャラクターのロードを待つ
    
    -- 飛行中なら再設定
    if isVflying then
        Fly.Visible = false
        Stat2.Text = "On"
        Stat2.TextColor3 = Color3.fromRGB(0, 255, 0)
        Unfly.Visible = true
        Flyon.Visible = true
    end
end)

print("Vfly tool loaded successfully!")
print("Use Vfly tool in your backpack to open the GUI")
