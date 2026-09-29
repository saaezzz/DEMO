# Changelog

Formato basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/).
Las entradas nuevas van en `Unreleased`.

## [Unreleased]

### Added
- Toolchain fijado con Rokit (`rokit.toml`): rojo, selene, stylua, luau-lsp, lune.
- Configuración de lint (`selene.toml`), formato (`stylua.toml`) y tipos (`.luaurc`).
- `.gitattributes` para forzar finales de línea LF.
- `docs/PROJECT_CONSTITUTION.md`, `docs/DECISIONS.md`, `docs/CHANGELOG.md`.
- Script `Health` vacío en `StarterCharacterScripts` para desactivar la regeneración por defecto de Roblox (D-010).

### Changed
- Clases y servicios reescritos con el patrón de D-011: 0 errores de tipo en luau-lsp (antes 57) y 0 avisos de Selene.
- `CombatIntent` reducido a `Type` + `ComboId`; `ServerCombatResponse` a `Status` + `Message`; `AnimationId` solo en `ClientComboCatalog` (D-012).
- Los cooldowns de combate se mantienen al morir (antes morir los reiniciaba).
- `Character` y `StateMachine` siguen siendo seguros de usar tras `Destroy` (antes quitaban la metatabla y cualquier llamada fallaba).

### Fixed
- Combate: `Stunned` ya no es permanente; parry (0,8 s) y rotura de postura (1,5 s) tienen duración y vuelven a `Idle`.
- Combate: los golpes y la recuperación de un ataque se cancelan al salir de `Attacking` (sin golpes tras recibir parry, y la recuperación de un combo anterior ya no corta el siguiente).
- Combate: las tareas programadas se limpian al ejecutarse o al desregistrar el personaje (antes la lista crecía sin límite).
- Recursos: el Reiatsu se regenera y la postura decae de forma pasiva; el M1 ya no consume Reiatsu (D-008).
- Personajes: las conexiones por personaje se liberan en cada respawn (antes se acumulaban); al salir un jugador su personaje se retira también del combate.
- Personajes: un respawn durante la carga ya no registra un modelo antiguo; `Init` ya no bloquea esperando al personaje.
- Personajes: la muerte del `Humanoid` por causas ajenas al combate marca al `Character` como muerto.
- Hitbox: detecta personajes aunque la pieza golpeada esté en un sub-modelo (arma, accesorio).
- Cliente: usa el `Animator` creado por el servidor (las animaciones replican) y cachea los tracks en lugar de cargar uno por ataque.

### Security
- `CombatIntent`: validación de tipo, campos permitidos, tamaño y valores del payload; el servidor usa una copia saneada.
- `CombatIntent`: rate limit por jugador (token bucket, ráfaga 10, 8/s).
- Parry: ventana concedida como máximo cada 0,8 s; pulsar bloqueo en bucle ya no encadena parries.
- Los intents de un personaje muerto se rechazan.

### Removed
- Scripts de prueba `RedCircle.server.luau` y `Hello.luau`.
- Borrador de `DataService` y `Packages/README.md` (D-012).
- ID de animación de relleno `rbxassetid://0` del catálogo del cliente.
- Hook de depuración `OnComboHitMarker` del cliente y propiedad obsoleta `Workspace.FilteringEnabled`.

## [0.0.1] - 2026-09-29
### Added
- Prototipo inicial de combate: `StateMachine`, `Character`, `CombatService`, `HitboxUtil`, `CombatController`.
- Borrador de `DataService` (sin conectar).
