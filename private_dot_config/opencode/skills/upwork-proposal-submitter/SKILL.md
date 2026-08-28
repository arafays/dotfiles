---
name: Upwork Proposal Submitter
description: Submit Upwork proposals through the upwork MCP draft-confirm flow with connects-cost transparency, then handle interviews, offers, and milestones — every write gated on explicit user approval
---

# Upwork Proposal Submitter

## Gate

Requires the `upwork` MCP server. It is **disabled by default** in `~/.config/opencode/opencode.jsonc` (`mcp.servers.upwork`). If upwork tools are unavailable, **ask the user to enable the server and wait — never edit any config file yourself**. Resume once they confirm it is enabled.

## Tooling

Do not assume tool names, actions, or parameter names — the upwork MCP evolves:

1. Discover the current upwork tools by searching the tool catalog for the upwork server namespace.
2. Read each tool's live description/signature before calling it. The proposal and submission tools embed **mandatory workflow rules** (invitation checks, attachment questions, draft-preview-confirm gates, bid amounts as numbers not strings). Follow those embedded rules exactly; when they conflict with this file, the tool wins.
3. This skill references *capabilities* (job details, proposal creation, invitations, messaging, offers, milestones), not identifiers.

Identify the freelancer account and its org id via the account-listing capability first, and pass that org id on every call. Never hardcode it.

## Division of labor

Cover-letter **content** follows the `upwork-proposal-writer` skill — load it for the writing rules, portfolio, structure, and screening answers. This skill handles bid positioning, submission mechanics, and everything after the letter is written.

## Ground truth (read-only, before any write)

- Full job details: description, screening questions, budget, preferred qualifications, client hiring record and work history.
- Past proposals — recent submitted ones and especially offered/hired ones, for bid patterns and tone.
- Connects balance, and the highlights (portfolio projects / certificates) attachable to the proposal.

## Bid

- Anchor near Abdul's $35/hr rate. Match the client's stated range when plausible; when it is below the rate floor, flag the mismatch to the user before drafting.
- Use bid statistics (avg/min/max of competing proposals) only when a response actually includes them; never estimate competitor bids.
- Fixed-price: propose milestone-shaped amounts that reflect scope; recommend an upfront portion where the tooling supports it.

## Submission flow (draft → confirm)

1. **Pre-checks (mandatory):** before creating a proposal, check for an existing invitation and any prior proposal for this job — an invitation must be answered via the invitation-accept path, not a new proposal. Answer any screening questions from the job details; they must be passed with the submission.
2. **Draft:** prepare the proposal draft (job reference, cover letter, bid as a number, screening answers).
3. **Present the preview, always including:** the connects cost of applying, the current connects balance, whether applying is possible, any unmet preferred qualifications (advisory, not blocking), and any boost options with the *actual* competing bids the response shows. Never omit the connects cost.
4. **Highlights and attachments:** offer to attach the most relevant portfolio projects and certificates, and always ask whether the user wants file attachments (CV, work samples) before submitting — even if they decline.
5. **Revise** via the draft-update capability when the user wants changes; re-approve and confirm with the *new* draft id the update returns.
6. **Confirm** only after explicit approval, then verify the submission status.

## Interviews and follow-up

- Freelancers cannot send the first message on a proposal — the client must engage first. If no conversation room exists yet, say so.
- When a client replies: read the full conversation history first, then draft a reply that advances the deal — answer concretely and offer a small concrete deliverable (a plan, a quick audit) rather than reassurances.
- When scope and rate are agreed, propose a contract through the conversation-level proposal capability when the tooling offers it (not binding until the client accepts and funds).
- Track offers: present terms, and remember that *accepting* an offer is binding and typically must be finalized by the user on upwork.com via the provided link — decline/counter flows go through the draft-confirm path.
- On active contracts, submit milestone work with a clear client-facing note when the milestone capability is available.

## Standing rules

- One draft at a time, one confirmation per write — "approve all" is not blanket approval.
- Never spend connects (submission cost, boost bids, profile boosts) beyond an amount the user explicitly approved.
- Boosting: only present options the preview actually offers, with the real competing bids; the user picks the amount.
- Track submitted proposals and surface client-activity insights (opens, shortlists, messages, competing-field averages) when available — presented as activity, not a verdict.
