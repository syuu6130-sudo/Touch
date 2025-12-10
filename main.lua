-- ============================================
-- ENHANCED PLAYER CONTROL SCRIPT v2.0
-- Safe, Efficient, and Feature-Rich
-- ============================================

-- Initialize services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")
local MarketplaceService = game:GetService("MarketplaceService")

-- Configuration
local CONFIG = {
    DEBUG_MODE = false,
    VERSION = "2.0.1",
    AUTHOR = "Enhanced Script",
    
    -- Movement settings
    BASE_MOVE_FORCE = 12,
    THROW_FORCE = Vector3.new(80, 60, 0),
    MAX_TARGETS = 10,
    
    -- UI settings
    UI_OPACITY = 0.85,
    ANIMATION_SPEED = 0.2,
    HIGHLIGHT_COLORS = {
        SINGLE = Color3.fromRGB(0, 170, 255),
        MULTIPLE = Color3.fromRGB(255, 170, 0),
        LOCKED = Color3.fromRGB(255, 50, 50)
    },
    
    -- Keybinds (customizable)
    KEYBINDS = {
        TOGGLE_UI = Enum.KeyCode.RightControl,
        CLEAR_TARGETS = Enum.KeyCode.C,
        QUICK_THROW = Enum.KeyCode.T
    }
}

-- Safe module loader with fallback
local function loadExternalModule()
    local moduleScript = nil
    
    -- Try to find existing module first
    for _, obj in ipairs(game:GetDescendants()) do
        if obj:IsA("ModuleScript") and obj.Name == "EnhancedControlModule" then
            moduleScript = obj
            break
        end
    end
    
    -- Create fallback module if not found
    if not moduleScript then
        moduleScript = Instance.new("ModuleScript")
        moduleScript.Name = "EnhancedControlModule"
        
        -- Basic movement functions
        moduleScript.Source = [[
            local module = {}
            
            function module.getSafeCharacter(player)
                return player and player.Character and player.Character:FindFirstChild("Humanoid") and player.Character
            end
            
            function module.isValidTarget(target)
                if not target then return false end
                local humanoid = target:FindFirstChildOfClass("Humanoid")
                local root = target:FindFirstChild("HumanoidRootPart") or target:FindFirstChild("Torso")
                return humanoid and root and humanoid.Health > 0
            end
            
            function module.applyForce(target, forceVector, forceType)
                local root = target:FindFirstChild("HumanoidRootPart") or target:FindFirstChild("Torso")
                if not root then return false end
                
                -- Check if BodyVelocity exists (some games use custom physics)
                local bodyVelocity = root:FindFirstChildOfClass("BodyVelocity")
                if bodyVelocity then
                    bodyVelocity.Velocity = forceVector
                    bodyVelocity.MaxForce = Vector3.new(4000, 4000, 4000)
                    return true
                end
                
                -- Alternative: Use network ownership (safer)
                if root:CanSetNetworkOwnership() then
                    root:SetNetworkOwnership(false)
                end
                
                -- Apply impulse if possible
                local mass = root:GetMass()
                root:ApplyImpulse(forceVector * mass)
                return true
            end
            
            return module
        ]]
        
        moduleScript.Parent = game:GetService("ReplicatedStorage")
    end
    
    return require(moduleScript)
end

-- Initialize
local ControlModule = loadExternalModule()
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- State management
local state = {
    currentMode = "Single",
    selectedTarget = nil,
    selectedTargets = {},
    isLocked = false,
    isUIVisible = true,
    isInitialized = false,
    
    connections = {},
    highlights = {},
    uiElements = {},
    
    movementDirections = {
        Up = false,
        Down = false,
        Left = false,
        Right = false,
        Forward = false,
        Backward = false
    }
}

-- Safe initialization check
if not LocalPlayer then
    warn("Player not found. Script cannot initialize.")
    return
end

-- Enhanced logging system
local Logger = {
    log = function(message, level)
        if not CONFIG.DEBUG_MODE and level == "DEBUG" then return end
        
        local timestamp = os.date("%H:%M:%S")
        local prefix = level and string.format("[%s] ", level:upper()) or ""
        print(string.format("%s %s%s", timestamp, prefix, message))
    end,
    
    warn = function(message)
        warn(string.format("[WARN] %s", message))
    end,
    
    error = function(message)
        error(string.format("[ERROR] %s", message))
    end
}

