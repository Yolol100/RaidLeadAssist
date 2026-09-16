local jsonEscape = function(value)
    value = tostring(value)
    value = value:gsub('\\', '\\\\'):gsub('"', '\\"'):gsub('\n', '\\n'):gsub('\r', '\\r'):gsub('\t', '\\t')
    return '"' .. value .. '"'
end

local total, passed = 0, 0
local failures = {}
local fingerprints = {}
local categoryCounts = {}

local function stable(value)
    local t = type(value)
    if t == 'nil' then return 'null' end
    if t == 'boolean' or t == 'number' then return tostring(value) end
    if t == 'string' then return value end
    if t == 'table' then
        local keys = {}
        for k in pairs(value) do keys[#keys + 1] = k end
        table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
        local parts = {}
        for _, k in ipairs(keys) do parts[#parts + 1] = tostring(k) .. '=' .. stable(value[k]) end
        return '{' .. table.concat(parts, ',') .. '}'
    end
    return '<' .. t .. '>'
end

local function record(category, component, preconditions, inputValue, expected, fn)
    local fingerprint = table.concat({
        'controlled_runtime', category, component, 'addon-runtime',
        stable(preconditions), stable(inputValue), stable(expected), 'lua5.4-wow-doubles'
    }, '|')
    if fingerprints[fingerprint] then error('duplicate scenario fingerprint: ' .. fingerprint) end
    fingerprints[fingerprint] = true
    total = total + 1
    categoryCounts[category] = (categoryCounts[category] or 0) + 1
    local ok, err = pcall(fn)
    if ok then
        passed = passed + 1
    else
        failures[#failures + 1] = { category=category, component=component, fingerprint=fingerprint, error=tostring(err) }
    end
end

local function newNS()
    local ns = { modules = {}, version = 'audit' }
    function ns:RegisterModule(name, module) self.modules[name] = module end
    function ns:GetModule(name) assert(self.modules[name], 'missing module ' .. tostring(name)); return self.modules[name] end
    function ns:Print() end
    return ns
end

local function loadModule(path, ns)
    local chunk, err = loadfile(path)
    assert(chunk, err)
    return chunk('RaidLeadAssist', ns)
end

_G.issecretvalue = nil
_G.C_Spell = { GetSpellTexture = function(id) return tonumber(id) and (1000000 + tonumber(id)) or nil end }
_G.GetSpellTexture = function(id) return tonumber(id) and (1000000 + tonumber(id)) or nil end
_G.GetTime = function() return 100 end

-- Shared real Constants/Util modules.
local ns = newNS()
loadModule('Core/Constants.lua', ns)
loadModule('Core/Util.lua', ns)
local Constants = ns:GetModule('Core.Constants')
local Util = ns:GetModule('Core.Util')

local function expectedTiming(prepare, press)
    local p = tonumber(prepare)
    local r = tonumber(press)
    if not p or not r or p ~= p or r ~= r or p < 2 or p > 30 or r < 1 or r > 10 or p <= r then
        return 5, 3
    end
    return p, r
end

local function expectedGuidance(prepare, press, remaining, actionable)
    if actionable ~= true or type(remaining) ~= 'number' or remaining ~= remaining or remaining == math.huge or remaining == -math.huge then
        return 'IDLE'
    end
    if remaining < 0 then return remaining >= -1 and 'LATE' or 'IDLE' end
    local p, r = expectedTiming(prepare, press)
    if remaining <= r then return 'PRESS' end
    if remaining <= p then return 'PREPARE' end
    return 'WAIT'
end

-- 1) Timing state matrix: malformed overrides, every important signed boundary and actionable/non-actionable state.
local prepares = { -1, 2, 3, 5, 10, 30, 31 }
local presses = { 0, 1, 2, 3, 10, 11 }
local remainings = { -2, -1.01, -1, -0.5, -0.001, 0, 0.5, 1, 2, 3, 4, 5, 6, 9, 10, 11, 29, 30, 31 }
local actionables = { true, false }
for _, prepare in ipairs(prepares) do
    for _, press in ipairs(presses) do
        for _, remaining in ipairs(remainings) do
            for _, actionable in ipairs(actionables) do
                local expected = expectedGuidance(prepare, press, remaining, actionable)
                record('timing-guidance', 'Core.Constants', {prepare=prepare,press=press}, {remaining=remaining,actionable=actionable}, expected, function()
                    local actual = Constants.GetGuidanceState({prepareSeconds=prepare,pressSeconds=press}, remaining, actionable, {prepare=5,press=3})
                    assert(actual == expected, ('expected %s got %s'):format(expected, tostring(actual)))
                end)
            end
        end
    end
end

-- 2) Database migration/state-normalization matrix using the real Database module per scenario.
local schemaCases = { 0, 3, 7, 8, 9 }
local difficultyCases = { 'heroic', 'mythic', 'normal', '', false }
local timingCases = {
    {label='valid-default', value={prepare=5,press=3}, expected={prepare=5,press=3}},
    {label='valid-wide', value={prepare=20,press=8}, expected={prepare=20,press=8}},
    {label='inverted', value={prepare=2,press=3}, expected={prepare=5,press=3}},
    {label='out-of-range', value={prepare=31,press=0}, expected={prepare=5,press=3}},
    {label='wrong-type', value='bad', expected={prepare=5,press=3}},
}
local counterCases = {
    {label='missing', boss=nil, macro=nil, eb=8, em=12},
    {label='behind', boss=1, macro=1, eb=8, em=12},
    {label='ahead', boss=30, macro=40, eb=30, em=40},
    {label='invalid', boss='bad', macro=-1, eb=8, em=12},
}
for _, schema in ipairs(schemaCases) do
    for _, difficulty in ipairs(difficultyCases) do
        for _, timingCase in ipairs(timingCases) do
            for _, counters in ipairs(counterCases) do
                record('database-migration', 'Core.Database', {schema=schema,difficulty=difficulty,timing=timingCase.label}, {nextBossId=counters.boss,nextMacroId=counters.macro}, {boss=counters.eb,macro=counters.em}, function()
                    local localNS = newNS()
                    loadModule('Core/Util.lua', localNS)
                    _G.RaidLeadAssistDB = {
                        schemaVersion = schema,
                        selectedDifficultyKey = difficulty,
                        timingLead = timingCase.value,
                        nextBossId = counters.boss,
                        nextMacroId = counters.macro,
                        bossProfiles = {
                            ['custom:7'] = {id='custom:7', order=1, macros={{id=11,name='x',body='/rw x'}}},
                        },
                        position = {point='CENTER',relativePoint='CENTER',x=0,y=40},
                    }
                    loadModule('Core/Database.lua', localNS)
                    local Database = localNS:GetModule('Core.Database')
                    Database:Initialize()
                    local db = Database:Get()
                    local expectedDifficulty = (difficulty == 'heroic' or difficulty == 'mythic') and difficulty or 'heroic'
                    assert(db.selectedDifficultyKey == expectedDifficulty, 'difficulty normalization failed')
                    assert(db.timingLead.prepare == timingCase.expected.prepare and db.timingLead.press == timingCase.expected.press, 'timingLead normalization failed')
                    assert(db.nextBossId == counters.eb, ('nextBossId expected %s got %s'):format(counters.eb, tostring(db.nextBossId)))
                    assert(db.nextMacroId == counters.em, ('nextMacroId expected %s got %s'):format(counters.em, tostring(db.nextMacroId)))
                    if schema <= 8 then assert(db.schemaVersion == 8, 'schema was not migrated to 8') else assert(db.schemaVersion == 9, 'newer schema marker not preserved') end
                end)
            end
        end
    end
end

-- Real BossMacroService with a minimal Registry oracle.
local Registry = {
    GetOrdered = function() return {} end,
    GetProfile = function() return nil end,
}
ns:RegisterModule('Encounters.Registry', Registry)
loadModule('Services/BossMacroService.lua', ns)
local BossMacros = ns:GetModule('Services.BossMacroService')

local nameCases = {
    {label='empty', value=''},
    {label='spaces', value='   '},
    {label='short', value='Soak'},
    {label='exact16', value='1234567890ABCDEF'},
    {label='long', value='1234567890ABCDEFGH'},
}
local bodyCases = {
    {label='empty', value=''},
    {label='rw', value='/rw Go'},
    {label='say', value='/s Move now'},
    {label='multi', value='/rw One\n/y Two'},
}
local iconModes = { 'ability', 'custom', 'other' }
local timingPairs = {
    {label='default', prepare=5, press=3},
    {label='tight', prepare=2, press=1},
    {label='wide', prepare=30, press=10},
    {label='inverted', prepare=2, press=3},
    {label='range', prepare=31, press=0},
}
local spellCases = {
    {label='none', value={}},
    {label='numeric', value={123}},
    {label='numeric-string', value={'456'}},
}
local timingEnabledCases = { true, false }

-- 3) Boss macro update matrix: persistence validation, truncation, timing fallback, icon mode and spell identity.
for _, nameCase in ipairs(nameCases) do
    for _, bodyCase in ipairs(bodyCases) do
        for _, iconMode in ipairs(iconModes) do
            for _, pair in ipairs(timingPairs) do
                for _, spellCase in ipairs(spellCases) do
                    for _, timingEnabled in ipairs(timingEnabledCases) do
                        record('boss-macro-update', 'Services.BossMacroService', {name=nameCase.label,body=bodyCase.label,iconMode=iconMode}, {timing=pair.label,spell=spellCase.label,enabled=timingEnabled}, 'validated-update', function()
                            local macro = {id=1,name='Original',body='/rw Original',spellIDs={},timerNames={},iconMode='custom',customIcon=134400,timingEnabled=false,prepareSeconds=5,pressSeconds=3}
                            BossMacros.database = {
                                timingLead={prepare=5,press=3},
                                selectedDifficultyKey='heroic',
                                bossProfiles={ ['custom:1']={id='custom:1',name='Boss',macros={macro}} },
                            }
                            local draft = {
                                name=nameCase.value,
                                body=bodyCase.value,
                                iconMode=iconMode,
                                customIcon=222,
                                spellIDs=spellCase.value,
                                timerNames={'Timer'},
                                timingEnabled=timingEnabled,
                                prepareSeconds=pair.prepare,
                                pressSeconds=pair.press,
                            }
                            local ok, result = BossMacros:UpdateMacro('custom:1', 1, draft)
                            local valid = type(nameCase.value) == 'string' and nameCase.value:match('^%s*(.-)%s*$') ~= '' and bodyCase.value ~= ''
                            if not valid then
                                assert(ok == false, 'invalid macro unexpectedly accepted')
                                return
                            end
                            assert(ok == true and result == macro, 'valid macro rejected')
                            local trimmed = nameCase.value:match('^%s*(.-)%s*$')
                            assert(macro.name == trimmed:sub(1,16), 'name persistence/truncation mismatch')
                            assert(macro.body == bodyCase.value, 'body mismatch')
                            assert(macro.iconMode == (iconMode == 'ability' and 'ability' or 'custom'), 'icon mode normalization mismatch')
                            assert(macro.timingEnabled == timingEnabled, 'timing enabled mismatch')
                            local ep, er = expectedTiming(pair.prepare, pair.press)
                            assert(macro.prepareSeconds == ep and macro.pressSeconds == er, 'timing normalization mismatch')
                            assert(#macro.spellIDs == #spellCase.value, 'spell array length mismatch')
                            for i=1,#spellCase.value do assert(macro.spellIDs[i] == spellCase.value[i], 'spell array copy mismatch') end
                        end)
                    end
                end
            end
        end
    end
end

-- 4) Managed macro hard-limit matrix using the real marker format and real ValidateMacro implementation.
_G.Constants = { MacroConsts = { MAX_MACRO_LENGTH=255, MAX_ACCOUNT_MACROS=120 } }
loadModule('Services/ManagedMacroService.lua', ns)
local Managed = ns:GetModule('Services.ManagedMacroService')
local macroIds = { 1, 9, 10, 99, 100, 999, 1000, 9999 }
for _, macroId in ipairs(macroIds) do
    for bodyLength = 0, 260 do
        record('managed-macro-limit', 'Services.ManagedMacroService', {macroId=macroId}, {bodyLength=bodyLength}, 'body-plus-marker<=255', function()
            local body = string.rep('x', bodyLength)
            local marker = ('/run RLA_P(%d)'):format(macroId)
            local managedLength = bodyLength == 0 and #marker or (bodyLength + 1 + #marker)
            local expected = managedLength <= 255
            local ok, value = Managed:ValidateMacro({id=macroId,name='M',body=body})
            assert(ok == expected, ('managed length %d expected validity %s got %s (%s)'):format(managedLength,tostring(expected),tostring(ok),tostring(value)))
        end)
    end
