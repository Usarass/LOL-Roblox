local Controls = require(game:GetService("ReplicatedStorage").Services.Controls)
local Signal = require(game:GetService("ReplicatedStorage").Packages.GoodSignal)

-- Thumbstick Configuration
local CONFIG = {
    -- Visual settings
    Size = UDim2.new(0.2, 0, 0.2, 0), -- Thumbstick frame size
    Position = UDim2.new(0.5, 0, 0.5, 0), -- Position on screen
    DynamicReposition = true, -- Whether the whole thumbstick moves to the touch position
    ClampPadding = 40, -- Pixel padding from screen edges when repositioning
    
    -- Behavior settings
    KnobRangeMultiplier = 1.2, -- How far the knob can travel (1.2 = 120% of frame size)
    TouchAreaMultiplier = 1.5, -- Touch detection area (1.5 = 150% of frame size)
    DeadZone = 0.1, -- Minimum input threshold
    
    -- Visual feedback
    OuterRingColor = Color3.fromRGB(255, 255, 255),
    InnerKnobColor = Color3.fromRGB(255, 255, 255),
    OuterRingTransparency = 0.8,
    InnerKnobTransparency = 0.3,
    ActiveOuterTransparency = 0.6,
    ActiveInnerTransparency = 0.1,
}

local Thumbstick = {}
Thumbstick.__index = Thumbstick

function Thumbstick.init()
    local self = Thumbstick

    local user = game.Players.LocalPlayer
    if not user then
        warn("Thumbstick.init: LocalPlayer not found")
        return
    end

    local screenGui = user.PlayerGui:WaitForChild('InGamePhoneGui', 10)
    if not screenGui then
        warn("Thumbstick.init: InGamePhoneGui not found in PlayerGui")
        return
    end

    self.CloseToOpen = {}

    self.User = user
    self.ScreenGui = screenGui
    
    -- Thumbstick state
    self.ThumbstickEnabled = false
    self.ThumbstickUI = nil
    self.ThumbstickConnections = {}
    self.ThumbstickInput = Vector2.new(0, 0)
    self.IsThumbstickActive = false
  self.LastTouchInput = nil -- Holds the most recent touch (or mouse) InputObject that activated the thumbstick
    self._GlobalTouchTrackingInitialized = false
    self._GlobalTouchConnections = {}
    self.Released = Signal.new() -- Fires when user stops pressing (input ended after active drag)

  self.initThumbstick()
  self.initGlobalTouchTracking() -- start tracking touches globally (even when not activating thumbstick)

    return self
end

-- Configure thumbstick settings
function Thumbstick.configure(settings)
    for key, value in pairs(settings) do
        if CONFIG[key] ~= nil then
            CONFIG[key] = value
        else
            warn("Thumbstick.configure: Unknown setting '" .. tostring(key) .. "'")
        end
    end
    
    -- Recreate UI if it exists to apply new settings
    if Thumbstick.ThumbstickUI then
        local wasEnabled = Thumbstick.ThumbstickEnabled
        Thumbstick.createThumbstickUI()
        Thumbstick.setThumbstickEnabled(wasEnabled)
    end
end

function Thumbstick.initThumbstick()
  local self = Thumbstick
  
  -- Create thumbstick UI but keep it disabled by default
  self.createThumbstickUI()
  self.setThumbstickEnabled(false)

  -- self.enableThumbstick()
end

