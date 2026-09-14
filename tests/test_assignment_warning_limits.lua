local T = assert(loadfile("tests/testlib.lua"))()
local ns = T.NewNamespace()
_G.issecretvalue = function() return false end

ns:RegisterModule("Services.RosterService", {
    IsRaidRoster = function() return false end,
    GetRoster = function() return {} end,
})

T.Load("Core/Constants.lua", ns)
T.Load("Core/Util.lua", ns)
T.Load("Encounters/Registry.lua", ns)
T.Load("Encounters/AssignmentRegistry.lua", ns)
T.Load("Encounters/Boss78AssignmentOverride.lua", ns)
T.Load("Encounters/VenomousAbyss/Ulatek.lua", ns)
T.Load("Services/AssignmentService.lua", ns)

local Registry = ns:GetModule("Encounters.Registry")
local Assignments = ns:GetModule("Services.AssignmentService")
Assignments:Initialize({ assignments = {} })

local longMelee = "M" .. string.rep("elee", 20)
local longRanged = "R" .. string.rep("ange", 20)
local longHealer = "H" .. string.rep("ealr", 20)
assert(#longMelee <= Assignments.MAX_VALUE_LENGTH)
assert(#longRanged <= Assignments.MAX_VALUE_LENGTH)
assert(#longHealer <= Assignments.MAX_VALUE_LENGTH)

local ok, err = Assignments:ApplyBossDraft("ulatek", "heroic", {
    bite_melee = longMelee,
    bite_ranged = longRanged,
    bite_healer = longHealer,
})
assert(ok, err and err.message or "long but individually valid assignment fields must save")

local bite = Registry:GetProfile("ulatek", "heroic").callsByKey.bite
local warning, ready, reason = Assignments:BuildCallWarning(bite.warning, "ulatek", "heroic", "bite")
assert(warning == nil and ready == false,
    "template-expanded Bite warning above the chat limit must fail closed")
assert(type(reason) == "string" and reason:find("Raid Warning limit", 1, true),
    "oversized template warning must explain the Raid Warning limit")

ok = Assignments:ApplyBossDraft("ulatek", "heroic", {
    bite_melee = "MeleeOne",
    bite_ranged = "RangedOne",
    bite_healer = "HealerOne",
})
assert(ok)
warning, ready = Assignments:BuildCallWarning(bite.warning, "ulatek", "heroic", "bite")
assert(ready and warning == "Bite: MeleeOne; RangedOne; HealerOne soak. Purge out.",
    "Heroic template warning under the limit must still render exactly")
assert(#warning <= Assignments.MAX_WARNING_LENGTH)

_G.issecretvalue = nil
print("ok - template-expanded Heroic assignment warnings enforce the 200-character Raid Warning cap")
