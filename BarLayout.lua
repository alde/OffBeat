local OffBeat = _G.OffBeat

-- Puts a profile's spells on your action bars (profile.barLayout):
--
--   barLayout = {
--       { slot = 1,  key = "1", spellId = 55090 },   -- action slot, key it's bound to, spell
--       { slot = 7,  key = "G", spellId = 1271967, alt = { 1271974 } }, -- first known ID wins
--       ...
--   }
--
-- A slot can hold a macro that picks between spells two talent builds
-- don't share, so one key works in both:
--
--       { slot = 63, key = "Shift-3", macro = { name = "OB Malev/Cata",
--             spells = { 442726, 152108 } } },
--
-- becomes a per-character macro "#showtooltip / /cast [known:Malevolence]
-- Malevolence; Cataclysm": the first spell you know wins, the last one is
-- the fallback. `cursor = true` casts them at the mouse cursor
-- ([@cursor]), for ground-targeted spells, or `cursor = { ids }` only those
-- (Havoc on your target, Cataclysm at the cursor). A macro with cursor can
-- hold just one spell. `mouseover = true` casts a heal on the friendly unit
-- under the mouse, or your target when there is none
-- ([@mouseover,help,nodead][]); one spell. Spell names come from the game,
-- so it works in any client language. /ob bars apply creates the macro, or
-- rewrites it if it exists.
--
-- Raid and Mythic+ layouts: an entry with `content = "raid"` or
-- `"dungeon"` only belongs to that layout (entries without it are in both),
-- so the same slot can hold Vivify in raid and Spinning Crane Kick in a key.
-- Which one applies is the content mode (/ob mode; dungeons and delves are
-- Mythic+). When it changes, or you switch to the spec, OffBeat offers to
-- swap the layout on your bars (out of combat, per spec setting; see below).
-- Outside instances in auto mode: /ob bars raid | mythic [apply].
--
-- Slots are Blizzard's: 1-12 main bar, 61-72 bottom left, 49-60 bottom right,
-- 25-36 right, 37-48 left, 145-180 bars 5-7. `key` is only shown in the plan.
-- /ob bars shows the plan, /ob bars apply places it (out of combat). What was
-- in those slots is replaced; other slots are left alone. Spells you don't
-- know are skipped.

local CONTENT_NAMES = { raid = "raid", dungeon = "Mythic+" }

local function Known(spellId)
    local ok, known = pcall(IsPlayerSpell, spellId)
    return ok and known and true or false
end

local function SpellName(spellId)
    local info = C_Spell.GetSpellInfo(spellId)
    return info and info.name or ("spell " .. spellId)
end

