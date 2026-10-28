-- The Sanctum of Rebirth: Vermyx, Kezalam and Nakatra, fought in one run, with
-- one boss log page. Each boss has its own Beasts tab page and kill counts.
--
-- From the RuneScape Wiki's boss pages (rates from Jagex; CC BY-NC-SA 3.0),
-- checked 2026-10-27: every player gets their own rolls. Each boss rolls a book
-- table (1/125, hard mode 1/100): the Divine Rage prayer codex or the Scripture of
-- Amascut. Nakatra also rolls her weapons (1/75, hard mode 1/60): Roar of
-- Awakening or Ode to Deceit; and in hard mode the Shard of Genesis Essence (1/75).

local common = require("src/bosses/common")

local CODEX, SCRIPTURE, ROAR, ODE = 57156, 57124, 57162, 57158

-- The rolls, from 1 in books for a book, then for Nakatra 1 in weapons for a
-- weapon and 1 in shard for the Shard (hard mode only).
local function rolls(books, weapons, shard)
    local list = { { chance = 1 / books, items = common.Even({ CODEX, SCRIPTURE }) } }
    if weapons then
        table.insert(list, { chance = 1 / weapons, items = common.Even({ ROAR, ODE }) })
    end
    if shard then
        table.insert(list, { chance = 1 / shard, items = { [common.SHARD] = 1 } })
    end
    return list
end

local KC = "BSLAY_KILLS_RAID_REBIRTH1_" -- each boss's kill count var starts with this

return {
    key = "sanctum", -- saved data key: never change it
    name = "Sanctum of Rebirth",
    logPage = "COLLECTION_BOSS_RAID_REBIRTH1", -- the boss log page's database row
    assumptions = {},

    -- Mode names are saved with the player's data: never change them.
    modes = {
        { name = "Vermyx", kc = KC .. "WYRM_BOSS", rolls = rolls(125) },
        { name = "Vermyx hard mode", kc = KC .. "WYRM_BOSS_HARDMODE", rolls = rolls(100) },
        { name = "Kezalam", kc = KC .. "BEAST_BOSS", rolls = rolls(125) },
        { name = "Kezalam hard mode", kc = KC .. "BEAST_BOSS_HARDMODE", rolls = rolls(100) },
        { name = "Nakatra", kc = KC .. "SLAYER_MASTER_BOSS", rolls = rolls(125, 75) },
        { name = "Nakatra hard mode", kc = KC .. "SLAYER_MASTER_BOSS_HARDMODE", rolls = rolls(100, 60, 75) },
    },

    -- Every item on the boss log page, with its log count varbit and kind (see
    -- src/bosses/kreearra.lua for what each kind means).
    items = {
        [CODEX] = { log = "ITEMLOG_ITEM_COMBATV2_PRAYER_CODEX_DIVINE_RAGE", kind = "unique" },
        [SCRIPTURE] = { log = "ITEMLOG_ITEM_RAID_REBIRTH1_AMASCUT_BOOK_UNLOCK_TOKEN", kind = "unique" },
        [ROAR] = { log = "ITEMLOG_ITEM_MAGIC_DEVOURER_WAND_T95", kind = "unique" },
        [ODE] = { log = "ITEMLOG_ITEM_MAGIC_DEVOURER_ORB_T95", kind = "unique" },
        [common.SHARD] = common.SHARD_ITEM, -- also dropped by Amascut
        [57121] = { kind = "lore" }, -- The Brood Mother
        [57122] = { kind = "lore" }, -- The Beast of Darkness
        [57123] = { kind = "lore" }, -- Death and Devourers
        [57167] = { kind = "pet" }, -- Neffie
    },
}
