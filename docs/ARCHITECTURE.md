# Architecture

Principios generales en [PROJECT_CONSTITUTION.md](PROJECT_CONSTITUTION.md) §10–13 y §66.
Decisiones concretas en [DECISIONS.md](DECISIONS.md).

## Modelo cliente / servidor
El servidor es autoritativo sobre todo el estado de juego (vida, recursos, estados, cooldowns, daño).
El cliente envía **intenciones**; el servidor las valida y decide.

| Capa | Responsabilidades |
|---|---|
| Cliente | Input, cámara, UI, VFX locales, reproducción de animaciones |
| Servidor | Validación, combate, daño, estado de personajes, persistencia, NPCs |
| Shared | Tipos, módulos de lógica sin autoridad, catálogos de solo lectura |

## Mapeo Rojo
| Carpeta | Destino en el juego |
|---|---|
| `src/Server` | `ServerScriptService.Server` |
| `src/Client` | `StarterPlayer.StarterPlayerScripts.Client` |
| `src/Shared` | `ReplicatedStorage.Shared` |
| `src/CharacterScripts/Health.server.luau` | `StarterPlayer.StarterCharacterScripts.Health` (D-010) |
| — | `ReplicatedStorage.Remotes` — creada por `ServerNetwork` al arrancar (D-016) |

## Módulos actuales
### Server
- `init.server.luau` — arranque: nivel de log y lista ordenada de servicios para `ServiceLoader`.
- `Services/DataService` — perfiles con ProfileStore, migraciones y replicación al dueño (`docs/DATA.md`).
- `Services/CharacterService` — aparición tras cargar el perfil, sincronización con el `Humanoid`, reaparición y liberación.
- `Data/DataSchema`, `Data/Migrator` — versión, plantilla y migraciones del perfil.
- `Packages/ProfileStore` — tercero, no se modifica.
- `Services/CombatService` — registra a los personajes que combaten, atiende `CombatIntent` y gestiona la guardia (bloqueo/parry).
- `Services/AbilityService` — framework de habilidades (§17, D-025): requisitos, cooldown, coste, golpes, cadena M1.
- `Services/MovementService` — velocidad, sprint y capa de locomoción (D-026).
- `Services/ResourceService` — regeneración de recursos (con espera tras gastar) y postura.
- `Services/TrainingService` — muñecos de entrenamiento (D-027).
- `Services/EnemyService` — aparición, IA y recompensas de los enemigos (D-029).
- `Services/ProgressionService` — EXP y nivel (D-028).
- `Services/QuestService` — misiones: inicio, progreso, recompensas y cadena (D-030).
- `Npc/NpcFactory`, `Npc/NpcActions` — creación de NPCs de combate y ataques con aviso (§41).
- `Npc/EnemyBrain` — decisiones de la IA de enemigos (puro).
- `Modules/QuestLogic` — progreso de misiones (puro).
- `Content/Enemies`, `Content/EnemySpawns` — enemigos y zonas de aparición.
- `Combat/CombatRegistry` — personajes en combate y su estado de combate; punto común de los servicios.
- `Combat/DamageService`, `Combat/DamageResolver` — aplicación y resolución (pura) de golpes: parry, bloqueo, guardia rota, i-frames, aturdimiento, empuje.
- `Combat/HitboxService`, `Combat/HitboxUtil` — objetivos válidos y consultas espaciales.
- `Combat/Cooldowns`, `Combat/ComboChain`, `Combat/TaskScheduler` — piezas puras de cooldowns, cadena M1 y tareas agrupadas.
- `Config/CombatConfig`, `Config/MovementConfig` — valores de balance.
- `Network/ServerNetwork` — crea los remotes y registra handlers con validación obligatoria.
- `Network/RemoteGuard` — rate limit + validación + `pcall` para cada handler.
- `Combat/CombatIntentValidator` — esquema del payload de `CombatIntent`.
- `Modules/RateLimiter` — token bucket por clave (Luau puro).
- `Content/Abilities`, `Content/Movesets`, `Content/TrainingDummies` — contenido autoritativo (habilidades, qué habilidad va en cada acción, muñecos).
- `Modules/CharacterReplicator` — refleja el estado del `Character` en atributos del modelo (D-021).

