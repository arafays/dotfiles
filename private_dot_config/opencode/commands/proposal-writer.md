---
description: Write a tailored Upwork proposal using Abdul's portfolio and experience
model: opencode-go/deepseek-v4-flash
---

Write a tailored Upwork proposal for the job posting in `$ARGUMENTS`.

If `$ARGUMENTS` is empty, ask the user for the Upwork job URL or pasted job description before writing anything.

Load the `upwork-proposal-writer` skill and follow it exactly.

Core workflow:

1. Extract the client's real need, required stack, budget/timeline hints, and any screening questions.
2. Match only the most relevant parts of Abdul Rafay Shaikh's experience and portfolio from the skill.
3. Write a concise, plain-text proposal in 3-5 short paragraphs.
4. Mention 1-2 relevant portfolio projects with URLs when they strengthen the pitch.
5. Ask 1-2 thoughtful project-specific questions, not generic discovery questions.
6. Avoid markdown formatting, fake claims, fixed estimates without enough scope, and WordPress/no-code positioning.
7. If screening questions are present, answer them after the proposal in plain text. Ask the user for missing details instead of guessing.