local function MacroBody(m)
    if m.mouseover then
        return "#showtooltip\n/cast [@mouseover,help,nodead][] " .. SpellName(m.spells[1])
    end
    local atCursor = {}
    if m.cursor == true then
        for _, id in ipairs(m.spells) do atCursor[id] = true end
    elseif type(m.cursor) == "table" then
        for _, id in ipairs(m.cursor) do atCursor[id] = true end
    end
    local parts = {}
    for i, id in ipairs(m.spells) do
        local name = SpellName(id)
        local cond = {}
        if atCursor[id] then cond[#cond + 1] = "@cursor" end
        if i < #m.spells then cond[#cond + 1] = "known:" .. name end
        parts[#parts + 1] = (#cond > 0 and ("[" .. table.concat(cond, ",") .. "] ") or "") .. name
    end
    return "#showtooltip\n/cast " .. table.concat(parts, "; ")
end
OffBeat.BarLayoutMacroBody = MacroBody

-- Create or update the macro; returns true once it's on the cursor.
local function PickupLayoutMacro(m)
    local body = MacroBody(m)
    local index = GetMacroIndexByName(m.name)
    if index and index > 0 then
        EditMacro(index, m.name, nil, body)
    else
        local ok, newIndex = pcall(CreateMacro, m.name, "INV_MISC_QUESTIONMARK", body, true)
        if not ok or not newIndex then return false end
        index = newIndex
    end
    PickupMacro(index)
    return GetCursorInfo() == "macro"
end

local function MacroLabel(m)
    local names = {}
    for _, id in ipairs(m.spells) do names[#names + 1] = SpellName(id) end
    return "macro: " .. table.concat(names, " / ") .. (m.cursor == true and " at cursor" or "")
        .. (m.mouseover and " on mouseover" or "")
end

-- A known spell for a macro entry: shown with its icon, skipped when you
-- know none of its spells (a heal macro you aren't talented for).
local function MacroKnown(m)
    for _, id in ipairs(m.spells) do if Known(id) then return true end end
    return false
end

--- Does this layout have separate raid / Mythic+ entries?
function OffBeat:BarLayoutHasContent(layout)
    layout = layout or (self.activeProfile and self.activeProfile.barLayout)
    for _, e in ipairs(layout or {}) do if e.content then return true end end
    return false
end

--- Which layout applies: "raid" / "dungeon" from the argument or the content
--- mode, nil when the layout has no content entries. Second return is true
--- when it's ambiguous (content entries, auto mode, outside instances).
function OffBeat:BarLayoutContent(arg)
    if not self:BarLayoutHasContent() then return nil, false end
    if arg == "raid" then return "raid", false end
    if arg == "mythic" or arg == "dungeon" or arg == "m+" then return "dungeon", false end
    local now = self:ContentMode()
    return now, now == nil
end

local function Entries(layout, content)
    local out = {}
    for _, e in ipairs(layout) do
        if not e.content or e.content == content then out[#out + 1] = e end
    end
    return out
end

--- The plan as rows for the settings window:
--- { key, spellId (icon), text, known } in layout order.
function OffBeat:GetBarLayoutPlan(content)
    local layout = self.activeProfile and self.activeProfile.barLayout
    if not layout then return nil end
    local rows = {}
    for _, e in ipairs(Entries(layout, content)) do
        if e.macro then
            rows[#rows + 1] = { key = e.key or ("slot " .. e.slot), spellId = e.macro.spells[1],
                text = e.note or MacroLabel(e.macro), known = MacroKnown(e.macro), macro = MacroLabel(e.macro) }
        else
            local id = e.spellId
            if not Known(id) and e.alt then
                for _, a in ipairs(e.alt) do if Known(a) then id = a; break end end
            end
            rows[#rows + 1] = { key = e.key or ("slot " .. e.slot), spellId = id,
                text = e.note or SpellName(id), known = Known(id) }
        end
    end
    return rows
end

local function SpecSettings()
    local profile = OffBeat.activeProfile
    if not profile then return nil end
    local specs = OffBeat.db.profile.specSettings
    specs[profile.meta.specId] = specs[profile.meta.specId] or {}
    return specs[profile.meta.specId]
end

--- /ob bars [raid|mythic] [apply]
function OffBeat:ShowBarLayout(apply, contentArg)
    local layout = self.activeProfile and self.activeProfile.barLayout
    if not layout then
        self:Print("No bar layout for this spec.")
        return
    end
    local content, ambiguous = self:BarLayoutContent(contentArg)
    if ambiguous then
        self:Print("This spec has a raid and a Mythic+ layout. Pick one: /ob bars raid | mythic"
            .. (apply and " apply" or "") .. " (or set /ob mode).")
        return
    end
    if apply and InCombatLockdown() then
        self:Print("Can't change action bars in combat.")
        return
    end

    local label = content and (" (" .. CONTENT_NAMES[content] .. ")") or ""
    if not apply then self:Print("Bar layout for " .. self.activeProfile.meta.name .. label .. " (key: spell):") end
    local placed, skipped = 0, {}
    for _, e in ipairs(Entries(layout, content)) do
      if e.macro then
        if not MacroKnown(e.macro) then
            skipped[#skipped + 1] = SpellName(e.macro.spells[1])
            if not apply then self:Print(string.format("  %-8s %s |cff888888(not known, skipped)|r",
                e.key or ("slot " .. e.slot), SpellName(e.macro.spells[1]))) end
        elseif apply then
            ClearCursor()
            if PickupLayoutMacro(e.macro) then
                PlaceAction(e.slot)
                placed = placed + 1
            else
                skipped[#skipped + 1] = e.macro.name .. " (no free macro slot)"
            end
            ClearCursor()
        else
            self:Print(string.format("  |cffffd100%-10s|r %s", e.key or ("slot " .. e.slot),
                e.note and (e.note .. " |cff888888(" .. MacroLabel(e.macro) .. ")|r") or MacroLabel(e.macro)))
        end
      else
        local id = e.spellId
        if not Known(id) and e.alt then
            for _, a in ipairs(e.alt) do if Known(a) then id = a; break end end
        end
        local name = SpellName(id)
        if not Known(id) then
            skipped[#skipped + 1] = name
            if not apply then self:Print(string.format("  %-8s %s |cff888888(not known, skipped)|r", e.key or ("slot " .. e.slot), name)) end
        elseif apply then
            ClearCursor()
            C_Spell.PickupSpell(id)
            if GetCursorInfo() == "spell" then
                PlaceAction(e.slot)
                placed = placed + 1
            else
                skipped[#skipped + 1] = name
            end
            ClearCursor() -- drops whatever was in the slot before
        else
            self:Print(string.format("  |cffffd100%-10s|r %s", e.key or ("slot " .. e.slot), e.note or name))
        end
      end
    end

    if apply then
        local ss = SpecSettings()
        if ss and content then ss.barLayoutContent = content end
        self:Print(string.format("Placed %d spells on your bars%s.%s", placed, label,
            #skipped > 0 and (" Skipped: " .. table.concat(skipped, ", ") .. ".") or ""))
    else
        self:Print("Type |cffffd100/ob bars " .. (contentArg and (contentArg .. " ") or "") .. "apply|r to put these on "
            .. "your bars (replaces what's in those slots).")
    end
end

-- Offer the layout when it may be the wrong one on your bars:
--  * the content changes (entering a raid, a key or a delve, or /ob mode):
--    "Put your Mythic+ bar layout on your bars?" when it isn't already there;
--    "Not now" holds until the content changes again;
--  * you switch to the spec: in a raid / dungeon / delve the same question,
--    outside instances (auto mode) "Raid or Mythic+?".
-- Waits for the end of combat. Off with the per-spec toggle on Keys & Bars.

local declined   -- content the offer was turned down for, this session
local pending    -- an offer waiting for combat to end: "content" or "spec"

local function Apply(content) OffBeat:ShowBarLayout(true, content == "dungeon" and "mythic" or "raid") end

StaticPopupDialogs["OFFBEAT_BAR_SWAP"] = {
    text = "OffBeat: put your %s bar layout on your bars?\n(Replaces only the layout's slots.)",
    button1 = YES, button2 = "Not now",
    OnAccept = function(_, data) Apply(data) end,
    OnCancel = function(_, data) declined = data end,
    timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
}

StaticPopupDialogs["OFFBEAT_BAR_CHOOSE"] = {
    text = "OffBeat: which bar layout for %s?\nOn your bars now: %s. (Replaces only the layout's slots.)",
    button1 = "Raid", button3 = "Mythic+", button2 = "Not now",
    OnAccept = function() Apply("raid") end,
    OnAlt = function() Apply("dungeon") end,
    timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
}

function OffBeat:CheckBarSwap(specChanged)
    if not (self.db and self.activeProfile and self:BarLayoutHasContent()) then return end
    local ss = SpecSettings()
    if ss.barSwapOffer == false then return end
    local content = self:ContentMode()
    if specChanged then declined = nil end
    if not content and not specChanged then return end -- outside instances: only ask on a spec switch
    if content and ss.barLayoutContent == content then declined = nil; return end
    if content and declined == content then return end
    if InCombatLockdown() then
        pending = (specChanged or pending == "spec") and "spec" or "content"
        return
    end
    pending = nil
    StaticPopup_Hide("OFFBEAT_BAR_SWAP")
    StaticPopup_Hide("OFFBEAT_BAR_CHOOSE")
    if content then
        StaticPopup_Show("OFFBEAT_BAR_SWAP", CONTENT_NAMES[content], nil, content)
    else
        local onBars = ss.barLayoutContent
        StaticPopup_Show("OFFBEAT_BAR_CHOOSE", self.activeProfile.meta.name,
            onBars == "raid" and "raid" or onBars == "dungeon" and "Mythic+" or "not placed by OffBeat yet")
    end
end

local watcher = CreateFrame("Frame")
watcher:RegisterEvent("PLAYER_ENTERING_WORLD")
watcher:RegisterEvent("ZONE_CHANGED_NEW_AREA")
watcher:RegisterEvent("PLAYER_REGEN_ENABLED")
watcher:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
watcher:SetScript("OnEvent", function(_, event, unit)
    if event == "PLAYER_REGEN_ENABLED" then
        if not pending then return end
        local spec = pending == "spec"
        C_Timer.After(1, function() OffBeat:CheckBarSwap(spec) end)
        return
    end
    if event == "PLAYER_SPECIALIZATION_CHANGED" and unit ~= "player" then return end
    local spec = event == "PLAYER_SPECIALIZATION_CHANGED"
    -- give the profile a moment to load after a spec change or a loading screen
    C_Timer.After(2, function() OffBeat:CheckBarSwap(spec) end)
end)
OffBeat:RegisterMessage("OFFBEAT_CONTENT_MODE_CHANGED", function() OffBeat:CheckBarSwap() end)
