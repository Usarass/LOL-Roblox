local Character = require(script.Parent)
local CharacterLiterals = require(game:GetService("ReplicatedStorage").Literals.Characters)
local Consts = require(game:GetService("ReplicatedStorage").Literals.Consts)
local Warp = require(game:GetService("ReplicatedStorage").Packages.Warp)
local CooldownHanddler = require(game:GetService('ServerStorage').Modules.Cooldown)
local NPCsLiterals = require(game:GetService("ReplicatedStorage").Literals.NPCs)
local StatusEffects = require(game:GetService('ServerStorage').Modules.StatusEffects)

local PlayAnimationNPC = Warp.Server('PlayAnimationNPC')
local StopAnimationsNPC = Warp.Server('StopAnimationsNPC')
local PlaySound = Warp.Server('PlaySound')
local EmitCirleAoE = Warp.Server('EmitCircleAoE')
local SpecialEvent = Warp.Server('SpecialEvent')

local Default = {}
Default.__index = Default
setmetatable(Default, { __index = Character })

function Default.new(spawnCFrame : CFrame?)
  local self = setmetatable(Character.new('Default', spawnCFrame), Default)
  self.CooldownProfile = CooldownHanddler.new(self.Model)
  self.StatusEffectProfile = StatusEffects.new(self.Model)
  self.HuntedCharacter = nil

  local humanoid = self.Model:FindFirstChildOfClass("Humanoid")
  if not humanoid then
    warn("Humanoid not found in NPC model: " .. self.Model.Name)
    return nil
  end 

  local characterStats = NPCsLiterals.CharacterStats.Default
  if not characterStats then
    error("Character stats for NPC '" .. 'Default' .. "' not found.")
  end

  for _, paramName in pairs(characterStats.ToCharacterParameters) do
    self.Parameters[paramName] = characterStats[paramName]
  end

  for _, part in next, self.Model:GetDescendants() do
    if part:IsA("BasePart") == false then continue end

    part:SetNetworkOwner(nil) -- Set network ownership to nil to allow server control
  end

  self:Find()

  return self
end

function Default:Find()
  local currentStats = self.Parameters
  local reachDistanceMeters = currentStats.ReachDistance -- radius in meters
  local reachDistanceStuds = reachDistanceMeters * Consts.MeterToStudsMultiplier
  local diameterStuds = reachDistanceStuds * 2

  local overlapParams = OverlapParams.new()
  overlapParams.FilterType = Enum.RaycastFilterType.Exclude
  overlapParams.FilterDescendantsInstances = { self.Model }

  local triggerPart = Instance.new("Part", self.Model)
  triggerPart.Name = "TriggerPart"
  triggerPart.Size = Vector3.new(diameterStuds * .9, 40, diameterStuds * .9)
  triggerPart.Shape = Enum.PartType.Ball
  triggerPart.Transparency = 1
  triggerPart.CanCollide = false
  triggerPart.CanQuery = false
  triggerPart.CanTouch = true
  triggerPart.Anchored = true
  triggerPart.CFrame = self.SpawnCFrame

  local npcRootPart = self.Model:FindFirstChild("HumanoidRootPart")
  if not npcRootPart then 
    warn("HumanoidRootPart not found in NPC model: " .. self.Model.Name)
    return nil
  end

  local npcHumanoid = self.Model:FindFirstChildOfClass("Humanoid")
  if not npcHumanoid then 
    warn("Humanoid not found in NPC model: " .. self.Model.Name)
    return nil
  end

  local regenAttribute = self.Model:GetAttribute("Regen")
  if regenAttribute == nil then 
    warn("Regen attribute not found in NPC model: " .. self.Model.Name)
    return nil
  end

  triggerPart.Touched:Connect(function(hit : BasePart)
    if hit:IsDescendantOf(self.Model) then return end -- Ignore self collisions

    local enemyCharacter = hit:FindFirstAncestorOfClass("Model")
    if not enemyCharacter then return end

    local enemyHumanoid = enemyCharacter:FindFirstChildOfClass("Humanoid")
    if not enemyHumanoid then return end

    local enemyRootPart = enemyCharacter:FindFirstChild("HumanoidRootPart")
    if not enemyRootPart then return end

    if hit ~= enemyRootPart then return end -- Ensure the hit part is the root part

    if self.HuntedCharacter ~= nil then return end
    self.HuntedCharacter = enemyCharacter

    -- print("Touched by: " .. enemyCharacter.Name)
    EmitCirleAoE:Fires(true, self.Model, {WeldPart0 = triggerPart, Size = (reachDistanceStuds)})
    self.Model:SetAttribute("Regen", false)

    while self.HuntedCharacter do
      task.wait()
      self.HuntedCharacter = self:GetInRangeCharacter(triggerPart, overlapParams)
      if not self.HuntedCharacter then print('Character not found in cirlce') break end

      self:DefaultAttack(self.HuntedCharacter)
    end

    self.Model:SetAttribute("Regen", true)
    npcHumanoid:MoveTo(triggerPart.Position) -- Move back to the original position after attack
  end)

  triggerPart.TouchEnded:Connect(function(hit : BasePart)
    if hit:IsDescendantOf(self.Model) then return end -- Ignore self collisions

    local enemyCharacter = hit:FindFirstAncestorOfClass("Model")
    if not enemyCharacter then return end

    local enemyHumanoid = enemyCharacter:FindFirstChildOfClass("Humanoid")
    if not enemyHumanoid then return end

    local enemyRootPart = enemyCharacter:FindFirstChild("HumanoidRootPart")
    if not enemyRootPart then return end

    if hit ~= enemyRootPart then return end -- Ensure the hit part is the root part

    print("Touch ended by: " .. enemyCharacter.Name)
  end)
