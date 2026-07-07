local OffBeat = _G.OffBeat

local SOUND_LIST = {
    { key = "wood_break",     name = "Wood Break",        id = 173248 },
    { key = "talent_ready",   name = "Talent Ready",      id = 73280 },
    { key = "raid_warning",   name = "Raid Warning",      id = 8959 },
    { key = "ready_check",    name = "Ready Check",       id = 8960 },
    { key = "alarm1",         name = "Alarm Clock 1",     id = 12867 },
    { key = "alarm2",         name = "Alarm Clock 2",     id = 12889 },
    { key = "alarm3",         name = "Alarm Clock 3",     id = 12890 },
    { key = "pvp_flag",       name = "PvP Flag Taken",    id = 8174 },
    { key = "levelup",        name = "Level Up",          id = 888 },
    { key = "map_ping",       name = "Map Ping",          id = 3175 },
    { key = "loot_coin",      name = "Loot Coin",         id = 120 },
    { key = "quest_complete", name = "Quest Complete",     id = 878 },
    { key = "none",           name = "None",              id = nil },
    { key = "custom",         name = "Custom SoundKit ID", id = nil },
}

local SOUND_BY_KEY = {}
local SOUND_VALUES = {}
for _, entry in ipairs(SOUND_LIST) do
    SOUND_BY_KEY[entry.key] = entry
    SOUND_VALUES[entry.key] = entry.name
end

OffBeat.SOUND_LIST = SOUND_LIST
OffBeat.SOUND_VALUES = SOUND_VALUES

function OffBeat:PlayConfigSound(settingKey)
    local key = self.db.profile[settingKey]
    if key == "custom" then
        local id = tonumber(self.db.profile[settingKey .. "CustomId"])
        if id then PlaySound(id, "Master") end
        return
    end
    local entry = SOUND_BY_KEY[key]
    if entry and entry.id then
        PlaySound(entry.id, "Master")
    end
end

function OffBeat:GetSoundId(settingKey)
    local key = self.db.profile[settingKey]
    if key == "custom" then
        return tonumber(self.db.profile[settingKey .. "CustomId"])
    end
    local entry = SOUND_BY_KEY[key]
    return entry and entry.id
end