Logger.log(string.format("Enhanced Control Script v%s Initializing...", CONFIG.VERSION), "INFO")

-- ============================================
-- ENHANCED UI BUILDER
-- ============================================

local UIBuilder = {
    createElement = function(elementType, properties)
        local element = Instance.new(elementType)
        
        -- Apply default properties based on element type
        if elementType == "Frame" then
            element.BackgroundTransparency = 0.3
            element.BorderSizePixel = 0
        elseif elementType == "TextButton" then
            element.AutoButtonColor = true
            element.TextColor3 = Color3.new(1, 1, 1)
            element.Font = Enum.Font.GothamBold
            element.TextSize = 14
        elseif elementType == "TextLabel" then
            element.TextColor3 = Color3.new(1, 1, 1)
            element.Font = Enum.Font.Gotham
            element.TextSize = 14
            element.BackgroundTransparency = 1
        end
        
        -- Apply custom properties
        for property, value in pairs(properties) do
            if property ~= "Parent" then
                pcall(function()
                    element[property] = value
                end)
            end
        end
        
        -- Create rounded corners
        if not properties.UICornerDisabled then
            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 6)
            corner.Parent = element
        end
        
        -- Add drop shadow for depth
        if properties.Shadow then
            local shadow = Instance.new("UIStroke")
            shadow.Color = Color3.fromRGB(0, 0, 0)
            shadow.Thickness = 1
            shadow.Transparency = 0.5
            shadow.Parent = element
        end
        
        -- Set parent last
        if properties.Parent then
            element.Parent = properties.Parent
        end
        
        return element
    end,
    
    createTooltip = function(parent, text)
        local tooltip = UIBuilder.createElement("TextLabel", {
            Name = "Tooltip",
            Text = text,
            Size = UDim2.new(1, 0, 0, 20),
            Position = UDim2.new(0, 0, -0.3, 0),
            Visible = false,
            ZIndex = 100,
            Parent = parent
        })
        
        local bg = UIBuilder.createElement("Frame", {
            Name = "TooltipBG",
            Size = UDim2.new(1, 10, 1, 10),
            Position = UDim2.new(0, -5, 0, -5),
            BackgroundColor3 = Color3.fromRGB(20, 20, 20),
            ZIndex = 99,
            Parent = tooltip
        })
        
        -- Show/hide on hover
        parent.MouseEnter:Connect(function()
            tooltip.Visible = true
            local tween = TweenService:Create(tooltip, TweenInfo.new(0.2), {Position = UDim2.new(0, 0, -0.5, 0)})
            tween:Play()
        end)
        
        parent.MouseLeave:Connect(function()
            tooltip.Visible = false
        end)
        
        return tooltip
    end
}

-- ============================================
-- MAIN UI CONSTRUCTION
-- ============================================

-- Create main container with improved layout
local screenGui = UIBuilder.createElement("ScreenGui", {
    Name = "EnhancedControlUI",
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    Parent = LocalPlayer:WaitForChild("PlayerGui")
})

state.uiElements.mainGui = screenGui

-- Main control panel
local mainFrame = UIBuilder.createElement("Frame", {
    Name = "ControlPanel",
    Size = UDim2.new(0, 320, 0, 400),
    Position = UDim2.new(1, -340, 0.5, -200),
    BackgroundColor3 = Color3.fromRGB(25, 25, 30),
    BackgroundTransparency = 0.1,
    Parent = screenGui
})

-- Title bar
local titleBar = UIBuilder.createElement("Frame", {
    Name = "TitleBar",
    Size = UDim2.new(1, 0, 0, 30),
    BackgroundColor3 = Color3.fromRGB(40, 40, 45),
    Parent = mainFrame
})

local titleLabel = UIBuilder.createElement("TextLabel", {
    Name = "Title",
    Text = "ENHANCED CONTROL PANEL v" .. CONFIG.VERSION,
    Size = UDim2.new(1, -60, 1, 0),
    Position = UDim2.new(0, 10, 0, 0),
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = titleBar
})

-- Close button
local closeButton = UIBuilder.createElement("TextButton", {
    Name = "CloseButton",
    Text = "×",
    Size = UDim2.new(0, 30, 1, 0),
    Position = UDim2.new(1, -30, 0, 0),
    BackgroundColor3 = Color3.fromRGB(200, 50, 50),
    Parent = titleBar
})