end

function Default:GetInRangeCharacter(part : BasePart, overlapParams : OverlapParams?)
  local rootPart = self.Model:FindFirstChild("HumanoidRootPart")
  if not rootPart then
    warn("HumanoidRootPart not found in NPC model: " .. self.Model.Name)
    return nil
  end

  local inRangeParts = workspace:GetPartBoundsInBox(part.CFrame, part.Size, overlapParams)
  -- print("Parts in range: ", inRangeParts)
  -- print(inRangeParts)

  if #inRangeParts == 0 then
    return -- No parts in range
  end

  local charactersInRange = {}

  for _, part in pairs(inRangeParts) do
    local enemyCharacter = part:FindFirstAncestorOfClass("Model")
    if not enemyCharacter then continue end

    local enemyHumanoid = enemyCharacter:FindFirstChildOfClass("Humanoid")
    if not enemyHumanoid then continue end

    if table.find(charactersInRange, enemyCharacter) then
      continue -- Already added this character
    end

    table.insert(charactersInRange, enemyCharacter)
  end

  local targetCharacter = nil
  local minDistance = math.huge

  for _, character in next, charactersInRange do
    local enemyRootPart = character:FindFirstChild("HumanoidRootPart")
    if not enemyRootPart then continue end

    local distance = (rootPart.Position - enemyRootPart.Position).Magnitude
    if distance < minDistance then
      minDistance = distance
      targetCharacter = character
    end
  end

  return targetCharacter
end

function Character:DefaultAttack(enemyCharacter : Model)
  if not enemyCharacter or not enemyCharacter:IsA("Model") then
    return 
  end

  local enemyHumanoid = enemyCharacter:FindFirstChild("Humanoid")
  if not enemyHumanoid or not enemyHumanoid:IsA("Humanoid") then
    return 
  end

  local enemyRootPart = enemyCharacter:FindFirstChild("HumanoidRootPart")
  if not enemyRootPart then return end

  local playerCharacter = self.Model
  if not playerCharacter then return end

  local playerRootPart = playerCharacter:FindFirstChild("HumanoidRootPart")
  if not playerRootPart then return end

  local currentCharacter = self.NPCName
  if not currentCharacter or not CharacterLiterals.CharactersNames[currentCharacter] then
    warn("Current character name is invalid or not found in literals.")
    return
  end

  local currentStats = self.Parameters
  local fullStats = CharacterLiterals.CharacterStats[self.NPCName]
  if not fullStats then
    warn("Full stats for NPC '" .. self.NPCName .. "' not found.")
    return
  end

  local playerHumanoid = playerCharacter:FindFirstChildOfClass("Humanoid")
  if not playerHumanoid then return Enum.ContextActionResult.Pass end

  local lookAtCFrame = CFrame.new(enemyRootPart.Position, playerRootPart.Position)

  local cooldownProfile = self.CooldownProfile

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

  if cooldownProfile:Found('DefaultAttack') then return end
  playerHumanoid:MoveTo(lookAtCFrame.Position + lookAtCFrame.LookVector * Consts.MeterToStudsMultiplier) -- Move to a position in front of the enemy character

  local canAttack = false
  local attackDistance = currentStats.DefaultAttackDistance

  if ((enemyRootPart.Position - playerRootPart.Position).Magnitude < attackDistance * Consts.MeterToStudsMultiplier) then
    canAttack = true
  end

  if canAttack then
    if not cooldownProfile then
      warn("Cooldown profile not found for NPC: " .. self.Model)
      return
    end

    local animations = {
      `{currentCharacter}AttackDefault1`,
      `{currentCharacter}AttackDefault2`,
      `{currentCharacter}AttackDefault3`
    }

    cooldownProfile:Add('DefaultAttack', currentStats.DefaultAttackCooldown / currentStats.DefaultAttackSpeed)

    local choosenAnimation = animations[math.random(1, #animations)]
    StopAnimationsNPC:Fires(true, self.Model)
    PlayAnimationNPC:Fires(true, self.Model, choosenAnimation, {
      AnimationSpeed = currentStats.DefaultAttackSpeed,
      AnimationId = fullStats.Animation[choosenAnimation] or 'rbxassetid://0', -- Default to a dummy animation ID if not provided
    })
    PlaySound:Fires(true, fullStats.Sounds[`{currentCharacter}Whoosh`], {
      Parent = playerRootPart,
    })
    task.wait(currentStats.DefaultAttackDelay / currentStats.DefaultAttackSpeed) -- Wait for certain frame in the aniamtion

    if ((enemyRootPart.Position - playerRootPart.Position).Magnitude < attackDistance * Consts.MeterToStudsMultiplier) then
      -- Deal damage to the enemy character
      enemyHumanoid:TakeDamage(currentStats.DefaultAttackDamage)
      PlaySound:Fires(true, fullStats.Sounds[`{currentCharacter}LandedPunch`], {
        Parent = playerRootPart,
      })
    end
	end
end

return Default