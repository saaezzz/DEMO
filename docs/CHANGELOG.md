# Changelog

Formato basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/).
Las entradas nuevas van en `Unreleased`.

## [Unreleased]

### Added
- Toolchain fijado con Rokit (`rokit.toml`): rojo, selene, stylua, luau-lsp, lune.
- Configuración de lint (`selene.toml`), formato (`stylua.toml`) y tipos (`.luaurc`).
- `.gitattributes` para forzar finales de línea LF.
- `docs/PROJECT_CONSTITUTION.md`, `docs/DECISIONS.md`, `docs/CHANGELOG.md`.

### Fixed
- Combate: `Stunned` ya no es permanente; parry (0,8 s) y rotura de postura (1,5 s) tienen duración y vuelven a `Idle`.
- Combate: los golpes y la recuperación de un ataque se cancelan al salir de `Attacking` (sin golpes tras recibir parry, y la recuperación de un combo anterior ya no corta el siguiente).
- Combate: las tareas programadas se limpian al ejecutarse o al desregistrar el personaje (antes la lista crecía sin límite).
- Recursos: el Reiatsu se regenera y la postura decae de forma pasiva; el M1 ya no consume Reiatsu (D-008).

### Security
- `CombatIntent`: validación de tipo, campos permitidos, tamaño y valores del payload; el servidor usa una copia saneada.
- `CombatIntent`: rate limit por jugador (token bucket, ráfaga 10, 8/s).
- Parry: ventana concedida como máximo cada 0,8 s; pulsar bloqueo en bucle ya no encadena parries.
- Los intents de un personaje muerto se rechazan.

### Removed
- Scripts de prueba `RedCircle.server.luau` y `Hello.luau`.

## [0.0.1] - 2026-09-29
### Added
- Prototipo inicial de combate: `StateMachine`, `Character`, `CombatService`, `HitboxUtil`, `CombatController`.
- Borrador de `DataService` (sin conectar).
