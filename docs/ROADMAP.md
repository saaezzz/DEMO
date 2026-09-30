# Roadmap

Orden de trabajo según la constitución (§6, §70). Prioridades: P0 = core, P1 = vertical slice.

## M0 — Higiene y toolchain (HECHO)
- [x] Toolchain Rokit + selene + stylua + luau-lsp + lune.
- [x] Constitución, DECISIONS.md y CHANGELOG.md en el repo.
- [x] Bugs críticos de combate: aturdimiento permanente, golpes tras parry, fuga de tareas, recursos sin regeneración.
- [x] Validación de payload y rate limit en `CombatIntent`; anti-spam de parry.
- [x] Revisión completa: 0 errores de tipo, 0 avisos de lint, ciclo de vida de personajes corregido.

## M1 — Core Foundation (P0) — HECHO (pendiente de verificación en Studio)
- [x] Loader de servicios (`Init`/`Start`), `Logger`, `Signal`.
- [x] Capa `Networking` con validación de esquema y rate limit.
- [x] Separar IP del núcleo; estados de personaje de §15 (adaptados, D-017); recursos genéricos.
- [x] DataService v1 con ProfileStore, `DataVersion`, migraciones y replicación privada.
- [x] Test runner (Lune), tests de la lógica pura y CI.
- [x] `InputController` (KBM, gamepad, táctil).
- [x] Registros de animaciones y assets (D-020).
- [ ] Registro de habilidades → se hace con el framework de habilidades en M2 (D-020).
- [x] UI y animaciones provisionales propias (D-022), adelantadas del HUD de M3 a petición del Lead Programmer.

## M2 — Combat Foundation (P0/P1) — HECHO (pendiente de verificación en Studio)
- [x] Revisión de D-017: capas de estado centralizadas (D-024).
- [x] Framework y registro de habilidades; cadena M1, ataque pesado, esquiva, dash (D-025).
- [x] Servicios compartidos: hitbox, daño, cooldowns, recursos (stamina), movimiento (D-025, D-026).
- [x] Muñecos de entrenamiento (D-027).
- [ ] Validación anti speed-hack del movimiento (antes de abrir el juego; `SECURITY.md`).

## M3 — Loop PvE mínimo (P1)
- Enemigos + IA básica (con avisos visibles en ataques fuertes, D-023), EXP/nivel data-driven, HUD completo (EXP, cooldowns, quest tracker, objetivo), cámara + lock-on.

## M4 — Vertical Slice 0.1: Shinigami (P1)
## M5 — Vertical Slice 0.2: Hollow + Quincy (P1)
## M6 — Descubrimiento de Zanpakuto, pulido y playtests (P1)

## Histórico
- Prototipo inicial: `GameTypes`, `StateMachine`, `Character`, `CombatService`, `HitboxUtil`, `CombatController` y un borrador de `DataService` (retirado, D-012).
