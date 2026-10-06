---
description: Plan a feature by writing decisive, code-local comments without changing executable code.
agent: build
---

Plan the requested work by editing comments in the codebase, not by implementing behavior.

User request and context: $ARGUMENTS

Instructions:

- First inspect the relevant code so the comments are grounded in the actual flow.
- Write temporary planning comments near the code that will change.
- Keep each comment local to the code around it.
- Component comments describe component/rendering work.
- Route comments describe request handling, validation, auth, redirects, and persistence.
- Service comments describe service-owned data flow, integrations, and side effects.
- Write comments decisively. Avoid words like "probably", "maybe", "might", "consider", and "or something" unless there is a real unresolved decision.
- Do not change executable code unless the user explicitly asks for implementation.
- If a comment points to work owned by another file or layer, move that note to the file that owns the work.
- Preserve the style and rough tone of nearby planning comments when they already exist.

When finished, summarize which files received planning comments and confirm that executable code was not changed.
