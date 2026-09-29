# Assets

Constitución §54 y D-020. El manifiesto `src/Shared/Content/Assets.luau` es la **única fuente de verdad**
de los IDs de Roblox: ningún sistema escribe un `rbxassetid://` a mano.

## Convención de nombres
`<PREFIJO>_<Grupo>_<Nombre>`, con `Grupo` y `Nombre` en PascalCase, sin espacios ni guiones.

| Categoría | Prefijo | Ejemplo |
|---|---|---|
| Animation | `ANIM` | `ANIM_Sword_BasicSlash` |
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
| `UsedBy` | Qué lo usa (p. ej. `Combo:BasicSlash`) |
| `Notes` | Indicaciones para quien lo crea (duración, markers, estilo...) |

## Flujo de estados
`TODO` → `IN_PROGRESS` → `REVIEW` → `APPROVED` → `INTEGRATED` (y `BLOCKED` si algo lo impide).
Un asset `APPROVED` o `INTEGRATED` debe tener `AssetId` (lo comprueba un test).

## Alta de un asset nuevo
1. El Lead Programmer añade la entrada al manifiesto con `Status = "TODO"` y las notas necesarias.
2. Arte/Animación lo crea en Blender/Studio con ese nombre exacto y lo sube a Roblox.
3. Se rellena `AssetId`, se sube `Version` y se cambia el estado.
4. `lune run tests/runner ContentIntegrity` valida nombres, estados, IDs y dependencias.

## Assets actuales
| Nombre | Categoría | Estado | Usado por |
|---|---|---|---|
| `ANIM_Sword_BasicSlash` | Animation | TODO | `Combo:BasicSlash` |
