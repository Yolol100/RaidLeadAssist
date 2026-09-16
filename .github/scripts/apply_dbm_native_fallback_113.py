from pathlib import Path


def replace_once(text, old, new, label):
    if old not in text:
        raise SystemExit(f"Expected block not found: {label}")
    return text.replace(old, new, 1)


timeline_path = Path("Services/TimelineService.lua")
timeline = timeline_path.read_text(encoding="utf-8")

old_block = '''function TimelineService:HasDirectBossmodTimerForCall(call)
    if type(call) ~= "table" or type(call.key) ~= "string" or call.key == "" then return false end
    local now = GetTime()
    for _, timer in pairs(self.timers) do
        if timer.call and timer.call.key == call.key
            and not isBlizzardRepresentation(timer.providerName, timer)
            and (timer.paused == true or (isFiniteNumber(timer.expiration) and timer.expiration > now)) then
            return true
        end
    end
    return false
end

function TimelineService:CanUseSuppressedBlizzardFallback(data)
    if not self.encounterKey or type(data) ~= "table" then return false end
    local call = Registry:MatchCall(self.encounterKey, publicValue(data.key), publicValue(data.name))
    return call ~= nil and not self:HasDirectBossmodTimerForCall(call)
end
'''

new_block = '''function TimelineService:HasActionableDirectBossmodTimerForCall(call)
    if type(call) ~= "table" or type(call.key) ~= "string" or call.key == "" then return false end
    local now = GetTime()
    for _, timer in pairs(self.timers) do
        if timer.call and timer.call.key == call.key
            and not isBlizzardRepresentation(timer.providerName, timer)
            and self:IsActionable(timer)
            and (timer.paused == true or (isFiniteNumber(timer.expiration) and timer.expiration > now)) then
            return true
        end
    end
    return false
end

function TimelineService:CanUseSuppressedBlizzardFallback(data)
    if not self.encounterKey or type(data) ~= "table" then return false end
    local call = Registry:MatchCall(self.encounterKey, publicValue(data.key), publicValue(data.name))

    -- DBM intentionally classifies cd/cdcount timers as cooldown estimates while
    -- next/cast timers can be exact. When DBM asks consumers to ignore Blizzard's
    -- timeline, do not let a non-actionable approximate DBM bar suppress the
    -- native exact timeline event RLA needs for PRESS/PREPARE guidance. This keeps
    -- the DBM-only setup fail-closed: exact DBM wins when available, otherwise the
    -- matching Blizzard-native event remains the authoritative fallback.
    return call ~= nil and not self:HasActionableDirectBossmodTimerForCall(call)
end
'''

timeline = replace_once(timeline, old_block, new_block, "bossmod/native fallback helper")
timeline = replace_once(
    timeline,
    'and (not timer.call or self:HasDirectBossmodTimerForCall(timer.call)) then',
    'and (not timer.call or self:HasActionableDirectBossmodTimerForCall(timer.call)) then',
    "suppression cleanup",
)
timeline_path.write_text(timeline, encoding="utf-8")

toc_path = Path("RaidLeadAssist.toc")
toc = toc_path.read_text(encoding="utf-8")
toc = replace_once(toc, "## Version: 1.1.2", "## Version: 1.1.3", "toc version")
toc_path.write_text(toc, encoding="utf-8")

validation_path = Path(".github/workflows/validation.yml")
validation = validation_path.read_text(encoding="utf-8")
validation = replace_once(validation, "grep -q '^## Version: 1.1.2$' RaidLeadAssist.toc", "grep -q '^## Version: 1.1.3$' RaidLeadAssist.toc", "validation version")
anchor = "          grep -q 'iconSpellID = 1310099' Encounters/VenomousAbyss/TwinFangs.lua\n"
insert = anchor + "          grep -q 'HasActionableDirectBossmodTimerForCall' Services/TimelineService.lua\n          grep -q 'and self:IsActionable(timer)' Services/TimelineService.lua\n          grep -q 'matching Blizzard-native event remains the authoritative fallback' Services/TimelineService.lua\n"
validation = replace_once(validation, anchor, insert, "DBM fallback validation guards")
validation_path.write_text(validation, encoding="utf-8")
