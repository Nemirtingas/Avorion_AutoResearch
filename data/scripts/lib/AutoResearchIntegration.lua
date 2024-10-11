-- This file allows to change system upgrade names in cause you don't like auto detected ones

local custom = {}

local function add(scriptName, systemName, extraArguments)
    scriptName = "data/scripts/systems/"..scriptName..".lua"
    custom[scriptName] = { name = systemName, extra = extraArguments }
end
local addSystemUpgrade = add

--[[ Examples:

-- Simple name
add("energybooster", "Generator Upgrade")

-- Complex name. Just replace all these 'num's and 'mark's with something general like "X ".
add("arbitrarytcs", "Turret Control System A-TCS-${num}", {num = "X "})
]]

if GameVersion() >= Version("2.0") then -- making vanilla system names a bit nicer (without losing translation capabilities)
    add("batterybooster", "Battery Booster")
    add("energybooster", "Generator Booster")
    add("enginebooster", "Engine Booster")
    add("hyperspacebooster", "Hyperspace Booster")
    add("miningsystem", "Mining Subsystem")
    add("radarbooster", "Radar Booster")
    add("resistancesystem", "Shield Ionizer")
    add("shieldbooster", "Shield Booster")
    add("shieldimpenetrator", "Shield Impenetrator")
    add("tradingoverview", "Basic Trading Subsystem v${version}.${patch}", {version = "1", patch = "0"})
    add("valuablesdetector", "Object Detector")
end

return custom