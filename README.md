# Demo_RPG

RPG de acción PvE cooperativo para Roblox (prototipo inspirado en BLEACH).
Ver [docs/PROJECT_CONSTITUTION.md](docs/PROJECT_CONSTITUTION.md) para alcance y reglas del proyecto.

## Requisitos
- Roblox Studio con el plugin de Rojo 7.7.0.
- [Rokit](https://github.com/rojo-rbx/rokit) (gestor de herramientas).

## Primer uso
```bash
rokit install          # instala rojo, selene, stylua, luau-lsp y lune con las versiones del repo
rojo build -o "Demo_RPG.rbxlx"
```
Abre `Demo_RPG.rbxlx` en Roblox Studio y arranca el servidor de Rojo:
```bash
rojo serve
```

## Antes de hacer commit
```bash
selene src
stylua --check src
```

## Estructura
```
src/Server   -> ServerScriptService.Server
src/Client   -> StarterPlayerScripts.Client
src/Shared   -> ReplicatedStorage.Shared
docs/        documentación (fuente de verdad)
assets/      assets fuente (Blender, texturas, etc.)
tests/       tests
```

## Equipo
- El código Luau solo se modifica en el repositorio (sincronizado con Rojo), nunca directamente en Studio.
- Mundo, modelos, animaciones y VFX se trabajan en Studio / Team Create.
