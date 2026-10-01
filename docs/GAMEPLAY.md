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

## Mapa: Karakura (D-043)
Apareces en el patio de la **tienda de Urahara** (Mitsumiya, al este). Lugares importantes:
| Lugar | Qué hay |
|---|---|
| Galería subterránea (bajo la tienda de Urahara) | Muñecos de entrenamiento. Se baja por la rampa del patio |
| Parque Tsubakidai | Hollows débiles |
| Ruinas del Hospital Matsukura (junto al parque) | Hollows |
| Restos del edificio de carreras (Kinogaya) | Hollow élite |
| Orilla del Karasu (sur) | El Gran Hollow |
| Estación de Karakura Honchō, instituto, clínica Kurosaki, hospital, galería comercial, santuario… | Ambientación |

Hay día y noche (D-044): 18 min de día y 8 de noche.
- De noche se encienden ventanas, farolas y letreros.
- El tren pasa de vez en cuando y para en la estación.
- En los pasos a nivel bajan las barreras cuando pasa el tren.

## Muñecos de entrenamiento (D-027)
En la galería subterránea bajo la tienda de Urahara:
| Muñeco | Comportamiento | Para probar |
|---|---|---|
| Muñeco | Quieto | Cadena de golpes, pesado, números de daño |
| Muñeco atacante | Si estás a menos de 9 studs, se ilumina en **rojo** y 0,6 s después ataca (cada 2,5 s) | Bloqueo, parry, esquiva |
| Muñeco en guardia | Siempre bloquea (y vuelve a bloquear tras un aturdimiento) | Ataque pesado y rotura de postura |

## Enemigos (M3, D-029)
Repartidos por Karakura (ver Mapa). Todos avisan en **rojo** antes de atacar.
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

## Razas (M4–M5, D-034, D-042)
Al entrar por primera vez eliges raza: **Shinigami**, **Hollow** o **Quincy**. La elección es definitiva.

| Kit Shinigami | |
|---|---|
| Arma | Asauchi (espada en la mano) |
| Ataques | Cadena de 3 tajos, pesado, esquiva |
| Movimiento | **Shunpo** (Q): 28 studs, también en el aire, 15 Reiatsu |
| Técnicas | **Byakurai** (Z): rayo de 40 studs, 22 de daño, 25 Reiatsu, 6 s · **Sai** (X): inmoviliza 2 s a un enemigo cercano, ignora la guardia, 20 Reiatsu, 10 s |
| Objetos iniciales | 3 Bálsamos curativos, 2 Tónicos de Reiatsu |

| Kit Hollow | |
|---|---|
| Pieza | Máscara |
| Ataques | Cadena de 3 zarpazos (9 / 9 / 15), **Desgarro** (pesado, rompe la guardia), esquiva |
| Movimiento | **Sonido** (Q): 26 studs, también en el aire, 12 Reiatsu |
| Técnicas | **Devorar** (Z): mordisco que ignora la guardia, **cura todo el daño que hace** y **remata** a un enemigo con ≤ 30 % de vida (no a jefes); 10 Reiatsu, 8 s · **Cero** (X): carga 0,8 s, rayo de 50 studs, 30 de daño, 35 Reiatsu, 9 s |
| Evolución | **Hambre insaciable** (nivel 2 + 3 almas devoradas) → **Bala** (disparo rápido) · **Gillian** (nivel 5 + 12 almas) → **Hierro** (−30 % de daño recibido 10 s) |
| Objetos iniciales | 2 Bálsamos, 2 Tónicos de Reiatsu |

| Kit Quincy | |
|---|---|
| Arma | Arco espiritual (mano izquierda) |
| Recurso | **Reishi** en lugar de Reiatsu: se regenera más rápido donde hay Reishi ambiental denso |
| Ataques | Cadena de 3 flechas de **Heilig Pfeil** a 36 studs (7 / 7 / 11), **flecha cargada** (pesado, atraviesa y rompe la guardia), esquiva |
| Movimiento | **Hirenkyaku** (Q): 32 studs, también en el aire, 12 Reishi |
| Técnicas | **Licht Regen** (Z): lluvia de flechas en un círculo de radio 9 a 18 studs, 35 Reishi, 10 s · **Blut Vene** (X): −40 % de daño recibido 8 s, 30 Reishi, 20 s |
| Hitos | **Blut Arterie** (nivel 3 + 15 enemigos abatidos con flechas) → +35 % de daño 8 s |
| Objetos iniciales | 3 Bálsamos, 2 Viales de Reishi |

Antes de elegir: los mismos golpes y un **paso** corto (16 studs, 15 de stamina) en lugar de Shunpo.

## Hitos de raza (D-039)
Piden **nivel y una acción concreta** (devorar, abatir con flechas…); los muñecos de entrenamiento no cuentan.
Al cumplirlos aparece un aviso y la técnica nueva entra en la barra (hasta 4 técnicas). Cada baja que cuenta
muestra el progreso ("Almas devoradas: 2/3").

## Potenciadores (D-040)
Hierro, Blut Vene y Blut Arterie cambian el daño recibido o hecho durante unos segundos. Se ven como un
contorno de color sobre el personaje, que se desvanece al acabar. Usar el mismo otra vez lo renueva, no lo acumula.

## Reishi ambiental (D-041)
| Zona | Densidad |
|---|---|
| Fuera de zonas | ×1 |
| Galería subterránea | ×1,3 |
| Parque Tsubakidai | ×1,5 |
| Ruinas del Hospital Matsukura / restos del edificio de carreras | ×1,6 |
| Orilla del Karasu | ×2 |

Multiplica la regeneración de Reishi (7/s base). Un Quincy ve un aviso al entrar y salir.

## Objetos (D-036)
Mochila con **B** (o el botón "MOCHILA"). El color del borde indica la rareza: Común (gris), Poco común (verde),
Raro (azul), Épico (morado), Legendario (naranja).
- **Bálsamo curativo:** +40 de vida. **Tónico de Reiatsu:** +50 de Reiatsu. Cooldown de 5 s; no se gastan si no harían nada.
- Materiales: Fragmento de máscara, Núcleo de Hollow, Colmillo de élite, Máscara del Gran Hollow (legendaria).
- Cada jugador que dañó a un enemigo tira **su propio botín**.

## Jefe: Gran Hollow (D-037)
En la orilla del río Karasu. Nivel 10, 1600 de vida, reaparece a los 90 s.
- **Fase 1:** zarpazo amplio y **golpe al suelo en área**: un círculo rojo marca la zona 1,2 s antes. Rompe la guardia, así que sal del círculo o haz parry.
- **Fase 2** (60 % de vida): se enfurece, más rápido, y añade una **carga** de 30 studs.
- **Fase 3** (25 %): ataca casi sin pausa.
- Punto débil: su postura. Rómpela (o hazle parry) y quedará aturdido.
- Misión final "El Gran Hollow": 500 EXP. Botín: materiales y 30 % de la máscara legendaria.

## Pendiente
- Transformaciones (§19), descubrimiento de Zanpakuto (M6), evolución Hollow más allá de Gillian.
- Proyectiles físicos (flechas y Cero son instantáneos).
- Cancelaciones adicionales, combate aéreo, ataques cargados, bloqueo perfecto distinto del parry.
