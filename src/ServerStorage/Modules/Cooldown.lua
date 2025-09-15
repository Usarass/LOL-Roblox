local Warp = require(game:GetService('ReplicatedStorage').Packages.Warp)

local ShowCooldown = Warp.Server('ShowCooldown')

local CooldownHandler = {}
CooldownHandler.__index = CooldownHandler

CooldownHandler.Handlers = {}

function CooldownHandler.new(owner)
  if not owner then
    warn("CooldownHandler:new called with no owner")
    return nil
  end

  local self = setmetatable({
    Owner = owner,
    ActiveCooldowns = {},
  }, CooldownHandler)

  CooldownHandler.Handlers[owner] = self
  return self
end

function CooldownHandler.destruct(owner)
  if not owner then
    warn("CooldownHandler:destruct called with no owner")
    return
  end

  if not CooldownHandler.Handlers[owner] then
    warn("CooldownHandler:destruct called but owner not found in CooldownHandler.Handlers")
    return
  end
  CooldownHandler.Handlers[owner] = nil
end

function CooldownHandler.GetProfile(owner)
  if not owner then
    warn("CooldownHandler:GetProfile called with no owner")
    return nil
  end

  if not CooldownHandler.Handlers[owner] then
    warn("CooldownHandler:GetProfile called but owner not found in CooldownHandler.Handlers")
    return nil
  end
  return CooldownHandler.Handlers[owner]
end

function CooldownHandler:Add(name, cooldown)
  if not name or not cooldown then
    warn("CooldownHandler:Add called with no name or cooldown")
    return
  end

  -- Only fire the UI remote when the owner is a Player (clients expect a Player)
  if typeof(self.Owner) == "Instance" and self.Owner:IsA("Player") then
    ShowCooldown:Fire(true, self.Owner, name, cooldown)
  end

  table.insert(self.ActiveCooldowns, name)
  task.spawn(function()
    task.wait(cooldown)
    self:Remove(name)
  end)
end

function CooldownHandler:Remove(name)
  if not name then
    return
  end

  local cooldownIndex = table.find(self.ActiveCooldowns, name)
  if not cooldownIndex then
    return
  end

  table.remove(self.ActiveCooldowns, cooldownIndex)
end

function CooldownHandler:RemoveAll(name)
  if not name then
    warn("CooldownHandler:RemoveAll called with no name")
    return
  end

  local cooldownIndex = table.find(self.ActiveCooldowns, name)
  if not cooldownIndex then
    warn("CooldownHandler:RemoveAll called with name not found in ActiveCooldowns")
    return
  end

  while cooldownIndex do
    table.remove(self.ActiveCooldowns, cooldownIndex)
    cooldownIndex = table.find(self.ActiveCooldowns, name)
  end
end

function CooldownHandler:Found(name)
  if not name then
    warn("CooldownHandler:Found called with no name")
    return false
  end

  return table.find(self.ActiveCooldowns, name) ~= nil
end

return CooldownHandler