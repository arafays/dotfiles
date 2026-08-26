env: Linux/Arch/Wayland/cachyos (niri)
shell: fish
secrets: gnome-keyring
pkg: [paru, jdx/mise, jdx/aube]
rules:

- edit source files in chezmoi repo, not live configs
- Use mise for tool management & global npm pkgs, like "mise use node@24" for project level or "mise use -g npm:vercel@latest" for global
- never run sudo — ask user for password commands
- Use aube for Node.js package management: `aube add`, `aubr <script>`, `aubx <tool>` (see aube section below)

## aube (Node.js package manager)

aube (/ob/ — "ohb") is the Node.js package manager: a fast, security-focused pnpm/npm
alternative. Three binaries ship together — they're the same tool dispatching on argv[0]:

- `aube` — full package manager (add/install/run/exec/ci/...)
- `aubr` — shorthand for `aube run` (run a package.json script or local bin)
- `aubx` — shorthand for `aube dlx` (run a one-off tool from a throwaway env)

Key behavior:

- **Auto-install before scripts.** `aubr test`, `aube test`, `aube exec vitest` check install
  freshness first: if package.json or the lockfile changed they install, else they go
  straight to the script. Don't run a separate `aube install` first — just run the
  script/binary you actually want.
- **Existing lockfiles are read/written in place.** A project keeps its existing
  pnpm-lock.yaml / package-lock.json / yarn.lock / bun.lock. New projects default to
  aube-lock.yaml.
- **Global content-addressable store** — package files are shared across projects.

Daily commands:

    aube add react              # add a dependency
    aube add -D vitest          # add a dev dependency
    aube remove react           # remove a dependency
    aubr build                  # run a script, auto-installing first
    aube exec vitest            # run a local binary, auto-installing first
    aubx cowsay hi              # one-off tool (local bin, else throwaway install)
    aubx -p create-vite create-vite my-app   # package name != binary name
    aube ci                     # clean frozen install for CI

Security: dependency lifecycle scripts are deny-by-default (approve with
`aube approve-builds` or `allowBuilds:` in aube-workspace.yaml). `paranoid: true` in
aube-workspace.yaml enables the full strict bundle (build jail, no-downgrade trust,
24h cooling on new releases, strict integrity/advisory checks).

Docs: https://aube.jdx.dev/

<!-- CODEGRAPH_START -->

## CodeGraph

In repositories indexed by CodeGraph (a `.codegraph/` directory exists at the repo root), reach for it BEFORE grep/find or reading files when you need to understand or locate code:

- **MCP tool** (when available): `codegraph_explore` answers most code questions in one call — the relevant symbols' verbatim source plus the call paths between them, including dynamic-dispatch hops grep can't follow. Name a file or symbol in the query to read its current line-numbered source. If it's listed but deferred, load it by name via tool search.
- **Shell** (always works): `codegraph explore "<symbol names or question>"` prints the same output.

If there is no `.codegraph/` directory, skip CodeGraph entirely — indexing is the user's decision.

<!-- CODEGRAPH_END -->
