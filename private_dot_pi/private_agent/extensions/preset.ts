/**
 * Preset Extension
 *
 * Allows defining named presets that configure model, thinking level, tools,
 * and system prompt instructions. Presets are defined in JSON config files
 * and can be activated via CLI flag, /preset command, or Ctrl+Shift+U to cycle.
 *
 * Config files (merged, project takes precedence):
 * - ~/.pi/agent/presets.json (global)
 * - <cwd>/.pi/presets.json (project-local)
 *
 * The `tools` and `skills` fields support wildcard and negation patterns:
 * - `["*"]` — allow all tools/skills
 * - `["*", "!read"]` — allow all except `read`
 * - `["!read", "!edit"]` — allow all except `read` and `edit` (implicit wildcard)
 * - `["read", "bash", "edit", "write"]` — exact allow list (original behavior)
 *
 * Skill names are matched against the skills loaded at startup (e.g., `agent-browser`).
 * When a preset specifies `skills`, instructions are injected into the system prompt
 * telling the agent which skills are available or unavailable.
 *
 * Example presets.json:
 * ```json
 * {
 *   "plan": {
 *     "provider": "openai-codex",
 *     "model": "gpt-5.2-codex",
 *     "thinkingLevel": "high",
 *     "tools": ["read", "grep", "find", "ls"],
 *     "instructions": "You are in PLANNING MODE. Your job is to deeply understand the problem and create a detailed implementation plan.\n\nRules:\n- DO NOT make any changes. You cannot edit or write files.\n- Read files IN FULL (no offset/limit) to get complete context. Partial reads miss critical details.\n- Explore thoroughly: grep for related code, find similar patterns, understand the architecture.\n- Ask clarifying questions if requirements are ambiguous. Do not assume.\n- Identify risks, edge cases, and dependencies before proposing solutions.\n\nOutput:\n- Create a structured plan with numbered steps.\n- For each step: what to change, why, and potential risks.\n- List files that will be modified.\n- Note any tests that should be added or updated.\n\nWhen done, ask the user if they want you to:\n1. Write the plan to a markdown file (e.g., PLAN.md)\n2. Create a GitHub issue with the plan\n3. Proceed to implementation (they should switch to 'implement' preset)"
 *   },
 *   "implement": {
 *     "provider": "anthropic",
 *     "model": "claude-sonnet-4-5",
 *     "thinkingLevel": "high",
 *     "tools": ["read", "bash", "edit", "write"],
 *     "instructions": "You are in IMPLEMENTATION MODE. Your job is to make focused, correct changes.\n\nRules:\n- Keep scope tight. Do exactly what was asked, no more.\n- Read files before editing to understand current state.\n- Make surgical edits. Prefer edit over write for existing files.\n- Explain your reasoning briefly before each change.\n- Run tests or type checks after changes if the project has them (npm test, npm run check, etc.).\n- If you encounter unexpected complexity, STOP and explain the issue rather than hacking around it.\n\nIf no plan exists:\n- Ask clarifying questions before starting.\n- Propose what you'll do and get confirmation for non-trivial changes.\n\nAfter completing changes:\n- Summarize what was done.\n- Note any follow-up work or tests that should be added."
 *   },
 *   "review": {
 *     "tools": ["*", "!edit", "!write"],
 *     "skills": ["*", "!agent-browser"],
 *     "instructions": "Read-only review mode: you can look but not touch."
 *   },
 *   "browser-test": {
 *     "tools": ["read", "bash"],
 *     "skills": ["agent-browser"],
 *     "instructions": "You are in browser testing mode. Use the agent-browser skill to interact with web pages."
 *   }
 * }
 * ```
 *
 * Usage:
 * - `pi --preset plan` - start with plan preset
 * - `/preset` - show selector to switch presets mid-session
 * - `/preset implement` - switch to implement preset directly
 * - `Ctrl+Shift+U` - cycle through presets
 *
 * CLI flags always override preset values.
 */

