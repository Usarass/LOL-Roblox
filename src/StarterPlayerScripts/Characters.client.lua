local Warp = require(game:GetService("ReplicatedStorage").Packages.Warp)
local CharactersEvents = require(game:GetService('ReplicatedStorage').Modules.Characters)

local SpecialEvent = Warp.Client('SpecialEvent')
local SpecialEventFunc = Warp.Client('SpecialEventFunc')

SpecialEvent:Connect(function(eventName : string, ...)
  print("SpecialEvent received:", eventName)
  print(...)
  local currentCharacter = game:GetService('Players').LocalPlayer:GetAttribute("CurrentCharacter")
  CharactersEvents[currentCharacter][eventName](...)
end)

SpecialEventFunc:Connect(function(eventName : string, ...)
  print("SpecialEventFunc received:", eventName)
  print(...)
  local currentCharacter = game:GetService('Players').LocalPlayer:GetAttribute("CurrentCharacter")
  local funcResult = CharactersEvents[currentCharacter][eventName](...)
  return funcResult
end)