local ContextActionService = game:GetService("ContextActionService")

local Keymap = {
  actions = {},
  OnMobile = nil,
  mobileButtons = {},
  GamepadConnected = game:GetService('UserInputService').GamepadEnabled
}
Keymap.__index = Keymap

export type Keymap = {
  actions: { [string]: Enum.KeyCode },
  BindAction: (self: Keymap, actionName: string, keyCode: Enum.KeyCode, actionHandler: (actionName: string, userInputState: Enum.UserInputState) -> ()) -> nil,
  UnbindAction: (self: Keymap, actionName: string) -> nil,
  UnbindAll: (self: Keymap) -> nil,
}

function Keymap:BindAction(actionName : string, keyCodes : {Enum.KeyCode}, createButtonInMobile : boolean, actionHandler : () -> nil)
  ContextActionService:BindAction(actionName, actionHandler, false, table.unpack(keyCodes))

  if createButtonInMobile and self:GetIsOnMobile() then
    local playerGui = game:GetService('Players').LocalPlayer.PlayerGui

    local mobileGui = playerGui:FindFirstChild('Mobile') or Instance.new('ScreenGui')
    if mobileGui.Name ~= 'Mobile' then
      mobileGui.Name = 'Mobile'
      mobileGui.Parent = playerGui
    end

    local button = Instance.new('ImageButton') 
    button.Image = 'rbxassetid://11111111111111111111111111111111'
    button.Size = UDim2.new(.09, 0, .09, 0)
    button.ScaleType = Enum.ScaleType.Fit
    button.Position = UDim2.new(0, 0, 0, 0)
    button.Parent = mobileGui
    button.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    button.BackgroundTransparency = 0.5

    local uiCorner = Instance.new('UICorner')
    uiCorner.CornerRadius = UDim.new(1, 0)
    uiCorner.Parent = button

    local uiStroke = Instance.new('UIStroke')
    uiStroke.Color = Color3.fromRGB(214, 214, 214)
    uiStroke.Thickness = 2
    uiStroke.Parent = button
    uiStroke.Transparency = .5

    local textLabel = Instance.new('TextLabel')
    textLabel.Text = actionName
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.Position = UDim2.new(0, 0, 0, 0)
    textLabel.Parent = button
    textLabel.TextColor3 = Color3.fromRGB(214, 214, 214)
    textLabel.BackgroundTransparency = 1

    button.InputBegan:Connect(function(input, gameProcessedEvent)
      actionHandler(actionName, Enum.UserInputState.Begin)
    end)

    button.InputEnded:Connect(function()
      actionHandler(actionName, Enum.UserInputState.End)
    end)

    self.mobileButtons[actionName] = button
  end

  self.actions[actionName] = {
    Keycodes = keyCodes,
    Handler = actionHandler
  }
end

function Keymap:GetHandlerFunction(actionName : string)
  if not self.actions[actionName] then
    return nil
  end

  return self.actions[actionName].Handler
end

function Keymap:UnbindAction(actionName : string)
  if not self.actions[actionName] then
    -- warn("No action with name " .. actionName .. " is bound.")
    return
  end

  ContextActionService:UnbindAction(actionName)
  self.actions[actionName] = nil
end

function Keymap:GetGamepadConnected()
  self.GamepadConnected = game:GetService('UserInputService').GamepadEnabled
  return self.GamepadConnected
end

function Keymap:GetIsOnMobile()
  if self.OnMobile ~= nil then return self.OnMobile end

  local player = game:GetService('Players').LocalPlayer
  if not player then return false end

  local UserInputService = game:GetService("UserInputService")
  -- self.OnMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled and not UserInputService.GamepadEnabled --ON PRODUCT
  self.OnMobile = UserInputService.TouchEnabled -- ON DEV
  return self.OnMobile
end

function Keymap:SetMobileTitle(actionName : string, title : string)
  if not self.mobileButtons[actionName] then
    -- warn("No action with name " .. actionName .. " is bound.")
    return
  end

  local textLabel = self.mobileButtons[actionName]:FindFirstChild('TextLabel')
  if not textLabel then
    -- warn("No text label found for action " .. actionName)
    return
  end

  textLabel.Text = title
end

function Keymap:SetMobilePosition(actionName : string, position : UDim2)
  if not self.mobileButtons[actionName] then
    -- warn("No action with name " .. actionName .. " is bound.")
    return
  end

  self.mobileButtons[actionName].Position = position
end

function Keymap:GetMobileButton(actionName : string)
  return self.mobileButtons[actionName]
end

function Keymap:SetMobileButtonSize(actionName : string, size : UDim2)
  local button = self:GetMobileButton(actionName)
  button.Size = size
end

function Keymap:SetMobileButtonImage(actionName : string, image : string)
  local button = self:GetMobileButton(actionName)
  button.Image = image
end

function Keymap:CustomSetButton(actionName : string, callback: (any?) -> nil, ... : any)
  local button = self:GetMobileButton(actionName)

  callback(button, ...)
end

function Keymap:UnbindAll()
  for actionName, _ in pairs(self.actions) do
    ContextActionService:UnbindAction(actionName)
  end
  self.actions = {}
end

return Keymap