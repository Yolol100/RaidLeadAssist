local _, ns = ...

local AssignmentRegistry = ns:GetModule("Encounters.AssignmentRegistry")

local baseGetLayout = AssignmentRegistry.GetLayout

-- The base assignment registry predates the latest pre-release Ula'tek review.
-- Keep this compatibility overlay narrow until live raid validation settles the
-- Heroic/Mythic mechanic split. The current pre-release plan does not expose
-- Heroic Coil rotation fields or Mass Gestation instructions.
local HEROIC_LAYOUT = {
    summary = "Assign one owner to each Doomscale Egg side; Heroic Coil and Fangs targets stay live and dynamic.",
    sections = {
        {
            key = "eggs",
            title = "Doomscale Eggs",
            description = "Heroic: Doomscale Eggs still need controlled handling. Assign one owner to each side before the pull.",
            columns = 2,
            slots = {
                { key = "egg_left", label = "Left Egg Owner", kind = "assignee", required = true },
                { key = "egg_right", label = "Right Egg Owner", kind = "assignee", required = true },
            },
        },
    },
}

function AssignmentRegistry:GetLayout(bossKey, difficultyKey)
    if bossKey == "ulatek" and difficultyKey == "heroic" then
        return HEROIC_LAYOUT
    end
    return baseGetLayout(self, bossKey, difficultyKey)
end

ns:RegisterModule("Encounters.VenomousAbyss.UlatekAssignmentPolicy", {
    heroicLayout = HEROIC_LAYOUT,
})
