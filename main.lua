-- 外部スクリプト読み込みを削除（直接コードを記述）
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

-- RemoteEvent検索関数（元のまま）
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

-- GUI作成
local main = Instance.new("ScreenGui")
local Frame = Instance.new("Frame")
local up = Instance.new("TextButton")
local down = Instance.new("TextButton")
local onof = Instance.new("TextButton")
local TextLabel = Instance.new("TextLabel")
local plus = Instance.new("TextButton")
local speed = Instance.new("TextLabel")
local mine = Instance.new("TextButton")
local closebutton = Instance.new("TextButton")
local mini = Instance.new("TextButton")
local mini2 = Instance.new("TextButton")

main.Name = "main"
main.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
main.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
main.ResetOnSpawn = false

Frame.Parent = main
Frame.BackgroundColor3 = Color3.fromRGB(163, 255, 137)
Frame.BorderColor3 = Color3.fromRGB(103, 221, 213)
Frame.Position = UDim2.new(0.100320168, 0, 0.379746825, 0)
Frame.Size = UDim2.new(0, 190, 0, 57)

up.Name = "up"
up.Parent = Frame
up.BackgroundColor3 = Color3.fromRGB(79, 255, 152)
up.Size = UDim2.new(0, 44, 0, 28)
up.Font = Enum.Font.SourceSans
up.Text = "UP"
up.TextColor3 = Color3.fromRGB(0, 0, 0)
up.TextSize = 14.000

down.Name = "down"
down.Parent = Frame
down.BackgroundColor3 = Color3.fromRGB(215, 255, 121)
down.Position = UDim2.new(0, 0, 0.491228074, 0)
down.Size = UDim2.new(0, 44, 0, 28)
down.Font = Enum.Font.SourceSans
down.Text = "DOWN"
down.TextColor3 = Color3.fromRGB(0, 0, 0)
down.TextSize = 14.000

onof.Name = "onof"
onof.Parent = Frame
onof.BackgroundColor3 = Color3.fromRGB(255, 249, 74)
onof.Position = UDim2.new(0.702823281, 0, 0.491228074, 0)
onof.Size = UDim2.new(0, 56, 0, 28)
onof.Font = Enum.Font.SourceSans
onof.Text = "fly"
onof.TextColor3 = Color3.fromRGB(0, 0, 0)
onof.TextSize = 14.000

TextLabel.Parent = Frame
TextLabel.BackgroundColor3 = Color3.fromRGB(242, 60, 255)
TextLabel.Position = UDim2.new(0.469327301, 0, 0, 0)
TextLabel.Size = UDim2.new(0, 100, 0, 28)
TextLabel.Font = Enum.Font.SourceSans
TextLabel.Text = "FLY GUI V3"
TextLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
TextLabel.TextScaled = true
TextLabel.TextSize = 14.000
TextLabel.TextWrapped = true

plus.Name = "plus"
plus.Parent = Frame
plus.BackgroundColor3 = Color3.fromRGB(133, 145, 255)
plus.Position = UDim2.new(0.231578946, 0, 0, 0)
plus.Size = UDim2.new(0, 45, 0, 28)
plus.Font = Enum.Font.SourceSans
plus.Text = "+"
plus.TextColor3 = Color3.fromRGB(0, 0, 0)
plus.TextScaled = true
plus.TextSize = 14.000
plus.TextWrapped = true

speed.Name = "speed"
speed.Parent = Frame
speed.BackgroundColor3 = Color3.fromRGB(255, 85, 0)
speed.Position = UDim2.new(0.468421042, 0, 0.491228074, 0)
speed.Size = UDim2.new(0, 44, 0, 28)
speed.Font = Enum.Font.SourceSans
speed.Text = "50"
speed.TextColor3 = Color3.fromRGB(0, 0, 0)
speed.TextScaled = true
speed.TextSize = 14.000
speed.TextWrapped = true

mine.Name = "mine"
mine.Parent = Frame
mine.BackgroundColor3 = Color3.fromRGB(123, 255, 247)
mine.Position = UDim2.new(0.231578946, 0, 0.491228074, 0)
mine.Size = UDim2.new(0, 45, 0, 29)
mine.Font = Enum.Font.SourceSans
mine.Text = "-"
mine.TextColor3 = Color3.fromRGB(0, 0, 0)
mine.TextScaled = true
mine.TextSize = 14.000
mine.TextWrapped = true

