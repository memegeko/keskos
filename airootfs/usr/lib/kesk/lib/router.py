from __future__ import annotations

import os
from pathlib import Path
from typing import Sequence

from common import APP_VERSION, KeskConsole


HELP_ROWS = (
    ("kesk help", "Show the command router help."),
    ("kesk version", "Show the current Kesk tool version."),
    ("kesk upgrade", "Open the KeskOS system upgrade manager."),
)


def show_help(console: KeskConsole, error: str | None = None) -> int:
    console.clear()
    console.header("KESK SYSTEM TOOLS", "BASE COMMAND ROUTER")
    if error:
        console.status("warn", error)
        console.line()
    console.table("AVAILABLE COMMANDS", HELP_ROWS)
    console.line()
    console.muted("Unknown commands fall back to this help screen.")
    return 0 if error is None else 1


def show_version(console: KeskConsole) -> int:
    console.line(f"kesk {APP_VERSION}")
    return 0


def exec_command(command_path: Path, extra_args: Sequence[str]) -> int:
    os.execv(str(command_path), [str(command_path), *extra_args])
    return 1


def main(args: Sequence[str], root: Path) -> int:
    console = KeskConsole()
    upgrade_path = root / "commands" / "upgrade"

    if not args:
        return show_help(console)

    command = args[0]
    extra_args = list(args[1:])

    if command in {"help", "--help", "-h"}:
        if extra_args and extra_args[0] == "upgrade" and upgrade_path.exists():
            return exec_command(upgrade_path, ["--help"])
        return show_help(console)

    if command in {"version", "--version", "-V"}:
        return show_version(console)

    if command == "upgrade":
        if not upgrade_path.exists():
            return show_help(console, "upgrade command is missing from /usr/lib/kesk/commands.")
        return exec_command(upgrade_path, extra_args)

    return show_help(console, f"unknown command: {command}")
