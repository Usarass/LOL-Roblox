local UI = require(game:GetService("ReplicatedStorage").Modules.UI)
local Warp = require(game:GetService('ReplicatedStorage').Packages.Warp)
local Controls = require(game:GetService("ReplicatedStorage").Services.Controls)

local ShowCooldown = Warp.Client('ShowCooldown')
local ReqRegen = Warp.Client('ReqRegen')

local ControlsUI = {}
ControlsUI.__index = ControlsUI

function ControlsUI.init()
    local self = ControlsUI

    local user = game.Players.LocalPlayer
    if not user then
        warn("ControlsUI.init: LocalPlayer not found")
        return
    end

    local screenGui = user.PlayerGui:WaitForChild('InGamePhoneGui', 10)
    if not screenGui then
        warn("ControlsUI.init: InGamePhoneGui not found in PlayerGui")
        return
    end

    self.CloseToOpen = {
        'CharacterSelectUI'
    }

    self.User = user
    self.ScreenGui = screenGui
    self.Skill1Button = screenGui.Skill1
    self.Skill2Button = screenGui.Skill2
    self.Skill3Button = screenGui.Skill3
    self.AttackButton = screenGui.AttackButton
    self.RegenButton = screenGui.Regen
    self.RegenCooldownText = screenGui.Skill5Regen

    self.Skill1Name = screenGui.Controls_Skill_1
    self.Skill2Name = screenGui.Controls_Skill_2
    self.Skill3Name = screenGui.Controls_Skill_3

    self.SkillActivateButton1 = screenGui.SkillButton_1
    self.SkillActivateButton2 = screenGui.SkillButton_2
    self.SkillActivateButton3 = screenGui.SkillButton_3

    self.currentImages = {}

    self.skillButtons = {
      DefaultRange = {
        [self.SkillActivateButton1] = "ActionF",
        [self.SkillActivateButton2] = "ActionE",
        [self.SkillActivateButton3] = "ActionC"
      },

      Default = {
        [self.SkillActivateButton1] = "ActionR",
        [self.SkillActivateButton2] = "ActionF",
        [self.SkillActivateButton3] = "ActionC"
      }
    }

    local UIAssets = game:GetService("ReplicatedStorage").Assets.UI
    if not UIAssets then
      warn("ControlsUI.init: UI assets not found in ReplicatedStorage")
      return
    end

    self.ToCharacterSkillImage = {
      Default = {
        ActionF = UIAssets.Skill1Melee,
        ActionE = UIAssets.Skill2Melee,
        ActionC = UIAssets.Skill3Melee
      },
      DefaultRange = {
        ActionF = UIAssets.Skill1Ranged,
        ActionE = UIAssets.Skill2Ranged,
        ActionC = UIAssets.Skill3Ranged
      }
    }

    self.ToCharacterSkillName = {
      Default = {
        Skill1Name = "Press R",
        Skill2Name = "Press F",
        Skill3Name = "Press C"
      },
      DefaultRange = {
        Skill1Name = "F - AtkS & Damage",
        Skill2Name = "E - Slow & Dmg",
        Skill3Name = "C - Invis & Speed & +Dmg"
      }
    }

    self.Connections = {}
    self.NameToUi = {
        ActionC = self.Skill3Button,
        ActionE = self.Skill2Button,
        ActionF = self.Skill1Button,
        Regen = self.RegenCooldownText
    }

    self.skillButtonsConnections = {}

    self.characterBased()
    self.activateAttackButton()
    self.activateLowButtons()

    user.CharacterAdded:Connect(function()
      self.characterBased()
    end)

    return self
end

function ControlsUI.skillActivateButtons() --A method that inits activate buttons
  local self = ControlsUI

  local currentCharacter = self.User:GetAttribute("CurrentCharacter")
  if not currentCharacter then
    warn("ControlsUI.skillActivateButtons: CurrentCharacter attribute not found on player")
    return
  end

  local skillButtons = self.skillButtons[currentCharacter]
  if not skillButtons then
    warn("ControlsUI.skillActivateButtons: No skill buttons found for character: " .. currentCharacter)
    return
  end

  for button, actionName in next, skillButtons do
    local connection
    connection = button.MouseButton1Down:Connect(function(x, y)
      local handleFunc = Controls:GetHandlerFunction(actionName)
      if not handleFunc then
        warn("ControlsUI.skillButtons: No handler function found for " .. actionName)
        return
      end

      handleFunc(actionName, Enum.UserInputState.Begin, {X = x, Y = y, UserInputType = Enum.UserInputType.Touch, UserInputState = Enum.UserInputState.Begin})
    end)

    table.insert(self.skillButtonsConnections, connection)
  end
