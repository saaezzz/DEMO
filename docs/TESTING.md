# Testing

Estrategia en [DECISIONS.md](DECISIONS.md) D-006. Prioridades de la constitución en §57.

## Qué se prueba y dónde
| Tipo | Herramienta | Qué cubre |
|---|---|---|
| Unitarios | Lune (`tests/`) | Lógica pura: estados, recursos, señales, validadores, rate limit, cargador de servicios. En M1+: cooldowns, migraciones de datos, fórmulas |
| Integración | Roblox Studio (manual, por ahora) | Todo lo que depende del motor: Humanoid, hitboxes, red, animaciones, respawn |
| Estático | Selene, StyLua, luau-lsp | Lint, formato y tipos en modo strict (0 errores obligatorio) |

## Ejecutar
```bash
lune run tests/runner          # todos los tests
lune run tests/runner Signal   # solo los specs cuya ruta contenga "Signal"
```
El runner regenera `sourcemap.json` con Rojo antes de ejecutar.

## Cómo funciona
`tests/lib/RobloxEnvironment.luau` reconstruye el árbol de instancias del proyecto a partir
del sourcemap de Rojo y emula `script`, `game:GetService(...)` y `require(instancia)`.
Los módulos se cargan **tal cual**, sin adaptarlos a los tests. No emula el motor: un módulo
que use `Instance.new`, `Players`, física, etc. no es testeable así y se prueba en Studio.
Por eso la lógica de juego debe vivir en módulos puros siempre que sea posible (D-006).

Cada archivo spec recibe un entorno nuevo: los módulos se recargan y su estado de módulo
(p. ej. el nivel del `Logger`) no se filtra entre archivos.

## Escribir un test
Crea `tests/<Server|Shared|Client>/<Módulo>.spec.luau` devolviendo una tabla de casos:
```lua
local Character = require(game:GetService("ReplicatedStorage").Shared.Modules.Character)

return {
	["TakeDamage reduce la vida"] = function()
		local character = Character.new({ ... })
		character:TakeDamage(30)
		expect(character:GetHealth()).toBe(70)
	end,
}
```
Aserciones disponibles (`tests/lib/expect.luau`): `toBe`, `toEqual` (comparación profunda),
`toBeNil`, `toBeTruthy`, `toBeFalsy`, `toBeCloseTo`, `toThrow(fragmento?)`.

## Playtest en Studio
Hasta que exista un checklist por hito, cada prueba manual cubre (D-023):
- Personaje nuevo de nivel 1 de principio a fin, incluida la muerte y la reaparición.
- **Test → Clientes y servidores** con 2 o más jugadores: placas, daño y animaciones de los demás.
- Emulador de dispositivos (móvil) y mando si el cambio toca input o UI.
- Output sin errores en rojo.

## CI
`.github/workflows/ci.yml` ejecuta en cada push a `main` y en cada PR: formato, lint,
tipos, tests y build de Rojo. Un fallo en cualquiera bloquea el cambio.
