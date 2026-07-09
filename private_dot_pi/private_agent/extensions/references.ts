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
 * Features:
 * - Reference directories are injected into agent system prompt for auto-context
 * - Agent can use @alias/path syntax in read/edit/write tools (resolved automatically)
 * - Dedicated tools: read_reference, list_reference_files, search_reference, list_references
 * - /references command to list and inspect all configured references
 * - Git repos are cloned to ~/.pi/agent/references/<alias>/ on first use
 */

import { execSync } from "node:child_process";
import { existsSync, mkdirSync, readFileSync, readdirSync, statSync } from "node:fs";
import { isAbsolute, join, resolve, relative } from "node:path";
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
  /** Hide from @ autocomplete and agent context but keep available via tools */
  hidden?: boolean;
}

interface ReferencesConfig {
  [alias: string]: Reference | string;
}

interface ResolvedReference {
  alias: string;
  path: string;
  description?: string;
  hidden?: boolean;
  /** True if this was cloned from a git repo into the cache */
  isCached: boolean;
}

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

const GIT_CACHE_DIR = join(getAgentDir(), "references");

const REFERENCE_ALIAS_RE = /@([\w-]+)(\/|$)/g;

// ---------------------------------------------------------------------------
// Config loading
// ---------------------------------------------------------------------------

/**
 * Load and merge references from global and project config files.
 * Project config overrides global config for same-named aliases.
 */
