/**
 * References Extension
 *
 * OpenCode-style References for Pi: configure aliases to external directories
 * (local paths or git repos) and use them as context for the agent.
 *
 * Config files (merged, project takes precedence):
 * - ~/.pi/agent/references.json (global)
 * - <cwd>/.pi/references.json (project-local)
 *
 * Config format (references.json):
 * ```json
 * {
 *   "docs": {
 *     "path": "/home/user/projects/docs",
 *     "description": "Product documentation for reference"
 *   },
 *   "sdk": {
 *     "repository": "github.com/org/sdk",
 *     "branch": "main",
 *     "description": "JavaScript SDK source"
 *   },
 *   "shared": "../shared-lib"
 * }
 * ```
 *
 * String shorthand resolves to `path`.
 * Paths can be absolute, ~/-prefixed, or relative to the config file's directory.
 *
 * Semantics (mirrors OpenCode references):
 * - Only references WITH a `description` are advertised in the agent system
 *   prompt. Undescribed references stay available via the dedicated tools and
 *   @alias/path syntax but are not auto-advertised.
 * - `hidden` only affects autocomplete (a TUI concept Pi does not have), so it
 *   is accepted for config compatibility and does not remove a described
 *   reference from agent context.
 * - Git repositories are cloned to ~/.pi/agent/references/<alias>/ on first
 *   use. Clones/updates run in the background so session start is never
 *   blocked; the reference becomes available as soon as the clone completes.
 *
 * Features:
 * - Reference directories are injected into agent system prompt for auto-context
 * - Agent can use @alias/path syntax in read/edit/write tools (resolved automatically)
 * - Dedicated tools: read_reference, list_reference_files, search_reference, list_references
 * - /references command to list and inspect all configured references
 */

import { execFileSync, spawn } from "node:child_process";
import { existsSync, mkdirSync, readFileSync, readdirSync, statSync } from "node:fs";
import { isAbsolute, join, relative, resolve, sep } from "node:path";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { CONFIG_DIR_NAME, getAgentDir } from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

interface Reference {
  /** Local path to the reference directory (mutually exclusive with repository) */
  path?: string;
  /** Git repository URL or GitHub owner/repo shorthand (e.g. "user/repo") */
  repository?: string;
  /** Git branch or tag (only used with repository) */
  branch?: string;
  /** Description injected into agent context. Only refs with descriptions are advertised. */
  description?: string;
  /** Hide from @ autocomplete. Pi has no @ autocomplete, so this is a no-op kept for OpenCode config compatibility. */
  hidden?: boolean;
}

interface ReferencesConfig {
  [alias: string]: Reference | string;
}

/** A config entry paired with the base directory for relative path resolution. */
interface LoadedReference {
  ref: Reference;
  baseDir: string;
}

interface ResolvedReference {
  alias: string;
  path: string;
  description?: string;
  hidden?: boolean;
  /** True if this was cloned from a git repo into the cache */
  isCached: boolean;
  /** Present when this is a git-backed reference. */
  repository?: string;
  branch?: string;
}

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

const GIT_CACHE_DIR = join(getAgentDir(), "references");

// ---------------------------------------------------------------------------
// Config loading
// ---------------------------------------------------------------------------

/**
 * Load and merge references from global and project config files.
 * Project config overrides global config for same-named aliases.
 *
 * Relative-path base mirrors OpenCode: the project config conceptually lives at
 * the project root, so project-relative paths resolve against `cwd`; the global
 * config resolves relative paths against `$HOME`.
 */
function loadReferences(cwd: string): Record<string, LoadedReference> {
  const globalPath = join(getAgentDir(), "references.json");
  const projectPath = join(cwd, CONFIG_DIR_NAME, "references.json");
  const homeDir = process.env.HOME || "/";

  const merged: Record<string, LoadedReference> = {};

  const readConfig = (path: string): ReferencesConfig => {
    if (!existsSync(path)) return {};
    try {
      return JSON.parse(readFileSync(path, "utf-8"));
    } catch (err) {
      console.error(`[references] Failed to load config ${path}: ${err}`);
      return {};
    }
  };

  const globalConfig = readConfig(globalPath);
  for (const [alias, raw] of Object.entries(globalConfig)) {
    merged[alias] = { ref: normalizeReference(raw), baseDir: homeDir };
  }

  const projectConfig = readConfig(projectPath);
  for (const [alias, raw] of Object.entries(projectConfig)) {
    merged[alias] = { ref: normalizeReference(raw), baseDir: cwd };
  }

  return merged;
}

