local UI = {}
UI.__index = UI

local uiObjects = {}

function UI.init()
  UI.CurrentOpened = {}

  for _, module in pairs(script:GetChildren()) do
    if module:IsA("ModuleScript") == false then
      warn("Non-module script found in UI folder: " .. module.Name)
      continue
    end

    local success, uiModule = pcall(require, module)
    if not success then
      warn("Failed to require module " .. module.Name .. ": " .. tostring(uiModule))
      continue
    end

    local uiObject = uiModule.init()
    uiObjects[uiObject.ScreenGui] = uiObject
  end

  print("UI.init: Initialized UI modules: ", uiObjects)
end

function UI.getInstance(screenGuiName : string)
  local player = game.Players.LocalPlayer
  if not player then
    warn("UI.getInstance: LocalPlayer not found")
    return nil
  end

  local playerGui = player.PlayerGui
  if not playerGui then
    warn("UI.getInstance: PlayerGui not found")
    return nil
  end

  local screenGui = playerGui:WaitForChild(screenGuiName)
  if not screenGui or not screenGui:IsA("ScreenGui") then
    warn("UI.getInstance: ScreenGui " .. screenGuiName .. " not found in PlayerGui")
    return nil
  end

  return screenGui
end

function UI.getObject(screenGui : ScreenGui)
  if not screenGui or typeof(screenGui) ~= "Instance" or not screenGui:IsA("ScreenGui") then
    warn("UI.get: Invalid ScreenGui provided")
    return nil
  end

  -- print("UI.get: Getting UI object for ScreenGui ", screenGui)
  -- print("UI.get: UI objects table: ", uiObjects)
  return uiObjects[screenGui]
end

function UI.hasOpened(screenGui : ScreenGui)
  if not screenGui or typeof(screenGui) ~= "Instance" or not screenGui:IsA("ScreenGui") then
    warn("UI.hasOpened: Invalid ScreenGui provided")
    return false
  end

  return UI.CurrentOpened[screenGui] and true or false
end

function UI.openClose(screenGuiName : string)
  local screenGui = UI.getInstance(screenGuiName)
  if not screenGui then
    warn("UI.openClose: ScreenGui instance not found for the provided name: " .. screenGuiName)
    return
  end

  local uiObject = UI.getObject(screenGui)
  if not uiObject then
    warn("UI.openClose: UI object not found for the provided ScreenGui")
    return
  end

  local isOpen = UI.CurrentOpened[screenGui] or false

  if isOpen then 
    screenGui.Enabled = false
    UI.CurrentOpened[screenGui] = nil
    uiObject.close()

    return true
  end

  local closeToOpen = uiObject.CloseToOpen or {}
  for _,  screenGuiName in next, closeToOpen do
    local targetScreenGui = UI.getInstance(screenGuiName)

    local toCloseUi = UI.getObject(targetScreenGui)
    if not toCloseUi then
      warn("UI.openClose: UI object not found for the ScreenGui to close: " .. screenGuiName)
      continue
    end

    -- print(toCloseUi)
    toCloseUi.ScreenGui.Enabled = false
    UI.CurrentOpened[toCloseUi.ScreenGui] = nil
  end

  uiObject.open()
  screenGui.Enabled = true
  UI.CurrentOpened[screenGui] = true
end

return UI