#!/usr/bin/env python3
from __future__ import annotations
import re, sys
from pathlib import Path, PurePosixPath

ROOT = Path(__file__).resolve().parents[1]
TOC = ROOT / "RaidLeadAssist.toc"
RUNTIME_DIRS = {"Core", "Encounters", "Services", "UI"}
FORBIDDEN_MARKERS = re.compile(r"\b(TODO|FIXME|HACK|XXX)\b")
FORBIDDEN_POLICY = re.compile(r"\b(patreon|paypal|donat(?:e|ion)|premium|advertis(?:e|ement)|sponsor)\b", re.I)
FORBIDDEN_CODE = re.compile(r"\b(loadstring|RunScript|SendAddonMessage|C_ChatInfo\.SendAddonMessage)\b")
DUTCH_UI = re.compile(r"\b(instellingen|opslaan|annuleren|verwijderen|waarschuwing|moeilijkheid|speler|groep|gevecht|toewijzing|rotatie|sturen|baas)\b", re.I)
OBSOLETE_OVERLAYS = {
    "UI/MainFrameEnhancements.lua",
    "Core/TimingStatusIntegration.lua",
    "Core/AssignmentIntegration.lua",
    "Encounters/VenomousAbyss/UlatekAssignmentPolicy.lua",
}

def fail(message: str) -> None:
    print(f"error - {message}", file=sys.stderr)
    raise SystemExit(1)

def runtime_entries() -> list[str]:
    if not TOC.is_file(): fail("missing RaidLeadAssist.toc")
    entries, seen = [], set()
    for raw in TOC.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line or line.startswith("#"): continue
        path = PurePosixPath(line)
        if path.is_absolute() or ".." in path.parts or "." in path.parts: fail(f"unsafe TOC path: {line}")
        if line in seen: fail(f"duplicate TOC entry: {line}")
        seen.add(line); entries.append(line)
    return entries

def main() -> int:
    entries = runtime_entries(); entryset = set(entries)
    obsolete = OBSOLETE_OVERLAYS & entryset
    if obsolete: fail("obsolete overlay loaded: " + ", ".join(sorted(obsolete)))

    runtime_lua = []
    for path in ROOT.rglob("*.lua"):
        rel = path.relative_to(ROOT).as_posix()
        if rel == "Bootstrap.lua" or rel.split("/", 1)[0] in RUNTIME_DIRS:
            runtime_lua.append(rel)
    unlisted = sorted(set(runtime_lua) - entryset)
    if unlisted: fail("runtime Lua exists outside TOC: " + ", ".join(unlisted))
    missing = sorted(entryset - set(runtime_lua))
    if missing: fail("TOC entry is missing or not runtime Lua: " + ", ".join(missing))

    lowered = {}
    for rel in runtime_lua:
        if " " in rel or "\\" in rel: fail(f"invalid runtime filename: {rel}")
        if not re.fullmatch(r"[A-Za-z0-9_./-]+\.lua", rel): fail(f"non-canonical runtime filename: {rel}")
        key = rel.lower()
        if key in lowered and lowered[key] != rel: fail(f"case-colliding runtime paths: {lowered[key]} / {rel}")
        lowered[key] = rel
        text = (ROOT / rel).read_text(encoding="utf-8")
        if FORBIDDEN_MARKERS.search(text): fail(f"development marker in runtime: {rel}")
        if FORBIDDEN_POLICY.search(text): fail(f"policy-sensitive advertising/donation copy in runtime: {rel}")
        if FORBIDDEN_CODE.search(text): fail(f"forbidden/unneeded dynamic or addon-network primitive in runtime: {rel}")
        if DUTCH_UI.search(text): fail(f"Dutch user-facing token detected in runtime: {rel}")

    app = (ROOT / "Core/App.lua").read_text(encoding="utf-8")
    for marker in ("originalInitialize", "originalSelectBoss", "originalSelectDifficulty", "originalSendExplanation"):
        if marker in app: fail(f"canonical App contains monkey-patch marker: {marker}")
    if "Services.AssignmentService" not in app or "UI.AssignmentFrame" not in app:
        fail("assignment integration is not canonical in Core/App.lua")

    toc_text = TOC.read_text(encoding="utf-8")
    version = re.search(r"^## Version:\s*(\S+)\s*$", toc_text, re.M)
    if not version: fail("TOC version missing")
    changelog = (ROOT / "CHANGELOG.md").read_text(encoding="utf-8")
    release = re.search(r"^##\s+(\S+)\s+", changelog, re.M)
    if not release or release.group(1) != version.group(1): fail("TOC version does not match top changelog release")

    print(f"ok - runtime audit passed ({len(runtime_lua)} Lua files; canonical structure, English/policy hygiene, version parity)")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
