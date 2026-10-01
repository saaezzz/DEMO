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

## M3 — Loop PvE mínimo (P1) — HECHO (pendiente de verificación en Studio)
- [x] Enemigos con IA y avisos visibles en todos sus ataques (D-029).
- [x] EXP y nivel dirigidos por datos (D-028).
- [x] Misiones con seguimiento y marcador; perfil v2 (D-030).
- [x] HUD: EXP, avisos, cooldowns, misión, objetivo (D-031).
- [x] Cámara de combate y fijado de objetivo (D-032).
- [x] Jefe con fases (§43), drops e inventario (§46) → hechos en M4.

## M4 — Vertical Slice 0.1: Shinigami (P1) — HECHO y probado en Studio
- [x] Integración de arte desde Studio sin código y guía del equipo (D-033).
- [x] Elección de raza y kit Shinigami: espada, Shunpo, Byakurai, Sai (D-034).
- [x] Efectos visuales por datos (D-035).
- [x] Inventario, objetos, botín y consumibles (D-036).
- [x] Jefe con fases (D-037).
- [ ] Descubrimiento de Zanpakuto → M6 (roadmap original).
- [ ] Validación anti speed-hack (pendiente desde M2).

## M5 — Vertical Slice 0.2: Hollow + Quincy (P1) — HECHO (pendiente de verificación en Studio)
- [x] Kit Hollow: garras, Devorar (cura y remata), Cero, Sonido, máscara (D-042, D-038).
- [x] Kit Quincy: arco, Heilig Pfeil, flecha cargada, Licht Regen, Blut Vene, Hirenkyaku (D-042).
- [x] Reishi como recurso Quincy y Reishi ambiental por zonas (D-041).
- [x] Hitos de raza que desbloquean técnicas; prototipo de evolución Hollow; perfil v3 (D-039).
- [x] Potenciadores temporales (D-040).
- [ ] Proyectiles físicos para flechas y Cero (ahora son instantáneos).

## Mapa principal: Karakura — HECHO (pendiente de verificación en Studio)
- [x] Generador por datos y modelo sincronizado por Rojo (D-043).
- [x] Día y noche, luces de la ciudad, semáforos, tren y pasos a nivel (D-044).
- [ ] Sustituir los lugares principales por modelos de Arte cuando existan.

## M6 — Descubrimiento de Zanpakuto, pulido y playtests (P1)

## Histórico
- Prototipo inicial: `GameTypes`, `StateMachine`, `Character`, `CombatService`, `HitboxUtil`, `CombatController` y un borrador de `DataService` (retirado, D-012).
