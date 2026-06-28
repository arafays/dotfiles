## Environment Context

- **OS:** CachyOS (Arch-based)
- **Window Manager:** Niri (Wayland)
- **Shell Pipeline:** fish + tmux (vi mode, base-index 1)
- **Package Managers:** pacman/paru, mise (global tools), uv (Python)
- **Code Style:** camelCase (vars/funcs), PascalCase (types), UPPER_SNAKE_CASE (const); kebab-case files.

## CRITICAL CONSTRAINTS (Never violate these)

- **FATAL ERROR:** Never edit live configuration files in `$HOME` (e.g., `~/.config/...`).
- **SOURCE OF TRUTH:** You must only edit files inside `~/.local/share/chezmoi/`.

<!-- CODEGRAPH_START -->

## CodeGraph

In repositories indexed by CodeGraph (a `.codegraph/` directory exists at the repo root), reach for it BEFORE grep/find or reading files when you need to understand or locate code:

- **MCP tool** (when available): `codegraph_explore` answers most code questions in one call — the relevant symbols' verbatim source plus the call paths between them, including dynamic-dispatch hops grep can't follow. Name a file or symbol in the query to read its current line-numbered source. If it's listed but deferred, load it by name via tool search.
- **Shell** (always works): `codegraph explore "<symbol names or question>"` prints the same output.

If there is no `.codegraph/` directory, skip CodeGraph entirely — indexing is the user's decision.

<!-- CODEGRAPH_END -->