closeButton.MouseButton1Click:Connect(function()
    screenGui.Enabled = not screenGui.Enabled
    closeButton.Text = screenGui.Enabled and "×" or "+"
end)

-- Content frame
local contentFrame = UIBuilder.createElement("Frame", {
    Name = "Content",
    Size = UDim2.new(1, -20, 1, -50),
    Position = UDim2.new(0, 10, 0, 40),
    BackgroundTransparency = 1,
    Parent = mainFrame
})

-- ============================================
-- MOVEMENT CONTROL GRID
-- ============================================

local movementGrid = UIBuilder.createElement("Frame", {
    Name = "MovementGrid",
    Size = UDim2.new(1, 0, 0, 180),
    BackgroundTransparency = 1,
    Parent = contentFrame
})

-- Grid layout
local gridLayout = Instance.new("UIGridLayout")
gridLayout.CellSize = UDim2.new(0, 80, 0, 50)
gridLayout.CellPadding = UDim2.new(0, 5, 0, 5)
gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
gridLayout.StartCorner = Enum.StartCorner.TopLeft
gridLayout.Parent = movementGrid

-- Direction buttons with icons
local directionButtons = {
    {name = "Up", text = "↑", row = 1, col = 2, color = Color3.fromRGB(60, 120, 200)},
    {name = "Left", text = "←", row = 2, col = 1, color = Color3.fromRGB(60, 120, 200)},
    {name = "Center", text = "•", row = 2, col = 2, color = Color3.fromRGB(100, 100, 100)},
    {name = "Right", text = "→", row = 2, col = 3, color = Color3.fromRGB(60, 120, 200)},
    {name = "Down", text = "↓", row = 3, col = 2, color = Color3.fromRGB(60, 120, 200)},
    {name = "Forward", text = "F↑", row = 1, col = 4, color = Color3.fromRGB(80, 160, 100)},
    {name = "Backward", text = "B↓", row = 3, col = 4, color = Color3.fromRGB(80, 160, 100)}
}

for _, btnInfo in ipairs(directionButtons) do
    local btn = UIBuilder.createElement("TextButton", {
        Name = btnInfo.name .. "Button",
        Text = btnInfo.text,
        BackgroundColor3 = btnInfo.color,
        Parent = movementGrid
    })
    
    UIBuilder.createTooltip(btn, btnInfo.name .. " Movement")
    state.uiElements[btnInfo.name .. "Button"] = btn
end

-- ============================================
-- CONTROL BUTTONS
-- ============================================

local controlSection = UIBuilder.createElement("Frame", {
    Name = "ControlSection",
    Size = UDim2.new(1, 0, 0, 150),
    Position = UDim2.new(0, 0, 0, 190),
    BackgroundTransparency = 1,
    Parent = contentFrame
})

local controlButtons = {
    {
        name = "ModeToggle",
        text = "Mode: Single",
        position = UDim2.new(0, 0, 0, 0),
        size = UDim2.new(0.48, 0, 0, 40),
        color = Color3.fromRGB(70, 70, 120)
    },
    {
        name = "LockToggle",
        text = "🔒 Lock Target",
        position = UDim2.new(0.52, 0, 0, 0),
        size = UDim2.new(0.48, 0, 0, 40),
        color = Color3.fromRGB(120, 70, 70)
    },
    {
        name = "ThrowButton",
        text = "🚀 THROW",
        position = UDim2.new(0, 0, 0, 50),
        size = UDim2.new(1, 0, 0, 45),
        color = Color3.fromRGB(200, 100, 50)
    },
    {
        name = "ClearButton",
        text = "Clear Targets",
        position = UDim2.new(0, 0, 0, 105),
        size = UDim2.new(0.48, 0, 0, 35),
        color = Color3.fromRGB(70, 70, 70)
    },
    {
        name = "SettingsButton",
        text = "⚙ Settings",
        position = UDim2.new(0.52, 0, 0, 105),
        size = UDim2.new(0.48, 0, 0, 35),
        color = Color3.fromRGB(70, 70, 70)
    }
}

for _, btnInfo in ipairs(controlButtons) do
    local btn = UIBuilder.createElement("TextButton", {
        Name = btnInfo.name,
        Text = btnInfo.text,
        Size = btnInfo.size,
        Position = btnInfo.position,
        BackgroundColor3 = btnInfo.color,
        Parent = controlSection
    })
    
    state.uiElements[btnInfo.name] = btn
