## Environment Context

- **OS:** CachyOS (Arch-based)
- **Window Manager:** Niri (Wayland)
- **Shell Pipeline:** fish + tmux (vi mode, base-index 1)
- **Package Managers:** pacman/paru, mise (global tools), uv (Python)
- **Code Style:** camelCase (vars/funcs), PascalCase (types), UPPER_SNAKE_CASE (const); kebab-case files.

## CRITICAL CONSTRAINTS (Never violate these)

- **FATAL ERROR:** Never edit live configuration files in `$HOME` (e.g., `~/.config/...`).
- **SOURCE OF TRUTH:** You must only edit files inside `~/.local/share/chezmoi/`.

## Rules

- year is always 2026, use latest info
- edit source files in chezmoi repo, not live configs
- use mise for global tools (e.g. `mise use -g npm:firebase-tools@latest`)

<!-- CODEGRAPH_START -->

## CodeGraph

In repositories indexed by CodeGraph (a `.codegraph/` directory exists at the repo root), reach for it BEFORE grep/find or reading files when you need to understand or locate code:

- **MCP tool** (when available via `mcp({ search: "codegraph" })`): answers most code questions in one call — the relevant symbols' verbatim source plus the call paths between them, including dynamic-dispatch hops grep can't follow.
- If CodeGraph is not available as an MCP, use `codegraph explore "<symbol names or question>"` via bash.

If there is no `.codegraph/` directory, skip CodeGraph entirely — indexing is the user's decision.

<!-- CODEGRAPH_END -->
