-- DamageService
-- Computes final damage after status effects and fires a signal when damage is accepted.

local GoodSignal = require(game:GetService("ReplicatedStorage").Packages.GoodSignal)
local StatusEffects = require(game:GetService("ServerStorage").Modules.StatusEffects)
local CharactersLiterals = require(game:GetService("ReplicatedStorage").Literals.Characters)
local PlayerStats = require(game:GetService("ServerStorage").Classes.Players)

local DamageService = {}

-- Public signal: Connect to this to observe accepted damage
DamageService.DamageAccepted = GoodSignal.new()

local function calculateResistance(targetModule : {}, attackerModule : {}, baseDamage : number)
  local resistanceFactor = targetModule.Parameters.Resistance
  if not resistanceFactor then
    print("DamageService: Target has no Resistance parameter")
      return baseDamage
  end
  return baseDamage * resistanceFactor
end

local function calculateBuffs(targetModule : {}, attackerModule : {}, baseDamage : number)
  local damageMultiplier = attackerModule.Parameters.DamageMultiplier

  if not damageMultiplier then 
    print("DamageService: Target has no DamageMultiplier parameter")
    return baseDamage 
  end

  return baseDamage * damageMultiplier
end

function DamageService.CalculateAndApplyDamage(attacker : Player | Model, target : Player | Model, baseDamage : number)
    if type(baseDamage) ~= "number" then
        warn("DamageService: baseDamage must be a number")
        return nil
    end
    if not target then
        warn("DamageService: target required")
        return nil
    end

    local characterModule = PlayerStats.getCharacterModule(target)
    if not characterModule then
        warn("DamageService: target has no character module")
        characterModule = {
          Parameters = {
            Resistance = 1,
          }
        }
        -- DamageService.DamageAccepted:Fire(attacker, target, baseDamage)
        -- return baseDamage
    end

    local attackerModule = PlayerStats.getCharacterModule(attacker)
    if not attackerModule then
        warn("DamageService: attacker has no character module")
        DamageService.DamageAccepted:Fire(attacker, target, baseDamage)
        return baseDamage
    end

    -- local dmgMultiplier = computeDamageMultiplierForTarget(target)
    local finalDamage = calculateResistance(characterModule, attackerModule, baseDamage)
    finalDamage = calculateBuffs(characterModule, attackerModule, finalDamage)

    -- Fire signal (non-blocking); handlers may yield safely because GoodSignal spawns runners
    DamageService.DamageAccepted:Fire(attacker, target, finalDamage)

    return finalDamage
end

return DamageService