end

-- ============================================
-- TARGET INFO PANEL
-- ============================================

local infoPanel = UIBuilder.createElement("Frame", {
    Name = "InfoPanel",
    Size = UDim2.new(1, 0, 0, 60),
    Position = UDim2.new(0, 0, 1, 10),
    BackgroundColor3 = Color3.fromRGB(30, 30, 35),
    Parent = contentFrame
})

local targetCountLabel = UIBuilder.createElement("TextLabel", {
    Name = "TargetCount",
    Text = "Targets: 0",
    Size = UDim2.new(1, -10, 0.5, -5),
    Position = UDim2.new(0, 5, 0, 5),
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = infoPanel
})

local statusLabel = UIBuilder.createElement("TextLabel", {
    Name = "Status",
    Text = "Status: Ready",
    Size = UDim2.new(1, -10, 0.5, -5),
    Position = UDim2.new(0, 5, 0.5, 5),
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = infoPanel
})

state.uiElements.targetCountLabel = targetCountLabel
state.uiElements.statusLabel = statusLabel

-- ============================================
-- SETTINGS PANEL (HIDDEN BY DEFAULT)
-- ============================================

local settingsPanel = UIBuilder.createElement("Frame", {
    Name = "SettingsPanel",
    Size = UDim2.new(1, 0, 1, 0),
    Position = UDim2.new(1, 0, 0, 0),
    BackgroundColor3 = Color3.fromRGB(30, 30, 40),
    Visible = false,
    Parent = mainFrame
})

local settingsContent = {
    {"ForceSlider", "Move Force: " .. CONFIG.BASE_MOVE_FORCE, 0, 50, CONFIG.BASE_MOVE_FORCE},
    {"MaxTargets", "Max Targets: " .. CONFIG.MAX_TARGETS, 1, 20, CONFIG.MAX_TARGETS},
    {"UIOpacity", "UI Opacity: " .. CONFIG.UI_OPACITY, 0.1, 1, CONFIG.UI_OPACITY}
}

local yPos = 10
for i, setting in ipairs(settingsContent) do
    local label = UIBuilder.createElement("TextLabel", {
        Name = setting[1] .. "Label",
        Text = setting[2],
        Size = UDim2.new(1, -20, 0, 25),
        Position = UDim2.new(0, 10, 0, yPos),
        Parent = settingsPanel
    })
    
    local slider = UIBuilder.createElement("TextButton", {
        Name = setting[1] .. "Slider",
        Text = "",
        Size = UDim2.new(1, -20, 0, 15),
        Position = UDim2.new(0, 10, 0, yPos + 25),
        BackgroundColor3 = Color3.fromRGB(80, 80, 80),
        Parent = settingsPanel
    })
    
    local fill = UIBuilder.createElement("Frame", {
        Name = "Fill",
        Size = UDim2.new((setting[5] - setting[3]) / (setting[4] - setting[3]), 0, 1, 0),
        BackgroundColor3 = Color3.fromRGB(0, 170, 255),
        Parent = slider
    })
    
    yPos = yPos + 50
end

local closeSettings = UIBuilder.createElement("TextButton", {
    Name = "CloseSettings",
    Text = "← Back",
    Size = UDim2.new(0.5, 0, 0, 30),
    Position = UDim2.new(0.25, 0, 1, -40),
    BackgroundColor3 = Color3.fromRGB(70, 70, 70),
    Parent = settingsPanel
})

-- ============================================
-- ENHANCED HIGHLIGHT SYSTEM
-- ============================================

