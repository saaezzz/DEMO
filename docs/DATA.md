# Data

Persistencia de los datos del jugador. Decisiones: D-004 (ProfileStore), D-005 (replicación),
D-018 (versionado y ciclo de vida). Constitución §59.

## Esquema actual (versión 1)
Tipo en `src/Shared/Types/PlayerDataTypes.luau`; plantilla y versión en `src/Server/Data/DataSchema.luau`.

| Clave | Tipo | Valor inicial | Uso |
|---|---|---|---|
| `DataVersion` | number | 2 | Versión del esquema (obligatoria) |
| `Race` | RaceId | `Races.Default` | Raza del personaje (contenido) |
| `Level` | number | 1 | Nivel (máx. 100, §14) |
| `Experience` | number | 0 | EXP acumulada en el nivel |
| `Currency` | number | 0 | Moneda |
| `Inventory` | `{ { Id, Quantity } }` | `{}` | Inventario |
| `Settings` | `{ MusicVolume, SfxVolume, CameraShake }` | 0.5 / 0.5 / true | Ajustes del jugador |
| `Quests` | `{ Active = { { Id, Progress } }, Completed = { [Id]: true } }` | vacío | Misiones en curso y completadas (v2, M3) |

Los valores de combate (vida actual, recursos, postura) **no** se guardan: se recalculan al aparecer.

## Ciclo de vida
1. `PlayerAdded` → `DataService` abre la sesión con ProfileStore (`Player_<UserId>`, store `PlayerData`).
   Se cancela si el jugador se va mientras carga.
2. Se **migra** una copia de los datos a la versión actual (`Migrator`). Si falla o los datos son de una
   versión futura, el jugador es expulsado y los datos **no se modifican**.
3. `Reconcile` completa las claves que falten con la plantilla.
4. Se envía una copia completa al cliente (remote `PlayerData`) y se emite `DataService.ProfileLoaded`.
5. `CharacterService` genera el personaje con la raza y el nivel del perfil (`CharacterAutoLoads` desactivado).
6. `PlayerRemoving` → se cierra la sesión (guardado final). ProfileStore guarda también cada 300 s y al cerrar el servidor.
7. Si otro servidor toma la sesión, este expulsa al jugador (evita duplicados de datos).

En Studio sin acceso a la API de DataStore, ProfileStore usa automáticamente un almacenamiento simulado.

## Leer y modificar
- `DataService:GetData(player)` — lectura. **No mutar la tabla devuelta.**
- `DataService:SetValue(player, key, value)` — modifica una clave de primer nivel y replica el cambio al dueño.
- Cliente: `PlayerDataController:GetData()`, señales `Loaded` y `Changed(key, value)`.

## Cambiar el esquema
1. Incrementa `DataSchema.VERSION`.
2. Añade `DataSchema.MIGRATIONS[versiónAnterior]` que transforme los datos antiguos (recibe una copia; puede mutarla).
3. Actualiza `createTemplate()`, `PlayerDataTypes` y la tabla de este documento.
4. Añade tests en `tests/Server/DataSchema.spec.luau`.

Nunca borres ni renombres claves sin una migración (§59). Una migración que lanza un error no guarda nada.
