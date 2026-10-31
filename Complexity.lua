local OffBeat = _G.OffBeat

-- How much a spec's rotation asks of you, rated 1 (among the simplest) to
-- 5 (among the most demanding), worked out from the profile itself so
-- every spec is judged the same way:
--
--   buttons     keys you press regularly (Key Layout: core and regular tiers)
--   pace        rotation casts a minute for the top players (benchmarks)
--   conditions  priority lines that hang on a proc, a stack count or a
--               threshold ("Ice Lance at 6+ Freezing"), counted for one
--               playthrough (one hero tree, one kind of content)
--   juggling    cooldowns to keep rolling (idle alerts) and to line up
--               before the big one (countdown checks)
--   splits      different builds, bars or sheets for raid, M+ or hero tree
--
-- It measures what the rotation asks for, read from what top players do;
-- not how forgiving the spec is when you play it badly. A profile can
-- override the result: complexity = { score = 3, note = "why" }.

local C = {}
OffBeat.Complexity = C

-- Text that makes a priority line conditional. "on cooldown" and "every
-- ~30s" are timing, not conditions, so plain numbers don't count; numbers
-- next to a resource or a comparison do.
local CONDITION_PATTERNS = {
    "%f[%a]with%f[%A]", "%f[%a]without%f[%A]", "%f[%a]if%f[%A]", "%f[%a]when%f[%A]",
    "%f[%a]below%f[%A]", "%f[%a]under%f[%A]", "%f[%a]above%f[%A]", "%f[%a]until%f[%A]",
    "%f[%a]unless%f[%A]", "%f[%a]proc%a*", "%d+%+", "%f[%a]at %d", "%f[%a]stacks?%f[%A]",
    "%f[%a]charges?%f[%A]", "%f[%a]before%f[%A]", "%f[%a]after%f[%A]",
}

local function IsConditional(text)
    if type(text) ~= "string" then return false end
    local t = text:lower()
    for _, pat in ipairs(CONDITION_PATTERNS) do
        if t:find(pat) then return true end
    end
    return false
end

