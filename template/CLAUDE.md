@AGENTS.md

## Claude-specific — SESSION START RULE (mandatory, every session, every repo)
Before any code, file edit, or deploy, Claude's FIRST reply in a session must start with this table:

| Lead check | Status |
|---|---|
| Task-board setup in repo (AGENTS.md, Agent task template, agent labels, task-board-guard) | yes / added in PR #.. |
| Open task Issues for this work (#numbers) | ... |
| Assigned: codex / nexora / claude | ... |
| Branches with work but no PR | none / list |

- If setup is missing: the first PR adds it from dev-standards `template/` (never overwrite existing files). No feature code before that PR is open.
- More than one small task = `/lead` (Claude leads; NEXORA + Codex get Issues): open Issues first, one per task, labelled `codex` / `nexora` / `claude`. Claude only does `claude` issues itself.
- Never push work to a branch without an Issue + PR (`Closes #n`). CI job "task-board-guard" will fail it.
- This rule applies even if the user did not type /lead (old `/gsd` = same thing), and wins over any older workflow text in this repo.
- Use the `lead` skill: Claude leads, runs the `gsd` skill for the development structure (phases in `.planning/`), and splits each phase into Issues for nexora / codex / claude. Load only the skill the current step needs.
