local assets = game:GetService("ReplicatedStorage").Assets

return {
  Star = function(emitConfig : {model : Model, duration : number})
    print("Emitters: Star emitter called")

    local model = emitConfig.Model
    local duration = emitConfig.Duration

    if not model or not model:IsA("Model") then
      warn("Emitters: expected model (Model), got", typeof(model))
      return
    end

    if duration == nil or typeof(duration) ~= "number" then
      warn("Emitters: expected duration (number), got", typeof(duration))
      duration = 1
    end

    local stars = assets:FindFirstChild("Stars")
    if not stars then
      warn("Emitters: no Stars asset found in ReplicatedStorage.Assets")
      return
    end

    stars = stars:Clone()

    local emitterAttachment = stars:FindFirstChildOfClass("Attachment")
    if not emitterAttachment then
      warn("Emitters: no Attachment found in Stars asset")
      return
    end

    local emitter = emitterAttachment:FindFirstChildOfClass("ParticleEmitter")
    if not emitter then
      warn("Emitters: no ParticleEmitter found in Stars asset")
      return
    end

    local leftArm = model:FindFirstChild("Left Arm") or model:FindFirstChild("LeftHand")
    if not leftArm then
      warn("Emitters: no Left Arm or LeftHand found in model", model)
      return
    end

    emitterAttachment.Parent = leftArm
    emitter.Enabled = true
    emitter:Emit(1)

    task.wait(duration)

    emitter.Enabled = false
    task.wait(5)
    stars:Destroy()
  end,

  Shield = function(emitConfig : {model : Model, duration : number})
    local model = emitConfig.Model
    local duration = emitConfig.Duration

    if not model or not model:IsA("Model") then
      warn("Emitters: expected model (Model), got", typeof(model))
      return
    end

    if duration == nil or typeof(duration) ~= "number" then
      warn("Emitters: expected duration (number), got", typeof(duration))
      duration = 1
    end

    local shield = assets:FindFirstChild("Shield")
    if not shield then
      warn("Emitters: no Shield asset found in ReplicatedStorage.Assets")
      return
    end

    local rootPart = model:FindFirstChild("HumanoidRootPart")
    if not rootPart then
      warn("Emitters: no HumanoidRootPart found in model", model)
      return
    end

    shield = shield:Clone()

    local emitterAttachment = shield:FindFirstChildOfClass("Attachment")
    if not emitterAttachment then
      warn("Emitters: no Attachment found in Shield asset")
      return
    end

    local emitters = {}

    for _, emitter in pairs(emitterAttachment:GetChildren()) do
      if emitter:IsA("ParticleEmitter") == false then continue end

      emitter.Enabled = true
      emitter:Emit(1)
      table.insert(emitters, emitter)
    end

    emitterAttachment.Parent = rootPart
    task.wait(duration)

    for _, emitter in pairs(emitters) do
      emitter.Enabled = false
    end

    task.wait(5)
    shield:Destroy()
  end
}