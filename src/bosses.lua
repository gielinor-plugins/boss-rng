-- Every boss Boss RNG supports. Each file in src/bosses/ is plain data:
-- see src/bosses/kreearra.lua for the format. (src/bosses/common.lua,
-- godwars.lua and godwars2.lua are helpers, not bosses.)

local BOSS_FILES = {
    "graardor", "kreearra", "kril", "nex", "zilyana", -- God Wars
    "furies", "gregorovic", "helwyr", "vindicta", -- God Wars 2
}

local bosses = {}
for _, file in ipairs(BOSS_FILES) do
    -- Assigning keeps only require's first result (Lua 5.4 also returns the path).
    bosses[#bosses + 1] = require("src/bosses/" .. file)
end

return bosses
