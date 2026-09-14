local T = assert(loadfile("tests/testlib.lua"))()
local ns = T.NewNamespace()

local roster = {}
ns:RegisterModule("Services.RosterService", {
    GetRoster = function() return roster end,
})
T.Load("Services/RaidGroupSplitService.lua", ns)
local Split = ns:GetModule("Services.RaidGroupSplitService")

local function makeRoster(spec)
    local result = {}
    for subgroup, size in pairs(spec) do
        for index = 1, size do
            result[#result + 1] = { name = ("P%d_%d"):format(subgroup, index), subgroup = subgroup }
        end
    end
    return result
end

roster = makeRoster({ [1]=5, [2]=5, [3]=5, [4]=5 })
assert(Split:Describe("RED", "GREEN") == "G1 + G2 = RED — G3 + G4 = GREEN")
assert(Split:Describe("BLUE", "X") == "G1 + G2 = BLUE — G3 + G4 = X")

roster = makeRoster({ [1]=5, [2]=5 })
assert(Split:Describe("RED", "GREEN") == "G1 = RED — G2 = GREEN")

roster = makeRoster({ [1]=5, [2]=3, [3]=4 })
local uneven = assert(Split:BuildSplit(roster))
assert(math.abs(uneven.firstPlayers - uneven.secondPlayers) <= 4, "uneven groups must choose the closest whole-group balance")

roster = makeRoster({ [1]=4, [3]=4, [4]=4 })
local gapped = Split:Describe("RED", "GREEN")
assert(not gapped:find("G2", 1, true), "empty subgroup gaps must never appear in the dynamic split")

local first = Split:Describe("RED", "GREEN")
for _ = 1, 10 do
    assert(Split:Describe("RED", "GREEN") == first, "same roster must always produce the same split")
end

roster = {}
assert(Split:Describe("RED", "GREEN") == nil,
    "empty roster must fail closed instead of inventing G1-G4")
roster = makeRoster({ [2]=5 })
assert(Split:Describe("RED", "GREEN") == nil,
    "single populated subgroup cannot produce a verified two-side split")

print("ok - raid subgroup splitting is populated-group aware, balanced, deterministic and fail-closed")
