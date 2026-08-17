import type { ExtensionAPI, ExtensionCommandContext, Theme, ToolInfo } from "@earendil-works/pi-coding-agent";
import { copyToClipboard } from "@earendil-works/pi-coding-agent";
import { matchesKey, type TUI, truncateToWidth, visibleWidth, wrapTextWithAnsi } from "@earendil-works/pi-tui";

// ---------------------------------------------------------------------------
// /system-prompt — Display the full system prompt and tool definitions
//
// Registers a full-screen scrollable overlay showing:
//   - the effective system prompt (`ctx.getSystemPrompt()`)
//   - the active tools with their parameter schemas (`pi.getAllTools()`)
//
// Navigation: ↑/↓ or j/k to scroll, PgUp/PgDn to page, Home/End to jump,
// `c` to copy the full text to the clipboard, Esc/q to close.
//
// The command is self-contained: the default export below calls
// `pi.registerCommand("system-prompt", ...)` and wires it to
// `systemPromptHandler`.
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// Pure helpers (the testable core)
// ---------------------------------------------------------------------------

/** A single rendered display line, mapped back to its source line index. */
export interface DisplayLine {
  text: string;
  originalIndex: number;
  continuation: boolean;
}

/** Style categories derived from the system prompt's actual section markers. */
export type LineStyle = "tools" | "guidelines" | "heading" | "bullet" | "toolLine" | "plain";

/**
 * Classify a source line for styling. Matches Pi's built-in system prompt
 * sections ("Available tools:", "Guidelines:") plus generic markdown headings
 * and bullets for custom prompts.
 */
