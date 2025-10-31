local Character = require(script.Parent)
local CharacterLiterals = require(game:GetService("ReplicatedStorage").Literals.Characters)
local Consts = require(game:GetService("ReplicatedStorage").Literals.Consts)
local Warp = require(game:GetService("ReplicatedStorage").Packages.Warp)
local CooldownHandler = require(game:GetService('ServerStorage').Modules.Cooldown)
local StatusEffects = require(game:GetService('ServerStorage').Modules.StatusEffects)

-- local PlayAnimation = Warp.Server('PlayAnimation')
-- local StopAllAnimations = Warp.Server('StopAllAnimations')
local PlaySound = Warp.Server('PlaySound')
local SpecialEvent = Warp.Server('SpecialEvent')
local EmitCirleAoE = Warp.Server('EmitCircleAoE')
local SpecialEventFunc = Warp.Server('SpecialEventFunc')
local EmitRemote = Warp.Server("Emit")

local DamageService = require(game:GetService("ServerStorage").Services.DamageService)
local PlayerStats = require(game:GetService("ServerStorage").Classes.Players)

local arrowModel = game:GetService('ReplicatedStorage').Assets.Arrow

local Default = {}
Default.__index = Default
setmetatable(Default, { __index = Character })

function Default.new(player : Player)
  local self = setmetatable(Character.new(player), Default)
  self.Parameters = {}
  self.CharacterName = 'DefaultRange'
  self.ActionCReady = false

  for _, paramName in pairs(CharacterLiterals.CharacterStats.DefaultRange.ToCharacterParameters) do
    self.Parameters[paramName] = CharacterLiterals.CharacterStats.DefaultRange[paramName]
  end

  return self
end

