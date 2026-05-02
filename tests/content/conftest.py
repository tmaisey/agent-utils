"""Shared fixtures for content tests."""

from pathlib import Path

import pytest


REPO_ROOT = Path(__file__).resolve().parents[2]


@pytest.fixture(scope="session")
def repo_root() -> Path:
    """Absolute path to the repo root."""
    return REPO_ROOT


@pytest.fixture(scope="session")
def skill_dirs(repo_root: Path) -> list[Path]:
    """Every top-level directory that contains a SKILL.md."""
    return sorted(
        p.parent for p in repo_root.glob("*/SKILL.md") if p.parent.parent == repo_root
    )
