local UI = require(game:GetService("ReplicatedStorage").Modules.UI)
local Warp = require(game:GetService('ReplicatedStorage').Packages.Warp)
local Controls = require(game:GetService("ReplicatedStorage").Services.Controls)
local CharactersLiterals = require(game:GetService('ReplicatedStorage').Literals.Characters)  

local RequestChangeCharacter = Warp.Client("RequestChangeCharacter")
local SwitchCharacter = {}
SwitchCharacter.__index = SwitchCharacter

function SwitchCharacter.init()
    local self = SwitchCharacter

    local user = game.Players.LocalPlayer
    if not user then
        warn("SwitchCharacter.init: LocalPlayer not found")
        return
    end

    local playerGui = user.PlayerGui

    local screenGui = playerGui:WaitForChild('CharacterSelectUI')
    if not screenGui then
        warn("SwitchCharacter.init: CharacterSelectUI not found in PlayerGui")
        return
    end

    self.ScreenGui = screenGui
    self.CharacterHolder = screenGui:WaitForChild('CharactersHolder', 3)
    if not self.CharacterHolder then
        warn("SwitchCharacter.init: CharacterHolder not found in CharacterSelectUI")
        return
    end

    self.CharacterFrameTemplate = self.CharacterHolder:WaitForChild('CharacterFrameTemplate', 10)

    self.IgnoreCharacterName = {
      CharactersLiterals.CharactersNames.NPCDefault
    }

    self.OpenToClose = {
      'InGamePhoneGui'
    }

    self.CloseToOpen = {
      'InGamePhoneGui'
    }

    return self
end

function SwitchCharacter.render()
  local CharactersHolder = SwitchCharacter.CharacterHolder
  local CharacterFrameTemplate = SwitchCharacter.CharacterFrameTemplate
  
    for _, frame in next, CharactersHolder:GetChildren() do
    if frame:IsA("Frame") == false or frame == CharacterFrameTemplate then continue end

    frame:Destroy()
  end

  print(SwitchCharacter.IgnoreCharacterName)

  for _, character in next, CharactersLiterals.CharactersNames do
    if table.find(SwitchCharacter.IgnoreCharacterName, character) then
      continue
    end 
    -- print("Rendering character: " .. character)
    local characterFrame = CharacterFrameTemplate:Clone()
    local characterImage = characterFrame:FindFirstChild("CharacterImage")
    if not characterImage then
      warn("CharacterImage not found in CharacterFrameTemplate")
      continue
    end

    local characterName = characterImage:FindFirstChild("CharacterName")
    if not characterName then
      warn("CharacterName not found in CharacterImage")
      continue
    end

    characterName.Text = character

    characterFrame.Parent = CharactersHolder
    characterFrame.Visible = true

    characterImage.MouseButton1Click:Connect(function()
      RequestChangeCharacter:Fire(true, character)
      UI.openClose('CharacterSelectUI')
    end)
  end
end

function SwitchCharacter.open()
  SwitchCharacter.render()
end

function SwitchCharacter.close()
  UI.openClose('InGamePhoneGui')
end

Controls:BindAction("OpenCharacterSelect", {Enum.KeyCode.M}, true, function(actionName, userInputState)
  if actionName ~= "OpenCharacterSelect" or userInputState ~= Enum.UserInputState.Begin then return Enum.ContextActionResult.Pass end

  UI.openClose('CharacterSelectUI')
end)

return SwitchCharacter