function Thumbstick.createThumbstickUI()
  local self = Thumbstick
  
  if self.ThumbstickUI then
    self.ThumbstickUI:Destroy()
  end
  
  -- Create main thumbstick container
  local thumbstickFrame = Instance.new("Frame")
  thumbstickFrame.Name = "ThumbstickFrame"
  thumbstickFrame.Size = CONFIG.Size
  thumbstickFrame.Position = CONFIG.Position
  thumbstickFrame.AnchorPoint = Vector2.new(0.5, 0.5)
  thumbstickFrame.BackgroundTransparency = 1
  thumbstickFrame.Parent = self.ScreenGui
  
  -- Add UIAspectRatioConstraint to maintain perfect circle on all screen sizes
  local aspectRatio = Instance.new("UIAspectRatioConstraint")
  aspectRatio.AspectRatio = 1 -- 1:1 ratio for perfect circle
  aspectRatio.Parent = thumbstickFrame
  
  -- Outer ring (background)
  local outerRing = Instance.new("Frame")
  outerRing.Name = "OuterRing"
  outerRing.Size = UDim2.new(1, 0, 1, 0)
  outerRing.Position = UDim2.new(0.5, 0, 0.5, 0)
  outerRing.AnchorPoint = Vector2.new(0.5, 0.5)
  outerRing.BackgroundColor3 = CONFIG.OuterRingColor
  outerRing.BackgroundTransparency = CONFIG.OuterRingTransparency
  outerRing.Parent = thumbstickFrame
  
  local outerCorner = Instance.new("UICorner")
  outerCorner.CornerRadius = UDim.new(1, 0)
  outerCorner.Parent = outerRing
  
  -- Inner knob (draggable part)
  local innerKnob = Instance.new("Frame")
  innerKnob.Name = "InnerKnob"
  innerKnob.Size = UDim2.new(0.4, 0, 0.4, 0)
  innerKnob.Position = UDim2.new(0.5, 0, 0.5, 0)
  innerKnob.AnchorPoint = Vector2.new(0.5, 0.5)
  innerKnob.BackgroundColor3 = CONFIG.InnerKnobColor
  innerKnob.BackgroundTransparency = CONFIG.InnerKnobTransparency
  innerKnob.Parent = thumbstickFrame

  print(innerKnob)
  
  local innerCorner = Instance.new("UICorner")
  innerCorner.CornerRadius = UDim.new(1, 0)
  innerCorner.Parent = innerKnob
  
  self.ThumbstickUI = thumbstickFrame
  self.OuterRing = outerRing
  self.InnerKnob = innerKnob
end

function Thumbstick.setThumbstickEnabled(enabled: boolean)
  local self = Thumbstick
  
  self.ThumbstickEnabled = enabled
  
  if not self.ThumbstickUI then
    self.createThumbstickUI()
  end
  
  self.ThumbstickUI.Visible = enabled
  
  -- Disconnect existing connections
  for _, connection in pairs(self.ThumbstickConnections) do
    connection:Disconnect()
  end
  table.clear(self.ThumbstickConnections)
  
  if enabled then
    self.connectThumbstickInput()
  else
    if self.IsThumbstickActive then
      -- Consider this a release as well
      self.Released:Fire(self.LastTouchInput, self.ThumbstickInput)
    end
    self.ThumbstickInput = Vector2.new(0, 0)
    self.IsThumbstickActive = false
    self.LastTouchInput = nil
  end
end

-- Global tracking of any touch/mouse down so LastTouchInput is always updated, even if thumbstick isn't engaged
function Thumbstick.initGlobalTouchTracking()
  local self = Thumbstick
  if self._GlobalTouchTrackingInitialized then return end
  self._GlobalTouchTrackingInitialized = true
  local UserInputService = game:GetService("UserInputService")

  local beganConn = UserInputService.InputBegan:Connect(function(input: InputObject)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
      self.LastTouchInput = input
    end
  end)

  local changedConn = UserInputService.InputChanged:Connect(function(input: InputObject)
    if input.UserInputType == Enum.UserInputType.Touch then
      -- Update reference so position remains fresh (InputObject instance updates position, but we reassign for clarity)
      self.LastTouchInput = input
    end
  end)

  table.insert(self._GlobalTouchConnections, beganConn)
  table.insert(self._GlobalTouchConnections, changedConn)
end

function Thumbstick.onInputBegan(input)
  
end

