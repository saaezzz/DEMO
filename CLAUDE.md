GAME ENGINE
Roblox

LANGUAGE
Luau

ART SOFTWARE
Blender

ARCHITECTURE
Client / Server

SERVER AUTHORITY
YES

CODE STYLE
Typed Luau

DESIGN PRINCIPLE
Prefer composition over inheritance

NETWORKING
All client input must be validated server-side

ASSETS
All assets must follow naming conventions

PERFORMANCE
Mobile must be supported

AI RULE
Never modify architecture without documenting the change

---

PROJECT CONSTITUTION
Read docs/PROJECT_CONSTITUTION.md before any non-trivial change. It is the source of truth
for scope, architecture, security and workflow. Key rules:
- Gameplay framework must stay separate from IP/content data (§4): no "Shunpo", "Bankai",
  race names, etc. hardcoded inside core services — use Definitions.
- Server is authoritative; every remote validates type, size, rate, state and ownership (§10–11).
- Vertical slice first; do not implement P3/P4 while P0/P1 is broken (§62–63).
- Avoid overengineering (§66).

DECISIONS
Record every non-trivial technical or design decision in docs/DECISIONS.md (D-XXX entries).
Record user-visible changes in docs/CHANGELOG.md under [Unreleased].

TOOLCHAIN
Managed by Rokit (rokit.toml). Run `rokit install` once.
- Lint:    selene src
- Format:  stylua src          (check: stylua --check src)
- Sync:    rojo serve
- Types:   luau-lsp analyze --sourcemap=sourcemap.json --definitions=globalTypes.d.luau src
           (setup in README; must report 0 errors)
Run selene, stylua --check and luau-lsp analyze before committing Luau changes.
Follow the class/service patterns in docs/DECISIONS.md D-011.

LANGUAGE OF THE PROJECT
Code identifiers in English. Comments, docs and commit messages in Spanish.

COMMITS
Small and meaningful, Conventional Commits: feat(...), fix(...), refactor(...), docs(...), test(...), chore(...).
