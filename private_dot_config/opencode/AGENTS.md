<!-- CODEGRAPH_START -->

## CodeGraph

In repositories indexed by CodeGraph (a `.codegraph/` directory exists at the repo root), reach for it BEFORE grep/find or reading files when you need to understand or locate code:

- **MCP tool** (when available): `codegraph_explore` answers most code questions in one call — the relevant symbols' verbatim source plus the call paths between them, including dynamic-dispatch hops grep can't follow. Name a file or symbol in the query to read its current line-numbered source. If it's listed but deferred, load it by name via tool search.
- **Shell** (always works): `codegraph explore "<symbol names or question>"` prints the same output.

If there is no `.codegraph/` directory, skip CodeGraph entirely — indexing is the user's decision.
<!-- CODEGRAPH_END -->

## Environment

- OS: Linux/Arch/Wayland (niri); shell: fish + tmux
- Secrets: gnome-keyring
- Packages: paru, pacman, mise — use `mise` for tool management and global npm packages (e.g. `mise use node@24` or `mise use -g npm:vercel@latest`)
- Editors: vscode-insiders, nvim

## Working rules

- Concise, technical, no preamble
- Edit source files in the chezmoi repo (`~/.local/share/chezmoi/`), never live configs; use chezmoi to apply
- Never start dev servers — ask the user to start the dev server and provide the live URL for debugging
