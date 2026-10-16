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
    "statPriority", "heroStatPriorities", "keyLayout", "windows", "benchmarks", "pet", "movingCasts", "barLayout", "rotationSheet", "prep", "failNudges", "castAuras",
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

    if profile.keyLayout then
        local ok, err = self:ValidateKeyLayout(profile.keyLayout)
        if not ok then return false, err end
    end

    if profile.windows then
        local ok, err = self:ValidateWindows(profile.windows)
        if not ok then return false, err end
    end

    if profile.failNudges then
        if type(profile.failNudges) ~= "table" then return false, "failNudges must be a list" end
        for i, n in ipairs(profile.failNudges) do
            local where = "failNudges[" .. i .. "]"
            if n.error ~= "runes" and n.error ~= "range" and n.error ~= "essence" and n.error ~= "moving" then
                return false, where .. ".error must be \"runes\", \"range\", \"essence\" or \"moving\""
            end
            if type(n.spells) ~= "table" or #n.spells == 0 then return false, where .. ".spells must be a non-empty list" end
            if type(n.text) ~= "string" then return false, where .. ".text must be a string" end
        end
    end

    if profile.prep then
        local ok, err = self:ValidatePrep(profile.prep)
        if not ok then return false, err end
    end

    if profile.benchmarks then
        local ok, err = self:ValidateBenchmarks(profile.benchmarks)
        if not ok then return false, err end
    end

    for i, cd in ipairs(profile.idleCooldowns or {}) do
        if cd.content ~= nil and cd.content ~= "raid" and cd.content ~= "dungeon" then
            return false, "idleCooldowns[" .. i .. "].content must be \"raid\" or \"dungeon\""
        end
    end

    if profile.movingCasts ~= nil then
        if type(profile.movingCasts) ~= "table" or #profile.movingCasts == 0 then
            return false, "movingCasts must be a non-empty list"
        end
        for i, m in ipairs(profile.movingCasts) do
            if type(m) ~= "table" or type(m.spellId) ~= "number" then
                return false, "movingCasts[" .. i .. "].spellId must be a spell ID"
            end
        end
    end

    if profile.barLayout ~= nil then
        if type(profile.barLayout) ~= "table" or #profile.barLayout == 0 then
            return false, "barLayout must be a non-empty list"
        end
        local used = {}
        for i, e in ipairs(profile.barLayout) do
            local where = "barLayout[" .. i .. "]"
            if type(e) ~= "table" or type(e.slot) ~= "number" then
                return false, where .. " needs a slot"
            end
            if e.macro ~= nil then
                local m = e.macro
                if type(m) ~= "table" or type(m.name) ~= "string" or #m.name == 0 or #m.name > 16 then
                    return false, where .. ".macro needs a name of 1-16 characters"
                end
                if m.cursor ~= nil and m.cursor ~= true and type(m.cursor) ~= "table" then
                    return false, where .. ".macro.cursor must be true or a list of spell IDs"
                end
                if m.mouseover ~= nil and m.mouseover ~= true then
                    return false, where .. ".macro.mouseover must be true"
                end
                -- one spell at the cursor or on mouseover; otherwise it picks between builds
                local minSpells = (m.cursor == true or m.mouseover) and 1 or 2
                if type(m.spells) ~= "table" or #m.spells < minSpells then
                    return false, where .. ".macro needs at least " .. minSpells .. " spell(s)"
                end
                for _, id in ipairs(m.spells) do
                    if type(id) ~= "number" then return false, where .. ".macro.spells must be spell IDs" end
                end
            elseif type(e.spellId) ~= "number" then
                return false, where .. " needs a spellId or a macro"
            end
            if e.slot < 1 or e.slot > 180 then return false, where .. ".slot must be 1-180" end
            if e.content ~= nil and e.content ~= "raid" and e.content ~= "dungeon" then
                return false, where .. ".content must be \"raid\" or \"dungeon\""
            end
            -- a slot can hold one spell in raid and another in M+, but not two in the same layout
            local u = used[e.slot]
            if u and (u == "both" or e.content == nil or u == e.content) then
                return false, where .. ": slot " .. e.slot .. " is used twice"
            end
            used[e.slot] = u and "both" or (e.content or "both")
        end
    end

    if profile.rotationSheet ~= nil then
        if type(profile.rotationSheet) ~= "table" or #profile.rotationSheet == 0 then
            return false, "rotationSheet must be a non-empty list of sections"
        end
        for i, section in ipairs(profile.rotationSheet) do
            local where = "rotationSheet[" .. i .. "]"
            if type(section) ~= "table" or type(section.lines) ~= "table" then
                return false, where .. " needs lines"
            end
            if section.content ~= nil and section.content ~= "raid" and section.content ~= "dungeon" then
                return false, where .. ".content must be \"raid\" or \"dungeon\""
            end
            for _, k in ipairs({ "known", "unknown" }) do
                if section[k] ~= nil and type(section[k]) ~= "table" then
                    return false, where .. "." .. k .. " must be a list of spell IDs"
                end
            end
            for j, line in ipairs(section.lines) do
                if type(line) ~= "table" or type(line.text) ~= "string" then
                    return false, where .. ".lines[" .. j .. "] needs text"
                end
                if line.spellId ~= nil and type(line.spellId) ~= "number" then
                    return false, where .. ".lines[" .. j .. "].spellId must be a number"
                end
            end
        end
    end

    if profile.assistedCombat ~= nil and type(profile.assistedCombat) ~= "boolean" then
        return false, "assistedCombat must be true or false"
    end

    if profile.pet ~= nil then
        if type(profile.pet) ~= "table" then return false, "pet must be a table" end
        if profile.pet.quickSummon ~= nil and type(profile.pet.quickSummon) ~= "number" then
            return false, "pet.quickSummon must be a spell ID"
        end
        if profile.pet.sacrifice ~= nil and type(profile.pet.sacrifice) ~= "number" then
            return false, "pet.sacrifice must be a spell ID"
        end
    end

    if profile.keyLayoutLabels ~= nil then
        local l = profile.keyLayoutLabels
        if type(l) ~= "table" then return false, "keyLayoutLabels must be a table" end
        for _, k in ipairs({ "st", "aoe", "stLong", "aoeLong" }) do
            if type(l[k]) ~= "string" then
                return false, "keyLayoutLabels." .. k .. " must be a string"
            end
        end
    end

    if profile.procTracking then
        for i, pt in ipairs(profile.procTracking) do
            if type(pt.procAura) ~= "number" then
                return false, "procTracking[" .. i .. "].procAura must be a spell ID"
            end
            if type(pt.consumeSpells) ~= "table" or #pt.consumeSpells == 0 then
                return false, "procTracking[" .. i .. "].consumeSpells must be a non-empty list"
            end
        end
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