/**
 * Normalize a config value (string shorthand or object) to a Reference object.
 */
function normalizeReference(raw: Reference | string): Reference {
  if (typeof raw === "string") {
    return { path: raw };
  }
  return raw;
}

/**
 * Resolve a local path to an existing directory.
 *
 * 1. Absolute paths used as-is
 * 2. ~/ resolves to $HOME
 * 3. Relative paths resolve from the given config directory
 *
 * Returns null if the path doesn't exist or isn't a directory.
 */
function resolveSinglePath(p: string, configDir: string): string | null {
  let resolvedPath: string;

  if (p.startsWith("~/")) {
    resolvedPath = join(process.env.HOME || "", p.slice(2));
  } else if (isAbsolute(p)) {
    resolvedPath = p;
  } else {
    resolvedPath = join(configDir, p);
  }

  resolvedPath = resolve(resolvedPath);

  if (existsSync(resolvedPath) && statSync(resolvedPath).isDirectory()) {
    return resolvedPath;
  }

  return null;
}

/**
 * Resolve `subPath` against `rootPath` and require the result to stay inside
 * the root. Returns null when the result escapes the root (path traversal).
 */
function resolveWithinRoot(rootPath: string, subPath: string): string | null {
  const resolvedPath = resolve(rootPath, subPath);
  const rel = relative(rootPath, resolvedPath);
  if (rel === ".." || rel.startsWith(`..${sep}`) || isAbsolute(rel)) {
    return null;
  }
  return resolvedPath;
}

// ---------------------------------------------------------------------------
// Git references
// ---------------------------------------------------------------------------

/**
 * Get the cache directory for a git-backed reference.
 */
function gitCachePath(alias: string): string {
  return join(GIT_CACHE_DIR, alias);
}

/**
 * Check if a git reference is already cached locally.
 */
function isGitCached(alias: string): boolean {
  const cacheDir = gitCachePath(alias);
  return existsSync(cacheDir) && statSync(cacheDir).isDirectory();
}

/**
 * Normalize a git URL. Supports GitHub owner/repo shorthand, host/path
 * references, and full URLs.
 */
function normalizeGitUrl(url: string): string {
  if (url.includes("://") || url.includes("@")) {
    return url;
  }
  // GitHub owner/repo shorthand: "Effect-TS/effect"
  if (/^[\w.-]+\/[\w.-]+$/.test(url)) {
    return `https://github.com/${url}.git`;
  }
  // host/path reference: "github.com/org/repo"
  if (/^[\w.-]+\/[\w.-]+\/[\w.-]+$/.test(url)) {
    return `https://${url}.git`;
  }
  return url;
}

/** Run a git command asynchronously, resolving with the exit code. */
function runGit(args: string[], cwd?: string): Promise<number | null> {
  return new Promise((resolvePromise) => {
    const child = spawn("git", args, { cwd, stdio: "ignore" });
    child.on("close", (code) => resolvePromise(code));
    child.on("error", () => resolvePromise(null));
  });
}

/**
 * Clone or update a git reference in the background.
 * Returns true when the reference is (still) available in the cache afterwards.
 */
async function refreshGitReference(alias: string, ref: Reference): Promise<boolean> {
  const norm = normalizeReference(ref);
  if (!norm.repository) return false;

  const cacheDir = gitCachePath(alias);
  const repoUrl = normalizeGitUrl(norm.repository);

  try {
    if (isGitCached(alias)) {
      // Update existing clone.
      if (norm.branch) {
        await runGit(["fetch", "origin", norm.branch], cacheDir);
        await runGit(["checkout", norm.branch], cacheDir);
      } else {
        await runGit(["pull", "--ff-only"], cacheDir);
      }
      return isGitCached(alias);
    }

    // Fresh clone.
    if (!existsSync(GIT_CACHE_DIR)) {
      mkdirSync(GIT_CACHE_DIR, { recursive: true });
    }
    const cloneArgs = ["clone", ...(norm.branch ? ["--branch", norm.branch] : []), repoUrl, cacheDir];
    const code = await runGit(cloneArgs);
    return code === 0 && isGitCached(alias);
  } catch (err) {
    console.error(`[references] Failed to clone/pull git repo "${alias}": ${err}`);
    // Keep using the cached copy if we have one.
    return isGitCached(alias);
  }
}

