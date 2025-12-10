-- 外部スクリプト読み込み部分（元のまま）
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
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- Fly機能の状態管理
local isFlying = false
local flySpeed = 50
local flyVelocity = Vector3.zero
local bodyVelocity, bodyGyro
local flyLoop

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

-- Flyの開始
local function startFly()
    if isFlying then return end
    
    local character = LocalPlayer.Character
    if not character then return end
    
    local humanoid = character:FindFirstChild("Humanoid")
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    
    if not humanoid or not rootPart then return end
    
    isFlying = true
    
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
    
    -- 重力を無効化
    humanoid.PlatformStand = true
    
    -- Flyコントロールループ
    flyLoop = RunService.Heartbeat:Connect(function(delta)
        if not isFlying or not rootPart then
            flyLoop:Disconnect()
            return
        end
        
        -- 移動方向の計算
        local direction = Vector3.zero
        
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then
            direction = direction + rootPart.CFrame.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then
            direction = direction - rootPart.CFrame.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then
            direction = direction - rootPart.CFrame.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then
            direction = direction + rootPart.CFrame.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            direction = direction + Vector3.new(0, 1, 0)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
            direction = direction + Vector3.new(0, -1, 0)
        end
        
        -- 速度の適用
        if direction.Magnitude > 0 then
            direction = direction.Unit * flySpeed
        end
        
        -- 姿勢の維持
        bodyGyro.CFrame = rootPart.CFrame
        
        -- 速度の適用
        if bodyVelocity then
            bodyVelocity.Velocity = direction
        end
    end)
    
    print("Fly mode: ON")
end

-- Flyの停止
local function stopFly()
    if not isFlying then return end
    
    isFlying = false
    
    local character = LocalPlayer.Character
    if character then
        local humanoid = character:FindFirstChild("Humanoid")
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        
        if humanoid then
            humanoid.PlatformStand = false
        end
        
        if bodyVelocity then
            bodyVelocity:Destroy()
            bodyVelocity = nil
        end
        
        if bodyGyro then
            bodyGyro:Destroy()
            bodyGyro = nil
        end
    end
    
    if flyLoop then
        flyLoop:Disconnect()
        flyLoop = nil
    end
    
    print("Fly mode: OFF")
end

-- Flyトグル関数
local function toggleFly()
    if isFlying then
        stopFly()
    else
        startFly()
    end
end

-- Flyツールの作成
local flyTool = Instance.new("Tool")
flyTool.Name = "Fly"
flyTool.RequiresHandle = false
flyTool.CanBeDropped = false
flyTool.ToolTip = "Press to toggle flying"

-- アイコン設定（見た目を良くするため）
local selectionBox = Instance.new("SelectionBox")
selectionBox.Color3 = Color3.fromRGB(0, 170, 255)
selectionBox.LineThickness = 0.05
selectionBox.Adornee = flyTool
selectionBox.Parent = flyTool

-- ツール使用時の処理
flyTool.Activated:Connect(function()
    toggleFly()
end)

-- ツール装備時の処理
flyTool.Equipped:Connect(function()
    print("Fly tool equipped")
end)

-- ツール解除時の処理
flyTool.Unequipped:Connect(function()
    -- 必要に応じてFlyを停止
    -- stopFly()
end)

-- キャラクター変更時の処理
LocalPlayer.CharacterAdded:Connect(function(character)
    -- 新しいキャラクターにFlyを継続
    task.wait(1) -- キャラクターのロードを待つ
    if isFlying then
        stopFly() -- 一旦停止
        task.wait(0.1)
        startFly() -- 再開
    end
end)

-- キー入力による制御（オプション）
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    -- EキーでFlyトグル（オプション）
    if input.KeyCode == Enum.KeyCode.E then
        toggleFly()
    end
end)

-- ゲーム終了時のクリーンアップ
game:GetService("CoreGui").ChildRemoved:Connect(function()
    stopFly()
end)

-- ツールをバックパックに追加
flyTool.Parent = LocalPlayer:WaitForChild("Backpack")

print("Fly tool loaded successfully!")
print("Controls: W/A/S/D = Move, Space = Up, Shift = Down, E = Toggle")
