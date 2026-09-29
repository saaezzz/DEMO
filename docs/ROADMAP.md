# Roadmap

Orden de trabajo según la constitución (§6, §70). Prioridades: P0 = core, P1 = vertical slice.

## M0 — Higiene y toolchain (EN CURSO)
- [x] Toolchain Rokit + selene + stylua + luau-lsp + lune.
- [x] Constitución, DECISIONS.md y CHANGELOG.md en el repo.
- [x] Bugs críticos de combate: aturdimiento permanente, golpes tras parry, fuga de tareas, recursos sin regeneración.
- [x] Validación de payload y rate limit en `CombatIntent`; anti-spam de parry.

## M1 — Core Foundation (P0)
- [ ] Loader de servicios (`Init`/`Start`), `Logger`, `Signal`.
- [ ] Capa `Networking` con validación de esquema y rate limit.
- [ ] Separar IP del núcleo; estados de personaje de §15; recursos genéricos.
- [ ] DataService v1 con ProfileStore, `DataVersion`, migraciones y replicación privada.
- [ ] Test runner (Lune) y tests de la lógica pura.
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
- Prototipo inicial: `GameTypes`, `StateMachine`, `Character`, `CombatService`, `HitboxUtil`, `CombatController`, borrador de `DataService`.
