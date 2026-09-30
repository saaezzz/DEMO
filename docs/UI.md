# UI

Constitución §52 y D-022. UI **provisional** con estilo propio: sustituye a la de Roblox hasta
que el equipo de UI entregue el diseño final. Todo lo visual sale de `Client/UI/Theme`.

## Piezas
| Módulo | Qué muestra |
|---|---|
| `Controllers/HudController` | Panel arriba a la izquierda: nombre, nivel y raza, estado de acción, vida, postura y recursos. Pantalla de muerte con cuenta atrás |
| `Controllers/NameplateController` | Placa sobre cada **otro** jugador: nombre, nivel, vida y postura (esta solo si es > 0) |
| `Controllers/HitFeedbackController` | Destello blanco y número de daño flotante al recibir daño (en todos los personajes) |
| `UI/StatBar` | Barra reutilizable con relleno animado y "barra fantasma" del daño recién recibido |
| `UI/Theme`, `UI/UIUtil` | Colores, tipografías (Oswald) y creación de instancias |

Se desactivan la barra de vida de Roblox (`CoreGuiType.Health`) y el nombre/vida sobre la cabeza
(`Humanoid.DisplayDistanceType = None`). Chat, lista de jugadores y menú se mantienen.

## De dónde salen los datos
Solo de lo que replica el servidor (D-021): vida del `Humanoid` y atributos del modelo
(`Shared/Network/ReplicatedAttributes`). La UI nunca decide nada de juego.
El color y el nombre de cada recurso vienen de `Content/Resources` (`Color`, `DisplayName`).

## Móvil
El panel va arriba a la izquierda para no tapar el joystick táctil (abajo a la izquierda) ni los
botones de acción (abajo a la derecha). Un `UIScale` lo reduce en pantallas bajas.

## Pendiente (§52)
Stamina, EXP, habilidades y cooldowns, quest tracker e información del objetivo llegarán con sus
sistemas (M2–M3). Menús: más adelante.
