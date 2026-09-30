# Input

Constitución §51 y D-019. Los sistemas de juego escuchan **acciones**, nunca teclas.
Controles definidos en `src/Client/Input/InputBindings.luau` (mantener esta tabla sincronizada).

## Controles
| Acción | Teclado / ratón | Mando | Táctil | Estado |
|---|---|---|---|---|
| `LightAttack` | Clic izquierdo | X | Botón "Atacar" | En uso: cadena de 3 golpes |
| `HeavyAttack` | R | Y | Botón "Pesado" | En uso: rompe la guardia |
| `Block` | F (mantener) | R1 (mantener) | Botón "Bloquear" (mantener) | En uso (parry al empezar) |
| `Dodge` | Ctrl izquierdo | B | Botón "Esquivar" | En uso: i-frames |
| `Dash` | Q | L1 | Botón "Dash" | En uso: direccional y aéreo |
| `Sprint` | Shift izquierdo (mantener) | L3 (mantener) | — (en móvil se corre a velocidad normal) | En uso: gasta stamina |
| `Ability1`–`Ability4` | Z / X / C / V | Cruceta ↑ → ↓ ← | — | Reservadas |
| `Transform` | G | R2 | — | Reservada |
| `LockOn` | T (pulsar: fijar/cambiar; mantener: soltar) | R3 | Botón "Fijar" | En uso (D-032) |
| `Interact` | E | L2 | — | Reservada |

Movimiento, salto y cámara son los de Roblox (WASD / Espacio / stick izquierdo / A); no se reasignan.
El shift-lock de Roblox está desactivado (`StarterPlayer.EnableMouseLockOption = false`) porque Shift es sprint;
la cámara de combate con fijado de objetivo llegará en M3.

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
