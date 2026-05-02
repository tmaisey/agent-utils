"""README mini-help must list the same top-level commands as `bin/<cli> --help`.

We don't require character-for-character matching (the README abridges); we require
that every command the CLI exposes is mentioned in the README's mini-help block,
and vice versa. Drift (a renamed/added/removed subcommand) fails the test.
"""

from __future__ import annotations

import re
import subprocess
from pathlib import Path

import pytest


# Per-CLI: how to invoke help, and the regex that extracts subcommand names from
# the help output. Each tuple is (skill_dir_name, cli_name, help_args, command_regex,
# readme_block_regex).
#
# command_regex captures the subcommand verbs the CLI documents.
# readme_block_regex captures the fenced code block in README.md that holds the mini-help.

CLI_SPECS = [
    {
        "skill": "managing-git-worktrees",
        "cli": "gwt.sh",
        "help_invocation": ["zsh", "-c", "{cli} help"],
        # gwt's help lists subcommand lines like "  gwt cleanup <branch>..." — capture verb after "gwt "
        "command_re": re.compile(r"^\s*gwt\s+(<branch>|cleanup|list|ports|help)\b", re.MULTILINE),
        # The README mini-help block sits under "### `bin/gwt.sh` (the worktree CLI)" inside ``` ... ```
        "readme_section_marker": "`bin/gwt.sh`",
    },
    {
        "skill": "analysing-security",
        "cli": "security-audit",
        "help_invocation": ["{cli}", "--help"],
        # security-audit's help shows "security-audit [scan] [OPTIONS]" etc.
        "command_re": re.compile(r"^\s*security-audit\s+(\[scan\]|scan|setup|report|version)\b", re.MULTILINE),
        "readme_section_marker": "`bin/security-audit`",
    },
]


def _extract_fenced_block_after(text: str, marker: str) -> str:
    """Return the first fenced code block that follows `marker` in `text`."""
    idx = text.find(marker)
    assert idx != -1, f"marker {marker!r} not found in README"
    after = text[idx:]
    fence = re.search(r"```[a-z]*\n(.*?)```", after, re.DOTALL)
    assert fence, f"no fenced code block after {marker!r}"
    return fence.group(1)


@pytest.mark.parametrize("spec", CLI_SPECS, ids=lambda s: s["cli"])
def test_readme_mini_help_matches_cli(repo_root: Path, spec: dict) -> None:
    cli_path = repo_root / spec["skill"] / "bin" / spec["cli"]
    assert cli_path.exists(), f"CLI not found: {cli_path}"

    invocation = [arg.format(cli=str(cli_path)) for arg in spec["help_invocation"]]
    proc = subprocess.run(invocation, capture_output=True, text=True, timeout=10)
    assert proc.returncode == 0, (
        f"{spec['cli']} help failed: rc={proc.returncode}\nstderr:\n{proc.stderr}"
    )

    cli_commands = set(spec["command_re"].findall(proc.stdout))
    assert cli_commands, (
        f"command_re matched nothing in {spec['cli']} help — regex needs updating.\n"
        f"help output:\n{proc.stdout}"
    )

    readme = (repo_root / "README.md").read_text()
    block = _extract_fenced_block_after(readme, spec["readme_section_marker"])
    readme_commands = set(spec["command_re"].findall(block))

    missing_in_readme = cli_commands - readme_commands
    extra_in_readme = readme_commands - cli_commands

    assert not missing_in_readme, (
        f"README mini-help for {spec['cli']} is missing commands: {sorted(missing_in_readme)}\n"
        f"CLI exposes: {sorted(cli_commands)}\n"
        f"README block:\n{block}"
    )
    assert not extra_in_readme, (
        f"README mini-help for {spec['cli']} mentions commands not in CLI help: "
        f"{sorted(extra_in_readme)}\n"
        f"CLI exposes: {sorted(cli_commands)}"
    )
