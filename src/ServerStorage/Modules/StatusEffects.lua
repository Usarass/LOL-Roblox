local PlayerStats = require(game:GetService("ServerStorage").Classes.Players)
local CharactersLiterals = require(game:GetService("ReplicatedStorage").Literals.Characters)

local ToParametersName = {
  AttackSpeed = "DefaultAttackSpeed",
  Damage = "DefaultAttackDamageMultiplier",
}

local StatusEffects = {
  Profiles = {},
}
StatusEffects.__index = StatusEffects

function StatusEffects.new(player : Player)
  local self = setmetatable({
    Owner = player,
    WalkspeedStatusEffects = {},
    WalkspeedMultiplier = 1,
  }, StatusEffects)

  StatusEffects.Profiles[player] = self
  return self
end

function StatusEffects:ApplyEffect(effectName : string, effectPercentage : number, duration : number)
  local parameterName = ToParametersName[effectName]
  if not parameterName then warn('No parameter name found') return end

  local normalizedPercentage = effectPercentage / 100
  local characterModule = PlayerStats.getCharacterModule(self.Owner)
  if not characterModule then warn('No character module found') return end

  print("Applying effect:", effectName, "to player:", self.Owner.Name, "with percentage:", effectPercentage, "for duration:", duration)
  characterModule.Parameters[parameterName] += normalizedPercentage
  task.delay(duration, function()
    characterModule.Parameters[parameterName] -= normalizedPercentage
    print("Effect expired:", effectName, "for player:", self.Owner.Name)
  end)
end

function StatusEffects:ApplyWalkSpeedEffect(effectName : string, effectPercentage : number, effectDuration : number)
  if self.WalkspeedStatusEffects[effectName] then self.WalkspeedStatusEffects[effectName] = effectDuration  return end

  local isPlayer = self.Owner:IsA("Player")

  local character
  if isPlayer == false then
    character = self.Owner
  else 
    character = self.Owner.Character  
  end
  if not character then warn('No character found') return end

  local humanoid = character:FindFirstChildOfClass("Humanoid")
  if not humanoid then warn('No humanoid found') return end

  
  local selectedCharacter = self.Owner:GetAttribute("CurrentCharacter")
  if not selectedCharacter then warn('No selected character found') return end

  local normalizedPercentage = effectPercentage / 100
  self.WalkspeedStatusEffects[effectName] = effectDuration
  self.WalkspeedMultiplier += normalizedPercentage

  local baseWalkSpeed = CharactersLiterals.CharacterStats[selectedCharacter].BaseWalkSpeed
  humanoid.WalkSpeed = baseWalkSpeed * self.WalkspeedMultiplier

  local connection
  connection = game:GetService('RunService').Heartbeat:Connect(function(deltaTime)
    self.WalkspeedStatusEffects[effectName] -= deltaTime
    if self.WalkspeedStatusEffects[effectName] <= 0 then
      self.WalkspeedStatusEffects[effectName] = nil
      self.WalkspeedMultiplier -= normalizedPercentage
      humanoid.WalkSpeed = baseWalkSpeed * self.WalkspeedMultiplier
      connection:Disconnect()
    end
  end)
end

function StatusEffects.get(player : Player)
  local profile = StatusEffects.Profiles[player]
  if not profile then
    player = game:GetService("Players"):GetPlayerFromCharacter(player)
    profile = StatusEffects.Profiles[player]
    if not profile then return end
  end

  return profile
end

function StatusEffects.destruct(player : Player)
  StatusEffects.Profiles[player] = nil
end

return StatusEffects