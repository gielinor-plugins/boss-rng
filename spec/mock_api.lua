-- A stand-in for the Client API parts our modules use. Call Reset() before each
-- test. Run specs from the project root with: busted

local mock = {}

local subscribers = {} -- [event name] = { [ref] = handler }
local vars = {} -- [var name] = VarType-like table
local saved = {} -- PersistentDB entries

-- Copies a table, like the real API, which serializes saved data.
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
            return {
                isValid = true,
                GetTotal = function(_, itemID)
                    return mock.backpack[itemID] or 0
                end,
            }
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
        IsAvailable = function()
            return mock.inGame
        end,
        GetEntity = function()
            return { displayName = mock.characterName }
        end,
    }
    PersistentDB = {
        GetStructuredData = function(_, key)
            return copy(saved[key])
        end,
        SetStructuredData = function(_, key, value)
            saved[key] = copy(value)
            return true
        end,
        Delete = function(_, key)
            saved[key] = nil
            return true
        end,
        -- Calls callback(key, value) for each entry until it returns true; returns the
        -- number of entries it was called for.
        IterateEntries = function(_, callback)
            local count = 0
            for key, value in pairs(saved) do
                count = count + 1
                if callback(key, copy(value)) then
                    break
                end
            end
            return count
        end,
    }
end

-- Saves an entry, as if an earlier session had.
function mock.SetSaved(key, value)
    saved[key] = copy(value)
end

function mock.Saved(key)
    return saved[key]
end

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
