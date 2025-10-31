-- EmittersHandler.client.lua
-- Listens for server 'Emit' events and invokes matching functions from ReplicatedStorage.Modules.Emitters

local Warp = require(game:GetService("ReplicatedStorage").Packages.Warp)
local EmitRemote = Warp.Client("Emit")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local success, Emitters = pcall(function()
    return require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Emitters"))
end)
if not success or type(Emitters) ~= "table" then
    warn("EmittersHandler: failed to require Emitters module")
    Emitters = {}
end

-- Handler for the remote call
EmitRemote:Connect(function(funcName : string, ...)
  if funcName == nil then
      warn("EmittersHandler: expected function name (string) from server, got nil")
      return
  end

  if typeof(funcName) ~= "string" then
      warn("EmittersHandler: expected function name (string) from server, got", typeof(funcName))
      return
  end

  local fn = Emitters[funcName]
  if type(fn) ~= "function" then
      warn(("EmittersHandler: no emitter function found for '%s'"):format(tostring(funcName)))
      return
  end

  fn(...)
end)
