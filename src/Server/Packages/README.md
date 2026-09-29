# Packages

Coloca aquí las librerías de terceros como `ModuleScript` (`.luau`):

- `ProfileService.luau` — https://github.com/MadStudioRoblox/ProfileService
- `ReplicaService.luau` (o su carpeta `ReplicaService/`) — https://github.com/MadStudioRoblox/ReplicaService

Estos archivos no se generan automáticamente (son librerías externas de terceros);
descárgalos de sus repositorios oficiales o instálalos vía Wally y colócalos en
esta carpeta. `DataService.luau` los requiere como:

```lua
local ProfileService = require(script.Parent.Packages.ProfileService)
local ReplicaService = require(script.Parent.Packages.ReplicaService)
```

Esta carpeta se sincroniza vía Rojo como `ServerScriptService.Server.Packages`.
