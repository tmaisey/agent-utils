"""No em-dashes (—) or en-dashes (–) in *.md outside fenced code blocks.

CLAUDE.md style rule: use commas, full stops, or parentheses instead. Code blocks
are exempt because they may quote external output.
"""

from __future__ import annotations

import re
from pathlib import Path

import pytest


# Walk every .md file in the repo, except vendored helpers and node_modules-style noise.
EXCLUDE_DIRS = {"node_modules", ".git", ".venv", "__pycache__", "helpers"}


def _md_files(root: Path) -> list[Path]:
    out: list[Path] = []
    for p in root.rglob("*.md"):
        if any(part in EXCLUDE_DIRS for part in p.parts):
            continue
        out.append(p)
    return sorted(out)


def _strip_fenced_blocks(text: str) -> str:
    """Replace fenced code blocks (``` ... ```) with blank lines so dash matches in code don't count."""
    return re.sub(r"```.*?```", "", text, flags=re.DOTALL)


@pytest.mark.parametrize(
    "char,name",
    [("—", "em-dash"), ("–", "en-dash")],
)
def test_no_unicode_dashes(repo_root: Path, char: str, name: str) -> None:
    offenders: list[str] = []
    for md in _md_files(repo_root):
        prose = _strip_fenced_blocks(md.read_text())
        for lineno, line in enumerate(prose.splitlines(), start=1):
            if char in line:
                rel = md.relative_to(repo_root)
                offenders.append(f"{rel}:{lineno}: {line.strip()}")
    assert not offenders, (
        f"Found {name} ({char!r}) in markdown prose. Use commas, full stops, "
        f"or parentheses instead.\n" + "\n".join(offenders)
    )