local HighlightManager = {
    activeHighlights = {},
    
    applyHighlight = function(target, highlightType)
        if not ControlModule.isValidTarget(target) then return nil end
        
        -- Remove existing highlight
        HighlightManager.removeHighlight(target)
        
        local highlight = Instance.new("Highlight")
        highlight.Name = "EnhancedHighlight_" .. target.Name
        highlight.Adornee = target
        
        -- Configure based on type
        if highlightType == "SINGLE" then
            highlight.FillColor = CONFIG.HIGHLIGHT_COLORS.SINGLE
            highlight.FillTransparency = 0.7
            highlight.OutlineColor = CONFIG.HIGHLIGHT_COLORS.SINGLE
            highlight.OutlineTransparency = 0
        elseif highlightType == "MULTIPLE" then
            highlight.FillColor = CONFIG.HIGHLIGHT_COLORS.MULTIPLE
            highlight.FillTransparency = 0.8
            highlight.OutlineColor = CONFIG.HIGHLIGHT_COLORS.MULTIPLE
            highlight.OutlineTransparency = 0
        elseif highlightType == "LOCKED" then
            highlight.FillColor = CONFIG.HIGHLIGHT_COLORS.LOCKED
            highlight.FillTransparency = 0.6
            highlight.OutlineColor = CONFIG.HIGHLIGHT_COLORS.LOCKED
            highlight.OutlineTransparency = 0
        end
        
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Parent = target
        
        HighlightManager.activeHighlights[target] = highlight
        
        -- Pulse animation
        task.spawn(function()
            local pulseTime = 0.5
            local startTransparency = highlight.FillTransparency
            for i = 1, 3 do
                local tweenOut = TweenService:Create(highlight, TweenInfo.new(pulseTime/2), {FillTransparency = startTransparency + 0.2})
                local tweenIn = TweenService:Create(highlight, TweenInfo.new(pulseTime/2), {FillTransparency = startTransparency})
                tweenOut:Play()
                tweenOut.Completed:Wait()
                tweenIn:Play()
                tweenIn.Completed:Wait()
            end
        end)
        
        return highlight
    end,
    
    removeHighlight = function(target)
        local highlight = HighlightManager.activeHighlights[target]
        if highlight then
            highlight:Destroy()
            HighlightManager.activeHighlights[target] = nil
        end
    end,
    
    clearAllHighlights = function()
        for target, highlight in pairs(HighlightManager.activeHighlights) do
            highlight:Destroy()
        end
        HighlightManager.activeHighlights = {}
    end,
    
    updateHighlightMode = function()
        for target, highlight in pairs(HighlightManager.activeHighlights) do
            local isInMulti = table.find(state.selectedTargets, target)
            local isLocked = state.isLocked and target == state.selectedTarget
            
            if isLocked then
                highlight.FillColor = CONFIG.HIGHLIGHT_COLORS.LOCKED
                highlight.OutlineColor = CONFIG.HIGHLIGHT_COLORS.LOCKED
            elseif isInMulti then
                highlight.FillColor = CONFIG.HIGHLIGHT_COLORS.MULTIPLE
                highlight.OutlineColor = CONFIG.HIGHLIGHT_COLORS.MULTIPLE
            else
                highlight.FillColor = CONFIG.HIGHLIGHT_COLORS.SINGLE
                highlight.OutlineColor = CONFIG.HIGHLIGHT_COLORS.SINGLE
            end
        end
    end
}

-- ============================================
-- TARGET MANAGEMENT
-- ============================================

