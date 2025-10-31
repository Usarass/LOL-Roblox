-- REFINED ULTRA-MODERN HP BAR UI

-- Features: Glassmorphism, Advanced Particles, Dynamic Glow, Smooth Animations

-- IMPROVED: Removed big outline, enhanced line styling

local Players = game:GetService("Players")

local RunService = game:GetService("RunService")

local TweenService = game:GetService("TweenService")

local HpBarUI = {}

HpBarUI.__index = HpBarUI

-- REFINED CONFIGURATION - Clean, Modern Design
local CONFIG = {
	StudsOffset = Vector3.new(0, 3.5, 0),
	MaxDistance = 200,
	BillboardSize = UDim2.new(0, 140, 0, 20), -- More rectangular shape

	-- REFINED GLASSMORPHISM
	BackgroundColor = Color3.fromRGB(0, 0, 0),
	BackgroundTransparency = 0.85,

	-- REMOVED: Big outer glow outline
	-- IMPROVED: Subtle inner effects only

	-- ENHANCED HEALTH COLORS (Changed Critical to Red)
	HealthColors = {
		Full = {
			Primary = Color3.fromRGB(46, 204, 113),
			Secondary = Color3.fromRGB(39, 174, 96),
			Glow = Color3.fromRGB(46, 255, 113)
		},
		Medium = {
			Primary = Color3.fromRGB(241, 196, 15),
			Secondary = Color3.fromRGB(243, 156, 18),
			Glow = Color3.fromRGB(255, 220, 15)
		},
		Low = {
			Primary = Color3.fromRGB(231, 76, 60),
			Secondary = Color3.fromRGB(192, 57, 43),
			Glow = Color3.fromRGB(255, 100, 100)
		},
		Critical = {
			Primary = Color3.fromRGB(231, 76, 60), -- Changed to red
			Secondary = Color3.fromRGB(192, 57, 43), -- Changed to red
			Glow = Color3.fromRGB(255, 100, 100) -- Changed to red
		}
	},
	HealthThresholds = {
		Medium = 0.6,
		Low = 0.35,
		Critical = 0.15
	},

	-- IMPROVED SEPARATOR SYSTEM (Better lines with alternating positions)
	HealthPerSeparator = 500,
	SeparatorColor = Color3.fromRGB(0, 0, 0),
	SeparatorTransparency = 0.4,
	SeparatorThickness = 1,
	SeparatorHeight = 0.4,
	SeparatorVerticalOffset = 0, -- Start at top
	SeparatorGlowEnabled = true,
	MaxSeparators = 30,

	-- ADVANCED PARTICLE SYSTEM
	ParticlesEnabled = true,
	HealParticles = {
		Color = Color3.fromRGB(46, 255, 113),
		Count = 8,
		Speed = 2,
		Life = 1.2,
		Size = 3
	},
	DamageParticles = {
		Color = Color3.fromRGB(255, 100, 100),
		Count = 12,
		Speed = 3,
		Life = 0.8,
		Size = 4
	},

	-- MODERN LEVEL DISPLAY
	LevelBoxEnabled = true,
	LevelBoxSize = UDim2.new(0, 24, 0, 20),
	LevelBoxOffset = -30,

	-- SMOOTH ANIMATIONS
	AnimationSpeed = 0.2,
	EasingStyle = Enum.EasingStyle.Quart,
	EasingDirection = Enum.EasingDirection.Out,

	-- CHIP DAMAGE SYSTEM
	ChipDamageEnabled = true,
	ChipDamageDelay = 1.0,
	ChipDamageSpeed = 0.6,
	ChipDamageColor = Color3.fromRGB(139, 69, 19),

	-- SHIELD SYSTEM
	ShieldEnabled = true,
	ShieldColor = Color3.fromRGB(100, 181, 246),
	ShieldGlow = Color3.fromRGB(144, 202, 249),

	-- PULSING EFFECTS
	LowHealthPulse = true,
	PulseSpeed = 1.8,
	PulseIntensity = 0.4,

	-- FLOATING TEXT
	FloatingTextEnabled = true,
	Debug = false,
}

local function dprint(...)
	if CONFIG.Debug then
		print("[Refined HpBarUI]", ...)
	end
end

HpBarUI._registry = {}
HpBarUI._initialized = false

local function disconnectAll(list)
	if not list then return end
	for i = #list, 1, -1 do
		local conn = list[i]
		if conn and conn.Disconnect then
			conn:Disconnect()
		end
		list[i] = nil
	end
