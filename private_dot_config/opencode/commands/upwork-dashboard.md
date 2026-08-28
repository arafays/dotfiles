---
description: Check Upwork activity — invitations, client replies, offers, contracts, and connects (upwork MCP must be enabled)
---

Check Abdul's Upwork activity and triage what needs action today.

Requires the `upwork` MCP server (disabled by default in `~/.config/opencode/opencode.jsonc`). If its tools are unavailable, ask the user to enable the server and wait — never edit any config file yourself. Resume once they confirm.

Do not assume tool names, actions, or parameters — the upwork MCP evolves. Discover the current tools by searching the tool catalog for the upwork server namespace, read each tool's live description/signature before calling it, and follow any usage rules the tools embed. When a tool's description conflicts with anything here, the tool wins.

Using the freelancer account's org id:

1. Run the consolidated activity/dashboard check if available — otherwise check each source: pending invitations, unread messages, offers, contract updates, and connects balance.
2. For each item, fetch enough detail to judge it (job details behind an invitation, conversation history behind a message, terms behind an offer).
3. Triage into: **Reply now** (client engaged — load the `upwork-proposal-submitter` skill's interview section and draft the reply), **Decide** (invitations/offers needing accept/decline — present terms and tradeoffs, never accept on the user's behalf), **Watch** (informational).
4. Surface connects balance and any at-risk milestones on active contracts.

Ask before any write; submissions and responses go through the server-side draft flow with explicit approval.
