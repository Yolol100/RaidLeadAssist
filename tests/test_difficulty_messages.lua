local T = assert(loadfile("tests/testlib.lua"))()
local ns = T.NewNamespace()
_G.issecretvalue = function() return false end

T.Load("Core/Constants.lua", ns)
T.Load("Core/Util.lua", ns)
ns:RegisterModule("Core.EventBus", { Emit = function() end })
T.Load("Encounters/Registry.lua", ns)
for _, file in ipairs({"CoiledAltar.lua","Explorers.lua","Nekzali.lua","Sentinels.lua","Sszorak.lua","TwinFangs.lua","Ulatek.lua","Vashnik.lua"}) do
    T.Load("Encounters/VenomousAbyss/" .. file, ns)
end
T.Load("Services/MessageService.lua", ns)

local Constants = ns:GetModule("Core.Constants")
local Registry = ns:GetModule("Encounters.Registry")
local Messages = ns:GetModule("Services.MessageService")
local db = { selectedDifficultyKey = "heroic", customMessages = {} }
Registry:SetActiveDifficulty("heroic")
Messages:Initialize(db)

assert(Constants.DIFFICULTIES.normal == nil, "Normal must not be an active supported difficulty")
assert(Constants.DIFFICULTY_KEY_BY_ID[14] == nil, "Normal instance difficulty must fail closed")
assert(#Constants.DIFFICULTY_ORDER == 2 and Constants.DIFFICULTY_ORDER[1] == "heroic" and Constants.DIFFICULTY_ORDER[2] == "mythic")

local heroicDefault = Registry:GetProfile("nekzali", "heroic").callsByKey.adds.warning
assert(Messages:SetCallWarning("nekzali", "heroic", "adds", "HEROIC ONLY CALL"))
assert(Messages:GetCallWarning("nekzali", "heroic", "adds") == "HEROIC ONLY CALL")
assert(Messages:GetCallWarning("nekzali", "mythic", "adds") ~= "HEROIC ONLY CALL", "Heroic custom call must not leak into Mythic")

assert(Messages:SetExplanationText("nekzali", "mythic", "MYTHIC CUSTOM PLAN"))
assert(Messages:GetExplanation("nekzali", "mythic")[1] == "MYTHIC CUSTOM PLAN")
assert(Messages:GetExplanation("nekzali", "heroic")[1] ~= "MYTHIC CUSTOM PLAN", "Mythic plan override must not leak into Heroic")

Messages:ResetBoss("nekzali", "heroic")
assert(Messages:GetCallWarning("nekzali", "heroic", "adds") == heroicDefault, "Heroic reset must restore Heroic default")
assert(Messages:GetExplanation("nekzali", "mythic")[1] == "MYTHIC CUSTOM PLAN", "Heroic reset must not wipe Mythic override")

print("ok - Heroic/Mythic message overrides stay isolated and Normal is unsupported")
