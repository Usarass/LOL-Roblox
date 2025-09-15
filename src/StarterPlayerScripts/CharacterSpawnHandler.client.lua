local Controls = require(game:GetService('ReplicatedStorage').Services.Controls)
local ProximityPromptService = game:GetService('ProximityPromptService')
local CharactersLiterals = require(game:GetService('ReplicatedStorage').Literals.Characters)
local Warp = require(game:GetService('ReplicatedStorage').Packages.Warp)

local CharacterSelectUI = game:GetService('Players').LocalPlayer.PlayerGui:WaitForChild("CharacterSelectUI")
local CharactersHolder = CharacterSelectUI.CharactersHolder
local CharacterFrameTemplate = CharactersHolder.CharacterFrameTemplate

local RequestChangeCharacter = Warp.Client("RequestChangeCharacter")

local function Render()
  for _, frame in next, CharactersHolder:GetChildren() do
    if frame:IsA("Frame") == false or frame == CharacterFrameTemplate then continue end

    frame:Destroy()
  end

  for _, character in next, CharactersLiterals.CharactersNames do
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
      CharacterSelectUI.Enabled = false
    end)
  end
end

-- Controls:BindAction("OpenCharacterSelect", {Enum.KeyCode.M}, true, function(actionName, userInputState)
--   if actionName ~= "OpenCharacterSelect" or userInputState ~= Enum.UserInputState.Begin then return Enum.ContextActionResult.Pass end

--   CharacterSelectUI.Enabled = not CharacterSelectUI.Enabled
--   if CharacterSelectUI.Enabled then
--     Render()
--   end

--   -- RequestChangeCharacter:Fire(true)
-- end)



