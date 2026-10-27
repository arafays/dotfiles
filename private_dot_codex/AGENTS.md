<!-- CODEGRAPH_START -->
## CodeGraph

In repositories indexed by CodeGraph (a `.codegraph/` directory exists at the repo root), reach for it BEFORE grep/find or reading files when you need to understand or locate code:

- **MCP tool** (when available): `codegraph_explore` answers most code questions in one call — the relevant symbols' verbatim source plus the call paths between them, including dynamic-dispatch hops grep can't follow. Name a file or symbol in the query to read its current line-numbered source. If it's listed but deferred, load it by name via tool search.
- **Shell** (always works): `codegraph explore "<symbol names or question>"` prints the same output.

If there is no `.codegraph/` directory, skip CodeGraph entirely — indexing is the user's decision.
<!-- CODEGRAPH_END -->

<!-- MODEL_ROUTING_START -->
## Model routing and delegation

The user wants routine work on economical models. Apply this policy to coordinators and every descendant agent; explicit user model choices take precedence.

| Work | Model | Reasoning | Custom agent |
| --- | --- | --- | --- |
| Everyday coordination and bounded integration | `gpt-6-luna` | `high` | main session |
| Bounded exploration, docs extraction, test/log analysis | `gpt-6-luna` | `high` | `explorer` |
| Scoped implementation following an agreed approach | `gpt-6-luna` | `high` | `worker` |
| Substantial independent correctness review and integration risks | `gpt-6.1-sol` | `medium` | `reviewer` |
| New visual direction, redesign tradeoffs, difficult visual judgment | `gpt-6.1-sol` | `high` | `design_director` |
| Ambiguous architecture, security, concurrency, persistent difficult failures | `gpt-6.1-sol` | `high` | `expert` |

- Delegate useful independent work, especially read-heavy investigation and verification. Keep tiny tasks and dependent steps in the main agent. Do not create every role for every request.
- Start with one or two focused subagents; use at most two concurrently across the task tree. Children return to their coordinator before creating more agents unless the coordinator explicitly assigns a further split.
- Select the custom agent when the tool supports it. Otherwise pass its model and reasoning explicitly when supported. Do not silently inherit the coordinator's expensive model. If selecting a model requires `fork_turns="none"`, use a fresh context and supply a self-contained brief; use full-history forks only when that history is necessary and acknowledge their inherited model.
- Each handoff states the question/outcome, relevant files, ownership of writes, constraints, and acceptance checks. Return changed paths, evidence, unresolved risks, and a short result; keep raw logs in files. Parallel writers own disjoint files. One agent integrates and runs shared checks.
- Escalate only the bounded hard part when the lower tier cannot resolve a concrete issue after a focused attempt, or when the task is already clearly security-sensitive or architecturally ambiguous. Give the expert the evidence and failed approach. Return routine execution to the lower tier afterward.
- Avoid duplicate investigations, repeated full test runs, speculative agent trees, and blanket reviews for trivial edits. Reuse an existing agent when appropriate. Max/Ultra and Astra require an explicit user request; they are not routine fallbacks.
- If a requested model is unavailable, report that fact and choose an available economical model appropriate to the task; do not silently upgrade every agent to GPT-6.1/Astra. Saved defaults affect new sessions; existing chats may retain their composer model/effort.

### Impeccable compatibility

For UI work, follow the installed Impeccable skill and its selected playbook. The coordinator loads `impeccable context` once in its session and supplies relevant context paths and approved decisions to workers. A fresh subagent follows its own applicable skill setup; do not assume a summary replaces required source/context reads. Read `craft-floor.md` immediately before UI edits. Use Luna for well-scoped refinements, implementation, detector runs, and mechanical QA; reserve GPT-6.1 for substantial review, open-ended direction, or difficult fidelity judgments. When the playbook requires the shipped `impeccable_finish_reviewer`, spawn that role fresh without conversation history and supply its complete evidence packet; the personal reviewer is not a substitute. Honor shipped role configuration. Use the shipped `impeccable_documenter` when required and verify its required outputs. Inspect the rendered result at shipped sizes and batch fixes between captures. Keep approved product truth, identity, behavior, and copy within the requested scope. Workflow advice alone does not authorize a design command. Do not reduce required visual verification or change the installed skill to save tokens.
<!-- MODEL_ROUTING_END -->
