# Gameplay

Estado actual del prototipo. Los valores son provisionales hasta que exista `BALANCE.md`;
viven como constantes al inicio de `src/Server/Services/CombatService.luau`.

## Estados de personaje
`Idle`, `Attacking`, `Blocking`, `Stunned`, `Shunpo`, `Casting`, `Ragdoll`
(ver `src/Shared/Types/GameTypes.luau` y la tabla de transiciones en `src/Shared/Modules/Character.luau`).
La lista completa de §15 de la constitución llegará en M1.

## Combate
- El cliente solo envía intenciones (`CombatIntent`); el servidor valida y resuelve.
- Combos definidos en `src/Server/Combos/`, con ventanas de golpe (`ComboHitWindow`) e hitboxes.
- **Ataque básico (M1):** sin coste de recurso; cooldown por combo.
- **Bloqueo:** alterna al pulsar. Reduce el daño al 25 % y multiplica ×1,5 el daño a la postura.
- **Parry:** los primeros 0,3 s de un bloqueo anulan el golpe y aturden al atacante 0,8 s.
  Solo se concede una ventana de parry cada 0,8 s; bloquear antes sigue bloqueando, pero sin parry.
- **Postura:** al llenarse se vacía y aturde al defensor 1,5 s. Decae 10/s fuera de `Blocking` y `Stunned`.
- **Shunpo:** 15 de Reiatsu, 0,4 s en estado `Shunpo`. Todavía no desplaza al personaje (framework de movimiento en M2).

## Recursos
- **Reiatsu:** se regenera 5/s.
- **Vida:** sin regeneración pasiva (D-010).

## Pendiente
- Framework de habilidades, movimiento y transformaciones (M2).
- Progresión de combos y desbloqueos.
