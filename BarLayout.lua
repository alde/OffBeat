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
-- Mythic+; outside instances your talents, when the profile names
-- tell-tale ones). When it changes, OffBeat offers to swap the layout on
-- your bars (see below). Or pick one: /ob bars raid | mythic [apply].
--
-- Slots are Blizzard's: 1-12 main bar, 61-72 bottom left, 49-60 bottom right,
-- 25-36 right, 37-48 left, 145-180 bars 5-7. `key` is only shown in the plan.
-- /ob bars shows the plan, /ob bars apply places it (out of combat). What was
-- in those slots is replaced; other slots are left alone. Spells you don't
-- know are skipped.

local CONTENT_NAMES = { raid = "raid", dungeon = "Mythic+" }

local function KnownExact(spellId)
    local ok, known = pcall(IsPlayerSpell, spellId)
    return ok and known and true or false
end

--- The spellbook's ID for `spellId`: itself, the spell it overrides, or the
--- spellbook spell with the same name. The IDs in a profile come from
--- combat logs, which can be a talent's or hero tree's cast ID rather than
--- the one in the spellbook (Hammer of Wrath, Holy Bulwark).
local function Resolve(spellId)
    if KnownExact(spellId) then return spellId end
    if FindSpellOverrideByID then
        local ok, override = pcall(FindSpellOverrideByID, spellId)
        if ok and override and override ~= spellId and KnownExact(override) then return override end
    end
    local info = C_Spell.GetSpellInfo(spellId)
    if info and info.name then
        local byName = C_Spell.GetSpellInfo(info.name)
        if byName and byName.spellID and KnownExact(byName.spellID) then return byName.spellID end
    end
    return nil
end

--- Last resort: walk the spellbook (what the spellbook window lists) for
--- an active spell with this name. Returns the slot, or nil.
local function BookSlot(spellId)
    if not (C_SpellBook and C_SpellBook.GetNumSpellBookSkillLines) then return nil end
    local info = C_Spell.GetSpellInfo(spellId)
    local name = info and info.name
    if not name then return nil end
    local bank = Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player or 0
    -- the game's own lookup: finds Holy Bulwark (432459) in the book even
    -- though IsPlayerSpell says no
    if C_SpellBook.FindSpellBookSlotForSpell then
        for _, key in ipairs({ spellId, name }) do
            local okF, slot = pcall(C_SpellBook.FindSpellBookSlotForSpell, key)
            if okF and slot then return slot end
        end
    end
    local ok, found = pcall(function()
        for line = 1, C_SpellBook.GetNumSpellBookSkillLines() do
            local li = C_SpellBook.GetSpellBookSkillLineInfo(line)
            if li and not li.offSpecID then
                for slot = li.itemIndexOffset + 1, li.itemIndexOffset + li.numSpellBookItems do
                    local item = C_SpellBook.GetSpellBookItemInfo(slot, bank)
                    if item and item.name == name and not item.isPassive and not item.isOffSpec then
                        return slot
                    end
                end
            end
        end
    end)
    return ok and found or nil
end

local function Known(spellId)
    return Resolve(spellId) ~= nil or BookSlot(spellId) ~= nil
end

--- Put the spell on the cursor, by ID or from its spellbook slot.
local function PickupLayoutSpell(spellId)
    local id = Resolve(spellId)
    if id then C_Spell.PickupSpell(id); return end
    local slot = BookSlot(spellId)
    if slot then
        local bank = Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player or 0
        C_SpellBook.PickupSpellBookItem(slot, bank)
    end
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
            PickupLayoutSpell(id)
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

-- Offer the layout when the one on your bars doesn't match the content:
-- entering a raid, a key or a delve, /ob mode, or swapping talent loadouts
-- outside instances (profiles with contentTalents: Mistweaver's Yu'lon raid
-- build vs Chi-Ji M+ build). "Put your Mythic+ bar layout on your bars?";
-- "Not now" holds until the content changes again. Nothing is asked when
-- the content can't be told (auto mode, outside instances, no tell-tale
-- talents). Your bars are per specialization, so a spec switch only matters
-- for what that spec's bars hold. Waits for the end of combat. Off with the
-- per-spec toggle on Keys & Bars.

