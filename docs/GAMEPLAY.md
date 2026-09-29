# Gameplay

Estado actual del prototipo. Los valores son provisionales hasta que exista `BALANCE.md`;
viven como constantes al inicio de `src/Server/Services/CombatService.luau`.

## Estados de personaje
Estados de acción (exclusivos, D-017): `Idle`, `Attacking`, `Blocking`, `Parrying`, `Dodging`, `Dashing`,
`Casting`, `Transforming`, `Stunned`, `Knocked`, `Ragdolled`, `Disabled`, `Dead`.
Las interrupciones (`Stunned`, `Knocked`, `Ragdolled`, `Disabled`, `Dead`) pueden ocurrir desde cualquier estado vivo;
`Dead` es terminal. Locomoción y forma transformada serán capas aparte (M2).
En uso actualmente: `Idle`, `Attacking`, `Blocking`, `Dashing`, `Stunned`, `Dead`.

## Combate
- El cliente solo envía intenciones (`CombatIntent`); el servidor valida y resuelve.
- Combos definidos en `src/Server/Content/Combos.luau`, con ventanas de golpe (`ComboHitWindow`) e hitboxes.
- **Ataque básico (M1):** sin coste de recurso; cooldown por combo.
- **Bloqueo:** alterna al pulsar. Reduce el daño al 25 % y multiplica ×1,5 el daño a la postura.
- **Parry:** los primeros 0,3 s de un bloqueo anulan el golpe y aturden al atacante 0,8 s.
  Solo se concede una ventana de parry cada 0,8 s; bloquear antes sigue bloqueando, pero sin parry.
- **Postura:** al llenarse se vacía y aturde al defensor 1,5 s. Decae 10/s fuera de `Blocking` y `Stunned`.
- **Dash** (contenido actual: Shunpo): 15 de Reiatsu, 0,4 s en estado `Dashing`. Todavía no desplaza al personaje (framework de movimiento en M2).

## Recursos
- Recursos definidos en `Shared/Content/Resources.luau`. **Reiatsu:** máximo 100, se regenera 5/s.
- **Vida:** sin regeneración pasiva (D-010).

## Pendiente
- Framework de habilidades, movimiento y transformaciones (M2).
- Progresión de combos y desbloqueos.
