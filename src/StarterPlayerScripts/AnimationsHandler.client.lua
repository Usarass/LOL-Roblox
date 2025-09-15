--//Player
local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

--//Modules
local AnimationsService = require(game:GetService('ReplicatedStorage').Services.Animations)
local Warp = require(game:GetService('ReplicatedStorage').Packages.Warp)
local CharacterLiterals = require(game:GetService('ReplicatedStorage').Literals:WaitForChild('Characters'))

local PlayAnimation = Warp.Client('PlayAnimation')
local StopAllAnimations = Warp.Client('StopAllAnimations')
local PlayAnimationNPC = Warp.Client('PlayAnimationNPC')
local StopAnimationsNPC = Warp.Client('StopAnimationsNPC')

--/Init animations
local animator = character:WaitForChild('Humanoid'):WaitForChild('Animator')

PlayAnimation:Connect(function(animationName : string, animationArgs : { [string]: any })
  if not animationName or typeof(animationName) ~= 'string' then
    warn("No animation name was provided or it is not a string")
    return
  end

  print("Playing animation: " .. animationName)
  local track = AnimationsService:GetTrack(animationName)
  track:Play()
  track:AdjustSpeed(animationArgs.AnimationSpeed or 1)
end)

PlayAnimationNPC:Connect(function(model : Model, animationName : string, animationArgs : { [string]: any })
  if not model or not model:IsA('Model') then
    warn("No valid model provided for PlayAnimationNPC")
    return
  end

  if not animationName or typeof(animationName) ~= 'string' then
    warn("No animation name was provided or it is not a string")
    return
  end

  local modelHumanoid = model:FindFirstChildOfClass('Humanoid')
  if not modelHumanoid then
    warn("No Humanoid found in the provided model for PlayAnimationNPC")
    return
  end

  local animator = modelHumanoid:FindFirstChild('Animator')
  if not animator then
    warn("No Animator found in the Humanoid for PlayAnimationNPC")
    return
  end

  -- print("Playing NPC animation: " .. animationName)
  local animationInstance = AnimationsService.AnimationsInstances[animationName]
  if not animationInstance then
    animationInstance = Instance.new('Animation')
    animationInstance.Name = animationName
    animationInstance.AnimationId = animationArgs.AnimationId or 'rbxassetid://0' -- Default to a dummy animation ID if not provided
    AnimationsService.AnimationsInstances[animationName] = animationInstance
  end

  local animationTrack = animator:LoadAnimation(animationInstance)
  if not animationTrack then
    warn("Failed to load animation track for " .. animationName)
    return
  end
  
  animationTrack:Play()
  animationTrack:AdjustSpeed(animationArgs.AnimationSpeed or 1)
end)

StopAllAnimations:Connect(function()
  for _, track in pairs(animator:GetPlayingAnimationTracks()) do
    track:Stop()
  end
end)

for _, characterLiterals in next, CharacterLiterals.CharacterStats do
  for animationName, animationId in next, characterLiterals.Animation do
    AnimationsService:CreateTrack(animator, animationName, animationId)
  end
end

game:GetService('Players').LocalPlayer.CharacterAdded:Connect(function(newCharacter)  
  AnimationsService:ReloadExisitngTracks(newCharacter:WaitForChild('Humanoid'):WaitForChild('Animator'))
end)