// ---------------------------------------------------------------------------
// Reference resolution
// ---------------------------------------------------------------------------

/**
 * Build the resolved reference list from config, resolving local paths and
 * scheduling background git clones for git-backed references.
 *
 * `onGitReady` is invoked after a first-time git clone completes so the caller
 * can re-resolve and update status.
 */
function buildReferences(cwd: string, onGitReady?: () => void): ResolvedReference[] {
  const config = loadReferences(cwd);
  const results: ResolvedReference[] = [];

  for (const [alias, entry] of Object.entries(config)) {
    const ref = entry.ref;
    let resolvedPath: string | null = null;
    let isCached = false;

    if (ref.path) {
      resolvedPath = resolveSinglePath(ref.path, entry.baseDir);
    } else if (ref.repository) {
      if (isGitCached(alias)) {
        resolvedPath = gitCachePath(alias);
        isCached = true;
        // Refresh in the background; never block session start.
        void refreshGitReference(alias, ref);
      } else {
        // Clone in the background and re-resolve when it finishes.
        void (async () => {
          const ok = await refreshGitReference(alias, ref);
          if (ok) onGitReady?.();
        })();
      }
    }

    results.push({
      alias,
      path: resolvedPath || "",
      description: ref.description,
      hidden: ref.hidden,
      isCached,
      repository: ref.repository,
      branch: ref.branch,
    });
  }

  return results;
}

/**
 * Resolve an `@alias/rest/of/path` or `@alias` string to the real filesystem path.
 * Returns null if the alias is unknown.
 */
function resolveAtPath(input: string, refs: ResolvedReference[]): string | null {
  for (const ref of refs) {
    if (!ref.path) continue;

    // Exact match: @alias
    if (input === `@${ref.alias}`) {
      return ref.path;
    }

    // Prefix match: @alias/rest/of/path
    const prefix = `@${ref.alias}/`;
    if (input.startsWith(prefix)) {
      return join(ref.path, input.slice(prefix.length));
    }
  }

  return null;
}

/**
 * Replace `@alias/...` patterns in a bash command string.
 * The `@` must be at a word boundary (start or preceded by whitespace/quote) so
 * `user@host/...` URLs and emails are not mangled.
 */
