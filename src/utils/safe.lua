-- Runs plugin code so that one error can't break the rest of Boss RNG.
-- Each distinct error is printed once, so a repeating error doesn't flood the console.

local safe = {}

local reported = {} -- [error message] = true once printed

-- Calls fn(...) and returns true if it ran without an error. label says what was
-- being done, e.g. "updating the panel".
function safe.Call(label, fn, ...)
    local ok, err = pcall(fn, ...)
    if not ok then
        local message = label .. ": " .. tostring(err)
        if not reported[message] then
            reported[message] = true
            print("[Boss RNG] Error " .. message)
        end
    end
    return ok
end

return safe
