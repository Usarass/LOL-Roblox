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

local damagableHumanoids = workspace.DamagableHumanoids

local Default = {}
Default.__index = Default
setmetatable(Default, { __index = Character })

function Default.new(player : Player)
  print("Creating Default character for player: " .. player.Name)
  local self = setmetatable(Character.new(player), Default)
  self.Parameters = {}
  self.DashCharged = false

  for _, paramName in pairs(CharacterLiterals.CharacterStats.Default.ToCharacterParameters) do
    self.Parameters[paramName] = CharacterLiterals.CharacterStats.Default[paramName]
  end

  return self
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

  for _, enemyCharacter in pairs(damagableHumanoids:GetDescendants()) do
    if enemyCharacter:IsA("Model") == false then continue end

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
    local cooldownProfile = CooldownHandler.GetProfile(self.Player)
    if not cooldownProfile then
      warn("Cooldown profile not found for player: " .. self.Player.Name)
      return
    end
    
    if cooldownProfile:Found('DefaultAttack') then return end

    local animations = {
      `{currentCharacter}AttackDefault1`,
      `{currentCharacter}AttackDefault2`,
      `{currentCharacter}AttackDefault3`
    }

    self.InUse = true
    cooldownProfile:Add('DefaultAttack', currentStats.DefaultAttackCooldown / currentStats.DefaultAttackSpeed)

    StopAllAnimations:Fire(true, self.Player)
    PlayAnimation:Fire(true, self.Player, animations[math.random(1, #animations)], {
      AnimationSpeed = currentStats.DefaultAttackSpeed,
    })
    PlaySound:Fires(true, fullStats.Sounds[`{currentCharacter}Whoosh`], {
      Parent = playerRootPart,
    })
    task.wait(currentStats.DefaultAttackDelay / currentStats.DefaultAttackSpeed) -- Wait for certain frame in the aniamtion
    task.delay(currentStats.DefaultAttackAfterHitDelay / currentStats.DefaultAttackSpeed, function()
      self.InUse = false
    end)

    if ((enemyRootPart.Position - playerRootPart.Position).Magnitude < attackDistance * Consts.MeterToStudsMultiplier) then
      -- Deal damage to the enemy character
      enemyHumanoid:TakeDamage(currentStats.DefaultAttackDamage * currentStats.DefaultAttackDamageMultiplier)
      PlaySound:Fires(true, fullStats.Sounds[`{currentCharacter}LandedPunch`], {
        Parent = playerRootPart,
      })
    end
	end
end

function Default:ActionR(inputState)
  local character = self.Player.Character
  if not character then return end

  local humanoid = character:FindFirstChildOfClass("Humanoid")
  if not humanoid or humanoid.Health <= 0 then return end

  local rootPart = character:FindFirstChild("HumanoidRootPart")
  if not rootPart then return end

  local cooldownProfile = CooldownHandler.GetProfile(self.Player)
  if not cooldownProfile then
    warn("Cooldown profile not found for player: " .. self.Player.Name)
    return
  end

  print("Dash input state for player: " .. self.Player.Name .. " is " .. tostring(inputState))
  if self.DashCharged and inputState == Enum.UserInputState.End then 
    cooldownProfile:Add('Dash', self.Parameters.DashCooldown)
    self.DashCharged = false
    print("Dashing for player: " .. self.Player.Name)
    SpecialEvent:Fire(true, self.Player, "Dash")

    return
  end

  if cooldownProfile:Found('Dash') or inputState ~= Enum.UserInputState.Begin then return end

  SpecialEvent:Fire(true, self.Player, "DashVisual")
  self.DashCharged = true
end

return Default