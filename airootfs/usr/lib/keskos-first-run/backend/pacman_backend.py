from __future__ import annotations

import re
import socket
import subprocess
from dataclasses import dataclass
from functools import lru_cache
from typing import Iterable

HEADER_PATTERN = re.compile(
    r"^(?P<repo>[^/\s]+)/(?P<name>\S+)\s+(?P<version>\S+)(?:\s+\[(?P<status>[^\]]+)\])?$"
)
DESCRIPTION_PATTERN = re.compile(r"^Description\s*:\s*(?P<value>.+)$")
VERSION_PATTERN = re.compile(r"^Version\s*:\s*(?P<value>.+)$")
REPO_PATTERN = re.compile(r"^Repository\s*:\s*(?P<value>.+)$")


@dataclass(slots=True)
class PackageRecord:
    repo: str
    name: str
    version: str
    description: str
    installed: bool = False
    available: bool = True


def run_command(command: list[str], timeout: float = 30.0) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        command,
        capture_output=True,
        text=True,
        timeout=timeout,
        check=False,
    )


def internet_available() -> bool:
    try:
        with socket.create_connection(("archlinux.org", 443), timeout=3):
            return True
    except OSError:
        return False


@lru_cache(maxsize=256)
def is_installed(package_name: str) -> bool:
    result = run_command(["pacman", "-Q", package_name], timeout=10.0)
    return result.returncode == 0


@lru_cache(maxsize=256)
def get_sync_info(package_name: str) -> PackageRecord | None:
    result = run_command(["pacman", "-Si", package_name], timeout=15.0)
    if result.returncode != 0:
        return None

    repo = ""
    version = ""
    description = ""
    for line in result.stdout.splitlines():
        repo_match = REPO_PATTERN.match(line)
        if repo_match:
            repo = repo_match.group("value").strip()
            continue
        version_match = VERSION_PATTERN.match(line)
        if version_match:
            version = version_match.group("value").strip()
            continue
        description_match = DESCRIPTION_PATTERN.match(line)
        if description_match:
            description = description_match.group("value").strip()
            continue

    return PackageRecord(
        repo=repo or "unknown",
        name=package_name,
        version=version or "-",
        description=description or "No description available.",
        installed=is_installed(package_name),
        available=True,
    )


def resolve_first_available(candidates: Iterable[str]) -> str | None:
    for candidate in candidates:
        if is_installed(candidate) or get_sync_info(candidate) is not None:
            return candidate
    return None


def inspect_packages(package_names: Iterable[str]) -> dict[str, PackageRecord]:
    records: dict[str, PackageRecord] = {}
    for name in dict.fromkeys(package_names):
        info = get_sync_info(name)
        if info is None:
            records[name] = PackageRecord(
                repo="unavailable",
                name=name,
                version="-",
                description="Package is not available in the configured pacman repositories.",
                installed=False,
                available=False,
            )
            continue
        records[name] = info
    return records


def parse_search_output(output: str) -> list[PackageRecord]:
    records: list[PackageRecord] = []
    current: dict[str, str] | None = None
    descriptions: list[str] = []

    def flush() -> None:
        nonlocal current, descriptions
        if not current:
            return
        description = " ".join(part.strip() for part in descriptions if part.strip()) or "No description available."
        name = current["name"]
        installed = is_installed(name) or "installed" in current.get("status", "").lower()
        records.append(
            PackageRecord(
                repo=current["repo"],
                name=name,
                version=current["version"],
                description=description,
                installed=installed,
                available=True,
            )
        )
        current = None
        descriptions = []

    for line in output.splitlines():
        header = HEADER_PATTERN.match(line)
        if header:
            flush()
            current = header.groupdict()
            descriptions = []
            continue

        if current and line.startswith(" "):
            descriptions.append(line.strip())

    flush()
    return records


def search_packages(query: str) -> tuple[list[PackageRecord], str | None]:
    query = query.strip()
    if not query:
        return [], None

    result = run_command(["pacman", "-Ss", query], timeout=45.0)
    if result.returncode not in (0, 1):
        error_text = result.stderr.strip() or result.stdout.strip() or "pacman search failed"
        return [], error_text

    packages = parse_search_output(result.stdout)
    return packages, None


def build_install_command(package_names: Iterable[str], refresh_db: bool = False) -> list[str]:
    packages = [name for name in dict.fromkeys(package_names) if name]
    base = ["pkexec", "pacman"]
    if refresh_db:
        base.append("-Sy")
    base.extend(["-S", "--needed", "--noconfirm"])
    base.extend(packages)
    return base
