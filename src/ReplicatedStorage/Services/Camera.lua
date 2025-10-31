-- Camera Service
-- Provides a toggleable Top-Down (MOBA / ARPG style) camera.
-- Usage:
--   local CamService = require(ReplicatedStorage.Services.Camera)
--   CamService.setUp(true)  -- enable top-down mode
--   CamService.setUp(false) -- revert to default Roblox camera

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local camera = workspace.CurrentCamera

Players.LocalPlayer.CharacterAdded:Connect(function(character)
    camera = workspace.CurrentCamera
end)

local localPlayer = Players.LocalPlayer

local CameraService = {}
CameraService.__index = CameraService

-- Internal state
CameraService._enabled = false
CameraService._conn = nil
CameraService._charConn = nil
CameraService._zoomConn = nil
CameraService._lastRoot = nil
CameraService._lastCFrame = nil
CameraService._defaultCameraType = nil

-- Configuration (can be adjusted at runtime via CameraService.configure)
local CONFIG = {
	Height = 30,            -- Vertical height above character
	BackDistance = 25,      -- Horizontal distance behind character (along character LookVector)
	FixedWorldYaw = true,   -- If true, camera yaw does not rotate with character
	WorldYawDegrees = 45,   -- Only used when FixedWorldYaw = true (rotates around Y world axis)
	LerpSpeed = 12,          -- Follow smoothing speed
	MinZoom = 30,           -- Minimum height (zoom in)
	MaxZoom = 75,           -- Maximum height (zoom out)
	ZoomStep = 5,           -- Scroll wheel zoom step
	AllowZoom = false,      -- Enable scroll wheel zoom
	MaintainLookAt = true,  -- Always look at character root position
	UseHumanoidRootPart = true, -- Prefer HumanoidRootPart else PrimaryPart
}

-- Public: adjust configuration at runtime
function CameraService.configure(options: { [string]: any })
	for k, v in pairs(options) do
		if CONFIG[k] ~= nil then
			CONFIG[k] = v
		end
	end
end

local function getCharacter()
	if not localPlayer then return nil end
	return localPlayer.Character or localPlayer.CharacterAdded:Wait()
end

local function getRootPart(character: Model)
	if not character then return nil end
	if CONFIG.UseHumanoidRootPart then
		return character:FindFirstChild("HumanoidRootPart")
	end
	return character.PrimaryPart or character:FindFirstChild("HumanoidRootPart")
end

local function computeTargetCFrame(root: BasePart)
	local rootPos = root.Position
	local up = Vector3.yAxis

	local camPos
	if CONFIG.FixedWorldYaw then
		local yaw = math.rad(CONFIG.WorldYawDegrees)
		-- Base offset: we want a vector that has horizontal magnitude BackDistance and vertical Height
		-- We'll point horizontal portion using yaw (world oriented)
		local horizontal = Vector3.new(math.cos(yaw), 0, math.sin(yaw)) * CONFIG.BackDistance
		camPos = rootPos + Vector3.new(0, CONFIG.Height, 0) + horizontal
	else
		-- Follow character facing: place camera behind character along its LookVector
		local look = root.CFrame.LookVector
		camPos = rootPos + Vector3.new(0, CONFIG.Height, 0) - look * CONFIG.BackDistance
	end

	local lookAtPos = CONFIG.MaintainLookAt and rootPos or (rootPos + Vector3.new(0, -5, 0))
	return CFrame.lookAt(camPos, lookAtPos, up)
end

local function update(dt)
	if not CameraService._enabled then return end
	if not camera then
		camera = workspace.CurrentCamera
		if not camera then return end
	end

	local character = getCharacter()
  -- print(character)
	if not character then return end
	local root = getRootPart(character)
	if not root then return end

	local target = computeTargetCFrame(root)
	local current = CameraService._lastCFrame or camera.CFrame
	local alpha = math.clamp(dt * CONFIG.LerpSpeed, 0, 1)
	local blended = current:Lerp(target, alpha)
	camera.CFrame = blended
	CameraService._lastCFrame = blended
end

local function enableZoom()
	if not CONFIG.AllowZoom then return end
	if CameraService._zoomConn then
		CameraService._zoomConn:Disconnect()
		CameraService._zoomConn = nil
	end
	CameraService._zoomConn = UserInputService.InputChanged:Connect(function(input, gpe)
		if gpe then return end
		if input.UserInputType == Enum.UserInputType.MouseWheel then
			local delta = input.Position.Z -- positive / negative scroll
			if delta > 0 then
				CONFIG.Height = math.max(CONFIG.MinZoom, CONFIG.Height - CONFIG.ZoomStep)
				CONFIG.BackDistance = math.max(5, CONFIG.BackDistance - CONFIG.ZoomStep * 0.5)
			elseif delta < 0 then
				CONFIG.Height = math.min(CONFIG.MaxZoom, CONFIG.Height + CONFIG.ZoomStep)
				CONFIG.BackDistance = math.min(CONFIG.MaxZoom * 1.5, CONFIG.BackDistance + CONFIG.ZoomStep * 0.5)
			end
		end
	end)
end

local function disableZoom()
	if CameraService._zoomConn then
		CameraService._zoomConn:Disconnect()
		CameraService._zoomConn = nil
	end
end

local function start()
  print("Starting camera")
	if CameraService._conn then warn("Camera is already running") return end
	CameraService._defaultCameraType = camera and camera.CameraType or Enum.CameraType.Custom
	if camera then
		camera.CameraType = Enum.CameraType.Scriptable
	end
	CameraService._conn = RunService.RenderStepped:Connect(update)
	if CameraService._charConn then CameraService._charConn:Disconnect() end
	if localPlayer then
		CameraService._charConn = localPlayer.CharacterAdded:Connect(function()
			-- Reset last cframe so we snap to character on respawn quickly
			CameraService._lastCFrame = nil
		end)
	end
	enableZoom()
end

local function stop()
	if CameraService._conn then
		CameraService._conn:Disconnect()
		CameraService._conn = nil
	end
	if CameraService._charConn then
		CameraService._charConn:Disconnect()
		CameraService._charConn = nil
	end
	disableZoom()
	if camera then
		camera.CameraType = CameraService._defaultCameraType or Enum.CameraType.Custom
	end
	CameraService._lastCFrame = nil
end

-- Public API: setUp(boolean)
function CameraService.setUp(useTopDown: boolean)
	if useTopDown and not CameraService._enabled then
    print("set up true internal")
		CameraService._enabled = true
		start()
	elseif (not useTopDown) and CameraService._enabled then
    print("set up false internal")
		CameraService._enabled = false
		stop()
	end
end

-- Convenience alias
function CameraService.enable()
  print("set up true")
	CameraService.setUp(true)
end

function CameraService.disable()
	CameraService.setUp(false)
end

-- Optional: quick method to pulse snap (force immediate alignment)
function CameraService.snap()
	if not CameraService._enabled then return end
	local character = getCharacter()
	local root = character and getRootPart(character)
	if root and camera then
		camera.CFrame = computeTargetCFrame(root)
		CameraService._lastCFrame = camera.CFrame
	end
end

return CameraService