end

-- Create refined particle effect
local function createRefinedParticles(billboard, isHealing, amount)
	if not CONFIG.ParticlesEnabled then return end
	local particleConfig = isHealing and CONFIG.HealParticles or CONFIG.DamageParticles
	local particleCount = math.min(particleConfig.Count, math.ceil(amount / 10))
	for i = 1, particleCount do
		local particle = Instance.new("Frame")
		particle.Name = "Particle"
		particle.Size = UDim2.new(0, particleConfig.Size, 0, particleConfig.Size)
		particle.Position = UDim2.new(
			math.random(10, 90) / 100,
			0,
			0.5 + (math.random(-20, 20) / 100),
			0
		)
		particle.BackgroundColor3 = particleConfig.Color
		particle.BorderSizePixel = 0
		particle.ZIndex = 15
		particle.Parent = billboard

		-- Particle glow
		local particleGlow = Instance.new("UIStroke")
		particleGlow.Color = particleConfig.Color
		particleGlow.Thickness = 2
		particleGlow.Transparency = 0.2
		particleGlow.Parent = particle

		-- Rounded particle
		local particleCorner = Instance.new("UICorner")
		particleCorner.CornerRadius = UDim.new(1, 0)
		particleCorner.Parent = particle

		-- Refined particle animation
		local endPos = UDim2.new(
			particle.Position.X.Scale + (math.random(-30, 30) / 100),
			0,
			particle.Position.Y.Scale - (0.4 * particleConfig.Speed),
			0
		)
		local particleTween = TweenService:Create(particle,
			TweenInfo.new(
				particleConfig.Life,
				Enum.EasingStyle.Quad,
				Enum.EasingDirection.Out
			),
			{
				Position = endPos,
				BackgroundTransparency = 1,
				Size = UDim2.new(0, 1, 0, 1),
				Rotation = math.random(-180, 180)
			}
		)
		particleTween:Play()
		particleTween.Completed:Connect(function()
			particle:Destroy()
		end)
	end
end

