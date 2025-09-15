local StatusEffects = require(game:GetService('ServerStorage').Modules.StatusEffects)

game:GetService('Players').PlayerAdded:Connect(function(player)
  StatusEffects.new(player)
end)

game:GetService('Players').PlayerRemoving:Connect(function(player)
  StatusEffects.destruct(player)
end)