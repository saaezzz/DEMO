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