local function GateKey(section)
    local parts = {}
    for _, k in ipairs({ "known", "unknown" }) do
        if section[k] then
            local ids = {}
            for _, id in ipairs(section[k]) do ids[#ids + 1] = tostring(id) end
            table.sort(ids)
            parts[#parts + 1] = k .. ":" .. table.concat(ids, ",")
        end
    end
    if section.content then parts[#parts + 1] = "content:" .. section.content end
    return #parts > 0 and table.concat(parts, "|") or nil
end

-- Conditional lines for one playthrough: every ungated section, plus the
-- busiest of the gated ones (hero tree / content variants are
-- alternatives, not extra work).
local function Conditions(sheet)
    if type(sheet) ~= "table" then return 0, false, false end
    local base, groups, treeSplit, contentSplit = 0, {}, false, false
    for _, section in ipairs(sheet) do
        local n = 0
        if section.title and section.title:lower():find("opener") then
            n = 0 -- the opener is a script, not a priority
        else
            for _, line in ipairs(section.lines or {}) do
                if IsConditional(line.text) then n = n + 1 end
            end
        end
        if section.known or section.unknown then treeSplit = true end
        if section.content then contentSplit = true end
        local key = GateKey(section)
        if key then groups[key] = (groups[key] or 0) + n else base = base + n end
    end
    local best = 0
    for _, n in pairs(groups) do if n > best then best = n end end
    return base + best, treeSplit, contentSplit
end

local function Buttons(keyLayout)
    local n = 0
    for _, e in ipairs(keyLayout or {}) do
        local st, aoe = e.st, e.aoe
        if (st and st <= 2) or (aoe and aoe <= 2) then n = n + 1 end
    end
    return n
end

-- Median rotation casts a minute from the benchmarks (the rate with
-- all = true): heroic bosses overall, else all M+ dungeons.
local function Pace(b)
    if type(b) ~= "table" or type(b.rates) ~= "table" then return nil end
    local idx
    for i, r in ipairs(b.rates) do if r.all then idx = i; break end end
    if not idx then return nil end
    for _, key in ipairs({ "overall", "dungeonOverall" }) do
        local v = b[key] and b[key].values and b[key].values[idx]
        if type(v) == "table" and type(v[2]) == "number" then return v[2] end
    end
    return nil
end

local function Juggling(p)
    local n = #(p.idleCooldowns or {})
    if p.prep and p.prep.checks then n = n + #p.prep.checks end
    -- buffs you keep on allies (Augmentation's Prescience, Ebon Might)
    n = n + #(p.trackedBuffs or {})
    return n
end

-- Separate raid and M+ bars. (Training windows that differ by content
-- don't count: they're the same build with different goals.)
local function HasContentBars(p)
    for _, e in ipairs(p.barLayout or {}) do if e.content then return true end end
    return false
end

local function Clamp01(x) return x < 0 and 0 or (x > 1 and 1 or x) end

-- Each factor's 0..1 range and weight. The ranges span the current
-- profiles; conditions weigh most (they're what you have to watch for),
-- splits least (you pick a build once).
local SCALE = {
    buttons    = { lo = 6,  hi = 13, w = 0.25 },
    pace       = { lo = 42, hi = 70, w = 0.20 },
    conditions = { lo = 2,  hi = 11, w = 0.30 },
    juggling   = { lo = 2,  hi = 8,  w = 0.15 },
    splits     = { lo = 0,  hi = 2,  w = 0.10 },
}

-- Combined score (0..1) -> 1..5. The cut points split the 23 profiles of
-- October 2026 into roughly equal fifths, so the rating says where a spec
-- sits among the others: 1 = among the simplest rotations, 5 = among the
-- most demanding. Re-check them when profiles change a lot (README).
local CUTS = { 0.23, 0.34, 0.44, 0.52 }

local ORDER = { "conditions", "buttons", "pace", "juggling", "splits" }

local function Norm(name, v)
    local s = SCALE[name]
    if v == nil then return nil end
    return Clamp01((v - s.lo) / (s.hi - s.lo))
end

--- Rate a profile. Returns { score = 1..5, factors = {...}, why = "..." }.
function C.Rate(p)
    if type(p) ~= "table" then return nil end
    local conditions, treeSplit, contentSplit = Conditions(p.rotationSheet)
    local splits = (treeSplit and 1 or 0) + ((contentSplit or HasContentBars(p)) and 1 or 0)
    local f = {
        buttons = Buttons(p.keyLayout),
        pace = Pace(p.benchmarks),
        conditions = conditions,
        juggling = Juggling(p),
        splits = splits,
    }

    local sum, wsum = 0, 0
    for _, name in ipairs(ORDER) do
        local s = SCALE[name]
        local n = Norm(name, f[name])
        if n then sum = sum + n * s.w; wsum = wsum + s.w end
    end
    local x = wsum > 0 and sum / wsum or 0
    local score = 5
    for i, cut in ipairs(CUTS) do
        if x < cut then score = i; break end
    end

    -- The reason, in words: the two heaviest factors for a busy spec, the
    -- two lightest for a simple one, one of each in between ("but").
    local words = {
        buttons    = function(v, light) return (light and "only " or "") .. v .. " buttons in the rotation" end,
        pace       = function(v, light) return string.format(light and "an unhurried %d casts a minute"
                        or "%d casts a minute", math.floor(v + 0.5)) end,
        conditions = function(v, light) return v == 0 and "a fixed priority"
                        or ((light and "only " or "") .. v .. " priority lines that hang on a proc or a count") end,
        juggling   = function(v, light) return (light and "only " or "") .. v .. " cooldowns and buffs to keep up" end,
        splits     = function(v) return v == 0 and "one build everywhere"
                        or (v == 1 and "a second build or layout" or "builds by hero tree and content") end,
    }
    local ranked = {}
    for i, name in ipairs(ORDER) do
        local n = Norm(name, f[name])
        if n then ranked[#ranked + 1] = { name = name, n = n, i = i, pull = (n - 0.5) * SCALE[name].w } end
    end
    table.sort(ranked, function(a, b) -- heaviest first, ties in ORDER
        if a.pull ~= b.pull then return a.pull > b.pull end
        return a.i < b.i
    end)
    local function say(e) return words[e.name](f[e.name], e.n < 0.5) end
    local why = ""
    if #ranked > 0 then
        local heavy, light = ranked[1], ranked[#ranked]
        if score >= 4 then
            why = say(ranked[1]) .. (ranked[2] and (", " .. say(ranked[2])) or "")
        elseif score <= 2 then
            why = say(light) .. (ranked[#ranked - 1] and (", " .. say(ranked[#ranked - 1])) or "")
            if heavy.n >= 0.8 then why = why .. ", but " .. say(heavy) end
        else
            why = say(heavy) .. (heavy ~= light and (", but " .. say(light)) or "")
        end
    end

    local result = { score = score, x = x, factors = f, why = why }
    local o = p.complexity
    if type(o) == "table" then
        if type(o.score) == "number" then result.score = math.max(1, math.min(5, math.floor(o.score))) end
        if type(o.note) == "string" then result.why = o.note end
        result.overridden = true
    end
    return result
end

C.LABELS = { "Simplest", "Simple", "Moderate", "Busy", "Most demanding" }

function C.Text(r)
    if not r then return nil end
    return string.format("%d/5 %s: %s", r.score, C.LABELS[r.score], r.why)
end

--- /ob specs: every installed profile, simplest first.
function OffBeat:PrintSpecComplexity()
    local rows = {}
    for _, list in pairs(self.profiles or {}) do
        for _, p in ipairs(list) do
            local r = C.Rate(p)
            if r then rows[#rows + 1] = { p = p, r = r } end
        end
    end
    if #rows == 0 then self:Print("No profiles installed.") return end
    table.sort(rows, function(a, b)
        if a.r.score ~= b.r.score then return a.r.score < b.r.score end
        return (a.r.x or 0) < (b.r.x or 0)
    end)
    self:Print("Rotation complexity, simplest first (1-5, compared with each other):")
    for _, row in ipairs(rows) do
        self:Print(string.format("  %d  %s: %s", row.r.score, row.p.meta.name, row.r.why))
    end
end
