from pathlib import Path
import hashlib
import json
import re

ROOT = Path('.')
scenarios = []
failures = []
fingerprints = set()

def record(category, component, preconditions, input_value, expected, actual, ok):
    payload = {
        'evidence_layer': 'source',
        'category': category,
        'component': component,
        'actor': 'addon-runtime',
        'preconditions': preconditions,
        'input': input_value,
        'expected_result': expected,
        'environment': 'RaidLeadAssist-main-compatible-source',
    }
    raw = json.dumps(payload, sort_keys=True, ensure_ascii=False)
    fp = hashlib.sha256(raw.encode()).hexdigest()
    if fp in fingerprints:
        raise AssertionError(f'duplicate fingerprint: {payload}')
    fingerprints.add(fp)
    entry = {**payload, 'fingerprint': fp, 'actual': actual, 'status': 'pass' if ok else 'fail'}
    scenarios.append(entry)
    if not ok:
        failures.append(entry)

# Manifest closure and order.
toc = (ROOT / 'RaidLeadAssist.toc').read_text(encoding='utf-8')
entries = [line.strip() for line in toc.splitlines() if line.strip() and not line.startswith('##')]
for index, entry in enumerate(entries, 1):
    p = ROOT / entry
    record('manifest', entry, f'toc-index={index}', 'exists', True, p.exists(), p.exists())
    record('manifest', entry, f'toc-index={index}', 'lua-extension', entry.endswith('.lua'), entry.endswith('.lua'), entry.endswith('.lua'))

# Every runtime Lua source must parse as a TOC-owned file; README/audit files are excluded.
runtime_lua = sorted(p.as_posix() for p in ROOT.rglob('*.lua') if 'audit/' not in p.as_posix() and '.github/' not in p.as_posix())
entry_set = set(entries)
for path in runtime_lua:
    record('manifest', path, 'runtime-lua', 'listed-in-toc', True, path in entry_set, path in entry_set)

# Load-order contracts for core dependencies.
order_requirements = [
    ('Bootstrap.lua', 'Core/Constants.lua'),
    ('Core/Constants.lua', 'Core/Util.lua'),
    ('Core/Util.lua', 'Core/Database.lua'),
    ('Encounters/Registry.lua', 'Services/BossMacroService.lua'),
    ('Services/TimelineService.lua', 'Services/BossMacroService.lua'),
    ('Services/BossMacroService.lua', 'Services/ManagedMacroService.lua'),
    ('Services/ManagedMacroService.lua', 'Services/ActionBarOverlayService.lua'),
    ('UI/IconPicker.lua', 'UI/BossMacroManager.lua'),
    ('UI/BossMacroManager.lua', 'Core/App.lua'),
]
position = {name: idx for idx, name in enumerate(entries)}
for before, after in order_requirements:
    actual = before in position and after in position and position[before] < position[after]
    record('load-order', f'{before}->{after}', 'toc-order', 'before-after', True, actual, actual)

# Repo hygiene: runtime-only final product should not contain stale dashboard layers or persistent audit/test residue.
banned_paths = [
    'UI/MainFrame.lua', 'UI/ProductivityPanel.lua', 'UI/ReadinessPanel.lua', 'UI/SetupPanel.lua',
    'Services/AssignmentService.lua', 'Services/ReadinessService.lua', 'Services/ProductivityService.lua',
]
for path in banned_paths:
    exists = (ROOT / path).exists()
    record('hygiene', path, 'runtime-only-product', 'legacy-path-absent', False, exists, not exists)

# Public UX contract from the requested Boss Macro Manager.
ui = (ROOT / 'UI/BossMacroManager.lua').read_text(encoding='utf-8')
icon = (ROOT / 'UI/IconPicker.lua').read_text(encoding='utf-8')
app = (ROOT / 'Core/App.lua').read_text(encoding='utf-8')
boss = (ROOT / 'Services/BossMacroService.lua').read_text(encoding='utf-8')
managed = (ROOT / 'Services/ManagedMacroService.lua').read_text(encoding='utf-8')
overlay = (ROOT / 'Services/ActionBarOverlayService.lua').read_text(encoding='utf-8')

required_ui_tokens = [
    'ButtonFrameTemplate', 'Boss:', 'UIDropDownMenuTemplate', 'Change Name/Icon', 'Boss Ability:',
    'Enter Macro Commands:', 'To Action Bar', 'Automatic timing overlay', 'Delete', 'New', 'Save', 'Cancel'
]
for token in required_ui_tokens:
    ok = token in ui
    record('frontend-contract', 'UI/BossMacroManager.lua', 'boss-macro-manager', token, True, ok, ok)

required_icon_tokens = ['Change Name/Icon', 'Enter Macro Name', 'Currently Selected', 'Choose an Icon:', 'All Icons', 'Okay', 'Cancel']
for token in required_icon_tokens:
    ok = token in icon
    record('frontend-contract', 'UI/IconPicker.lua', 'blizzard-icon-picker', token, True, ok, ok)

