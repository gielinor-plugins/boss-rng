-- Data saved on this computer for the logged in character. Saved data is shared
-- by every character on this computer, so each character gets its own entry,
-- keyed by display name. A display name change starts a new entry.

local saved = {}

-- The logged in character's display name, or nil.
local function characterName()
    if not Player.IsAvailable() then
        return nil
    end
    local entity = Player.GetEntity()
    if entity == nil or entity.displayName == "" then
        return nil
    end
    return entity.displayName
end

-- A store of one record per character, saved under prefix .. display name.
--   store.Load()  the logged in character's record and name, loaded if needed,
--                 or nil if nobody is logged in. A missing record, or one saved
--                 by another version, starts again as fresh().
--   store.Save()  saves the loaded record
function saved.ForCharacter(prefix, version, fresh)
    local store = {}
    local name, record = nil, nil

    function store.Load()
        local current = characterName()
        if current == nil then
            return nil
        end
        if current ~= name then
            name = current
            record = PersistentDB:GetStructuredData(prefix .. name)
            if record == nil or record.version ~= version then
                record = fresh()
                record.version = version
            end
        end
        return record, name
    end

    function store.Save()
        if not PersistentDB:SetStructuredData(prefix .. name, record) then
            print("[Boss RNG] Could not save data for " .. name)
        end
    end

    return store
end

return saved
