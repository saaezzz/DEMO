# Security

Reglas generales en la constitución §10–11. Este documento recoge lo que **ya está
implementado** y los riesgos conocidos pendientes.

## Garantías actuales
| Amenaza | Mitigación | Dónde |
|---|---|---|
| Spam de remotes | Rate limit por jugador y por remote (token bucket) | `RemoteGuard`, `RemoteDefinitions` |
| Payloads malformados o enormes | Esquema estricto: tipos, rangos, longitudes, sin claves desconocidas | `Schema` |
| Uso de la tabla del cliente | El handler recibe una copia saneada | `Schema.record` |
| Error en un handler | `pcall` + log; el cliente recibe `nil` | `RemoteGuard` |
| Daño/cooldown/recurso decidido por el cliente | Todo se resuelve en el servidor; el intent no lleva valores | `AbilityService`, `DamageService` |
| Cliente que elige una habilidad que no tiene | El cliente pide acciones; la habilidad sale del moveset del servidor | `AbilityService` (D-025) |
| Acciones de personajes muertos | Se rechazan | `CombatRegistry.GetAlive` |
| Parry encadenado pulsando bloqueo | Una ventana de parry cada 0,8 s | `CombatService` (D-009) |
| Reiniciar cooldowns muriendo | Los cooldowns son por jugador, no por modelo | `AbilityService` |
| Friendly fire | Los golpes solo afectan a personajes hostiles (jugador ↔ NPC) | `CombatRegistry.AreHostile` |
| Elegir raza no disponible o cambiarla | `ChooseRace` valida que exista, sea `Playable` y que aún no se haya elegido; límite 3 peticiones | `RaceService` (D-034) |
| Usar objetos que no se tienen o espamearlos | `UseItem` valida posesión, que sea consumible, cooldown y que tenga efecto; el objeto se quita antes de aplicar | `InventoryService` (D-036) |
| Duplicar botín | El botín se da en el servidor al morir el enemigo, a quien le dañó | `EnemyService` |
| Sesiones concurrentes / duplicación de datos | Bloqueo de sesión de ProfileStore; si otro servidor toma la sesión, se expulsa al jugador | `DataService` |
| Corrupción por migraciones o rollback | Migración sobre copia; versiones futuras no se tocan | `Migrator` (D-018) |
| Datos de otros jugadores | Cada cliente solo recibe sus propios datos | `DataService` (D-005) |
| Vida modificada fuera del servidor | Vida autoritativa en `Character`; regeneración de Roblox desactivada | D-010 |

## Riesgos conocidos (pendientes)
- **Movimiento (D-026):** la física del personaje es del cliente (así funciona Roblox): un exploit puede cambiar su
  WalkSpeed local o desplazarse más de lo permitido. El servidor ya decide velocidad, costes y cooldowns, pero **aún no
  comprueba el desplazamiento real** (anti speed-hack / teletransporte). Pendiente antes de abrir el juego a público.
- **Hitbox sin orientación:** el bloqueo protege también de golpes por la espalda.
