-- A small stand-in for the parts of the Client API our modules use, for specs.
-- Call Reset() before each test.

local mock = {}

local subscribers = {} -- [event name] = { [ref] = handler }
local vars = {}        -- [var name] = VarType-like table

function mock.Reset()
    subscribers, vars = {}, {}
    mock.inGame = false

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
    Player = { IsAvailable = function() return mock.inGame end }
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
