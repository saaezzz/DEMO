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
- **Estado:** ACCEPTED (pendiente de implementar, tarea 8)
- **Decisión:** Sustituir ProfileService por [ProfileStore](https://github.com/MadStudioRoblox/ProfileStore) (sucesor del mismo autor).
- **Motivo:** ProfileService ya no recibe desarrollo activo. Todavía no existen datos guardados, así que la migración no tiene coste de datos.
- **Requisitos asociados:** `DataVersion` + migraciones (§59) desde la primera versión del esquema.

## D-005 — Replicación de datos propia y mínima
- **Fecha:** 2026-09-29
- **Estado:** ACCEPTED (pendiente de implementar, tarea 8)
- **Decisión:** No usar ReplicaService. Replicar al cliente solo sus propios datos mediante la capa de red del proyecto (snapshot inicial + deltas por ruta). Los datos públicos necesarios para otros jugadores (nivel, raza visible) se replicarán explícitamente, nunca por defecto.
- **Alternativas:** ReplicaService (sin mantenimiento activo) o su sucesor `Replica`.
- **Motivo:** Menos dependencias externas para un equipo pequeño, control total sobre qué se filtra (el `Replication = "All"` anterior exponía inventario y moneda de todos los jugadores).

## D-006 — Tests con Lune para la lógica pura
- **Fecha:** 2026-09-29
- **Estado:** ACCEPTED (pendiente de implementar, tarea 9)
- **Decisión:** Los tests de lógica pura (máquinas de estado, recursos, cooldowns, validadores, migraciones, fórmulas) se ejecutan con [Lune](https://github.com/lune-org/lune) fuera de Studio, para poder correr en CI. Los módulos de lógica deben evitar dependencias de `game`/`Instance` para ser testeables (p. ej. un `Signal` en Luau puro en vez de `BindableEvent`). Las pruebas de integración que requieran el motor se hacen en Studio.
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
