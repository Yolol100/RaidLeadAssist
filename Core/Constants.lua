local _, ns = ...

local Constants = {
    ADDON_NAME = "Raid Lead Assist",
    RAID_NAME = "THE VENOMOUS ABYSS",
    INSTANCE_ID = 3004,

    HEROIC_DIFFICULTY_ID = 15,
    MYTHIC_DIFFICULTY_ID = 16,

    DIFFICULTY_ORDER = { "heroic", "mythic" },
    DIFFICULTIES = {
        heroic = { key = "heroic", name = "Heroic", label = "HEROIC", id = 15 },
        mythic = { key = "mythic", name = "Mythic", label = "MYTHIC", id = 16 },
    },
    DIFFICULTY_KEY_BY_ID = {
        [15] = "heroic",
        [16] = "mythic",
    },

    PREPARE_SECONDS = 5,
    PRESS_SECONDS = 3,
    MIN_PREPARE_SECONDS = 2,
    MAX_PREPARE_SECONDS = 30,
    MIN_PRESS_SECONDS = 1,
    MAX_PRESS_SECONDS = 10,
    MANUAL_CLICK_LOCK_SECONDS = 1.25,
    BRIEFING_CLICK_LOCK_SECONDS = 2.0,
    BRIEFING_LINE_DELAY = 0.50,
    CALLED_FEEDBACK_SECONDS = 0.8,
    DUPLICATE_TIMER_TOLERANCE = 5.0,
    RECENT_ACKNOWLEDGEMENT_SECONDS = 8.0,
    TIMER_EXPIRY_GRACE_SECONDS = 1.0,
    ENCOUNTER_REMAP_WINDOW_SECONDS = 3.0,

    -- DBM is the primary bossmod source for this deployment. BigWigs remains a
    -- fully supported optional source, while Blizzard is the native fallback.
    PROVIDER_PRIORITY = { "DBM", "BigWigs", "Blizzard" },

    TimerPrecision = {
        NATIVE = "native",
        EXACT = "exact",
        APPROXIMATE = "approximate",
    },

    CallState = {
        IDLE = "IDLE",
        WAIT = "WAIT",
        PREPARE = "PREPARE",
        PRESS = "PRESS",
        LATE = "LATE",
        CALLED = "CALLED",
    },
}

local secretPredicate = _G.issecretvalue

local function finite(value)
    return type(value) == "number" and value == value and value > -math.huge and value < math.huge
end

local function numeric(value)
    if secretPredicate and secretPredicate(value) then return nil end
    if type(value) == "number" then return value end
    if type(value) == "string" then return tonumber(value) end
    return nil
end

function Constants.NormalizeTimingLead(value)
    if type(value) ~= "table" then
        return Constants.PREPARE_SECONDS, Constants.PRESS_SECONDS, false
    end
    local prepare = numeric(value.prepare)
    local press = numeric(value.press)
    if not finite(prepare) or not finite(press)
        or prepare < Constants.MIN_PREPARE_SECONDS or prepare > Constants.MAX_PREPARE_SECONDS
        or press < Constants.MIN_PRESS_SECONDS or press > Constants.MAX_PRESS_SECONDS
        or prepare <= press then
        return Constants.PREPARE_SECONDS, Constants.PRESS_SECONDS, false
    end
    return prepare, press, true
end

function Constants.GetCallTiming(call, timingLead)
    if timingLead == nil and type(_G.RaidLeadAssistDB) == "table" then
        timingLead = _G.RaidLeadAssistDB.timingLead
    end
    local configuredPrepare, configuredPress = Constants.NormalizeTimingLead(timingLead)
    local prepare = type(call) == "table" and numeric(call.prepareSeconds) or nil
    local press = type(call) == "table" and numeric(call.pressSeconds) or nil
    if not finite(prepare) then prepare = configuredPrepare end
    if not finite(press) then press = configuredPress end

    -- A malformed encounter override must never invert the warning windows.
    -- Fall back to the validated user/default pair instead of guessing intent.
    if prepare < Constants.MIN_PREPARE_SECONDS or prepare > Constants.MAX_PREPARE_SECONDS
        or press < Constants.MIN_PRESS_SECONDS or press > Constants.MAX_PRESS_SECONDS
        or prepare <= press then
        return configuredPrepare, configuredPress
    end
    return prepare, press
end

-- Legacy call-state helper retained for compatibility with existing consumers.
-- It intentionally has no WAIT/LATE presentation state.
function Constants.GetCallState(call, remaining, actionable, timingLead)
    if actionable == false or type(remaining) ~= "number" then
        return Constants.CallState.IDLE
    end

    local prepare, press = Constants.GetCallTiming(call, timingLead)
    if remaining <= press then return Constants.CallState.PRESS end
    if remaining <= prepare then return Constants.CallState.PREPARE end
    return Constants.CallState.IDLE
end

-- Guidance uses signed remaining time. Automatic guidance is only allowed for
-- an already-verified actionable timer. Far-away mechanics are WAIT, the prepare
-- window is presented as SOON, the press window as PRESS NOW, and a just-missed
-- occurrence stays visibly LATE only for the bounded expiry grace.
function Constants.GetGuidanceState(call, signedRemaining, actionable, timingLead)
    if actionable ~= true or not finite(signedRemaining) then
        return Constants.CallState.IDLE
    end

    if signedRemaining < 0 then
        if signedRemaining >= -Constants.TIMER_EXPIRY_GRACE_SECONDS then
            return Constants.CallState.LATE
        end
        return Constants.CallState.IDLE
    end

    local prepare, press = Constants.GetCallTiming(call, timingLead)
    if signedRemaining <= press then return Constants.CallState.PRESS end
    if signedRemaining <= prepare then return Constants.CallState.PREPARE end
    return Constants.CallState.WAIT
end

ns:RegisterModule("Core.Constants", Constants)
