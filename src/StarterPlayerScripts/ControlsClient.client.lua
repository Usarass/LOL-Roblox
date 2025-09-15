local player = game.Players.LocalPlayer
local camera = workspace.CurrentCamera

local UserInputService = game:GetService("UserInputService")

local Controls = require(game:GetService("ReplicatedStorage").Services.Controls)
local CharacterLiterals = require(game:GetService("ReplicatedStorage").Literals.Characters)
local Consts = require(game:GetService("ReplicatedStorage").Literals.Consts)
local Warp = require(game:GetService("ReplicatedStorage").Packages.Warp)

local OnLeftClick = Warp.Client("LeftClick")
local OnActionF = Warp.Client("ActionF")
local OnActionC = Warp.Client("ActionC")
local OnActionE = Warp.Client("ActionE")
local OnActionR = Warp.Client("OnActionR")

local function GetCharacterAtScreenPosition(screenPos: Vector2)
	local ray = camera:ViewportPointToRay(screenPos.X, screenPos.Y)
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
	raycastParams.FilterDescendantsInstances = {player.Character}

	local result = workspace:Raycast(ray.Origin, ray.Direction * 1000, raycastParams)

	if result and result.Instance then
		local model = result.Instance:FindFirstAncestorOfClass("Model")
		if model and model:FindFirstChild("Humanoid") then
			return model
		end
	end
	return nil
end

local function OnCharacter(inputState, inputObj)
	if inputState ~= Enum.UserInputState.Begin then return end

	-- Get screen position of input (mouse or touch or gamepad)
	local screenPos: Vector2

	if inputObj.UserInputType == Enum.UserInputType.Touch then
		screenPos = inputObj.Position
	elseif inputObj.UserInputType == Enum.UserInputType.MouseButton1 then
		screenPos = UserInputService:GetMouseLocation()
	-- elseif inputObj.UserInputType == Enum.UserInputType.Gamepad1 then
	-- 	-- Optional: center of screen for gamepad support
	-- 	screenPos = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
	else
		return
	end

	local character = GetCharacterAtScreenPosition(screenPos)
  if character == nil then return end

  return character
end

local function FindClosestCharacterInRange(maxDist)
    local playerCharacter = player.Character
    if not playerCharacter then return nil end
    local playerRootPart = playerCharacter:FindFirstChild("HumanoidRootPart")
    if not playerRootPart then return nil end

    local bestModel = nil
    local bestDist = math.huge
    for _, model in ipairs(workspace.DamagableHumanoids:GetDescendants()) do
        if model:IsA("Model") and model ~= playerCharacter and model:FindFirstChild("Humanoid") then
            local root = model:FindFirstChild("HumanoidRootPart")
            if root then
                local d = (root.Position - playerRootPart.Position).Magnitude
                if d <= maxDist and d < bestDist then
                    bestModel = model
                    bestDist = d
                end
            end
        end
    end
    return bestModel
end

local holdLeftClick = false
Controls:BindAction("LeftClick", { Enum.UserInputType.MouseButton1 }, false, function(actionName, inputState, inputObj)
    if inputState == Enum.UserInputState.End then 
        holdLeftClick = false	
        return Enum.ContextActionResult.Pass
    end

    -- If on mobile or console, find the closest character in range instead of raycasting
    local isMobile = UserInputService.TouchEnabled
    local isConsole = UserInputService.GamepadEnabled

    if isMobile or isConsole then
        local currentCharacter = player:GetAttribute("CurrentCharacter") -- A character that player choose to play with
				if currentCharacter == nil then return Enum.ContextActionResult.Sink end

        local reachDistance = CharacterLiterals.CharacterStats[currentCharacter].ReachDistance * Consts.MeterToStudsMultiplier
        local enemyCharacter = FindClosestCharacterInRange(reachDistance)

        if not enemyCharacter then
            OnLeftClick:Fire(true)
        else
            OnLeftClick:Fire(true, enemyCharacter)
        end

        return Enum.ContextActionResult.Sink
    end

    -- Desktop / mouse behaviour (hold-to-repeat)
    holdLeftClick = true
    while holdLeftClick do
        task.wait(.2)
        local enemyCharacter = OnCharacter(inputState, inputObj)
        if not enemyCharacter then
            OnLeftClick:Fire(true)
            continue
        end

        local enemyRootPart = enemyCharacter:FindFirstChild("HumanoidRootPart")
        if not enemyRootPart then continue end

        local currentCharacter = player:GetAttribute("CurrentCharacter") -- A character that player choose to play with
        if currentCharacter == nil then continue end

        local playerCharacter = player.Character
        if not playerCharacter then continue end

        local playerRootPart = playerCharacter:FindFirstChild("HumanoidRootPart")
        if not playerRootPart then continue end

        if enemyCharacter == playerCharacter then
            continue-- Ignore clicks on own character
        end

        local reachDistance = CharacterLiterals.CharacterStats[currentCharacter].ReachDistance
        if (enemyRootPart.Position - playerRootPart.Position).Magnitude > reachDistance * Consts.MeterToStudsMultiplier then
            continue
        end

        OnLeftClick:Fire(true, enemyCharacter)
    end

    return Enum.ContextActionResult.Sink
end) 

Controls:BindAction("ActionF", {Enum.KeyCode.F}, false, function(actionName, inputState, inputObj)
	if actionName ~= "ActionF" or inputState ~= Enum.UserInputState.Begin then
		return Enum.ContextActionResult.Pass
	end

	OnActionF:Fire(true)
end)

Controls:BindAction("ActionC", {Enum.KeyCode.C}, false, function(actionName, inputState, inputObj)
	if actionName ~= "ActionC" or inputState ~= Enum.UserInputState.Begin then
		return Enum.ContextActionResult.Pass
	end

	OnActionC:Fire(true)
end)

Controls:BindAction('ActionE', {Enum.KeyCode.E}, false, function(actionName, inputState, inputObj)
	if actionName ~= "ActionE" or inputState ~= Enum.UserInputState.Begin then
		return Enum.ContextActionResult.Pass
	end

	OnActionE:Fire(true)
end)

Controls:BindAction("ActionR", {Enum.KeyCode.R}, false, function(actionName, inputState, inputObj)
	if actionName ~= "ActionR" then
		return Enum.ContextActionResult.Pass
	end

	OnActionR:Fire(true, inputState)
end)