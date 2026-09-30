# AGENTS.md — rules for every AI agent on this repo (Claude, Codex, NEXORA, any other)

Standard: github.com/ranatif2013/dev-standards (same rules in every project).
Owner: Rana (not a developer). He gives ideas and approvals; agents do all technical work.
Project: <PROJECT NAME> — <one line what it does>. Live URL: <url or "not live yet">.

## 1. Read first (nothing else unless needed)
1. `.planning/STATE.md` — what is live, what is in progress, who works on what, next steps.
2. `.planning/PROJECT.md` — business rules and decisions. These are law; never "fix" them.
3. `docs/REGRESSIONS.md` — bugs already fixed once. Do not bring them back.
4. Only then the code files your task touches. Grep, don't read everything. Never read `docs/history/*` whole.

## 2. Where code lives and runs
- Source of truth: GitHub, branch `main` (protected: only PRs with green CI).
- **machine03 = development.** Agents write code here (`~/projects/<repo>`), one branch per task.
- **machine02 = production.** Runs only `main`, updated only with `ops-deploy <project>`. Nobody edits files there.
- No tgz snapshots, patch files or `.bak` copies as a way of moving code. If an emergency hotfix is made on a server, commit it to `main` the same day.

## 3. How to make any change
1. `git pull` on `main`, then branch `<agent>/<short-task>` (e.g. `nexora/sms-reminder`, `codex/fix-login`, `claude/new-report`).
2. Claim it: one line under "In progress" in `.planning/STATE.md` (agent | branch | files/area | date). If another agent claimed the same files, stop and tell Rana.
3. Smallest change that solves the task. No unrelated refactors.
4. Run the project checks (`npm run check` and `npm run lint` for Node projects). Must pass.
5. **Bug fix = regression test** in `tests/` + one row in `docs/REGRESSIONS.md`.
6. Commit, push the branch, open a PR to `main`. CI must be green; Rana merges.
7. After merge: update `.planning/STATE.md` (In progress -> Done, next steps). Keep it under ~120 lines.

## 4. Deploy (production)
- Only `main`, only green CI, only with Rana's explicit OK: `ops-deploy <project>` on machine02 (backup, build, health check, auto-rollback).
- DB schema changes: Rana's literal "approved" + backup. Never destructive (no DROP / DELETE of real data).

## 5. Never
- Never commit secrets (.env, keys, passwords, tokens) or put them in STATE.md or chat.
- Never delete or overwrite another agent's work.
- Never fake success: if something is simulated or unfinished, say so in the UI and STATE.md.
<project-specific "never" rules go here>

## 6. Talking to Rana
Roman Urdu + English, short, tables/lists. Explain results, not code. Ask him only for business decisions, approvals and sign-ins — never to run commands.
