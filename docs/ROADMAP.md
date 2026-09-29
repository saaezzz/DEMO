# Roadmap

Orden de trabajo según la constitución (§6, §70). Prioridades: P0 = core, P1 = vertical slice.

## M0 — Higiene y toolchain (HECHO)
- [x] Toolchain Rokit + selene + stylua + luau-lsp + lune.
- [x] Constitución, DECISIONS.md y CHANGELOG.md en el repo.
- [x] Bugs críticos de combate: aturdimiento permanente, golpes tras parry, fuga de tareas, recursos sin regeneración.
- [x] Validación de payload y rate limit en `CombatIntent`; anti-spam de parry.
- [x] Revisión completa: 0 errores de tipo, 0 avisos de lint, ciclo de vida de personajes corregido.

## M1 — Core Foundation (P0)
- [x] Loader de servicios (`Init`/`Start`), `Logger`, `Signal`.
- [x] Capa `Networking` con validación de esquema y rate limit.
- [x] Separar IP del núcleo; estados de personaje de §15 (adaptados, D-017); recursos genéricos.
- [ ] DataService v1 con ProfileStore, `DataVersion`, migraciones y replicación privada.
- [x] Test runner (Lune), tests de la lógica pura y CI.
- [ ] `InputService` (KBM, gamepad, táctil).
- [ ] Registros: habilidades, animaciones, assets.

## M2 — Combat Foundation (P0/P1)
- Framework de habilidades, Hitbox/Damage/Cooldown/Resource, dodge, heavy, stamina, dummy de entrenamiento, framework de movimiento.

## M3 — Loop PvE mínimo (P1)
- Enemigos + IA básica, EXP/nivel data-driven, muerte/respawn, HUD, cámara + lock-on.

## M4 — Vertical Slice 0.1: Shinigami (P1)
## M5 — Vertical Slice 0.2: Hollow + Quincy (P1)
## M6 — Descubrimiento de Zanpakuto, pulido y playtests (P1)

## Histórico
- Prototipo inicial: `GameTypes`, `StateMachine`, `Character`, `CombatService`, `HitboxUtil`, `CombatController` y un borrador de `DataService` (retirado, D-012).