local TargetManager = {
    addTarget = function(target)
        if not ControlModule.isValidTarget(target) then
            Logger.log("Invalid target: " .. tostring(target), "DEBUG")
            return false
        end
        
        local player = Players:GetPlayerFromCharacter(target)
        if not player or player == LocalPlayer then
            Logger.log("Cannot target self or non-player", "DEBUG")
            return false
        end
        
        if state.currentMode == "Single" then
            TargetManager.clearTargets()
            state.selectedTarget = target
            
            HighlightManager.applyHighlight(target, "SINGLE")
            Logger.log("Selected single target: " .. player.Name, "INFO")
            
        else -- Multiple mode
            if #state.selectedTargets >= CONFIG.MAX_TARGETS then
                Logger.log("Max targets reached (" .. CONFIG.MAX_TARGETS .. ")", "WARN")
                return false
            end
            
            if not table.find(state.selectedTargets, target) then
                table.insert(state.selectedTargets, target)
                HighlightManager.applyHighlight(target, "MULTIPLE")
                Logger.log("Added target: " .. player.Name .. " (" .. #state.selectedTargets .. "/" .. CONFIG.MAX_TARGETS .. ")", "INFO")
            end
        end
        
        TargetManager.updateUI()
        return true
    end,
    
    clearTargets = function()
        state.selectedTarget = nil
        state.selectedTargets = {}
        HighlightManager.clearAllHighlights()
        TargetManager.updateUI()
        Logger.log("All targets cleared", "INFO")
    end,
    
    removeTarget = function(target)
        if state.selectedTarget == target then
            state.selectedTarget = nil
        end
        
        local index = table.find(state.selectedTargets, target)
        if index then
            table.remove(state.selectedTargets, index)
            HighlightManager.removeHighlight(target)
        end
        
        TargetManager.updateUI()
    end,
    
    getCurrentTargets = function()
        local targets = {}
        
        if state.currentMode == "Single" and state.selectedTarget then
            table.insert(targets, state.selectedTarget)
        elseif state.currentMode == "Multiple" then
            for _, target in ipairs(state.selectedTargets) do
                if ControlModule.isValidTarget(target) then
                    table.insert(targets, target)
                end
            end
        end
        
        return targets
    end,
    
    updateUI = function()
        local totalTargets = state.currentMode == "Single" and 
                            (state.selectedTarget and 1 or 0) or 
                            #state.selectedTargets
        
        state.uiElements.targetCountLabel.Text = "Targets: " .. totalTargets
        state.uiElements.statusLabel.Text = "Mode: " .. state.currentMode .. " | " .. 
                                           (state.isLocked and "LOCKED" or "READY")
        
        -- Update mode button text
        state.uiElements.ModeToggle.Text = "Mode: " .. state.currentMode
        
        -- Update lock button
        state.uiElements.LockToggle.Text = state.isLocked and "🔓 Unlock" or "🔒 Lock"
        state.uiElements.LockToggle.BackgroundColor3 = state.isLocked and 
            Color3.fromRGB(70, 200, 70) or 
            Color3.fromRGB(200, 70, 70)
            
        -- Update highlights
        HighlightManager.updateHighlightMode()
    end
}

-- ============================================
-- MOVEMENT SYSTEM
-- ============================================

local MovementSystem = {
    activeLoop = nil,
    
    startMovement = function(direction)
        if not state.movementDirections[direction] then
            state.movementDirections[direction] = true
            MovementSystem.updateMovementLoop()
        end
    end,
    
    stopMovement = function(direction)
        if state.movementDirections[direction] then
            state.movementDirections[direction] = false
            MovementSystem.updateMovementLoop()
        end
    end,
    
    getMovementVector = function()
        local character = ControlModule.getSafeCharacter(LocalPlayer)
        if not character or not character:FindFirstChild("HumanoidRootPart") then
            return Vector3.zero
        end
        
        local hrp = character.HumanoidRootPart
        local forward = hrp.CFrame.LookVector
        local right = hrp.CFrame.RightVector
        local up = Vector3.new(0, 1, 0)
        
        local direction = Vector3.zero
        
        if state.movementDirections.Up then direction += up end
        if state.movementDirections.Down then direction -= up end
        if state.movementDirections.Forward then direction += forward end
        if state.movementDirections.Backward then direction -= forward end
        if state.movementDirections.Right then direction += right end
        if state.movementDirections.Left then direction -= right end
        
        return direction.Unit * CONFIG.BASE_MOVE_FORCE
    end,
    
    updateMovementLoop = function()
        -- Check if any direction is active
        local anyActive = false
        for _, isActive in pairs(state.movementDirections) do
            if isActive then
                anyActive = true
                break
            end
        end
        
        -- Start or stop loop
        if anyActive and not MovementSystem.activeLoop then
            MovementSystem.activeLoop = RunService.Heartbeat:Connect(function()
                local targets = TargetManager.getCurrentTargets()
                local moveVector = MovementSystem.getMovementVector()
                
                if moveVector.Magnitude > 0 and #targets > 0 then
                    for _, target in ipairs(targets) do
                        ControlModule.applyForce(target, moveVector, "continuous")
                    end
                end
            end)
            Logger.log("Movement loop started", "DEBUG")
            
        elseif not anyActive and MovementSystem.activeLoop then
            MovementSystem.activeLoop:Disconnect()
            MovementSystem.activeLoop = nil
            Logger.log("Movement loop stopped", "DEBUG")
        end
    end,
    
    throwTarget = function()
        local targets = TargetManager.getCurrentTargets()
        if #targets == 0 then
            Logger.log("No targets to throw", "WARN")
            return
        end
        
        local character = ControlModule.getSafeCharacter(LocalPlayer)
        if not character or not character:FindFirstChild("HumanoidRootPart") then
            Logger.log("Cannot throw: Player character invalid", "WARN")
            return
        end
        
        local forward = character.HumanoidRootPart.CFrame.LookVector
        local throwForce = forward * CONFIG.THROW_FORCE.X + 
                          Vector3.new(0, CONFIG.THROW_FORCE.Y, 0) + 
                          forward * CONFIG.THROW_FORCE.Z
        
        for _, target in ipairs(targets) do
            ControlModule.applyForce(target, throwForce, "impulse")
        end
        
        Logger.log("Threw " .. #targets .. " target(s)", "INFO")
    end
}

-- ============================================
-- INPUT HANDLING
-- ============================================

local InputHandler = {
    bindDirectionButton = function(button, direction)
        button.MouseButton1Down:Connect(function()
            MovementSystem.startMovement(direction)
            button.BackgroundColor3 = button.BackgroundColor3:Lerp(Color3.new(1, 1, 1), 0.3)
        end)
        
        button.MouseButton1Up:Connect(function()
            MovementSystem.stopMovement(direction)
            button.BackgroundColor3 = button.BackgroundColor3:Lerp(Color3.new(0.3, 0.3, 0.3), 0.7)
        end)
        
        button.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch then
                MovementSystem.startMovement(direction)
            end
        end)
        
        button.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch then
                MovementSystem.stopMovement(direction)
            end
        end)
    end,
    
    setupKeyboardShortcuts = function()
        local keyConnections = {}
        
        -- Toggle UI visibility
        table.insert(keyConnections, UserInputService.InputBegan:Connect(function(input)
            if input.KeyCode == CONFIG.KEYBINDS.TOGGLE_UI then
                screenGui.Enabled = not screenGui.Enabled
                Logger.log("UI " .. (screenGui.Enabled and "shown" or "hidden"), "INFO")
            elseif input.KeyCode == CONFIG.KEYBINDS.CLEAR_TARGETS then
                TargetManager.clearTargets()
            elseif input.KeyCode == CONFIG.KEYBINDS.QUICK_THROW then
                MovementSystem.throwTarget()
            end
        end))
        
        -- Add mouse click for target selection
        table.insert(keyConnections, UserInputService.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                local target = Mouse.Target
                if target then
                    local model = target:FindFirstAncestorOfClass("Model")
                    if model then
                        TargetManager.addTarget(model)
                    end
                end
            end
        end))
        
        return keyConnections
    end,
    
    setupButtonEvents = function()
        -- Mode toggle
        state.uiElements.ModeToggle.MouseButton1Click:Connect(function()
            state.currentMode = state.currentMode == "Single" and "Multiple" or "Single"
            TargetManager.updateUI()
            Logger.log("Switched to " .. state.currentMode .. " mode", "INFO")
        end)
        
        -- Lock toggle
        state.uiElements.LockToggle.MouseButton1Click:Connect(function()
            state.isLocked = not state.isLocked
            TargetManager.updateUI()
            Logger.log("Target lock " .. (state.isLocked and "enabled" or "disabled"), "INFO")
        end)
        
        -- Throw button
        state.uiElements.ThrowButton.MouseButton1Click:Connect(function()
            MovementSystem.throwTarget()
        end)
        
        -- Clear button
        state.uiElements.ClearButton.MouseButton1Click:Connect(function()
            TargetManager.clearTargets()
        end)
        
        -- Settings button
        state.uiElements.SettingsButton.MouseButton1Click:Connect(function()
            settingsPanel.Visible = true
            local tween = TweenService:Create(settingsPanel, TweenInfo.new(0.3), {Position = UDim2.new(0, 0, 0, 0)})
            tween:Play()
        end)
        
        -- Close settings
        closeSettings.MouseButton1Click:Connect(function()
            local tween = TweenService:Create(settingsPanel, TweenInfo.new(0.3), {Position = UDim2.new(1, 0, 0, 0)})
            tween:Play()
            tween.Completed:Connect(function()
                settingsPanel.Visible = false
            end)
        end)
    end
}

