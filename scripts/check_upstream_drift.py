#!/usr/bin/env python3
"""Validate and optionally check RaidLeadAssist's upstream baselines."""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BASELINE_PATH = ROOT / "docs" / "UPSTREAM_BASELINES.json"
SHA_RE = re.compile(r"^[0-9a-f]{40}$")
DATE_RE = re.compile(r"^\d{4}-\d{2}-\d{2}$")
API = "https://api.github.com"


def fail(message: str) -> None:
    raise ValueError(message)


def validate_watch(owner: str, watch: object, seen_paths: set[tuple[str, str]]) -> None:
    if not isinstance(watch, dict):
        fail(f"{owner}: watch entries must be objects")
    path = watch.get("path")
    ref = watch.get("ref")
    blob_sha = watch.get("blobSha")
    if not isinstance(path, str) or not path or path.startswith("/") or ".." in Path(path).parts:
        fail(f"{owner}: invalid watch path {path!r}")
    if not isinstance(ref, str) or not ref.strip():
        fail(f"{owner}: watch ref is required for {path}")
    if not isinstance(blob_sha, str) or not SHA_RE.fullmatch(blob_sha):
        fail(f"{owner}: invalid blobSha for {path}")
    key = (ref, path)
    if key in seen_paths:
        fail(f"{owner}: duplicate watch path {ref}:{path}")
    seen_paths.add(key)


def load_baselines() -> dict:
    try:
        data = json.loads(BASELINE_PATH.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        fail(f"cannot read {BASELINE_PATH.relative_to(ROOT)}: {exc}")

    if data.get("schemaVersion") != 1:
        fail("UPSTREAM_BASELINES schemaVersion must be 1")
    if not DATE_RE.fullmatch(str(data.get("reviewedAt", ""))):
        fail("reviewedAt must be YYYY-MM-DD")
    if data.get("wowInterface") != 120100:
        fail("wowInterface must match the audited Retail 12.1 interface 120100")

    providers = data.get("providers")
    if not isinstance(providers, list) or not providers:
        fail("providers must be a non-empty list")

    names: set[str] = set()
    for provider in providers:
        if not isinstance(provider, dict):
            fail("provider entries must be objects")
        name = provider.get("name")
        repository = provider.get("repository")
        release_tag = provider.get("releaseTag")
        release_commit = provider.get("releaseCommit")
        if not isinstance(name, str) or not name.strip() or name in names:
            fail("provider names must be unique non-empty strings")
        names.add(name)
        if not isinstance(repository, str) or repository.count("/") != 1:
            fail(f"{name}: repository must be owner/name")
        if not isinstance(release_tag, str) or not release_tag.strip():
            fail(f"{name}: releaseTag is required")
        if not isinstance(release_commit, str) or not SHA_RE.fullmatch(release_commit):
            fail(f"{name}: releaseCommit must be a 40-character lowercase SHA")
        watches = provider.get("watchPaths")
        if not isinstance(watches, list) or not watches:
            fail(f"{name}: watchPaths must be a non-empty list")
        seen_paths: set[tuple[str, str]] = set()
        for watch in watches:
            validate_watch(name, watch, seen_paths)

    sources = data.get("sources", [])
    if not isinstance(sources, list):
        fail("sources must be a list")
    source_names: set[str] = set()
    for source in sources:
        if not isinstance(source, dict):
            fail("source entries must be objects")
        name = source.get("name")
        repository = source.get("repository")
        if not isinstance(name, str) or not name.strip() or name in source_names:
            fail("source names must be unique non-empty strings")
        source_names.add(name)
        if not isinstance(repository, str) or repository.count("/") != 1:
            fail(f"{name}: repository must be owner/name")
        watches = source.get("watchPaths")
        if not isinstance(watches, list) or not watches:
            fail(f"{name}: watchPaths must be a non-empty list")
        seen_paths: set[tuple[str, str]] = set()
        for watch in watches:
            validate_watch(name, watch, seen_paths)

    return data


def api_get(path: str, token: str | None) -> object:
    request = urllib.request.Request(
        API + path,
        headers={
            "Accept": "application/vnd.github+json",
            "User-Agent": "RaidLeadAssist-upstream-audit",
            "X-GitHub-Api-Version": "2022-11-28",
            **({"Authorization": f"Bearer {token}"} if token else {}),
        },
    )
    try:
        with urllib.request.urlopen(request, timeout=20) as response:
            return json.load(response)
    except (urllib.error.URLError, json.JSONDecodeError) as exc:
        raise RuntimeError(f"GitHub API request failed for {path}: {exc}") from exc


def check_watch_paths(owner: str, repo: str, watches: list[dict], token: str | None) -> list[str]:
    drift: list[str] = []
    for watch in watches:
        quoted_path = urllib.parse.quote(watch["path"], safe="/")
        quoted_ref = urllib.parse.quote(watch["ref"], safe="")
        payload = api_get(f"/repos/{repo}/contents/{quoted_path}?ref={quoted_ref}", token)
        actual_sha = payload.get("sha") if isinstance(payload, dict) else None
        if actual_sha != watch["blobSha"]:
            drift.append(
                f"{owner}: watched upstream file changed: {watch['ref']}:{watch['path']} "
                f"expected {watch['blobSha'][:12]}, got {str(actual_sha)[:12]}"
            )
    return drift


def check_online(data: dict) -> list[str]:
    token = os.getenv("GITHUB_TOKEN") or os.getenv("GH_TOKEN")
    drift: list[str] = []

    for provider in data["providers"]:
        name = provider["name"]
        repo = provider["repository"]
        latest = api_get(f"/repos/{repo}/releases/latest", token)
        latest_name = latest.get("tag_name") if isinstance(latest, dict) else None
        if latest_name != provider["releaseTag"]:
            drift.append(f"{name}: latest release changed: expected {provider['releaseTag']}, got {latest_name}")
        else:
            release_commit = api_get(
                f"/repos/{repo}/commits/{urllib.parse.quote(provider['releaseTag'], safe='')}", token
            )
            latest_commit = release_commit.get("sha") if isinstance(release_commit, dict) else None
            if latest_commit != provider["releaseCommit"]:
                drift.append(
                    f"{name}: release commit changed: expected {provider['releaseCommit'][:12]}, "
                    f"got {str(latest_commit)[:12]}"
                )
        drift.extend(check_watch_paths(name, repo, provider["watchPaths"], token))

    for source in data.get("sources", []):
        drift.extend(check_watch_paths(source["name"], source["repository"], source["watchPaths"], token))

    return drift


def main() -> int:
    parser = argparse.ArgumentParser()
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument("--validate-only", action="store_true", help="validate the baseline file without network access")
    mode.add_argument("--online", action="store_true", help="compare the pinned baselines with GitHub upstream")
    args = parser.parse_args()

    try:
        data = load_baselines()
    except ValueError as exc:
        print(f"error - {exc}", file=sys.stderr)
        return 2

    print(
        f"ok - upstream baseline schema valid "
        f"({len(data['providers'])} providers, {len(data.get('sources', []))} sources, reviewed {data['reviewedAt']})"
    )
    if not args.online:
        return 0

    try:
        drift = check_online(data)
    except RuntimeError as exc:
        print(f"error - {exc}", file=sys.stderr)
        return 2

    if drift:
        for message in drift:
            print(f"::error::{message}")
        print("error - upstream drift detected; re-review provider contracts and affected encounter data", file=sys.stderr)
        return 1

    print("ok - no watched DBM/BigWigs release or Blizzard/source drift detected")
    return 0


if __name__ == "__main__":
    sys.exit(main())
