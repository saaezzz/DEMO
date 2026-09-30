# Assets

Constitución §54 y D-020. El manifiesto `src/Shared/Content/Assets.luau` es la **única fuente de verdad**
de los IDs de Roblox: ningún sistema escribe un `rbxassetid://` a mano.

## Convención de nombres
`<PREFIJO>_<Grupo>_<Nombre>`, con `Grupo` y `Nombre` en PascalCase, sin espacios ni guiones.

| Categoría | Prefijo | Ejemplo |
|---|---|---|
| Animation | `ANIM` | `ANIM_Sword_Slash1` |
| Model | `MDL` | `MDL_Weapon_StarterSword` |
| VFX | `VFX` | `VFX_Combat_SlashTrail` |
| SFX | `SFX` | `SFX_Combat_SwordHit` |
| Music | `MUS` | `MUS_Town_Theme` |
| UI | `UI` | `UI_Hud_HealthBar` |
| Texture | `TEX` | `TEX_Env_StreetAsphalt` |

El mismo nombre se usa en Studio y en los archivos fuente (`assets/`, Blender) para poder rastrear cada asset.

## Campos de cada entrada
| Campo | Descripción |
|---|---|
| `Name` | Nombre según la convención (único) |
| `Category` | Una de las categorías de la tabla |
| `AssetId` | ID numérico de Roblox; vacío hasta que se sube |
| `Owner` | Responsable (Programación, Arte/Builder, Animación/Visual) |
| `Status` | Ver flujo de estados |
| `Version` | Se incrementa cada vez que se sustituye el asset subido |
| `Dependencies` | Otros assets del manifiesto que necesita |
| `UsedBy` | Qué lo usa (p. ej. `Ability:Slash1`) |
| `Notes` | Indicaciones para quien lo crea (duración, markers, estilo...) |

## Flujo de estados
`TODO` → `IN_PROGRESS` → `REVIEW` → `APPROVED` → `INTEGRATED` (y `BLOCKED` si algo lo impide).
Un asset `APPROVED` o `INTEGRATED` debe tener `AssetId` (lo comprueba un test).

## Alta de un asset nuevo
1. El Lead Programmer añade la entrada al manifiesto con `Status = "TODO"` y las notas necesarias.
2. Arte/Animación lo crea con ese nombre exacto y **lo coloca en Studio** en `ReplicatedStorage.Assets/<carpeta>`
   (D-033, [GUIA_EQUIPO.md](GUIA_EQUIPO.md)). El juego lo usa en cuanto está; Output (`[Assets]`) confirma que se ha encontrado.
3. Opcional: se copia su `AssetId` al manifiesto, se sube `Version` y se cambia el estado (así no depende del lugar).
4. `lune run tests/runner ContentIntegrity` valida nombres, estados, IDs y dependencias.

## Assets actuales
| Nombre | Categoría | Estado | Usado por |
|---|---|---|---|
| `ANIM_Sword_Slash1`–`3` | Animation | TODO | `Ability:Slash1`–`3` |
| `ANIM_Sword_HeavySlash` | Animation | TODO | `Ability:HeavySlash` |
| `ANIM_Combat_Dodge` | Animation | TODO | `Ability:Dodge` |
| `ANIM_Combat_Block` | Animation | TODO | `State:Blocking` |
| `ANIM_Combat_Dash` | Animation | TODO | `Ability:Shunpo`, `Ability:Step` |
| `ANIM_Cast_Point`, `ANIM_Cast_Bind` | Animation | TODO | `Ability:Byakurai`, `Ability:Sai` |
| `ANIM_Enemy_Swipe`, `_Lunge`, `_Crush` | Animation | TODO | `Ability:EnemySwipe`, `EnemyLunge`, `EnemyCrush` |
| `ANIM_Reaction_Stun` | Animation | TODO | `State:Stunned` |
| `ANIM_Locomotion_*` (9) | Animation | INTEGRATED (catálogo Roblox, provisional) | `Locomotion` |
| `MDL_Weapon_Asauchi` | Model | TODO | `Weapon:Asauchi` |
| `MDL_Enemy_WeakHollow`, `_StandardHollow`, `_EliteHollow` | Model | TODO | Enemigos |
| `MDL_Boss_GreatHollow` | Model | TODO | Jefe |
| `VFX_Kido_Byakurai`, `VFX_Kido_Sai`, `VFX_Movement_Shunpo`, `VFX_Telegraph_Area` | VFX | TODO | `Content/Effects` |

La lista completa y actual la da Output al darle a Play en Studio (`[Assets] ... Pendientes: ...`).
