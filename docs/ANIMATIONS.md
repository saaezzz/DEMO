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

## Animaciones provisionales (D-022)
Mientras Animación/Visual no entregue los assets:
- **Locomoción:** pack Ninja del catálogo de Roblox (`ANIM_Locomotion_*`, `Content/LocomotionAnimations`).
  `CharacterAnimationController` cambia los `AnimationId` del script `Animate` por defecto. Solo R15.
- **Acciones:** placeholders procedurales en `Client/Animation/PlaceholderAnimations`, con las mismas claves
  que `Content/Animations`. Son keyframes de ángulos por articulación R15 que se suman al `C0` de los `Motor6D`.

Qué animación toca en cada momento sale del estado replicado del personaje (D-021):
`Attacking` → animación del combo (`ComboAnimations[ActionId]`); el resto de estados, `Content/StateAnimations`.

**Al subir un asset real:** rellenar su `AssetId` y su estado en el manifiesto. El asset sustituye al
placeholder sin cambiar código: lo reproduce el dueño en su `Animator` y replica a los demás.
Un test exige que toda animación de acción tenga asset o placeholder.

## Pendientes de crear
| Clave | Asset | Uso |
|---|---|---|
| `Combat.BasicSlash` | `ANIM_Sword_BasicSlash` | Combo `BasicSlash` (marker `Hit`) |
| `Combat.Block` | `ANIM_Combat_Block` | Estados `Blocking` y `Parrying` (bucle) |
| `Combat.Dash` | `ANIM_Combat_Dash` | Estado `Dashing` |
| `Reaction.Stun` | `ANIM_Reaction_Stun` | Estados `Stunned` y `Knocked` (bucle) |
