#!/usr/bin/env python3
from __future__ import annotations
import re, sys
from pathlib import Path, PurePosixPath

ROOT = Path(__file__).resolve().parents[1]
TOC = ROOT / "RaidLeadAssist.toc"
RUNTIME_DIRS = {"Core", "Encounters", "Services", "UI"}
EXPECTED_INTERFACE = "120100"
EXPECTED_TITLE = "Raid Lead Assist"
EXPECTED_SAVED_VARIABLES = "RaidLeadAssistDB"
EXPECTED_OPTIONAL_DEPS = {"DBM-Core", "BigWigs"}
FORBIDDEN_MARKERS = re.compile(r"\b(TODO|FIXME|HACK|XXX)\b")
FORBIDDEN_POLICY = re.compile(r"\b(patreon|paypal|donat(?:e|ion)|premium|advertis(?:e|ement)|sponsor)\b", re.I)
FORBIDDEN_CODE = re.compile(r"\b(loadstring|RunScript|SendAddonMessage|C_ChatInfo\.SendAddonMessage)\b")
DUTCH_UI = re.compile(r"\b(instellingen|opslaan|annuleren|verwijderen|waarschuwing|moeilijkheid|speler|groep|gevecht|toewijzing|rotatie|sturen|baas)\b", re.I)
OBSOLETE_OVERLAYS = {
    "UI/MainFrameEnhancements.lua",
    "Core/TimingStatusIntegration.lua",
    "Encounters/VenomousAbyss/UlatekAssignmentPolicy.lua",
}

def fail(message: str) -> None:
    print(f"error - {message}", file=sys.stderr)
    raise SystemExit(1)

def toc_text() -> str:
    if not TOC.is_file(): fail("missing RaidLeadAssist.toc")
    return TOC.read_text(encoding="utf-8")

def toc_metadata(text: str) -> dict[str, str]:
    metadata: dict[str, str] = {}
    for raw in text.splitlines():
        if not raw.startswith("## "): continue
        body = raw[3:]
        if ":" not in body: continue
        key, value = body.split(":", 1)
        key, value = key.strip(), value.strip()
        if key in metadata: fail(f"duplicate TOC metadata key: {key}")
        metadata[key] = value
    return metadata

def runtime_entries(text: str) -> list[str]:
    entries, seen = [], set()
    for raw in text.splitlines():
        line = raw.strip()
        if not line or line.startswith("#"): continue
        path = PurePosixPath(line)
        if path.is_absolute() or ".." in path.parts or "." in path.parts: fail(f"unsafe TOC path: {line}")
        if line in seen: fail(f"duplicate TOC entry: {line}")
        seen.add(line); entries.append(line)
    return entries

def validate_toc_metadata(text: str) -> str:
    metadata = toc_metadata(text)
    required = {"Interface", "Title", "Notes", "Version", "SavedVariables", "OptionalDeps"}
    missing = sorted(required - metadata.keys())
    if missing: fail("missing TOC metadata: " + ", ".join(missing))
    if metadata["Interface"] != EXPECTED_INTERFACE: fail(f"unexpected TOC Interface: {metadata['Interface']}")
    if metadata["Title"] != EXPECTED_TITLE: fail(f"unexpected TOC Title: {metadata['Title']}")
    if metadata["SavedVariables"] != EXPECTED_SAVED_VARIABLES: fail(f"unexpected SavedVariables: {metadata['SavedVariables']}")
    deps = {item.strip() for item in metadata["OptionalDeps"].split(",") if item.strip()}
    if deps != EXPECTED_OPTIONAL_DEPS: fail("OptionalDeps must be exactly DBM-Core and BigWigs")
    visible_metadata = " ".join(metadata.get(key, "") for key in ("Title", "Notes", "X-Category"))
    if FORBIDDEN_POLICY.search(visible_metadata): fail("policy-sensitive advertising/donation copy in TOC metadata")
    if DUTCH_UI.search(visible_metadata): fail("Dutch user-facing token detected in TOC metadata")
    if not re.fullmatch(r"0\.9\.0-beta\.\d+", metadata["Version"]): fail(f"unexpected beta version format: {metadata['Version']}")
    return metadata["Version"]

def main() -> int:
    text = toc_text()
    version = validate_toc_metadata(text)
    entries = runtime_entries(text); entryset = set(entries)
    obsolete = OBSOLETE_OVERLAYS & entryset
    if obsolete: fail("obsolete overlay loaded: " + ", ".join(sorted(obsolete)))
    runtime_lua = []
    for path in ROOT.rglob("*.lua"):
        rel = path.relative_to(ROOT).as_posix()
        if rel == "Bootstrap.lua" or rel.split("/", 1)[0] in RUNTIME_DIRS: runtime_lua.append(rel)
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
        source = (ROOT / rel).read_text(encoding="utf-8")
        if FORBIDDEN_MARKERS.search(source): fail(f"development marker in runtime: {rel}")
        if FORBIDDEN_POLICY.search(source): fail(f"policy-sensitive advertising/donation copy in runtime: {rel}")
        if FORBIDDEN_CODE.search(source): fail(f"forbidden/unneeded dynamic or addon-network primitive in runtime: {rel}")
        if DUTCH_UI.search(source): fail(f"Dutch user-facing token detected in runtime: {rel}")
    changelog = (ROOT / "CHANGELOG.md").read_text(encoding="utf-8")
    release = re.search(r"^##\s+(\S+)\s+", changelog, re.M)
    if not release or release.group(1) != version: fail("TOC version does not match top changelog release")
    print(f"ok - runtime audit passed ({len(runtime_lua)} Lua files; TOC metadata/path, English/policy hygiene and version parity)")
    return 0

if __name__ == "__main__": raise SystemExit(main())
