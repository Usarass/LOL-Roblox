--!strict
local player = game:GetService("Players").LocalPlayer
local character = script:FindFirstAncestorOfClass("Model")
local rootPart = character:WaitForChild("HumanoidRootPart")

local CharacterLiterals = require(game:GetService("ReplicatedStorage").Literals.Characters)
local Consts = require(game:GetService("ReplicatedStorage").Literals.Consts)
local Warp = require(game:GetService("ReplicatedStorage").Packages.Warp)

local EmitCircleAoE = Warp.Client('EmitCircleAoE')

local circle = game:GetService("ReplicatedStorage").Assets.CircleAoE:Clone()
local circleAttachment = circle:WaitForChild("Attachment")
local circleParticle = circleAttachment:WaitForChild("Circle56")

circle.Parent = rootPart

local weld = Instance.new("Weld", rootPart)
weld.Part0 = rootPart
weld.Part1 = circle
weld.C1 = CFrame.new(0, 2.5, 0)

local selectedCharacter = player:GetAttribute("CurrentCharacter")
circleParticle.Size = NumberSequence.new(CharacterLiterals.CharacterStats[selectedCharacter].ReachDistance * Consts.MeterToStudsMultiplier) -- Convert meters to studs (1 meter = 3.57 studs)

EmitCircleAoE:Connect(function(emitCharacter : Model, emitParameters : {}?)
  if not emitCharacter or not emitCharacter:IsA("Model") then return end
  if not emitParameters then emitParameters = {} end

  local characterRootPart = emitCharacter:FindFirstChild("HumanoidRootPart")
  if not characterRootPart then return end

  local characterCircle = characterRootPart:FindFirstChild("CircleAoE")
  if not characterCircle then 
    characterCircle = circle:Clone()
    characterCircle.Parent = characterRootPart
    local weld = Instance.new("Weld", characterRootPart)
    weld.Part0 = emitParameters.WeldPart0 or characterRootPart
    weld.Part1 = characterCircle
    weld.C1 = CFrame.new(0, 3.5, 0)
  end

  local characterCircleAttachment = characterCircle:FindFirstChild("Attachment")
  if not characterCircleAttachment then return end

  local characterCircleParticle = characterCircleAttachment:FindFirstChild("Circle56")
  if not characterCircleParticle then return end

  local size = emitParameters.Size or CharacterLiterals.CharacterStats[selectedCharacter].ReachDistance * Consts.MeterToStudsMultiplier

  characterCircleParticle:Emit(1) -- Emit one particle
  -- characterCircleParticle.Enabled = true
  characterCircleParticle.Size = NumberSequence.new(size) -- Update size based on character's reach distance
end)
