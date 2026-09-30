# Changelog

Formato basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/).
Las entradas nuevas van en `Unreleased`.

## [Unreleased]

### Added
- M4 Vertical Slice 0.1 (Shinigami): integración de arte desde Studio sin código con informe en Output y `docs/GUIA_EQUIPO.md` (D-033); elección de raza con kit (espada, Shunpo, Byakurai, Sai y objetos iniciales; D-034); efectos visuales por datos (D-035); inventario con rarezas, botín por jugador, consumibles y mochila (D-036); jefe Gran Hollow con 3 fases, golpe en área avisado con círculo y barra de jefe (D-037).
- M3 Loop PvE mínimo: enemigos con IA (tres tipos, zona de caza, avisos en rojo; D-029), EXP y nivel (D-028), cadena de tres misiones con seguimiento y marcador (D-030), barra de EXP, avisos de progreso, barra de acciones con cooldowns y panel del objetivo (D-031), fijado de objetivo con cámara de combate (D-032).
- `NpcFactory`/`NpcActions` comunes a muñecos y enemigos; `EnemyBrain`, `QuestLogic` y `Progression` puros con tests.
- M2 Combat Foundation: framework de habilidades (D-025) con cadena M1 de tres golpes, ataque pesado que rompe guardias, esquiva con i-frames y dash direccional y aéreo; hitstun y empuje; stamina y sprint (D-026); muñecos de entrenamiento pasivo, atacante (con aviso rojo) y en guardia (D-027).
- Capas de locomoción y forma en `Character` (D-024): `IsInState` responde a los 16 estados de §15 y `MeetsRequirements` comprueba los requisitos de las habilidades.
- Servicios `AbilityService`, `MovementService`, `ResourceService` y `TrainingService`; módulos `CombatRegistry`, `DamageService`, `DamageResolver`, `HitboxService`, `Cooldowns`, `ComboChain`, `TaskScheduler` y `VelocityImpulse`.
- UI provisional propia (D-022, `docs/UI.md`): HUD con vida, postura, recursos, nivel/raza y estado; placas sobre los demás jugadores; destello y números de daño; pantalla de muerte con cuenta atrás. Sustituye la barra de vida y el nombre por defecto de Roblox.
- Animaciones provisionales (D-022): locomoción con el pack Ninja del catálogo de Roblox y animaciones procedurales de tajo, guardia, dash y aturdimiento, sustituibles por assets reales sin tocar código.
- Estado de los personajes replicado por atributos del modelo (`CharacterReplicator`, `ReplicatedAttributes`, D-021).
- Pautas de diseño de la guía de PromptBlox en `GDD.md` y checklist de playtest en `TESTING.md` (D-023).
- `Shared/Utils/Signal`: señal síncrona en Luau puro (D-013).
- `Shared/Utils/Logger`: logs con niveles y ámbito (D-015).
- `Shared/Utils/ServiceLoader`: arranque en dos fases Init/Start (D-014).
- Tests con Lune: runner con emulación del árbol de instancias desde el sourcemap y 51 tests de Signal, StateMachine, Character, Logger, ServiceLoader, RateLimiter y CombatIntentValidator (`docs/TESTING.md`).
- CI en GitHub Actions: formato, lint, tipos, tests y build.
- DataService v1 (D-018): ProfileStore 1.0.3, `DataVersion` y migraciones sobre copia, replicación al dueño (`PlayerData`), `PlayerDataController` en el cliente. Doc `DATA.md`.
- Aparición controlada por el servidor tras cargar el perfil y reaparición tras morir (`CharacterAutoLoads` desactivado).
- Manifiesto de assets con convención de nombres y flujo de estados, registro de animaciones con markers estándar (D-020). Docs `ASSETS.md` y `ANIMATIONS.md`.
- Capa de input (D-019): acciones abstractas, controles para teclado/ratón, mando y botones táctiles; `InputController`. Doc `INPUT.md`.
- Capa de contenido (D-017): `Shared/Content` (razas, recursos, animaciones), `Server/Content` (combos, acciones), `Shared/Config/CharacterConfig` y tipos `ContentTypes`. Tests de frontera de IP e integridad de contenido.
- Capa de red (D-016): `RemoteDefinitions`, `Schema`, `ServerNetwork`, `RemoteGuard`, `ClientNetwork`; remotes creados por código. Docs `NETWORKING.md` y `SECURITY.md`.
- Toolchain fijado con Rokit (`rokit.toml`): rojo, selene, stylua, luau-lsp, lune.
- Configuración de lint (`selene.toml`), formato (`stylua.toml`) y tipos (`.luaurc`).
- `.gitattributes` para forzar finales de línea LF.
- `docs/PROJECT_CONSTITUTION.md`, `docs/DECISIONS.md`, `docs/CHANGELOG.md`.
- Script `Health` vacío en `StarterCharacterScripts` para desactivar la regeneración por defecto de Roblox (D-010).

