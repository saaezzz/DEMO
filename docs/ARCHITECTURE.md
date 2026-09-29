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
- `Services/CharacterService` — ciclo de vida del personaje de cada jugador (crear, sincronizar con el `Humanoid`, liberar).
- `Services/CombatService` — carga los combos, atiende `CombatIntent`: ataque, bloqueo/parry, Shunpo, aturdimientos, regeneración.
- `Modules/HitboxUtil` — consultas espaciales y resolución de objetivos.
- `Network/ServerNetwork` — crea los remotes y registra handlers con validación obligatoria.
- `Network/RemoteGuard` — rate limit + validación + `pcall` para cada handler.
- `Modules/CombatIntentValidator` — esquema del payload de `CombatIntent`.
- `Modules/RateLimiter` — token bucket por clave (Luau puro).
- `Combos/ExampleCombos` — definiciones autoritativas de combos.

### Client
- `init.client.luau` — arranque: nivel de log y lista de controladores.
- `Controllers/CombatController` — input provisional y animaciones de combo.
- `Network/ClientNetwork` — `Invoke`/`Fire`/`OnEvent` sobre los remotes.

### Shared
- `Types/GameTypes`, `Types/DataTypes` — tipos compartidos y borrador del esquema de datos.
- `Modules/StateMachine` — máquina de estados genérica.
- `Modules/Character` — vida, Reiatsu, postura y estado de un personaje.
- `Network/RemoteDefinitions` — catálogo de remotes y rate limits (D-016).
- `Network/Schema` — validadores declarativos de payloads.
- `Utils/Signal` — señal síncrona en Luau puro (D-013).
- `Utils/Logger` — logs con niveles (D-015).
- `Utils/ServiceLoader` — arranque Init/Start (D-014).
- `Combos/ClientComboCatalog` — animación por combo (solo presentación).

## Arranque
`ServiceLoader.Run` ejecuta `Init` de todos los servicios en orden y después `Start` (D-014).
Servidor: `ServerNetwork` → `CombatService` → `CharacterService`. Cliente: `CombatController`.

## Flujo de un ataque
1. El cliente envía `{ Type = "Attack", ComboId }` por `CombatIntent`.
2. `RemoteGuard` aplica rate limit y valida el payload; `CombatService` comprueba personaje vivo, estado, cooldown y recurso.
3. Transición a `Attacking` y programación de los golpes (`task.delay` por ventana de golpe).
4. Cada golpe consulta la hitbox en la posición actual del atacante y resuelve bloqueo, parry, daño y postura.
5. Al salir de `Attacking` por cualquier motivo se cancelan los golpes pendientes.
6. El cliente reproduce la animación solo si la respuesta es `Accepted`.

## Convenciones de código
- `--!strict` en todos los módulos; patrones de clase y servicio según D-011.
- Identificadores en inglés; comentarios y documentación en español.
- Composición sobre herencia. Módulos pequeños y con una responsabilidad.
- Lógica pura (sin `game`/`Instance`) siempre que sea posible, para poder testearla con Lune (D-006).
- No duplicar lógica de negocio entre cliente y servidor.