end

-- 5) Timer identity matching matrix: call key, numeric identity and normalized timer-name fallbacks.
local sourceKeys = { false, 'ability' }
local timerCallKeys = { false, 'ability', 'other' }
local macroSpellCases = { {}, {123}, {'123'} }
local timerKeys = { false, 123, 124 }
local macroTimerNameCases = { {}, {'Shadow Nova'}, {'Raging Crosswinds'} }
local timerNames = { 'Shadow Nova', '|cffffffffShadow Nova|r', 'Shadow Nova (2)', 'Raging Crosswinds', 'Other' }
local function normalizeTimerName(v)
    if type(v) ~= 'string' then return nil end
    v=v:gsub('|c%x%x%x%x%x%x%x%x',''):gsub('|r',''):gsub('|T.-|t',''):gsub('|A.-|a',''):gsub('^%s*%[B%]%s*',''):gsub('%s+%(%d+%)%s*$',''):gsub('%s+#%d+%s*$','')
    return v:lower():gsub('[^%w]','')
end
for _, sourceKey in ipairs(sourceKeys) do
    for _, timerCallKey in ipairs(timerCallKeys) do
        for spellIndex, macroSpells in ipairs(macroSpellCases) do
            for _, timerKey in ipairs(timerKeys) do
                for nameIndex, macroTimerNames in ipairs(macroTimerNameCases) do
                    for _, timerName in ipairs(timerNames) do
                        record('timer-matching', 'Services.BossMacroService', {sourceKey=sourceKey,spellCase=spellIndex,nameCase=nameIndex}, {timerCall=timerCallKey,timerKey=timerKey,timerName=timerName}, 'call-or-spell-or-normalized-name', function()
                            local macro = {sourceCallKey=sourceKey or nil,spellIDs=macroSpells,timerNames=macroTimerNames}
                            local timer = {call=timerCallKey and {key=timerCallKey} or nil,key=timerKey or nil,name=timerName}
                            local expected = false
                            if sourceKey and timerCallKey == sourceKey then expected = true end
                            if not expected and (timerKey == 123) and (#macroSpells > 0) and tonumber(macroSpells[1]) == 123 then expected = true end
                            if not expected then
                                local normalized = normalizeTimerName(timerName)
                                for _, candidate in ipairs(macroTimerNames) do if normalizeTimerName(candidate) == normalized then expected = true end end
                            end
                            local actual = BossMacros:TimerMatchesMacro({id='boss'}, macro, timer)
                            assert(actual == expected, ('expected %s got %s'):format(tostring(expected), tostring(actual)))
                        end)
                    end
                end
            end
        end
    end
end

-- 6) Ability catalog independence: registry-backed choices survive macro CRUD and prefer the active difficulty variant.
local abilityProfiles = {
    heroic = { calls = {
        {key='shared', ability='Heroic Shared', spellIDs={101}, prepareSeconds=7, pressSeconds=4},
        {key='heroic_only', ability='Heroic Only', spellIDs={102}, timing=false},
    } },
    mythic = { calls = {
        {key='shared', ability='Mythic Shared', spellIDs={201}, prepareSeconds=8, pressSeconds=5},
        {key='mythic_only', ability='Mythic Only', spellIDs={202}, timing=false},
    } },
}
Registry.GetProfile = function(_, encounterKey, difficultyKey)
    if encounterKey ~= 'catalogboss' then return nil end
    return abilityProfiles[difficultyKey]
