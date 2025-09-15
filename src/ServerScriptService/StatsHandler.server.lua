local Stats = require(game:GetService("ServerStorage").Classes.Players)

game:GetService("Players").PlayerAdded:Connect(function(player)
  Stats.new(player)
end)

game:GetService("Players").PlayerRemoving:Connect(function(player)
  Stats.destruct(player)
end)