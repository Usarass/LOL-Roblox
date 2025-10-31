local Character = require(script.Parent)
local CharacterLiterals = require(game:GetService("ReplicatedStorage").Literals.Characters)
local Consts = require(game:GetService("ReplicatedStorage").Literals.Consts)
local Warp = require(game:GetService("ReplicatedStorage").Packages.Warp)
local CooldownHandler = require(game:GetService('ServerStorage').Modules.Cooldown)

local PlayAnimation = Warp.Server('PlayAnimation')
local StopAllAnimations = Warp.Server('StopAllAnimations')
local PlaySound = Warp.Server('PlaySound')
local EmitCirleAoE = Warp.Server('EmitCircleAoE')
local SpecialEvent = Warp.Server('SpecialEvent')
local SpecialEventFunc = Warp.Server('SpecialEventFunc')
local EmitRemote = Warp.Server("Emit")

local DamageService = require(game:GetService("ServerStorage").Services.DamageService)
local StatusEffects = require(game:GetService("ServerStorage").Modules.StatusEffects)
local PlayerStats = require(game:GetService("ServerStorage").Classes.Players)

local damagableHumanoids = workspace.DamagableHumanoids

local Default = {}
Default.__index = Default
setmetatable(Default, { __index = Character })

function Default.new(player : Player)
  print("Creating Default character for player: " .. player.Name)
  local self = setmetatable(Character.new(player), Default)
  self.Parameters = {}
  self.CharacterName = 'Default'
  self.DashCharged = false
  self.ActionCHealBuff = false
  self.ActionFReady = false
  self.Connections = {}

  for _, paramName in pairs(CharacterLiterals.CharacterStats.Default.ToCharacterParameters) do
    self.Parameters[paramName] = CharacterLiterals.CharacterStats.Default[paramName]
  end

  local connection 
  connection = DamageService.DamageAccepted:Connect(function(attacker, target, damage)
    print("DamageService: Damage accepted from " .. tostring(attacker) .. " to " .. tostring(target) .. " for " .. tostring(damage))
    if attacker ~= player or self.ActionCHealBuff == false then return end

    local character = attacker.Character or typeof(attacker) == "Instance" and attacker:Is("Model") and attacker or nil
    if not character then return end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return end

    local newHealth = math.clamp(humanoid.Health + self.Parameters.ActionCHeal, 0, humanoid.MaxHealth)
    humanoid.Health = newHealth
  end)
  table.insert(self.Connections, connection)

  player.AncestryChanged:Connect(function(_, parent)
    if parent == nil then
      self:Destroy()
    end
  end)

  return self
end

function Default:Destroy()
  for _, conn in pairs(self.Connections) do
    conn:Disconnect()
  end

  self = nil
end

function Default:OnLeftClick()
  local playerCharacter = self.Player.Character
  if not playerCharacter then return end

  local playerRootPart = playerCharacter:FindFirstChild("HumanoidRootPart")
  if not playerRootPart then return end

  local currentStats = self.Parameters
  local attackDistance = currentStats.DefaultAttackDistance

  local closestCharacter = nil
  local closestDistance = math.huge

  -- for _, player in next, game:GetService("Players"):GetPlayers() do
  --   if player == self.Player then continue end

  --   local enemyCharacter = player.Character
  --   if not enemyCharacter then continue end

  --   local enemyHumanoid = enemyCharacter:FindFirstChildOfClass("Humanoid")
  --   if not enemyHumanoid or enemyHumanoid.Health <= 0 then continue end

  --   local enemyRootPart = enemyCharacter:FindFirstChild("HumanoidRootPart")
  --   if not enemyRootPart then continue end

  --   local distanceBetween = (enemyRootPart.Position - playerRootPart.Position).Magnitude

  --   if distanceBetween > attackDistance * Consts.MeterToStudsMultiplier then
  --     continue
  --   end

  --   if distanceBetween < closestDistance then
  --     closestDistance = distanceBetween
  --     closestCharacter = enemyCharacter
  --   end
  -- end

  local character = self.Player.Character
  if not character then print("Player character not found") return end

  for _, enemyCharacter in pairs(damagableHumanoids:GetDescendants()) do
    if enemyCharacter:IsA("Model") == false or enemyCharacter == character then continue end

    local enemyHumanoid = enemyCharacter:FindFirstChildOfClass("Humanoid")
    if not enemyHumanoid or enemyHumanoid.Health <= 0 then continue end

    local enemyRootPart = enemyCharacter:FindFirstChild("HumanoidRootPart")
    if not enemyRootPart then continue end

    local distanceBetween = (enemyRootPart.Position - playerRootPart.Position).Magnitude

    if distanceBetween > attackDistance * Consts.MeterToStudsMultiplier then
      continue
    end

    if distanceBetween < closestDistance then
      closestDistance = distanceBetween
      closestCharacter = enemyCharacter
    end
  end

  if closestCharacter then
    self:DefaultAttack(closestCharacter)
  end
