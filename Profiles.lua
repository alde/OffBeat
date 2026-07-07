local OffBeat = _G.OffBeat

local AceSerializer = LibStub("AceSerializer-3.0")
local LibDeflate = LibStub("LibDeflate")

local EXPORT_PREFIX = "!OB1!"
local PROFILE_VERSION = 1

-- Validation

local REQUIRED_META_FIELDS = { "name", "specId", "version" }

local VALID_SECTIONS = {
    "trackedBuffs", "alerts", "castWarnings",
    "rotationSpells", "mistakes", "trackedAuras",
    "keyCooldown", "idleCooldowns", "procTracking",
}

function OffBeat:ValidateProfile(profile)
    if type(profile) ~= "table" then
        return false, "profile must be a table"
    end

    if type(profile.meta) ~= "table" then
        return false, "profile.meta is required"
    end

    for _, field in ipairs(REQUIRED_META_FIELDS) do
        if profile.meta[field] == nil then
            return false, "profile.meta." .. field .. " is required"
        end
    end

    if type(profile.meta.specId) ~= "number" then
        return false, "profile.meta.specId must be a number"
    end

    local hasFeature = false
    for _, section in ipairs(VALID_SECTIONS) do
        if profile[section] then
            hasFeature = true
            break
        end
    end

    if not hasFeature then
        return false, "profile must contain at least one feature section"
    end

    if profile.trackedBuffs then
        local ok, err = self:ValidateTrackedBuffs(profile.trackedBuffs)
        if not ok then return false, err end
    end

    if profile.rotationSpells then
        local ok, err = self:ValidateRotationSpells(profile.rotationSpells)
        if not ok then return false, err end
    end

    if profile.mistakes then
        local ok, err = self:ValidateMistakes(profile.mistakes)
        if not ok then return false, err end
    end

    return true
end

function OffBeat:ValidateTrackedBuffs(buffs)
    if type(buffs) ~= "table" then
        return false, "trackedBuffs must be a table"
    end
    for i, buff in ipairs(buffs) do
        if type(buff.spellId) ~= "number" then
            return false, "trackedBuffs[" .. i .. "].spellId must be a number"
        end
        if type(buff.name) ~= "string" then
            return false, "trackedBuffs[" .. i .. "].name must be a string"
        end
    end
    return true
end

function OffBeat:ValidateRotationSpells(spells)
    if type(spells) ~= "table" then
        return false, "rotationSpells must be a table"
    end
    for i, spell in ipairs(spells) do
        if type(spell.spellId) ~= "number" then
            return false, "rotationSpells[" .. i .. "].spellId must be a number"
        end
    end
    return true
end

function OffBeat:ValidateMistakes(mistakes)
    if type(mistakes) ~= "table" then
        return false, "mistakes must be a table"
    end
    local validTypes = { repeat_cast = true, proc_waste = true }
    for i, mistake in ipairs(mistakes) do
        if not validTypes[mistake.type] then
            return false, "mistakes[" .. i .. "].type must be repeat_cast or proc_waste"
        end
    end
    return true
end

-- Deep copy (strips non-serializable types)

local function DeepCopy(src, seen)
    if type(src) ~= "table" then return src end
    if seen and seen[src] then return seen[src] end
    seen = seen or {}
    local copy = {}
    seen[src] = copy
    for k, v in pairs(src) do
        if type(v) ~= "userdata" and type(v) ~= "function" then
            copy[DeepCopy(k, seen)] = DeepCopy(v, seen)
        end
    end
    return copy
end

OffBeat.DeepCopy = DeepCopy

-- Export

function OffBeat:ExportProfile(profile)
    local clean = DeepCopy(profile)
    local serialized = AceSerializer:Serialize(clean)
    local compressed = LibDeflate:CompressDeflate(serialized)
    local encoded = LibDeflate:EncodeForPrint(compressed)
    return EXPORT_PREFIX .. encoded
end

-- Import

function OffBeat:ImportProfile(str)
    if not str or #str < #EXPORT_PREFIX + 1 then
        return nil, "Invalid import string"
    end

    if str:sub(1, #EXPORT_PREFIX) ~= EXPORT_PREFIX then
        return nil, "Not an OffBeat profile string (expected " .. EXPORT_PREFIX .. " prefix)"
    end

    local encoded = str:sub(#EXPORT_PREFIX + 1)

    local compressed = LibDeflate:DecodeForPrint(encoded)
    if not compressed then
        return nil, "Failed to decode string"
    end

    local serialized = LibDeflate:DecompressDeflate(compressed)
    if not serialized then
        return nil, "Failed to decompress data"
    end

    local ok, profile = AceSerializer:Deserialize(serialized)
    if not ok then
        return nil, "Failed to deserialize profile data"
    end

    local valid, err = self:ValidateProfile(profile)
    if not valid then
        return nil, "Invalid profile: " .. err
    end

    return profile
end

--- Save an imported profile to the database and register it.
function OffBeat:SaveImportedProfile(profile)
    local key = profile.meta.name .. ":" .. profile.meta.specId
    self.db.profile.importedProfiles = self.db.profile.importedProfiles or {}
    self.db.profile.importedProfiles[key] = DeepCopy(profile)

    local specId = profile.meta.specId
    self.profiles[specId] = self.profiles[specId] or {}

    for i, existing in ipairs(self.profiles[specId]) do
        if existing.meta.name == profile.meta.name then
            self.profiles[specId][i] = profile
            return
        end
    end

    table.insert(self.profiles[specId], profile)
end

--- Remove an imported profile.
function OffBeat:RemoveImportedProfile(profile)
    local key = profile.meta.name .. ":" .. profile.meta.specId
    if self.db.profile.importedProfiles then
        self.db.profile.importedProfiles[key] = nil
    end

    local specId = profile.meta.specId
    local available = self.profiles[specId]
    if available then
        for i, p in ipairs(available) do
            if p.meta.name == profile.meta.name then
                table.remove(available, i)
                break
            end
        end
    end
end

