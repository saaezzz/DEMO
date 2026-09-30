# Animations

Constitución §53 y D-020. Los sistemas usan **claves** de animación (`Combat.Slash1`), nunca IDs.

## Piezas
| Módulo | Función |
|---|---|
| `Shared/Content/Assets` | Asset de la animación (ID de Roblox, estado, dueño) |
| `Shared/Content/Animations` | Clave → asset, prioridad, bucle y markers esperados |
| `Server/Content/Abilities` | Cada habilidad lleva su clave de animación (`Animation`) |
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
cada habilidad lleva su animación y el servidor la replica con `ActionAnimation` y `ActionSeq` (D-025); los estados que no vienen de una habilidad (guardia, aturdimiento), con `Content/StateAnimations`.

**Al subir un asset real:** rellenar su `AssetId` y su estado en el manifiesto. El asset sustituye al
placeholder sin cambiar código: lo reproduce el dueño en su `Animator` y replica a los demás.
Un test exige que toda animación de acción tenga asset o placeholder.

## Pendientes de crear
| Clave | Asset | Uso |
|---|---|---|
| `Combat.Slash1`–`Slash3` | `ANIM_Sword_Slash1`–`3` | Cadena M1 (marker `Hit`) |
| `Combat.HeavySlash` | `ANIM_Sword_HeavySlash` | Ataque pesado (marker `Hit`) |
| `Combat.Dodge` | `ANIM_Combat_Dodge` | Esquiva |
| `Combat.Block` | `ANIM_Combat_Block` | Estados `Blocking` y `Parrying` (bucle) |
| `Combat.Dash` | `ANIM_Combat_Dash` | Dash |
| `Enemy.Swipe`, `Enemy.Lunge`, `Enemy.Crush` | `ANIM_Enemy_Swipe`, `_Lunge`, `_Crush` | Ataques de enemigos (marker `Hit`) |
| `Reaction.Stun` | `ANIM_Reaction_Stun` | Estados `Stunned` y `Knocked` (bucle) |
