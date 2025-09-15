local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Lightweight signal
local function makeSignal()
    local sig = {}
    sig._b = {}
    function sig:Connect(fn)
        self._b[fn] = true
        return { Disconnect = function() self._b[fn] = nil end }
    end
    function sig:Fire(...)
        for fn in pairs(self._b) do
            task.spawn(fn, ...)
        end
    end
    return sig
end

export type StateDef = {
    Name: string,
    Priority: number?,                     -- Higher wins (default 0)
    Duration: number?,                     -- Optional auto-exit timer
    Tags: {string}?,                       -- Custom tags (e.g. {"Offensive"})
    BlockInput: boolean?,                  -- If true, input blocked
    AttributeValue: any?,                  -- Written to Character:SetAttribute("State", value or Name)
    AllowedNext: {[string]: boolean}?,     -- Whitelist transitions (if provided)
    DeniedNext: {[string]: boolean}?,      -- Blacklist transitions
    Enter: (ctx: any, prev: string?) -> ()?,
    Exit: (ctx: any, next: string?) -> ()?,
    CanInterrupt: (incoming: StateDef, ctx: any) -> boolean? -- Return true to allow being replaced
}

export type StateMachine = {
    Character: Model,
    Player: Player?,
    Current: string?,
    CurrentDef: StateDef?,
    StartedAt: number?,
    States: {[string]: StateDef},
    Busy: boolean,
    Version: number,
    Signals: {
        Changed: any,
        Entered: any,
        Exited: any,
        Failed: any
    },
    Context: any,
    SetState: (self: StateMachine, name: string, opts: {Force: boolean?, Reason: string?}?) -> boolean,
    Try: (self: StateMachine, name: string) -> boolean,
    IsIn: (self: StateMachine, name: string) -> boolean,
    HasTag: (self: StateMachine, tag: string) -> boolean,
    CanTransition: (self: StateMachine, name: string) -> (boolean, string?),
    RegisterState: (self: StateMachine, def: StateDef) -> (),
    Step: (self: StateMachine) -> (),
    Destroy: (self: StateMachine) -> ()
}

local Registry: {[Model]: StateMachine} = {}

local DEFAULT_PRIORITY = 0

local Manager = {}
Manager.__index = Manager

-- Utility
local function setAttributeSafe(char: Model, key: string, value: any)
    if char and char.Parent then
        pcall(function()
            char:SetAttribute(key, value)
        end)
    end
end

local function tableToSet(list)
    if not list then return nil end
    local s = {}
    for _, v in ipairs(list) do s[v] = true end
    return s
end

-- Public: Get machine for character (creates if not exists, no states pre-registered)
function Manager.Get(character: Model): StateMachine
    return Registry[character]
end

-- Constructor
function Manager.new(character: Model, context: any?): StateMachine
    assert(character, "Character required")
    local self: StateMachine = setmetatable({}, Manager)
    self.Character = character
    self.Player = Players:GetPlayerFromCharacter(character)
    self.States = {}
    self.Current = nil
    self.CurrentDef = nil
    self.StartedAt = nil
    self.Busy = false
    self.Version = 0
    self.Context = context or {}
    self.Signals = {
        Changed = makeSignal(),
        Entered = makeSignal(),
        Exited = makeSignal(),
        Failed = makeSignal()
    }

    Registry[character] = self

    -- Clean up on character removal
    character.AncestryChanged:Connect(function(_, parent)
        if not parent then
            self:Destroy()
        end
    end)

    -- Heartbeat auto-duration handling
    RunService.Heartbeat:Connect(function()
        if self.Character.Parent == nil then return end
        self:Step()
    end)

    return self
end

-- Register a state definition
function Manager:RegisterState(def: StateDef)
    assert(def and def.Name, "State def must have Name")
    if self.States[def.Name] then
        warn("State already registered: " .. def.Name)
        return
    end
    def.Priority = def.Priority or DEFAULT_PRIORITY
    if def.Tags then
        def._TagSet = tableToSet(def.Tags)
    end
    if def.AllowedNext then
        local map = {}
        for _, n in ipairs(def.AllowedNext) do map[n] = true end
        def.AllowedNext = map
    end
    if def.DeniedNext then
        local map = {}
        for _, n in ipairs(def.DeniedNext) do map[n] = true end
        def.DeniedNext = map
    end
    self.States[def.Name] = def
end

function Manager:IsIn(name: string): boolean
    return self.Current == name
end

function Manager:HasTag(tag: string): boolean
    if not self.CurrentDef or not self.CurrentDef._TagSet then return false end
    return self.CurrentDef._TagSet[tag] == true
end

-- Core transition validation
function Manager:CanTransition(nextName: string): (boolean, string?)
    local nextDef = self.States[nextName]
    if not nextDef then
        return false, "State not registered"
    end

    local char = self.Character
    if char and char:GetAttribute("Stunned") and nextName ~= "Stunned" then
        -- Hard lock while stunned (unless going into Stunned again, which will early out)
        return false, "Character stunned"
    end

    -- Already in it
    if self.Current == nextName then
        return false, "Already in state"
    end

    local currentDef = self.CurrentDef
    if not currentDef then
        return true, nil
    end

    -- Allowed / Denied lists
    if currentDef.AllowedNext and not currentDef.AllowedNext[nextName] then
        return false, "Not in AllowedNext"
    end
    if currentDef.DeniedNext and currentDef.DeniedNext[nextName] then
        return false, "In DeniedNext"
    end

    -- Priority rules
    if nextDef.Priority < currentDef.Priority then
        return false, "Lower priority"
    end
    if nextDef.Priority == currentDef.Priority then
        -- Optionally allow same-priority override only if current permits
        if currentDef.CanInterrupt and currentDef.CanInterrupt(nextDef, self.Context) == false then
            return false, "Cannot interrupt same priority"
        end
    end

    -- Current may block interruption
    if currentDef.CanInterrupt and currentDef.CanInterrupt(nextDef, self.Context) == false then
        return false, "Cannot interrupt"
    end

    return true, nil
