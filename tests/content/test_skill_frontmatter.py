"""Frontmatter and reference-linkage checks for every SKILL.md."""

from __future__ import annotations

import re
from pathlib import Path

import pytest
import yaml


FRONTMATTER_RE = re.compile(r"^---\n(.*?)\n---\n", re.DOTALL)
NAME_RE = re.compile(r"^[a-z][a-z0-9-]*$")


def _parse_frontmatter(skill_md: Path) -> dict:
    text = skill_md.read_text()
    match = FRONTMATTER_RE.match(text)
    assert match, f"{skill_md}: missing YAML frontmatter (--- ... ---)"
    return yaml.safe_load(match.group(1)) or {}


def test_skill_md_filename_is_uppercase(skill_dirs: list[Path]) -> None:
    """Filename must be exactly SKILL.md (case-sensitive). The Skills standard
    requires this; macOS's case-insensitive default hides drift."""
    for d in skill_dirs:
        candidates = list(d.glob("[Ss][Kk][Ii][Ll][Ll].md"))
        assert candidates, f"{d}: no SKILL.md found"
        for c in candidates:
            assert c.name == "SKILL.md", (
                f"{c}: must be exactly 'SKILL.md', got {c.name!r}"
            )


def test_frontmatter_has_name_and_description(skill_dirs: list[Path]) -> None:
    for d in skill_dirs:
        fm = _parse_frontmatter(d / "SKILL.md")
        assert "name" in fm, f"{d}/SKILL.md: missing 'name:' in frontmatter"
        assert "description" in fm, (
            f"{d}/SKILL.md: missing 'description:' in frontmatter"
        )
        assert fm["description"].strip(), (
            f"{d}/SKILL.md: 'description:' is empty"
        )


def test_name_matches_folder(skill_dirs: list[Path]) -> None:
    for d in skill_dirs:
        fm = _parse_frontmatter(d / "SKILL.md")
        assert fm["name"] == d.name, (
            f"{d}/SKILL.md: frontmatter name {fm['name']!r} "
            f"does not match folder name {d.name!r}"
        )


def test_name_is_lowercase_hyphenated(skill_dirs: list[Path]) -> None:
    for d in skill_dirs:
        fm = _parse_frontmatter(d / "SKILL.md")
        assert NAME_RE.match(fm["name"]), (
            f"{d}/SKILL.md: name {fm['name']!r} must be lowercase, "
            f"start with a letter, and contain only [a-z0-9-]"
        )


def test_description_under_1024_chars(skill_dirs: list[Path]) -> None:
    """Frontmatter is loaded into every conversation; long descriptions cost context."""
    for d in skill_dirs:
        fm = _parse_frontmatter(d / "SKILL.md")
        desc = fm["description"]
        assert len(desc) <= 1024, (
            f"{d}/SKILL.md: description is {len(desc)} chars (max 1024)"
        )


def test_no_orphan_references(skill_dirs: list[Path]) -> None:
    """Every references/*.md must be linked from its SKILL.md."""
    for d in skill_dirs:
        ref_dir = d / "references"
        if not ref_dir.is_dir():
            continue
        skill_text = (d / "SKILL.md").read_text()
        for ref in sorted(ref_dir.glob("*.md")):
            rel = ref.relative_to(d).as_posix()
            assert rel in skill_text, (
                f"{d}/SKILL.md: reference {rel!r} exists but is not linked from SKILL.md"
            )
