local Players = game:GetService("Players")
local StateManager = require(game.ServerStorage.Classes.StateManager)

Players.PlayerAdded:Connect(function(player)
  player.CharacterAdded:Connect(function(character)
    local manager = StateManager.new(character)
    StateManager.ApplyDefaultStates(manager)
  end)
end)