/**
 * Skills Extension
 *
 * Provides a /skills command to enable/disable skills interactively.
 * Disabled skills are filtered from the system prompt in real-time.
 *
 * Usage:
 * 1. Use /skills to open the skill selector
 * 2. Toggle skills on/off with arrow keys
 * 3. Press Ctrl+S to save and close
 * 4. Press Escape to cancel without saving
 */

import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { getSettingsListTheme } from "@earendil-works/pi-coding-agent";
import { Container, type SettingItem, SettingsList } from "@earendil-works/pi-tui";

// State persisted to session
interface SkillsState {
	/** Skills explicitly disabled by user (all others are enabled) */
	disabledSkills: string[];
}

// Skill info parsed from system prompt
interface SkillEntry {
	name: string;
	xmlBlock: string;
}

export default function skillsExtension(pi: ExtensionAPI) {
	// Skills disabled by user (persisted across session)
	let disabledSkills: Set<string> = new Set();
	// Track if we've loaded state from session
	let stateLoaded = false;

	// Persist current state
	function persistState() {
		pi.appendEntry<SkillsState>("skills-config", {
			disabledSkills: Array.from(disabledSkills),
		});
	}

	// Restore state from session branch
	function restoreFromBranch(ctx: ExtensionContext) {
		const branchEntries = ctx.sessionManager.getBranch();
		let savedState: SkillsState | undefined;

		for (const entry of branchEntries) {
			if (entry.type === "custom" && entry.customType === "skills-config") {
				savedState = entry.data as SkillsState;
			}
		}

		if (savedState?.disabledSkills) {
			disabledSkills = new Set(savedState.disabledSkills);
		}
		stateLoaded = true;
	}

	// Parse skill entries from system prompt XML
	function parseSkillsFromPrompt(prompt: string): SkillEntry[] {
		const skills: SkillEntry[] = [];
		const skillRegex = /<skill>([\s\S]*?)<\/skill>/g;
		let match;

		while ((match = skillRegex.exec(prompt)) !== null) {
			const block = match[0];
			const nameMatch = block.match(/<name>([\s\S]*?)<\/name>/);
			if (nameMatch) {
				skills.push({
					name: nameMatch[1].trim(),
					xmlBlock: block,
				});
			}
		}

		return skills;
	}

	// Get all available skill names from system prompt
	function getAvailableSkills(prompt: string): string[] {
		return parseSkillsFromPrompt(prompt).map((s) => s.name);
	}

	// Filter system prompt to remove disabled skills
	function filterSystemPrompt(prompt: string): string {
		if (disabledSkills.size === 0) return prompt;

		let filtered = prompt;

		for (const skill of parseSkillsFromPrompt(prompt)) {
			if (disabledSkills.has(skill.name)) {
				filtered = filtered.replace(skill.xmlBlock, "");
			}
		}

		// Clean up empty lines left behind
		filtered = filtered.replace(/\n{3,}/g, "\n\n");

		return filtered;
	}

	// Register /skills command
	pi.registerCommand("skills", {
		description: "Enable/disable skills from system prompt",
		handler: async (_args, ctx) => {
			if (ctx.mode !== "tui") {
				ctx.ui.notify("/skills requires TUI mode", "error");
				return;
			}

			// Get current system prompt to discover available skills
			const currentPrompt = ctx.getSystemPrompt();
			const availableSkills = getAvailableSkills(currentPrompt);

			if (availableSkills.length === 0) {
				ctx.ui.notify("No skills found in system prompt", "warning");
				return;
			}

			// Track pending changes before saving
			let pendingDisabled = new Set(disabledSkills);

			const result = await ctx.ui.custom((tui, theme, _kb, done) => {
				// Build settings items for each skill
				const items: SettingItem[] = availableSkills.map((name) => ({
					id: name,
					label: name,
					currentValue: pendingDisabled.has(name) ? "disabled" : "enabled",
					values: ["enabled", "disabled"],
				}));

				const container = new Container();

				// Header with instructions
				container.addChild(
					new (class {
						render(_width: number) {
							return [
								theme.fg("accent", theme.bold("Skill Configuration")),
								"",
								theme.fg("muted", `${availableSkills.length} skills in system prompt`),
								theme.fg("muted", `${pendingDisabled.size} currently disabled`),
								"",
								theme.fg("success", "Ctrl+S") + theme.fg("muted", " save & close   ") +
								theme.fg("error", "Esc") + theme.fg("muted", " cancel"),
								"",
							];
						}
						invalidate() {}
					})(),
				);

				const settingsList = new SettingsList(
					items,
					Math.min(items.length + 2, 15),
					getSettingsListTheme(),
					(id, newValue) => {
						// Update pending state (not final until Ctrl+S)
						if (newValue === "disabled") {
							pendingDisabled.add(id);
						} else {
							pendingDisabled.delete(id);
						}
					},
					() => {
						// Escape pressed - cancel
						done(false);
					},
				);

				container.addChild(settingsList);

				const component = {
					render(width: number) {
						return container.render(width);
					},
					invalidate() {
						container.invalidate();
					},
					handleInput(data: string) {
						// Ctrl+S to save
						if (data === "\x13") {
							done(true);
							return;
						}
						// Pass other input to settings list
						settingsList.handleInput?.(data);
						tui.requestRender();
					},
				};

				return component;
			});

			if (result === true) {
				// Save the pending changes
				disabledSkills = pendingDisabled;
				persistState();

				const enabledCount = availableSkills.length - disabledSkills.size;
				ctx.ui.notify(
					`Saved: ${enabledCount} enabled, ${disabledSkills.size} disabled`,
					"info",
				);
			} else {
				// Cancelled - no changes
				ctx.ui.notify("Cancelled - no changes", "info");
			}
		},
	});

	// Filter skills from system prompt in real-time
	pi.on("before_agent_start", async (event, _ctx) => {
		if (disabledSkills.size === 0) return;

		const filteredPrompt = filterSystemPrompt(event.systemPrompt);
		if (filteredPrompt !== event.systemPrompt) {
			return { systemPrompt: filteredPrompt };
		}
	});

	// Restore state on session start
	pi.on("session_start", async (_event, ctx) => {
		restoreFromBranch(ctx);
	});

	// Restore state when navigating the session tree
	pi.on("session_tree", async (_event, ctx) => {
		restoreFromBranch(ctx);
	});
}
