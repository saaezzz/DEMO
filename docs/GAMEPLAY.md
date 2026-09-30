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
| `Slash1` → `Slash2` → `Slash3` | Ataque ligero | Cadena de 3 golpes (10 / 10 / 16 de daño). Pulsar dentro de 0,8 s tras un golpe encadena el siguiente; el remate empuja unos 11 studs | — | — |
| `HeavySlash` | Ataque pesado | Carga de 0,5 s, 24 de daño, 30 de postura. **Rompe la guardia** y empuja unos 9 studs | 20 stamina | 3 s |
| `Dodge` | Esquiva | Paso de 14 studs en la dirección de movimiento (atrás si no te mueves). **Invulnerable 0,28 s**. Cancela un ataque o un bloqueo | 20 stamina | 0,6 s |
| `Shunpo` (Shinigami) / `Step` (sin raza) | Dash | 28 studs en la dirección de movimiento (delante si no te mueves), también en el aire / paso de 16 studs en el suelo | 15 Reiatsu / 15 stamina | 1 s / 1,2 s |

- **Golpe limpio:** daño completo, postura y un breve aturdimiento (hitstun, 0,3 s) que interrumpe lo que hiciera el objetivo.
- **Bloqueo:** mientras se mantiene pulsado (D-019). Reduce el daño al 25 % y multiplica ×1,5 el daño a la postura.
- **Parry:** los primeros 0,3 s de un bloqueo anulan el golpe (también el pesado) y aturden al atacante 0,8 s.
  Solo se concede una ventana de parry cada 0,8 s; bloquear antes sigue bloqueando, pero sin parry.
- **Sin espamear la guardia:** tras soltarla (o perderla), hay que esperar 0,5 s para volver a bloquear. Si se mantiene
  la tecla, la guardia entra sola en cuanto se puede.
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

## Enemigos (M3, D-029)
Zona de caza al norte, pasados los muñecos. Todos avisan en **rojo** antes de atacar.
| Enemigo | Nivel | Vida | Ataques | EXP | Reaparece |
|---|---|---|---|---|---|
| Hollow débil (×4) | 1 | 60 | Zarpazo | 20 | 12 s |
| Hollow (×2) | 3 | 140 | Zarpazo, embestida (salta 14 studs y empuja) | 55 | 20 s |
| Hollow élite (×1) | 6 | 400 | Zarpazo, embestida y **aplastamiento** (carga larga, rompe la guardia) | 180 | 45 s |

- Te detectan a unos 35–45 studs; si les golpeas desde más lejos, también van a por ti.
- Si se alejan demasiado de su sitio, vuelven y se curan del todo.
- **EXP para todos los que le hayan hecho daño**, y la baja cuenta para las misiones de todos ellos.

## Progresión (D-028)
- EXP para subir del nivel N: `60 · N^1.5` (60, 169, 311, 480, 670…). Nivel máximo 100.
- Cada nivel da +4 de vida máxima; al subir, la vida se llena.

## Misiones (D-030)
Empiezan solas y se encadenan:
1. **Primera cacería:** derrota 3 Hollows débiles → 60 EXP.
2. **Amenaza creciente:** derrota 2 Hollows → 150 EXP.
3. **El Hollow élite:** derrótalo → 300 EXP.

El seguimiento está a la derecha, con un marcador ◆ y la distancia hacia el objetivo.

## Fijar objetivo (D-032)
- **T / R3 / "Fijar":** fija el enemigo más centrado; volver a pulsar pasa al siguiente. **Mantener** lo suelta.
- Con objetivo, el personaje lo encara y la cámara encuadra a ambos. Opcional.

## Razas (M4, D-034)
Al entrar por primera vez eliges raza. Ahora solo **Shinigami** está disponible; Hollow y Quincy llegan en M5.

| Kit Shinigami | |
|---|---|
| Arma | Asauchi (espada en la mano) |
| Ataques | Cadena de 3 tajos, pesado, esquiva |
| Movimiento | **Shunpo** (Q): 28 studs, también en el aire, 15 Reiatsu |
| Técnicas | **Byakurai** (Z): rayo de 40 studs, 22 de daño, 25 Reiatsu, 6 s · **Sai** (X): inmoviliza 2 s a un enemigo cercano, ignora la guardia, 20 Reiatsu, 10 s |
| Objetos iniciales | 3 Bálsamos curativos, 2 Tónicos de Reiatsu |

Antes de elegir: los mismos golpes y un **paso** corto (16 studs, 15 de stamina) en lugar de Shunpo.

## Objetos (D-036)
Mochila con **B** (o el botón "MOCHILA"). El color del borde indica la rareza: Común (gris), Poco común (verde),
Raro (azul), Épico (morado), Legendario (naranja).
- **Bálsamo curativo:** +40 de vida. **Tónico de Reiatsu:** +50 de Reiatsu. Cooldown de 5 s; no se gastan si no harían nada.
- Materiales: Fragmento de máscara, Núcleo de Hollow, Colmillo de élite, Máscara del Gran Hollow (legendaria).
- Cada jugador que dañó a un enemigo tira **su propio botín**.

## Jefe: Gran Hollow (D-037)
Al fondo de la zona. Nivel 10, 1600 de vida, reaparece a los 90 s.
- **Fase 1:** zarpazo amplio y **golpe al suelo en área**: un círculo rojo marca la zona 1,2 s antes. Rompe la guardia, así que sal del círculo o haz parry.
- **Fase 2** (60 % de vida): se enfurece, más rápido, y añade una **carga** de 30 studs.
- **Fase 3** (25 %): ataca casi sin pausa.
- Punto débil: su postura. Rómpela (o hazle parry) y quedará aturdido.
- Misión final "El Gran Hollow": 500 EXP. Botín: materiales y 30 % de la máscara legendaria.

## Pendiente
- Transformaciones (§19), Hollow y Quincy (M5), descubrimiento de Zanpakuto (M6).
- Cancelaciones adicionales, combate aéreo, ataques cargados, bloqueo perfecto distinto del parry.