end

function ControlsUI.activateAttackButton()
  local self = ControlsUI

  local hold = false
  self.AttackButton.MouseButton1Down:Connect(function()
    hold = true
    local handleFunc = Controls:GetHandlerFunction("LeftClick")
    if not handleFunc then
      warn("ControlsUI.activateAttackButton: No handler function found for LeftClick")
      return
    end

    while hold do
      handleFunc("LeftClick", Enum.UserInputState.Begin)
      task.wait(0.1)
    end
  end)

  self.AttackButton.MouseButton1Up:Connect(function()
    hold = false
  end)
end

function ControlsUI.characterBased() --Makes all names in UIs character based
  local currentCharacter = ControlsUI.User:GetAttribute("CurrentCharacter")
  if not currentCharacter then
    warn("ControlsUI.characterBased: CurrentCharacter attribute not found on player")
    return
  end

  local skillNames = ControlsUI.ToCharacterSkillName[currentCharacter]
  if not skillNames then
    warn("ControlsUI.characterBased: No skill names found for character: " .. currentCharacter)
    return
  end

  ControlsUI.Skill1Name.Text = skillNames.Skill1Name
  ControlsUI.Skill2Name.Text = skillNames.Skill2Name
  ControlsUI.Skill3Name.Text = skillNames.Skill3Name

  local skillImages = ControlsUI.ToCharacterSkillImage[currentCharacter]
  if not skillImages then
    warn("ControlsUI.characterBased: No skill images found for character: " .. currentCharacter)
    return
  end

  local uiAssets = game:GetService("ReplicatedStorage").Assets.UI
  for _, img in next, ControlsUI.currentImages do
    img.Visible = false
    img.Parent = uiAssets
  end
  table.clear(ControlsUI.currentImages)

  local playerUI = ControlsUI.ScreenGui

  for action, button in next, skillImages do
    button.Visible = true
    button.Parent = playerUI
    ControlsUI.currentImages[action] = button
  end

  for _, connection in next, ControlsUI.skillButtonsConnections do
    connection:Disconnect()
  end

  table.clear(ControlsUI.skillButtonsConnections)
  ControlsUI.skillActivateButtons()
end

function ControlsUI.cooldown(cooldownName : string, cooldownDuration : number) --countdown the cooldown that are sent here
  if not cooldownName or not cooldownDuration then
    warn("CooldownVisual: ShowCooldown received no cooldownName or cooldown")
    return
  end

  if cooldownDuration <= 0 then
    warn("CooldownVisual: ShowCooldown received non-positive cooldown duration")
    return
  end

  local connections = ControlsUI.Connections
  local nameToUI = ControlsUI.NameToUi

  local uiElement = nameToUI[cooldownName]
  if not uiElement then
    warn("CooldownVisual: No UI element found for cooldown name: " .. tostring(cooldownName))
    return
  end

  local imageElement = ControlsUI.currentImages[cooldownName]
  if not imageElement then
    warn("CooldownVisual: No image element found for cooldown name: " .. tostring(cooldownName))
    return
  end
  imageElement.ImageTransparency = 0.5

  if connections[cooldownName] then
    connections[cooldownName]:Disconnect()
    connections[cooldownName] = nil
  end
  uiElement.Text = cooldownName

  connections[cooldownName] = game:GetService("RunService").RenderStepped:Connect(function(deltaTime)
    if cooldownDuration <= 0 then
      uiElement.Text = "0"
      connections[cooldownName]:Disconnect()
      connections[cooldownName] = nil
      imageElement.ImageTransparency = 0
      return
    end

    cooldownDuration = math.max(0, cooldownDuration - deltaTime)
    uiElement.Text = tostring(math.round(cooldownDuration))
  end)
end

function ControlsUI.activateLowButtons()
  local self = ControlsUI

  self.RegenButton.MouseButton1Click:Connect(function()
    print("ControlsUI.activateLowButtons: Firing ReqRegen action")
    ReqRegen:Fire(true)
  end)
end

function ControlsUI.open()

end

function ControlsUI.close()
    
end

ShowCooldown:Connect(function(cooldownName : string, cooldownDuration : number)
    ControlsUI.cooldown(cooldownName, cooldownDuration)
end)

return ControlsUI