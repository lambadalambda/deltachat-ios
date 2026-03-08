# AGENTS

This project includes the following workflow expectations for agent-driven work:

## Development Process

- Use TDD for feature and bug-fix work: `red -> green -> refactor`.
- Start by adding or updating a test that fails for the intended behavior.
- Implement the smallest change needed to make tests pass.
- Refactor only after tests are green, and keep behavior unchanged.

## Commit Discipline

- Commit early and often.
- Keep commits small and topical.
- Do not mix unrelated changes in the same commit.
- Write clear commit messages that explain intent.

## Local iOS Workflow

- Prefer `mise` tasks for repeatable local iOS workflows.
- If `mise` asks for trust, run `mise trust .mise.toml` once in the repo root.
- Use `mise run ios-test-agent-progress-parser` when touching agent progress parsing or rendering behavior.
- Use `mise run ios-build` for a generic iOS build.
- Use `mise run ios-list-devices` to list paired devices.
- For local fork setup, set `IOS_TEAM_ID` and `IOS_BUNDLE_ID`, then run `mise run ios-local-fork-setup`.
- To build, install, and launch on a physical device, run `mise run ios-run-on-device` (optionally set `IOS_DEVICE` and `IOS_CONFIGURATION`).