# Explicit geometry contract: all icon rows must fit between grid top and footer.
frame_height, grid_top, grid_bottom, button_height, row_step = 590, 178, 54, 45, 49
m = re.search(r'local columns, rows = (\d+), (\d+)', icon)
rows = int(m.group(2)) if m else 999
used = button_height + max(0, rows - 1) * row_step
available = frame_height - grid_top - grid_bottom
record('frontend-geometry', 'UI/IconPicker.lua', f'rows={rows}', 'icon-grid-height', f'<= {available}', used, used <= available)

# Front/back wiring contracts.
wiring_tokens = {
    'save->managed-sync': 'ManagedMacros:SyncMacro(macro)',
    'pickup->managed-pickup': 'ManagedMacros:Pickup(macro)',
    'delete->managed-delete': 'ManagedMacros:DeleteManaged(macro)',
    'save->overlay-refresh': 'Overlay:RefreshBindings()',
    'unknown-encounter-fail-closed': 'Timeline:SetEncounter(nil)',
    'unknown-encounter-overlay-hide': 'Overlay:HideAll()',
}
for name, token in wiring_tokens.items():
    ok = token in app
    record('integration-contract', 'Core/App.lua', name, token, True, ok, ok)

# Managed macro protected-action contracts.
for operation in ['CreateMacro', 'EditMacro', 'DeleteMacro', 'PickupMacro']:
    ok = operation in managed
    record('managed-macro', 'Services/ManagedMacroService.lua', 'wow-macro-api', operation, True, ok, ok)
for token in ['InCombatLockdown', 'PLAYER_REGEN_ENABLED', 'pendingMacroSync', '/run RLA_P(']:
    ok = token in managed
    record('combat-safety', 'Services/ManagedMacroService.lua', 'protected-action-boundary', token, True, ok, ok)

# Full-button timing layer contracts.
for token in ['progress:SetAllPoints(overlay)', 'veil:SetAllPoints(overlay)', 'overlay.Countdown', 'CallState.PRESS', 'CallState.LATE', 'CallState.PREPARE']:
    ok = token in overlay
    record('timing-overlay', 'Services/ActionBarOverlayService.lua', 'full-button-overlay', token, True, ok, ok)

# The ability catalog must be independent of the mutable macro list. Deleting a macro must not erase the boss ability choice.
service_has_catalog = 'function BossMacroService:GetAbilityOptions' in boss
ui_uses_catalog = 'BossMacros:GetAbilityOptions' in ui
record('ability-catalog', 'Services/BossMacroService.lua', 'boss-abilities-survive-macro-crud', 'service-catalog', True, service_has_catalog, service_has_catalog)
record('ability-catalog', 'UI/BossMacroManager.lua', 'boss-abilities-survive-macro-crud', 'ui-uses-service-catalog', True, ui_uses_catalog, ui_uses_catalog)

# Broad structural negative checks: old architecture names must not leak into any runtime source.
banned_tokens = [
    'AssignmentService', 'ReadinessService', 'ProductivityService', 'SetupPanel', 'ReadinessPanel',
    'ProductivityPanel', 'AssignmentPanel', 'StrategyEditor', 'assignmentPresets', 'forceShown'
]
for path in runtime_lua:
    text = (ROOT / path).read_text(encoding='utf-8')
    for token in banned_tokens:
        # Database migration fields are intentionally tolerated for backwards compatibility.
        allowed = path == 'Core/Database.lua' and token in {'assignmentPresets', 'forceShown'}
        found = token in text
        ok = allowed or not found
        record('legacy-leak', path, 'new-primary-product', token, 'absent-or-migration-only', found, ok)

# Validate no persistent test/audit/CI residue in the final tree except this temporary audit branch.
for path in sorted(p.as_posix() for p in ROOT.rglob('*') if p.is_file()):
    if path.startswith('.git/') or path.startswith('audit/') or path.startswith('.github/workflows/high-volume-audit.yml') or path.startswith('.github/workflows/apply-audit-fixes.yml'):
        continue
    bad = any(part in path.lower() for part in ['/tests/', '/test/', '/audit/', '__pycache__', '.pytest_cache'])
    record('repo-hygiene', path, 'runtime-only-default-branch', 'persistent-test-residue', False, bad, not bad)

Path('/tmp/source-scenarios.json').write_text(json.dumps(scenarios, indent=2), encoding='utf-8')
summary = {
    'executed': len(scenarios),
    'passed': len(scenarios) - len(failures),
    'failed': len(failures),
    'unique_fingerprints': len(fingerprints),
    'failures': [{k: f[k] for k in ('category','component','preconditions','input','expected_result','actual','fingerprint')} for f in failures[:50]],
}
Path('/tmp/source-summary.json').write_text(json.dumps(summary, indent=2), encoding='utf-8')
print(json.dumps(summary, indent=2))
# Do not exit non-zero here; the workflow final gate must still run controlled-runtime scenarios.