local function IsCondition(c)
    return c.aura ~= nil or c.power ~= nil or c.combat ~= nil or c.hardcast ~= nil or c.moving ~= nil or c.recent ~= nil
end

local function ValidateCondition(c, where)
    if type(c) ~= "table" then return false, where .. " must be a table" end
    if c.aura then
        if type(c.aura) ~= "number" then return false, where .. ".aura must be a spell ID" end
        if c.minStacks ~= nil and type(c.minStacks) ~= "number" then return false, where .. ".minStacks must be a number" end
        if c.maxStacks ~= nil and type(c.maxStacks) ~= "number" then return false, where .. ".maxStacks must be a number" end
    elseif c.power then
        if type(c.power) ~= "string" and type(c.power) ~= "number" then
            return false, where .. ".power must be a power type name or number"
        end
        if c.min == nil and c.max == nil then return false, where .. " needs min and/or max" end
    elseif c.combat ~= nil then
        if type(c.combat) ~= "boolean" then return false, where .. ".combat must be true or false" end
    elseif c.hardcast ~= nil then
        if type(c.hardcast) ~= "boolean" then return false, where .. ".hardcast must be true or false" end
    elseif c.moving ~= nil then
        if type(c.moving) ~= "boolean" then return false, where .. ".moving must be true or false" end
    elseif c.recent ~= nil then
        if type(c.recent) ~= "number" then return false, where .. ".recent must be a spell ID" end
        if type(c.within) ~= "number" then return false, where .. ".within must be seconds" end
    else
        return false, where .. " must have aura, power, combat, hardcast, moving or recent"
    end
    return true