function replaceAtInBash(command: string, refs: ResolvedReference[]): string {
  return command.replace(/(^|[\s"'=([{])@([\w-]+)(\/|$)/g, (match, prefix, alias, separator) => {
    const ref = refs.find((r) => r.alias === alias);
    if (ref && ref.path) {
      return `${prefix}${ref.path}${separator}`;
    }
    return match;
  });
}

/**
 * Build system prompt context. Mirrors OpenCode: only references that have a
 * `description` are advertised. `hidden` does not suppress a described ref.
 */
function buildReferenceContext(refs: ResolvedReference[]): string {
  const visible = refs.filter((r) => r.path && r.description);

  if (visible.length === 0) return "";

  const lines: string[] = [
    "",
    "---",
    "## Available References",
    "",
    "External directories configured as references. Use @alias/path syntax in read, edit,",
    "or write tools — the extension resolves them automatically.",
    "You can also use the dedicated tools: read_reference, list_reference_files,",
    "search_reference, and list_references.",
    "",
  ];

  for (const ref of visible) {
    lines.push(`- @${ref.alias}  →  ${ref.path}  (${ref.description})`);
  }

  lines.push("", "---", "");
  return lines.join("\n");
}

// ---------------------------------------------------------------------------
// Extension
// ---------------------------------------------------------------------------

export default function referencesExtension(pi: ExtensionAPI) {
  let resolvedRefs: ResolvedReference[] = [];
  let lastCtx: ExtensionContext | undefined;

  function updateStatus(ctx: ExtensionContext) {
    const count = resolvedRefs.filter((r) => r.path).length;
    if (count > 0) {
      ctx.ui.setStatus("refs", ctx.ui.theme.fg("accent", `refs:${count}`));
    } else {
      ctx.ui.setStatus("refs", undefined);
    }
  }

  function recompute(cwd: string, ctx: ExtensionContext) {
    lastCtx = ctx;
    const config = loadReferences(cwd);
    if (Object.keys(config).length === 0) {
      resolvedRefs = [];
      return;
    }
    resolvedRefs = buildReferences(cwd, () => {
      if (lastCtx) {
        resolvedRefs = buildReferences(cwd, () => {});
        updateStatus(lastCtx);
      }
    });
    updateStatus(ctx);
  }

  // -----------------------------------------------------------------------
  // Tools
  // -----------------------------------------------------------------------

  pi.registerTool({
    name: "read_reference",
    label: "Read Reference",
    description:
      "Read a file from a configured reference directory. Provide the alias and path within the reference.",
    promptSnippet: "Read files from configured reference directories",
    promptGuidelines: [
      "Use read_reference to read files from external reference directories configured by the user.",
      "You can also use @alias/path syntax directly in the read tool for convenience.",
    ],
    parameters: Type.Object({
      alias: Type.String({ description: "Reference alias (e.g. 'docs', 'sdk')" }),
      path: Type.String({
        description: "Path within the reference directory (e.g. 'api/overview.md')",
      }),
      offset: Type.Optional(
        Type.Number({ description: "Line number to start reading from (1-indexed)" }),
      ),
      limit: Type.Optional(Type.Number({ description: "Maximum number of lines to read" })),
    }),
    async execute(_toolCallId, params) {
      const ref = resolvedRefs.find((r) => r.alias === params.alias);

      if (!ref || !ref.path) {
        throw new Error(
          `Unknown or unresolvable reference alias: "${params.alias}". Use list_references to see available references.`,
        );
      }

      const fullPath = resolveWithinRoot(ref.path, params.path);

      if (!fullPath || !existsSync(fullPath)) {
        throw new Error(
          `File not found within "${params.alias}": ${params.path}\nUse list_reference_files to list contents of "${params.alias}".`,
        );
      }

      if (statSync(fullPath).isDirectory()) {
        throw new Error(`"${params.path}" is a directory. Use list_reference_files to list its contents.`);
      }

      const content = readFileSync(fullPath, "utf-8");
      const lines = content.split("\n");
      const offset = params.offset ?? 1;
      const limit = params.limit ?? lines.length;
      const selected = lines.slice(offset - 1, offset - 1 + limit);
      const total = lines.length;
      const startLine = offset;
      const endLine = Math.min(offset + selected.length - 1, total);

      return {
        content: [
          {
            type: "text",
            text: [
              `File: ${fullPath}`,
              `${total} lines  (showing ${startLine}–${endLine})`,
              "---",
              ...selected.map((line: string, i: number) => {
                const lineNum = startLine + i;
                return `${String(lineNum).padStart(4, " ")} │ ${line}`;
              }),
              "---",
            ].join("\n"),
          },
        ],
      };
    },
  });

  pi.registerTool({
    name: "list_reference_files",
    label: "List Reference Files",
    description: "List files and directories within a configured reference directory.",
    promptSnippet: "List files in configured reference directories",
    parameters: Type.Object({
      alias: Type.String({ description: "Reference alias (e.g. 'docs', 'sdk')" }),
      path: Type.Optional(
        Type.String({ description: "Subdirectory path within the reference (default: root)" }),
      ),
    }),
    async execute(_toolCallId, params) {
      const ref = resolvedRefs.find((r) => r.alias === params.alias);

      if (!ref || !ref.path) {
        throw new Error(
          `Unknown or unresolvable reference alias: "${params.alias}". Use list_references to see available references.`,
        );
      }

      const dirPath = params.path ? resolveWithinRoot(ref.path, params.path) : ref.path;

      if (!dirPath || !existsSync(dirPath)) {
        throw new Error(`Path not found within "${params.alias}": ${params.path || "."}`);
      }

      if (!statSync(dirPath).isDirectory()) {
        throw new Error(`"${params.path || "."}" is a file, not a directory.`);
      }

      const entries = readdirSync(dirPath, { withFileTypes: true }).sort((a, b) =>
        a.name.localeCompare(b.name),
      );
      const lines = [`Reference: @${params.alias}  →  ${ref.path}`];

      if (params.path) {
        lines.push(`Directory: ${dirPath}`);
      }

      lines.push("");

      for (const entry of entries) {
        const prefix = entry.isDirectory() ? "📁 " : "📄 ";
        const suffix = entry.isDirectory() ? "/" : "";
        lines.push(`  ${prefix}${entry.name}${suffix}`);
      }

      lines.push("", `${entries.length} entries`);

      return {
        content: [
          {
            type: "text",
            text: lines.join("\n"),
          },
        ],
      };
    },
  });

  pi.registerTool({
    name: "search_reference",
    label: "Search Reference",
    description:
      "Search for text within reference directories using grep. Searches all configured references by default, or a specific alias.",
    promptSnippet: "Search text within reference directories",
    parameters: Type.Object({
      pattern: Type.String({ description: "Search pattern (passed to grep)" }),
      alias: Type.Optional(
        Type.String({
          description: "Optional reference alias to scope the search (e.g. 'docs')",
        }),
      ),
      glob: Type.Optional(Type.String({ description: "File glob pattern (e.g. '*.md', '*.ts')" })),
      maxResults: Type.Optional(
        Type.Number({
          description: "Maximum number of results to return (default: 30)",
        }),
      ),
    }),
    async execute(_toolCallId, params) {
      const targets = params.alias
        ? resolvedRefs.filter((r) => r.alias === params.alias)
        : resolvedRefs.filter((r) => r.path);

      if (targets.length === 0) {
        throw new Error(
          params.alias
            ? `Unknown reference alias: "${params.alias}".`
            : "No references configured.",
        );
      }

      const maxResults = params.maxResults ?? 30;
      const perTarget = Math.max(1, maxResults);
      const allResults: string[] = [];
      let totalMatches = 0;

      for (const target of targets) {
        if (!target.path) continue;

        // Pass the pattern as a positional argument (no shell) to avoid command
        // injection. `--` guards against patterns starting with `-`.
        const args = [
          "-rnI",
          "-n",
          "-m",
          String(perTarget),
          ...(params.glob ? ["--include", params.glob] : []),
          "--",
          params.pattern,
          target.path,
        ];

        let output = "";
        try {
          output = execFileSync("grep", args, {
            encoding: "utf-8",
            timeout: 10000,
            maxBuffer: 4 * 1024 * 1024,
          });
        } catch (err: unknown) {
          const e = err as { status?: number; stderr?: Buffer | string; message?: string };
          if (e?.status === 1) {
            continue; // no matches in this reference
          }
          const detail = e?.stderr ? String(e.stderr).trim() : e?.message ?? String(err);
          throw new Error(`grep failed for @${target.alias}: ${detail}`);
        }

        const matches = output.trim().split("\n").filter(Boolean);
        if (matches.length === 0) continue;

        const formatted: string[] = [];
        for (const matchLine of matches.slice(0, maxResults - totalMatches)) {
          const parsed = parseGrepLine(matchLine, target.path);
          if (parsed) {
            formatted.push(
              `  @${target.alias}/${parsed.relPath}:${parsed.lineNo}: ${parsed.content}`,
            );
          }
        }
        if (formatted.length > 0) {
          totalMatches += formatted.length;
          allResults.push(`@${target.alias}  (${formatted.length} matches):`);
          allResults.push(...formatted);
        }
        if (totalMatches >= maxResults) break;
      }

      if (allResults.length === 0) {
        return {
          content: [
            {
              type: "text",
              text: `No matches found for "${params.pattern}"${params.alias ? ` in @${params.alias}` : " in any reference"}.`,
            },
          ],
        };
      }

      return {
        content: [
          {
            type: "text",
            text: [
              `Search results for: ${params.pattern}`,
              "---",
              ...allResults,
              "---",
              `Use read_reference to view a matched file, or use the @alias/path syntax in the read tool.`,
            ].join("\n"),
          },
        ],
      };
    },
  });

  pi.registerTool({
    name: "list_references",
    label: "List References",
    description:
      "List all configured reference directories with their aliases, paths, and descriptions.",
    promptSnippet: "Show all configured reference directories",
    parameters: Type.Object({}),
    async execute() {
      const available = resolvedRefs.filter((r) => r.path);

      if (available.length === 0) {
        return {
          content: [
            {
              type: "text",
              text: "No references configured. Add entries to ~/.pi/agent/references.json or .pi/references.json.",
            },
          ],
        };
      }

      const lines = [`${available.length} reference(s) configured:\n`];

      for (const ref of available) {
        lines.push(`@${ref.alias}`);
        lines.push(`  Path: ${ref.path}`);
        if (ref.description) {
          lines.push(`  Description: ${ref.description}`);
        }
        if (ref.isCached) {
          lines.push(`  (git repository, cached locally)`);
        }
        if (ref.hidden) {
          lines.push(`  (hidden)`);
        }
        lines.push("");
      }

      lines.push("Use @alias/path in read/edit/write tools, or use the dedicated reference tools.");

      return {
        content: [
          {
            type: "text",
            text: lines.join("\n"),
          },
        ],
      };
    },
  });

  // -----------------------------------------------------------------------
  // Command: /references
  // -----------------------------------------------------------------------

  pi.registerCommand("references", {
    description: "List configured reference directories",
    handler: async (args, ctx) => {
      const available = resolvedRefs.filter((r) => r.path);

      if (args?.trim()) {
        // Show details for a specific reference
        const alias = args.trim();
        const ref = resolvedRefs.find((r) => r.alias === alias);
        if (!ref) {
          const aliases = resolvedRefs.map((r) => r.alias).join(", ") || "(none)";
          ctx.ui.notify(`Unknown reference "${alias}". Available: ${aliases}`, "error");
          return;
        }
        if (!ref.path) {
          ctx.ui.notify(
            `Reference "${alias}"${ref.repository ? ` (${ref.repository})` : ""} is still resolving.`,
            "warning",
          );
          return;
        }
        ctx.ui.notify(
          `@${ref.alias} → ${ref.path}${ref.description ? " (" + ref.description + ")" : ""}`,
          "info",
        );
        return;
      }

      if (available.length === 0) {
        const configPaths = [
          join(getAgentDir(), "references.json"),
          join(ctx.cwd, CONFIG_DIR_NAME, "references.json"),
        ];
        ctx.ui.notify(`No references configured. Add to:\n  ${configPaths.join("\n  ")}`, "info");
        return;
      }

      const lines: string[] = [`${available.length} reference(s) configured:\n`];
      for (const ref of available) {
        lines.push(`  @${ref.alias}`);
        lines.push(`      Path: ${ref.path}`);
        if (ref.description) lines.push(`      Desc: ${ref.description}`);
        if (ref.isCached) lines.push(`      (git, cached)`);
        if (ref.hidden) lines.push(`      (hidden)`);
        lines.push("");
      }
      ctx.ui.notify(lines.join("\n"), "info");
    },
  });

  // -----------------------------------------------------------------------
  // System prompt injection
  // -----------------------------------------------------------------------

  pi.on("before_agent_start", async (event) => {
    const context = buildReferenceContext(resolvedRefs);
    if (context) {
      return {
        systemPrompt: `${event.systemPrompt}\n${context}`,
      };
    }
  });

  // -----------------------------------------------------------------------
  // @alias/ path resolution in built-in tools
  // -----------------------------------------------------------------------

  pi.on("tool_call", async (event) => {
    if (!event.input || !resolvedRefs.length) return;

    // Resolve @alias/ in read/edit/write path arguments
    if (
      (event.toolName === "read" || event.toolName === "edit" || event.toolName === "write") &&
      typeof event.input.path === "string"
    ) {
      const resolved = resolveAtPath(event.input.path, resolvedRefs);
      if (resolved) {
        event.input.path = resolved;
      }
    }

    // Resolve @alias/ in bash commands
    if (event.toolName === "bash" && typeof event.input.command === "string") {
      const replaced = replaceAtInBash(event.input.command, resolvedRefs);
      if (replaced !== event.input.command) {
        event.input.command = replaced;
      }
    }
  });

  // -----------------------------------------------------------------------
  // Initialization
  // -----------------------------------------------------------------------

  pi.on("session_start", async (_event, ctx) => {
    lastCtx = ctx;
    const config = loadReferences(ctx.cwd);
    if (Object.keys(config).length === 0) {
      resolvedRefs = [];
      return;
    }

    resolvedRefs = buildReferences(ctx.cwd, () => {
      if (lastCtx) {
        resolvedRefs = buildReferences(ctx.cwd, () => {});
        updateStatus(lastCtx);
      }
    });
    updateStatus(ctx);
  });
}

/**
 * Parse a `grep -rn` output line (`<path>:<line>:<content>`) into parts,
 * with the path made relative to the reference root.
 */
function parseGrepLine(
  line: string,
  rootPath: string,
): { relPath: string; lineNo: string; content: string } | null {
  const firstColon = line.indexOf(":");
  if (firstColon === -1) return null;
  const file = line.slice(0, firstColon);
  const rest = line.slice(firstColon + 1);

  const secondColon = rest.indexOf(":");
  if (secondColon === -1) return null;
  const lineNo = rest.slice(0, secondColon);
  const content = rest.slice(secondColon + 1);

  return { relPath: relative(rootPath, file), lineNo, content };
}