export function lineStyle(originalLine: string): LineStyle {
  if (originalLine.startsWith("Available tools:")) return "tools";
  if (originalLine.startsWith("Guidelines:")) return "guidelines";
  if (/^#+\s/.test(originalLine)) return "heading";
  if (originalLine.startsWith("- ")) return "bullet";
  if (originalLine.startsWith("  ") || originalLine.startsWith("    ")) return "toolLine";
  return "plain";
}

/** Apply styling for the first (non-wrapped) line of a source line. */
export function styleFirstLine(th: Theme, text: string, style: LineStyle): string {
  switch (style) {
    case "tools":
      return th.fg("success", th.bold(text));
    case "guidelines":
      return th.fg("accent", th.bold(text));
    case "heading":
      return th.fg("accent", th.bold(text));
    case "bullet":
      return th.fg("muted", text);
    default:
      return text;
  }
}

/** Apply styling for a wrapped (continuation) line of a source line. */
export function styleContinuation(th: Theme, text: string, style: LineStyle): string {
  switch (style) {
    case "bullet":
      return th.fg("muted", text);
    case "heading":
      return th.fg("dim", text);
    default:
      return th.fg("dim", text);
  }
}

/**
 * Build the tool-definition display lines. Mirrors the original
 * `buildToolLines`, adapted to the current `ToolInfo` shape (source lives in
 * `sourceInfo.source`: "builtin" | "sdk" | custom string).
 */
export function buildToolLines(tools: ToolInfo[]): string[] {
  const lines: string[] = [];
  if (tools.length === 0) {
    lines.push("No tools registered.");
    return lines;
  }

  lines.push(`Tool Definitions (${tools.length} tools)`);
  lines.push("");

  for (const tool of tools) {
    const source = tool.sourceInfo?.source ?? "unknown";
    const sourceText = source === "builtin" ? "built-in" : source === "sdk" ? "SDK" : source;

    lines.push(`name: ${tool.name}`);
    lines.push(`  description: ${tool.description}`);
    lines.push(`  source: ${sourceText}`);
    lines.push("  parameters:");

    const paramStr = JSON.stringify(tool.parameters, null, 2);
    for (const pl of paramStr.split("\n")) {
      lines.push(`    ${pl}`);
    }

    lines.push("");
  }

  return lines;
}

/** Overlay height cap as a fraction of the terminal, kept in sync with overlayOptions.maxHeight. */
const OVERLAY_MAX_HEIGHT_FRACTION = 0.8;

/** Non-content chrome rows: top border, header, blank, blank-before-footer, footer, bottom border. */
const OVERLAY_CHROME_ROWS = 6;

/** Number of content rows visible inside the overlay at the current terminal height. */
export function visibleContentRows(termRows: number): number {
  if (!termRows || termRows <= 0) return 30;
  return Math.max(1, Math.floor(termRows * OVERLAY_MAX_HEIGHT_FRACTION) - OVERLAY_CHROME_ROWS);
}

// ---------------------------------------------------------------------------
// Overlay component
// ---------------------------------------------------------------------------

interface SystemPromptComponent {
  render(width: number): string[];
  handleInput(data: string): void;
  invalidate(): void;
  dispose(): void;
}

/** Wrap a view's display lines (already text-wrapped) for a given width. */
function buildDisplayLines(allLines: string[], contentW: number): DisplayLine[] {
  const displayLines: DisplayLine[] = [];
  for (let i = 0; i < allLines.length; i++) {
    const wrapped = wrapTextWithAnsi(allLines[i] ?? "", contentW);
    for (let w = 0; w < wrapped.length; w++) {
      displayLines.push({
        text: wrapped[w] ?? "",
        originalIndex: i,
        continuation: w > 0
      });
    }
  }
  return displayLines;
}

function createSystemPromptView(
  tui: TUI,
  allLines: string[],
  allTools: ToolInfo[],
  promptLineCount: number,
  promptCharCount: number,
  theme: Theme,
  done: () => void
): SystemPromptComponent {
  let scrollOffset = 0;
  let copiedAt = 0;
  let totalDisplayLines = 0;

  const fullText = allLines.join("\n");

  const visible = (): number => visibleContentRows(tui.terminal.rows);
  const total = (): number => totalDisplayLines;

  const copyToClipboardSafe = async (): Promise<void> => {
    try {
      await copyToClipboard(fullText);
      copiedAt = Date.now();
    } catch {
      // Fall back to OSC 52 (remote terminals without native clipboard access).
      const base64 = Buffer.from(fullText, "utf-8").toString("base64");
      process.stdout.write(`\x1b]52;c;${base64}\x07`);
      copiedAt = Date.now();
    }
    tui.requestRender();
  };

  const handleInput = (data: string): void => {
    if (matchesKey(data, "up") || matchesKey(data, "k")) {
      if (scrollOffset > 0) scrollOffset -= 1;
      tui.requestRender();
      return;
    }
    if (matchesKey(data, "down") || matchesKey(data, "j")) {
      const max = Math.max(0, total() - visible());
      if (scrollOffset < max) scrollOffset += 1;
      tui.requestRender();
      return;
    }
    if (matchesKey(data, "pageUp")) {
      scrollOffset = Math.max(0, scrollOffset - visible());
      tui.requestRender();
      return;
    }
    if (matchesKey(data, "pageDown")) {
      scrollOffset = Math.min(Math.max(0, total() - visible()), scrollOffset + visible());
      tui.requestRender();
      return;
    }
    if (matchesKey(data, "home")) {
      scrollOffset = 0;
      tui.requestRender();
      return;
    }
    if (matchesKey(data, "end")) {
      scrollOffset = Math.max(0, total() - visible());
      tui.requestRender();
      return;
    }
    if (matchesKey(data, "c")) {
      void copyToClipboardSafe();
      return;
    }
    if (matchesKey(data, "escape") || matchesKey(data, "q")) {
      done();
    }
  };

  const render = (width: number): string[] => {
    const th = theme;
    const innerW = width - 2;
    const contentW = Math.max(1, innerW - 1);
    const rows = visible();

    const displayLines = buildDisplayLines(allLines, contentW);
    totalDisplayLines = displayLines.length;

    const pad = (s: string, len: number): string => {
      const vis = visibleWidth(s);
      return s + " ".repeat(Math.max(0, len - vis));
    };

    const row = (content: string): string => th.fg("border", "│") + pad(content, innerW) + th.fg("border", "│");

    const out: string[] = [];

    // Top border + header
    out.push(th.fg("border", `╭${"─".repeat(innerW)}╮`));
    out.push(
      row(
        truncateToWidth(
          ` ${th.fg("accent", th.bold("System Prompt"))}  ${th.fg(
            "dim",
            `— ${promptLineCount} lines, ${promptCharCount.toLocaleString()} chars`
          )}  ${th.fg("dim", `|  ${allTools.length} tools`)}`,
          innerW
        )
      )
    );
    out.push(row(""));

    // Content area
    const end = Math.min(scrollOffset + rows, displayLines.length);
    for (let i = scrollOffset; i < end; i++) {
      const dl = displayLines[i];
      if (dl === undefined) continue;
      const originalLine = allLines[dl.originalIndex] ?? "";
      const style = lineStyle(originalLine);
      const styled = dl.continuation ? styleContinuation(th, dl.text, style) : styleFirstLine(th, dl.text, style);
      out.push(row(` ${styled}`));
    }

    // Pad empty rows if content is shorter than the visible area.
    for (let i = end - scrollOffset; i < rows; i++) {
      out.push(row(""));
    }

    // Footer
    const pct = displayLines.length > 0 ? Math.round((scrollOffset / displayLines.length) * 100) : 0;
    const footerLeft = `${scrollOffset + 1}-${end}/${displayLines.length} (${pct}%)`;
    const copyLabel = Date.now() - copiedAt < 2000 ? th.fg("success", "copied") : "copy";
    const footerRight = `c ${copyLabel}  ↑↓/jk pgup/pgdn home/end  Esc/q`;
    const leftVis = visibleWidth(footerLeft);
    const rightVis = visibleWidth(footerRight);
    const gap = Math.max(1, innerW - 1 - leftVis - rightVis);
    const footer = truncateToWidth(` ${th.fg("dim", footerLeft)}${" ".repeat(gap)}${th.fg("dim", footerRight)}`, innerW);
    out.push(row(""));
    out.push(row(footer));

    // Bottom border
    out.push(th.fg("border", `╰${"─".repeat(innerW)}╯`));

    return out;
  };

  return {
    render,
    handleInput,
    invalidate: () => {},
    dispose: () => {}
  };
}

// ---------------------------------------------------------------------------
// Command handler
// ---------------------------------------------------------------------------

/**
 * Open the `/system-prompt` overlay. In non-TUI modes the same content is
 * surfaced through `ctx.ui.notify` (no terminal component host available).
 *
 * Never throws (Pi command contract): any error is surfaced via
 * `ctx.ui.notify` and swallowed.
 */
export async function systemPromptHandler(
  pi: ExtensionAPI,
  _args: string,
  ctx: ExtensionCommandContext
): Promise<void> {
  try {
    await ctx.waitForIdle();

    const prompt = ctx.getSystemPrompt();
    const promptLines = prompt.split("\n");
    const charCount = prompt.length;
    const lineCount = promptLines.length;

    const active = new Set(pi.getActiveTools());
    const activeTools = pi.getAllTools().filter((t) => active.has(t.name));

    const toolLines = buildToolLines(activeTools);
    const allLines = [...promptLines, "", "────────────────────────────────────────", "", ...toolLines];

    if (ctx.mode !== "tui") {
      if (ctx.hasUI) ctx.ui.notify(allLines.join("\n"), "info");
      return;
    }

    await ctx.ui.custom<void>(
      (tui, theme, _keybindings, done) =>
        createSystemPromptView(tui, allLines, activeTools, lineCount, charCount, theme, done),
      {
        overlay: true,
        overlayOptions: {
          width: "90%",
          maxHeight: "80%",
          minWidth: 40,
          anchor: "center",
          margin: 0
        }
      }
    );
  } catch (error) {
    if (ctx.hasUI) ctx.ui.notify(`System prompt display failed: ${String(error)}`, "error");
  }
}

// ---------------------------------------------------------------------------
// Extension entry point — registers the command.
// ---------------------------------------------------------------------------
export default function (pi: ExtensionAPI): void {
  pi.registerCommand("system-prompt", {
    description: "Display the full system prompt and active tool definitions",
    handler: (args: string, ctx: ExtensionCommandContext) => systemPromptHandler(pi, args, ctx)
  });
}
