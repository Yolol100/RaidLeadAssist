#!/usr/bin/env python3
"""Build and verify the exact Raid Lead Assist runtime ZIP without dev-only files."""

from __future__ import annotations

import argparse
import hashlib
import sys
import zipfile
from pathlib import Path, PurePosixPath

ADDON_ROOT = "RaidLeadAssist"
TOC_NAME = "RaidLeadAssist.toc"
FIXED_ZIP_TIME = (1980, 1, 1, 0, 0, 0)
ROOT = Path(__file__).resolve().parents[1]


def fail(message: str) -> None:
    raise SystemExit(message)


def normalize_runtime_path(raw: str) -> str:
    raw = raw.strip()
    if not raw:
        fail("empty runtime path")
    if "\\" in raw:
        fail(f"TOC runtime path must use forward slashes: {raw}")
    path = PurePosixPath(raw)
    if path.is_absolute() or ".." in path.parts or "." in path.parts:
        fail(f"unsafe TOC runtime path: {raw}")
    if not path.parts:
        fail(f"invalid TOC runtime path: {raw}")
    return path.as_posix()


def runtime_files() -> list[str]:
    toc = ROOT / TOC_NAME
    if not toc.is_file():
        fail(f"missing {TOC_NAME}")

    result = [TOC_NAME]
    seen = {TOC_NAME}
    for raw_line in toc.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#"):
            continue
        relative = normalize_runtime_path(line)
        if relative in seen:
            fail(f"duplicate TOC runtime entry: {relative}")
        source = ROOT / relative
        if not source.is_file() or source.is_symlink():
            fail(f"runtime entry is missing or not a regular file: {relative}")
        seen.add(relative)
        result.append(relative)
    return result


def archive_name(relative: str) -> str:
    return f"{ADDON_ROOT}/{relative}"


def write_entry(archive: zipfile.ZipFile, relative: str) -> None:
    source = ROOT / relative
    info = zipfile.ZipInfo(archive_name(relative), FIXED_ZIP_TIME)
    info.compress_type = zipfile.ZIP_DEFLATED
    info.create_system = 3
    info.external_attr = 0o100644 << 16
    archive.writestr(info, source.read_bytes(), compress_type=zipfile.ZIP_DEFLATED, compresslevel=9)


def build(output: Path) -> list[str]:
    files = runtime_files()
    output.parent.mkdir(parents=True, exist_ok=True)
    if output.exists():
        output.unlink()
    with zipfile.ZipFile(output, "w") as archive:
        for relative in files:
            write_entry(archive, relative)
    return files


def verify(output: Path, files: list[str] | None = None) -> str:
    if not output.is_file():
        fail(f"release ZIP does not exist: {output}")
    files = files or runtime_files()
    expected = [archive_name(relative) for relative in files]

    with zipfile.ZipFile(output, "r") as archive:
        names = archive.namelist()
        if len(names) != len(set(names)):
            fail("release ZIP contains duplicate entries")
        if names != expected:
            extra = sorted(set(names) - set(expected))
            missing = sorted(set(expected) - set(names))
            fail(f"release ZIP inventory mismatch; extra={extra}, missing={missing}")

        for name, relative in zip(names, files):
            path = PurePosixPath(name)
            if path.is_absolute() or ".." in path.parts or not path.parts or path.parts[0] != ADDON_ROOT:
                fail(f"unsafe release ZIP path: {name}")
            source_bytes = (ROOT / relative).read_bytes()
            if archive.read(name) != source_bytes:
                fail(f"release ZIP content differs from tested source: {relative}")

    digest = hashlib.sha256(output.read_bytes()).hexdigest()
    print(f"ok - verified release package: {output} sha256={digest}")
    return digest


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", default="dist/RaidLeadAssist.zip")
    parser.add_argument("--verify-only", action="store_true")
    args = parser.parse_args()

    output = Path(args.output)
    if not output.is_absolute():
        output = ROOT / output

    if args.verify_only:
        verify(output)
    else:
        files = build(output)
        verify(output, files)
    return 0


if __name__ == "__main__":
    sys.exit(main())
