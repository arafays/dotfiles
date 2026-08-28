---
name: Upwork Job Finder
description: Search, score, and triage Upwork jobs against Abdul's frontend-first full-stack profile using the upwork MCP server, with client vetting and low-competition filters
---

# Upwork Job Finder

## Gate

Requires the `upwork` MCP server, which is **disabled by default** in `~/.config/opencode/opencode.jsonc` (`mcp.servers.upwork`). If upwork tools are unavailable, **ask the user to enable the server and wait — never edit any config file yourself**. Resume once they confirm it is enabled.

## Tooling

Do **not** assume tool names, actions, or parameter names — the upwork MCP evolves. Instead:

1. Discover the current upwork tools by searching the tool catalog for the upwork server namespace (queries like "upwork jobs", "upwork proposals").
2. Read each tool's live description/signature before calling it — most upwork tools embed their own usage rules, actions, and param lists, and several expose a tool-help capability for full reference. **When a tool's own description conflicts with anything written here, the tool wins.**
3. This skill deliberately references *capabilities* (job search, job details, account listing, saved jobs), not identifiers.

## Setup

- Identify the freelancer account and its org id first via the account-listing tool; pass that org id on every subsequent call. Never hardcode it.
- If triage depends on application budget, check the connects balance via the profile tooling.

## Fit profile

Score every job against Abdul's positioning ($35/hr, frontend-first full-stack, 12+ years):

- **Tier 1 — core:** React, Next.js, Vue.js, Nuxt, TypeScript, JavaScript, TailwindCSS, CSS/SCSS, responsive design
- **Tier 2 — full-stack:** Node.js, Express, MongoDB, MySQL, Firebase, REST/API integration, Docker, CI/CD
- **Tier 3 — differentiators:** PWA, Core Web Vitals / Lighthouse / performance audits, SEO, accessibility, Figma-to-code
- **Tier 4 — AI:** OpenAI, Vercel AI SDK, chatbot / LLM / fal.ai integrations
- **Low fit (penalize):** WordPress, Shopify, Wix, PHP/Laravel, native mobile, pure graphic design, data entry
- **Rate floor:** hourly budgets under ~$20/hr are weak fits; under $10/hr skip unless the client is exceptional.

### Scoring (0-10)

+3 Tier-1 match in title/skills · +2 Tier-2 backend present · +1 performance/PWA/SEO/a11y emphasis · +1 AI work · +1 budget clears the rate floor · +2 client quality (verified payment AND (lifetime spend ≥ $10k OR hires ≥ 5) AND rating ≥ 4.5) · −2 low-fit stack · −2 below rate floor · −1 heavy proposal competition (e.g., 50+ existing proposals).

Present ≥7 as **Apply now**, 5–6 as **Maybe**, <5 as **Skip**.

## Client vetting

Interpret the client fields the search results actually return; these heuristics apply when present:

- A client rating is typically the score *freelancers* gave that client — below ~4.0 is a warning about the client, not about their success. Check what the response says the rating basis is.
- Read lifetime spend and hire count together (45 hires at $500 ≠ 45 hires at $50k).
- Unverified + $0 spent + 0 hires = high risk, especially for fixed-price work.
- Search results generally omit hire/invite liveness and the client's preferred qualifications — fetch full job details on shortlisted jobs before recommending a submission.

## Search workflow

1. **URL or job id given** → fetch that job's full details (job tools usually accept a numeric id, a `~02…` ciphertext, or a full Upwork URL as-is). Evaluate directly.
2. **Default discovery** → use the profile-matched job search capability (matches jobs to the freelancer's profile skills) if the current tools offer it; otherwise run a filtered search built from the Tier 1-2 skills above.
3. **Named tech/niche** → run a filtered search with a query like "next.js dashboard" or "vue performance audit".
4. Useful refinements to offer when relevant (exact param names come from the live tool schema; ask before applying optional filters when the user asks for "best/top/urgent" picks): job type, verified-payment-only, proposal count (low-competition mode: few existing proposals), budget bounds, client hire count (proven hirers), recency/sort, workload, expected duration, timezone/location, previous clients only, experience level.
5. Marketplace search commonly lacks a posted-date filter — sort by recency where available and narrow client-side using the dates each result carries; jobs older than ~2 weeks with many proposals score lower.
6. Paginate only when the response says more pages exist, repeating identical filters with the provided cursor.

## Output

One ranked table: title (linked to the job URL), type + budget, fit score, why it fits (one line), client signals (country, rating, hires, spend, verification), proposal count, age. Then **Top picks** — the 1-3 jobs worth acting on now and why, plus which refinements would sharpen another pass.

## Handoff

- Save interesting jobs via the saved-jobs capability if present (job id comes from the results).
- For a chosen job, load the `upwork-proposal-writer` skill (letter craft) which hands off to `upwork-proposal-submitter` (submission) — pass the job's identifier and URL.
