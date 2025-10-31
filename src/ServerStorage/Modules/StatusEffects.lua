local StatusEffects = {}

local registries = {}

export type StatusEffectDescription = {
  User : Player | Model,
  Name: string,
  Percentage: number,
  Duration: number,
  AffectedModule: {}
}

export type changeDescription = {
  ParameterName : string,
  NewValue : number,
  OldValue : number
}

StatusEffects.statusEffectHandlers = {
  WalkspeedMultiplier = function(self, changeDescription : changeDescription)
    local params = self.Parameters
    if not params then warn('No parameters found for character: ' .. tostring(self.CharacterName)) return end

    local baseWalkSpeed = params.BaseWalkSpeed
    if not baseWalkSpeed then warn('No base walkspeed found for character: ' .. tostring(self.CharacterName)) return end

    local character
    if self.Player then 
      character = self.Player.Character
    else
      character = self.Model
    end
    if not character then warn('No character found for player: ' .. self.Player.Name) return end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then warn('No humanoid found in character for player: ' .. self.Player.Name) return end

    humanoid.WalkSpeed = baseWalkSpeed * changeDescription.NewValue
  end
}

function StatusEffects.AddToRegistry(user : Player | Model)
  if not user then warn('No user found') return end
  if registries[user] then return registries[user] end

  registries[user] = {}

  user.AncestryChanged:Connect(function(_, parent)
    if not parent then
      registries[user] = nil
    end
  end)

  return registries[user]
end

function StatusEffects.ApplyEffect(effectDescription : StatusEffectDescription)
  if not effectDescription.User then warn('No user found') return end
  if not effectDescription.Name then warn('No effect name found') return end
  if not effectDescription.Percentage then warn('No effect percentage found') return end
  if not effectDescription.Duration then warn('No effect duration found') return end
  if not effectDescription.AffectedModule then warn('No affected module found') return end

  local user = effectDescription.User

  local normalizedPercentage = effectDescription.Percentage / 100
  local characterModule = effectDescription.AffectedModule

  local userRegistry = StatusEffects.AddToRegistry(user)
  local paramName = effectDescription.Name

  local effectName = effectDescription.EffectName
  if not effectName then
    warn('No effect name provided, using parameter name as effect name')
    effectName = paramName
  end

  local changeSignal = characterModule.StatusEffectChanged
  if not changeSignal then print('No change signal found') end

  if userRegistry[effectName] then
    print('Effect already applied, refreshing duration: ' .. effectDescription.Name .. ' for user: ' .. tostring(user))
    userRegistry[effectName].TimeLeft += effectDescription.Duration
    return
  else
    userRegistry[effectName] = {
      TimeLeft = effectDescription.Duration,
      Percentage = normalizedPercentage,
      AffectedModule = characterModule
    }
  end

  print('currentPercentage:', characterModule.Parameters[paramName] + normalizedPercentage)
  characterModule.Parameters[paramName] += normalizedPercentage
  -- pr
  print('changedPercentage:', characterModule.Parameters[paramName])
  print('Applied effect: ' .. effectDescription.Name .. ' to user: ' .. tostring(user) .. ' with percentage: ' .. tostring(normalizedPercentage) .. ' for duration: ' .. tostring(effectDescription.Duration) .. ' seconds')

  if changeSignal then
    changeSignal:Fire(characterModule,{
      Name = paramName,
      NewValue = characterModule.Parameters[paramName],
      OldValue = characterModule.Parameters[paramName] - normalizedPercentage
    })
  end

  if effectDescription.Duration < 0 then return end --If duration is negative, the effect is permanent until removed manually

  local connection   
  connection = game:GetService('RunService').Heartbeat:Connect(function(deltaTime)
    userRegistry[effectName].TimeLeft -= deltaTime
    if userRegistry[effectName].TimeLeft > 0 then return end

    print('Removing effect: ' .. effectDescription.Name .. ' from user: ' .. tostring(user))
    userRegistry[effectName] = nil
    characterModule.Parameters[paramName] -= normalizedPercentage
    connection:Disconnect() 

    if changeSignal then
      changeSignal:Fire(characterModule,{
        Name = paramName,
        NewValue = characterModule.Parameters[paramName],
        OldValue = characterModule.Parameters[paramName] + normalizedPercentage
      })
    end
  end)
end

function StatusEffects.RemoveEffect(effectName: string, user: Player | Model)
  if not user then warn('No user provided') return end
  if not effectName then warn('No effect provided') return end

  local userRegistry = StatusEffects.AddToRegistry(user)
  if not userRegistry[effectName] then warn('No effect found') return end

  local effectData = userRegistry[effectName]
  local characterModule = effectData.AffectedModule

  characterModule.Parameters[effectName] -= effectData.Percentage
  userRegistry[effectName] = nil
end

return StatusEffects