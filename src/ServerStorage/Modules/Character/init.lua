--//WARNING: While naming scripts inside this, please notice that it MUST be the same as the character name in the Characters.lua file

local CharacterLiterals = require(game:GetService("ReplicatedStorage").Literals.Characters)
local Consts = require(game:GetService("ReplicatedStorage").Literals.Consts)
local Warp = require(game:GetService("ReplicatedStorage").Packages.Warp)
local CooldownHandler = require(game:GetService('ServerStorage').Modules.Cooldown)

local PlayAnimation = Warp.Server('PlayAnimation')
local StopAllAnimations = Warp.Server('StopAllAnimations')
local PlaySound = Warp.Server('PlaySound')

local Character = {}
Character.__index = Character

function Character.new(player : Player)
  local self = setmetatable({
    Player = player,
    InUse = false,
  }, Character)

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

return Character