end

local function ValidateWhen(when, where)
    if type(when) ~= "table" then return false, where .. " is required" end
    if IsCondition(when) then when = { when } end
    if #when == 0 then return false, where .. " needs at least one condition" end
    for j, c in ipairs(when) do
        local ok, err = ValidateCondition(c, where .. "[" .. j .. "]")
        if not ok then return false, err end
    end
    return true
end

local function ValidateBench(e, nRates, where)
    if type(e) ~= "table" then return false, where .. " must be a table" end
    if type(e.name) ~= "string" then return false, where .. ".name must be a string" end
    if e.window ~= nil and type(e.window) ~= "number" then return false, where .. ".window must be a number" end
    if type(e.values) ~= "table" then
        return false, where .. ".values must list { low, median, high } per rate"
    end
    -- nil in a rate's place: no number for it here (raid-only / M+-only rates)
    local any = false
    for k in pairs(e.values) do
        if type(k) ~= "number" or k < 1 or k > nRates or k % 1 ~= 0 then
            return false, where .. ".values has more entries than there are rates"
        end
    end
    for j = 1, nRates do
        local v = e.values[j]
        if v ~= nil then
            if type(v) ~= "table" or type(v[1]) ~= "number" or type(v[2]) ~= "number" or type(v[3]) ~= "number" then
                return false, where .. ".values[" .. j .. "] must be { low, median, high }"
            end
            any = true
        end
    end
    if not any then return false, where .. ".values must list { low, median, high } per rate" end
    return true
end

