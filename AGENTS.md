# AGENTS

- Distro: Arch (use `yay`); Shell: `zsh`; Editors: VS Code Insiders, `nvim`; `tmux`.
- Global profile: `~/.config/opencode/profile.yaml` (agents should read this on start).
- Search: use `rg` only; do not call `grep` (alias points to `rg`).

Build/Lint/Test:

- JS/TS: format `npx @biomejs/biome format .`; lint `npx @biomejs/biome lint .`.
- Node tests: all `npm test`; single Jest `npm test -- path/to/file.test.ts`; single Vitest `npx vitest run path/to/file.test.ts -t "name"`.
- Python: lint `ruff check . && mypy .`; tests `pytest`; single `pytest path/to/test.py::TestClass::test_case -k "pattern"`.
- Prefer running via mise: `mise exec -- <cmd>` to ensure correct tool versions.

Code Style:

- Imports: absolute from roots; group stdlib/third‑party/local; sort A→Z; no unused.
- Formatting: Biome; width 100; single quotes; semicolons in TS; trailing commas.
- Types: TS strict; prefer `unknown` + narrowing; Python: type hints; mypy strict.
- Naming: camelCase vars/functions; PascalCase types/classes; UPPER_SNAKE_CASE constants; files kebab-case (TS/JS) or snake_case (py).
- Errors: typed Result/custom Error at boundaries; never swallow; log context; validate early.
- Async: no floating promises; await/return; try/catch awaited calls; timeouts/cancellation for I/O.

Conventions:

- Use `mise` for tool versions; prefer repo `.mise.toml` when present.
- Activate tools if missing: `mise use -g node@22 python@3.12 go@1.22 flutter@stable`.
- Per-repo: add `.mise.toml` with `[tools]` entries; run `mise install`.
- Interactive shells: add `eval "$(~/.local/bin/mise activate zsh)"` to `~/.zshrc`.
- GitHub Instructions: honor `.github/instructions/*.instructions.md` (topic-specific). Prefer the most specific instruction for the task; fall back to `.github/copilot-instructions.md`, then `.cursor/rules/` or `.cursorrules`.
- Add `build`, `lint`, `test`, `format` scripts; keep commands env‑agnostic.
- Editors: VS Code Insiders and `nvim`; tmux sessions; dotfiles via chezmoi.
