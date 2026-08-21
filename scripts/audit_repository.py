#!/usr/bin/env python3
from __future__ import annotations

import re
import subprocess
import sys
import unicodedata
from pathlib import Path, PurePosixPath

ROOT = Path(__file__).resolve().parents[1]
TOC = ROOT / "RaidLeadAssist.toc"
MAX_TRACKED_BYTES = 1024 * 1024
MIN_BEHAVIOR_TESTS = 35

REQUIRED_FILES = {
    ".editorconfig", ".gitattributes", ".github/CODEOWNERS", ".github/dependabot.yml",
    ".github/ISSUE_TEMPLATE/bug.yml", ".github/ISSUE_TEMPLATE/config.yml",
    ".github/ISSUE_TEMPLATE/provider.yml", ".github/ISSUE_TEMPLATE/strategy.yml",
    ".github/PULL_REQUEST_TEMPLATE.md",
    ".github/workflows/validate.yml", ".github/workflows/upstream-drift.yml", ".luacheckrc",
    "CHANGELOG.md", "CONTRIBUTING.md", "PRIVACY.md", "README.md", "RaidLeadAssist.toc", "SECURITY.md",
    "docs/ARCHITECTURE.md", "docs/AUDIT_SOURCES.md", "docs/LIVE_TEST_MATRIX.md", "docs/RELEASE_PROCESS.md",
    "docs/TEN_OF_TEN_ACCEPTANCE.md", "docs/STATIC_ANALYSIS.md", "docs/UPSTREAM_BASELINES.json",
    "scripts/audit_runtime.py", "scripts/audit_repository.py", "scripts/build_release.py", "scripts/build_sbom.py",
    "scripts/check_upstream_drift.py", "tests/testlib.lua",
}

FORBIDDEN_PATH_PARTS = {
    ".idea", ".vscode", "__pycache__", ".pytest_cache", ".mypy_cache", "node_modules",
    "dist", "build", "coverage", ".coverage", ".env",
}
FORBIDDEN_SUFFIXES = {".log", ".tmp", ".swp", ".swo", ".bak", ".orig", ".rej", ".pem", ".p12", ".pfx"}
SECRET_PATTERNS = {
    "private key": re.compile(r"-----BEGIN (?:RSA |EC |OPENSSH |DSA )?PRIVATE KEY-----"),
    "GitHub token": re.compile(r"\b(?:gh[pousr]_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{40,})\b"),
    "AWS access key": re.compile(r"\bAKIA[0-9A-Z]{16}\b"),
    "Google API key": re.compile(r"\bAIza[0-9A-Za-z_-]{30,}\b"),
    "Slack token": re.compile(r"\bxox[baprs]-[0-9A-Za-z-]{20,}\b"),
    "OpenAI key": re.compile(r"\bsk-(?:proj-)?[A-Za-z0-9_-]{24,}\b"),
}
FORBIDDEN_RUNTIME_APIS = re.compile(
    r"\b(?:CombatLogGetCurrentEventInfo|COMBAT_LOG_EVENT_UNFILTERED|UnitAura|C_UnitAuras|"
    r"UnitPower|UnitPowerMax|UnitCastingInfo|UnitChannelInfo|UnitPosition|"
    r"GetPlayerMapPosition|CastSpellByID|CastSpellByName|UseAction|TargetUnit|FocusUnit|"
    r"SetBinding|SetOverrideBinding|RegisterStateDriver|SecureActionButtonTemplate|SecureHandler|"
    r"SendAddonMessage|loadstring|RunScript)\b"
)
DISPLAY_ONLY_HEALTH_APIS = re.compile(r"\b(?:UnitHealth|UnitHealthMax)\b")
APPROVED_SECRET_HEALTH_DISPLAY_FILES = {"UI/SentinelsPanel.lua"}
APPROVED_RUNTIME_PATCHES = {
    "Core/AssignmentIntegration.lua": {
        "Core.App": {"Initialize", "SelectBoss", "SelectDifficulty", "SendExplanation", "SendCall"},
    },
    "Core/ReadinessIntegration.lua": {
        "Core.App": {"PrintDoctor"},
    },
    "Core/ProviderRecoveryIntegration.lua": {
        "Services.TimelineService": {"ProviderTimerStarted"},
    },
    "Core/SentinelsIntegration.lua": {
        "UI.MainFrame": {"Initialize", "SetEncounter", "SetCallState", "ResetCallStates"},
    },
}


