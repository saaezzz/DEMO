# Changelog

Formato basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/).
Las entradas nuevas van en `Unreleased`.

## [Unreleased]

### Added
- Toolchain fijado con Rokit (`rokit.toml`): rojo, selene, stylua, luau-lsp, lune.
- Configuración de lint (`selene.toml`), formato (`stylua.toml`) y tipos (`.luaurc`).
- `.gitattributes` para forzar finales de línea LF.
- `docs/PROJECT_CONSTITUTION.md`, `docs/DECISIONS.md`, `docs/CHANGELOG.md`.

### Removed
- Scripts de prueba `RedCircle.server.luau` y `Hello.luau`.

## [0.0.1] - 2026-09-29
### Added
- Prototipo inicial de combate: `StateMachine`, `Character`, `CombatService`, `HitboxUtil`, `CombatController`.
- Borrador de `DataService` (sin conectar).
