"""README.md must list every top-level skill folder."""

from __future__ import annotations

from pathlib import Path


def test_readme_lists_all_skills(repo_root: Path, skill_dirs: list[Path]) -> None:
    readme = (repo_root / "README.md").read_text()
    for d in skill_dirs:
        assert d.name in readme, (
            f"README.md does not mention skill folder {d.name!r}"
        )


def test_readme_skill_table_links_to_anchor(repo_root: Path, skill_dirs: list[Path]) -> None:
    """Each skill in the top-of-README table links to its per-skill anchor."""
    readme = (repo_root / "README.md").read_text()
    for d in skill_dirs:
        anchor_link = f"(#{d.name})"
        assert anchor_link in readme, (
            f"README.md skill table is missing anchor link {anchor_link!r}"
        )


def test_readme_has_per_skill_section(repo_root: Path, skill_dirs: list[Path]) -> None:
    """Each skill has its own H2 section."""
    readme = (repo_root / "README.md").read_text()
    for d in skill_dirs:
        heading = f"## {d.name}"
        assert heading in readme, (
            f"README.md is missing per-skill section heading {heading!r}"
        )


def test_readme_does_not_reference_lowercase_skill_md(repo_root: Path) -> None:
    """The Skills standard mandates uppercase SKILL.md; README must not refer to skill.md."""
    readme = (repo_root / "README.md").read_text()
    assert "skill.md" not in readme, (
        "README.md references 'skill.md' (lowercase). "
        "The standard is 'SKILL.md'."
    )
