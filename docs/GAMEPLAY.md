# Gameplay

## Estados de personaje
`Idle`, `Attacking`, `Blocking`, `Stunned`, `Shunpo`, `Casting`, `Ragdoll`
(ver `src/Shared/Types/GameTypes.luau`).

## Combate
- El cliente solo envía intenciones (`CombatIntent`); el servidor valida y resuelve.
- Combos definidos en `src/Server/Combos/`, con ventanas de golpe (`ComboHitWindow`) e hitboxes.
- Bloqueo: mitiga daño y aumenta daño a la postura.
- Parry: bloquear en los primeros instantes de `Blocking` anula el golpe y aturde al atacante.

## Pendiente de definir
- Sistema de habilidades (`CastAbility`).
- Progresión de combos y desbloqueos.
