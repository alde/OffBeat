local OffBeat = _G.OffBeat
local Sheet = OffBeat:NewModule("Sheet", "AceEvent-3.0")

-- A movable rotation cheat sheet (profile.rotationSheet):
--
--   rotationSheet = {
--       { title = "Single target", lines = {
--           { spellId = 445468, alt = { 348 }, text = "Wither: keep it up" },
--           { text = "A tip with no spell" },
--       } },
--       { title = "AoE (3+)", lines = { ... } },
--       { title = "Diabolist", unknown = { 445465 }, lines = { ... } },
--   }
--
-- A section with `known` only shows when you know one of those spells, one
-- with `unknown` only when you know none of them: different sheets for
-- different talent builds (say Hellcaller for raid, Diabolist for M+),
-- switching by themselves when you change loadout. `content = "raid"` or
-- `"dungeon"` limits a section to raids or dungeons; outside instances
-- (dummies, the open world) every section shows.
-- Each line shows the spell's icon, the key it's bound to (read from your
-- bars) and the text. Lines for spells you don't know are hidden; the first
-- known ID of spellId / alt wins. /ob sheet shows or hides it (per spec).
-- Like the other panels it drags while frames are unlocked and lets clicks
-- through while they're locked; the x always works.

local WIDTH = 300
local PAD = 8
local ICON = 16
local KEY_W = 34
local LINE_GAP = 3

local frame
local pool = {}      -- reusable line rows
local headers = {}   -- reusable section headers
local refreshQueued = false

local function GetSpecSettings()
    local profile = OffBeat.activeProfile
    if not profile then return nil end
    local specs = OffBeat.db.profile.specSettings
    specs[profile.meta.specId] = specs[profile.meta.specId] or {}
    return specs[profile.meta.specId]
end

local function GetSpecOr(key)
    local ss = GetSpecSettings()
    if ss and ss[key] ~= nil then return ss[key] end
    return OffBeat.db.profile[key]
end

local function Known(id)
    local ok, known = pcall(IsPlayerSpell, id)
    return ok and known and true or false
end

-- The spell this line is about: first known of spellId / alt, or nil.
local function ResolveSpell(line)
    if not line.spellId then return nil end
    if Known(line.spellId) then return line.spellId end
    for _, a in ipairs(line.alt or {}) do
        if Known(a) then return a end
    end
    return false -- has a spell, none known
end

local function AnyKnown(ids)
    for _, id in ipairs(ids) do
        if Known(id) then return true end
    end
    return false
end

local function InContent(content)
    local ok, inInstance, kind = pcall(IsInInstance)
    if not ok or not inInstance then return true end
    if content == "raid" then return kind == "raid" end
    if content == "dungeon" then return kind == "party" end
    return true
end

local function SectionShown(section)
    if section.content and not InContent(section.content) then return false end
    if section.known and not AnyKnown(section.known) then return false end
    if section.unknown and AnyKnown(section.unknown) then return false end
    return true
end

local function CreatePanel()
    local f = OffBeat:CreateMovableFrame("OffBeatSheet", "sheetPosition", {
        width = WIDTH, height = 100,
        backdrop = {
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
        },
        backdropColor = { 0.04, 0.05, 0.07, 0.82 },
        borderColor = { 0.35, 0.70, 1.0, 0.35 },
        defaultPoint = "LEFT", defaultRelPoint = "LEFT", defaultX = 40, defaultY = 80,
    })

    f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f.title:SetPoint("TOPLEFT", PAD, -PAD)
    f.title:SetJustifyH("LEFT")

    local close = CreateFrame("Button", nil, f, "UIPanelCloseButtonNoScripts")
    close:SetSize(20, 20)
    close:SetPoint("TOPRIGHT", -2, -2)
    close:SetScript("OnClick", function()
        local ss = GetSpecSettings()
        if ss then ss.showSheet = false end
        f:Hide()
        OffBeat:Print("Rotation sheet hidden. |cffffd100/ob sheet|r brings it back.")
    end)

    f.overlay = OffBeat:CreateUnlockOverlay(f, "Rotation Sheet")
    if not OffBeat.db.profile.locked then f.overlay:Show() end
    return f
end

local function GetHeader(i)
    local h = headers[i]
    if not h then
        h = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        h:SetJustifyH("LEFT")
        h:SetTextColor(0.35, 0.70, 1.0)
        headers[i] = h
    end
    h:Show()
    return h
end

