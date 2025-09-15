--!strict
local CharacterDefaultName = 'Default'
local CharacterRangeDefaultName = 'DefaultRange'

local DefaultSoundsGroup = game:GetService('SoundService').DefaultSounds
local DefaultRangeSoundsGroup = game:GetService('SoundService').DefaultRangeSounds

return {
  CharactersNames = {
    [CharacterDefaultName] = CharacterDefaultName,
    [CharacterRangeDefaultName] = CharacterRangeDefaultName,
  },

  CharacterStats = {
    [CharacterDefaultName] = {
      DefaultAttackDamage = 10,
      DefaultAttackDistance = 1.5, -- In meters
      ReachDistance = 10, --A diameter in meters
      DefaultAttackCooldown = .5, -- In seconds
      DefaultAttackSpeed = 1, -- 1 Means normal speed, 2 means double speed, etc. (so the animation will be played twice as fast)
      DefaultAttackDamageMultiplier = 1,
      DefaultAttackDelay = 0.45, -- In seconds
      DashCooldown = 2, -- In seconds
      DashDistance = 10, -- In meters
      DefaultAttackAfterHitDelay = 0.1, -- In seconds
      BaseWalkSpeed = 16,

      ToCharacterParameters = { --This transfers the stats to character parameters so in future it could be changed while game process
        'DefaultAttackDamage',
        'DefaultAttackDistance',
        'ReachDistance',
        'DefaultAttackCooldown',
        'DefaultAttackSpeed',
        'DefaultAttackDelay',
        'DashCooldown',
        'DashDistance',
        'DefaultAttackAfterHitDelay',
        'DefaultAttackDamageMultiplier'
      },

      Animation = {
        DefaultAttackDefault1 = 'rbxassetid://85425098780416',
        DefaultAttackDefault2 = 'rbxassetid://82954434741753',
        DefaultAttackDefault3 = 'rbxassetid://127300311899120', 
      },

      Sounds = {
        DefaultWhoosh = DefaultSoundsGroup.DefaultWhoosh,
        DefaultLandedPunch = DefaultSoundsGroup.DefaultLandedPunch,
      }
    },

    [CharacterRangeDefaultName] = {
      AttackSpeed = 1,
      DamageMultiplier = 1,
      BaseWalkSpeed = 26,

      DefaultAttackDamage = 10,
      DefaultAttackDistance = 10, -- In meters
      ReachDistance = 10, --A diameter in meters
      DefaultAttackCooldown = .5, -- In seconds
      -- DefaultAttackSpeed = 1, -- 1 Means normal speed, 2 means double speed, etc. (so the animation will be played twice as fast)
      -- DefaultAttackDamageMultiplier = 1,
      DefaultAttackDelay = 0.05, -- In seconds
      DefaultAttackArrowSpeed = 150, -- In studs per second
      DefaultAttackArrowHitDistance = .05, -- In meters
      DefaultAttackAfterHitDelay = 0.1, -- In seconds

      ActionFDamageBuff = 10, --In percentage
      ActionFAttackSpeedBuff = 20, --In percentage
      ActionFDamageBuffDuration = 3, --In seconds
      ActionFAttackSpeedBuffDuration = 3, --In seconds
      ActionFCooldown = 3, --In seconds

      ActionEDelay = .1,
      ActionEDamage = 10,
      ActionEWalkSpeedSlowdown = -50, --Slowdown in percentage
      ActionEWalkSpeedSlowdownDuration = 2,
      ActionECooldown = 3,
      ActionEReachDistance = 3.2, --In meters
      ActionEBetweenCooldown = .5,

      ActionCTransparency = .7,
      ActionCAttackSpeedBuff = 40, -- In percentage
      ActionCAttackSpeedBuffDuration = 6,
      ActionCDamageBuff = 20, -- In percentage,
      ActionCDamageBuffDuration = 6,
      ActionCWalkSpeedBuff = 20, -- In percentage
      ACtionCWalkSpeedBuffDuration = 6,
      ActionCCooldown = 6,

      ToCharacterParameters = {
        'DefaultAttackDamage',
        'DefaultAttackDistance',
        'ReachDistance',
        'DefaultAttackCooldown',
        'DefaultAttackSpeed',
        'DefaultAttackDelay',
        'DefaultAttackArrowHitDistance',
        'DefaultAttackArrowSpeed',
        'DefaultAttackAfterHitDelay',
        'DefaultAttackDamageMultiplier',
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
        'ActionEWalkSpeedSlowdownDuration'
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
    }
  }
}