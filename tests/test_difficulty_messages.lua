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

local Registry = ns:GetModule("Encounters.Registry")
local Messages = ns:GetModule("Services.MessageService")
local db = { selectedDifficultyKey = "heroic", customMessages = {} }
Registry:SetActiveDifficulty("heroic")
Messages:Initialize(db)

local normalDefault = Registry:GetProfile("nekzali", "normal").callsByKey.adds.warning
local heroicDefault = Registry:GetProfile("nekzali", "heroic").callsByKey.adds.warning
assert(Messages:SetCallWarning("nekzali", "normal", "adds", "NORMAL ONLY CALL"))
assert(Messages:GetCallWarning("nekzali", "normal", "adds") == "NORMAL ONLY CALL")
assert(Messages:GetCallWarning("nekzali", "heroic", "adds") == heroicDefault, "Normal custom call must not leak into Heroic")
assert(Messages:GetCallWarning("nekzali", "mythic", "adds") ~= "NORMAL ONLY CALL", "Normal custom call must not leak into Mythic")

assert(Messages:SetExplanationText("nekzali", "mythic", "MYTHIC CUSTOM PLAN"))
assert(Messages:GetExplanation("nekzali", "mythic")[1] == "MYTHIC CUSTOM PLAN")
assert(Messages:GetExplanation("nekzali", "normal")[1] ~= "MYTHIC CUSTOM PLAN", "Mythic plan override must not leak into Normal")

Messages:ResetBoss("nekzali", "normal")
assert(Messages:GetCallWarning("nekzali", "normal", "adds") == normalDefault, "Normal reset must restore Normal default")
assert(Messages:GetExplanation("nekzali", "mythic")[1] == "MYTHIC CUSTOM PLAN", "Normal reset must not wipe Mythic override")

print("ok - difficulty-specific message overrides stay isolated")
