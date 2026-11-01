-- Sanctum of Rebirth: three bosses in one run with one boss log page, each with its own
-- kill counts. Rates: RuneScape Wiki (from Jagex; CC BY-NC-SA 3.0), checked 2026-10-27.
-- Every player gets their own rolls.

local common = require("src/bosses/common")

local VARS = {
    kc = "BSLAY_KILLS_RAID_REBIRTH1_", -- then each boss's name, with _HARDMODE for hard mode
    log = "ITEMLOG_ITEM_", -- then each unique's log count name
}

local CODEX, SCRIPTURE, ROAR, ODE = 57156, 57124, 57162, 57158

-- Rolls by rate names: a book, then for Nakatra a weapon and, in hard mode, the Shard.
local function rolls(books, weapons, shard)
    return function(r)
        local list = { { chance = r[books], items = common.Even({ CODEX, SCRIPTURE }) } }
        if weapons then
            table.insert(list, { chance = r[weapons], items = common.Even({ ROAR, ODE }) })
        end
        if shard then
            table.insert(list, { chance = r[shard], items = { [common.SHARD] = 1 } })
        end
        return list
    end
end

local BOOKS, HARD_BOOKS = rolls("books"), rolls("hardBooks")

return {
    key = "sanctum", -- saved data key: never change it
    name = "Sanctum of Rebirth",
    assumptions = {},

    -- Mode names are saved: never change them.
    modes = {
        { name = "Vermyx", kc = VARS.kc .. "WYRM_BOSS", rolls = BOOKS },
        { name = "Vermyx hard mode", kc = VARS.kc .. "WYRM_BOSS_HARDMODE", rolls = HARD_BOOKS },
        { name = "Kezalam", kc = VARS.kc .. "BEAST_BOSS", rolls = BOOKS },
        { name = "Kezalam hard mode", kc = VARS.kc .. "BEAST_BOSS_HARDMODE", rolls = HARD_BOOKS },
        { name = "Nakatra", kc = VARS.kc .. "SLAYER_MASTER_BOSS", rolls = rolls("books", "weapons") },
        { name = "Nakatra hard mode", kc = VARS.kc .. "SLAYER_MASTER_BOSS_HARDMODE",
            rolls = rolls("hardBooks", "hardWeapons", "hardShard") },
    },

    items = {
        [CODEX] = { log = VARS.log .. "COMBATV2_PRAYER_CODEX_DIVINE_RAGE", kind = "unique" },
        [SCRIPTURE] = { log = VARS.log .. "RAID_REBIRTH1_AMASCUT_BOOK_UNLOCK_TOKEN", kind = "unique" },
        [ROAR] = { log = VARS.log .. "MAGIC_DEVOURER_WAND_T95", kind = "unique" },
        [ODE] = { log = VARS.log .. "MAGIC_DEVOURER_ORB_T95", kind = "unique" },
        [common.SHARD] = common.SHARD_ITEM, -- also dropped by Amascut
        [57121] = { kind = "lore" }, -- The Brood Mother
        [57122] = { kind = "lore" }, -- The Beast of Darkness
        [57123] = { kind = "lore" }, -- Death and Devourers
        [57167] = { kind = "pet" }, -- Neffie
    },
}
