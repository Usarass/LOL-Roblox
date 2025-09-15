local player = game:GetService("Players").LocalPlayer
local Consts = require(game:GetService("ReplicatedStorage").Literals.Consts)
local CharactersLiterals = require(game:GetService("ReplicatedStorage").Literals.Characters)
local RunService = game:GetService("RunService")

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

return {
  ["Default"] = {
    DashVisual = function()
      local dashDistance = CharactersLiterals.CharacterStats.Default.DashDistance
      dashDistance = dashDistance * Consts.MeterToStudsMultiplier

      local camera = workspace.CurrentCamera
      if not camera then return end

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

      local connection
      connection = game:GetService('RunService').Stepped:Connect(function()
        if visualPart == nil or not visualPart:IsDescendantOf(character) then
            connection:Disconnect()
            return
        end

        local cameraLookVector = camera.CFrame.LookVector
        cameraLookVector = Vector3.new(cameraLookVector.X, 0, cameraLookVector.Z).Unit

        local direction = cameraLookVector * dashDistance

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

        attachmentT.Position = Vector3.new(0, 0, arrowPart.Size.Z/2)
        attachmentO.Position = Vector3.new(0, 0, -arrowPart.Size.Z/2)
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

      local cameraLookVector = camera.CFrame.LookVector
      cameraLookVector = Vector3.new(cameraLookVector.X, 0, cameraLookVector.Z).Unit

      local raycastParams = RaycastParams.new()
      raycastParams.FilterType = Enum.RaycastFilterType.Exclude
      raycastParams.FilterDescendantsInstances = {character}

      local cameraLookVector = camera.CFrame.LookVector
      cameraLookVector = Vector3.new(cameraLookVector.X, 0, cameraLookVector.Z).Unit

      local direction = cameraLookVector * dashDistance

      local raycast = workspace:Raycast(rootPart.Position, direction, raycastParams)
      local targetPos
      if raycast then
          targetPos = raycast.Position
      else
          targetPos = rootPart.Position + direction
      end

      rootPart.CFrame = CFrame.new(targetPos, targetPos + cameraLookVector)

      visualPart:Destroy()
    end,

    Arrows = Arrows
  },

  ["DefaultRange"] = {
    Arrow = Arrow,

    Arrows = Arrows,

    MarksmenCircle = function()
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

      local connection
      connection = RunService.RenderStepped:Connect(function()
        if marksmenShootCircle.Parent ~= character then connection:Disconnect() return end
        local mousePos = userInputService:GetMouseLocation()
        local unitRay = camera:ViewportPointToRay(mousePos.X, mousePos.Y)

        local result = workspace:Raycast(unitRay.Origin, unitRay.Direction * 500, raycastParams)

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
          -- local finalPosition = rootPart.Position + offset
          -- MarksmenShootCircle.CFrame = CFrame.new(finalPosition)
        else
          local downResult = workspace:Raycast(rootPart.Position + unitRay.Direction * maxDistance, Vector3.new(0, -100000, 0), raycastParams)

          if not downResult then
            print("no down result")
            return
          end

          marksmenShootCircle.Position = downResult.Position
        end
      end)
    end,

    MarksmenCircleCancel = function()
      local character = player.Character
      if not character then return end

      local marksmenShootCircle = character:FindFirstChild("MarksmenShootCircle")
      if not marksmenShootCircle then return end

      marksmenShootCircle.Parent = workspace
      task.wait(CharactersLiterals.CharacterStats.DefaultRange.ActionEDelay)

      marksmenShootCircle:Destroy()
    end,

    GetCursorRay = function()
      local userInputService = game:GetService("UserInputService")
      local camera = workspace.CurrentCamera

      local mousePos = userInputService:GetMouseLocation()
      local unitRay = camera:ViewportPointToRay(mousePos.X, mousePos.Y)
      return unitRay
    end
  },
}