-- Create floating damage text
local function createFloatingText(billboard, text, color, isHealing)
	if not CONFIG.FloatingTextEnabled then return end
	local textLabel = Instance.new("TextLabel")
	textLabel.Name = "FloatingText"
	textLabel.Size = UDim2.new(0, 60, 0, 20)
	textLabel.Position = UDim2.new(0.5, 0, 0, -10)
	textLabel.AnchorPoint = Vector2.new(0.5, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.Text = text
	textLabel.TextColor3 = color
	textLabel.TextScaled = true
	textLabel.Font = Enum.Font.GothamBold
	textLabel.ZIndex = 20
	textLabel.Parent = billboard

	-- Text glow
	local textStroke = Instance.new("UIStroke")
	textStroke.Color = Color3.fromRGB(0, 0, 0)
	textStroke.Thickness = 2
	textStroke.Transparency = 0.3
	textStroke.Parent = textLabel

	-- Floating animation
	local endPos = UDim2.new(0.5, math.random(-20, 20), 0, -40)
	local floatTween = TweenService:Create(textLabel,
		TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{
			Position = endPos,
			TextTransparency = 1,
			Size = UDim2.new(0, 80, 0, 25)
		}
	)
	floatTween:Play()
	floatTween.Completed:Connect(function()
		textLabel:Destroy()
	end)
end

-- Create refined modern billboard
local function createRefinedBillboard(model: Model, humanoid: Humanoid, head: BasePart, player: Player?)
	dprint("Creating refined modern billboard for", model.Name)
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "RefinedHPBar"
	billboard.AlwaysOnTop = true
	billboard.ExtentsOffsetWorldSpace = CONFIG.StudsOffset
	billboard.MaxDistance = CONFIG.MaxDistance
	billboard.Size = CONFIG.BillboardSize
	billboard.LightInfluence = 0
	billboard.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	billboard.ResetOnSpawn = false
	billboard.Adornee = head
	billboard.Parent = head

	-- REFINED: No big outer outline - clean design

	-- Modern level box
	local levelBox = nil
	if CONFIG.LevelBoxEnabled then
		levelBox = Instance.new("Frame")
		levelBox.Name = "LevelBox"
		levelBox.Size = CONFIG.LevelBoxSize
		levelBox.Position = UDim2.new(0, CONFIG.LevelBoxOffset, 0, 0)
		levelBox.BackgroundColor3 = CONFIG.BackgroundColor
		levelBox.BackgroundTransparency = CONFIG.BackgroundTransparency
		levelBox.BorderSizePixel = 0
		levelBox.Parent = billboard

		-- Glassmorphism styling
		local levelBoxCorner = Instance.new("UICorner")
		levelBoxCorner.CornerRadius = UDim.new(0, 6)
		levelBoxCorner.Parent = levelBox

		local levelBoxStroke = Instance.new("UIStroke")
		levelBoxStroke.Color = Color3.fromRGB(255, 255, 255)
		levelBoxStroke.Thickness = 1
		levelBoxStroke.Transparency = 0.6
		levelBoxStroke.Parent = levelBox

		-- Level text
		local levelText = Instance.new("TextLabel")
		levelText.Name = "LevelText"
		levelText.Size = UDim2.fromScale(1, 1)
		levelText.BackgroundTransparency = 1
		levelText.Text = "1"
		levelText.TextColor3 = Color3.fromRGB(255, 255, 255)
		levelText.TextScaled = true
		levelText.Font = Enum.Font.GothamBold
		levelText.ZIndex = 5
		levelText.Parent = levelBox

		-- Text glow
		local levelTextStroke = Instance.new("UIStroke")
		levelTextStroke.Color = Color3.fromRGB(0, 0, 0)
		levelTextStroke.Thickness = 2
		levelTextStroke.Transparency = 0.4
		levelTextStroke.Parent = levelText
	end

	-- Main glassmorphism background
	local background = Instance.new("Frame")
	background.Name = "Background"
	background.Size = UDim2.fromScale(1, 1)
	background.Position = UDim2.fromScale(0, 0)
	background.BackgroundColor3 = CONFIG.BackgroundColor
	background.BackgroundTransparency = CONFIG.BackgroundTransparency
	background.BorderSizePixel = 0
	background.Parent = billboard

	-- Glassmorphism styling
	local backgroundCorner = Instance.new("UICorner")
	backgroundCorner.CornerRadius = UDim.new(0, 6)
	backgroundCorner.Parent = background

	local backgroundStroke = Instance.new("UIStroke")
	backgroundStroke.Color = Color3.fromRGB(0, 0, 0)
	backgroundStroke.Thickness = 1
	backgroundStroke.Transparency = 0.5
	backgroundStroke.Parent = background

	-- Fill container (with padding to keep health bar inside)
	local fillContainer = Instance.new("Frame")
	fillContainer.Name = "FillContainer"
	fillContainer.Size = UDim2.new(1, -4, 1, -4) -- Padding to keep inside
	fillContainer.Position = UDim2.new(0, 2, 0, 2) -- Centered with padding
	fillContainer.BackgroundTransparency = 1
	fillContainer.ClipsDescendants = true
	fillContainer.Parent = background

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0, 4) -- Match inner radius
	fillCorner.Parent = fillContainer

	-- Chip damage bar
	local chipBar = Instance.new("Frame")
	chipBar.Name = "ChipBar"
	chipBar.Size = UDim2.fromScale(1, 1)
	chipBar.Position = UDim2.fromScale(0, 0)
	chipBar.BackgroundColor3 = CONFIG.ChipDamageColor
	chipBar.BorderSizePixel = 0
	chipBar.ZIndex = 1
	chipBar.Parent = fillContainer

	-- Main health bar
	local healthBar = Instance.new("Frame")
	healthBar.Name = "HealthBar"
	healthBar.Size = UDim2.fromScale(1, 1)
	healthBar.Position = UDim2.fromScale(0, 0)
	healthBar.BackgroundColor3 = CONFIG.HealthColors.Full.Primary
	healthBar.BorderSizePixel = 0
	healthBar.ZIndex = 2
	healthBar.Parent = fillContainer

	-- Health bar gradient
	local healthGradient = Instance.new("UIGradient")
	healthGradient.Name = "HealthGradient"
	healthGradient.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, CONFIG.HealthColors.Full.Primary),
		ColorSequenceKeypoint.new(0.5, CONFIG.HealthColors.Full.Secondary),
		ColorSequenceKeypoint.new(1, CONFIG.HealthColors.Full.Primary)
	}
	healthGradient.Rotation = 45
	healthGradient.Parent = healthBar

	-- Animate gradient
	spawn(function()
		while healthBar.Parent do
			TweenService:Create(healthGradient,
				TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
				{Rotation = 405}
			):Play()
			wait(6)
		end
	end)

	-- Shield bar
	local shieldBar = Instance.new("Frame")
	shieldBar.Name = "ShieldBar"
	shieldBar.Size = UDim2.fromScale(0, 1)
	shieldBar.Position = UDim2.fromScale(1, 0)
	shieldBar.AnchorPoint = Vector2.new(1, 0)
	shieldBar.BackgroundColor3 = CONFIG.ShieldColor
	shieldBar.BorderSizePixel = 0
	shieldBar.ZIndex = 3
	shieldBar.Visible = false
	shieldBar.Parent = fillContainer

	-- Shield glow
	local shieldGlow = Instance.new("UIStroke")
	shieldGlow.Color = CONFIG.ShieldGlow
	shieldGlow.Thickness = 2
	shieldGlow.Transparency = 0.3
	shieldGlow.Parent = shieldBar

	-- IMPROVED SEPARATORS CONTAINER
	local separatorsFolder = Instance.new("Folder")
	separatorsFolder.Name = "Separators"
	separatorsFolder.Parent = background

	return billboard
