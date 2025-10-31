--!strict
local NPCDefaultName = 'NPCDefault'

return {
  CharactersNames = {
    [NPCDefaultName] = NPCDefaultName,
  },

  CharacterStats = {
    [NPCDefaultName] = {
      AttackSpeed = 1, -- 1 Means normal speed, 2 means double speed, etc. (so the animation will be played twice as fast)
      BaseSpeed = 8,
      WalkspeedMultiplier = 1, -- 1 Means normal speed, 2 means double speed, etc.

      DefaultAttackDamage = 10,
      DefaultAttackDistance = 1.5, -- In meters
      ReachDistance = 7, --A diameter in meters
      DefaultAttackCooldown = .8, -- In seconds
      DefaultAttackDelay = 0.45, -- In seconds
      RegenPerSecond = 20, -- Health points per second

      ToCharacterParameters = { --This transfers the stats to character parameters so in future it could be changed while game process
        'DefaultAttackDamage',
        'DefaultAttackDistance',
        'ReachDistance',
        'DefaultAttackCooldown',
        'DefaultAttackSpeed',
        'DefaultAttackDelay',
        'RegenPerSecond',
        'AttackSpeed',
        'BaseSpeed',
        'WalkspeedMultiplier',
      },

      Animation = {
        DefaultAttackDefault1 = 'rbxassetid://85425098780416',
        DefaultAttackDefault2 = 'rbxassetid://82954434741753',
        DefaultAttackDefault3 = 'rbxassetid://127300311899120', 
      }
    },
  },
}