function Default:DefaultAttack(enemyCharacter : Model)
  if self.InUse then return end

  print("Default range attack called for player: " .. self.Player.Name)
  if not enemyCharacter or not enemyCharacter:IsA("Model") then
    return 
  end

  local enemyHumanoid = enemyCharacter:FindFirstChild("Humanoid")
  if not enemyHumanoid or not enemyHumanoid:IsA("Humanoid") then
    return 
  end

  local enemyRootPart = enemyCharacter:FindFirstChild("HumanoidRootPart")
  if not enemyRootPart then return end

  local currentCharacter = self.Player:GetAttribute("CurrentCharacter") -- A character that player choose to play with
  if currentCharacter == nil then return end

  local playerCharacter = self.Player.Character
  if not playerCharacter then return end

  local playerRootPart = playerCharacter:FindFirstChild("HumanoidRootPart")
  if not playerRootPart then return end

  local currentStats = self.Parameters

  local reachDistance = currentStats.ReachDistance
  if (enemyRootPart.Position - playerRootPart.Position).Magnitude > reachDistance * Consts.MeterToStudsMultiplier then
    return 
  end

  local playerHumanoid = playerCharacter:FindFirstChildOfClass("Humanoid")
  if not playerHumanoid then return Enum.ContextActionResult.Pass end

  local lookAtCFrame = CFrame.new(enemyRootPart.Position, playerRootPart.Position)
  EmitCirleAoE:Fire(true, self.Player, playerCharacter)

  -- playerHumanoid:MoveTo(lookAtCFrame.Position + lookAtCFrame.LookVector * Consts.MeterToStudsMultiplier) -- Move to a position in front of the enemy character

  local alignOrientation = playerRootPart:FindFirstChild("AlignOrientationOnEnemy")
  if alignOrientation == nil then 
    alignOrientation = Instance.new("AlignOrientation")
    alignOrientation.Name = "AlignOrientationOnEnemy"
    alignOrientation.MaxTorque = 1000000
    alignOrientation.Responsiveness = 200
    alignOrientation.Parent = playerRootPart
    alignOrientation.Attachment0 = playerRootPart:FindFirstChildOfClass("Attachment") or Instance.new("Attachment", playerRootPart)
    alignOrientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
  end
  alignOrientation.CFrame = CFrame.new(playerRootPart.Position, enemyRootPart.Position)
  alignOrientation.Enabled = true

  task.delay(.1, function()
    alignOrientation.Enabled = false
  end)

  local attackDistance = currentStats.DefaultAttackDistance

  local canAttack = false
  if (enemyRootPart.Position - playerRootPart.Position).Magnitude < attackDistance * Consts.MeterToStudsMultiplier then
    canAttack = true
  end
  
  if canAttack then
    if not CooldownHandler then
      warn("Cooldown profile not found for player: " .. self.Player.Name)
      return
    end

    if CooldownHandler.Found(self.Player, 'DefaultAttack') then return end

    local animations = {
      `{currentCharacter}AttackDefault1`,
      `{currentCharacter}AttackDefault2`,
      `{currentCharacter}AttackDefault3`
    }

    CooldownHandler.Add(self.Player, 'DefaultAttack', currentStats.DefaultAttackCooldown / currentStats.AttackSpeed)

    -- StopAllAnimations:Fire(true, self.Player)
    -- PlayAnimation:Fire(true, self.Player, animations[math.random(1, #animations)], {
    --   AnimationSpeed = currentStats.AttackSpeed,
    -- })
    task.wait(currentStats.DefaultAttackDelay / currentStats.AttackSpeed)
    task.delay(currentStats.DefaultAttackAfterHitDelay / currentStats.AttackSpeed, function()
      self.InUse = false
    end)
    PlaySound:Fires(true, CharacterLiterals.CharacterStats.DefaultRange.Sounds[`{currentCharacter}Fire`], {
      Parent = playerRootPart,
    })
    -- print("Attack animation played")

    -- local arrow = arrowModel:Clone()
    -- arrow.Anchored = false
    -- arrow.Parent = workspace
    -- arrow.CFrame = CFrame.new(playerRootPart.Position, enemyRootPart.Position) * CFrame.new(0, 0, -2)

    -- local checckPart = Instance.new("Part", workspace)
    -- checckPart.Size = Vector3.new(1, 1, 1)
    -- checckPart.Anchored = true
    -- checckPart.CanCollide = false

    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = { enemyCharacter }
    raycastParams.FilterType = Enum.RaycastFilterType.Include

    -- arrow:SetNetworkOwner(self.Player)
    SpecialEvent:Fires(false, 'Arrow', playerRootPart, enemyRootPart, currentStats)

    local startPosition = (CFrame.new(playerRootPart.Position, enemyRootPart.Position) - playerRootPart.CFrame.LookVector * 1.2).Position
    local distanceTraveled = 0
    local direction = (enemyRootPart.Position - playerRootPart.Position).Unit
    local arrowSpeed = currentStats.DefaultAttackArrowSpeed

    local connection
    connection = game:GetService("RunService").Stepped:Connect(function(_, deltaTime)
      -- simulate movement
      distanceTraveled += arrowSpeed * deltaTime
      -- simulate current position based on time
      local simulatedPosition = startPosition + direction * distanceTraveled

      -- checckPart.CFrame = CFrame.new(simulatedPosition)

      -- check hit
      local raycastResult = workspace:Raycast(simulatedPosition, direction * 3.5, raycastParams)
      if raycastResult and raycastResult.Instance and raycastResult.Instance:IsDescendantOf(enemyRootPart.Parent) then
          -- print("Simulated hit!")
          local enemyHumanoid = enemyRootPart.Parent:FindFirstChildOfClass("Humanoid")

          if enemyHumanoid == nil then return end
          PlaySound:Fires(true, CharacterLiterals.CharacterStats.DefaultRange.Sounds[`{currentCharacter}Hit`], {
            Parent = playerRootPart,
          })
          enemyHumanoid:TakeDamage(DamageService.CalculateAndApplyDamage(self.Player, enemyRootPart.Parent, currentStats.DefaultAttackDamage))
          
          connection:Disconnect()
      end
    end)

    -- local arrowLinearVelocity = arrow:FindFirstChildOfClass("LinearVelocity")
    -- arrowLinearVelocity.VectorVelocity = (enemyRootPart.Position - playerRootPart.Position).Unit * currentStats.DefaultAttackArrowSpeed
    -- arrowLinearVelocity.Enabled true= 

    -- local arrowHitDistance = currentStats.DefaultAttackArrowHitDistance * Consts.MeterToStudsMultiplier

      task.delay(5, function()
        connection:Disconnect() -- Disconnect the connection after 5 seconds to prevent memory leaks
        -- if arrow and arrow:IsDescendantOf(workspace) then
        --   arrow:Destroy() -- Clean up the arrow after 5 seconds
        --   connection:Disconnect() -- Disconnect the connection to prevent memory leaks
        -- end
      end)

    -- if ((enemyRootPart.Position - playerRootPart.Position).Magnitude < attackDistance * Consts.MeterToStudsMultiplier) then
    --   -- Deal damage to the enemy character
    --   enemyHumanoid:TakeDamage(currentStats.DefaultAttackDamage)
    --   PlaySound:Fires(true, currentStats.Sounds[`{currentCharacter}LandedPunch`], {
    --     Parent = playerRootPart,
    --   })
    -- end
	end
end

function Default:ActionF()
  if not CooldownHandler then
    warn("Cooldown profile not found for player: " .. self.Player.Name)
    return
  end

  local parameters = self.Parameters

  if CooldownHandler.Found(self.Player, 'ActionF') then return end
  CooldownHandler.Add(self.Player, 'ActionF', parameters.ActionFCooldown)

  print("Action F used by player: " .. self.Player.Name)

  -- local statusEffectProfile = StatusEffects.get(self.Player)
  -- if not statusEffectProfile then
  --   warn("Status effect profile not found for player: " .. self.Player.Name)
  --   return
  -- end
  
  StatusEffects.ApplyEffect({
    User = self.Player,
    Name = 'AttackSpeed',
    EffectName = 'ActionFAttackSpeedBuff',
    Percentage = parameters.ActionFAttackSpeedBuff,
    Duration = parameters.ActionFAttackSpeedBuffDuration,
    AffectedModule = self,
  })

  StatusEffects.ApplyEffect({
    User = self.Player,
    Name = 'DamageMultiplier',
    EffectName = 'ActionFDamageBuff',
    Percentage = parameters.ActionFDamageBuff,
    Duration = parameters.ActionFDamageBuffDuration,
    AffectedModule = self,
  })

  EmitRemote:Fires(true, 'Star', {
    Duration = parameters.ActionFDamageBuffDuration,
    Model = self.Player.Character,
  })
  -- print("Action F used by player: " .. self.Player.Name)
  -- statusEffectProfile:ApplyEffect('Damage', parameters.ActionFDamageBuff, parameters.ActionFDamageBuffDuration) --parameters.ActionFAttackSpeedBuff
  -- statusEffectProfile:ApplyEffect('AttackSpeed', parameters.ActionFAttackSpeedBuff, parameters.ActionFAttackSpeedBuffDuration)
end

function Default:ActionC()
  if not CooldownHandler then
    warn("Cooldown profile not found for player: " .. self.Player.Name)
    return
  end

  local character = self.Player.Character
  if not character then return end

  if CooldownHandler.Found(self.Player, 'ActionC') then return end
  CooldownHandler.Add(self.Player, 'ActionC', self.Parameters.ActionCCooldown)

  local previousTransparency = {}
  for _, part in next, character:GetDescendants() do
    if part:IsA("Decal") == true then
      previousTransparency[part] = part.Transparency
      part.Transparency = self.Parameters.ActionCTransparency
      
      continue 
    end
    if part:IsA("BasePart") == false or part.Name == 'Hitbox' then continue end

    previousTransparency[part] = part.Transparency
    part.Transparency = self.Parameters.ActionCTransparency
  end

  print("Action C used by player: " .. self.Player.Name)

  local parameters = self.Parameters

  print(parameters.ACtionCWalkSpeedBuffDuration)

  StatusEffects.ApplyEffect({
    User = self.Player,
    Name = 'WalkspeedMultiplier',
    EffectName = 'ActionCWalkSpeedBuff',
    Percentage = parameters.ActionCWalkSpeedBuff,
    Duration = parameters.ACtionCWalkSpeedBuffDuration,
    AffectedModule = self,
  })

  StatusEffects.ApplyEffect({
    User = self.Player,
    Name = 'AttackSpeed',
    EffectName = 'ActionCAttackSpeedBuff',
    Percentage = parameters.ActionCAttackSpeedBuff,
    Duration = parameters.ActionCAttackSpeedBuffDuration,
    AffectedModule = self,
  })

  StatusEffects.ApplyEffect({
    User = self.Player,
    Name = 'DamageMultiplier',
    EffectName = 'ActionCDamageBuff',
    Percentage = parameters.ActionCDamageBuff,
    Duration = parameters.ActionCDamageBuffDuration,
    AffectedModule = self,
  })

  -- statusEffectProfile:ApplyEffect('Damage', self.Parameters.ActionCDamageBuff, self.Parameters.ActionCDamageBuffDuration)
  -- statusEffectProfile:ApplyEffect('AttackSpeed', self.Parameters.ActionCAttackSpeedBuff, self.Parameters.ActionCAttackSpeedBuffDuration)
  -- statusEffectProfile:ApplyWalkSpeedEffect('ActionCWalkSpeedBuff', self.Parameters.ActionCWalkSpeedBuff, self.Parameters.ACtionCWalkSpeedBuffDuration)

  task.wait(self.Parameters.ACtionCWalkSpeedBuffDuration)
  for part, transparency in next, previousTransparency do
    part.Transparency = transparency
  end
end

function Default:ActionE(inputObj : InputObject)
  if not CooldownHandler then
    warn("Cooldown profile not found for player: " .. self.Player.Name)
    return
  end

  if CooldownHandler.Found(self.Player, 'ActionE') or CooldownHandler.Found(self.Player, 'ActionESmall') then return end

  local params = self.Parameters
  if self.ActionCReady == false then 
    print(inputObj)
    SpecialEvent:Fire(true, self.Player, "MarksmenCircle", inputObj)

    self.ActionCReady = true
    -- CooldownHandler.Add('ActionESmall', params.ActionEBetweenCooldown)
    return
  end

  print("Action E used by player: " .. self.Player.Name)

  local unitRay = SpecialEventFunc:Invoke(2, self.Player, "GetCursorRay")
  if not unitRay then return end

  SpecialEvent:Fire(true, self.Player, "MarksmenCircleCancel")  

  local character = self.Player.Character
  if not character then return end

  local rootPart = character:FindFirstChild("HumanoidRootPart")
  if not rootPart then return end

  local raycastParams = RaycastParams.new()
  raycastParams.FilterDescendantsInstances = {workspace.Baseplate}
  raycastParams.FilterType = Enum.RaycastFilterType.Include

  local maxDistance = params.ReachDistance * Consts.MeterToStudsMultiplier

  local result = workspace:Raycast(unitRay.Origin, unitRay.Direction * 500, raycastParams)
  local hitPosition

  if result then
    result = workspace:Raycast(result.Position + Vector3.new(0, 10, 0), Vector3.new(0, -100000, 0), raycastParams)

    if not result then
      print("no result")
      return
    end

    local offset = result.Position - rootPart.Position

    if offset.Magnitude > maxDistance then
      offset = offset.Unit * maxDistance
    end

    local finalPosition = rootPart.Position + Vector3.new(offset.X, 0, offset.Z)
    finalPosition = Vector3.new(finalPosition.X, result.Position.Y, finalPosition.Z)

    hitPosition = finalPosition
  else
    local downResult = workspace:Raycast(rootPart.Position + unitRay.Direction * maxDistance, Vector3.new(0, -100000, 0), raycastParams)

    if not downResult then
      print("no down result")
      return
    end

    hitPosition = downResult.Position
  end

  local hitDistance = params.ActionEReachDistance * Consts.MeterToStudsMultiplier

  SpecialEvent:Fires(true, 'Arrows', self.Player, hitPosition, params.AttackSpeed)
  CooldownHandler.Add(self.Player, 'ActionESmall', params.ActionEBetweenCooldown)
  task.wait(params.ActionEDelay / params.AttackSpeed)

  local isHit = false

  for _, enemyCharacter in next, workspace.DamagableHumanoids:GetDescendants() do
    if enemyCharacter:IsA("Model") == false or enemyCharacter == character then continue end

    local enemyHumanoid = enemyCharacter:FindFirstChildWhichIsA("Humanoid")
    if not enemyHumanoid or enemyHumanoid.Health <= 0 then continue end

    local enemyRootPart = enemyCharacter:FindFirstChild("HumanoidRootPart")
    if not enemyRootPart then continue end

    local distanceBetween = (enemyRootPart.Position - hitPosition).Magnitude

    if distanceBetween < hitDistance then
      enemyHumanoid:TakeDamage(DamageService.CalculateAndApplyDamage(self.Player, enemyRootPart.Parent, params.ActionEDamage))
      isHit = true

      StatusEffects.ApplyEffect({
        User = enemyRootPart.Parent,
        Name = "WalkspeedMultiplier",
        EffectName = "ActionEWalkSpeedDebuff",
        Percentage = params.ActionEWalkSpeedSlowdown,
        Duration = params.ActionEWalkSpeedSlowdownDuration,
        AffectedModule = PlayerStats.getCharacterModule(enemyRootPart.Parent),
      })

      -- local statusEffectProfile = StatusEffects.get(enemyCharacter)
      -- if not statusEffectProfile then continue end

      -- statusEffectProfile:ApplyWalkSpeedEffect('ActionEWalkSpeedDebuff', params.ActionEWalkSpeedSlowdown, params.ActionEWalkSpeedSlowdownDuration)
    end
  end

  if isHit then
    CooldownHandler.Add(self.Player, 'ActionE', params.ActionECooldown)
  end

  self.ActionCReady = false
end

function Default:Destroy()
  
end

return Default