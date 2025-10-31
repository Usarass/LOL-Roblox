local Warp = require(game:GetService('ReplicatedStorage').Packages.Warp)
local ShowCooldown = Warp.Server('ShowCooldown')

-- Weak-keyed registry so owner entries don't prevent GC
local registries = setmetatable({}, { __mode = "k" })

local Cooldown = {}
Cooldown.__index = Cooldown

-- Ensure registry exists for owner (returns the registry table)
local function ensure(owner)
    if not owner then
        warn("Cooldown:ensure called with no owner")
        return nil
    end
    local reg = registries[owner]
    if reg then return reg end

    reg = {
        Owner = owner,
        Active = {}
    }

    -- best-effort cleanup when Instance owners are removed
    if typeof(owner) == "Instance" and owner.AncestryChanged then
        pcall(function()
            owner.AncestryChanged:Connect(function(_, parent)
                if not parent then
                    registries[owner] = nil
                end
            end)
        end)
    end

    registries[owner] = reg
    return reg
end

-- Public: register owner (keeps previous API shape .new but returns registry)
function Cooldown.new(owner)
    return ensure(owner)
end

-- Public: remove registry and stop tracking owner
function Cooldown.destruct(owner)
    if not owner then return end
    registries[owner] = nil
end

-- Add a cooldown for owner (auto-creates registry)
function Cooldown.Add(owner, name, duration)
    if not owner or not name or not duration then
        warn("Cooldown.Add - missing arguments")
        return
    end

    local reg = ensure(owner)
    if not reg then return end

    table.insert(reg.Active, name)

    -- notify client UI only for Player owners
    if typeof(owner) == "Instance" and owner:IsA("Player") then
        pcall(function() ShowCooldown:Fire(true, owner, name, duration) end)
    end

    task.spawn(function()
        task.wait(duration)
        -- make sure registry still present
        if registries[owner] then
            Cooldown.Remove(owner, name)
        end
    end)
end

-- Remove a single cooldown
function Cooldown.Remove(owner, name)
    if not owner or not name then return end
    local reg = registries[owner]
    if not reg then return end

    local idx = table.find(reg.Active, name)
    if idx then table.remove(reg.Active, idx) end
end

-- Remove all occurrences of a cooldown name
function Cooldown.RemoveAll(owner, name)
    if not owner or not name then return end
    local reg = registries[owner]
    if not reg then return end

    local idx = table.find(reg.Active, name)
    while idx do
        table.remove(reg.Active, idx)
        idx = table.find(reg.Active, name)
    end
end

-- Check if owner has a cooldown
function Cooldown.Found(owner, name)
    if not owner or not name then return false end
    local reg = registries[owner]
    if not reg then return false end
    return table.find(reg.Active, name) ~= nil
end

return Cooldown