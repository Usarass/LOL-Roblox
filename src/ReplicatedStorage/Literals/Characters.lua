--!strict
local CharacterDefaultName = 'Default'
local CharacterRangeDefaultName = 'DefaultRange'
local NPCDefaultName = 'NPCDefault'

local DefaultSoundsGroup = game:GetService('SoundService').DefaultSounds
local DefaultRangeSoundsGroup = game:GetService('SoundService').DefaultRangeSounds

return {
  CharactersNames = {
    [CharacterDefaultName] = CharacterDefaultName,
    [CharacterRangeDefaultName] = CharacterRangeDefaultName,
    [NPCDefaultName] = NPCDefaultName,
  },

  CharacterStats = {
    [CharacterDefaultName] = {
      AttackSpeed = 1,
      DamageMultiplier = 1,
      BaseWalkSpeed = 22,
			BaseHealth = 3257,
      WalkspeedMultiplier = 1,
      Resistance = 1, --Resistance in normal percentage, so 1 means 100% damage taken, 0.9 means 90% damage taken, etc.

      DefaultAttackDamage = 159,
      DefaultAttackDistance = 3, -- In meters
      ReachDistance = 3, --A diameter in meters
      DefaultAttackCooldown = .5, -- In seconds
      -- DefaultAttackSpeed = 1, -- 1 Means normal speed, 2 means double speed, etc. (so the animation will be played twice as fast)
      DefaultAttackDamageMultiplier = 1,
      DefaultAttackDelay = 0.45, -- In seconds
      DashCooldown = 8, -- In seconds
      DashDistance = 5, -- In meters
      DefaultAttackAfterHitDelay = 0.1, -- In seconds
      -- BaseWalkSpeed = 16,

      ActionCCooldown = 22,
      ActionCInvisibilityDuration = 3,
      ActionCWalkSpeedBuff = 40, -- In percentage
      ActionCWalkSpeedBuffDuration = 3,
      ActionCDamageResistanceBuff = -100, -- In percentage
      ActionCDamageResistanceBuffDuration = 3,
      ActionCHeal = 100, --In actual health points
      ActionCHealDuration = 3, --In seconds
      ActionCTransparency = .95,

      ActionFDamage = 11,
      ActionFTargetWalkSpeedSlowdown = -70, --In percentage
      ActionFTargetWalkSpeedDuration = .9, --In seconds
      ActionFCooldown = 10, --In seconds
      ActionFAttackSpeedBuff = 50, --In percentage
      ActionFAttackSpeedBuffDuration = 2, --In seconds
      ActionFTargetAttackSpeedSlowdown = -50, --In percentage
      ActionFTargetAttackSpeedDuration = 2, --In seconds
      ActionFReachDistance = 3, --In meters
      ActionFRaycastDuration = .4, --In seconds
      ActionFNoCollisionDuration = .5, --In seconds
      ActionFRaycastMultiplier = 4, -- Multiplier for the raycast length
      ActionFAlignForcesDuration = .15, --In seconds

      RegenCooldown = 11, -- Cooldown in seconds
			RegenTotalHealth = 3257, -- Total health to regen
      RegenDuration = 1, -- Duration of the regen in seconds
      ReducePercentageWhenDamaged = 99, -- Percentage to reduce the regen when damaged during the regen duration

      ToCharacterParameters = { --This transfers the stats to character parameters so in future it could be changed while game process
        'AttackSpeed',
        'DamageMultiplier',
        'BaseWalkSpeed',
        'WalkspeedMultiplier',
        'Resistance',

        'DefaultAttackDamage',
        'DefaultAttackDistance',
        'ReachDistance',
        'DefaultAttackCooldown',
        -- 'DefaultAttackSpeed',
        'DefaultAttackDelay',
        'DashCooldown',
        'DashDistance',
        'DefaultAttackAfterHitDelay',
        -- 'DefaultAttackDamageMultiplier'

        'ActionCCooldown',
        'ActionCInvisibilityDuration',
        'ActionCWalkSpeedBuff',
        'ActionCWalkSpeedBuffDuration',
        'ActionCDamageResistanceBuff',
        'ActionCDamageResistanceBuffDuration',
        'ActionCHeal',
        'ActionCHealDuration',
        'ActionCTransparency',

        'ActionFDamage',
        'ActionFTargetWalkSpeedSlowdown',
        'ActionFTargetWalkSpeedDuration',
        'ActionFCooldown',
        'ActionFAttackSpeedBuff',
        'ActionFAttackSpeedBuffDuration',
        'ActionFTargetAttackSpeedSlowdown',
        'ActionFTargetAttackSpeedDuration',
        'ActionFReachDistance',
        'ActionFRaycastDuration',
        'ActionFNoCollisionDuration',
        'ActionFRaycastMultiplier',
        
        'RegenTotalHealth',
        'RegenDuration',
        'ReducePercentageWhenDamaged',
        'RegenCooldown',
      },

      Animation = {
        DefaultAttackP1 = 'rbxassetid://85425098780416',
        DefaultAttackP2 = 'rbxassetid://82954434741753',
        DefaultAttackP3 = 'rbxassetid://127300311899120',
      },

      Sounds = {
        Whoosh = DefaultSoundsGroup.DefaultWhoosh,
        LandedPunch = DefaultSoundsGroup.DefaultLandedPunch,
      }
    },

    [CharacterRangeDefaultName] = {
      AttackSpeed = 1,
      DamageMultiplier = 1,
      BaseWalkSpeed = 18,
      WalkspeedMultiplier = 1,
			BaseHealth = 2897,
      Resistance = 1, --Resistance in normal percentage, so 1 means 100% damage taken, 0.9 means 90% damage taken, etc.

      DefaultAttackDamage = 120,
      DefaultAttackDistance = 13, -- In meters
      ReachDistance = 13, --A diameter in meters
      DefaultAttackCooldown = .5, -- In seconds
      -- DefaultAttackSpeed = 1, -- 1 Means normal speed, 2 means double speed, etc. (so the animation will be played twice as fast)
      -- DefaultAttackDamageMultiplier = 1,
      DefaultAttackDelay = 0.05, -- In seconds
      DefaultAttackArrowSpeed = 150, -- In studs per second
      DefaultAttackArrowHitDistance = .05, -- In meters
      DefaultAttackAfterHitDelay = 0.1, -- In seconds

      ActionFDamageBuff = 50,   --In percentage
      ActionFAttackSpeedBuff = 100, --In percentage
      ActionFDamageBuffDuration = 3, --In seconds
      ActionFAttackSpeedBuffDuration = 3, --In seconds
      ActionFCooldown = 7, --In seconds

      ActionEDelay = .1,
      ActionEDamage = 111,
      ActionEWalkSpeedSlowdown = -40, --Slowdown in percentage
      ActionEWalkSpeedSlowdownDuration = 1,
      ActionECooldown = 9,
      ActionEReachDistance = 3.2, --In meters
      ActionEBetweenCooldown = 3,

      ActionCTransparency = .97,
      ActionCAttackSpeedBuff = 140, -- In percentage
      ActionCAttackSpeedBuffDuration = 6,
      ActionCDamageBuff = 90, -- In percentage,
      ActionCDamageBuffDuration = 6,
      ActionCWalkSpeedBuff = 5, -- In percentage
      ACtionCWalkSpeedBuffDuration = 6,
      ActionCCooldown = 19,

      RegenCooldown = 6, -- Cooldown in seconds
			RegenTotalHealth = 2897, -- Total health to regen
      RegenDuration = 1, -- Duration of the regen in seconds
      ReducePercentageWhenDamaged = 99, -- Percentage to reduce the regen when damaged during the regen duration

      ToCharacterParameters = {
        'AttackSpeed',
        'DamageMultiplier',
        'BaseWalkSpeed',
        'WalkspeedMultiplier',
        'Resistance',

        'DefaultAttackDamage',
        'DefaultAttackDistance',
        'ReachDistance',
        'DefaultAttackCooldown',
        -- 'DefaultAttackSpeed',
        'DefaultAttackDelay',
        'DefaultAttackArrowHitDistance',
        'DefaultAttackArrowSpeed',
        'DefaultAttackAfterHitDelay',
        -- 'DefaultAttackDamageMultiplier',
        'ActionFDamageBuff',
        'ActionFAttackSpeedBuff',
        'ActionFDamageBuffDuration',
        'ActionFAttackSpeedBuffDuration',
        'ActionFCooldown',
        'ActionCTransparency',
        'ActionCAttackSpeedBuff',
        'ActionCAttackSpeedBuffDuration',
        'ActionCDamageBuff',
        'ActionCDamageBuffDuration',
        'ActionCWalkSpeedBuff',
        'ACtionCWalkSpeedBuffDuration',
        'ActionCCooldown',
        'ActionEDelay',
        'ActionEDamage',
        'ActionEWalkSpeedSlowdown',
        'ActionECooldown',
        'ActionEReachDistance',
        'ActionEBetweenCooldown',
        'ActionEWalkSpeedSlowdownDuration',

        'RegenTotalHealth',
        'RegenDuration',
        'ReducePercentageWhenDamaged',
        'RegenCooldown',
      },

      Animation = {
        DefaultRangeAttackDefault1 = 'rbxassetid://85425098780416',
        DefaultRangeAttackDefault2 = 'rbxassetid://82954434741753',
        DefaultRangeAttackDefault3 = 'rbxassetid://127300311899120', 
      },

      Sounds = {
        DefaultRangeFire = DefaultRangeSoundsGroup.BowFire,
        DefaultRangeHit = DefaultRangeSoundsGroup.BowHit,
      }
    },

    [NPCDefaultName] = {
      AttackSpeed = 1, -- 1 Means normal speed, 2 means double speed, etc. (so the animation will be played twice as fast)
      BaseWalkSpeed = 17,
      BaseHealth = 20000,
      WalkspeedMultiplier = 1, -- 1 Means normal speed, 2 means double speed, etc.

      DefaultAttackDamage = 60,
      DefaultAttackDistance = 2.5, -- In meters
      ReachDistance = 15, --A diameter in meters
      DefaultAttackCooldown = .8, -- In seconds
      DefaultAttackDelay = 0.45, -- In seconds
      RegenPerSecond = 5000, -- Health points per second

      ToCharacterParameters = { --This transfers the stats to character parameters so in future it could be changed while game process
        'DefaultAttackDamage',
        'DefaultAttackDistance',
        'ReachDistance',
        'DefaultAttackCooldown',
        'DefaultAttackSpeed',
        'DefaultAttackDelay',
        'RegenPerSecond',
        'AttackSpeed',
        'BaseWalkSpeed',
        'WalkspeedMultiplier',
      },

      Animation = {
        AttackDefault1 = 'rbxassetid://85425098780416',
        AttackDefault2 = 'rbxassetid://82954434741753',
        AttackDefault3 = 'rbxassetid://127300311899120', 
      },

      Sounds = {
        Whoosh = DefaultSoundsGroup.DefaultWhoosh,
        LandedPunch = DefaultSoundsGroup.DefaultLandedPunch,
      }
    },
  }
}