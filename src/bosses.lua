-- Every boss Boss RNG supports. Each file in src/bosses/ is plain data:
-- see src/bosses/kreearra.lua for the format.

local BOSS_FILES = { "kreearra" }

local bosses = {}
for _, file in ipairs(BOSS_FILES) do
    -- Assigning keeps only require's first result (Lua 5.4 also returns the path).
    bosses[#bosses + 1] = require("src/bosses/" .. file)
end

return bosses
