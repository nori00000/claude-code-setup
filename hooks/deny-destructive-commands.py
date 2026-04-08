import json
import re
import sys
from typing import Optional


def blocked_reason(command: str) -> Optional[str]:
    checks = [
        (
            re.compile(
                r"(^|[;&|()\s])rm\s+(-[A-Za-z]*[rfRF][A-Za-z]*\s+)+(?:\./|\.\.(?:$|[\s/])|\.(?:$|[\s/])|/(?:$|\s)|~(?:$|[\s/])|[*?]|\$\([^)]+\)|`[^`]+`)",
                re.IGNORECASE,
            ),
            "Blocked bulk rm command targeting wildcard, current directory, home, root, or command-expanded paths.",
        ),
        (
            re.compile(r"(^|[;&|()\s])find\b[^\n;|&]*\s-delete(\s|$)", re.IGNORECASE),
            "Blocked find -delete command.",
        ),
        (
            re.compile(r"(^|[;&|()\s])git\s+clean\s+-[A-Za-z]*[dfxX][A-Za-z]*", re.IGNORECASE),
            "Blocked git clean command that can mass-delete files.",
        ),
        (
            re.compile(r"(^|[;&|()\s])git\s+reset\s+--hard(\s|$)", re.IGNORECASE),
            "Blocked git reset --hard command that can discard large amounts of work.",
        ),
        (
            re.compile(r"(^|[;&|()\s])rsync\b[^\n;|&]*\s--delete(\s|$)", re.IGNORECASE),
            "Blocked rsync --delete command.",
        ),
        (
            re.compile(r"xargs\s+[^\n;|&]*\brm\b", re.IGNORECASE),
            "Blocked xargs rm pipeline.",
        ),
    ]
    for pattern, reason in checks:
        if pattern.search(command):
            return reason
    return None


def main() -> int:
    try:
        payload = json.load(sys.stdin)
    except Exception:
        return 0

    command = (
        payload.get("tool_input", {}).get("command", "")
        if isinstance(payload, dict)
        else ""
    )
    if not isinstance(command, str):
        return 0

    reason = blocked_reason(command)
    if reason is None:
        return 0

    response = {
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": (
                f"{reason} This Claude Code profile is configured to prevent unattended mass deletion."
            ),
        },
        "systemMessage": (
            "Destructive shell command denied by local safety hook. "
            "Use a reviewed manual session if deletion is intentional."
        ),
    }
    json.dump(response, sys.stdout)
    sys.stdout.write("\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
