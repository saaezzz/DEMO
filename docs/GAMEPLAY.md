# Gameplay

Estado actual del prototipo. Los valores son provisionales hasta que exista `BALANCE.md`:
combate en `src/Server/Config/CombatConfig.luau`, movimiento en `src/Server/Config/MovementConfig.luau`
y cada habilidad en `src/Server/Content/Abilities.luau`.

## Estados de personaje
Estados de acción (exclusivos, D-017): `Idle`, `Attacking`, `Blocking`, `Parrying`, `Dodging`, `Dashing`,
`Casting`, `Transforming`, `Stunned`, `Knocked`, `Ragdolled`, `Disabled`, `Dead`.
Las interrupciones (`Stunned`, `Knocked`, `Ragdolled`, `Disabled`, `Dead`) pueden ocurrir desde cualquier estado vivo;
`Dead` es terminal. Además hay dos capas simultáneas (D-024): locomoción (`Stationary`, `Moving`, `Running`, `Sprinting`)
y forma (`Transformed` o no). Las habilidades declaran desde qué estados pueden empezar.
En uso actualmente: `Idle`, `Attacking`, `Blocking`, `Dodging`, `Dashing`, `Stunned`, `Dead`; locomoción completa.

## Combate (M2)
- El cliente pide **acciones** (`LightAttack`, `HeavyAttack`, `Block`, `Dodge`, `Dash`, `Sprint`); el servidor elige la
  habilidad según el moveset y resuelve todo (D-025).
- **Solo PvE:** los golpes de un jugador solo afectan a NPCs y viceversa.

| Habilidad | Acción | Qué hace | Coste | Cooldown |
|---|---|---|---|---|
| `Slash1` → `Slash2` → `Slash3` | Ataque ligero | Cadena de 3 golpes (10 / 10 / 16 de daño). Pulsar dentro de 0,8 s tras un golpe encadena el siguiente; el remate empuja | — | — |
| `HeavySlash` | Ataque pesado | Carga de 0,5 s, 24 de daño, 30 de postura. **Rompe la guardia** y empuja | 20 stamina | 3 s |
| `Dodge` | Esquiva | Paso de 14 studs en la dirección de movimiento (atrás si no te mueves). **Invulnerable 0,28 s**. Cancela un ataque o un bloqueo | 20 stamina | 0,6 s |
| `Dash` | Dash | 28 studs en la dirección de movimiento (delante si no te mueves), también en el aire | 15 Reiatsu | 1 s |

- **Golpe limpio:** daño completo, postura y un breve aturdimiento (hitstun, 0,3 s) que interrumpe lo que hiciera el objetivo.
- **Bloqueo:** mientras se mantiene pulsado (D-019). Reduce el daño al 25 % y multiplica ×1,5 el daño a la postura.
- **Parry:** los primeros 0,3 s de un bloqueo anulan el golpe (también el pesado) y aturden al atacante 0,8 s.
  Solo se concede una ventana de parry cada 0,8 s; bloquear antes sigue bloqueando, pero sin parry.
- **Guardia rota:** un ataque que rompe guardias contra alguien que bloquea (sin parry) hace el 50 % del daño,
  vacía su postura y lo aturde 1,5 s.
- **Postura:** al llenarse se vacía y aturde 1,5 s. Se recupera 10/s fuera de `Blocking`, `Parrying` y `Stunned`.
- Un aturdimiento nuevo solo alarga el actual, nunca lo acorta.

## Movimiento (D-026)
- Velocidad: 16 normal, 26 corriendo (sprint), 8 atacando/bloqueando, 3 aturdido.
- **Sprint:** mantener Shift / L3. Gasta 12 de stamina por segundo; hace falta 15 para empezar a correr.
- Dash y esquiva los aplica el cliente al recibir la aprobación del servidor.

## Recursos
- Definidos en `Shared/Content/Resources.luau`.
- **Reiatsu:** máximo 100, se regenera 5/s.
- **Stamina:** máximo 100, se regenera 25/s tras 1 s sin gastarla. Todas las razas la tienen.
- **Vida:** sin regeneración pasiva (D-010).

## Muñecos de entrenamiento (D-027)
Enfrente del punto de aparición:
| Muñeco | Comportamiento | Para probar |
|---|---|---|
| Muñeco | Quieto | Cadena de golpes, pesado, números de daño |
| Muñeco atacante | Si estás a menos de 9 studs, se ilumina en **rojo** y 0,6 s después ataca (cada 2,5 s) | Bloqueo, parry, esquiva |
| Muñeco en guardia | Siempre bloquea (y vuelve a bloquear tras un aturdimiento) | Ataque pesado y rotura de postura |

## Pendiente
- Transformaciones (§19) y habilidades de raza.
- Cancelaciones adicionales, combate aéreo, ataques cargados, bloqueo perfecto distinto del parry.
