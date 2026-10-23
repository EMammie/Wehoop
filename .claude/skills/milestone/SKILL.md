---
name: milestone
description: Run one slice of the Wehoop iOS M5 rebuild (S0–S8 in docs/M5-PLAN.md) end to end with the implementer, reviewer, validator and devlog subagents. Usage: /milestone <slice> (e.g. /milestone S2). Stops and reports if review blockers persist after two loops or if evidence is incomplete.
---

# /milestone <slice>

Orchestrate slice `<slice>` of `docs/M5-PLAN.md` through the four agents in `.claude/agents/`. You are the coordinator: you do not implement, review or validate yourself. You delegate, relay results and enforce the gates.

## Steps

1. **Prepare**
   - Read the slice row (scope, acceptance evidence, hours) and the module table in `docs/M5-PLAN.md`, and `CLAUDE.md`.
   - Work on `m5-modular` (or the branch the user names). Confirm a clean tree (`git status --porcelain` empty) and note the base commit for the slice range.
   - If the slice needs the wehoop-api dev stack (S3, S4), confirm with the user that it is running; never start or change anything in `~/Projects/wehoop-api` yourself.

2. **Implement** → spawn `implementer` with: the slice row verbatim, the branch, the base commit, and a reminder of the CLAUDE.md security and dependency rules. Wait for its `## Handoff`.

3. **Review** → spawn `reviewer` with the branch, the commit range and the handoff.
   - If the verdict is `BLOCKED`: send the blocker list back to a new `implementer` run on the same branch. Maximum **two** review loops. If still blocked, stop and report the remaining blockers to the user.
   - `[should]` findings go to the implementer in the same loop if a loop is happening anyway; otherwise list them in the final report.

4. **Validate** → spawn `validator` with the slice id, its acceptance row and the final handoff's commands. Evidence goes to `devlog/evidence/M5.md` (artifacts in `devlog/evidence/M5/`).
   - If the slice's section has any `FAIL` or `NOT RUN`, stop and report which items failed. Do not proceed to devlog.

5. **Devlog** → spawn `devlog` with the slice id and the commit range. It writes `devlog/M5-<slice>-<slug>.md` and posts nothing.

6. **Commit and report**
   - Commit `devlog/` changes on the branch (`docs(m5): evidence + devlog for <slice>`), ending with the Co-Authored-By trailer.
   - Do **not** push, open a PR, merge or tag unless the user asks.
   - Final report: branch, commit range, review verdict, evidence summary table, devlog path, open shoulds/nits, and what the user must do next.

## Gates (never skip)
- No commit to `main`; no push or merge without the user.
- Nobody opens `Legacy/Config.xcconfig`; no provider key enters the new app.
- The validator runs against the exact final commit (re-run if the implementer changed anything after validation).
- The slice is DONE only when every acceptance item is PASS.
