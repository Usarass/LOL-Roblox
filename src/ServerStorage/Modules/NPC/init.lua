local npcsFolder = workspace.DamagableHumanoids.NPCs
if not npcsFolder then
  npcsFolder = Instance.new("Folder")
  npcsFolder.Name = "NPCs"
  npcsFolder.Parent = workspace
end

local npcAssets = game:GetService("ReplicatedStorage").Assets.NPCModels
if not npcAssets then
  error("NPC models not found in ReplicatedStorage")
end

local NPCsLiterals = require(game:GetService("ReplicatedStorage").Literals.Characters)
local CooldownHandlerNPC = require(game:GetService('ServerStorage').Modules.Cooldown)
local GoodSignal = require(game:GetService("ReplicatedStorage").Packages.GoodSignal)
local StatusEffects = require(game:GetService("ServerStorage").Modules.StatusEffects)

local Character = {
  Characters = {},
}
Character.__index = Character

function Character.new(NPCName : string?, spawnCFrame : CFrame?)
  if not NPCName or not NPCsLiterals.CharactersNames[NPCName] then
    NPCName = NPCsLiterals.CharactersNames['NPCDefault']
  end

  local npcModel = npcAssets:FindFirstChild(NPCName)
  if not npcModel then
    error("NPC model '" .. NPCName .. "' not found in Assets.NPCModels")
  end

  npcModel = npcModel:Clone()
  npcModel.Parent = npcsFolder

  if not spawnCFrame then
    spawnCFrame = CFrame.new(0, 2.5, 0) -- Default spawn position
  end

  local npcHumanoid = npcModel:FindFirstChildOfClass("Humanoid")
  if not npcHumanoid then
    error("Humanoid not found in NPC model: " .. NPCName)
  end

  local baseHealth = NPCsLiterals.CharacterStats[NPCName].BaseHealth
  if not baseHealth or type(baseHealth) ~= "number" then
    error("BaseHealth not defined or invalid for NPC: " .. NPCName)
  end

  npcHumanoid.MaxHealth = baseHealth
  npcHumanoid.Health = npcHumanoid.MaxHealth

  local self = setmetatable({
    NPCName = NPCName,
    Model = npcModel,
    SpawnCFrame = spawnCFrame,
    Parameters = {},
    ToAtributes = {
      Regen = false,
      CurrentCharacter = NPCName
    },

    CharacterModule = '',
    StatusEffectChanged = GoodSignal.new(),
  }, Character)

  self.StatusEffectChanged:Connect(function(self, changeDescription : StatusEffects.changeDescription)
    local handler = StatusEffects.statusEffectHandlers[changeDescription.Name]
    if not handler then print("No handler for status effect: " .. changeDescription.Name) return end

    handler(self, changeDescription)
  end)

  for _, part in next, npcModel:GetDescendants() do
    if part:IsA("BasePart") == false then continue end

    part.CollisionGroup = "Character"
  end

  for attributeName, attributeValue in next, self.ToAtributes do
    self.Model:SetAttribute(attributeName, attributeValue)
  end

  self:Regen()
  npcModel:PivotTo(spawnCFrame)

  local humanoid = self.Model:FindFirstChildOfClass("Humanoid")
  if not humanoid then warn("Humanoid not found in NPC model: " .. self.Model.Name) return end

  humanoid.Died:Connect(function()
    Character.destruct(self.Model)
    CooldownHandlerNPC.destruct(self.Model)
  end)

  Character.Characters[npcModel] = self

  return self
end

function Character.getCharacterModule(NPCModel : Model)
  return Character.Characters[NPCModel]
end

function Character:Regen()
  local humanoid = self.Model:FindFirstChildOfClass("Humanoid")
  if not humanoid then warn("Humanoid not found in NPC model: " .. self.Model.Name) return end

  local regenAttribute = self.Model:GetAttribute("Regen")
  if regenAttribute == nil then warn("Regen attribute not found in NPC model: " .. self.Model.Name) return end

  self.Model:GetAttributeChangedSignal("Regen"):Connect(function()
    while self.Model:GetAttribute("Regen") do
      task.wait(1)
      humanoid.Health = math.clamp(humanoid.Health + self.Parameters.RegenPerSecond, 0, humanoid.MaxHealth)
    end
  end)

  self.Model:SetAttribute("Regen", true)
end

function Character:Find()
  
end

function Character:DefaultAttack()
  
end

function Character.destruct(NPCModel : Model)
  local character = Character.Characters[NPCModel]
  if not character then
    warn("Character:destruct called but player not found in Character.Characters")
    return
  end
  Character.Characters[NPCModel] = nil
end

return Character