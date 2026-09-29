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
| Daño/cooldown/recurso decidido por el cliente | Todo se resuelve en el servidor; el intent no lleva valores | `CombatService` |
| Acciones de personajes muertos | Se rechazan | `CombatService.getActiveCharacter` |
| Parry encadenado pulsando bloqueo | Una ventana de parry cada 0,8 s | `CombatService` (D-009) |
| Reiniciar cooldowns muriendo | Los cooldowns son por jugador, no por modelo | `CombatService` |
| Vida modificada fuera del servidor | Vida autoritativa en `Character`; regeneración de Roblox desactivada | D-010 |

## Riesgos conocidos (pendientes)
- **Movimiento:** no hay validación de velocidad/teletransporte. Necesario antes de que Shunpo mueva al personaje (framework de movimiento, M2).
- **Hitbox sin orientación:** el bloqueo protege también de golpes por la espalda.
- **Friendly fire:** los jugadores pueden dañarse entre sí; falta la capa de facciones/objetivos válidos (juego PvE).
- **Datos persistentes:** aún no existen; la tarea 8 (ProfileStore) debe incluir protección contra duplicados y sesiones concurrentes.
