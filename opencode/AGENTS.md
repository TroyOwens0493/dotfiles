# Agent Documentation Guidance

When you need documentation or are unsure about an API, library, or framework detail, use Context7 to fetch up-to-date docs and examples. This should be your default source for resolving uncertainty and confirming usage.

# Coding Rules

## Types

- Use types for everything you write: function parameters, variables when inference is not enough, component props, loader/action data, and object shapes.
- Avoid `any`. Prefer precise unions, generics, utility types, and narrowed domain types.
- Define a type inline only when it is local to a single file and will not be reused.
- When a type may be shared across files, move it to a shared type module instead of redefining it.
- Never write explicit return types for functions, when using TypeScript they should always be inferred.

## Functions

- Add a doc comment to every function you write, including exported helpers, server utilities, loaders, actions, React components, and small local helpers.
- Keep doc comments concise and useful. Describe the function's purpose and include important behavior when it is not obvious from the name/signature.
- Try to keep write functions that only do one thing. If you are considering writing a function that does lots of tasks, consider refactoring.

## Comments

- Write inline comments for code that is complex, surprising, or otherwise hard to follow.
- Do not add comments for straightforward code or comments that only restate the code.
- Prefer comments that explain why the code exists, what edge case it handles, or what assumption it relies on.