-- ============================================
-- INITIALIZATION
-- ============================================

local function initialize()
    if state.isInitialized then return end
    
    Logger.log("Initializing Enhanced Control System...", "INFO")
    
    -- Bind direction buttons
    InputHandler.bindDirectionButton(state.uiElements.UpButton, "Up")
    InputHandler.bindDirectionButton(state.uiElements.DownButton, "Down")
    InputHandler.bindDirectionButton(state.uiElements.LeftButton, "Left")
    InputHandler.bindDirectionButton(state.uiElements.RightButton, "Right")
    InputHandler.bindDirectionButton(state.uiElements.ForwardButton, "Forward")
    InputHandler.bindDirectionButton(state.uiElements.BackwardButton, "Backward")
    
    -- Setup button events
    InputHandler.setupButtonEvents()
    
    -- Setup keyboard shortcuts
    local keyConnections = InputHandler.setupKeyboardShortcuts()
    for _, conn in ipairs(keyConnections) do
        table.insert(state.connections, conn)
    end
    
    -- Initial UI update
    TargetManager.updateUI()
    
    -- Add cleanup connection
    table.insert(state.connections, game:GetService("CoreGui").ChildRemoved:Connect(function(child)
        if child == screenGui then
            Logger.log("UI removed, cleaning up...", "WARN")
            for _, conn in ipairs(state.connections) do
                pcall(function() conn:Disconnect() end)
            end
            HighlightManager.clearAllHighlights()
            if MovementSystem.activeLoop then
                MovementSystem.activeLoop:Disconnect()
            end
        end
    end))
    
    -- Character added/removed handling
    table.insert(state.connections, LocalPlayer.CharacterAdded:Connect(function()
        task.wait(1) -- Wait for character to fully load
        Logger.log("Character loaded, resetting state", "INFO")
        TargetManager.clearTargets()
        state.isLocked = false
    end))
    
    state.isInitialized = true
    Logger.log("Enhanced Control System initialized successfully!", "INFO")
    
    -- Show welcome notification
    task.spawn(function()
        task.wait(1)
        StarterGui:SetCore("SendNotification", {
            Title = "Enhanced Control v" .. CONFIG.VERSION,
            Text = "Control Panel Loaded!\nUse Right Ctrl to toggle UI",
            Duration = 5,
            Icon = "rbxassetid://4483345998"
        })
    end)