closebutton.Name = "Close"
closebutton.Parent = main.Frame
closebutton.BackgroundColor3 = Color3.fromRGB(225, 25, 0)
closebutton.Font = "SourceSans"
closebutton.Size = UDim2.new(0, 45, 0, 28)
closebutton.Text = "X"
closebutton.TextSize = 30
closebutton.Position =  UDim2.new(0, 0, -1, 27)

mini.Name = "minimize"
mini.Parent = main.Frame
mini.BackgroundColor3 = Color3.fromRGB(192, 150, 230)
mini.Font = "SourceSans"
mini.Size = UDim2.new(0, 45, 0, 28)
mini.Text = "-"
mini.TextSize = 40
mini.Position = UDim2.new(0, 44, -1, 27)

mini2.Name = "minimize2"
mini2.Parent = main.Frame
mini2.BackgroundColor3 = Color3.fromRGB(192, 150, 230)
mini2.Font = "SourceSans"
mini2.Size = UDim2.new(0, 45, 0, 28)
mini2.Text = "+"
mini2.TextSize = 40
mini2.Position = UDim2.new(0, 44, -1, 57)
mini2.Visible = false

-- Fly機能の変数
local flySpeed = 50
local isFlying = false
local bodyVelocity, bodyGyro
local flyConnection

-- 速度更新
local function updateSpeed()
    flySpeed = tonumber(speed.Text) or 50
    if flySpeed < 1 then flySpeed = 1 end
    if flySpeed > 200 then flySpeed = 200 end
    speed.Text = tostring(flySpeed)
end

-- Fly開始関数（修正版）
local function startFly()
    if isFlying then return end
    
    local character = LocalPlayer.Character
    if not character then return end
    
    local humanoid = character:FindFirstChild("Humanoid")
    local rootPart = character:FindFirstChild("HumanoidRootPart") or 
                     character:FindFirstChild("Torso") or 
                     character:FindFirstChild("UpperTorso")
    
    if not humanoid or not rootPart then return end
    
    isFlying = true
    onof.Text = "STOP"
    humanoid.PlatformStand = true
    
    -- BodyVelocityとBodyGyroを作成
    bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.Velocity = Vector3.zero
    bodyVelocity.MaxForce = Vector3.new(10000, 10000, 10000)
    bodyVelocity.P = 1000
    bodyVelocity.Parent = rootPart
    
    bodyGyro = Instance.new("BodyGyro")
    bodyGyro.MaxTorque = Vector3.new(10000, 10000, 10000)
    bodyGyro.P = 1000
    bodyGyro.CFrame = rootPart.CFrame
    bodyGyro.Parent = rootPart
    
    -- キーボード入力による移動
    local moveDirection = Vector3.zero
    local lastUpdate = tick()
    
    flyConnection = RunService.Heartbeat:Connect(function(delta)
        if not isFlying or not rootPart or not bodyVelocity or not bodyGyro then
            return
        end
        
        -- カメラ方向の追従
        bodyGyro.CFrame = workspace.CurrentCamera.CFrame
        
        -- 移動方向の計算
        local newDirection = Vector3.zero
        
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then
            newDirection = newDirection + workspace.CurrentCamera.CFrame.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then
            newDirection = newDirection - workspace.CurrentCamera.CFrame.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then
            newDirection = newDirection - workspace.CurrentCamera.CFrame.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then
            newDirection = newDirection + workspace.CurrentCamera.CFrame.RightVector
        end
        
        -- 速度適用
        if newDirection.Magnitude > 0 then
            newDirection = newDirection.Unit * flySpeed
        end
        
        -- 上昇/下降
        if up.MouseEnter.Connected or UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            newDirection = newDirection + Vector3.new(0, flySpeed, 0)
        end
        if down.MouseEnter.Connected or UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
            newDirection = newDirection - Vector3.new(0, flySpeed, 0)
        end
        
        bodyVelocity.Velocity = newDirection
    end)
    
    print("Fly mode: ON")
end