def fail(message: str) -> None:
    print(f"error - {message}", file=sys.stderr)
    raise SystemExit(1)


def git_files() -> list[str]:
    try:
        raw = subprocess.check_output(["git", "ls-files", "-z"], cwd=ROOT)
    except (OSError, subprocess.CalledProcessError) as exc:
        fail(f"cannot enumerate tracked files: {exc}")
    return [item.decode("utf-8") for item in raw.split(b"\0") if item]


def read_text(rel: str) -> str:
    path = ROOT / rel
    try:
        data = path.read_bytes()
    except OSError as exc:
        fail(f"cannot read tracked file {rel}: {exc}")
    if b"\0" in data:
        fail(f"binary/NUL content is not allowed in source repository: {rel}")
    try:
        text = data.decode("utf-8")
    except UnicodeDecodeError:
        fail(f"tracked source must be UTF-8: {rel}")
    if "\r" in text:
        fail(f"tracked source must use LF line endings: {rel}")
    if data and not data.endswith(b"\n"):
        fail(f"tracked text must end with a newline: {rel}")
    if len(data) > MAX_TRACKED_BYTES:
        fail(f"tracked source exceeds {MAX_TRACKED_BYTES} bytes: {rel}")
    return text


def validate_paths(files: list[str]) -> None:
    lower: dict[str, str] = {}
    for rel in files:
        if unicodedata.normalize("NFC", rel) != rel:
            fail(f"path is not NFC-normalized: {rel}")
        if any(ord(ch) < 32 for ch in rel) or "\\" in rel:
            fail(f"unsafe tracked path: {rel!r}")
        p = PurePosixPath(rel)
        if p.is_absolute() or ".." in p.parts or any(part in FORBIDDEN_PATH_PARTS for part in p.parts):
            fail(f"forbidden tracked path: {rel}")
        if any(part.endswith(" ") or part.endswith(".") for part in p.parts):
            fail(f"non-portable tracked path: {rel}")
        if p.suffix.lower() in FORBIDDEN_SUFFIXES or rel.endswith("~"):
            fail(f"temporary/sensitive file must not be tracked: {rel}")
        key = rel.casefold()
        if key in lower and lower[key] != rel:
            fail(f"case-colliding tracked paths: {lower[key]} / {rel}")
        lower[key] = rel
        if (ROOT / rel).is_symlink():
            fail(f"symlinks are not allowed in the release repository: {rel}")


def toc_entries() -> list[str]:
    entries = []
    for raw in TOC.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if line and not line.startswith("#"):
            entries.append(line)
    return entries


def runtime_patch_surface(entries: list[str]) -> dict[str, dict[str, set[str]]]:
    surface: dict[str, dict[str, set[str]]] = {}
    alias_re = re.compile(r'local\s+([A-Za-z_][A-Za-z0-9_]*)\s*=\s*ns:GetModule\("([^"]+)"\)')
    for rel in entries:
        source = read_text(rel)
        aliases = dict(alias_re.findall(source))
        file_surface: dict[str, set[str]] = {}
        for alias, module_name in aliases.items():
            methods = set(re.findall(rf"^function\s+{re.escape(alias)}:([A-Za-z_][A-Za-z0-9_]*)\s*\(", source, re.M))
            methods.update(re.findall(rf"^{re.escape(alias)}\.([A-Za-z_][A-Za-z0-9_]*)\s*=\s*function\b", source, re.M))
            if methods:
                file_surface[module_name] = methods
        if file_surface:
            surface[rel] = file_surface
    return surface