import { existsSync, readFileSync } from "node:fs";
import { join } from "node:path";
import type { Api, Model } from "@earendil-works/pi-ai";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { CONFIG_DIR_NAME, DynamicBorder, getAgentDir } from "@earendil-works/pi-coding-agent";
import { Container, Key, type SelectItem, SelectList, Text } from "@earendil-works/pi-tui";

// Preset configuration
interface Preset {
  /** Provider name (e.g., "anthropic", "openai") */
  provider?: string;
  /** Model ID (e.g., "claude-sonnet-4-5") */
  model?: string;
  /** Thinking level */
  thinkingLevel?: "off" | "minimal" | "low" | "medium" | "high" | "xhigh";
  /** Tools to enable (replaces default set) */
  tools?: string[];
  /** Skills to make available (supports wildcard and negation patterns, same as tools) */
  skills?: string[];
  /** Instructions to append to system prompt */
  instructions?: string;
}

interface PresetsConfig {
  [name: string]: Preset;
}

/**
 * Load presets from config files.
 * Project-local presets override global presets with the same name.
 */
function loadPresets(cwd: string): PresetsConfig {
  const globalPath = join(getAgentDir(), "presets.json");
  const projectPath = join(cwd, CONFIG_DIR_NAME, "presets.json");

  let globalPresets: PresetsConfig = {};
  let projectPresets: PresetsConfig = {};

  // Load global presets
  if (existsSync(globalPath)) {
    try {
      const content = readFileSync(globalPath, "utf-8");
      globalPresets = JSON.parse(content);
    } catch (err) {
      console.error(`Failed to load global presets from ${globalPath}: ${err}`);
    }
  }

  // Load project presets
  if (existsSync(projectPath)) {
    try {
      const content = readFileSync(projectPath, "utf-8");
      projectPresets = JSON.parse(content);
    } catch (err) {
      console.error(`Failed to load project presets from ${projectPath}: ${err}`);
    }
  }

  // Merge (project overrides global)
  return { ...globalPresets, ...projectPresets };
}

interface OriginalState {
  model: Model<Api> | undefined;
  thinkingLevel: "off" | "minimal" | "low" | "medium" | "high" | "xhigh";
  tools: string[];
}

interface PatternResult {
  selected: string[];
  invalid: string[];
}

/**
 * Resolve wildcard/negation patterns against a list of valid names.
 *
 * Examples:
 *   resolvePatterns(["*", "!read"], ["read","bash","edit","write"]) → { selected: ["bash","edit","write"], invalid: [] }
 *   resolvePatterns(["read", "bash"], ["read","bash","edit","write"]) → { selected: ["read","bash"], invalid: [] }
 *   resolvePatterns(["!read"], ["read","bash","edit","write"]) → { selected: ["bash","edit","write"], invalid: [] }
 *   resolvePatterns(["*", "!nope"], ["read","bash","edit","write"]) → { selected: ["read","bash","edit","write"], invalid: ["nope"] }
 */
function resolvePatterns(specs: string[], allNames: string[]): PatternResult {
  const positiveItems: string[] = [];
  const negativeItems: string[] = [];

  for (const s of specs) {
    if (s.startsWith("!")) {
      negativeItems.push(s.slice(1));
    } else {
      positiveItems.push(s);
    }
  }

  const validPositive = positiveItems.filter((n) => n === "*" || allNames.includes(n));
  const invalid = [
    ...positiveItems.filter((n) => n !== "*" && !allNames.includes(n)),
    ...negativeItems.filter((n) => !allNames.includes(n)),
  ];

  let selected: string[];
  if (validPositive.includes("*") || (validPositive.length === 0 && negativeItems.length > 0)) {
    // Wildcard or implicit wildcard: start with all names, apply exclusions
    selected = [...allNames];
  } else if (validPositive.length > 0) {
    // Exact list
    selected = validPositive.filter((n) => n !== "*");
  } else {
    selected = [];
  }

  if (negativeItems.length > 0) {
    selected = selected.filter((n) => !negativeItems.includes(n));
  }

  return { selected, invalid };
}

