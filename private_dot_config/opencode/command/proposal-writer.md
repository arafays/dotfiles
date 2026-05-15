---
description: Write an Upwork proposal using your portfolio and experience
model: opencode-go/deepseek-v4-flash
fallback_modes: [
  "opencode-go/mimo-v2-omni",
]
---

The user wants to write an Upwork proposal. Load the upwork-proposal-writer skill and follow its instructions to craft a tailored proposal.

1. Ask the user for the job posting URL or paste the job description text.
2. Load the upwork-proposal-writer skill.
3. Analyze the job posting against the skill's portfolio, tech stack, and approach.
4. Write a tailored 3-5 paragraph proposal following the proposal structure template in the skill.
5. Present the proposal to the user for review/edits before they copy it.
6. If the job posting includes screening questions, answer each one concisely and accurately using the skill's portfolio and experience. If the skill does not contain enough information to answer a question, ask the user for the relevant details rather than guessing.

Job Description after this point should be provided by the user, and the proposal will be crafted based on that information
---
