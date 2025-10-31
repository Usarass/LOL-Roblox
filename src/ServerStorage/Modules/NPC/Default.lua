local Character = require(script.Parent)
local Consts = require(game:GetService("ReplicatedStorage").Literals.Consts)
local Warp = require(game:GetService("ReplicatedStorage").Packages.Warp)
local RunService = game:GetService("RunService")
local CooldownHandler = require(game:GetService('ServerStorage').Modules.Cooldown)
local NPCsLiterals = require(game:GetService("ReplicatedStorage").Literals.Characters)
local StatusEffects = require(game:GetService('ServerStorage').Modules.StatusEffects)

local PlayAnimationNPC = Warp.Server('PlayAnimationNPC')
local StopAnimationsNPC = Warp.Server('StopAnimationsNPC')
local PlaySound = Warp.Server('PlaySound')
local EmitCirleAoE = Warp.Server('EmitCircleAoE')
local SpecialEvent = Warp.Server('SpecialEvent')
local DamageService = require(game:GetService("ServerStorage").Services.DamageService)

local Default = {}
Default.__index = Default
setmetatable(Default, { __index = Character })

function Default.new(spawnCFrame : CFrame?)
  local self = setmetatable(Character.new('NPCDefault', spawnCFrame), Default)
  self.CharacterName = 'NPCDefault'
  self.HuntedCharacter = nil
  self.CharacterModule = self

  local humanoid  = self.Model:FindFirstChildOfClass("Humanoid")
  if not humanoid then
    warn("Humanoid not found in NPC model: " .. self.Model.Name)
    return nil
  end 

  local characterStats = NPCsLiterals.CharacterStats.NPCDefault
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

  humanoid.Died:Connect(function()
    if type(self.Destroy) == "function" then
      self:Destroy()
    end
  end)

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
  -- triggerPart.Size = triggerPart.Size * .8
  triggerPart.Shape = Enum.PartType.Ball
  triggerPart.Transparency = 1
  triggerPart.CanCollide = false
  triggerPart.CanQuery = false
  triggerPart.CanTouch = true
  triggerPart.Anchored = true
  triggerPart.CFrame = self.SpawnCFrame
  -- keep reference for cleanup
  self._triggerPart = triggerPart

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

  -- Distance-based monitor: use RunService.Heartbeat to poll every 0.25s
  local pollInterval = 0.25
  local accumulator = 0

  local hbConn
  hbConn = RunService.Heartbeat:Connect(function(deltaTime)
    if not (self.Model and self.Model.Parent) then
      if hbConn then hbConn:Disconnect() end
      return
    end

    accumulator = accumulator + deltaTime
    if accumulator < pollInterval then
      return
    end
    accumulator = 0

    -- If currently hunting, refresh the hunted character; otherwise try to acquire one
    if not self.HuntedCharacter then
      local found = self:GetInRangeCharacter(triggerPart, overlapParams)
      if found then
        self.HuntedCharacter = found
        EmitCirleAoE:Fires(true, self.Model, {WeldPart0 = triggerPart, Size = (reachDistanceStuds)})
        self.Model:SetAttribute("Regen", false)

        -- Spawn attack loop in its own task to avoid yielding inside Heartbeat
        task.spawn(function()
          while self.HuntedCharacter do
            task.wait()
            self.HuntedCharacter = self:GetInRangeCharacter(triggerPart, overlapParams)
            if not self.HuntedCharacter then break end
            self:DefaultAttack(self.HuntedCharacter)
          end

          -- Target lost; restore regen and return to trigger position
          if self.Model then
            self.Model:SetAttribute("Regen", true)
          end
          if npcHumanoid and npcHumanoid.MoveTo then
            npcHumanoid:MoveTo(triggerPart.Position)
          end
          self.HuntedCharacter = nil
        end)
      end
    else
      -- If we already have a hunted character, ensure they are still valid
      local still = self:GetInRangeCharacter(triggerPart, overlapParams)
      if not still then
        self.HuntedCharacter = nil
      end
    end
  end)

  -- store connection for cleanup
  self._hbConn = hbConn

  -- auto-destroy when model removed
  if self.Model and self.Model.AncestryChanged then
    self._ancestryConn = self.Model.AncestryChanged:Connect(function(_, parent)
      if not parent then
        if type(self.Destroy) == "function" then
          self:Destroy()
        end
      end
    end)
  end
