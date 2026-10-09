local OffBeat = _G.OffBeat

-- Puts a profile's spells on your action bars (profile.barLayout):
--
--   barLayout = {
--       { slot = 1,  key = "1", spellId = 55090 },   -- action slot, key it's bound to, spell
--       { slot = 7,  key = "G", spellId = 1271967, alt = { 1271974 } }, -- first known ID wins
--       ...
--   }
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

    if apply then
        self:Print(string.format("Placed %d spells on your bars.%s", placed,
            #skipped > 0 and (" Skipped (not known): " .. table.concat(skipped, ", ") .. ".") or ""))
    else
        self:Print("Type |cffffd100/ob bars apply|r to put these on your bars (replaces what's in those slots).")
    end
end
