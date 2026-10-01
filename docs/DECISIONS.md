# Decisions

Registro de decisiones técnicas y de diseño (formato ADR ligero).
Cada decisión es la fuente de verdad hasta que otra la reemplace explícitamente.

Estados: `ACCEPTED`, `SUPERSEDED`, `REJECTED`.

---

## D-001 — Constitución del proyecto en el repositorio
- **Fecha:** 2026-09-29
- **Estado:** ACCEPTED
- **Decisión:** La constitución del proyecto vive en `docs/PROJECT_CONSTITUTION.md` y `CLAUDE.md` la referencia.
- **Motivo:** GitHub es la fuente de verdad (§8). Cualquier sesión de Claude o miembro del equipo debe poder leerla.

## D-002 — Toolchain gestionado con Rokit
- **Fecha:** 2026-09-29
- **Estado:** ACCEPTED
- **Decisión:** Usar [Rokit](https://github.com/rojo-rbx/rokit) con `rokit.toml` en el repo. Herramientas fijadas: rojo 7.7.0, selene, stylua, luau-lsp, lune.
- **Alternativas:** Aftman (instalado globalmente antes; sin mantenimiento activo, Rokit es su sucesor y lee también `aftman.toml`), Foreman.
- **Motivo:** Versiones idénticas para todo el equipo y CI; `rokit install` basta para configurar un equipo nuevo.

## D-003 — Lint y formato
- **Fecha:** 2026-09-29
- **Estado:** ACCEPTED
- **Decisión:** Selene (`std = "roblox"`) + StyLua (tabs, 120 columnas, LF). `.luaurc` en modo `strict`. `.gitattributes` fuerza LF.
- **Motivo:** El código existente ya usaba tabs y `--!strict`; se formaliza en vez de cambiar el estilo.

## D-004 — Persistencia con ProfileStore
- **Fecha:** 2026-09-29
- **Estado:** ACCEPTED (implementado, ver D-018)
- **Decisión:** Sustituir ProfileService por [ProfileStore](https://github.com/MadStudioRoblox/ProfileStore) (sucesor del mismo autor).
- **Motivo:** ProfileService ya no recibe desarrollo activo. Todavía no existen datos guardados, así que la migración no tiene coste de datos.
- **Requisitos asociados:** `DataVersion` + migraciones (§59) desde la primera versión del esquema.

## D-005 — Replicación de datos propia y mínima
- **Fecha:** 2026-09-29
- **Estado:** ACCEPTED (implementado, ver D-018)
- **Decisión:** No usar ReplicaService. Replicar al cliente solo sus propios datos mediante la capa de red del proyecto (snapshot inicial + deltas por ruta). Los datos públicos necesarios para otros jugadores (nivel, raza visible) se replicarán explícitamente, nunca por defecto.
- **Alternativas:** ReplicaService (sin mantenimiento activo) o su sucesor `Replica`.
- **Motivo:** Menos dependencias externas para un equipo pequeño, control total sobre qué se filtra (el `Replication = "All"` anterior exponía inventario y moneda de todos los jugadores).

## D-006 — Tests con Lune para la lógica pura
- **Fecha:** 2026-09-29
- **Estado:** ACCEPTED (implementado)
- **Decisión:** Los tests de lógica pura (máquinas de estado, recursos, cooldowns, validadores, migraciones, fórmulas) se ejecutan con [Lune](https://github.com/lune-org/lune) fuera de Studio, para poder correr en CI. Los módulos de lógica deben evitar dependencias de `game`/`Instance` para ser testeables (p. ej. un `Signal` en Luau puro en vez de `BindableEvent`). Las pruebas de integración que requieran el motor se hacen en Studio.
- **Implementación:** runner propio (`tests/runner.luau`) que reconstruye el árbol de instancias desde el sourcemap de Rojo para que `script`, `game:GetService` y `require(instancia)` funcionen sin modificar los módulos. Aserciones mínimas estilo Jest. Se descartó Jest-Lua por su coste de integración con Lune para el tamaño actual del proyecto; se puede migrar si los tests crecen.
- **Motivo:** Tests que corren en cada commit sin abrir Studio; empuja hacia módulos desacoplados.

## D-007 — Salida automática de estados temporales en combate
- **Fecha:** 2026-09-29
- **Estado:** ACCEPTED
- **Decisión:** Todo estado temporal (`Stunned`) se programa con una duración y vuelve a `Idle` al expirar. Los golpes programados de un ataque se cancelan si el atacante deja el estado `Attacking`.
- **Motivo:** Corrige el bug de aturdimiento permanente y golpes "fantasma" tras un parry. Valores en constantes de `CombatService` hasta que exista `CombatConfig`/definiciones de datos.

## D-008 — M1 no consume recurso; regeneración de Reiatsu y postura
- **Fecha:** 2026-09-29
- **Estado:** ACCEPTED (valores provisionales, ver `BALANCE.md` cuando exista)
- **Decisión:** El ataque básico no cuesta Reiatsu. El Reiatsu se regenera y la postura decae de forma pasiva en un tick del servidor de baja frecuencia (no por Heartbeat).
- **Motivo:** Sin regeneración el jugador quedaba incapaz de atacar tras ~20 golpes. Un tick de 0,25 s sobre ≤15 jugadores es barato (§58).

## D-009 — Validación y rate limit del remote de combate
- **Fecha:** 2026-09-29
- **Estado:** ACCEPTED (provisional hasta la capa `Networking`, tarea 6)
- **Decisión:** `CombatIntent` valida tipo, campos y tamaño del payload y aplica un rate limit por jugador (token bucket). El bloqueo tiene un tiempo mínimo entre activaciones para que el parry no se pueda encadenar pulsando repetidamente.
- **Motivo:** §11. La lógica se moverá a la capa de red genérica cuando exista.

## D-010 — La vida autoritativa vive en Character; se desactiva la regeneración de Roblox
- **Fecha:** 2026-09-29
- **Estado:** ACCEPTED
- **Decisión:** `StarterCharacterScripts/Health` se sustituye por un script vacío (`src/CharacterScripts/Health.server.luau`). El `Humanoid` solo refleja la vida de `Character`. Las muertes ajenas al combate (`Humanoid.Died`, p. ej. caer al vacío) se propagan a `Character`.
- **Motivo:** El script por defecto regeneraba el `Humanoid` sin pasar por `Character`, creando dos fuentes de verdad. La regeneración de vida, si se quiere, la decidirá el servidor (futuro ResourceService).

## D-011 — Patrones de código para clases y servicios
- **Fecha:** 2026-09-29
- **Estado:** ACCEPTED
- **Decisión:**
  - **Clases** (objetos con varias instancias, p. ej. `Character`, `StateMachine`, `RateLimiter`):
    ```lua
    local Class = {}
    Class.__index = Class
    type ClassData = { _field: number }
    export type Class = typeof(setmetatable({} :: ClassData, Class))
    function Class.new(): Class return setmetatable({ _field = 0 }, Class) end
    function Class.Method(self: Class): number return self._field end
    ```
  - **Servicios y controladores** (singletons): estado privado en variables locales del módulo; la tabla del módulo solo expone la API pública (`function Service:Init()`).
  - Lecturas de mapas que pueden faltar se anotan como opcionales (`local x: Model? = map[key]`).
  - Sin casts `(self :: any) :: Internal` ni redefinición de `self`.
  - Los módulos de `Shared` se requieren siempre por la ruta absoluta `ReplicatedStorage.Shared...`, también desde otros módulos de `Shared`, para que cada módulo tenga una única identidad para el analizador.
  - Excepción para clases genéricas: ver D-013.
  - El analizador generaliza los literales a `string` en variables locales, variables de bucle, `pcall(f, ...)` y `task.spawn(f, ...)`. Si un valor debe conservar un tipo literal (estados, acciones, claves), anota la variable (`local state: CharacterStateName = ...`) y usa closures en `pcall`/`task.spawn`.
- **Motivo:** El patrón anterior producía 57 errores de tipo y 30 avisos de sombreado en luau-lsp y exponía el estado interno de los servicios. El nuevo patrón analiza sin errores en modo strict.

## D-012 — Retirada del borrador de DataService y reducción de CombatIntent
- **Fecha:** 2026-09-29
- **Estado:** ACCEPTED
- **Decisión:** Se elimina `DataService.luau` (no se inicializaba, dependía de paquetes ausentes y queda sustituido por D-004/D-005; sigue disponible en el historial de git). `CombatIntent` se reduce a `Type` + `ComboId` y `ServerCombatResponse` a `Status` + `Message`; `ComboDefinition` pierde `AnimationId` (la animación vive solo en `ClientComboCatalog`).
- **Motivo:** Eliminar código muerto y campos que nadie leía. Los campos de habilidades (`AbilityId`, dirección) se definirán con el framework de habilidades (M2), no por adelantado.

## D-013 — Signal propio, síncrono y en Luau puro
- **Fecha:** 2026-09-29
- **Estado:** ACCEPTED
- **Decisión:** `Shared/Utils/Signal` sustituye a `BindableEvent` en la lógica de juego. `Fire` ejecuta los handlers de forma síncrona y en orden; los handlers no deben ceder y sus errores se propagan a quien emite.
- **Alternativas:** `BindableEvent` (depende de `Instance`, no testeable con Lune; con `SignalBehavior = Deferred` los handlers se retrasan al final del frame, lo que hacía no determinista el orden de eventos de combate) o librerías externas tipo GoodSignal (un hilo por handler; innecesario aquí).
- **Tipado:** una clase genérica (`Signal<T...>`) no se puede tipar con el patrón `typeof(setmetatable(...))` de D-011 (el solver instancia mal los métodos genéricos). Para clases genéricas, el tipo público se declara como interfaz explícita y la implementación es interna, con un único cast en el constructor.

## D-014 — Ciclo de vida de servicios: Init / Start
- **Fecha:** 2026-09-29
- **Estado:** ACCEPTED
- **Decisión:** `Shared/Utils/ServiceLoader.Run({...})` recibe una lista **ordenada y explícita** de servicios (servidor) o controladores (cliente). Cada uno es una tabla con `Name` y, opcionalmente, `Init` (estado interno, sin llamar a otros servicios, sin yield) y `Start` (conexión de eventos y bucles). Un fallo aborta el arranque indicando servicio y fase. Los servicios viven lo mismo que el servidor: no hay `Shutdown`.
- **Alternativas:** Knit u otros frameworks; descubrimiento automático por carpeta; inyección de dependencias. Descartados por §66 (equipo pequeño, magia innecesaria).
- **Consecuencia:** cada servicio gestiona lo suyo en `Start` (p. ej. `CombatService` conecta su remote y carga sus combos en `Init`); los bootstraps solo fijan el nivel de log y la lista de servicios.

## D-015 — Logger con niveles
- **Fecha:** 2026-09-29
- **Estado:** ACCEPTED
- **Decisión:** `Shared/Utils/Logger` con niveles `Debug < Info < Warn < Error` y ámbito por módulo (`[Info][CombatService] ...`). Nivel global: `Debug` en Studio, `Info` en servidores publicados. `Error` escribe con `warn`, no lanza. La salida es inyectable para tests.
- **Motivo:** sustituir `print` sueltos por mensajes filtrables y con origen.

## D-016 — Capa de red con definiciones, esquemas y guardas
- **Fecha:** 2026-09-29
- **Estado:** ACCEPTED (sustituye la parte provisional de D-009)
- **Decisión:** Todos los remotes se declaran en `Shared/Network/RemoteDefinitions` (tipo y rate limit) y el servidor los crea por código. Un handler solo se puede registrar con `ServerNetwork:HandleFunction/HandleEvent` junto a un validador de `Shared/Network/Schema`; `RemoteGuard` aplica rate limit, validación y `pcall`. Los rechazos devuelven `nil` al cliente.
- **Alternativas:** librerías de red externas (ByteNet, Zap, Blink): aportan serialización binaria y tipado generado, pero añaden dependencia y paso de build; no hacen falta con el tráfico actual. Se reconsiderará si el ancho de banda lo exige.
- **Motivo:** §11 exige validar tipo, tamaño y ritmo en cada remote; centralizarlo evita que un remote nuevo olvide alguna comprobación. `CombatIntentValidator` pasa a ser un esquema (§67: un mecanismo reutilizable).
- **Pendiente:** `CombatIntent` sigue siendo `RemoteFunction` (el cliente espera la respuesta antes de animar). Pasar a evento + predicción del cliente se decidirá con el framework de combate (M2).

## D-017 — Capa de contenido, recursos genéricos y estados de acción
- **Fecha:** 2026-09-29
- **Estado:** ACCEPTED
- **Decisión (IP, §4):** Todo nombre propio de la IP vive en carpetas `Content`: `Shared/Content` (datos públicos: razas, recursos, animaciones) y `Server/Content` (datos autoritativos: combos, acciones). El núcleo solo maneja identificadores opacos (`RaceId`, `ResourceId`) y los tipos de `Shared/Types/ContentTypes`. El test `tests/Content/IpBoundary.spec.luau` falla si aparece un término de la IP fuera de `Content`; `ContentIntegrity.spec.luau` comprueba que todos los IDs referenciados existen. Los valores de balance que no son IP van en `Shared/Config`.
- **Decisión (recursos):** `Character` gestiona recursos genéricos por ID (`SpendResource`, `RestoreResource`, `ResourceChanged`). Los costes son `{ Resource, Amount }` y la regeneración usa `RegenPerSecond` de cada definición. La postura sigue siendo un medidor de combate propio de `Character`.
- **Decisión (estados, adaptación de §15):** la máquina de estados modela **acciones exclusivas**: `Idle`, `Attacking`, `Blocking`, `Parrying`, `Dodging`, `Dashing`, `Casting`, `Transforming`, `Stunned`, `Knocked`, `Ragdolled`, `Disabled`, `Dead`. Las interrupciones (`Stunned`, `Knocked`, `Ragdolled`, `Disabled`, `Dead`) son alcanzables desde cualquier estado vivo; `Dead` es terminal y morir transiciona a él. **Diferencias con §15:**
  - `Moving`, `Running`, `Sprinting` no son estados de acción sino una **capa de locomoción** independiente (MovementService, M2): un personaje puede atacar mientras se mueve, y meterlos en la misma máquina obligaría a duplicar cada acción por modo de movimiento.
  - `Transformed` es un **flag/capa** de TransformationService (M2), no un estado exclusivo: un personaje transformado sigue atacando, bloqueando, etc. `Transforming` (la animación de transformación) sí es un estado.
  - Se añade `Dashing` (movimiento rápido tipo Shunpo), distinto de `Dodging` (esquiva con i-frames).
- **Revisión:** revisada y confirmada en D-024 (capas centralizadas en `Character`).

## D-018 — DataService v1: versionado, migraciones y aparición tras cargar datos
- **Fecha:** 2026-09-29
- **Estado:** ACCEPTED
- **Decisión:**
  - ProfileStore 1.0.3 incluido en `src/Server/Packages` (commit fijado, licencia Apache-2.0, excluido de lint/formato/tipos). Se incluye el archivo en lugar de usar Wally: es una única dependencia y evita otra herramienta en el toolchain.
  - Esquema con `DataVersion` obligatorio. `Migrator` migra **una copia**: si una migración falla o los datos son de una versión futura (p. ej. tras un rollback del servidor), el jugador es expulsado y los datos guardados no cambian.
  - Replicación propia (D-005): copia completa al cargar y cambios por clave de primer nivel, solo al dueño, por el remote `PlayerData` (`ToClientEvent`).
  - `Players.CharacterAutoLoads = false`: el personaje aparece cuando el perfil está cargado (usa su raza y nivel) y reaparece tras `CharacterConfig.RespawnSeconds`.
- **Motivo:** §59 (no destruir datos), §10 (el servidor decide la aparición) y evitar la carrera entre `CharacterAdded` y la carga del perfil.

## D-019 — Capa de input por acciones con ContextActionService
- **Fecha:** 2026-09-29
- **Estado:** ACCEPTED (pendiente de verificar en Studio con mando y emulador móvil)
- **Decisión:** Acciones abstractas (`InputBindings`) con controles por plataforma como datos; `InputController` las enlaza con `ContextActionService` y emite `ActionBegan`/`ActionEnded`. Los botones táctiles son los de `ContextActionService` (sin UI propia hasta que el equipo de UI la diseñe). El bloqueo pasa de alternar a **mantener pulsado**: el cliente envía `Block` con `Active = true/false` y el servidor lo aplica de forma idempotente.
- **Alternativas:** `UserInputService.InputBegan` (no crea botones táctiles; cada sistema tendría que filtrar teclas) o una UI táctil propia (depende del equipo de UI; se podrá sustituir sin tocar los sistemas de juego).
- **Motivo:** §51 (teclado, mando y táctil sin código específico por plataforma). El bloqueo alternado podía desincronizarse entre cliente y servidor si se perdía un intent.

## D-020 — Manifiesto de assets y registro de animaciones; registro de habilidades en M2
- **Fecha:** 2026-09-29
- **Estado:** ACCEPTED
- **Decisión:** `Content/Assets` es el manifiesto de §54 y la única fuente de IDs de Roblox, con convención de nombres `<PREFIJO>_<Grupo>_<Nombre>` validada por tests. `Content/Animations` asocia claves de juego a assets, prioridad y markers estándar de §53; `AssetRegistry` y `AnimationRegistry` dan acceso a ambos. Los combos referencian animaciones por clave y sus `MarkerName` deben existir en la animación.
- **Registro de habilidades:** §70 lo incluye en CORE FOUNDATION, pero se implementará con el framework de habilidades (M2): definir `AbilityDefinition` antes de diseñar ese framework sería especulativo y probablemente se reharía. Los combos actuales ya son definiciones de datos validadas.
- **Motivo:** que ningún sistema escriba IDs a mano, que el equipo de arte tenga un flujo de estados trazable y que los errores de referencias se detecten en CI, no en una prueba en Studio.

## D-021 — Estado de los personajes replicado por atributos del modelo
- **Fecha:** 2026-09-30
- **Estado:** ACCEPTED
- **Decisión:** `CharacterReplicator` escribe en el modelo de cada personaje, como atributos, lo que la UI y las animaciones necesitan: `Level`, `Race`, `Posture`, `MaxPosture`, `ActionState`, `Resource_<Id>` y `ResourceMax_<Id>`. `CombatService` añade `ActionId` (combo en curso) **antes** de pasar a `Attacking`. Los nombres están en `Shared/Network/ReplicatedAttributes`. La vida sigue replicando por el `Humanoid`. Los clientes solo leen.
- **Alternativas:** un remote propio con snapshots/deltas (más código y más superficie de red para datos que no son secretos) o `ValueObject`s (más instancias y el mismo resultado).
- **Motivo:** los atributos replican solos, llegan a todos los clientes (co-op: cada uno ve la postura y el estado de los demás) y no abren ningún canal cliente→servidor. Estos datos son visibles en el juego, así que no hay nada privado que proteger. Cuando haya NPCs, basta con llamar también a `CharacterReplicator.Bind`.

## D-022 — UI y animaciones provisionales propias
- **Fecha:** 2026-09-30
- **Estado:** ACCEPTED (provisional hasta que Arte/Animación entregue los assets finales)
- **Decisión:**
  - **UI** (`Client/UI`, `docs/UI.md`): HUD propio (vida, postura, recursos, nivel/raza, estado de acción), placas sobre los demás jugadores, destello y números de daño, y pantalla de muerte con cuenta atrás. Sustituyen la barra de vida y el nombre por defecto de Roblox. Todo el estilo sale de `UI/Theme`.
  - **Locomoción:** el pack **Ninja** del catálogo de Roblox (creador Roblox, uso libre), registrado en el manifiesto como `ANIM_Locomotion_*` y aplicado sobre el script `Animate` por defecto. Solo R15.
  - **Acciones** (tajo, guardia, dash, aturdimiento): animaciones **procedurales** en el cliente (`Client/Animation`) que giran los `Motor6D.C0` según el `ActionState` replicado (D-021). Usan las mismas claves que `Content/Animations`: en cuanto un asset tenga `AssetId`, se usa el asset y el placeholder deja de usarse, sin tocar código. Un test obliga a que toda animación de acción tenga asset o placeholder.
- **Alternativas:** subir animaciones hechas a mano (necesitan el editor de animación y una cuenta con permisos; es trabajo de Animación/Visual, §55) o `KeyframeSequenceProvider:RegisterKeyframeSequence` (solo sirve para pruebas en Studio).
- **Limitaciones:** las animaciones de acción empiezan cuando llega el estado del servidor, así que el ataque propio se ve con la latencia de ida y vuelta. Los placeholders solo funcionan en R15. Se aceptan porque son provisionales.
- **Motivo:** el Lead Programmer pidió ver ya una UI y unas animaciones distintas a las de Roblox, sin esperar a los assets finales y sin atar los sistemas a nada provisional.

## D-023 — Pautas de diseño tomadas de la guía de PromptBlox
- **Fecha:** 2026-09-30
- **Estado:** ACCEPTED
- **Fuente:** https://promptblox.ai/roblox-rpg-maker (guía de creación de RPG en Roblox).
- **Qué se adopta** (ya coincide con §62–63 de la constitución; se añade como criterio de diseño en `docs/GDD.md`):
  - Alcance del primer build: **una zona, una misión, una mazmorra corta**, y ampliar después.
  - Números pequeños al principio; progresión rápida en los primeros niveles para que el jugador note que avanza.
  - Botín raro de verdad y distinguible a simple vista.
  - Siempre un marcador o seguimiento de la misión activa (el HUD de §52 ya incluye quest tracker).
  - Ataques de jefe con **aviso visible** (círculos o zonas de peligro) para que el jugador pueda aprender el combate.
  - Probar el bucle completo con un personaje **nuevo de nivel 1**, incluida la derrota y el modo multijugador; arreglar un sistema cada vez.
- **Qué no se adopta:** la generación de código con su herramienta. El proyecto tiene su propia arquitectura y su propio flujo de trabajo (constitución).

## D-024 — Revisión de D-017: tres capas de estado centralizadas en Character
- **Fecha:** 2026-09-30
- **Estado:** ACCEPTED (revisión de D-017 pedida por el Lead Programmer antes de M2)
- **Revisión:** §15 pide dos cosas: un sistema de estados **centralizado** con al menos 16 estados, y que las habilidades declaren desde qué estados pueden empezar. D-017 acertaba al separar acción, locomoción y forma: si `Running` o `Transformed` fueran estados exclusivos, cada acción habría que duplicarla (atacar corriendo, bloquear transformado…). Pero dejaba la locomoción y la forma para "algún servicio" futuro, con lo que el sistema ya no sería centralizado.
- **Decisión:** `Character` guarda las tres capas y es el único sitio donde se consultan:

  | Capa | Valores | Quién la cambia |
  |---|---|---|
  | Acción (máquina de estados) | `Idle`, `Attacking`, `Blocking`, `Parrying`, `Dodging`, `Dashing`, `Casting`, `Transforming`, `Stunned`, `Knocked`, `Ragdolled`, `Disabled`, `Dead` | Servicios de combate y habilidades |
  | Locomoción | `Stationary`, `Moving` (lento), `Running`, `Sprinting` | `MovementService` según el movimiento real |
  | Forma | id de transformación o `nil` (= `Transformed` o no) | Framework de transformaciones (futuro) |

  - `Character:IsInState(nombre)` responde a cualquiera de los 16 estados de §15 (+ `Dashing`, + `Stationary`). `Idle` es el de acción; "parado" es `Stationary`.
  - Las habilidades declaran `StateRequirements`: `StartStates` (obligatorio) y, opcionalmente, `Locomotion` y `Transformed`. `Character:MeetsRequirements` los comprueba.
  - Las tres capas se replican como atributos (`ActionState`, `Locomotion`, `Form`; D-021).
- **Motivo:** cumple §15 al completo sin duplicar acciones por modo de movimiento o forma.

## D-025 — Framework de habilidades y servicios de combate compartidos
- **Fecha:** 2026-09-30
- **Estado:** ACCEPTED
- **Decisión:**
  - **Toda acción de combate es una `AbilityDefinition`** (`Shared/Types/AbilityTypes`, contenido en `Server/Content/Abilities`): estado de acción, `StateRequirements` (§15), duración, cooldown, coste, golpes (`AbilityHit` con marker, daño, postura, hitbox, rompe-guardia, empuje), i-frames, movimiento y animación. `AbilityService` las ejecuta todas por el mismo camino. Los combos de M1 y `CombatActions` desaparecen: son habilidades.
  - **El cliente pide acciones, no habilidades:** `CombatIntent = { Action, Active? }`. El servidor elige la habilidad con el **moveset** (`Server/Content/Movesets`); `LightAttack` es una cadena (`ComboChain`) que avanza si se pulsa dentro de `ComboWindowSeconds` tras el golpe anterior. Un cliente no puede pedir una habilidad que no tiene.
  - **Servicios de §13/§17 sin dependencias circulares:** `CombatRegistry` guarda las entidades de combate (personaje, humanoid, tareas, guardia, acción en curso, gastos, sprint) y es lo único que comparten `CombatService` (intents y guardia), `AbilityService`, `DamageService`, `HitboxService`, `ResourceService` y `MovementService`. Las piezas con lógica pura (`DamageResolver`, `Cooldowns`, `ComboChain`, `TaskScheduler`) tienen tests.
  - **Replicación de la habilidad:** `ActionAnimation` + `ActionSeq` (contador) en el modelo, escritos antes de la transición. El contador hace que dos habilidades seguidas del mismo estado (tajo 1 → tajo 2) se distingan. Sustituyen a `ActionId`.
  - **Reglas nuevas (§16):** hitstun breve en golpes limpios, empuje, guardia rota, i-frames, esquiva que cancela ataques y bloqueos, y aturdimientos que solo se alargan. **PvE:** solo hay daño entre jugadores y NPCs (`CombatRegistry.AreHostile`).
  - `StatusEffectService`, `AnimationService`, `VFXService` y `SFXService` de §17 no se crean todavía: el único efecto de estado es el aturdimiento (en `DamageService`) y las animaciones ya tienen su sistema (D-022). Se crearán cuando haya un segundo caso real (§66).
- **Motivo:** §17 (una habilidad nueva solo necesita definición, animación, VFX, SFX y balance) y §15 (requisitos de estado declarados por la habilidad).

## D-026 — Framework de movimiento: el servidor decide, el cliente desplaza
- **Fecha:** 2026-09-30
- **Estado:** ACCEPTED
- **Decisión:**
  - Los desplazamientos de las habilidades (`MovementSpec`: distancia, duración, dirección, si vale en el aire) son datos de la habilidad (§18): Shunpo, Sonido o Hirenkyaku serán definiciones distintas del mismo motor.
  - El servidor valida y cobra; si acepta, la respuesta de `CombatIntent` lleva el `MovementSpec` y **el cliente aplica el impulso** (`VelocityImpulse`, un `LinearVelocity` temporal). El cliente es dueño de la física de su personaje en Roblox; aplicarlo en el servidor añadiría una ida y vuelta de latencia sin impedir nada a un exploit.
  - `MovementService` (servidor) decide la `WalkSpeed` según el estado (normal, sprint, lento al atacar/bloquear, casi quieto aturdido), gasta stamina al correr (con un mínimo para empezar, para que no sea entrecortado) y actualiza la capa de locomoción (D-024).
  - El empuje de los golpes lo aplica el servidor con el mismo `VelocityImpulse`: la restricción replica al dueño de la física.
  - Se desactiva el shift-lock de Roblox (`EnableMouseLockOption = false`) porque Shift es sprint; la cámara de combate llega en M3.
- **Riesgo aceptado:** falta validar el desplazamiento real contra speed-hacks y teletransportes (`SECURITY.md`). Pendiente antes de abrir el juego.

## D-027 — Muñecos de entrenamiento
- **Fecha:** 2026-09-30
- **Estado:** ACCEPTED
- **Decisión:** `TrainingService` crea tres NPCs (`Server/Content/TrainingDummies`): pasivo, atacante y en guardia. Usan **el mismo** `Character`, `CombatService` y habilidades que un jugador (sin atajos), llevan la etiqueta `CombatNPC` y el atributo `DisplayName`, y reaparecen al morir. El atacante avisa con el atributo `Telegraph` (contorno rojo en el cliente) 0,6 s antes de golpear, aplicando la pauta de D-023. La física de los NPCs es del servidor.
- **Motivo:** §63 pide un dummy de entrenamiento en M2, y permite probar todo el combate (parry, esquiva, guardia rota) sin un segundo jugador. Además, es la primera prueba de que el sistema sirve igual para NPCs, antes de los enemigos de M3.

## D-028 — Experiencia y nivel dirigidos por datos
- **Fecha:** 2026-09-30
- **Estado:** ACCEPTED
- **Decisión:** la curva está en `Shared/Config/ProgressionConfig` (EXP para pasar del nivel N = `floor(60 · N^1.5)`, nivel máximo 100, +4 de vida máxima por nivel) y `Shared/Modules/Progression` hace los cálculos (puro, con tests). Ningún valor por nivel está escrito a mano (§14). `ProgressionService` guarda nivel y EXP en el perfil (que ya replica al dueño) y, al subir de nivel, actualiza el personaje vivo (`Character:SetLevel`, `SetMaxHealth` con la vida al máximo).
- **Motivo:** §14 y §44. El nivel aporta poco poder por sí solo (§44: "Level alone must not determine all power"); el resto vendrá de estadísticas, maestrías y habilidades. Primeros niveles rápidos (D-023).

## D-029 — Framework de enemigos e IA
- **Fecha:** 2026-09-30
- **Estado:** ACCEPTED
- **Decisión:**
  - Cada enemigo es una `EnemyDefinition` (`Server/Content/Enemies`): estadísticas, aspecto, velocidad, aggro (detección, pérdida, correa), ataques (habilidad, alcance, aviso previo), intervalo y EXP. Las zonas de aparición son datos (`EnemySpawns`).
  - `NpcFactory` y `NpcActions` construyen y hacen atacar a cualquier NPC (§41: ningún script por NPC); muñecos y enemigos los comparten.
  - `EnemyBrain` (puro, con tests) decide en cada tick: perseguir, atacar, esperar a distancia de ataque, volver a casa si se aleja demasiado (y curarse) u ocupado. `EnemyService` ejecuta la decisión con un único bucle de 0,2 s para todos (§58).
  - Todo ataque enemigo se avisa con el contorno rojo (D-023). Los NPCs usan las mismas habilidades y reglas de daño que los jugadores; su desplazamiento (embestida) lo aplica el servidor, que es dueño de su física.
  - Quien daña a un enemigo pasa a ser su objetivo si no tenía, y participa en la recompensa: **EXP completa para todos los que le hicieron daño** (co-op sin robos de kill). Se anota antes de aplicar el daño (`DamageService.HitLanded`), así el golpe final cuenta.
  - Movimiento en línea recta (`Humanoid:MoveTo`); pathfinding cuando haya mapas con obstáculos. **Drops** (§42): cuando exista el inventario.
- **Motivo:** §42 (definiciones reutilizables), §41 y §58.

## D-030 — Sistema de misiones y perfil v2
- **Fecha:** 2026-09-30
- **Estado:** ACCEPTED
- **Decisión:** `QuestDefinition` (`Shared/Content/Quests`, compartido para que el cliente muestre títulos y objetivos): tipo de §40, objetivos, recompensas y misión siguiente. Por ahora solo hay objetivos `Kill`; el resto de tipos añadirán los suyos cuando se usen (§66). `QuestLogic` (puro, con tests) avanza y completa; `QuestService` empieza la primera misión, reparte recompensas y encadena. El perfil pasa a **v2** con `Quests = { Active, Completed }` y su migración desde v1 (probada). La primera cadena son tres misiones de caza (D-023: una zona, una misión, un reto final).
- **Motivo:** §40 y §63 (misión en la vertical slice).

## D-031 — HUD de M3
- **Fecha:** 2026-09-30
- **Estado:** ACCEPTED (provisional, como D-022)
- **Decisión:** barra de EXP; avisos arriba al centro (EXP ganada, nivel, misión nueva o completada) deducidos de los cambios del perfil, sin remotes nuevos; seguimiento de misión a la derecha con marcador y distancia en el mundo; barra de acciones con cooldowns (la respuesta de `CombatIntent` incluye el cooldown) y la tecla o botón según el mando, oculta en táctil; panel del objetivo fijado.
- **Motivo:** §52 (EXP, habilidades, cooldowns, quest tracker, información del objetivo).

## D-032 — Fijado de objetivo y cámara de combate
- **Fecha:** 2026-09-30
- **Estado:** ACCEPTED
- **Decisión:** `LockOnController` (cliente). Pulsar T / R3 / "Fijar" fija el enemigo más centrado en pantalla o pasa al siguiente; mantener lo suelta; se suelta solo si el objetivo muere o se aleja. Con objetivo, el personaje lo encara y una cámara suavizada, que se ejecuta justo después de la de Roblox, encuadra a ambos. Sin objetivo, la cámara es la de Roblox (§50: el juego se juega igual sin fijar).
- **Pendiente:** sensibilidad configurable, cámara consciente de habilidades y jefes (§50), y evitar que la cámara atraviese paredes cuando haya mapa.

## D-033 — Integración de arte desde Studio, sin código
- **Fecha:** 2026-09-30
- **Estado:** ACCEPTED
- **Decisión:** Rojo crea `ReplicatedStorage.Assets` (`Animations`, `Models`, `VFX`, `Sounds`) con `$ignoreUnknownInstances`, así que no borra lo que se añada en Studio. `AssetLibrary` resuelve cada asset por su nombre del manifiesto: primero el `AssetId` del manifiesto y, si no lo tiene, el objeto colocado en Studio (`Animation.AnimationId`, `Sound.SoundId`, o una copia del modelo o efecto). Si no hay ninguno, se usa el placeholder. `AssetAuditService` (solo en Studio) informa en Output de lo que está, lo que falta y los nombres o carpetas incorrectos. Guía en `docs/GUIA_EQUIPO.md`.
- **Alternativas:** guardar los modelos como `.rbxm` en el repositorio (obliga a Arte a usar git) o que Programación copie cada ID al manifiesto (cuello de botella).
- **Motivo:** §55 (Arte y Animación trabajan en Studio; el código va por el repo). El equipo ya está modelando y animando: con esto integran su trabajo sin depender de Programación, y el manifiesto sigue siendo la lista de lo que hace falta.

## D-034 — Razas elegibles con kit, armas y técnicas
- **Fecha:** 2026-09-30
- **Estado:** ACCEPTED
- **Decisión:** cada `RaceDefinition` tiene `Description` y un `Kit` (moveset, arma y objetos iniciales). Un personaje nuevo elige raza una sola vez (`ChooseRace`, validado en el servidor: existe, `Playable` y aún no ha elegido) y reaparece con su kit. Abrir Hollow y Quincy (M5) es completar su kit y poner `Playable = true`. `Movesets` pasa a `Shared` (el cliente muestra las técnicas) y gana `Skills` (Ability1-4). El moveset se elige por la raza del personaje. `WeaponService` pone en la mano el arma del kit (modelo de Arte con `Handle` o hoja provisional). Los golpes admiten `Stun` (ataduras) y `Unblockable`. Shinigami: espada, Shunpo, Byakurai (rayo) y Sai (atadura). Quien no ha elegido tiene `Step`, un paso corto que usa el mismo motor que Shunpo (§28).
- **Motivo:** §21, §22, §26, §28 y §63 (kit inicial de la vertical slice).

## D-035 — Efectos visuales por datos
- **Fecha:** 2026-09-30
- **Estado:** ACCEPTED
- **Decisión:** `Content/Effects` define cada efecto con una versión provisional (`Beam`, `Burst`, `Ring`) y su asset `VFX_`. `Content/AbilityInfo` da a cada habilidad su nombre, descripción y efectos con retardo. El servidor replica `ActionId`; `VfxController` y `EffectPlayer` los reproducen en todos los clientes. Si Arte ha colocado el efecto, se usa el suyo. El aviso de área de los enemigos es otro efecto (`Telegraph.Area`), con el radio y la duración que publica el servidor.
- **Motivo:** §17 (VFXService): una habilidad nueva solo necesita datos y su efecto.

## D-036 — Inventario, objetos y botín
- **Fecha:** 2026-09-30
- **Estado:** ACCEPTED
- **Decisión:** `ItemDefinition` (categorías de §46, rareza, pila máxima, icono opcional y efecto de uso) en `Content/Items`; rarezas y casillas en `ItemConfig`. `InventoryLogic` (puro, con tests) añade respetando pilas y casillas, quita y cuenta. `InventoryService` da objetos y atiende `UseItem`, validando que el objeto exista, que se tenga, el cooldown y que tenga efecto. Botín por enemigo (`Drops`, `DropLogic` puro): **cada participante tira el suyo** (co-op sin robos). La mochila (B o botón en pantalla) muestra el color de rareza (D-023). Los avisos de objetos conseguidos se deducen del perfil.
- **Mando:** no quedan botones libres; la mochila se abre con su botón en pantalla y la navegación de UI de Roblox (`GamepadUsesMenuButton`).
- **Táctil:** las casillas de la barra de acciones se pueden pulsar (`InputController:Trigger`). Pesado, esquiva, dash y técnicas se lanzan desde ahí, y los botones de pantalla quedan para atacar, bloquear y fijar.

## D-037 — Jefes como enemigos con fases
- **Fecha:** 2026-09-30
- **Estado:** ACCEPTED
- **Decisión:** no hay un sistema de jefes aparte. Cualquier `EnemyDefinition` puede tener `Phases`, que cambian ataques, ritmo y velocidad al bajar de un umbral de vida; `EnemyBrain.PhaseIndex`/`PhaseSettings` son puros. Un enemigo con `Tier = "Boss"` se marca `IsBoss` y tiene barra propia, con aviso de fase. Los ataques en área declaran `AreaRadius`, que se dibuja en el suelo durante el aviso; un test comprueba que coincide con la hitbox real. Primer jefe: Gran Hollow (3 fases). Contraataques: rotura de postura, parry y salir del círculo (§43: la dificultad no es solo mucha vida). Participación: EXP, botín y misión para todos los que le hicieron daño.
- **Además:** al cargar el perfil se retoman las cadenas de misiones con una misión siguiente nueva, así el contenido añadido llega a los jugadores existentes.

## D-038 — Efectos de golpe sobre el atacante: robo de vida y remate
- **Fecha:** 2026-09-30
- **Estado:** ACCEPTED
- **Decisión:** `AbilityHit` admite `Drain` (fracción del daño hecho que recupera el atacante), `Execute` (`HealthFraction` + `MaxDamage`: un golpe limpio derrota al objetivo si le queda poca vida, pero nunca a uno con más vida que `MaxDamage`, así que los jefes no se rematan) y `KillStat` (estadística que suma 1 si el golpe derrota al objetivo). `DamageResolver` sigue siendo puro y decide el remate; `DamageService` aplica el robo de vida y emite `Killed(atacante, defensor, golpe)`. Devorar (Hollow) es solo datos: mordisco que ignora la guardia, cura lo que hace y remata.
- **Motivo:** §29 (devorar) sin código específico de raza; el remate solo entra con golpe limpio (bloquear o esquivar lo evita).

## D-039 — Estadísticas e hitos de raza; perfil v3
- **Fecha:** 2026-09-30
- **Estado:** ACCEPTED
- **Decisión:** cada raza tiene `Milestones` en orden: nivel mínimo + estadísticas mínimas (`Content/Stats`) → técnicas que se añaden a la barra detrás de las del moveset (máximo 4). `MilestoneService` suma las estadísticas con `DamageService.Killed` (solo enemigos reales, no muñecos) y evalúa los hitos al sumar, al subir de nivel (`ProgressionService.LeveledUp`) y al cargar el perfil. Un hito alcanzado se guarda para siempre. `KitLogic` (puro y compartido, con tests) calcula las técnicas y los hitos: el servidor decide con él y el cliente muestra la misma barra. Perfil v3: `Stats` y `Milestones`, con migración desde v2.
- **Prototipos:** Hollow — "Hambre insaciable" (nivel 2 + 3 almas devoradas → Bala) y "Gillian" (nivel 5 + 12 → Hierro). Quincy — "Blut Arterie" (nivel 3 + 15 bajas con flechas).
- **Motivo:** §29 ("la evolución no debe ser mata X y evoluciona": pide nivel y una acción concreta), §31 y la definición de hecho de las transformaciones (desbloqueo de habilidades). El descubrimiento de la Zanpakuto (M6) usará los mismos hitos.

## D-040 — Modificadores temporales (potenciadores)
- **Fecha:** 2026-09-30
- **Estado:** ACCEPTED
- **Decisión:** una habilidad puede aplicar `SelfModifier` (`Id`, `Duration`, `DamageTaken`, `DamageDealt`). Se guardan en la entidad de combate (`Modifiers`, puro, con tests); el mismo `Id` se renueva en lugar de acumularse. `DamageService` multiplica el daño por el daño hecho del atacante y el daño recibido del defensor antes de resolver. Se ven con el efecto `Aura` (contorno de color, o el aura de Arte soldada al personaje) con la misma duración; un test lo comprueba. Hierro, Blut Vene y Blut Arterie son solo datos.
- **Alternativas:** un sistema de estados alterados completo (veneno, ralentizar…): demasiado para la vertical slice (§66). Este modelo se puede ampliar con más campos.

## D-041 — Reishi ambiental por zonas
- **Fecha:** 2026-09-30
- **Estado:** ACCEPTED
- **Decisión:** un recurso con `AmbientScaling` multiplica su regeneración por la densidad de la zona en la que está el personaje (`Server/Content/AmbientZones`: centro, radio horizontal y densidad; fuera de toda zona, `DefaultDensity`; si se solapan, gana la más densa). `AmbientDensity` es puro, con tests. `ResourceService` replica al jugador la zona y su densidad, y el cliente avisa al entrar y salir si su raza depende de ello. Zonas de prueba: coto de caza ×1,5 y guarida del jefe ×2.
- **Motivo:** §32 (`AmbientReishiDensity` configurable por zona). Premia al Quincy por luchar donde hay más enemigos.

## D-042 — Kits de Hollow y Quincy (M5)
- **Fecha:** 2026-09-30
- **Estado:** ACCEPTED
- **Decisión:** ambas razas pasan a `Playable`, sin código específico de raza. **Hollow:** garras (cadena de 3 y desgarro que rompe la guardia), Devorar, Cero (carga de 0,8 s), Sonido, máscara en la cabeza; Reiatsu. **Quincy:** arco en la mano izquierda, cadena de 3 flechas de Heilig Pfeil a distancia, flecha cargada que rompe la guardia, Licht Regen (área por delante), Blut Vene, Hirenkyaku; usa **Reishi** en lugar de Reiatsu. `WeaponDefinition` gana `AttachTo` (parte del cuerpo) para piezas que no van en la mano derecha.
- **Motivo:** §63 (kits de la vertical slice) reutilizando los frameworks de habilidades, movimiento y efectos (§28, §31).
- **Pendiente:** las flechas son instantáneas (sin proyectil físico); Pesquisa, Garganta, Gintō y la evolución más allá de Gillian quedan para después.

## D-043 — Mapa principal generado por datos (Karakura)
- **Fecha:** 2026-10-01
- **Estado:** ACCEPTED
- **Decisión:** el mapa se describe con datos puros en `src/Shared/Content/Maps/<Mapa>.luau`.
  - **Qué contiene:** límite del pueblo, ríos, costa, vía, calles, distritos (estilo y cuadrícula), lugares singulares, parques, colinas, galería subterránea y puntos con nombre (`Anchors`).
  - **Coordenadas:** se copian en píxeles del mapa de referencia (`docs/references/karakura_map.png`) con `px(x, y)`.
  - **Generación:** un generador en Lune (`lune run tools/worldgen`) construye el modelo y lo guarda en `world/<Mapa>.rbxm`, que se importa en Studio como `Workspace.Map` (ver la enmienda de abajo). También deja una vista cenital `world/<Mapa>_preview.png`.
  - **Relleno:** callejuelas, parcelas, casas, pisos, tiendas, tiendas 24 h, oficinas, postes con cables, farolas, semáforos, máquinas, coches y huertos. Se decide con una semilla fija: los mismos datos dan el mismo mapa.
  - **Uso en el juego:** enemigos, muñecos, zonas y marcadores de misión se colocan con `WorldMap.Anchor(nombre)`, sin copiar coordenadas. El mapa activo se elige en `Content/World`.
  - **Contrato con el cliente:** las etiquetas y atributos que comparten generador y cliente están en `Shared/Config/WorldTags`.
- **Enmienda (2026-10-01): el mapa no se sincroniza con Rojo.**
  - **Problema:** con `rojo serve` el mapa no aparecía en Studio. Son unas 27 600 instancias y unos 17 MB de datos, demasiado para la sincronización en vivo.
  - **Solución:** el mapa se importa a mano. Se arrastra `world/<Mapa>.rbxm` a `Workspace` y se guarda con el lugar.
  - **Rojo:** `Workspace` lleva `$ignoreUnknownInstances` para no borrar el mapa importado.
  - **Aviso:** si falta `Workspace.Map`, `EnvironmentService` lo indica en Output.
- **Arte en Studio:** `Workspace.MapDetails` es una carpeta que ni Rojo ni el generador tocan. El equipo puede añadir ahí detalles a mano, y regenerar el mapa no los borra.
- **Rendimiento (móvil):**
  - Las piezas decorativas no chocan, no proyectan sombra y no las encuentran raycasts ni hitboxes.
  - `StreamingEnabled` activado (radio objetivo 768).
  - Los NPCs y los personajes son modelos atómicos.
- **Alternativas:** construirlo a mano en Studio (lento y difícil de cambiar en equipo) o generarlo al arrancar el servidor (no se vería en modo edición y retrasaría el arranque).
- **Validación:**
  - `MapIntegrity.spec` comprueba que los puntos del juego caen dentro del pueblo, fuera de ríos y calles, y que los lugares no se pisan.
  - El generador falla si encuentra avisos.
  - El test de frontera de IP también revisa `tools/`.

## D-044 — Ciclo de día y noche y ambiente de la ciudad
- **Fecha:** 2026-10-01
- **Estado:** ACCEPTED
- **Decisión:**
  - **Servidor:** `EnvironmentService` avanza `Lighting.ClockTime` (18 min de día y 8 de noche, `EnvironmentConfig`). Es lo único que se replica.
  - **Iluminación:** cada cliente (`EnvironmentController`) interpola entre preajustes por hora (ambiente, atmósfera, corrección de color, bloom). Se usa iluminación `Future`.
  - **Ciudad de noche:** se encienden ventanas con `Lit`, farolas, letreros y luces.
  - **Animaciones:** semáforos, relojes con la hora del juego, la luz que parpadea en las ruinas y las balizas de las azoteas.
  - **Tren:** `TrainController` mueve un tren de cuatro vagones por la vía. Su horario sale de la hora del servidor, así que todos lo ven igual sin tráfico de red. Para en la estación, y en los pasos a nivel se encienden las luces y bajan las barreras.
  - **Agua:** la del generador se cambia por agua de Terrain al arrancar.
  - **Tests:** `DayCycle` y `PathLogic` son puros y tienen tests.
- **Motivo:** ambientación pedida para el mapa principal, sin coste de red y escalable: cualquier pieza nueva con la etiqueta correcta se anima sola.