### Client
- `init.client.luau` — arranque: nivel de log y lista de controladores.
- `Controllers/InputController` — acciones abstractas de input (teclado, mando, táctil; `docs/INPUT.md`).
- `Input/InputBindings` — controles por acción y plataforma.
- `Controllers/CombatController` — traduce acciones a intents de combate y avisa de los cooldowns.
- `Controllers/NotificationController`, `Controllers/QuestTrackerController`, `Controllers/ActionBarController`, `Controllers/TargetFrameController` — HUD de M3 (D-031).
- `Controllers/LockOnController` — fijado de objetivo y cámara de combate (D-032).
- `Controllers/MovementController` — aplica el desplazamiento de dash y esquiva aprobados (D-026).
- `Controllers/HudController`, `Controllers/NameplateController`, `Controllers/HitFeedbackController` — UI provisional (`docs/UI.md`, D-022).
- `Controllers/CharacterAnimationController` — locomoción y animaciones de acción según el estado replicado (`docs/ANIMATIONS.md`, D-022).
- `UI/Theme`, `UI/UIUtil`, `UI/StatBar` — estilo y componentes de UI.
- `Animation/ProceduralClip`, `Animation/ProceduralAnimator`, `Animation/PlaceholderAnimations` — animaciones procedurales provisionales.
- `Utils/CharacterWatcher` — callback por cada personaje que aparece (jugadores y NPCs etiquetados), con limpieza al irse.
- `Network/ClientNetwork` — `Invoke`/`Fire`/`OnEvent` sobre los remotes.
- `Controllers/PlayerDataController` — copia local de los datos del jugador.

### Shared
- `Types/GameTypes`, `Types/AbilityTypes`, `Types/EnemyTypes`, `Types/QuestTypes`, `Types/ContentTypes`, `Types/PlayerDataTypes` — tipos del núcleo, del contenido y del perfil.
- `Config/CharacterConfig`, `Config/ProgressionConfig` — valores base de balance y curva de progresión (no IP).
- `Modules/Progression` — cálculos de nivel, EXP y vida por nivel (puro, D-028).
- `Content/Races`, `Content/Resources`, `Content/Quests` — contenido público (capa IP).
- `Content/Assets`, `Content/Animations`, `Content/StateAnimations`, `Content/LocomotionAnimations` — manifiesto de assets y animaciones (`docs/ASSETS.md`, `docs/ANIMATIONS.md`).
- `Modules/StateMachine` — máquina de estados genérica.
- `Modules/Character` — vida, recursos genéricos, postura y las tres capas de estado de un personaje (D-024).
- `Modules/VelocityImpulse` — velocidad temporal (dash, esquiva, empuje).
- `Modules/AssetRegistry`, `Modules/AnimationRegistry` — acceso al manifiesto de assets y a las animaciones (D-020).
- `Network/RemoteDefinitions` — catálogo de remotes y rate limits (D-016).
- `Network/Schema` — validadores declarativos de payloads.
- `Network/ReplicatedAttributes` — nombres de los atributos replicados de los personajes (D-021).
- `Utils/Signal` — señal síncrona en Luau puro (D-013).
- `Utils/Logger` — logs con niveles (D-015).
- `Utils/ServiceLoader` — arranque Init/Start (D-014).

## Arranque
`ServiceLoader.Run` ejecuta `Init` de todos los servicios en orden y después `Start` (D-014).
Servidor: `ServerNetwork` → `DataService` → `AbilityService` → `MovementService` → `ResourceService` → `CombatService` → `CharacterService` → `ProgressionService` → `QuestService` → `TrainingService` → `EnemyService`. Cliente: `PlayerDataController` → `InputController` → `MovementController` → `CombatController` → `HudController` → `NameplateController` → `HitFeedbackController` → `NotificationController` → `QuestTrackerController` → `ActionBarController` → `LockOnController` → `TargetFrameController` → `CharacterAnimationController`.

## Flujo de una habilidad (D-025)
1. El cliente envía `{ Action = "LightAttack" }` por `CombatIntent`.
2. `RemoteGuard` aplica rate limit y valida el payload; `CombatService` busca el personaje vivo del jugador.
3. `AbilityService` elige la habilidad con el moveset (y la cadena M1), y comprueba requisitos de estado (§15),
   transición, aire, cooldown y coste.
4. Escribe `ActionAnimation`/`ActionSeq` en el modelo, pasa al estado de la habilidad y programa sus golpes.
5. Cada golpe consulta `HitboxService` desde la posición actual del atacante y `DamageService` resuelve
   i-frames, parry, bloqueo, guardia rota, daño, postura, aturdimiento y empuje.
6. Salir del estado de la habilidad por cualquier motivo (aturdido, esquiva, muerte) cancela los golpes pendientes.
7. Si es de movimiento, la respuesta lleva el desplazamiento y el cliente lo aplica (D-026).
8. Todos los clientes animan la habilidad a partir de los atributos replicados (D-021, D-022).

## Capa de contenido (IP)
Constitución §4 y D-017. El núcleo (servicios, módulos, tipos, red) no contiene nombres de la IP;
los datos concretos viven en carpetas `Content` y se referencian por ID. `tests/Content/IpBoundary.spec.luau`
lo hace cumplir y `ContentIntegrity.spec.luau` valida las referencias entre definiciones.

## Convenciones de código
- `--!strict` en todos los módulos; patrones de clase y servicio según D-011.
- Identificadores en inglés; comentarios y documentación en español.
- Composición sobre herencia. Módulos pequeños y con una responsabilidad.
- Lógica pura (sin `game`/`Instance`) siempre que sea posible, para poder testearla con Lune (D-006).
- No duplicar lógica de negocio entre cliente y servidor.
