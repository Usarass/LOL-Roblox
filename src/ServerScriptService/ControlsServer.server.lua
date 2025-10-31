local Warp = require(game:GetService("ReplicatedStorage").Packages.Warp)
local CharacterLiterals = require(game:GetService("ReplicatedStorage").Literals.Characters)
local Consts = require(game:GetService("ReplicatedStorage").Literals.Consts)
local PlayerStats = require(game:GetService("ServerStorage").Classes.Players)

local OnLeftClick = Warp.Server("LeftClick")
local OnActionF = Warp.Server("ActionF")
local OnActionC = Warp.Server("ActionC")
local OnActionE = Warp.Server("ActionE")
local OnActionR = Warp.Server("OnActionR")
local ReqRegen = Warp.Server('ReqRegen')

OnLeftClick:Connect(function(player, enemyCharacter : Model)
  local playerStats = PlayerStats.get(player)
  if not playerStats then
    warn("Player stats not found for player: " .. player.Name)
    return
  end

  local characterModule = playerStats.CharacterModule
  -- print("Character module for player: ", characterModule)
  if not characterModule then
    warn("Character module not found for player: " .. player.Name)
    return
  end

  if not enemyCharacter then
    characterModule:OnLeftClick()
    return
  end

  if enemyCharacter:IsA("Model") == false then
    warn("Enemy character is not a Model for player: " .. player.Name)
    return
  end
  
  characterModule:DefaultAttack(enemyCharacter)
end)

OnActionR:Connect(function(player, inputState)
  local playerStats = PlayerStats.get(player)
  if not playerStats then
    warn("Player stats not found for player: " .. player.Name)
    return
  end

  local characterModule = playerStats.CharacterModule
  -- print("Character module for player: ", characterModule)
  if not characterModule then
    warn("Character module not  nd for player: " .. player.Name)
    return
  end

  characterModule:ActionR(inputState)
end)

OnActionF:Connect(function(player, inputState)
  local playerStats = PlayerStats.get(player)
  if not playerStats then
    warn("Player stats not found for player: " .. player.Name)
    return
  end

  local characterModule = playerStats.CharacterModule
  -- print("Character module for player: ", characterModule)
  if not characterModule then
    warn("Character module not found for player: " .. player.Name)
    return
  end

  characterModule:ActionF(inputState)
end)

OnActionC:Connect(function(player)
  local playerStats = PlayerStats.get(player)
  if not playerStats then
    warn("Player stats not found for player: " .. player.Name)
    return
  end

  local characterModule = playerStats.CharacterModule
  -- print("Character module for player: ", characterModule)
  if not characterModule then
    warn("Character module not found for player: " .. player.Name)
    return
  end

  characterModule:ActionC()
end)

OnActionE:Connect(function(player, inputObj)
  local playerStats = PlayerStats.get(player)
  if not playerStats then
    warn("Player stats not found for player: " .. player.Name)
    return
  end

  local characterModule = playerStats.CharacterModule
  -- print("Character module for player: ", characterModule)
  if not characterModule then
    warn("Character module not found for player: " .. player.Name)
    return
  end

  print("Calling ActionE on server with inputObj: ", inputObj)
  characterModule:ActionE(inputObj)
end)

ReqRegen:Connect(function(player)
  local playerStats = PlayerStats.get(player)
  if not playerStats then
    warn("Player stats not found for player: " .. player.Name)
    return
  end

  local characterModule = playerStats.CharacterModule
  -- print("Character module for player: ", characterModule)
  if not characterModule then
    warn("Character module not found for player: " .. player.Name)
    return
  end

  characterModule:Regen()
end)