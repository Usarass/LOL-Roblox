local animations = {
  Animations = {},
  AnimationsInstances = {},
  Preloaded = false,
}
animations.__index = animations

function animations:CreateTrack(animator : Animator, animationName : string, animationId : string, animationPriority : Enum.AnimationPriority?) : AnimationTrack
  if not animator then warn("No animator was provided") return end

  local animationInstance = self.AnimationsInstances[animationName]
  if not animationInstance then 
    animationInstance = Instance.new("Animation")
    animationInstance.Name = animationName
    animationInstance.AnimationId = animationId

    self.AnimationsInstances[animationName] = animationInstance
  end 

  -- LoaderService.PreloadAssets({animationInstance})

  local animationTrack = animator:LoadAnimation(animationInstance)
  if animationPriority then animationTrack.Priority = animationPriority end
  self.Animations[animationName] = animationTrack

  return self.Animations[animationName] 
end

function animations:CreateEsolatedTrack(animator : Animator, animationName : string, animationId : string)
  if not animator then warn("No animator was provided") return end

  local animationInstance = self.AnimationsInstances[animationName]
  if not animationInstance then 
    animationInstance = Instance.new("Animation")
    animationInstance.Name = animationName
    animationInstance.AnimationId = animationId

    self.AnimationsInstances[animationName] = animationInstance
  end 

  local animationTrack = animator:LoadAnimation(animationInstance)

  return animationTrack
end

function animations:GetTrack(animationName : string) : AnimationTrack
  if not self.Animations[animationName] then 
    local onWait = false
    task.delay(3, function()
      print('Waiting over')
      onWait = true
    end)

    while not self.Animations[animationName] and not onWait do task.wait() end
    if not self.Animations[animationName] then warn("No animation was found:", animationName) return end
  end

  return self.Animations[animationName]
end

function animations:PlayTrack(... : string) : nil
  for _, animationName in {...} do
    if not self.Animations[animationName] then warn("No animation was found:", animationName, "skipping") continue end
    self.Animations[animationName]:Play()
  end
end

function animations:StopTrack(... : string) : nil
  for _, animationName in {...} do
    if not self.Animations[animationName] then warn("No animation was found:", animationName, "skipping") continue end
    self.Animations[animationName]:Stop()
  end
end

function animations:StopAllTracks()
  for _, animationTrack in pairs(self.Animations) do
    if animationTrack.IsPlaying then
      animationTrack:Stop()
    end
  end
end

function animations:GiveTrackProperty(animationName : string, propertyName : string)
  if not self.Animations[animationName] then warn("No animation was found:", animationName) return end

  return self.Animations[animationName][propertyName]
end

function animations:GetRandomTrackOutOf(... : string) : AnimationTrack
  local animationNames = {...}
  local animationName = animationNames[math.random(1, #animationNames)]

  if not self.Animations[animationName] then warn("No animation was found:", animationName) return end
  return self.Animations[animationName]
end

function animations:ReloadExisitngTracks(newAnimator : Animator)
  for animationName, animationInstance in self.AnimationsInstances do
    self.Animations[animationName] = newAnimator:LoadAnimation(animationInstance)
  end
end

return animations

-- local animations = {
--   Animations = {},
--   AnimationsInstances = {},
--   Preloaded = false,
-- }
-- animations.__index = animations

-- function animations:CreateTrack(animator : Animator, animationName : string, animationId : string, animationPriority : Enum.AnimationPriority?) : AnimationTrack
--   if not animator then warn("No animator was provided") return end

--   local animationInstance = self.AnimationsInstances[animationName]
--   if not animationInstance then 
--     animationInstance = Instance.new("Animation")
--     animationInstance.Name = animationName
--     animationInstance.AnimationId = animationId

--     self.AnimationsInstances[animationName] = animationInstance
--   end 

--   local animationTrack = animator:LoadAnimation(animationInstance)
--   if animationPriority then animationTrack.Priority = animationPriority end

--   local character = animator:FindFirstAncestorOfClass("Model")
--   if not character then warn("Animator is not a child of a Model") return end

--   self.Animations[character.Name][animationName] = animationTrack

--   return self.Animations[animationName] 
-- end

-- function animations:GetTrack(animationName : string, characterName : string) : AnimationTrack
--   if not self.Animations[characterName][animationName] then 
--     local onWait = false
--     task.delay(3, function()
--       print('Waiting over')
--       onWait = true
--     end)

--     while not self.Animations[characterName][animationName] and not onWait do task.wait() end
--     if not self.Animations[characterName][animationName] then warn("No animation was found:", animationName) return end
--   end

--   return self.Animations[characterName][animationName]
-- end

-- function animations:PlayTrack(characterName : string, ... : string) : nil
--   for _, animationName in {...} do
--     if not self.Animations[characterName][animationName] then warn("No animation was found:", animationName, "skipping") continue end
--     self.Animations[characterName][animationName]:Play()
--   end
-- end

-- function animations:StopTrack(characterName : string, ... : string) : nil
--   for _, animationName in {...} do
--     if not self.Animations[characterName][animationName] then warn("No animation was found:", animationName, "skipping") continue end
--     self.Animations[characterName][animationName]:Stop()
--   end
-- end

-- function animations:GiveTrackProperty(characterName : string, animationName : string, propertyName : string)
--   if not self.Animations[characterName][animationName] then warn("No animation was found:", animationName) return end

--   return self.Animations[characterName][animationName][propertyName]
-- end

-- function animations:GetRandomTrackOutOf(characterName, ... : string) : AnimationTrack
--   local animationNames = {...}
--   local animationName = animationNames[math.random(1, #animationNames)]

--   if not self.Animations[characterName][animationName] then warn("No animation was found:", animationName) return end
--   return self.Animations[characterName][animationName]
-- end

-- function animations:ReloadExisitngTracks(characterName : string, newAnimator : Animator)
--   for animationName, animationInstance in self.AnimationsInstances do
--     self.Animations[characterName][animationName] = newAnimator:LoadAnimation(animationInstance)
--   end
-- end

-- return animations