export default function presetExtension(pi: ExtensionAPI) {
  let presets: PresetsConfig = {};
  let activePresetName: string | undefined;
  let activePreset: Preset | undefined;
  let originalState: OriginalState | undefined;

  // Register --preset CLI flag
  pi.registerFlag("preset", {
    description: "Preset configuration to use",
    type: "string",
  });

  /**
   * Apply a preset configuration.
   */
  async function applyPreset(
    name: string,
    preset: Preset,
    ctx: ExtensionContext,
  ): Promise<boolean> {
    // Snapshot state before the first preset is applied (i.e. only when transitioning from no-preset)
    if (activePresetName === undefined) {
      originalState = {
        model: ctx.model,
        thinkingLevel: pi.getThinkingLevel(),
        tools: pi.getActiveTools(),
      };
    }

    // Apply model if specified
    if (preset.provider && preset.model) {
      const model = ctx.modelRegistry.find(preset.provider, preset.model);
      if (model) {
        const success = await pi.setModel(model);
        if (!success) {
          ctx.ui.notify(
            `Preset "${name}": No API key for ${preset.provider}/${preset.model}`,
            "warning",
          );
        }
      } else {
        ctx.ui.notify(
          `Preset "${name}": Model ${preset.provider}/${preset.model} not found`,
          "warning",
        );
      }
    }

    // Apply thinking level if specified
    if (preset.thinkingLevel) {
      pi.setThinkingLevel(preset.thinkingLevel);
    }

    // Apply tools if specified
    if (preset.tools && preset.tools.length > 0) {
      try {
        const allToolNames = pi.getAllTools().map((t) => t.name);
        const { selected: finalTools, invalid: invalidTools } = resolvePatterns(
          preset.tools,
          allToolNames,
        );

        if (invalidTools.length > 0) {
          ctx.ui.notify(
            `Preset "${name}": Unknown tools, ignoring: ${invalidTools.join(", ")}`,
            "warning",
          );
        }

        if (finalTools.length > 0) {
          pi.setActiveTools(finalTools);
        }
      } catch (err) {
        ctx.ui.notify(
          `Preset "${name}": Failed to apply tools — ${err instanceof Error ? err.message : String(err)}`,
          "error",
        );
      }
    }

    // Store active preset for system prompt injection
    activePresetName = name;
    activePreset = preset;

    return true;
  }

  /**
   * Build description string for a preset.
   */
  function buildPresetDescription(preset: Preset): string {
    const parts: string[] = [];

    if (preset.provider && preset.model) {
      parts.push(`${preset.provider}/${preset.model}`);
    }
    if (preset.thinkingLevel) {
      parts.push(`thinking:${preset.thinkingLevel}`);
    }
    if (preset.tools) {
      parts.push(`tools:${preset.tools.join(",")}`);
    }
    if (preset.skills) {
      parts.push(`skills:${preset.skills.join(",")}`);
    }
    if (preset.instructions) {
      const truncated =
        preset.instructions.length > 30
          ? `${preset.instructions.slice(0, 27)}...`
          : preset.instructions;
      parts.push(`"${truncated}"`);
    }

    return parts.join(" | ");
  }

  /**
   * Show preset selector UI using custom SelectList component.
   */
  async function showPresetSelector(ctx: ExtensionContext): Promise<void> {
    const presetNames = Object.keys(presets);

    if (presetNames.length === 0) {
      ctx.ui.notify(
        `No presets defined. Add presets to ${join(getAgentDir(), "presets.json")} or ${join(ctx.cwd, CONFIG_DIR_NAME, "presets.json")}`,
        "warning",
      );
      return;
    }

    // Build select items with descriptions
    const items: SelectItem[] = presetNames.map((name) => {
      const preset = presets[name];
      const isActive = name === activePresetName;
      return {
        value: name,
        label: isActive ? `${name} (active)` : name,
        description: buildPresetDescription(preset),
      };
    });

    // Add "None" option to clear preset
    items.push({
      value: "(none)",
      label: "(none)",
      description: "Clear active preset, restore defaults",
    });

    const result = await ctx.ui.custom<string | null>((tui, theme, _kb, done) => {
      const container = new Container();
      container.addChild(new DynamicBorder((str) => theme.fg("accent", str)));

      // Header
      container.addChild(new Text(theme.fg("accent", theme.bold("Select Preset"))));

      // SelectList with themed styling
      const selectList = new SelectList(items, Math.min(items.length, 10), {
        selectedPrefix: (text) => theme.fg("accent", text),
        selectedText: (text) => theme.fg("accent", text),
        description: (text) => theme.fg("muted", text),
        scrollInfo: (text) => theme.fg("dim", text),
        noMatch: (text) => theme.fg("warning", text),
      });

      selectList.onSelect = (item) => done(item.value);
      selectList.onCancel = () => done(null);

      container.addChild(selectList);

      // Footer hint
      container.addChild(
        new Text(theme.fg("dim", "\u2191\u2195 navigate \u2022 enter select \u2022 esc cancel")),
      );

      container.addChild(new DynamicBorder((str) => theme.fg("accent", str)));

      return {
        render(width: number) {
          return container.render(width);
        },
        invalidate() {
          container.invalidate();
        },
        handleInput(data: string) {
          selectList.handleInput(data);
          tui.requestRender();
        },
      };
    });

    if (!result) return;

    if (result === "(none)") {
      // Clear preset and restore original state
      activePresetName = undefined;
      activePreset = undefined;
      if (originalState) {
        if (originalState.model) {
          await pi.setModel(originalState.model);
        }
        pi.setThinkingLevel(originalState.thinkingLevel);
        pi.setActiveTools(originalState.tools);
      } else {
        pi.setActiveTools(["read", "bash", "edit", "write"]);
      }
      ctx.ui.notify("Preset cleared, defaults restored", "info");
      updateStatus(ctx);
      return;
    }

    const preset = presets[result];
    if (preset) {
      await applyPreset(result, preset, ctx);
      ctx.ui.notify(`Preset "${result}" activated`, "info");
      updateStatus(ctx);
    }
  }

  /**
   * Update status indicator.
   */
  function updateStatus(ctx: ExtensionContext) {
    if (activePresetName) {
      ctx.ui.setStatus("preset", ctx.ui.theme.fg("accent", `preset:${activePresetName}`));
    } else {
      ctx.ui.setStatus("preset", undefined);
    }
  }

  function getPresetOrder(): string[] {
    return Object.keys(presets).sort();
  }

  async function cyclePreset(ctx: ExtensionContext): Promise<void> {
    const presetNames = getPresetOrder();
    if (presetNames.length === 0) {
      ctx.ui.notify(
        `No presets defined. Add presets to ${join(getAgentDir(), "presets.json")} or ${join(ctx.cwd, CONFIG_DIR_NAME, "presets.json")}`,
        "warning",
      );
      return;
    }

    const cycleList = ["(none)", ...presetNames];
    const currentName = activePresetName ?? "(none)";
    const currentIndex = cycleList.indexOf(currentName);
    const nextIndex = currentIndex === -1 ? 0 : (currentIndex + 1) % cycleList.length;
    const nextName = cycleList[nextIndex];

    if (nextName === "(none)") {
      activePresetName = undefined;
      activePreset = undefined;
      if (originalState) {
        if (originalState.model) {
          await pi.setModel(originalState.model);
        }
        pi.setThinkingLevel(originalState.thinkingLevel);
        pi.setActiveTools(originalState.tools);
      } else {
        pi.setActiveTools(["read", "bash", "edit", "write"]);
      }
      ctx.ui.notify("Preset cleared, defaults restored", "info");
      updateStatus(ctx);
      return;
    }

    const preset = presets[nextName];
    if (!preset) return;

    await applyPreset(nextName, preset, ctx);
    ctx.ui.notify(`Preset "${nextName}" activated`, "info");
    updateStatus(ctx);
  }

  pi.registerShortcut(Key.alt("p"), {
    description: "Cycle presets (Alt+P)",
    handler: async (ctx) => {
      await cyclePreset(ctx);
    },
  });

  // Register /preset command
  pi.registerCommand("preset", {
    description: "Switch preset configuration",
    handler: async (args, ctx) => {
      // If preset name provided, apply directly
      if (args?.trim()) {
        const name = args.trim();
        const preset = presets[name];

        if (!preset) {
          const available = Object.keys(presets).join(", ") || "(none defined)";
          ctx.ui.notify(`Unknown preset "${name}". Available: ${available}`, "error");
          return;
        }

        await applyPreset(name, preset, ctx);
        ctx.ui.notify(`Preset "${name}" activated`, "info");
        updateStatus(ctx);
        return;
      }

      // Otherwise show selector
      await showPresetSelector(ctx);
    },
  });

  // Inject preset instructions into system prompt
  pi.on("before_agent_start", async (event) => {
    let extra = "";

    if (activePreset?.instructions) {
      extra += `\n\n${activePreset.instructions}`;
    }

    // Handle skill filtering via system prompt instructions
    if (activePreset?.skills && event.systemPromptOptions?.skills) {
      const allSkillNames = event.systemPromptOptions.skills.map((s) => s.name);
      const { selected: activeSkills, invalid: _bad } = resolvePatterns(
        activePreset.skills,
        allSkillNames,
      );

      if (activeSkills.length === 0) {
        extra += `\n\nYou do not have access to any skills. Do not try to use them.`;
      } else if (activeSkills.length < allSkillNames.length) {
        const excluded = allSkillNames.filter((n) => !activeSkills.includes(n));
        extra += `\n\nYou have access to these skills: ${activeSkills.join(", ")}. Do NOT use: ${excluded.join(", ")}.`;
      }
      // If activeSkills is the same as allSkillNames, don't add any instructions
    }

    if (extra) {
      return {
        systemPrompt: `${event.systemPrompt}${extra}`,
      };
    }
  });

  // Initialize on session start
  pi.on("session_start", async (_event, ctx) => {
    // Load presets from config files
    presets = loadPresets(ctx.cwd);

    // Check for --preset flag
    const presetFlag = pi.getFlag("preset");
    if (typeof presetFlag === "string" && presetFlag) {
      const preset = presets[presetFlag];
      if (preset) {
        await applyPreset(presetFlag, preset, ctx);
        ctx.ui.notify(`Preset "${presetFlag}" activated`, "info");
      } else {
        const available = Object.keys(presets).join(", ") || "(none defined)";
        ctx.ui.notify(`Unknown preset "${presetFlag}". Available: ${available}`, "warning");
      }
    }

    // Restore preset from session state
    const entries = ctx.sessionManager.getEntries();
    const presetEntry = entries
      .filter(
        (e: { type: string; customType?: string }) =>
          e.type === "custom" && e.customType === "preset-state",
      )
      .pop() as { data?: { name: string } } | undefined;

    if (presetEntry?.data?.name && !presetFlag) {
      const preset = presets[presetEntry.data.name];
      if (preset) {
        activePresetName = presetEntry.data.name;
        activePreset = preset;
        // Don't re-apply model/tools on restore, just keep the name for instructions
      }
    }

    updateStatus(ctx);
  });

  // Persist preset state
  pi.on("turn_start", async () => {
    if (activePresetName) {
      pi.appendEntry("preset-state", { name: activePresetName });
    }
  });
}