function Thumbstick.connectThumbstickInput()
  local self = Thumbstick
  local UserInputService = game:GetService("UserInputService")
  local RunService = game:GetService("RunService")
  
  local thumbstickFrame = self.ThumbstickUI
  local innerKnob = self.InnerKnob
  local outerRing = self.OuterRing
  
  local dragging = false
  local startPos = Vector2.new(0, 0)
  local knobStartPos = UDim2.new(0.5, 0, 0.5, 0)
  
  -- Touch/Mouse input handling
  Thumbstick.onInputBegan = function(input, doReposition)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
      local frameSize = thumbstickFrame.AbsoluteSize

      local posX = 0
      local posY = 0

      if input.Position then
        posX = input.Position.X
        posY = input.Position.Y
      else -- Fallback to last known touch input if available
        local lastInput = self.LastTouchInput
        if lastInput then
          posX = lastInput.Position.X
          posY = lastInput.Position.Y
        else
          return -- No valid input position available
        end
      end

      local inputPos = Vector2.new(posX, posY)

      -- Optionally move the entire thumbstick to this touch position first (dynamic / floating joystick)
      if CONFIG.DynamicReposition and doReposition and thumbstickFrame.Parent and thumbstickFrame.Parent:IsA("ScreenGui") then
        local parent = thumbstickFrame.Parent
        local parentAbsSize = parent.AbsoluteSize
        local clampedX = math.clamp(inputPos.X, CONFIG.ClampPadding, parentAbsSize.X - CONFIG.ClampPadding)
        local clampedY = math.clamp(inputPos.Y, CONFIG.ClampPadding, parentAbsSize.Y - CONFIG.ClampPadding)
        local scaleX = clampedX / parentAbsSize.X
        local scaleY = clampedY / parentAbsSize.Y
        thumbstickFrame.Position = UDim2.new(scaleX, 0, scaleY, 0)
      end

      -- Recalculate after potential reposition
      local framePos = thumbstickFrame.AbsolutePosition
      local center = framePos + frameSize * 0.5
      local distance = (inputPos - center).Magnitude

      -- Accept input if within extended area OR if we just repositioned (distance may now be small)
      if distance <= frameSize.X * CONFIG.TouchAreaMultiplier * 0.5 then
        dragging = true
        startPos = inputPos
        knobStartPos = innerKnob.Position
        self.IsThumbstickActive = true
        -- self.LastTouchInput = input -- store the InputObject we are tracking
        
        -- Immediately move knob to touch position
        local offset = inputPos - center
        local maxDistance = frameSize.X * CONFIG.KnobRangeMultiplier * 0.5
        
        -- Clamp to circle with extended range
        if offset.Magnitude > maxDistance then
          offset = offset.Unit * maxDistance
        end
        
        -- Update knob position immediately
        innerKnob.Position = UDim2.new(0.5, offset.X, 0.5, offset.Y)
        
        -- Update input vector immediately
        self.ThumbstickInput = Vector2.new(
          offset.X / maxDistance,
          -offset.Y / maxDistance -- Invert Y for typical movement controls
        )
        
        -- Visual feedback using config values
        outerRing.BackgroundTransparency = CONFIG.ActiveOuterTransparency
        innerKnob.BackgroundTransparency = CONFIG.ActiveInnerTransparency
      end
    end
  end

  local function onInputChanged(input)
    if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
      local framePos = thumbstickFrame.AbsolutePosition
      local frameSize = thumbstickFrame.AbsoluteSize
      local center = framePos + frameSize * 0.5
      local inputPos = Vector2.new(input.Position.X, input.Position.Y)
      local offset = inputPos - center
      local maxDistance = frameSize.X * CONFIG.KnobRangeMultiplier * 0.5 -- Configurable knob range
      
      -- Clamp to circle with extended range
      if offset.Magnitude > maxDistance then
        offset = offset.Unit * maxDistance
      end
      
      -- Update knob position
      innerKnob.Position = UDim2.new(0.5, offset.X, 0.5, offset.Y)
      
      -- Update input vector (normalized -1 to 1)
      self.ThumbstickInput = Vector2.new(
        offset.X / maxDistance,
        -offset.Y / maxDistance -- Invert Y for typical movement controls
      )
    end
  end
  
  local function onInputEnded(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
      dragging = false
      local wasActive = self.IsThumbstickActive
      self.IsThumbstickActive = false
      -- Clear stored touch if this was the active one
      if self.LastTouchInput == input then
        self.LastTouchInput = nil
      end
      
      -- Reset knob position
      innerKnob.Position = UDim2.new(0.5, 0, 0.5, 0)
      local previousInput = self.ThumbstickInput
      self.ThumbstickInput = Vector2.new(0, 0)
      
      -- Reset visual feedback using config values
      outerRing.BackgroundTransparency = CONFIG.OuterRingTransparency
      innerKnob.BackgroundTransparency = CONFIG.InnerKnobTransparency

      if wasActive then
        -- Fire release signal with the last input object that ended it and the final vector before reset
        self.Released:Fire(input, previousInput)
      end
    end
  end
  
  -- Connect input events
  table.insert(self.ThumbstickConnections, UserInputService.InputBegan:Connect(Thumbstick.onInputBegan))
  table.insert(self.ThumbstickConnections, UserInputService.InputChanged:Connect(onInputChanged))
  table.insert(self.ThumbstickConnections, UserInputService.InputEnded:Connect(onInputEnded))
  
  -- Send thumbstick input to Controls service
  table.insert(self.ThumbstickConnections, RunService.RenderStepped:Connect(function()
    if self.ThumbstickEnabled and self.ThumbstickInput.Magnitude > CONFIG.DeadZone then
      -- Send movement input to Controls service
      local handleFunc = Controls:GetHandlerFunction("Movement")
      if handleFunc then
        handleFunc("Movement", Enum.UserInputState.Change, self.ThumbstickInput)
      end
    end
  end))
end

-- Public API methods
function Thumbstick.enableThumbstick()
  print("Enabling thumbstick")
  Thumbstick.setThumbstickEnabled(true)
end

function Thumbstick.disableThumbstick()
  Thumbstick.setThumbstickEnabled(false)
end

function Thumbstick.getThumbstickInput()
  return Thumbstick.ThumbstickInput, Thumbstick.IsThumbstickActive
end

-- Connect to release signal (fires with: inputObject, lastVectorBeforeReset)
function Thumbstick.onReleased(callback)
  return Thumbstick.Released:Connect(callback)
end

-- Returns the last (current active) touch InputObject that started the thumbstick drag, or nil
function Thumbstick.getLastTouchInput()
  return Thumbstick.LastTouchInput
end

-- Convenience methods for common configurations
function Thumbstick.setKnobRange(multiplier)
  Thumbstick.configure({KnobRangeMultiplier = multiplier})
end

function Thumbstick.setTouchArea(multiplier)
  Thumbstick.configure({TouchAreaMultiplier = multiplier})
end

function Thumbstick.setPosition(position)
  Thumbstick.configure({Position = position})
end

function Thumbstick.setSize(size)
  Thumbstick.configure({Size = size})
end

-- Enhanced position methods with presets
function Thumbstick.moveToBottomLeft(margin)
  margin = margin or 0.1 -- Default 10% margin from edges
  local position = UDim2.new(margin, 0, 1 - margin, 0)
  Thumbstick.setPosition(position)
end

function Thumbstick.moveToBottomRight(margin)
  margin = margin or 0.1
  local position = UDim2.new(1 - margin, 0, 1 - margin, 0)
  Thumbstick.setPosition(position)
end

function Thumbstick.moveToTopLeft(margin)
  margin = margin or 0.1
  local position = UDim2.new(margin, 0, margin, 0)
  Thumbstick.setPosition(position)
end

function Thumbstick.moveToTopRight(margin)
  margin = margin or 0.1
  local position = UDim2.new(1 - margin, 0, margin, 0)
  Thumbstick.setPosition(position)
end

function Thumbstick.moveToCenter()
  local position = UDim2.new(0.5, 0, 0.5, 0)
  Thumbstick.setPosition(position)
end

function Thumbstick.moveToCustomPosition(x, y, xOffset, yOffset)
  -- x, y in scale (0-1), xOffset, yOffset in pixels
  xOffset = xOffset or 0
  yOffset = yOffset or 0
  local position = UDim2.new(x, xOffset, y, yOffset)
  Thumbstick.setPosition(position)
end

function Thumbstick.setUDim2(position : UDim2)
  Thumbstick.setPosition(position)
end

function Thumbstick.open()

end

function Thumbstick.close()
    
end

return Thumbstick