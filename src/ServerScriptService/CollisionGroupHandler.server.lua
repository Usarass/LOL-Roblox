local ContentProvider = game:GetService("ContentProvider")
game:GetService('Players').PlayerAdded:Connect(function(player)
  player.CharacterAdded:Connect(function(character)
    for _, part in pairs(character:GetChildren()) do
      if part:IsA("BasePart") == false then continue end

      part.CollisionGroup = "Character"
    end
  end)
end)