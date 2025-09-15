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
    self.RegenButton = screenGui.Skill5Regen

    self.Skill1Name = screenGui.Controls_Skill_1
    self.Skill2Name = screenGui.Controls_Skill_2
    self.Skill3Name = screenGui.Controls_Skill_3

    self.SkillActivateButton1 = screenGui.SkillButton_1
    self.SkillActivateButton2 = screenGui.SkillButton_2
    self.SkillActivateButton3 = screenGui.SkillButton_3

    self.RegenButton = screenGui.Skill5Regen

    self.skillButtons = {
      [self.SkillActivateButton1] = 'ActionF',
      [self.SkillActivateButton2] = 'ActionE',
      [self.SkillActivateButton3] = 'ActionC'
    }

    self.ToCharacterSkillName = {
      Default = {
        Skill1Name = "ActionF",
        Skill2Name = "ActionE",
        Skill3Name = "ActionC"
      },
      DefaultRange = {
        Skill1Name = "ActionF",
        Skill2Name = "ActionE",
        Skill3Name = "ActionC"
      }
    }

    self.Connections = {}
    self.NameToUi = {
        ActionC = self.Skill3Button,
        ActionE = self.Skill2Button,
        ActionF = self.Skill1Button,
    }

    self.characterBased()
    self.skillActivateButtons()
    self.activateAttackButton()

    return self
end

function ControlsUI.skillActivateButtons() --A method that inits activate buttons
  local self = ControlsUI

  for button, actionName in next, self.skillButtons do
    button.MouseButton1Click:Connect(function()
      local handleFunc = Controls:GetHandlerFunction(actionName)
      if not handleFunc then
        warn("ControlsUI.skillButtons: No handler function found for " .. actionName)
        return
      end

      handleFunc(actionName, Enum.UserInputState.Begin)
    end)
  end
end

function ControlsUI.activateAttackButton()
  local self = ControlsUI

  self.AttackButton.MouseButton1Click:Connect(function()
    local handleFunc = Controls:GetHandlerFunction("LeftClick")
    if not handleFunc then
      warn("ControlsUI.activateAttackButton: No handler function found for LeftClick")
      return
    end

    print("ControlsUI.activateAttackButton: Firing LeftClick action")
    handleFunc("LeftClick", Enum.UserInputState.Begin)
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

  if connections[cooldownName] then
    connections[cooldownName]:Disconnect()
    connections[cooldownName] = nil
  end

  uiElement.Text = cooldownName
  
  print("CooldownVisual: Starting cooldown for " .. cooldownName .. " with duration " .. tostring(cooldownDuration))
  connections[cooldownName] = game:GetService("RunService").RenderStepped:Connect(function(deltaTime)
    -- print("CooldownVisual: Cooldown for " .. cooldownName .. " is " .. tostring(cooldown))
    if cooldownDuration <= 0 then
      uiElement.Text = "0"
      connections[cooldownName]:Disconnect()
      connections[cooldownName] = nil
      return
    end

    cooldownDuration = math.max(0, cooldownDuration - deltaTime)
    uiElement.Text = tostring(math.round(cooldownDuration))
  end)
end

function ControlsUI.activateLowButtons()
  local self = ControlsUI

  self.RegenButton.MouseButton1Click:Connect(function()
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