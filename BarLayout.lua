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
-- hold just one spell. Spell names come from the game, so it works in any client
-- language. /ob bars apply creates the macro, or rewrites it if it exists.
--
-- Slots are Blizzard's: 1-12 main bar, 61-72 bottom left, 49-60 bottom right,
-- 25-36 right, 37-48 left, 145-180 bars 5-7. `key` is only shown in the plan.
-- /ob bars shows the plan, /ob bars apply places it (out of combat). What was
-- in those slots is replaced; other slots are left alone. Spells you don't
-- know are skipped.

local function Known(spellId)
    local ok, known = pcall(IsPlayerSpell, spellId)
    return ok and known and true or false
end

local function SpellName(spellId)
    local info = C_Spell.GetSpellInfo(spellId)
    return info and info.name or ("spell " .. spellId)
end

local function MacroBody(m)
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
end

function OffBeat:ShowBarLayout(apply)
    local layout = self.activeProfile and self.activeProfile.barLayout
    if not layout then
        self:Print("No bar layout for this spec.")
        return
    end
    if apply and InCombatLockdown() then
        self:Print("Can't change action bars in combat.")
        return
    end

    if not apply then self:Print("Bar layout for " .. self.activeProfile.meta.name .. " (key: spell):") end
    local placed, skipped = 0, {}
    for _, e in ipairs(layout) do
      if e.macro then
        if apply then
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
        self:Print(string.format("Placed %d spells on your bars.%s", placed,
            #skipped > 0 and (" Skipped: " .. table.concat(skipped, ", ") .. ".") or ""))
    else
        self:Print("Type |cffffd100/ob bars apply|r to put these on your bars (replaces what's in those slots).")
    end
end
