local player = game:GetService("Players").LocalPlayer
local Consts = require(game:GetService("ReplicatedStorage").Literals.Consts)
local CharactersLiterals = require(game:GetService("ReplicatedStorage").Literals.Characters)
local RunService = game:GetService("RunService")
local Controls = require(game:GetService("ReplicatedStorage").Services.Controls)
local Thumbstick = require(game:GetService("ReplicatedStorage").Modules.UI.Thumbstick)
local Warp = require(game:GetService("ReplicatedStorage").Packages.Warp)

local ActionE = Warp.Client("ActionE")
local ActionR = Warp.Client("OnActionR")
local ActionF = Warp.Client("ActionF")
--General functions
local Arrows = function(mainPlayer : Player, marksmenShootCirclePosition : Vector3, currentAttackSpeed : number)
  local character = mainPlayer.Character
  if not character then return end

  local rootPart = character:FindFirstChild("HumanoidRootPart")
  if not rootPart then return end

  local tweenService = game:GetService("TweenService")
  local tweenInfo = TweenInfo.new(.5, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
  local tweenInfoTwo = TweenInfo.new(CharactersLiterals.CharacterStats.DefaultRange.ActionEDelay / currentAttackSpeed, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)

  local originalArrow = game:GetService("ReplicatedStorage").Assets.Arrow

  local offset = -25
  for count = 0, 3, 1 do
    local arrow = originalArrow:Clone()
    arrow.Parent = character
    arrow.CFrame = rootPart.CFrame

    local finalDistonation = marksmenShootCirclePosition + Vector3.new(0, 200, 0) + Vector3.new(offset, 0, 0)
    arrow.CFrame = CFrame.new(arrow.Position, finalDistonation)
    offset += 25

    local tween = tweenService:Create(arrow, tweenInfo, {Position = finalDistonation})
    tween:Play()

    task.delay(.5, function()
      arrow:Destroy()
    end)
  end

  local arrowsMade = {}

  local reachDistance = CharactersLiterals.CharacterStats.DefaultRange.ActionEReachDistance * Consts.MeterToStudsMultiplier
  for count = 0, 10, 1 do
    local arrow = originalArrow:Clone()
    arrow.Size = arrow.Size * 10
    arrow.Parent = character
    arrow.Position = marksmenShootCirclePosition + Vector3.new(0, 200, 0)
    table.insert(arrowsMade, arrow)

    local finalDistonation = marksmenShootCirclePosition + Vector3.new(math.random(-reachDistance/2, reachDistance/2), 0, math.random(-reachDistance/2, reachDistance/2))
    arrow.CFrame = CFrame.new(arrow.Position, finalDistonation)

    local tween = tweenService:Create(arrow, tweenInfoTwo, {Position = finalDistonation})
    tween:Play()
  end

  task.delay(1, function()
    for _, arrow in next, arrowsMade do
      arrow:Destroy()
    end
  end)
end

local Arrow = function(playerRootPart, enemyRootPart, currentStats)
      if not playerRootPart or not enemyRootPart then
        return
      end

      local arrow = game:GetService("ReplicatedStorage").Assets.Arrow:Clone()
      arrow.Anchored = false
      arrow.Parent = workspace
      arrow.CFrame = CFrame.new(playerRootPart.Position, enemyRootPart.Position) * CFrame.new(0, 0, -2)

      local arrowLinearVelocity = arrow:FindFirstChildOfClass("LinearVelocity")
      arrowLinearVelocity.VectorVelocity = (enemyRootPart.Position - playerRootPart.Position).Unit * currentStats.DefaultAttackArrowSpeed
      arrowLinearVelocity.Enabled = true

      local connection
      connection = game:GetService('RunService').Stepped:Connect(function()
      if not arrow or not arrow:IsDescendantOf(workspace) then
        -- print('disc clienht')
        connection:Disconnect()
        return
      end

      local raycastResult = workspace:Raycast(arrow.Position, (enemyRootPart.Position - arrow.Position).Unit * 3.5)
      if raycastResult and raycastResult.Instance and raycastResult.Instance:IsDescendantOf(enemyRootPart.Parent) then
        -- Deal damage to the enemy character
        -- PlaySound:Fires(true, currentStats.Sounds[`{currentCharacter}LandedPunch`], {
        --   Parent = playerRootPart,
        -- })
        print('disc clienht 2')
        arrow:Destroy() -- Destroy the arrow after hitting the target
        connection:Disconnect() -- Disconnect the connection to prevent memory leaks
      end
    end)
end

local pointingArrow = function(dashDistance, callback : () -> nil)
  -- local dashDistance = CharactersLiterals.CharacterStats.Default.DashDistance
  dashDistance = dashDistance * Consts.MeterToStudsMultiplier

  local character = player.Character
  if not character then return end

  local rootPart = character:FindFirstChild("HumanoidRootPart")
  if not rootPart then return end

  local visualPart = Instance.new("Part", character)
  visualPart.Size = Vector3.new(1, 1, 1)
  visualPart.Anchored = true
  visualPart.CanCollide = false
  visualPart.CanQuery = false
  visualPart.CanTouch = false
  visualPart.Transparency = 1
  visualPart.Name = "DashVisual"

  local targetPart = Instance.new("Part", visualPart)
  targetPart.Size = Vector3.new(1, 1, 1)
  targetPart.Anchored = true
  targetPart.Transparency = .5
  targetPart.CanCollide = false
  targetPart.CanQuery = false
  targetPart.CanTouch = false
  targetPart.Name = "DashTarget"

  local arrowPart = Instance.new("Part", visualPart)
  arrowPart.Size = Vector3.new(1, 1, dashDistance)
  arrowPart.Anchored = false
  arrowPart.Transparency = 1
  arrowPart.CanCollide = false
  arrowPart.CanQuery = false
  arrowPart.CanTouch = false
  arrowPart.CastShadow = false
  arrowPart.Massless = true
  arrowPart.Name = "DashArrow"

  local weld = Instance.new("Weld", visualPart)
  weld.Part0 = visualPart
  weld.Part1 = arrowPart
  weld.C1 = CFrame.new(0, 2 , 0)
-- 
  local raycastParams = RaycastParams.new()
  raycastParams.FilterType = Enum.RaycastFilterType.Exclude
  raycastParams.FilterDescendantsInstances = {character}

  local attachmentO = Instance.new("Attachment", arrowPart)
  attachmentO.CFrame = CFrame.new(attachmentO.Position) * CFrame.Angles(0, 0, math.rad(90))
  attachmentO.Visible = true
  attachmentO.Position = Vector3.new(0, 0, -dashDistance/2)

  local attachmentT = Instance.new("Attachment", arrowPart)
  attachmentT.CFrame = CFrame.new(attachmentT.Position) * CFrame.Angles(0, 0, math.rad(90))
  attachmentT.Visible = true

  local dashVisual = game:GetService("ReplicatedStorage").Assets.DashVisual
  local beamO = dashVisual:FindFirstChild("Beam"):Clone()
  local beomT = dashVisual:FindFirstChild("BeamDownwards Arrows"):Clone()

  beamO.Parent = arrowPart
  beamO.Attachment0 = attachmentO
  beamO.Attachment1 = attachmentT
  
  beomT.Parent = arrowPart
  beomT.Attachment0 = attachmentT
  beomT.Attachment1 = attachmentO

  beamO.Width0 = 15
  beamO.Width1 = 2

  beomT.Width0 = 2
  beomT.Width1 = 10

  local emittingCircle = game:GetService("ReplicatedStorage").Assets:FindFirstChild("EmmitingCircle")
  if not emittingCircle then warn("EmittingCircle not found") return end

  emittingCircle = emittingCircle:Clone()
  emittingCircle.Parent = visualPart

  local weld = Instance.new("Weld", visualPart)
  weld.Part0 = rootPart
  weld.Part1 = emittingCircle
  weld.C1 = CFrame.new(0, 2 , 0)

  local emitterAttachment = emittingCircle:FindFirstChildOfClass("Attachment")
  if not emitterAttachment then warn("Emitter attachment not found") return end

  local ringEmitter : ParticleEmitter = emitterAttachment:FindFirstChild("Ring")
  if not ringEmitter then warn("Ring emitter not found") return end

  local blurEmitter = emitterAttachment:FindFirstChild("Blur")
  if not blurEmitter then warn("Blur emitter not found") return end

  blurEmitter:Emit(1)
  ringEmitter:Emit(1)

  ringEmitter.Size = NumberSequence.new(dashDistance)
  blurEmitter.Size = NumberSequence.new(dashDistance * 2)

  local camera = workspace.CurrentCamera


  local connection
  local onMobile = Controls:GetIsOnMobile()
  if onMobile then
    Thumbstick.enableThumbstick() 
    Thumbstick.onInputBegan({UserInputType = Enum.UserInputType.Touch, UserInputState = Enum.UserInputState.Begin}, true)

    Thumbstick.Released:Once(function()
      connection:Disconnect()
      Thumbstick.disableThumbstick()  
      callback()
    end)
  end

  connection = game:GetService('RunService').Stepped:Connect(function()
    if visualPart == nil or not visualPart:IsDescendantOf(character) then
        connection:Disconnect()
        return
    end

    local direction
    if onMobile then
      -- Use thumbstick input when available on mobile
      local tv = Thumbstick.ThumbstickInput
      tv = Vector2.new(tv.X, -tv.Y)
      if tv.Magnitude > 0.05 then
        local cameraCFrame = camera.CFrame
        local cameraRight = Vector3.new(cameraCFrame.RightVector.X, 0, cameraCFrame.RightVector.Z).Unit
        local cameraForward = Vector3.new(-cameraCFrame.LookVector.X, 0, -cameraCFrame.LookVector.Z).Unit
        local moveDirection = (cameraRight * tv.X + cameraForward * tv.Y)
        direction = moveDirection.Unit * dashDistance
      -- else
      --   -- Fallback to camera forward
      --   local cameraLookVector = camera.CFrame.LookVector
      --   cameraLookVector = Vector3.new(cameraLookVector.X, 0, cameraLookVector.Z).Unit
      --   direction = cameraLookVector * dashDistance
      end
    else
      -- Use mouse position on desktop
      local userInputService = game:GetService("UserInputService")
      local mousePos = userInputService:GetMouseLocation()
      local unitRay = camera:ViewportPointToRay(mousePos.X, mousePos.Y)
      local mouseResult = workspace:Raycast(unitRay.Origin, unitRay.Direction * 1000, raycastParams)
      if mouseResult then
        local flatDirection = Vector3.new(mouseResult.Position.X - rootPart.Position.X, 0, mouseResult.Position.Z - rootPart.Position.Z)
        if flatDirection.Magnitude > dashDistance then
          flatDirection = flatDirection.Unit * dashDistance
        elseif flatDirection.Magnitude < dashDistance then 
          flatDirection = flatDirection.Unit * dashDistance
        end
        direction = flatDirection
      end
    end

    local raycast = workspace:Raycast(rootPart.Position, direction, raycastParams)
    local targetPos
    if raycast then
        targetPos = raycast.Position
    else
        targetPos = rootPart.Position + direction
    end

    local midPos = rootPart.Position + (targetPos - rootPart.Position) / 2
    visualPart.CFrame = CFrame.new(midPos, targetPos)
    arrowPart.Size = Vector3.new(1, 1, (rootPart.Position - targetPos).Magnitude)

    targetPart.Position = targetPos

    ringEmitter.Size = NumberSequence.new((rootPart.Position - targetPos).Magnitude)
    blurEmitter.Size = NumberSequence.new((rootPart.Position - targetPos).Magnitude * 2)

    attachmentT.Position = Vector3.new(0, 0, arrowPart.Size.Z/2)
    attachmentO.Position = Vector3.new(0, 0, -arrowPart.Size.Z/2)
  end)
end

return {
  ["Default"] = {
    DashVisual = function()
      pointingArrow(CharactersLiterals.CharacterStats.Default.DashDistance, function()
        ActionR:Fire(true, Enum.UserInputState.End)
      end)
      -- connection = game:GetService('RunService').Stepped:Connect(function()
      --   if visualPart == nil or not visualPart:IsDescendantOf(character) then
      --     connection:Disconnect()
      --     return
      --   end

      --   local cameraLookVector = camera.CFrame.LookVector
      --   cameraLookVector = Vector3.new(cameraLookVector.X, 0, cameraLookVector.Z).Unit

      --   local direction = cameraLookVector * dashDistance
      --   -- local lookCF = CFrame.new(Vector3.zero, cameraLookVector)
      --   -- weld.C1 = lookCF * CFrame.new(0, 0, dashDistance/2)

      --   local raycast = workspace:Raycast(rootPart.Position, direction, raycastParams)
      --   if raycast then
      --     visualPart.CFrame = CFrame.new(raycast.Position)
      --   else
      --     visualPart.CFrame = CFrame.new(rootPart.Position + direction)
      --   end
      -- end)
    end,

    Dash = function()
      local character = player.Character
      if not character then return end

      local rootPart = character:FindFirstChild("HumanoidRootPart")
      if not rootPart then return end

      local humnaoid = character:FindFirstChildOfClass("Humanoid")
      if not humnaoid or humnaoid.Health <= 0 then return end

      local visualPart = character:FindFirstChild("DashVisual")
      if visualPart == nil then return end

      local camera = workspace.CurrentCamera

      local dashDistance = CharactersLiterals.CharacterStats.Default.DashDistance
      dashDistance = dashDistance * Consts.MeterToStudsMultiplier

      local raycastParams = RaycastParams.new()
      raycastParams.FilterType = Enum.RaycastFilterType.Exclude
      raycastParams.FilterDescendantsInstances = {character}

      local targetPart = visualPart:FindFirstChild("DashTarget")
      if not targetPart then warn("DashTarget not found") return end

      local targetDirection = (targetPart.Position - rootPart.Position).Unit

      local direction = targetDirection * dashDistance

      local raycast = workspace:Raycast(rootPart.Position, direction, raycastParams)
      local targetPos
      if raycast then
          targetPos = raycast.Position
      else
          targetPos = rootPart.Position + direction
      end

      rootPart.CFrame = CFrame.new(targetPos, targetPos + targetDirection)

      visualPart:Destroy()
    end,

    SlashReady = function()
      pointingArrow(CharactersLiterals.CharacterStats.Default.ActionFReachDistance, function()
        ActionF:Fire(true, Enum.UserInputState.End)
      end)
    end,

    SlashUsed = function()
      local character = player.Character
      if not character then return end

      local rootPart = character:FindFirstChild("HumanoidRootPart")
      if not rootPart then return end

      local humnaoid = character:FindFirstChildOfClass("Humanoid")
      if not humnaoid or humnaoid.Health <= 0 then return end

      local visualPart = character:FindFirstChild("DashVisual")
      if visualPart == nil then return end

      local targetPart = visualPart:FindFirstChild("DashTarget")
      if not targetPart then warn("DashTarget not found") return end

      local dashDistance = CharactersLiterals.CharacterStats.Default.ActionFReachDistance
      dashDistance = dashDistance * Consts.MeterToStudsMultiplier

      local targetDirection = (targetPart.Position - rootPart.Position).Unit

      local raycastParams = RaycastParams.new()
      raycastParams.FilterType = Enum.RaycastFilterType.Exclude
      raycastParams.FilterDescendantsInstances = {character}

      local direction = targetDirection * dashDistance

      local raycast = workspace:Raycast(rootPart.Position, direction, raycastParams)
      local targetPos
      if raycast then
          targetPos = raycast.Position
      else
          targetPos = rootPart.Position + direction
      end

      -- local midPos = rootPart.Position + (targetPos - rootPart.Position) / 2

      local alignPosition = Instance.new("AlignPosition", rootPart)
      alignPosition.MaxForce = 100000
      alignPosition.Responsiveness = 100
      alignPosition.Attachment0 = rootPart:FindFirstChildOfClass("Attachment")
      alignPosition.Mode = Enum.PositionAlignmentMode.OneAttachment
      alignPosition.Position = targetPos
      alignPosition.Enabled = true

      local alignOrientation = Instance.new("AlignOrientation", rootPart)
      alignOrientation.MaxTorque = 100000
      alignOrientation.Responsiveness = 100000
      alignOrientation.Attachment0 = rootPart:FindFirstChildOfClass("Attachment")
      alignOrientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
      alignOrientation.CFrame = CFrame.new(rootPart.Position, targetPos)
      alignOrientation.Enabled = true

      task.delay(CharactersLiterals.CharacterStats.Default.ActionFAlignForcesDuration, function()
        alignPosition:Destroy()
        alignOrientation:Destroy()
      end)


      -- rootPart.CFrame = CFrame.new(targetPos, targetPos + cameraLookVector)

      visualPart:Destroy()
    end,

    Arrow = Arrow,

    Arrows = Arrows
  },

  ["DefaultRange"] = {
    Arrow = Arrow,

    Arrows = Arrows,

    MarksmenCircle = function(inputObj : InputObject)
      local character = player.Character
      if not character then return end

      local rootPart = character:FindFirstChild("HumanoidRootPart")
      if not rootPart then return end

      local camera = workspace.CurrentCamera

      local marksmenShootCircle = game:GetService("ReplicatedStorage").Assets.MarksmenShootCircle:Clone()
      marksmenShootCircle.Parent = character

      local userInputService = game:GetService("UserInputService")

      local maxDistance = CharactersLiterals.CharacterStats.DefaultRange.ReachDistance * Consts.MeterToStudsMultiplier

      local raycastParams = RaycastParams.new()
      raycastParams.FilterDescendantsInstances = {workspace.Baseplate}
      raycastParams.FilterType = Enum.RaycastFilterType.Include

      local attachment = marksmenShootCircle:FindFirstChildOfClass("Attachment")
      if not attachment then return end

      local particleEmitter = attachment:FindFirstChildOfClass("ParticleEmitter")
      if not particleEmitter then return end

      particleEmitter:Emit(5)
      
      local playerUI = player:FindFirstChildOfClass("PlayerGui")
      if not playerUI then return end

      local onMobile = Controls:GetIsOnMobile()
      if onMobile then 
        Thumbstick.enableThumbstick() 
        Thumbstick.onInputBegan(inputObj, true)

        local skillButton : GuiButton = playerUI.InGamePhoneGui.SkillButton_2
        if not skillButton then warn("SkillButton_2 not found") return end

        -- print("Disabling skill button")
        skillButton.Active = false
        skillButton.Interactable = false
      end

      local connection

      if onMobile then 
        Thumbstick.Released:Once(function()
          connection:Disconnect()

          local skillButton : GuiButton = playerUI.InGamePhoneGui.SkillButton_2
          if not skillButton then warn("SkillButton_2 not found") return end

          -- print("Enabling skill button")
          skillButton.Active = true
          skillButton.Interactable = true

          Thumbstick.disableThumbstick()
          ActionE:Fire(true)
        end)
      end

      connection = RunService.RenderStepped:Connect(function()
        if marksmenShootCircle.Parent ~= character then 
          if onMobile then Thumbstick.disableThumbstick() end
          connection:Disconnect() 
          return 
        end

        if onMobile then 
          -- Mobile: Use thumbstick to directly control circle position relative to player
          local thumbstickInput = Thumbstick.ThumbstickInput

          thumbstickInput = Vector2.new(thumbstickInput.X, -thumbstickInput.Y) -- Invert Y for screen to world space
          
          if thumbstickInput.Magnitude > 0.1 then -- Dead zone check
            -- Convert thumbstick input to world space direction
            local cameraCFrame = camera.CFrame
            
            -- Get camera's right and forward vectors (ignoring Y component for ground movement)
            local cameraRight = Vector3.new(cameraCFrame.RightVector.X, 0, cameraCFrame.RightVector.Z).Unit
            local cameraForward = Vector3.new(-cameraCFrame.LookVector.X, 0, -cameraCFrame.LookVector.Z).Unit
            
            -- Calculate movement direction based on thumbstick input
            local moveDirection = (cameraRight * thumbstickInput.X + cameraForward * thumbstickInput.Y)
            
            -- Calculate target position based on thumbstick magnitude and direction
            local targetDistance = thumbstickInput.Magnitude * maxDistance
            local targetOffset = moveDirection * targetDistance
            local targetPosition = rootPart.Position + targetOffset
            
            -- Raycast down to find ground position
            local downResult = workspace:Raycast(targetPosition + Vector3.new(0, 100, 0), Vector3.new(0, -200, 0), raycastParams)
            
            if downResult then
              marksmenShootCircle.Position = downResult.Position
            else
              -- Fallback to a position slightly above ground level
              marksmenShootCircle.Position = targetPosition + Vector3.new(0, 1, 0)
            end
          else
            -- No thumbstick input, keep circle at player position
            local downResult = workspace:Raycast(rootPart.Position + Vector3.new(0, 10, 0), Vector3.new(0, -100, 0), raycastParams)
            if downResult then
              marksmenShootCircle.Position = downResult.Position
            end
          end
        else
          -- Desktop: Use mouse cursor for targeting
          local mousePos = userInputService:GetMouseLocation()
          
          -- Ignore input when the player is interacting with a GUI
          local focused = userInputService:GetFocusedTextBox()
          if focused then
            return
          end
          local guiObjects = playerUI:GetGuiObjectsAtPosition(mousePos.X, mousePos.Y)

          for _, guiObject in next, guiObjects do
            if guiObject.Name == 'TouchControlFrame' then continue end
            return
          end

          local unitRay = camera:ViewportPointToRay(mousePos.X, mousePos.Y)
          local result = workspace:Raycast(unitRay.Origin, unitRay.Direction * 1000, raycastParams)

          if result then
            result = workspace:Raycast(result.Position + Vector3.new(0, 10, 0), Vector3.new(0, -100000, 0), raycastParams)

            if not result then
              print("no result")
              return
            end

            local offset = result.Position - rootPart.Position

            if offset.Magnitude > maxDistance then
              offset = offset.Unit * maxDistance
            end

            local finalPosition = rootPart.Position + Vector3.new(offset.X, 0, offset.Z)
            finalPosition = Vector3.new(finalPosition.X, result.Position.Y, finalPosition.Z)

            marksmenShootCircle.Position = finalPosition
          else
            local downResult = workspace:Raycast(rootPart.Position + unitRay.Direction * maxDistance, Vector3.new(0, -100000, 0), raycastParams)

            if not downResult then
              print("no down result")
              return
            end

            marksmenShootCircle.Position = downResult.Position
          end
        end
      end)
    end,

    MarksmenCircleCancel = function()
      local character = player.Character
      if not character then return end

      local marksmenShootCircle = character:FindFirstChild("MarksmenShootCircle")
      if not marksmenShootCircle then return end

      if Controls:GetIsOnMobile() then
        Thumbstick.disableThumbstick()
      end

      marksmenShootCircle.Parent = workspace
      task.wait(CharactersLiterals.CharacterStats.DefaultRange.ActionEDelay)

      marksmenShootCircle:Destroy()
    end,

    GetCursorRay = function()
      local camera = workspace.CurrentCamera

      if Controls:GetGamepadConnected() or Controls:GetIsOnMobile() then
        local character = player.Character
        if not character then return end

        local marksmenCircle = character:FindFirstChild("MarksmenShootCircle")
        if not marksmenCircle then return end

        return {
          Origin = camera.CFrame.Position,
          Direction = (marksmenCircle.Position - camera.CFrame.Position).Unit * 1000
        }
      end

      local userInputService = game:GetService("UserInputService")

      local mousePos = userInputService:GetMouseLocation()
      local unitRay = camera:ViewportPointToRay(mousePos.X, mousePos.Y)
      return unitRay
    end
  },
}