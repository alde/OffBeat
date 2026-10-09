local OffBeat = _G.OffBeat

-- Enchant and gem recommendations per spec (GearData.lua: OffBeat.GearRecs,
-- what the top heroic parses wear; OffBeat.GearNames has enchant names) and a check of what you have equipped.
-- Works for every spec, with or without a rotation profile.

local SLOTS = {
    -- simc slot name, inventory slot, label
    { "head",      1,  "Head" },
    { "neck",      2,  "Neck" },
    { "shoulder",  3,  "Shoulders" },
    { "back",      15, "Back" },
    { "chest",     5,  "Chest" },
    { "wrist",     9,  "Wrists" },
    { "hands",     10, "Hands" },
    { "waist",     6,  "Waist" },
    { "legs",      7,  "Legs" },
    { "feet",      8,  "Feet" },
    { "finger1",   11, "Ring 1" },
    { "finger2",   12, "Ring 2" },
    { "main_hand", 16, "Main Hand" },
    { "off_hand",  17, "Off Hand" },
}
OffBeat.GEAR_SLOTS = SLOTS

function OffBeat:GetGearRecs()
    local spec = GetSpecialization and GetSpecialization()
    local specId = spec and GetSpecializationInfo(spec)
    return specId and self.GearRecs and self.GearRecs[specId], specId
end

-- Item ID, enchant ID and gem IDs from an item link.
local function ParseLink(link)
    local body = link and link:match("item:([%-%d:]*)")
    if not body then return nil end
    local f, i = {}, 0
    for v in (body .. ":"):gmatch("([^:]*):") do i = i + 1; f[i] = tonumber(v) end -- empty fields stay nil
    local gems = {}
    for i = 3, 6 do
        if f[i] and f[i] > 0 then gems[#gems + 1] = f[i] end
    end
    return { item = f[1], enchant = (f[2] and f[2] > 0) and f[2] or nil, gems = gems }
end

local function SocketCount(link)
    local getStats = (C_Item and C_Item.GetItemStats) or GetItemStats
    if not getStats then return 0 end
    local ok, stats = pcall(getStats, link)
    if not ok or type(stats) ~= "table" then return 0 end
    local n = 0
    for k, v in pairs(stats) do
        if type(k) == "string" and k:find("^EMPTY_SOCKET_") then n = n + (tonumber(v) or 0) end
    end
    return n
end

function OffBeat:ReadEquipped(invSlot)
    local link = GetInventoryItemLink("player", invSlot)
    if not link then return nil end
    local info = ParseLink(link)
    if not info then return nil end
    info.link = link
    info.icon = GetInventoryItemTexture("player", invSlot)
    info.sockets = math.max(SocketCount(link), #info.gems)
    return info
end

--- Gem / enchant names: the recommendation's English name, else the game's.
function OffBeat:GearName(kind, id, recs)
    if kind == "enchant" then
        return (self.GearNames and self.GearNames[id]) or ("Enchant " .. id)
    end
    local name = C_Item.GetItemNameByID and C_Item.GetItemNameByID(id)
    if not name and C_Item.RequestLoadItemDataByID then C_Item.RequestLoadItemDataByID(id) end
    return name or ("Gem " .. id)
end

--- The check: one entry per enchantable slot, plus a gem summary.
---   enchants = { { label, icon, options = { {id, pct}, ... }, have = id|nil, status = "ok"|"other"|"missing"|"empty" } }
---   gems = { recommended = { {id, pct} }, sockets = n, filled = n, empty = { labels }, odd = { {label, id} } }
function OffBeat:CheckGear()
    local recs = self:GetGearRecs()
    if not recs then return nil end
    local out = { enchants = {}, gems = { recommended = recs.gems or {}, sockets = 0, filled = 0, empty = {}, odd = {} } }
    local goodGem = {}
    for _, g in ipairs(recs.gems or {}) do goodGem[g[1]] = true end

    for _, s in ipairs(SLOTS) do
        local key, invSlot, label = s[1], s[2], s[3]
        local eq = self:ReadEquipped(invSlot)
        local options = recs.enchants and recs.enchants[key]
        if options then
            local e = { label = label, icon = eq and eq.icon, options = options, have = eq and eq.enchant }
            if not eq then
                e.status = "empty"
            elseif not eq.enchant then
                e.status = "missing"
            else
                e.status = "other"
                for _, o in ipairs(options) do
                    if o[1] == eq.enchant then e.status = "ok" end
                end
            end
            out.enchants[#out.enchants + 1] = e
        end
        if eq and eq.sockets > 0 then
            out.gems.sockets = out.gems.sockets + eq.sockets
            out.gems.filled = out.gems.filled + #eq.gems
            for _ = #eq.gems + 1, eq.sockets do out.gems.empty[#out.gems.empty + 1] = label end
            for _, g in ipairs(eq.gems) do
                if not goodGem[g] then out.gems.odd[#out.gems.odd + 1] = { label, g } end
            end
        end
    end
    return out, recs
end

--- /ob gear: the check in chat.
function OffBeat:PrintGearCheck()
    local check, recs = self:CheckGear()
    if not check then
        self:Print("No gear recommendations for this spec yet.")
        return
    end
    self:Print("Enchants (what top players use, " .. (recs.source or "") .. "):")
    local MARK = { ok = "|cff33ff66ok|r", other = "|cffffd100other|r", missing = "|cffff4040missing|r", empty = "|cff888888no item|r" }
    for _, e in ipairs(check.enchants) do
        local top = e.options[1]
        local line = string.format("  %s %s: %s (%d%%)", MARK[e.status], e.label, self:GearName("enchant", top[1], recs), top[2])
        if e.status == "other" then line = line .. "  |cff888888yours: " .. self:GearName("enchant", e.have, recs) .. "|r" end
        self:Print(line)
    end
    local g = check.gems
    local names = {}
    for i, r in ipairs(g.recommended) do
        if i > 4 then break end
        names[#names + 1] = string.format("%s (%d%%)", self:GearName("gem", r[1]), r[2])
    end
    self:Print("Gems top players use: " .. table.concat(names, ", "))
    self:Print(string.format("  Your sockets: %d of %d filled%s", g.filled, g.sockets,
        #g.empty > 0 and (" |cffff4040(empty: " .. table.concat(g.empty, ", ") .. ")|r") or ""))
end