end

function Default:DefaultAttack(enemyCharacter : Model)
  if self.InUse then return end
  print("Default attack called for player: " .. self.Player.Name)

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
  local fullStats = CharacterLiterals.CharacterStats[currentCharacter]

  local reachDistance = currentStats.ReachDistance
  if (enemyRootPart.Position - playerRootPart.Position).Magnitude > reachDistance * Consts.MeterToStudsMultiplier then
    return 
  end

  local playerHumanoid = playerCharacter:FindFirstChildOfClass("Humanoid")
  if not playerHumanoid then return Enum.ContextActionResult.Pass end

  local lookAtCFrame = CFrame.new(enemyRootPart.Position, playerRootPart.Position)

  playerHumanoid:MoveTo(lookAtCFrame.Position + lookAtCFrame.LookVector * Consts.MeterToStudsMultiplier) -- Move to a position in front of the enemy 
  EmitCirleAoE:Fire(true, self.Player, playerCharacter)

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
    print("Performing default attack for player: " .. self.Player.Name)
    if not CooldownHandler then
      warn("Cooldown profile not found for player: " .. self.Player.Name)
      return
    end

    if CooldownHandler.Found(self.Player, 'DefaultAttack') then print('Found DefaultAttack cooldown') return end

    self.InUse = true
    CooldownHandler.Add(self.Player, 'DefaultAttack', currentStats.DefaultAttackCooldown / currentStats.AttackSpeed)

    local randomAnimation = math.random(1, 3)
    randomAnimation = `DefaultAttackP{randomAnimation}`

    StopAllAnimations:Fire(true, self.Player)
    PlayAnimation:Fire(true, self.Player, randomAnimation, {
      AnimationSpeed = currentStats.AttackSpeed,
    })
    PlaySound:Fires(true, fullStats.Sounds["Whoosh"], {
      Parent = playerRootPart,
    })
    task.wait(currentStats.DefaultAttackDelay / currentStats.AttackSpeed) -- Wait for certain frame in the aniamtion
    task.delay(currentStats.DefaultAttackAfterHitDelay / currentStats.AttackSpeed, function()
      self.InUse = false
    end)

    if ((enemyRootPart.Position - playerRootPart.Position).Magnitude < attackDistance * Consts.MeterToStudsMultiplier) then
      -- Deal damage to the enemy character
      -- enemyHumanoid:TakeDamage(currentStats.DefaultAttackDamage * currentStats.DamageMultiplier)
      enemyHumanoid:TakeDamage(DamageService.CalculateAndApplyDamage(self.Player, enemyCharacter, currentStats.DefaultAttackDamage))
      PlaySound:Fires(true, fullStats.Sounds["LandedPunch"], {
        Parent = playerRootPart,
      })
    end
	end
end

function Default:ActionR(inputState)
  if inputState ~= Enum.UserInputState.End and inputState ~= Enum.UserInputState.Begin then return end

  local character = self.Player.Character
  if not character then return end

  local humanoid = character:FindFirstChildOfClass("Humanoid")
  if not humanoid or humanoid.Health <= 0 then return end

  local rootPart = character:FindFirstChild("HumanoidRootPart")
  if not rootPart then return end

  print("Dash input state for player: " .. self.Player.Name .. " is " .. tostring(inputState))
  if self.DashCharged then 
    CooldownHandler.Add(self.Player, 'ActionF', self.Parameters.DashCooldown)
    self.DashCharged = false
    print("Dashing for player: " .. self.Player.Name)
    SpecialEvent:Fire(true, self.Player, "Dash")
    
    return
  end

  if CooldownHandler.Found(self.Player, 'ActionF') then return end

  if inputState == Enum.UserInputState.End then return end
  SpecialEvent:Fire(true, self.Player, "DashVisual")
  self.DashCharged = true
end

