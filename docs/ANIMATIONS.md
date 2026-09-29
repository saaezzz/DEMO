# Animations

Constitución §53 y D-020. Los sistemas usan **claves** de animación (`Combat.BasicSlash`), nunca IDs.

## Piezas
| Módulo | Función |
|---|---|
| `Shared/Content/Assets` | Asset de la animación (ID de Roblox, estado, dueño) |
| `Shared/Content/Animations` | Clave → asset, prioridad, bucle y markers esperados |
| `Shared/Content/ComboAnimations` | Combo → clave de animación |
| `Shared/Modules/AnimationRegistry` | `Get`, `GetContentId`, `GetEnumPriority`, `IsValidMarker` |

Si el asset aún no tiene `AssetId`, la animación no se reproduce, pero la mecánica funciona igual
(el servidor no depende de las animaciones).

## Markers estándar
`Startup`, `Hit`, `Active`, `Recovery`, `VFX`, `SFX`, `IFrameStart`, `IFrameEnd`.
Si un marker se repite en la misma animación se numera: `Hit`, `Hit2`, `Hit3`...

Cada golpe de un combo (`ComboHitWindow.MarkerName`) debe corresponder a un marker de su animación
(lo comprueba `ContentIntegrity.spec.luau`). Los tiempos del servidor (`StartTime`/`EndTime`) deben
coincidir con la posición de esos markers; si el animador cambia la animación, hay que revisarlos.

## Para Animación/Visual
- Nombre del asset según `docs/ASSETS.md` (`ANIM_<Grupo>_<Nombre>`).
- Añadir en el editor de animación los Keyframe Markers indicados en las notas del manifiesto.
- Prioridad: `Action` para ataques y habilidades, `Movement` para locomoción, `Idle`/`Core` para poses base.
