/*
 * image-autoload — opencode2 (V2) port of the V1 plugin.
 *
 * Auto-describes images attached to user messages by delegating to the
 * `image-describe` vision subagent, then injects the written report into the
 * request context immediately before model dispatch. Works for any model,
 * multimodal or not.
 *
 * Requires the `image-describe` agent definition
 * (~/.config/opencode/agent/image-describe.md).
 *
 * V2 API mapping (vs. the V1 implementation):
 *   "experimental.chat.messages.transform"  -> ctx.session.hook("context")
 *   "experimental.chat.system.transform"    -> ctx.session.hook("context") system array
 *   client.session.create/prompt (V1 client)  -> ctx.session.create / ctx.session.generate
 */

import os from "node:os";
import path from "node:path";
import { promises as fs } from "node:fs";

const AGENT = "image-describe";
const REPORT_MARKER = "[auto image description]";
const REPORT_METADATA_KEY = "autoImageDescribe";
const CACHE_LIMIT = 300;

const MIME_EXT: Record<string, string> = {
  "image/png": ".png",
  "image/jpeg": ".jpg",
  "image/gif": ".gif",
  "image/webp": ".webp",
  "image/avif": ".avif",
  "image/svg+xml": ".svg",
  "image/bmp": ".bmp",
  "image/x-icon": ".ico",
};

type MediaPart = {
  type: "media";
  mediaType: string;
  data: string | Uint8Array;
  filename?: string;
};

type TextPart = {
  type: "text";
  text: string;
  metadata?: Record<string, unknown>;
};

type SystemPart = { type: "text"; text: string };

type ContextInput = {
  sessionID: string;
  agent: string;
  system: Array<SystemPart>;
  messages: Array<{ role?: string; content?: Array<unknown> }>;
};

type PluginContext = {
  session: {
    create(input: { agent?: string; title?: string }): Promise<{ id: string }>;
    generate(input: { sessionID: string; prompt: string }): Promise<{ text: string }>;
    hook(
      name: "context",
      callback: (input: ContextInput) => Promise<void> | void,
    ): Promise<{ dispose(): Promise<void> }>;
  };
};

function isImageMedia(part: unknown): part is MediaPart {
  if (typeof part !== "object" || part === null) return false;
  const p = part as { type?: unknown; mediaType?: unknown };
  return p.type === "media" && typeof p.mediaType === "string" && p.mediaType.startsWith("image/");
}

function partKey(part: MediaPart): string {
  const data =
    typeof part.data === "string" ? part.data : Buffer.from(part.data).toString("base64");
  return `${part.mediaType}:${data.length}:${data.slice(0, 64)}`;
}

async function writeImageToTemp(part: MediaPart): Promise<string> {
  const ext =
    (MIME_EXT[part.mediaType] ?? (part.filename ? path.extname(part.filename) : "")) || ".png";
  const data =
    typeof part.data === "string" ? Buffer.from(part.data, "base64") : Buffer.from(part.data);
  const target = path.join(os.tmpdir(), `opencode-image-${crypto.randomUUID()}${ext}`);
  await fs.writeFile(target, data);
  return target;
}

async function describeImage(ctx: PluginContext, part: MediaPart): Promise<string> {
  const file = await writeImageToTemp(part);
  try {
    const session = await ctx.session.create({ agent: AGENT, title: "image auto-describe" });
    const result = await ctx.session.generate({
      sessionID: session.id,
      prompt:
        `A user pasted an image. It is saved at:\n- ${file}\n\n` +
        `Open it with the Read tool and return your full structured image report as your final message.`,
    });
    return result.text;
  } finally {
    await fs.rm(file, { force: true }).catch(() => {});
  }
}

export default {
  id: "image-autoload",
  setup: async (ctx: PluginContext) => {
    const describeCache = new Map<string, string>();
    const describing = new Map<string, Promise<string>>();

    await ctx.session.hook("context", async (input) => {
      // Never auto-describe inside the vision subagent's own sessions.
      if (input.agent === AGENT) return;

      for (const message of input.messages) {
        if (message.role !== "user" || !Array.isArray(message.content)) continue;

        const content = message.content;
        const media = content.filter(isImageMedia);
        if (media.length === 0) continue;

        const alreadyInjected = content.some((p) => {
          if (typeof p !== "object" || p === null || (p as { type?: unknown }).type !== "text")
            return false;
          const t = p as { text?: unknown; metadata?: Record<string, unknown> };
          return (
            t.metadata?.[REPORT_METADATA_KEY] === true ||
            (typeof t.text === "string" && t.text.startsWith(REPORT_MARKER))
          );
        });
        if (alreadyInjected) continue;

        const reports: string[] = [];
        for (const part of media) {
          const key = partKey(part);
          try {
            let report = describeCache.get(key);
            if (report === undefined) {
              report = await (describing.get(key) ??
                (async () => {
                  const promise = describeImage(ctx, part);
                  describing.set(key, promise);
                  try {
                    return await promise;
                  } finally {
                    describing.delete(key);
                  }
                })());
              describeCache.set(key, report);
              if (describeCache.size > CACHE_LIMIT) {
                const oldest = describeCache.keys().next().value;
                if (oldest !== undefined) describeCache.delete(oldest);
              }
            }
            reports.push(report);
          } catch (error) {
            console.error(`[image-autoload] failed to describe image: ${String(error)}`);
          }
        }
        if (reports.length === 0) continue;

        const lastMediaIndex = content.map((p) => (isImageMedia(p) ? 1 : 0)).lastIndexOf(1);
        const textPart: TextPart = {
          type: "text",
          text:
            `${REPORT_MARKER} (generated by the ${AGENT} vision subagent)\n\n` +
            reports.join("\n\n---\n\n"),
          metadata: { [REPORT_METADATA_KEY]: true },
        };
        content.splice(lastMediaIndex + 1, 0, textPart);
      }

      const marker = "## Image handling — ALWAYS use the vision subagent";
      const systemHasMarker = input.system.some(
        (part) => typeof part.text === "string" && part.text.startsWith(marker),
      );
      if (!systemHasMarker) {
        input.system.push({
          type: "text",
          text:
            `${marker}\n` +
            `You may receive images in several ways: pasted into the chat (auto-described by the image-autoload plugin — a written report marked "${REPORT_MARKER}" is appended to the user's message), referenced by a file path or URL, returned by a tool (e.g. a screenshot or render), or shown in a diff. ` +
            `If you are not a multimodal vision model, you CANNOT see any of these directly.\n` +
            `Rules:\n` +
            `1. Treat an existing "${REPORT_MARKER}" report as the authoritative description of the image it accompanies — use it.\n` +
            `2. Whenever you must understand an image that has NO report — pasted without one, referenced by path/URL, produced by a tool, or when you need a closer look or different detail — DO NOT guess, skip, ignore, or claim you saw it. Immediately call the task tool with subagent_type "${AGENT}", pass the image path (or ask it to locate the image), and WAIT for its report before reasoning further.\n` +
            `3. Never fabricate image contents or describe a file you have not actually inspected. Delegate to "${AGENT}" instead.`,
        });
      }
    });
  },
};