function OffBeat:ValidateBenchmarks(bm)
    if type(bm) ~= "table" or type(bm.rates) ~= "table" or #bm.rates == 0 then
        return false, "benchmarks.rates must be a non-empty list"
    end
    for i, r in ipairs(bm.rates) do
        local where = "benchmarks.rates[" .. i .. "]"
        if type(r.name) ~= "string" then return false, where .. ".name must be a string" end
        if not r.all and (type(r.spells) ~= "table" or #r.spells == 0) then
            return false, where .. " needs spells or all = true"
        end
    end
    if bm.encounters == nil and bm.overall == nil and bm.dungeons == nil then
        return false, "benchmarks needs encounters, overall and/or dungeons"
    end
    for id, e in pairs(bm.dungeons or {}) do
        if type(id) ~= "number" then return false, "benchmarks.dungeons keys must be instance IDs" end
        local ok, err = ValidateBench(e, #bm.rates, "benchmarks.dungeons[" .. id .. "]")
        if not ok then return false, err end
    end
    if bm.dungeonOverall then
        local ok, err = ValidateBench(bm.dungeonOverall, #bm.rates, "benchmarks.dungeonOverall")
        if not ok then return false, err end
    end
    for id, e in pairs(bm.encounters or {}) do
        if type(id) ~= "number" then return false, "benchmarks.encounters keys must be encounter IDs" end
        local ok, err = ValidateBench(e, #bm.rates, "benchmarks.encounters[" .. id .. "]")
        if not ok then return false, err end
    end
    if bm.overall then
        local ok, err = ValidateBench(bm.overall, #bm.rates, "benchmarks.overall")
        if not ok then return false, err end
    end
    return true
end

function OffBeat:ValidateWindows(windows)
    if type(windows) ~= "table" then return false, "windows must be a table" end
    for i, w in ipairs(windows) do
        local where = "windows[" .. i .. "]"
        if type(w.name) ~= "string" then return false, where .. ".name must be a string" end
        if type(w.trigger) ~= "number" then return false, where .. ".trigger must be a spell ID" end
        if w.note ~= nil and type(w.note) ~= "string" then return false, where .. ".note must be a string" end
        if type(w.duration) ~= "number" or w.duration <= 0 then
            return false, where .. ".duration must be a positive number"
        end
        if (w.goals == nil or #w.goals == 0) and (w.setup == nil or #w.setup == 0) then
            return false, where .. " needs goals and/or setup checks"
        end
        for j, g in ipairs(w.goals or {}) do
            local gw = where .. ".goals[" .. j .. "]"
            if type(g.name) ~= "string" then return false, gw .. ".name must be a string" end
            if type(g.spells) ~= "table" or #g.spells == 0 then return false, gw .. ".spells must be a non-empty list" end
            if type(g.min) ~= "number" then return false, gw .. ".min must be a number" end
        end
        for j, s in ipairs(w.setup or {}) do
            local sw = where .. ".setup[" .. j .. "]"
            if type(s.name) ~= "string" then return false, sw .. ".name must be a string" end
            local ok, err = ValidateWhen(s.when, sw .. ".when")
            if not ok then return false, err end
        end
    end
    return true
end

function OffBeat:ValidatePrep(prep)
    if type(prep) ~= "table" then return false, "prep must be a table" end
    if type(prep.spellId) ~= "number" then return false, "prep.spellId must be a spell ID" end
    if prep.cooldown ~= nil and type(prep.cooldown) ~= "number" then return false, "prep.cooldown must be a number" end
    if prep.lead ~= nil and type(prep.lead) ~= "number" then return false, "prep.lead must be a number" end
    for i, c in ipairs(prep.checks or {}) do
        local where = "prep.checks[" .. i .. "]"
        if c.ready ~= nil then
            if type(c.ready) ~= "number" then return false, where .. ".ready must be a spell ID" end
        else
            if type(c.power) ~= "string" then return false, where .. ".power must be a power type name" end
            if type(c.min) ~= "number" then return false, where .. ".min must be a number" end
        end
        if c.with ~= nil and (type(c.with) ~= "table" or type(c.with.spellId) ~= "number") then
            return false, where .. ".with must be { spellId = ... }"
        end
        if c.credit ~= nil and (type(c.credit) ~= "table" or type(c.credit.spellId) ~= "number"
                or type(c.credit.amount) ~= "number") then
            return false, where .. ".credit must be { spellId = ..., amount = n }"
        end
    end
    return true
end

function OffBeat:ValidateMistakes(mistakes)
    if type(mistakes) ~= "table" then
        return false, "mistakes must be a table"
    end
    for i, mistake in ipairs(mistakes) do
        local where = "mistakes[" .. i .. "]"
        local t = mistake.type
        if t == "bad_cast" then
            if type(mistake.spells) ~= "table" or #mistake.spells == 0 then
                return false, where .. ".spells must be a non-empty list"
            end
            local when = mistake.when
            if type(when) ~= "table" then return false, where .. ".when is required" end
            if IsCondition(when) then when = { when } end
            if #when == 0 then return false, where .. ".when needs at least one condition" end
            for j, c in ipairs(when) do
                local ok, err = ValidateCondition(c, where .. ".when[" .. j .. "]")
                if not ok then return false, err end
            end
        elseif t ~= "repeat_cast" then
            return false, where .. ".type must be repeat_cast or bad_cast"
        end
    end
    return true
end

function OffBeat:ValidateKeyLayout(layout)
    if type(layout) ~= "table" then
        return false, "keyLayout must be a table"
    end
    local function validTier(t) return t == nil or t == 1 or t == 2 or t == 3 end
    for i, entry in ipairs(layout) do
        local where = "keyLayout[" .. i .. "]"
        if type(entry.spellId) ~= "number" then
            return false, where .. ".spellId must be a number"
        end
        if not validTier(entry.st) or not validTier(entry.aoe) then
            return false, where .. ".st / .aoe must be 1, 2, 3 or nil"
        end
        if entry.st == nil and entry.aoe == nil then
            return false, where .. " needs an st or aoe tier"
        end
        if entry.alt ~= nil and type(entry.alt) ~= "table" then
            return false, where .. ".alt must be a list of spell IDs"
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
