local T = assert(loadfile("tests/testlib.lua"))()

local function newRegistry()
    local ns = T.NewNamespace()
    T.Load("Core/Constants.lua", ns)
    T.Load("Core/Util.lua", ns)
    T.Load("Encounters/Registry.lua", ns)
    return ns:GetModule("Encounters.Registry")
end

local function definition(call)
    local function profile()
        local copy = {}
        for key, value in pairs(call) do copy[key] = value end
        return { explanation = { "PLAN" }, calls = { copy } }
    end
    return {
        key = "boss",
        name = "Boss",
        encounterID = 1234,
        strategyStatus = "test source",
        profiles = {
            normal = profile(),
            heroic = profile(),
            mythic = profile(),
        },
    }
end

_G.issecretvalue = function() return false end

local Registry = newRegistry()
assert(pcall(function()
    Registry:Register(definition({
        key = "manual", ability = "Manual", action = "Do it", warning = "DO IT", timing = false,
    }))
end), "manual calls must not require timer identities")

Registry = newRegistry()
assert(pcall(function()
    Registry:Register(definition({
        key = "timed", ability = "Timed", action = "Do it", warning = "DO IT", spellIDs = { 123 },
    }))
end), "positive spell IDs must remain valid timer identities")

for _, badCall in ipairs({
    { key = "empty-spells", ability = "Timed", action = "Do it", warning = "DO IT", spellIDs = {} },
    { key = "empty-names", ability = "Timed", action = "Do it", warning = "DO IT", timerNames = {} },
    { key = "bad-spell", ability = "Timed", action = "Do it", warning = "DO IT", spellIDs = { -1 } },
    { key = "bad-name", ability = "Timed", action = "Do it", warning = "DO IT", timerNames = { "" } },
}) do
    Registry = newRegistry()
    local ok = pcall(function() Registry:Register(definition(badCall)) end)
    assert(ok == false, "invalid or empty timed identities must fail registration")
end

Registry = newRegistry()
local badDefinition = definition({
    key = "manual", ability = "Manual", action = "Do it", warning = "DO IT", timing = false,
})
badDefinition.encounterID = 0
assert(pcall(function() Registry:Register(badDefinition) end) == false,
    "encounters without a positive encounter identity must fail registration")

Registry = newRegistry()
badDefinition = definition({
    key = "manual", ability = "Manual", action = "Do it", warning = "DO IT", timing = false,
})
badDefinition.strategyStatus = ""
assert(pcall(function() Registry:Register(badDefinition) end) == false,
    "encounters without source/status metadata must fail registration")

print("ok - encounter registry requires encounter/source metadata and usable public timer identities")