function loadReferences(cwd: string): ReferencesConfig {
  const globalPath = join(getAgentDir(), "references.json");
  const projectPath = join(cwd, CONFIG_DIR_NAME, "references.json");

  let globalConfig: ReferencesConfig = {};
  let projectConfig: ReferencesConfig = {};

  if (existsSync(globalPath)) {
    try {
      globalConfig = JSON.parse(readFileSync(globalPath, "utf-8"));
    } catch (err) {
      console.error(`[references] Failed to load global config: ${err}`);
    }
  }

  if (existsSync(projectPath)) {
    try {
      projectConfig = JSON.parse(readFileSync(projectPath, "utf-8"));
    } catch (err) {
      console.error(`[references] Failed to load project config: ${err}`);
    }
  }

  return { ...globalConfig, ...projectConfig };
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
 * Resolve a reference's path based on which config file it came from.
 *
 * Order:
 * 1. Absolute paths used as-is
 * 2. ~/ resolves to $HOME
 * 3. Relative paths resolve from the config file's parent directory
 *
 * Returns null if the path doesn't exist or can't be resolved.
 */
function resolveRefPath(ref: Reference, configDir: string): string | null {
  const norm = normalizeReference(ref);

  // Local path
  if (norm.path) {
    return resolveSinglePath(norm.path, configDir);
  }

  // Git repository: clone to cache
  if (norm.repository) {
    return null; // handled by ensureGitReference
  }

  return null;
}

function resolveSinglePath(p: string, configDir: string): string | null {
  let resolved: string;

  if (p.startsWith("~/")) {
    resolved = join(process.env.HOME || "", p.slice(2));
  } else if (isAbsolute(p)) {
    resolved = p;
  } else {
    // Relative to config file directory
    resolved = join(configDir, p);
  }

  resolved = resolve(resolved);

  if (existsSync(resolved) && statSync(resolved).isDirectory()) {
    return resolved;
  }

  return null;
}

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
 * Clone or update a git repository reference.
 * Blocks until complete (called during initialization).
 */
function ensureGitReference(alias: string, ref: Reference): string | null {
  const norm = normalizeReference(ref);
  if (!norm.repository) return null;

  const cacheDir = gitCachePath(alias);
  const repoUrl = normalizeGitUrl(norm.repository);

  try {
    if (isGitCached(alias)) {
      // Update existing clone
      const branch = norm.branch || "HEAD";
      if (branch !== "HEAD") {
        execSync(`git -C "${cacheDir}" fetch origin "${branch}"`, {
          stdio: "pipe",
          timeout: 15000,
        });
        execSync(`git -C "${cacheDir}" checkout "${branch}"`, {
          stdio: "pipe",
          timeout: 10000,
        });
      } else {
        execSync(`git -C "${cacheDir}" pull --ff-only`, {
          stdio: "pipe",
          timeout: 15000,
        });
      }
    } else {
      // Fresh clone
      if (!existsSync(GIT_CACHE_DIR)) {
        mkdirSync(GIT_CACHE_DIR, { recursive: true });
      }

      const branchArgs = norm.branch ? ` --branch "${norm.branch}"` : "";
      execSync(`git clone${branchArgs} "${repoUrl}" "${cacheDir}"`, {
        stdio: "pipe",
        timeout: 60000,
      });
    }

    if (existsSync(cacheDir) && statSync(cacheDir).isDirectory()) {
      return cacheDir;
    }
  } catch (err) {
    // If we already have a cached copy, keep using it even if update fails
    if (isGitCached(alias)) {
      return cacheDir;
    }
    console.error(`[references] Failed to clone/pull git repo "${alias}": ${err}`);
  }

  return null;
}

/**
 * Normalize a git URL. Supports GitHub owner/repo shorthand.
 */
function normalizeGitUrl(url: string): string {
  // GitHub owner/repo shorthand
  if (/^[\w.-]+\/[\w.-]+$/.test(url) && !url.includes("://") && !url.includes("@")) {
    return `https://github.com/${url}.git`;
  }
  // Add .git if missing for common patterns
  if (url.startsWith("https://") && !url.endsWith(".git")) {
    return `${url}.git`;
  }
  return url;
}

// ---------------------------------------------------------------------------
// Reference manager
// ---------------------------------------------------------------------------

/**
 * Build the set of resolved references from config, resolving paths
 * and cloning git repos as needed.
 */
function buildReferences(cwd: string): ResolvedReference[] {
  const config = loadReferences(cwd);
  const results: ResolvedReference[] = [];

  // Determine config directories for relative path resolution
  const globalConfigDir = process.env.HOME || "/";
  const projectConfigDir = cwd;

  for (const [alias, raw] of Object.entries(config)) {
    const ref = normalizeReference(raw);
    let resolvedPath: string | null = null;
    let isCached = false;

    if (ref.path) {
      // Try relative to project config first, then global config dir
      resolvedPath = resolveSinglePath(ref.path, projectConfigDir);
      if (!resolvedPath && ref.path !== resolveSinglePath(ref.path, projectConfigDir)) {
        // Also try relative to home (global config)
        resolvedPath = resolveSinglePath(ref.path, globalConfigDir);
      }
    } else if (ref.repository) {
      const cacheDir = ensureGitReference(alias, ref);
      if (cacheDir) {
        resolvedPath = cacheDir;
        isCached = true;
      }
    }

    results.push({
      alias,
      path: resolvedPath || "",
      description: ref.description,
      hidden: ref.hidden,
      isCached,
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
 * Replace all `@alias/...` patterns in a bash command string.
 */
function replaceAtInBash(command: string, refs: ResolvedReference[]): string {
  return command.replace(REFERENCE_ALIAS_RE, (match, alias, separator) => {
    const ref = refs.find((r) => r.alias === alias);
    if (ref && ref.path) {
      return `${ref.path}${separator}`;
    }
    return match;
  });
}

/**
 * Build system prompt context for all visible references.
 */
function buildReferenceContext(refs: ResolvedReference[]): string {
  const visible = refs.filter((r) => r.path && !r.hidden);

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
    let line = `- @${ref.alias}  →  ${ref.path}`;
    if (ref.description) {
      line += `  (${ref.description})`;
    }
    lines.push(line);
  }

  lines.push("", "---", "");
  return lines.join("\n");
}

// ---------------------------------------------------------------------------
// Extension
// ---------------------------------------------------------------------------

export default function referencesExtension(pi: ExtensionAPI) {
  let resolvedRefs: ResolvedReference[] = [];

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
    async execute(toolCallId, params, signal, onUpdate, ctx) {
      const ref = resolvedRefs.find((r) => r.alias === params.alias);

      if (!ref || !ref.path) {
        return {
          content: [
            {
              type: "text",
              text: `Unknown or unresolvable reference alias: "${params.alias}". Use list_references to see available references.`,
            },
          ],
          isError: true,
        };
      }

      const fullPath = join(ref.path, params.path);

      if (!existsSync(fullPath)) {
        return {
          content: [
            {
              type: "text",
              text: `File not found: ${fullPath}\nUse list_reference_files to list contents of "${params.alias}".`,
            },
          ],
          isError: true,
        };
      }

      if (statSync(fullPath).isDirectory()) {
        return {
          content: [
            {
              type: "text",
              text: `"${params.path}" is a directory. Use list_reference_files to list its contents.`,
            },
          ],
          isError: true,
        };
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
    async execute(toolCallId, params) {
      const ref = resolvedRefs.find((r) => r.alias === params.alias);

      if (!ref || !ref.path) {
        return {
          content: [
            {
              type: "text",
              text: `Unknown or unresolvable reference alias: "${params.alias}". Use list_references to see available references.`,
            },
          ],
          isError: true,
        };
      }

      const dirPath = params.path ? join(ref.path, params.path) : ref.path;

      if (!existsSync(dirPath)) {
        return {
          content: [
            {
              type: "text",
              text: `Path not found: ${dirPath}`,
            },
          ],
          isError: true,
        };
      }

      if (!statSync(dirPath).isDirectory()) {
        return {
          content: [
            {
              type: "text",
              text: `"${params.path || "."}" is a file, not a directory.`,
            },
          ],
          isError: true,
        };
      }

      const entries = readdirSync(dirPath, { withFileTypes: true });
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
      "Search for text within reference directories using grep. Searches all visible references by default, or a specific alias.",
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
    async execute(toolCallId, params) {
      const targets = params.alias
        ? resolvedRefs.filter((r) => r.alias === params.alias)
        : resolvedRefs.filter((r) => r.path && !r.hidden);

      if (targets.length === 0) {
        return {
          content: [
            {
              type: "text",
              text: params.alias
                ? `Unknown reference alias: "${params.alias}".`
                : "No visible references configured.",
            },
          ],
          isError: true,
        };
      }

      const maxResults = params.maxResults ?? 30;
      const globArg = params.glob ? ` --include="${params.glob}"` : "";
      const allResults: string[] = [];

      for (const target of targets) {
        if (!target.path) continue;

        try {
          const output = execSync(
            `grep -rn${globArg} -m ${maxResults} -l "${params.pattern}" "${target.path}" 2>/dev/null || true`,
            { encoding: "utf-8", timeout: 10000, maxBuffer: 1024 * 1024 },
          );

          if (output.trim()) {
            const files = output.trim().split("\n").slice(0, maxResults);
            allResults.push(`@${target.alias}  (${files.length} matches):`);
            for (const file of files) {
              const relPath = relative(target.path, file);
              allResults.push(`  @${target.alias}/${relPath}`);
            }
          }
        } catch {
          // grep returns non-zero when no matches found; that's fine
        }
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
      const visible = resolvedRefs.filter((r) => r.path && !r.hidden);

      if (visible.length === 0) {
        return {
          content: [
            {
              type: "text",
              text: "No references configured. Add entries to ~/.pi/agent/references.json or .pi/references.json.",
            },
          ],
        };
      }

      const lines = [`${visible.length} reference(s) configured:\n`];

      for (const ref of visible) {
        lines.push(`@${ref.alias}`);
        lines.push(`  Path: ${ref.path}`);
        if (ref.description) {
          lines.push(`  Description: ${ref.description}`);
        }
        if (ref.isCached) {
          lines.push(`  (git repository, cached locally)`);
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
      const visible = resolvedRefs.filter((r) => r.path && !r.hidden);

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
          ctx.ui.notify(`Reference "${alias}" has no resolved path.`, "warning");
          return;
        }
        ctx.ui.notify(
          `@${ref.alias} → ${ref.path}${ref.description ? " (" + ref.description + ")" : ""}`,
          "info",
        );
        return;
      }

      if (visible.length === 0) {
        const configPaths = [
          join(getAgentDir(), "references.json"),
          join(ctx.cwd, CONFIG_DIR_NAME, "references.json"),
        ];
        ctx.ui.notify(`No references configured. Add to:\n  ${configPaths.join("\n  ")}`, "info");
        return;
      }

      const lines: string[] = [`${visible.length} reference(s) configured:\n`];
      for (const ref of visible) {
        lines.push(`  @${ref.alias}`);
        lines.push(`      Path: ${ref.path}`);
        if (ref.description) lines.push(`      Desc: ${ref.description}`);
        if (ref.isCached) lines.push(`      (git, cached)`);
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
    if (event.toolName === "read" && typeof event.input.path === "string") {
      const resolved = resolveAtPath(event.input.path, resolvedRefs);
      if (resolved) {
        event.input.path = resolved;
      }
    }

    if (event.toolName === "edit" && typeof event.input.path === "string") {
      const resolved = resolveAtPath(event.input.path, resolvedRefs);
      if (resolved) {
        event.input.path = resolved;
      }
    }

    if (event.toolName === "write" && typeof event.input.path === "string") {
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
  // Status indicator
  // -----------------------------------------------------------------------

  function updateStatus(ctx: ExtensionContext) {
    const count = resolvedRefs.filter((r) => r.path && !r.hidden).length;
    if (count > 0) {
      ctx.ui.setStatus("refs", ctx.ui.theme.fg("accent", `refs:${count}`));
    } else {
      ctx.ui.setStatus("refs", undefined);
    }
  }

  // -----------------------------------------------------------------------
  // Initialization
  // -----------------------------------------------------------------------

  pi.on("session_start", async (_event, ctx) => {
    const config = loadReferences(ctx.cwd);
    if (Object.keys(config).length === 0) {
      resolvedRefs = [];
      return;
    }

    resolvedRefs = buildReferences(ctx.cwd);
    updateStatus(ctx);
  });
}