def validate_modules(entries: list[str]) -> None:
    register_re = re.compile(r'ns:RegisterModule\("([^"]+)"')
    get_re = re.compile(r'ns:GetModule\("([^"]+)"')
    providers: dict[str, tuple[int, str]] = {}
    for index, rel in enumerate(entries):
        source = read_text(rel)
        for name in register_re.findall(source):
            if name in providers:
                fail(f"duplicate module registration {name}: {providers[name][1]} / {rel}")
            providers[name] = (index, rel)
    for index, rel in enumerate(entries):
        source = read_text(rel)
        for name in get_re.findall(source):
            if name not in providers:
                fail(f"module dependency has no provider: {rel} -> {name}")
            provider_index, provider_path = providers[name]
            if provider_index >= index:
                fail(f"module load-order violation: {rel} gets {name} before {provider_path} is loaded")

    patches = runtime_patch_surface(entries)
    if patches != APPROVED_RUNTIME_PATCHES:
        fail(f"runtime extension surface drifted: expected {APPROVED_RUNTIME_PATCHES}, got {patches}")
    if entries.index("Core/App.lua") >= entries.index("Core/AssignmentIntegration.lua"):
        fail("AssignmentIntegration must load after Core/App.lua")
    if entries.index("UI/MainFrame.lua") >= entries.index("Core/SentinelsIntegration.lua"):
        fail("SentinelsIntegration must load after UI/MainFrame.lua")


def validate_runtime_apis(entries: list[str]) -> None:
    for rel in entries:
        source = read_text(rel)
        match = FORBIDDEN_RUNTIME_APIS.search(source)
        if match:
            fail(f"forbidden combat automation/dynamic/network API in runtime {rel}: {match.group(0)}")

        health_match = DISPLAY_ONLY_HEALTH_APIS.search(source)
        if health_match and rel not in APPROVED_SECRET_HEALTH_DISPLAY_FILES:
            fail(f"boss health API is display-only and not approved in runtime {rel}: {health_match.group(0)}")
        if rel in APPROVED_SECRET_HEALTH_DISPLAY_FILES:
            if not health_match:
                fail(f"approved boss-health display file no longer uses its declared API: {rel}")
            for marker in (
                "issecretvalue", "canaccessvalue", "StatusBar", "SetMinMaxValues", "SetValue",
                "valueIsSecret(health) or valueIsSecret(maximum)", "if secret then", "UnitGUID(token)",
            ):
                if marker not in source:
                    fail(f"secret-safe boss-health display guard missing in {rel}: {marker}")
            for forbidden in (
                "SendChatMessage", "RaidWarning:Send", "TargetUnit", "FocusUnit",
                "BALANCE_THRESHOLD_PERCENT", "UpdateBalance", "SetBalanceCall", "return percent",
            ):
                if forbidden in source:
                    fail(f"boss-health display must not derive or automate a combat recommendation in {rel}: {forbidden}")
            if "UnitName(token)" in source:
                fail(f"boss-health mapping must not depend on localized UnitName strings in {rel}")


