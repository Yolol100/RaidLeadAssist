#!/usr/bin/env python3
"""Focused regression tests for scripts/check_upstream_drift.py."""

from __future__ import annotations

import importlib.util
import json
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "scripts" / "check_upstream_drift.py"
SPEC = importlib.util.spec_from_file_location("check_upstream_drift", SCRIPT)
assert SPEC and SPEC.loader
module = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(module)

GOOD = "a" * 40
OTHER = "b" * 40


def baseline() -> dict:
    return {
        "schemaVersion": 1,
        "reviewedAt": "2026-09-02",
        "wowInterface": 120100,
        "providers": [
            {
                "name": "Provider",
                "repository": "example/provider",
                "releaseTag": "v1",
                "releaseCommit": GOOD,
                "watchPaths": [{"ref": "main", "path": "provider.lua", "blobSha": GOOD}],
            }
        ],
        "sources": [
            {
                "name": "Blizzard EncounterTimeline API",
                "repository": "example/source",
                "watchPaths": [{"ref": "live", "path": "timeline.lua", "blobSha": GOOD}],
            }
        ],
    }


def test_schema_with_source() -> None:
    original = module.BASELINE_PATH
    try:
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "baseline.json"
            path.write_text(json.dumps(baseline()), encoding="utf-8")
            module.BASELINE_PATH = path
            loaded = module.load_baselines()
            assert len(loaded["sources"]) == 1
    finally:
        module.BASELINE_PATH = original


def fake_api(path: str, _token: str | None):
    if path.endswith("/releases/latest"):
        return {"tag_name": "v1"}
    if "/commits/v1" in path:
        return {"sha": GOOD}
    if "provider.lua" in path:
        return {"sha": GOOD}
    if "timeline.lua" in path:
        return {"sha": OTHER}
    raise AssertionError(f"unexpected API path: {path}")


def test_source_drift_is_blocking() -> None:
    original = module.api_get
    try:
        module.api_get = fake_api
        drift = module.check_online(baseline())
    finally:
        module.api_get = original
    assert len(drift) == 1
    assert "Blizzard EncounterTimeline API" in drift[0]
    assert "watched upstream file changed" in drift[0]


def test_matching_source_is_clean() -> None:
    original = module.api_get

    def clean_api(path: str, token: str | None):
        result = fake_api(path, token)
        if "timeline.lua" in path:
            return {"sha": GOOD}
        return result

    try:
        module.api_get = clean_api
        assert module.check_online(baseline()) == []
    finally:
        module.api_get = original


if __name__ == "__main__":
    test_schema_with_source()
    test_source_drift_is_blocking()
    test_matching_source_is_clean()
    print("ok - upstream drift source regressions")
