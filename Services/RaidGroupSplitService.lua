local _, ns = ...

local Roster = ns:GetModule("Services.RosterService")

local RaidGroupSplit = {}

local function groupCounts(roster)
    local counts = {}
    for index = 1, #(roster or {}) do
        local subgroup = tonumber(roster[index].subgroup)
        if subgroup and subgroup >= 1 and subgroup <= 8 then
            counts[subgroup] = (counts[subgroup] or 0) + 1
        end
    end

    local groups = {}
    for subgroup = 1, 8 do
        if counts[subgroup] and counts[subgroup] > 0 then groups[#groups + 1] = subgroup end
    end
    return groups, counts
end

local function copyList(source)
    local result = {}
    for index = 1, #source do result[index] = source[index] end
    return result
end

local function lexicographicallyLess(first, second)
    if not second then return true end
    local limit = math.min(#first, #second)
    for index = 1, limit do
        if first[index] ~= second[index] then return first[index] < second[index] end
    end
    return #first < #second
end

function RaidGroupSplit:BuildSplit(roster)
    if roster == nil then roster = Roster:GetRoster() end
    local groups, counts = groupCounts(roster)
    if #groups < 2 then return nil end

    local totalPlayers = 0
    for index = 1, #groups do totalPlayers = totalPlayers + counts[groups[index]] end

    local best
    local maxMask = (2 ^ #groups) - 1
    for mask = 1, maxMask - 1 do
        -- Side A always owns the lowest populated subgroup. This removes the
        -- mirrored duplicate and makes equal-score choices deterministic.
        if mask % 2 == 1 then
            local first, second = {}, {}
            local firstPlayers = 0
            for index = 1, #groups do
                local bit = 2 ^ (index - 1)
                local subgroup = groups[index]
                if math.floor(mask / bit) % 2 == 1 then
                    first[#first + 1] = subgroup
                    firstPlayers = firstPlayers + counts[subgroup]
                else
                    second[#second + 1] = subgroup
                end
            end

            if #first > 0 and #second > 0 then
                local secondPlayers = totalPlayers - firstPlayers
                local playerDiff = math.abs(firstPlayers - secondPlayers)
                local groupDiff = math.abs(#first - #second)
                local better = not best
                    or playerDiff < best.playerDiff
                    or (playerDiff == best.playerDiff and groupDiff < best.groupDiff)
                    or (playerDiff == best.playerDiff and groupDiff == best.groupDiff
                        and lexicographicallyLess(first, best.firstGroups))
                if better then
                    best = {
                        firstGroups = copyList(first),
                        secondGroups = copyList(second),
                        firstPlayers = firstPlayers,
                        secondPlayers = secondPlayers,
                        playerDiff = playerDiff,
                        groupDiff = groupDiff,
                    }
                end
            end
        end
    end

    return best
end

function RaidGroupSplit:FormatGroups(groups)
    local parts = {}
    for index = 1, #(groups or {}) do parts[#parts + 1] = "G" .. tostring(groups[index]) end
    return table.concat(parts, " + ")
end

function RaidGroupSplit:Describe(firstLabel, secondLabel, roster)
    firstLabel = tostring(firstLabel or "A")
    secondLabel = tostring(secondLabel or "B")
    local split = self:BuildSplit(roster)
    if not split then
        -- This fallback is only for preview/out-of-raid state where there is no
        -- authoritative multi-group roster. Real raid briefings resolve against
        -- the populated subgroups returned by the WoW roster API.
        return ("G1 + G2 = %s — G3 + G4 = %s"):format(firstLabel, secondLabel)
    end
    return ("%s = %s — %s = %s"):format(
        self:FormatGroups(split.firstGroups), firstLabel,
        self:FormatGroups(split.secondGroups), secondLabel
    )
end

ns:RegisterModule("Services.RaidGroupSplitService", RaidGroupSplit)