function Default:ActionC()
  if CooldownHandler.Found(self.Player, 'ActionC') then return end
  CooldownHandler.Add(self.Player, 'ActionC', self.Parameters.ActionCCooldown)

  local character = self.Player.Character
  if not character then return end

  local currentParams = self.Parameters

  self.ActionCHealBuff = true
  task.delay(currentParams.ActionCHealDuration, function()
    self.ActionCHealBuff = false
  end)

  local previousTransparency = {}
  for _, part in next, character:GetDescendants() do
    if part:IsA("Decal") == true then
      previousTransparency[part] = part.Transparency
      part.Transparency = currentParams.ActionCTransparency
      
      continue 
    end
    if part:IsA("BasePart") == false or part.Name == 'Hitbox' then continue end

    previousTransparency[part] = part.Transparency
    part.Transparency = currentParams.ActionCTransparency
  end

  task.delay(currentParams.ActionCInvisibilityDuration, function()
    for part, transparency in pairs(previousTransparency) do
      if part and part.Parent then
        part.Transparency = transparency
      end
    end
  end)

  StatusEffects.ApplyEffect({
    User = self.Player,
    Name = "WalkspeedMultiplier",
    EffectName = "ActionCWalkSpeedBuff",
    Percentage = currentParams.ActionCWalkSpeedBuff,
    Duration = currentParams.ActionCWalkSpeedBuffDuration,
    AffectedModule = self
  })

  StatusEffects.ApplyEffect({
    User = self.Player,
    Name = "Resistance",
    EffectName = "ActionCDamageResistanceBuff",
    Percentage = currentParams.ActionCDamageResistanceBuff,
    Duration = currentParams.ActionCDamageResistanceBuffDuration,
    AffectedModule = self
  })

  EmitRemote:Fires(true, 'Shield', {
    Duration = currentParams.ActionCDamageResistanceBuffDuration,
    Model = character,
  })
end

function Default:ActionF(inputState)
  if CooldownHandler.Found(self.Player, 'ActionE') then return end
  print("ActionF called for player: " .. self.Player.Name)

  if self.ActionFReady then 
    CooldownHandler.Add(self.Player, 'ActionE', self.Parameters.ActionFCooldown)
    self.ActionFReady = false

    local character = self.Player.Character
    if not character then return end

    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end

    local currentStats = self.Parameters

    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {character}

    local previousCollisions = {}

    for _, part in pairs(character:GetDescendants()) do
      if part:IsA("BasePart") == false then
        continue
      end

      previousCollisions[part] = part.CollisionGroup
      part.CollisionGroup = "NoCharacterCollisions"
    end

    task.delay(currentStats.ActionFNoCollisionDuration, function()
      for part, collisionGroup in pairs(previousCollisions) do
        if part and part.Parent then
          part.CollisionGroup = collisionGroup
        end
      end
    end)

    local connection 
    connection = game:GetService('RunService').Stepped:Connect(function(deltaTime)
      local result = workspace:Raycast(rootPart.Position, rootPart.CFrame.LookVector * currentStats.ActionFRaycastMultiplier, raycastParams)
      if not result or not result.Instance then return end

      local hitPart = result.Instance
      local hitCharacter = hitPart:FindFirstAncestorOfClass("Model")
      if not hitCharacter then return end

      local hitHumanoid = hitCharacter:FindFirstChildOfClass("Humanoid")
      if not hitHumanoid or hitHumanoid.Health <= 0 then return end

      connection:Disconnect()
      hitHumanoid:TakeDamage( DamageService.CalculateAndApplyDamage(self.Player, hitCharacter, currentStats.ActionFDamage) )

      local characterModule = PlayerStats.getCharacterModule(hitCharacter)

      StatusEffects.ApplyEffect({
        User = hitCharacter,
        Name = "WalkspeedMultiplier",
        EffectName = "ActionFTargetWalkSpeedDebuff",
        Percentage = currentStats.ActionFTargetWalkSpeedSlowdown,
        Duration = currentStats.ActionFTargetWalkSpeedDuration,
        AffectedModule = characterModule,
      })

      StatusEffects.ApplyEffect({
        User = hitCharacter,
        Name = "AttackSpeed",
        EffectName = "ActionFTargetAttackSpeedDebuff",
        Percentage = currentStats.ActionFTargetAttackSpeedSlowdown,
        Duration = currentStats.ActionFTargetAttackSpeedDuration,
        AffectedModule = characterModule,
      })

      StatusEffects.ApplyEffect({
        User = self.Player,
        Name = "AttackSpeed",
        EffectName = "ActionFAttackSpeedBuff",
        Percentage = currentStats.ActionFAttackSpeedBuff,
        Duration = currentStats.ActionFAttackSpeedBuffDuration,
        AffectedModule = self
      })
    end)

    task.delay(currentStats.ActionFRaycastDuration, function()
      if not connection then return end

      connection:Disconnect()
    end)

    SpecialEvent:Fire(true, self.Player, "SlashUsed")

    return
  end

  if inputState == Enum.UserInputState.End then return end
  self.ActionFReady = true
  SpecialEvent:Fire(true, self.Player, "SlashReady")
end

return Default