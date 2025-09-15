local PlayerStats = {Players = {}}
PlayerStats.__index = PlayerStats

function PlayerStats.new(player : Player, currentCharacter : string?)
  local self = setmetatable({
    ControllingPlayer = player,
    CurrentCharacter =  currentCharacter or 'DefaultRange',
    CharacterModule = '',
  }, PlayerStats)

  local ignoreAttributes = {
    "CharacterModule",
    "ControllingPlayer",
  }

  for statName, statValue in self do
    if table.find(ignoreAttributes, statName) then continue end
 
    player:SetAttribute(statName, statValue)
  end

  PlayerStats.Players[player.UserId] = self
  return self
end

function PlayerStats.get(player : Player)
  if not player or not player:IsA("Player") then
    warn("Invalid player provided to PlayerStats.get")
    return
  end

  if not PlayerStats.Players[player.UserId] then
    warn("PlayerStats not found for player: " .. player.Name)
    return
  end

  return PlayerStats.Players[player.UserId]
end

function PlayerStats.getCharacterModule(player : Player)
  local playerStats = PlayerStats.get(player)
  if not playerStats then return nil end

  return playerStats.CharacterModule
end

function PlayerStats:Set(statName : string, statValue : any)
  if not self[statName] then
    warn("Attempted to set non-existent stat: " .. statName)
    return
  end

  self[statName] = statValue
  print(self)

  local attribute = self.ControllingPlayer:GetAttribute(statName)
  if attribute == nil then
    return
  end

  self.ControllingPlayer:SetAttribute(statName, statValue)
end

function PlayerStats.destruct(player : Player)
  local playerStats = PlayerStats.Players[player.UserId]
  if playerStats == nil then return end

  PlayerStats.Players[player.UserId] = nil
end

return PlayerStats