local _, ns = ...

local Constants = {
    ADDON_NAME = "Raid Lead Assist",
    RAID_NAME = "THE VENOMOUS ABYSS · HEROIC",
    INSTANCE_ID = 3004,
    HEROIC_DIFFICULTY_ID = 15,

    PREPARE_SECONDS = 5,
    PRESS_SECONDS = 3,
    MANUAL_CLICK_LOCK_SECONDS = 1.25,
    BRIEFING_CLICK_LOCK_SECONDS = 2.0,
    BRIEFING_LINE_DELAY = 0.50,
    CALLED_FEEDBACK_SECONDS = 0.8,
    DUPLICATE_TIMER_TOLERANCE = 2.0,
    TIMER_EXPIRY_GRACE_SECONDS = 1.0,
    ENCOUNTER_REMAP_WINDOW_SECONDS = 3.0,

    PROVIDER_PRIORITY = { "BigWigs", "DBM", "Blizzard" },

    CallState = {
        IDLE = "IDLE",
        PREPARE = "PREPARE",
        PRESS = "PRESS",
        CALLED = "CALLED",
    },
}

ns:RegisterModule("Core.Constants", Constants)
