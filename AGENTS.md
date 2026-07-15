# System Directives for AI Agent: Chezmoi Dotfiles

You are managing a CachyOS/Linux dotfiles repository using `chezmoi`. You must strictly follow these operational rules to prevent system corruption and blocked processes.

## CRITICAL CONSTRAINTS (Never violate these)

- **FATAL ERROR:** Never edit live configuration files in `$HOME` (e.g., `~/.config/...`).
- **SOURCE OF TRUTH:** You must only edit files inside `~/.local/share/chezmoi/`.
- **FATAL ERROR:** Never run `chezmoi apply` or `chezmoi diff` without arguments. Running them globally evaluates all templates and will hang the system waiting for Bitwarden password prompts.
- **PATHING RULE (Apply):** When applying changes, you MUST use the `--source-path` flag followed by the exact source-relative filename.
- **PATHING RULE (Diff):** When previewing changes, you MUST pass the specific target path to `chezmoi diff` (e.g., `chezmoi diff ~/.config/niri/config.kdl`).

### Practical Example of Editing a Configuration

1. Edit ~/.local/share/chezmoi/private_dot_pi/private_agent/settings.json
2. Preview chezmoi diff ~/.pi/agent/settings.json
3. Apply chezmoi apply --source-path "private_dot_pi/private_agent/settings.json"

## The Modification Workflow

WHEN the user asks you to modify a configuration, you MUST execute these exact steps in order:

1. **Locate Source:** Run `chezmoi source-path <target-path>` to find the exact source file in `~/.local/share/chezmoi/`.
2. **Edit Source:** Make your changes exclusively to the file located in Step 1.
3. **Validate (Niri only):** IF you edited a Niri configuration, run `niri validate` to catch KDL syntax errors before proceeding.
4. **Preview Changes (Diff):** Run `chezmoi diff <target-path>` to verify your changes. **Never** run `chezmoi diff` without the target path. (Alternatively, use `chezmoi apply --source-path "<source-relative-path>" --dry-run`).
5. **Apply:** Run `chezmoi apply --source-path "<source-relative-path>"`.

_Example Application:_ `chezmoi apply --source-path "private_dot_config/niri/config.kdl"` or `chezmoi forget --force --source-path "private_dot_config/niri/config.kdl"` for no prompt

## Chezmoi Naming Cipher

Source filenames encode deployment behavior via specific prefixes and suffixes. Do not rename files without understanding this cipher.

- `dot_` translates to a leading `.` (e.g., `dot_gitconfig` -> `.gitconfig`).
- `private_` sets strict 0600 permissions.
- `executable_` sets `chmod +x`.
- `.tmpl` indicates a Go template. It is processed, and the suffix is stripped.
- Directory paths are encoded with underscores (e.g., `private_dot_config/niri/config.kdl` creates `~/.config/niri/config.kdl`).

## Template & Secrets Protocol

- Template variables are defined in `.chezmoi.toml.tmpl`.
- Undefined variables will crash the deployment (`missingkey=error`).
- Available vars include: `{{ .name }}`, `{{ .email }}`, `{{ .github_username }}`, `{{ .chezmoi.os }}`, `{{ .chezmoi.osRelease.id }}`.
- Retrieve secrets using the Bitwarden CLI exactly like this: `{{ (bitwarden "item" "Item Name").notes | trim }}`.

<!-- CODEGRAPH_START -->

## CodeGraph

In repositories indexed by CodeGraph (a `.codegraph/` directory exists at the repo root), reach for it BEFORE grep/find or reading files when you need to understand or locate code:

- **MCP tool** (when available): `codegraph_explore` answers most code questions in one call — the relevant symbols' verbatim source plus the call paths between them, including dynamic-dispatch hops grep can't follow. Name a file or symbol in the query to read its current line-numbered source. If it's listed but deferred, load it by name via tool search.
- **Shell** (always works): `codegraph explore "<symbol names or question>"` prints the same output.

If there is no `.codegraph/` directory, skip CodeGraph entirely — indexing is the user's decision.

<!-- CODEGRAPH_END -->

<!-- context7 -->

Use Context7 MCP to fetch current documentation whenever the user asks about a library, framework, SDK, API, CLI tool, or cloud service -- even well-known ones like React, Next.js, Prisma, Express, Tailwind, Django, or Spring Boot. This includes API syntax, configuration, version migration, library-specific debugging, setup instructions, and CLI tool usage. Use even when you think you know the answer -- your training data may not reflect recent changes. Prefer this over web search for library docs.

Do not use for: refactoring, writing scripts from scratch, debugging business logic, code review, or general programming concepts.

## Steps

1. Always start with `resolve-library-id` using the library name and the user's question, unless the user provides an exact library ID in `/org/project` format
2. Pick the best match (ID format: `/org/project`) by: exact name match, description relevance, code snippet count, source reputation (High/Medium preferred), and benchmark score (higher is better). If results don't look right, try alternate names or queries (e.g., "next.js" not "nextjs", or rephrase the question). Use version-specific IDs when the user mentions a version
3. `query-docs` with the selected library ID and the user's full question (not single words)
4. Answer using the fetched docs

<!-- context7 -->
