-- Data saved on this computer, shared by every character on it, so each gets its
-- own entry by display name. A display name change starts a new entry.

local saved = {}

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
-- store.Load() gives the character's record and name (nil if nobody is logged in);
-- a missing record, or one from another version, starts as fresh(). With codec,
-- codec.Encode(record) is what's saved and codec.Decode(saved) gives the record
-- back, converting older versions it can (nil to start again).
function saved.ForCharacter(prefix, version, fresh, codec)
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
            if record ~= nil and codec then
                record = codec.Decode(record)
            end
            if record == nil or record.version ~= version then
                record = fresh()
                record.version = version
            end
        end
        return record, name
    end

    function store.Save()
        if not PersistentDB:SetStructuredData(prefix .. name, codec and codec.Encode(record) or record) then
            print("[Boss RNG] Could not save data for " .. name)
        end
    end

    return store
end

return saved