end

-- Create IMPROVED separator lines with alternating positions
local function rebuildImprovedSeparators(billboard: BillboardGui, humanoid: Humanoid)
	if not billboard or not billboard.Parent then return end
	local background = billboard:FindFirstChild("Background")
	if not background then return end
	local separatorsFolder = background:FindFirstChild("Separators")
	if not separatorsFolder then return end
	local maxHealth = humanoid.MaxHealth
	local separatorCount = math.floor(maxHealth / CONFIG.HealthPerSeparator)
	separatorCount = math.min(separatorCount, CONFIG.MaxSeparators)
	local currentCount = separatorsFolder:GetAttribute("Count") or 0
	if currentCount == separatorCount then return end

	-- Clear existing separators
	for _, child in ipairs(separatorsFolder:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end

	separatorsFolder:SetAttribute("Count", separatorCount)
	if separatorCount <= 0 then return end

	-- Create IMPROVED separator lines with alternating positions
	for i = 1, separatorCount do
		local position = i / (separatorCount + 1)
		local separator = Instance.new("Frame")
		separator.Name = "Separator_" .. i

		-- All lines start at the top (Y = 0) but have different heights for alternating effect
		local verticalOffset = 0 -- All lines start at the top

		if i % 2 == 0 then
			-- Even lines (2nd, 4th, 6th, etc.) - shorter height to create visual difference
			separator.Size = UDim2.new(0, CONFIG.SeparatorThickness, CONFIG.SeparatorHeight * 0.7, 0)
		else
			-- Odd lines (1st, 3rd, 5th, etc.) - full height
			separator.Size = UDim2.new(0, CONFIG.SeparatorThickness, CONFIG.SeparatorHeight, 0)
		end

		separator.Position = UDim2.new(position, 0, verticalOffset, 0)
		separator.BackgroundColor3 = CONFIG.SeparatorColor
		separator.BackgroundTransparency = CONFIG.SeparatorTransparency
		separator.BorderSizePixel = 0
		separator.ZIndex = 10
		separator.Parent = separatorsFolder

		-- IMPROVED: Better glow effect
		if CONFIG.SeparatorGlowEnabled then
			local sepGlow = Instance.new("UIStroke")
			sepGlow.Color = CONFIG.SeparatorColor
			sepGlow.Thickness = 1
			sepGlow.Transparency = 0.5
			sepGlow.Parent = separator
		end
	end
end

-- Get health color based on percentage
local function getHealthColor(ratio)
	if ratio <= CONFIG.HealthThresholds.Critical then
		return CONFIG.HealthColors.Critical
	elseif ratio <= CONFIG.HealthThresholds.Low then
		return CONFIG.HealthColors.Low
	elseif ratio <= CONFIG.HealthThresholds.Medium then
		return CONFIG.HealthColors.Medium
	else
		return CONFIG.HealthColors.Full
	end
end

-- Update health display
local function updateRefinedHealthDisplay(data)
	local billboard = data and data.Billboard
	local humanoid = data and data.Humanoid
	if not billboard or not billboard.Parent or not humanoid then return end
	local background = billboard:FindFirstChild("Background")
	if not background then return end
	local fillContainer = background:FindFirstChild("FillContainer")
	if not fillContainer then return end
	local healthBar = fillContainer:FindFirstChild("HealthBar")
	local chipBar = fillContainer:FindFirstChild("ChipBar")
	local levelBox = billboard:FindFirstChild("LevelBox")
	if not healthBar then return end
	local maxHealth = math.max(humanoid.MaxHealth, 1)
	local currentHealth = humanoid.Health
	local lastHealth = data.LastHealth or currentHealth
	local healthRatio = math.clamp(currentHealth / maxHealth, 0, 1)

	-- Update level display
	if levelBox then
		local levelText = levelBox:FindFirstChild("LevelText")
		if levelText then
			local level = 1
			if data.Player and data.Player:FindFirstChild("leaderstats") then
				local levelStat = data.Player.leaderstats:FindFirstChild("Level")
				if levelStat then
					level = levelStat.Value
				end
			end
			levelText.Text = tostring(level)
		end
	end

	-- Get health colors
	local healthColors = getHealthColor(healthRatio)

	-- Update health bar color
	healthBar.BackgroundColor3 = healthColors.Primary
	local healthGradient = healthBar:FindFirstChild("HealthGradient")
	if healthGradient then
		healthGradient.Color = ColorSequence.new{
			ColorSequenceKeypoint.new(0, healthColors.Primary),
			ColorSequenceKeypoint.new(0.5, healthColors.Secondary),
			ColorSequenceKeypoint.new(1, healthColors.Primary)
		}
	end

	-- Create particles and floating text
	if lastHealth ~= currentHealth then
		local healthDiff = math.abs(currentHealth - lastHealth)
		local isHealing = currentHealth > lastHealth
		createRefinedParticles(billboard, isHealing, healthDiff)

		if CONFIG.FloatingTextEnabled then
			local text = (isHealing and "+" or "-") .. tostring(math.floor(healthDiff))
			local color = isHealing and CONFIG.HealParticles.Color or CONFIG.DamageParticles.Color
			createFloatingText(billboard, text, color, isHealing)
		end
	end

	-- Smooth health bar animation
	local targetSize = UDim2.fromScale(healthRatio, 1)
	if data.ActiveTween then
		data.ActiveTween:Cancel()
		data.ActiveTween = nil
	end

	local tweenInfo = TweenInfo.new(
		CONFIG.AnimationSpeed,
		CONFIG.EasingStyle,
		CONFIG.EasingDirection
	)

	data.ActiveTween = TweenService:Create(healthBar, tweenInfo, {Size = targetSize})
	data.ActiveTween:Play()

	-- Chip damage system
	if chipBar and CONFIG.ChipDamageEnabled then
		data._lagToken = (data._lagToken or 0) + 1
		local myToken = data._lagToken
		local currentChipRatio = chipBar.Size.X.Scale
		if currentHealth > lastHealth then
			if data._chipTween then
				data._chipTween:Cancel()
				data._chipTween = nil
			end

			local healTweenInfo = TweenInfo.new(
				CONFIG.AnimationSpeed * 0.8,
				CONFIG.EasingStyle,
				CONFIG.EasingDirection
			)
			data._chipTween = TweenService:Create(chipBar, healTweenInfo, {Size = targetSize})
			data._chipTween:Play()
		else
			if healthRatio < currentChipRatio then
				task.delay(CONFIG.ChipDamageDelay, function()
					if data._lagToken ~= myToken then return end
					if not chipBar or not chipBar.Parent then return end
					if data._chipTween then
						data._chipTween:Cancel()
						data._chipTween = nil
					end

					local chipTweenInfo = TweenInfo.new(
						CONFIG.ChipDamageSpeed,
						Enum.EasingStyle.Quad,
						Enum.EasingDirection.Out
					)
					data._chipTween = TweenService:Create(chipBar, chipTweenInfo, {Size = UDim2.fromScale(healthRatio, 1)})
					data._chipTween:Play()
				end)
			end
		end
	end

	data.LastHealth = currentHealth
	rebuildImprovedSeparators(billboard, humanoid)
end

-- Attach event listeners
local function attachRefinedListeners(model: Model, data)
	local humanoid = data.Humanoid
	if not humanoid then return end

	table.insert(data.Connections, humanoid.HealthChanged:Connect(function()
		updateRefinedHealthDisplay(data)
	end))

	table.insert(data.Connections, humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(function()
		updateRefinedHealthDisplay(data)
	end))

	table.insert(data.Connections, model.AncestryChanged:Connect(function(_, parent)
		if not parent then
			HpBarUI._destroyForModel(model)
		end
	end))

	table.insert(data.Connections, humanoid.Died:Connect(function()
		local billboard = data.Billboard
		if billboard then
			createRefinedParticles(billboard, false, 100)
			local background = billboard:FindFirstChild("Background")
			if background then
				TweenService:Create(background,
					TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{
						BackgroundTransparency = 1,
						Size = UDim2.fromScale(0, 0)
					}
				):Play()
			end
		end

		task.delay(2, function()
			HpBarUI._destroyForModel(model)
		end)
	end))

	updateRefinedHealthDisplay(data)
end

function HpBarUI._createForModel(model: Model)
	if not model then 
		warn("Refined HpBarUI: _createForModel called with no model") 
		return 
	end

	dprint("Creating refined HP bar for", model.Name)
	HpBarUI._destroyForModel(model)

	local humanoid: Humanoid? = model:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		humanoid = model:WaitForChild("Humanoid", 5)
	end

	if not humanoid or not humanoid:IsA("Humanoid") then 
		warn("Refined HpBarUI: Invalid humanoid for", model.Name) 
		return 
	end

	local head = model:WaitForChild("Head", 5)
	if not head or not head:IsA("BasePart") then 
		warn("Refined HpBarUI: Invalid head for", model.Name) 
		return 
	end

	local player = Players:GetPlayerFromCharacter(model)
	local billboard = createRefinedBillboard(model, humanoid, head, player)

	local data = {
		Character = model,
		Humanoid = humanoid,
		Billboard = billboard,
		Connections = {},
		Player = player,
	}

	HpBarUI._registry[model] = data
	attachRefinedListeners(model, data)
	dprint("Refined HP bar created successfully for", model.Name)
end

function HpBarUI._destroyForModel(model: Model)
	local data = HpBarUI._registry[model]
	if not data then return end

	disconnectAll(data.Connections)
	if data.Billboard and data.Billboard.Parent then
		data.Billboard:Destroy()
	end

	HpBarUI._registry[model] = nil
end

function HpBarUI.refresh(model: Model)
	if not model then return end
	HpBarUI._createForModel(model)
end

function HpBarUI.init()
	if HpBarUI._initialized then return HpBarUI end
	HpBarUI._initialized = true

	local localPlayer = Players.LocalPlayer
	if localPlayer then
		local playerGui = localPlayer:WaitForChild("PlayerGui")
		local container = playerGui:FindFirstChild("RefinedHpBarsGui")
		if not container then
			container = Instance.new("ScreenGui")
			container.Name = "RefinedHpBarsGui"
			container.ResetOnSpawn = false
			container.IgnoreGuiInset = true
			container.Enabled = true
			container.Parent = playerGui
		end

		HpBarUI.ScreenGui = container
	end

	local root = workspace:FindFirstChild("DamagableHumanoids")
	if not root then 
		dprint("No 'DamagableHumanoids' folder found")
		return HpBarUI
	end

	local function processModel(instance)
		if instance:IsA("Model") then
			task.spawn(function()
				HpBarUI._createForModel(instance)
			end)
		end
	end

	local function processFolder(folder)
		for _, child in ipairs(folder:GetChildren()) do
			processModel(child)
		end

		folder.ChildAdded:Connect(processModel)
	end

	root.ChildAdded:Connect(function(instance)
		if instance:IsA("Model") then
			processModel(instance)
		elseif instance:IsA("Folder") then
			processFolder(instance)
		end
	end)

	-- Process existing children
	for _, instance in ipairs(root:GetChildren()) do
		if instance:IsA("Model") then
			processModel(instance)
		elseif instance:IsA("Folder") then
			processFolder(instance)
		end
	end

	dprint("Refined HP Bar system initialized successfully")
	return HpBarUI
end

function HpBarUI.open()
	if HpBarUI.ScreenGui then
		HpBarUI.ScreenGui.Enabled = true
	end
end

function HpBarUI.close()
	if HpBarUI.ScreenGui then
		HpBarUI.ScreenGui.Enabled = false
	end
end

function HpBarUI.destruct()
	for model, _ in pairs(HpBarUI._registry) do
		HpBarUI._destroyForModel(model)
	end

	HpBarUI._initialized = false
end

return HpBarUI