end

-- ============================================
-- SAFE SHUTDOWN AND CLEANUP
-- ============================================

local function cleanup()
    Logger.log("Performing cleanup...", "INFO")
    
    -- Disconnect all connections
    for _, conn in ipairs(state.connections) do
        pcall(function() conn:Disconnect() end)
    end
    
    -- Stop movement loop
    if MovementSystem.activeLoop then
        MovementSystem.activeLoop:Disconnect()
        MovementSystem.activeLoop = nil
    end
    
    -- Clear highlights
    HighlightManager.clearAllHighlights()
    
    -- Remove UI
    if screenGui and screenGui.Parent then
        screenGui:Destroy()
    end
    
    -- Clear state
    state.connections = {}
    state.isInitialized = false
    
    Logger.log("Cleanup completed", "INFO")
end

-- ============================================
-- ERROR HANDLING AND PROTECTION
-- ============================================

-- Protected execution wrapper
local function protectedExecute(func, errorMessage)
    local success, result = pcall(func)
    if not success then
        Logger.error(errorMessage .. ": " .. tostring(result))
        return nil
    end
    return result
end

-- Main execution with error protection
local success, err = pcall(function()
    -- Wait for player to be ready
    if not LocalPlayer.Character then
        LocalPlayer.CharacterAdded:Wait()
    end
    
    -- Initialize
    initialize()
    
    -- Keep script alive
    while true do
        -- Periodically clean up invalid targets
        for i = #state.selectedTargets, 1, -1 do
            local target = state.selectedTargets[i]
            if not ControlModule.isValidTarget(target) then
                table.remove(state.selectedTargets, i)
                HighlightManager.removeHighlight(target)
            end
        end
        
        if state.selectedTarget and not ControlModule.isValidTarget(state.selectedTarget) then
            state.selectedTarget = nil
        end
        
        TargetManager.updateUI()
        task.wait(5) -- Check every 5 seconds
    end
end)

if not success then
    Logger.error("Fatal error in main execution: " .. tostring(err))
    
    -- Attempt emergency cleanup
    pcall(cleanup)
    
    -- Notify user
    StarterGui:SetCore("SendNotification", {
        Title = "Control System Error",
        Text = "An error occurred. Please rejoin.",
        Duration = 10,
        Icon = "rbxassetid://4483345998"
    })
end

-- Return cleanup function for external access if needed
return {
    cleanup = cleanup,
    getState = function() return state end,
    getConfig = function() return CONFIG end
}
