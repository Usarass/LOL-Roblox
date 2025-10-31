--//WARNING: While naming scripts inside this, please notice that it MUST be the same as the character name in the Characters.lua file

local CharacterLiterals = require(game:GetService("ReplicatedStorage").Literals.Characters)
local Consts = require(game:GetService("ReplicatedStorage").Literals.Consts)
local Warp = require(game:GetService("ReplicatedStorage").Packages.Warp)
local CooldownHandler = require(game:GetService('ServerStorage').Modules.Cooldown)
local GoodSignal = require(game:GetService("ReplicatedStorage").Packages.GoodSignal)
local StatusEffects = require(game:GetService("ServerStorage").Modules.StatusEffects)
local DamageService = require(game:GetService("ServerStorage").Services.DamageService)

local PlayAnimation = Warp.Server('PlayAnimation')
local StopAllAnimations = Warp.Server('StopAllAnimations')
local PlaySound = Warp.Server('PlaySound')

local Character = {}
Character.__index = Character

function Character.new(player : Player)
  local self = setmetatable({
    Player = player,
    InUse = false,

    StatusEffectChanged = GoodSignal.new(),
  }, Character)

  self.StatusEffectChanged:Connect(function(self, changeDescription : StatusEffects.changeDescription)
    local handler = StatusEffects.statusEffectHandlers[changeDescription.Name]
    if not handler then return end

    handler(self, changeDescription)
  end)

  local character = player.Character or player.CharacterAdded:Wait()
  local humanoid = character:FindFirstChildOfClass("Humanoid")

  if not humanoid then
    error("Humanoid not found in player's character")
  end

  return self
end

function Character:DefaultAttack(enemyCharacter : Model) --//Logic written in childs classes
end

function Character:OnLeftClick()
end

function Character:ActionR()
end

function Character:ActionF()
end

function Character:ActionC()
end

function Character:ActionE()
end

function Character:Regen()  
  local RunService = game:GetService("RunService")
  local Players = game:GetService("Players")

  local player = self.Player
  if not player then return end

  -- Prevent activation while on cooldown
  if CooldownHandler.Found(player, "Regen") then
    return
  end

  -- Start cooldown
  local params = self.Parameters
  CooldownHandler.Add(player, "Regen", params.RegenCooldown)

  local character = player.Character
  local humanoid = character:FindFirstChildOfClass("Humanoid")

  local totalHeal = params.RegenTotalHealth or 50
  local duration = params.RegenDuration or 1
  local reducePercentage = params.ReducePercentageWhenDamaged or 50
  reducePercentage = reducePercentage / 100

  local damaged = false

  -- Connect damage listener while healing
  local dmgConn
  dmgConn = DamageService.DamageAccepted:Connect(function(attacker, target, damage)
    -- target may be a Player, Model, or player instance
    if target == player then
      damaged = true
      return
    end
    if typeof(target) == "Instance" and target:IsA("Model") then
      local p = Players:GetPlayerFromCharacter(target)
      if p == player then
        damaged = true
      end
    end
  end)

  local elapsed = 0

  local hbConn
  hbConn = RunService.Heartbeat:Connect(function(deltaTime)
    if not humanoid or not humanoid.Parent then
      if hbConn then hbConn:Disconnect() end
      if dmgConn then dmgConn:Disconnect() end
      return
    end

    elapsed = elapsed + deltaTime

    local targetTotal = totalHeal * (deltaTime / duration)
    if damaged then
      targetTotal = targetTotal * reducePercentage
    end
    humanoid.Health = math.min(humanoid.Health + targetTotal, humanoid.MaxHealth)

    if elapsed >= duration then
      -- print("Regen complete")
      if hbConn then hbConn:Disconnect() end
      if dmgConn then dmgConn:Disconnect() end
      return
    end
  end)
end

return Character