end

function Default:Destroy()
  -- Disconnect heartbeat
  if self._hbConn then
    self._hbConn:Disconnect()
    self._hbConn = nil
  end

  -- Disconnect ancestry listener
  if self._ancestryConn then
    self._ancestryConn:Disconnect()
    self._ancestryConn = nil
  end

  -- Destroy trigger part
  if self._triggerPart then
    if self._triggerPart.Parent then
      self._triggerPart:Destroy()
    end
    self._triggerPart = nil
  end

  -- Clear hunted target and other references
  self.HuntedCharacter = nil
  -- Note: do not destroy model here; caller may handle that
  self.Model = nil
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

    if enemyHumanoid.Health <= 0 then
      continue -- Ignore dead characters
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
  if not currentCharacter or not NPCsLiterals.CharactersNames[currentCharacter] then
    warn("Current character name is invalid or not found in literals.")
    return
  end

  local currentStats = self.Parameters
  local fullStats = NPCsLiterals.CharacterStats[self.NPCName]
  if not fullStats then
    warn("Full stats for NPC '" .. self.NPCName .. "' not found.")
    return
  end

  local playerHumanoid = playerCharacter:FindFirstChildOfClass("Humanoid")
  if not playerHumanoid then return Enum.ContextActionResult.Pass end

  local lookAtCFrame = CFrame.new(enemyRootPart.Position, playerRootPart.Position)

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

  if CooldownHandler.Found(self.Model, 'DefaultAttack') then return end
  playerHumanoid:MoveTo(lookAtCFrame.Position + lookAtCFrame.LookVector * Consts.MeterToStudsMultiplier) -- Move to a position in front of the enemy character

  local canAttack = false
  local attackDistance = currentStats.DefaultAttackDistance

  if ((enemyRootPart.Position - playerRootPart.Position).Magnitude < attackDistance * Consts.MeterToStudsMultiplier) then
    canAttack = true
  end

  if canAttack then
    CooldownHandler.Add(self.Model, 'DefaultAttack', currentStats.DefaultAttackCooldown / currentStats.AttackSpeed)

    local choosenAnimation = math.random(1, 3)
    choosenAnimation = `AttackDefault{choosenAnimation}`

    StopAnimationsNPC:Fires(true, self.Model)
    PlayAnimationNPC:Fires(true, self.Model, choosenAnimation, {
      AnimationSpeed = currentStats.AttackSpeed,
      AnimationId = fullStats.Animation[choosenAnimation] or 'rbxassetid://0', -- Default to a dummy animation ID if not provided
    })
    PlaySound:Fires(true, fullStats.Sounds['Whoosh'], {
      Parent = playerRootPart,
    })
    task.wait(currentStats.DefaultAttackDelay / currentStats.AttackSpeed) -- Wait for certain frame in the aniamtion

    if ((enemyRootPart.Position - playerRootPart.Position).Magnitude < attackDistance * Consts.MeterToStudsMultiplier) then
      -- Deal damage to the enemy character
      -- enemyHumanoid:TakeDamage(currentStats.DefaultAttackDamage)
      enemyHumanoid:TakeDamage(DamageService.CalculateAndApplyDamage(self.Model, game:GetService('Players'):GetPlayerFromCharacter(enemyCharacter), currentStats.DefaultAttackDamage))
      PlaySound:Fires(true, fullStats.Sounds['LandedPunch'], {
        Parent = playerRootPart,
      })
    end
	end
end

return Default