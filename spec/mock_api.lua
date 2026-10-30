-- A small stand-in for the parts of the Client API our modules use, for specs.
-- Call Reset() before each test.

local mock = {}

local subscribers = {} -- [event name] = { [ref] = handler }
local vars = {}        -- [var name] = VarType-like table
local saved = {}       -- PersistentDB entries

-- Copies a table, so saved data can't be changed by accident (like the real thing,
-- which serializes it).
local function copy(value)
    if type(value) ~= "table" then
        return value
    end
    local result = {}
    for key, inner in pairs(value) do
        result[key] = copy(inner)
    end
    return result
end

-- Clears everything. Pass keepSaved = true to keep saved data, like a plugin reload.
function mock.Reset(keepSaved)
    subscribers, vars = {}, {}
    if not keepSaved then
        saved = {}
    end
    mock.inGame = false
    mock.characterName = "Tester"
    mock.backpack = {} -- [item id] = count

    config = { Inv = { INV = { id = 93, configName = "INV" } } }
    Inventory = {
        Find = function()
            return { isValid = true, GetTotal = function(_, itemID) return mock.backpack[itemID] or 0 end }
        end,
    }

    Event = setmetatable({}, {
        __index = function(_, name)
            return {
                Subscribe = function(ref, handler)
                    subscribers[name] = subscribers[name] or {}
                    subscribers[name][ref] = handler
                end,
                Unsubscribe = function(ref)
                    if subscribers[name] then
                        subscribers[name][ref] = nil
                    end
                end,
            }
        end,
    })
    var = { VarPlayer = vars }
    GameState = { LOGINSCREEN = 10, GAME = 30 }
    Player = {
        IsAvailable = function() return mock.inGame end,
        GetEntity = function() return { displayName = mock.characterName } end,
    }
    PersistentDB = {
        GetStructuredData = function(_, key) return copy(saved[key]) end,
        SetStructuredData = function(_, key, value)
            saved[key] = copy(value)
            return true
        end,
    }
end

-- A saved entry, for checking what was written.
function mock.Saved(key)
    return saved[key]
end

-- Sends an event to every subscriber.
function mock.Fire(name, payload)
    for _, handler in pairs(subscribers[name] or {}) do
        handler(payload)
    end
end

-- Number of active subscriptions, to check Stop() cleans up.
function mock.SubscriptionCount()
    local count = 0
    for _, refs in pairs(subscribers) do
        for _ in pairs(refs) do
            count = count + 1
        end
    end
    return count
end

-- Opens an interface with the given components, { [index] = component }.
-- Sets a var's value, adding the var if needed.
function mock.SetValue(name, value)
    vars[name] = vars[name] or { configName = name }
    vars[name].value = value
end

-- Adds a base var and returns it.
function mock.AddVar(name, id)
    vars[name] = { id = id, configName = name, isVarBit = false }
    return vars[name]
end

-- Adds a varbit using the bits in mask of base.
function mock.AddVarbit(name, id, base, mask)
    vars[name] = { id = id, configName = name, isVarBit = true, baseVar = base, varBitMask = mask }
end

return mock
