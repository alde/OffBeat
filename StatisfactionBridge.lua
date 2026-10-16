local OffBeat = _G.OffBeat

-- Stat priority now lives in the standalone Statisfaction addon. When it is
-- installed, feed it the active profile's priority so profile overrides keep
-- taking precedence over its built-in table: contentStatPriorities for the
-- content you're in (raid / dungeon, from /ob mode), then heroStatPriorities
-- for your hero tree, then statPriority.
local Statisfaction = _G.Statisfaction
if not (Statisfaction and Statisfaction.RegisterPriorityProvider) then return end

Statisfaction:RegisterPriorityProvider("OffBeat", function(specId, heroTree)
    local profile = OffBeat.activeProfile
    if not profile or profile.meta.specId ~= specId then return nil end
    local content = profile.contentStatPriorities and OffBeat:ContentMode()
    local prio = content and profile.contentStatPriorities[content]
    if prio then
        return prio, profile.meta.name .. (content == "raid" and " (raid)" or " (Mythic+)")
    end
    prio = heroTree and profile.heroStatPriorities and profile.heroStatPriorities[heroTree]
    prio = prio or profile.statPriority
    if prio then return prio, profile.meta.name end
end)

-- Runs on every spec change and profile switch, once activeProfile is set.
hooksecurefunc(OffBeat, "EnableAlwaysOnModules", function()
    Statisfaction:RequestRefresh()
end)

-- The content changed: /ob mode, or entering / leaving a raid, a dungeon or a delve.
OffBeat:RegisterMessage("OFFBEAT_CONTENT_MODE_CHANGED", function() Statisfaction:RequestRefresh() end)
local zoneWatcher = CreateFrame("Frame")
zoneWatcher:RegisterEvent("PLAYER_ENTERING_WORLD")
zoneWatcher:SetScript("OnEvent", function() Statisfaction:RequestRefresh() end)
