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
stylua --check src tests
lune run tests/runner
```
Ver [docs/TESTING.md](docs/TESTING.md). El CI (GitHub Actions) ejecuta estas mismas comprobaciones.

Análisis de tipos (debe dar 0 errores). La primera vez, descarga las definiciones de Roblox:
```bash
curl -L -o globalTypes.d.luau https://raw.githubusercontent.com/JohnnyMorganz/luau-lsp/main/scripts/globalTypes.d.luau
rojo sourcemap default.project.json --include-non-scripts -o sourcemap.json
luau-lsp analyze --sourcemap=sourcemap.json --definitions=globalTypes.d.luau src
```

## Estructura
```
src/Server   -> ServerScriptService.Server
src/Client   -> StarterPlayerScripts.Client
src/Shared   -> ReplicatedStorage.Shared
docs/        documentación (fuente de verdad)
assets/      assets fuente (Blender, texturas, etc.)
tests/       tests con Lune (ver docs/TESTING.md)
```

## Equipo
- El código Luau solo se modifica en el repositorio (sincronizado con Rojo), nunca directamente en Studio.
- Mundo, modelos, animaciones y VFX se trabajan en Studio / Team Create.
