local OffBeat = _G.OffBeat

-- Stat priority now lives in the standalone Statisfaction addon. When it is
-- installed, feed it the active profile's statPriority / heroStatPriorities so
-- profile overrides keep taking precedence over its built-in table.
local Statisfaction = _G.Statisfaction
if not (Statisfaction and Statisfaction.RegisterPriorityProvider) then return end

Statisfaction:RegisterPriorityProvider("OffBeat", function(specId, heroTree)
    local profile = OffBeat.activeProfile
    if not profile or profile.meta.specId ~= specId then return nil end
    local prio = heroTree and profile.heroStatPriorities and profile.heroStatPriorities[heroTree]
    prio = prio or profile.statPriority
    if prio then return prio, profile.meta.name end
end)

-- Runs on every spec change and profile switch, once activeProfile is set.
hooksecurefunc(OffBeat, "EnableAlwaysOnModules", function()
    Statisfaction:RequestRefresh()
end)