-- Fly停止関数
local function stopFly()
    if not isFlying then return end
    
    isFlying = false
    onof.Text = "fly"
    
    local character = LocalPlayer.Character
    if character then
        local humanoid = character:FindFirstChild("Humanoid")
        if humanoid then
            humanoid.PlatformStand = false
        end
    end
    
    -- 接続を切断
    if flyConnection then
        flyConnection:Disconnect()
        flyConnection = nil
    end
    
    -- BodyVelocityとBodyGyroを削除
    if bodyVelocity and bodyVelocity.Parent then
        bodyVelocity:Destroy()
        bodyVelocity = nil
    end
    
    if bodyGyro and bodyGyro.Parent then
        bodyGyro:Destroy()
        bodyGyro = nil
    end
    
    print("Fly mode: OFF")
end

-- Flyトグル
onof.MouseButton1Down:connect(function()
    if isFlying then
        stopFly()
    else
        updateSpeed()
        startFly()
    end
end)

-- UPボタン（上昇）
local upHovering = false
up.MouseEnter:Connect(function()
    upHovering = true
    while upHovering and isFlying and bodyVelocity do
        local currentVel = bodyVelocity.Velocity
        bodyVelocity.Velocity = Vector3.new(currentVel.X, flySpeed, currentVel.Z)
        RunService.Heartbeat:Wait()
    end
end)

up.MouseLeave:Connect(function()
    upHovering = false
    if isFlying and bodyVelocity then
        local currentVel = bodyVelocity.Velocity
        bodyVelocity.Velocity = Vector3.new(currentVel.X, 0, currentVel.Z)
    end
end)

-- DOWNボタン（下降）
local downHovering = false
down.MouseEnter:Connect(function()
    downHovering = true
    while downHovering and isFlying and bodyVelocity do
        local currentVel = bodyVelocity.Velocity
        bodyVelocity.Velocity = Vector3.new(currentVel.X, -flySpeed, currentVel.Z)
        RunService.Heartbeat:Wait()
    end
end)

down.MouseLeave:Connect(function()
    downHovering = false
    if isFlying and bodyVelocity then
        local currentVel = bodyVelocity.Velocity
        bodyVelocity.Velocity = Vector3.new(currentVel.X, 0, currentVel.Z)
    end
end)

-- 速度調整ボタン
plus.MouseButton1Down:connect(function()
    local current = tonumber(speed.Text) or 50
    if current < 200 then
        speed.Text = tostring(current + 5)
        updateSpeed()
    end
end)

mine.MouseButton1Down:connect(function()
    local current = tonumber(speed.Text) or 50
    if current > 5 then
        speed.Text = tostring(current - 5)
        updateSpeed()
    end
end)

-- 閉じるボタン
closebutton.MouseButton1Click:Connect(function()
    stopFly()
    main:Destroy()
end)

-- 最小化ボタン
mini.MouseButton1Click:Connect(function()
    up.Visible = false
    down.Visible = false
    onof.Visible = false
    plus.Visible = false
    speed.Visible = false
    mine.Visible = false
    mini.Visible = false
    mini2.Visible = true
    main.Frame.BackgroundTransparency = 1
    closebutton.Position = UDim2.new(0, 0, -1, 57)
end)

mini2.MouseButton1Click:Connect(function()
    up.Visible = true
    down.Visible = true
    onof.Visible = true
    plus.Visible = true
    speed.Visible = true
    mine.Visible = true
    mini.Visible = true
    mini2.Visible = false
    main.Frame.BackgroundTransparency = 0 
    closebutton.Position = UDim2.new(0, 0, -1, 27)
end)

-- ドラッグ可能にする
Frame.Active = true
Frame.Draggable = true

-- キャラクター変更時の処理
LocalPlayer.CharacterAdded:Connect(function(character)
    task.wait(0.5) -- キャラクターのロードを待つ
    stopFly()
end)

-- 起動通知
game:GetService("StarterGui"):SetCore("SendNotification", { 
    Title = "FLY GUI V3",
    Text = "BY XNEO - Fixed Version",
    Icon = "rbxthumb://type=Asset&id=5107182114&w=150&h=150",
    Duration = 5
})

print("Fly GUI V3 loaded successfully!")
print("Controls: W/A/S/D to move, SPACE/UP to ascend, SHIFT/DOWN to descend")
print("Speed: " .. tostring(flySpeed))