### Changed
- `Movesets` pasa a `Shared` y el moveset depende de la raza; `Dash` se divide en `Shunpo` (Shinigami) y `Step` (sin raza).
- En táctil, pesado, esquiva, dash y técnicas se lanzan desde las casillas de la barra de acciones; los botones de pantalla quedan para atacar, bloquear y fijar.
- Al cargar el perfil se retoman las cadenas de misiones con una misión siguiente nueva.
- Perfil v2: añade `Quests` con migración desde v1 (D-030). La vida máxima depende del nivel.
- La respuesta de `CombatIntent` incluye el cooldown de la habilidad aceptada.
- Guardia con cooldown de 0,5 s tras soltarla (no se puede espamear); el cliente reintenta mientras se mantiene la tecla. Empuje algo mayor (remate 55, pesado 45 studs/s).
- `CombatIntent` pasa a `{ Action, Active? }`: el cliente pide acciones y el servidor elige la habilidad (D-025). `Combos`, `CombatActions` y `ComboAnimations` se sustituyen por `Abilities` y `Movesets`.
- Los golpes solo afectan a enemigos (PvE). Transformar pasa a R2 en mando; Sprint usa Shift/L3 y se desactiva el shift-lock de Roblox.
- Valores de balance de combate en `Server/Config/CombatConfig` y de movimiento en `Server/Config/MovementConfig`.
- `CombatController` solo envía intents; las animaciones pasan a `CharacterAnimationController`.
- `CharacterService` usa `LoadCharacterAsync` (sustituye a la API obsoleta `LoadCharacter`) en una tarea propia con `pcall`.
- Las animaciones de combo se resuelven por clave vía `AnimationRegistry`; el marker del golpe de `BasicSlash` pasa a `Hit`.
- Bloqueo por mantener pulsado: intent `Block` con `Active` e idempotente en el servidor (D-019).
- Recursos genéricos por ID en `Character` (`SpendResource`, `RestoreResource`, `ResourceChanged`); costes `{ Resource, Amount }`; regeneración según la definición de cada recurso (D-017).
- Estados de acción de §15 adaptados (D-017); morir pasa a `Dead` (terminal) y cancela la acción en curso.
- El intent `Shunpo` pasa a ser `Dash` (estado `Dashing`); Shunpo queda como contenido.
- `Character` y `StateMachine` usan `Signal` en lugar de `BindableEvent` (eventos síncronos y deterministas).
- `CombatIntent` pasa por `ServerNetwork`; `CombatIntentValidator` es ahora un esquema de `Schema`; se elimina `Shared/Network/CombatRemotes` y el remote del `default.project.json`.
- Servicios y controladores arrancan con `ServiceLoader`; `CombatService` carga sus combos y conecta su remote; se eliminan los `Shutdown`/`Destroy` sin uso.
- Clases y servicios reescritos con el patrón de D-011: 0 errores de tipo en luau-lsp (antes 57) y 0 avisos de Selene.
- `CombatIntent` reducido a `Type` + `ComboId`; `ServerCombatResponse` a `Status` + `Message`; `AnimationId` solo en `ClientComboCatalog` (D-012).
- Los cooldowns de combate se mantienen al morir (antes morir los reiniciaba).
- `Character` y `StateMachine` siguen siendo seguros de usar tras `Destroy` (antes quitaban la metatabla y cualquier llamada fallaba).

### Fixed
- El círculo rojo del golpe en área del jefe se dibuja en el suelo (antes el rayo que busca el suelo chocaba con el cuerpo del jefe y quedaba a media altura). También se aplica si Arte coloca su propio `VFX_Telegraph_Area`.
- El servidor ya no se detiene si el lugar trae una carpeta `ReplicatedStorage.Remotes` antigua: la sustituye y avisa.
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
- `Shared/Types/DataTypes` (borrador de perfil; se rediseña en la tarea 8).
- Scripts de prueba `RedCircle.server.luau` y `Hello.luau`.
- Borrador de `DataService` y `Packages/README.md` (D-012).
- ID de animación de relleno `rbxassetid://0` del catálogo del cliente.
- Hook de depuración `OnComboHitMarker` del cliente y propiedad obsoleta `Workspace.FilteringEnabled`.

## [0.0.1] - 2026-09-29
### Added
- Prototipo inicial de combate: `StateMachine`, `Character`, `CombatService`, `HitboxUtil`, `CombatController`.
- Borrador de `DataService` (sin conectar).