local function GetRow(i)
    local r = pool[i]
    if not r then
        r = {}
        r.icon = frame:CreateTexture(nil, "ARTWORK")
        r.icon:SetSize(ICON, ICON)
        r.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        r.key = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        r.key:SetWidth(KEY_W)
        r.key:SetJustifyH("CENTER")
        r.key:SetTextColor(1, 0.82, 0)
        r.text = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        r.text:SetJustifyH("LEFT")
        r.text:SetWordWrap(true)
        r.text:SetWidth(WIDTH - PAD * 2 - ICON - KEY_W - 4)
        pool[i] = r
    end
    r.icon:Show(); r.key:Show(); r.text:Show()
    return r
end

function Sheet:Render()
    local profile = OffBeat.activeProfile
    local sheet = profile and profile.rotationSheet
    if not sheet then return end
    frame = frame or CreatePanel()

    for _, h in ipairs(headers) do h:Hide() end
    for _, r in ipairs(pool) do r.icon:Hide(); r.key:Hide(); r.text:Hide() end

    frame.title:SetText((profile.meta.name or "Rotation") .. " rotation")
    local y = -PAD - 18
    local nh, nr = 0, 0
    for _, section in ipairs(sheet) do
      if SectionShown(section) then
        if section.title then
            nh = nh + 1
            local h = GetHeader(nh)
            h:ClearAllPoints()
            h:SetPoint("TOPLEFT", frame, "TOPLEFT", PAD, y - 4)
            h:SetText(string.upper(section.title))
            y = y - 4 - h:GetStringHeight() - 4
        end
        for _, line in ipairs(section.lines or {}) do
            local id = ResolveSpell(line)
            if id ~= false then
                nr = nr + 1
                local r = GetRow(nr)
                r.icon:ClearAllPoints()
                r.icon:SetPoint("TOPLEFT", frame, "TOPLEFT", PAD, y)
                r.key:ClearAllPoints()
                r.key:SetPoint("LEFT", r.icon, "RIGHT", 2, 0)
                r.text:ClearAllPoints()
                r.text:SetPoint("TOPLEFT", r.icon, "TOPRIGHT", KEY_W + 4, -2)
                if id then
                    local tex = C_Spell.GetSpellTexture(id)
                    r.icon:SetTexture(tex)
                    r.icon:SetAlpha(1)
                    r.key:SetText(OffBeat:GetKeybindForSpell(id) or "|cff666666--|r")
                else
                    r.icon:SetTexture(nil)
                    r.key:SetText("")
                end
                r.text:SetText(line.text or "")
                local h = math.max(ICON, r.text:GetStringHeight() + 2)
                y = y - h - LINE_GAP
            end
        end
      end
    end
    frame:SetHeight(-y + PAD - LINE_GAP)
    self:UpdateVisibility()
end

function Sheet:UpdateVisibility()
    if not frame then return end
    local show = GetSpecOr("showSheet")
    if show and GetSpecOr("sheetHideInCombat") and InCombatLockdown() then show = false end
    frame:SetShown(show and true or false)
end

function Sheet:Toggle()
    if not (OffBeat.activeProfile and OffBeat.activeProfile.rotationSheet) then
        OffBeat:Print("No rotation sheet for this spec yet.")
        return
    end
    local ss = GetSpecSettings()
    ss.showSheet = not GetSpecOr("showSheet")
    self:Render()
end

-- Key labels follow your bars; re-read them shortly after anything changes.
function Sheet:QueueRefresh()
    if refreshQueued then return end
    refreshQueued = true
    C_Timer.After(0.3, function()
        refreshQueued = false
        if Sheet:IsEnabled() and not InCombatLockdown() then Sheet:Render() end
    end)
end

function Sheet:OnEnable()
    self:RegisterEvent("ACTIONBAR_SLOT_CHANGED", "QueueRefresh")
    self:RegisterEvent("UPDATE_BINDINGS", "QueueRefresh")
    self:RegisterEvent("UPDATE_MACROS", "QueueRefresh")
    self:RegisterEvent("PLAYER_TALENT_UPDATE", "QueueRefresh")
    self:RegisterEvent("TRAIT_CONFIG_UPDATED", "QueueRefresh")
    self:RegisterEvent("PLAYER_ENTERING_WORLD", "QueueRefresh")
    self:RegisterEvent("ZONE_CHANGED_NEW_AREA", "QueueRefresh")
    self:RegisterEvent("PLAYER_REGEN_DISABLED", "UpdateVisibility")
    self:RegisterEvent("PLAYER_REGEN_ENABLED", "UpdateVisibility")
    self:RegisterMessage("OFFBEAT_LOCK_CHANGED", "OnLockChanged")
    OffBeat:InvalidateKeybindCache()
    self:Render()
end

function Sheet:OnDisable()
    self:UnregisterAllEvents()
    self:UnregisterAllMessages()
    if frame then frame:Hide() end
end

function Sheet:OnLockChanged(_, locked)
    if frame and frame.overlay then frame.overlay:SetShown(not locked) end
end