def validate_workflows(files: list[str]) -> None:
    workflows = [rel for rel in files if rel.startswith(".github/workflows/") and rel.endswith((".yml", ".yaml"))]
    if not workflows:
        fail("no GitHub Actions workflows found")
    uses_re = re.compile(r"^\s*-?\s*uses:\s*([^\s#]+)", re.M)
    checkout_re = re.compile(r"^\s*-?\s*uses:\s*actions/checkout@[0-9a-f]{40}\b", re.M)
    persist_re = re.compile(r"^\s*persist-credentials:\s*false\s*(?:#.*)?$", re.M)
    for rel in workflows:
        text = read_text(rel)
        if "permissions:" not in text:
            fail(f"workflow must declare permissions explicitly: {rel}")
        for forbidden in ("pull_request_target:", "repository_dispatch:", "workflow_run:"):
            if forbidden in text:
                fail(f"high-risk workflow trigger {forbidden[:-1]} is not approved: {rel}")
        if re.search(r"\$\{\{\s*github\.event\.pull_request\.", text):
            fail(f"untrusted pull-request metadata interpolation detected in workflow: {rel}")
        if re.search(r"(?:curl|wget)[^\n|]*\|\s*(?:ba)?sh\b", text):
            fail(f"download-to-shell pattern detected in workflow: {rel}")
        for uses in uses_re.findall(text):
            if uses.startswith("./") or uses.startswith("docker://"):
                continue
            if "@" not in uses:
                fail(f"workflow action is missing an immutable ref: {rel}: {uses}")
            _, ref = uses.rsplit("@", 1)
            if not re.fullmatch(r"[0-9a-f]{40}", ref):
                fail(f"workflow action must be pinned to a full commit SHA: {rel}: {uses}")
        checkout_count = len(checkout_re.findall(text))
        persist_count = len(persist_re.findall(text))
        if persist_count != checkout_count:
            fail(
                f"every checkout must set persist-credentials: false: {rel} "
                f"({persist_count}/{checkout_count})"
            )
    validate = read_text(".github/workflows/validate.yml")
    for job in ("validation:", "reproducibility:", "reproducibility-check:", "provenance:", "release:"):
        if job not in validate:
            fail(f"validation workflow missing required job: {job[:-1]}")
    for marker in (
        "workflow_dispatch:",
        "concurrency:",
        "cancel-in-progress: ${{ github.event_name == 'pull_request' }}",
    ):
        if marker not in validate:
            fail(f"validation workflow missing deliberate release/concurrency contract: {marker}")
    release_condition = "if: github.event_name == 'workflow_dispatch' && github.ref == 'refs/heads/main'"
    if validate.count(release_condition) != 2:
        fail("provenance and release must both require explicit workflow_dispatch from main")
    if "if: github.event_name == 'push' && github.ref == 'refs/heads/main'" in validate:
        fail("ordinary main pushes must not publish or attest an addon release")
    unprivileged = validate.split("\n  provenance:\n", 1)[0]
    for forbidden in ("id-token: write", "attestations: write", "artifact-metadata: write", "contents: write"):
        if forbidden in unprivileged:
            fail(f"ordinary validation/reproducibility jobs must remain read-only: {forbidden}")
    if "gh attestation verify" not in validate:
        fail("release workflow must verify provenance before publishing")
    for marker in (
        "scripts/build_sbom.py",
        "SBOM.spdx.json",
        "sbom-path: dist/SBOM.spdx.json",
        "gh attestation verify dist/RaidLeadAssist.zip --repo",
    ):
        if marker not in validate:
            fail(f"validation/release workflow missing deterministic SBOM/provenance gate: {marker}")


def validate_secrets(files: list[str]) -> None:
    for rel in files:
        text = read_text(rel)
        for label, pattern in SECRET_PATTERNS.items():
            if pattern.search(text):
                fail(f"possible {label} committed in {rel}")


def validate_repository_contract(files: list[str]) -> None:
    missing = sorted(REQUIRED_FILES - set(files))
    if missing:
        fail("missing repository governance/audit files: " + ", ".join(missing))
    tests = sorted(rel for rel in files if rel.startswith("tests/test_") and rel.endswith(".lua"))
    if len(tests) < MIN_BEHAVIOR_TESTS:
        fail(f"behavioral test inventory regressed: expected at least {MIN_BEHAVIOR_TESTS}, got {len(tests)}")
    for rel in files:
        if rel.startswith("tests/") and rel.endswith(".lua") and rel != "tests/testlib.lua" and not re.fullmatch(r"tests/test_[a-z0-9_]+\.lua", rel):
            fail(f"non-canonical test filename: {rel}")
    acceptance = read_text("docs/TEN_OF_TEN_ACCEPTANCE.md")
    numbered = {int(x) for x in re.findall(r"^(\d+)\.\s", acceptance, re.M)}
    if not numbered or max(numbered) < 100:
        fail("master acceptance audit must contain at least 100 numbered checks")
    for marker in ("PASS-CI", "PASS-LIVE", "MANUAL TEST NEEDED", "DRIFT REVIEW", "FAIL"):
        if marker not in acceptance:
            fail(f"acceptance audit missing evidence state: {marker}")


def main() -> int:
    files = git_files()
    if not files:
        fail("repository contains no tracked files")
    validate_paths(files)
    for rel in files:
        read_text(rel)
    validate_repository_contract(files)
    entries = toc_entries()
    validate_modules(entries)
    validate_runtime_apis(entries)
    validate_workflows(files)
    validate_secrets(files)
    print(
        f"ok - repository audit passed ({len(files)} tracked files; {len(entries)} runtime files; "
        "paths/encoding/secrets/module-order/extensions/combat-API/workflow/test/release/SBOM/governance contract)"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