end

-- Attempt transition (no force)
function Manager:Try(name: string): boolean
    return self:SetState(name, {Force = false})
end

-- Forced or validated transition
function Manager:SetState(name: string, opts: {Force: boolean?, Reason: string?}?): boolean
    if self.Busy then return false end
    opts = opts or {}
    local force = opts.Force

    local nextDef = self.States[name]
    if not nextDef then
        self.Signals.Failed:Fire(self, name, "Unregistered")
        return false
    end

    if not force then
        local ok, why = self:CanTransition(name)
        if not ok then
            self.Signals.Failed:Fire(self, name, why)
            return false
        end
    end

    self.Busy = true
    local prevName = self.Current
    local prevDef = self.CurrentDef

    -- Exit previous
    if prevDef and prevDef.Exit then
        local ok, err = pcall(prevDef.Exit, self.Context, name)
        if not ok then warn("[State Exit Error] " .. tostring(err)) end
    end

    -- Update
    self.Current = name
    self.CurrentDef = nextDef
    self.StartedAt = os.clock()
    self.Version += 1

    -- Attribute
    setAttributeSafe(self.Character, "State", nextDef.AttributeValue ~= nil and nextDef.AttributeValue or name)
    -- Input blocking attribute
    if nextDef.BlockInput then
        setAttributeSafe(self.Character, "InputBlocked", true)
    else
        setAttributeSafe(self.Character, "InputBlocked", false)
    end

    -- Enter
    if nextDef.Enter then
        local ok, err = pcall(nextDef.Enter, self.Context, prevName)
        if not ok then warn("[State Enter Error] " .. tostring(err)) end
    end

    -- Signals
    self.Signals.Changed:Fire(self, prevName, name)
    if prevName then
        self.Signals.Exited:Fire(self, prevName, name)
    end
    self.Signals.Entered:Fire(self, name, prevName)

    self.Busy = false
    return true
end

-- Auto duration handling
function Manager:Step()
    if not self.CurrentDef then return end
    local dur = self.CurrentDef.Duration
    if dur and self.StartedAt and (os.clock() - self.StartedAt) >= dur then
        -- Auto revert to Idle if exists
        if self.States.Idle then
            self:SetState("Idle")
        else
            -- Clear
            self:SetState(self.Current) -- refresh or remain
        end
    end
end

function Manager:Destroy()
    if Registry[self.Character] == self then
        Registry[self.Character] = nil
    end
    self.States = {}
    self.Current = nil
    self.CurrentDef = nil
end

-- Convenience: Build a default fighting state set quickly
function Manager.ApplyDefaultStates(sm: StateMachine, config: {IdleSpeed: number?, WalkSpeedAttr: string?}? )
    config = config or {}
    local speedAttr = config.WalkSpeedAttr or "BaseWalkSpeed"
    local baseSpeed = config.IdleSpeed or 16

    sm:RegisterState({
        Name = "Idle",
        Priority = 1,
        Enter = function(ctx)
          print("Entering Idle")
          print('Character: ', sm.Character)
            local hum = sm.Character:FindFirstChildOfClass("Humanoid")
            if hum then print("Setting WalkSpeed to " .. baseSpeed) hum.WalkSpeed = baseSpeed end
        end,
        AllowedNext = {"Walk","Attack","Block","Stunned","Dash","Hitstun"}
    })

    sm:RegisterState({
        Name = "Walk",
        Priority = 1,
        Enter = function()
            -- local hum = sm.Character:FindFirstChildOfClass("Humanoid")
            -- if hum then
            --     hum.WalkSpeed = baseSpeed + 10
            -- end
        end,
        AllowedNext = {"Idle","Attack","Block","Dash","Stunned","Hitstun"}
    })

    sm:RegisterState({
        Name = "Attack",
        Priority = 5,
        BlockInput = true,
        Duration = .5,
        Enter = function() end,
        AllowedNext = {"Idle","Attack","Block","Stunned","Hitstun"}
    })

    sm:RegisterState({
        Name = "Block",
        Priority = 4,
        BlockInput = false,
        Enter = function()
            setAttributeSafe(sm.Character, "Blocking", true)
        end,
        Exit = function()
            setAttributeSafe(sm.Character, "Blocking", false)
        end,
        AllowedNext = {"Idle","Attack","Stunned","Hitstun"}
    })

    sm:RegisterState({
        Name = "Dash",
        Priority = 6,
        BlockInput = true,
        Duration = .25,
        AllowedNext = {"Idle","Attack","Block","Stunned","Hitstun"}
    })

    sm:RegisterState({
        Name = "Hitstun",
        Priority = 7,
        BlockInput = true,
        Duration = .35,
        AllowedNext = {"Idle","Attack","Block","Stunned"}
    })

    sm:RegisterState({
        Name = "Stunned",
        Priority = 10,
        BlockInput = true,
        Enter = function()
            setAttributeSafe(sm.Character, "Stunned", true)
            -- local hum = sm.Character:FindFirstChildOfClass("Humanoid")
            -- if hum then hum.WalkSpeed = 4 end
        end,
        Exit = function()
            setAttributeSafe(sm.Character, "Stunned", false)
            -- local hum = sm.Character:FindFirstChildOfClass("Humanoid")
            -- if hum then hum.WalkSpeed = baseSpeed end
        end,
        AllowedNext = {"Idle","Hitstun"} -- After stun ends
    })
end

return Manager