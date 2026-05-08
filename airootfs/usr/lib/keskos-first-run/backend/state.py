from __future__ import annotations

import getpass
import json
import os
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

CONFIG_DIR = Path.home() / ".config" / "keskos"
STATE_FILE = CONFIG_DIR / "first-run-complete"
LOG_DIR = Path.home() / ".local" / "state" / "keskos"
LOG_FILE = LOG_DIR / "first-run.log"


def ensure_state_dirs() -> None:
    CONFIG_DIR.mkdir(parents=True, exist_ok=True)
    LOG_DIR.mkdir(parents=True, exist_ok=True)


def is_complete() -> bool:
    return STATE_FILE.exists()


def should_skip_autorun() -> bool:
    if os.environ.get("KESKOS_DISABLE_FIRST_RUN") == "1":
        return True
    if Path("/run/archiso").exists():
        return True
    return getpass.getuser() == "liveuser"


def mark_complete(reason: str = "complete", metadata: dict[str, Any] | None = None) -> None:
    ensure_state_dirs()
    payload: dict[str, Any] = {
        "reason": reason,
        "completed_at": datetime.now(timezone.utc).isoformat(),
    }
    if metadata:
        payload["metadata"] = metadata
    STATE_FILE.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")


def reset_state() -> None:
    if STATE_FILE.exists():
        STATE_FILE.unlink()
