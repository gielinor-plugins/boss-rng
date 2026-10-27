-- Every boss Boss RNG supports. Each file in src/bosses/ is plain data:
-- see src/bosses/kreearra.lua for the format. (src/bosses/godwars.lua is a
-- helper, not a boss.)

local BOSS_FILES = { "graardor", "kreearra" }

local bosses = {}
for _, file in ipairs(BOSS_FILES) do
    -- Assigning keeps only require's first result (Lua 5.4 also returns the path).
    bosses[#bosses + 1] = require("src/bosses/" .. file)
end

return bosses
