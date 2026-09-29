# Networking

Decisión de diseño en [DECISIONS.md](DECISIONS.md) D-016. Requisitos de seguridad en
[SECURITY.md](SECURITY.md) y en la constitución §10–11.

## Principio
El cliente solo envía **intenciones**. El servidor valida y decide. Ningún payload del cliente
contiene resultados (daño, recompensas, posiciones de destino, estados).

## Piezas
| Módulo | Lado | Función |
|---|---|---|
| `Shared/Network/RemoteDefinitions` | Ambos | Catálogo de remotes: nombre, tipo (`Function`/`Event`) y rate limit |
| `Shared/Network/Schema` | Ambos | Validadores declarativos de payloads |
| `Server/Network/ServerNetwork` | Servidor | Crea los remotes al arrancar y registra handlers con validador obligatorio |
| `Server/Network/RemoteGuard` | Servidor | Rate limit → validación → handler protegido con `pcall` |
| `Client/Network/ClientNetwork` | Cliente | `Invoke`, `Fire`, `OnEvent` |

Los remotes se crean por código en `ReplicatedStorage.Remotes` durante `ServerNetwork:Init`;
**no** se declaran en `default.project.json`. Si el lugar trae una carpeta `Remotes` previa, el servidor
la sustituye y avisa en el log.

## Remotes actuales
| Nombre | Tipo | Rate limit | Payload | Respuesta |
|---|---|---|---|---|
| `CombatIntent` | Function | ráfaga 10, 8/s | `{ Type: "Attack" \| "Block" \| "Dash", ComboId: string(≤64)? }` | `ServerCombatResponse` o `nil` |
| `PlayerData` | ToClientEvent | — | `PlayerDataMessage` (copia completa o cambio por clave), solo al dueño | — |

## Añadir un remote
1. Añade el nombre al tipo `RemoteName` y su definición en `RemoteDefinitions` (`Function`, `ToServerEvent` o `ToClientEvent`; los que inicia el cliente necesitan `RateLimit`).
2. Define su esquema con `Schema` (en un módulo propio si quieres testearlo con Lune).
3. En el `Start` del servicio dueño:
   ```lua
   ServerNetwork:HandleFunction("MiRemote", MiEsquema, function(player, payload)
       -- payload ya está validado y es una copia saneada
   end)
   ```
4. En el cliente: `ClientNetwork.Invoke("MiRemote", payload)` (devuelve `nil` si se rechaza).
5. Añade tests del esquema y documenta el remote en la tabla de arriba.

## Comportamiento ante rechazos
- Rate limit superado, payload inválido o error del handler → el cliente recibe `nil` y el
  servidor lo registra (`Debug` para rechazos, `Error` para fallos del handler).
- Un `RemoteFunction` sin handler registrado responde `nil` en lugar de bloquear al cliente.
- Lo que un cliente emita en un `ToClientEvent` se descarta (y se registra en `Debug`).
- Registrar dos handlers para el mismo remote, o un handler del tipo equivocado, aborta el arranque.
