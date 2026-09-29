# Input

Constitución §51 y D-019. Los sistemas de juego escuchan **acciones**, nunca teclas.
Controles definidos en `src/Client/Input/InputBindings.luau` (mantener esta tabla sincronizada).

## Controles
| Acción | Teclado / ratón | Mando | Táctil | Estado |
|---|---|---|---|---|
| `LightAttack` | Clic izquierdo | X | Botón "Atacar" | En uso (M1 básico) |
| `HeavyAttack` | R | Y | — | Reservada (M2) |
| `Block` | F (mantener) | R1 (mantener) | Botón "Bloquear" (mantener) | En uso |
| `Dodge` | Ctrl izquierdo | B | — | Reservada (M2) |
| `Dash` | Q | L1 | Botón "Dash" | En uso |
| `Ability1`–`Ability4` | Z / X / C / V | Cruceta ↑ → ↓ ← | — | Reservadas (M2) |
| `Transform` | G | L3 | — | Reservada |
| `LockOn` | T | R3 | — | Reservada (M3) |
| `Interact` | E | L2 | — | Reservada |

Movimiento, salto y cámara son los de Roblox (WASD / Espacio / stick izquierdo / A); no se reasignan.

## Cómo funciona
- `InputController` enlaza cada acción con `ContextActionService`: respeta los TextBox enfocados y la UI que
  consume el input, y crea los botones táctiles en móvil.
- Emite `ActionBegan(action)` y `ActionEnded(action)`; `IsDown(action)` consulta si está pulsada.
- `GetInputMode()` / `InputModeChanged` devuelven `KeyboardMouse`, `Gamepad` o `Touch` según el último input,
  para que la UI muestre los iconos de controles correctos.
- Los handlers de estas señales **no deben ceder** (D-013): si llaman al servidor, usar `task.spawn`.

## Añadir o cambiar un control
1. Edita `InputBindings.luau` (y `ActionName` si es una acción nueva).
2. Actualiza la tabla de este documento.
3. `lune run tests/runner InputBindings` comprueba que no haya controles duplicados ni reservados.

## Pendiente de verificar en Studio
- Botones táctiles en el emulador de móvil (posición y tamaño por defecto de ContextActionService).
- Que el clic izquierdo sobre la UI del juego no dispare `LightAttack`.
