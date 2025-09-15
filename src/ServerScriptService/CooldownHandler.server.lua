local CooldownsHandler = require(game:GetService('ServerStorage').Modules.Cooldown)

game:GetService('Players').PlayerAdded:Connect(function(player)
  CooldownsHandler.new(player)
end)

game:GetService('Players').PlayerRemoving:Connect(function(player)
  CooldownsHandler.destruct(player)
end)