// DeepSeek Peak-Time Guard — PKT (UTC+5) peak hours → confirm dialog.
// Peak windows (UTC): 01:00–04:00, 06:00–10:00 → PKT: 06:00–09:00, 11:00–15:00
// Source: https://api-docs.deepseek.com/quick_start/pricing

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const DEEPSEEK_RE = /deepseek/i;

/** Current Pakistan Standard Time hour (0–23), no DST. */
function pktHour(): number {
  return Number(
    new Intl.DateTimeFormat("en-US", { timeZone: "Asia/Karachi", hour: "2-digit", hour12: false })
      .format(new Date()),
  );
}

function isPeakPKT(): boolean {
  const h = pktHour();
  return (h >= 6 && h < 9) || (h >= 11 && h < 15);
}

export default function (pi: ExtensionAPI) {
  pi.on("model_select", async (event, ctx) => {
    const { model, previousModel } = event;

    if (!DEEPSEEK_RE.test(model.id) && !DEEPSEEK_RE.test(model.provider)) return;
    if (!isPeakPKT()) return; // off-peak: silent pass-through

    const localTime = new Intl.DateTimeFormat("en-US", {
      timeZone: "Asia/Karachi", hour: "numeric", minute: "2-digit", hour12: true,
    }).format(new Date());

    const confirmed = await ctx.ui.confirm(
      "DeepSeek Peak Hours",
      `It's ${localTime} PKT — DeepSeek 100% rate window:\n` +
        "• 06:00–09:00 AM  •  11:00 AM–03:00 PM\n\n" +
        `${model.provider}/${model.id} — 2× off-peak price. Confirm? (10 s)`,
      { timeout: 10_000 },
    );

    if (confirmed) {
      ctx.ui.notify("DeepSeek confirmed (peak rates).", "warning");
    } else if (previousModel?.id && (await pi.setModel(previousModel))) {
      ctx.ui.notify(`Rolled back to ${previousModel.provider}/${previousModel.id}.`, "info");
    } else {
      ctx.ui.notify("DeepSeek selection kept.", "info");
    }
  });
}