local declined   -- content the offer was turned down for, this session
local pending    -- an offer waiting for combat to end

-- Our own little dialog, not Blizzard's StaticPopup: an addon touching
-- StaticPopupDialogs taints the shared popup code, and Blizzard UI that uses
-- it later (the guild rank screen calling IsUserOAuthed) gets blocked with
-- the blame on OffBeat.
local dialog
local function GetDialog()
    if dialog then return dialog end
    local f = CreateFrame("Frame", "OffBeatBarSwapDialog", UIParent, "BackdropTemplate")
    f:SetSize(340, 96)
    f:SetPoint("TOP", UIParent, "TOP", 0, -160)
    f:SetFrameStrata("DIALOG")
    f:SetClampedToScreen(true)
    f:EnableMouse(true)
    f:SetBackdrop(OffBeat.FLAT_BACKDROP or {
        bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    f:SetBackdropColor(0.04, 0.05, 0.07, 0.95)
    f:SetBackdropBorderColor(0.35, 0.70, 1.0, 0.6)
    f.text = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    f.text:SetPoint("TOP", 0, -14)
    f.text:SetWidth(310)
    local function button(label, x, onClick)
        local b = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        b:SetSize(110, 22)
        b:SetPoint("BOTTOM", x, 12)
        b:SetText(label)
        b:SetScript("OnClick", function() f:Hide(); onClick(f.content) end)
        return b
    end
    button(YES or "Yes", -60, function(content)
        OffBeat:ShowBarLayout(true, content == "dungeon" and "mythic" or "raid")
    end)
    button("Not now", 60, function(content) declined = content end)
    f:Hide()
    dialog = f
    return f
end

local function ShowOffer(content)
    local f = GetDialog()
    f.content = content
    f.text:SetText("OffBeat: put your " .. CONTENT_NAMES[content] .. " bar layout on your bars?\n"
        .. "|cff999999Replaces only the layout's slots.|r")
    f:Show()
end

local function HideOffer() if dialog then dialog:Hide() end end

function OffBeat:CheckBarSwap()
    if not (self.db and self.activeProfile and self:BarLayoutHasContent()) then return end
    local ss = SpecSettings()
    if ss.barSwapOffer == false then return end
    local content = self:ContentMode()
    if not content then return end
    if ss.barLayoutContent == content then declined = nil; HideOffer(); return end
    if declined == content then return end
    if InCombatLockdown() then pending = true; return end
    pending = nil
    ShowOffer(content)
end

local watcher = CreateFrame("Frame")
watcher:RegisterEvent("PLAYER_ENTERING_WORLD")
watcher:RegisterEvent("ZONE_CHANGED_NEW_AREA")
watcher:RegisterEvent("PLAYER_REGEN_ENABLED")
watcher:RegisterEvent("PLAYER_REGEN_DISABLED")
watcher:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
watcher:SetScript("OnEvent", function(_, event, unit)
    if event == "PLAYER_REGEN_DISABLED" then
        -- can't change bars in combat: put the question away, ask after
        if dialog and dialog:IsShown() then HideOffer(); pending = true end
        return
    end
    if event == "PLAYER_REGEN_ENABLED" and not pending then return end
    if event == "PLAYER_SPECIALIZATION_CHANGED" and unit ~= "player" then return end
    -- give the profile a moment to load after a spec change or a loading screen
    C_Timer.After(2, function() OffBeat:CheckBarSwap() end)
end)
-- /ob mode, or a loadout swap that changes the build (OffBeat.lua). Its own
-- listener: AceEvent keeps one handler per object and message, so another
-- file registering the same message on OffBeat would replace this one.
local listener = LibStub("AceEvent-3.0"):Embed({})
listener:RegisterMessage("OFFBEAT_CONTENT_MODE_CHANGED", function() OffBeat:CheckBarSwap() end)