end
local macroStates = {
    {label='empty', macros={}},
    {label='unrelated', macros={{id=8,name='Custom',body='/rw Custom',sourceCallKey=nil}}},
    {label='after-delete', macros={}},
}
for _, difficulty in ipairs({'heroic','mythic'}) do
    for _, macroState in ipairs(macroStates) do
        record('ability-catalog', 'Services.BossMacroService', {difficulty=difficulty,macroState=macroState.label}, 'GetAbilityOptions', 'registry-backed-options-remain', function()
  assert(type(BossMacros.GetAbilityOptions) == 'function', 'BossMacroService has no independent ability catalog')
  BossMacros.database = {
      selectedDifficultyKey=difficulty,
      timingLead={prepare=5,press=3},
      bossProfiles={ ['encounter:catalogboss']={id='encounter:catalogboss',sourceEncounterKey='catalogboss',macros=macroState.macros} },
  }
  local options = BossMacros:GetAbilityOptions('encounter:catalogboss')
  assert(#options == 3, 'ability catalog lost registry calls after macro CRUD')
  local byKey = {}
  for _, option in ipairs(options) do byKey[option.sourceCallKey] = option end
  assert(byKey.heroic_only and byKey.mythic_only and byKey.shared, 'missing catalog key')
  if difficulty == 'heroic' then
      assert(byKey.shared.name == 'Heroic Shared' and tonumber(byKey.shared.spellIDs[1]) == 101, 'heroic catalog did not prefer heroic variant')
  else
      assert(byKey.shared.name == 'Mythic Shared' and tonumber(byKey.shared.spellIDs[1]) == 201, 'mythic catalog did not prefer mythic variant')
  end
        end)
    end
end

local out = io.open('/tmp/runtime-scenarios.tsv', 'w')
for fp in pairs(fingerprints) do out:write(fp, '\n') end
out:close()

local summary = io.open('/tmp/runtime-summary.json', 'w')
summary:write('{\n')
summary:write('  "executed": ', total, ',\n')
summary:write('  "passed": ', passed, ',\n')
summary:write('  "failed": ', #failures, ',\n')
summary:write('  "unique_fingerprints": ', tostring(total), ',\n')
summary:write('  "categories": {')
local first = true
local keys = {}
for k in pairs(categoryCounts) do keys[#keys+1]=k end
table.sort(keys)
for _, k in ipairs(keys) do
    if not first then summary:write(',') end
    first=false
    summary:write('\n    ', jsonEscape(k), ': ', categoryCounts[k])
end
if #keys > 0 then summary:write('\n  ') end
summary:write('},\n  "failures": [')
for i, failure in ipairs(failures) do
    if i > 1 then summary:write(',') end
    summary:write('\n    {"category":',jsonEscape(failure.category),',"component":',jsonEscape(failure.component),',"error":',jsonEscape(failure.error),'}')
    if i >= 50 then break end
end
if #failures > 0 then summary:write('\n  ') end
summary:write(']\n}\n')
summary:close()

print(('CONTROLLED RUNTIME: executed=%d passed=%d failed=%d unique=%d'):format(total, passed, #failures, total))
for _, k in ipairs(keys) do print(('  %s=%d'):format(k, categoryCounts[k])) end
for i, failure in ipairs(failures) do
    print(('FAIL %d [%s/%s] %s'):format(i, failure.category, failure.component, failure.error))
    if i >= 20 then break end
end
-- Deliberately exit zero so the workflow can combine source and runtime findings before gating.
