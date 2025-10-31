local Characters = game:GetService('ServerStorage').Modules.Character
local PlayerStats = require(game:GetService("ServerStorage").Classes.Players)
local CharactersLiterals = require(game:GetService('ReplicatedStorage').Literals.Characters)

local Warp = require(game:GetService('ReplicatedStorage').Packages.Warp)

local RequestChangeCharacter = Warp.Server("RequestChangeCharacter")

local function onCharacterAdded(player, modelCharacter)
  local currentThread = coroutine.running()
  local currentCharacter = player:GetAttribute("CurrentCharacter")
  if not currentCharacter then
    task.delay(5, function()
      if currentCharacter then return end

      warn("CurrentCharacter attribute not set for player: " .. player.Name)
      coroutine.close(currentThread)
    end)

    while currentCharacter == nil do
      task.wait(.1) 
      currentCharacter = player:GetAttribute("CurrentCharacter") 
    end
  end

  local characterModule = PlayerStats.getCharacterModule(player)
  if characterModule ~= '' then 
    characterModule:Destroy()
  end

  local characterModule = require( Characters[currentCharacter] )
  if not characterModule then
    warn("Character module not found for: " .. currentCharacter)
    return
  end

  local character = characterModule.new(player)
  if not character then
    warn("Failed to create character for: " .. currentCharacter)
    return
  end
  -- print('character module:', character)

  local playerStats = PlayerStats.get(player)
  if not playerStats then
    task.delay(5, function()
      if playerStats then return end

      coroutine.close(currentThread)
      warn("Player stats not found for: " .. player.Name)
    end)

    while playerStats == nil do
      task.wait(.1)
      playerStats = PlayerStats.get(player)
    end

    return
  end
  
  playerStats:Set("CharacterModule", character)

  local humanoid = modelCharacter:FindFirstChildOfClass("Humanoid")
  if not humanoid then
    warn("Humanoid not found in character model: " .. modelCharacter.Name)
    return
  end

  humanoid.WalkSpeed = CharactersLiterals.CharacterStats[currentCharacter].BaseWalkSpeed
end

game:GetService('Players').PlayerAdded:Connect(function(player)
  -- onCharacterAdded(player)

  player.CharacterAdded:Connect(function(character)
    onCharacterAdded(player, character)

    print("Moing character to DamagableHumanoids")
    character.Parent = workspace.DamagableHumanoids

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then
      warn("Humanoid not found in character model: " .. character.Name)
      return
    end

    print("Setting health for", player.Name, "as", player:GetAttribute("CurrentCharacter"))
    local baseHealth = CharactersLiterals.CharacterStats[player:GetAttribute("CurrentCharacter")].BaseHealth or 100
    humanoid.MaxHealth = baseHealth
    humanoid.Health = baseHealth
  end)
end)

RequestChangeCharacter:Connect(function(player, characterName)
  characterName = CharactersLiterals.CharactersNames[characterName]
  if not characterName then
    warn("Invalid character name requested: " .. tostring(characterName))
    return
  end

  local playerStats = PlayerStats.get(player)
  if not playerStats then
    warn("Player stats not found for: " .. player.Name)
    return
  end

  playerStats:Set("CurrentCharacter", characterName)
  task.wait(0.1) -- Wait for the attribute to update
  player:LoadCharacter()
end)