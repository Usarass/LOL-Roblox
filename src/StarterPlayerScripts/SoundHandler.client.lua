local player = game.Players.LocalPlayer

local Warp = require(game:GetService('ReplicatedStorage').Packages.Warp)
local CharacterLiterals = require(game:GetService('ReplicatedStorage').Literals:WaitForChild('Characters'))

local PlaySound = Warp.Client('PlaySound')

PlaySound:Connect(function(soundInstance : Sound, soundArgs : { [string]: any })
  if not soundInstance or not soundInstance:IsA('Sound') then
    warn("No sound instance provided or it is not a Sound")
    return
  end

  if not soundArgs or type(soundArgs) ~= 'table' then
    warn("No sound arguments provided or it is not a table")
    return
  end

  local character = player.Character or player.CharacterAdded:Wait()
  if not character then
    warn("No character found for the player")
    return
  end

  local rootPart = character:FindFirstChild('HumanoidRootPart')
  if not rootPart then
    warn("No HumanoidRootPart found in the character")
    return
  end

  soundInstance = soundInstance:Clone()
  soundInstance.Parent = soundArgs.Parent or rootPart
  soundInstance.Volume = soundArgs.Volume or 1
  soundInstance.PlaybackSpeed = soundArgs.PlaybackSpeed or 1
  soundInstance:Play()
end)