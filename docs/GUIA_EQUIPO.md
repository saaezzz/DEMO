# Guía del equipo

Cómo añadir cosas al juego **sin tocar el código de los sistemas**. Todo lo que ves en el juego
(enemigos, ataques, objetos, misiones, animaciones, efectos) sale de **datos** o de **objetos
colocados en Studio con un nombre concreto**. Los sistemas ya saben usarlos.

- **Arte y Animación** trabajan en **Studio** (constitución §55): no necesitan tocar el repositorio.
- **Diseño y Programación** editan archivos de datos en el repositorio (`src/.../Content/`).
- Si algo falta, el juego usa un **placeholder** y sigue funcionando.

---

## 1. Dónde van los assets de Arte (en Studio)

Rojo crea esta carpeta y **nunca borra lo que pongáis dentro**:

```
ReplicatedStorage
└── Assets
    ├── Animations   ← objetos Animation
    ├── Models       ← modelos de personajes, enemigos y armas
    ├── VFX          ← efectos (Model o Part con ParticleEmitters)
    └── Sounds       ← sonidos (para más adelante)
```

**La regla de oro:** el objeto debe llamarse **exactamente** como su entrada en el manifiesto
(`src/Shared/Content/Assets.luau`, tabla en [ASSETS.md](ASSETS.md)). Ejemplos: `ANIM_Sword_Slash1`,
`MDL_Weapon_Asauchi`, `VFX_Kido_Byakurai`.

**Cómo comprobarlo:** dale a Play en Studio y mira **Output**. Aparece un informe `[Assets]`:
- `N de M assets listos. Pendientes: …` → lo que aún falta (se usa placeholder).
- `Assets/Models/XXX no está en el manifiesto (¿nombre mal escrito?)` → revisa el nombre.
- `XXX es de tipo Animation: muévelo a Assets/Animations` → está en la carpeta equivocada.

Después de colocar algo, **guarda y publica el lugar** (el arte vive en el lugar, no en el repo).

---

## 2. Arte / Builder: modelos

### Enemigos y jefes
1. Un **rig R15** con `Humanoid` y `HumanoidRootPart` (como un personaje de Roblox).
2. Nómbralo como su entrada del manifiesto (p. ej. `MDL_Enemy_WeakHollow`) y ponlo en `Assets/Models`.
3. Ya está: los enemigos de ese tipo aparecerán con tu modelo (usa las animaciones del juego).
   Si al modelo le falta el Humanoid o el HumanoidRootPart, Output lo avisa y se usa el provisional.

### Armas
1. Un `Model` con una pieza llamada **`Handle`** (el mango, por donde se sujeta).
2. La hoja apunta hacia **-Z** de la pieza Handle (hacia delante).
3. Nómbralo como su entrada (`MDL_Weapon_Asauchi`) y ponlo en `Assets/Models`.
4. El juego suelda todas sus piezas al Handle y el Handle a la mano derecha (o a la parte del cuerpo que
   diga su `AttachTo`: el arco va en la **mano izquierda** y la máscara Hollow en la **cabeza**, con la
   cara hacia -Z). Si queda mal colocada, se ajusta el `Grip` en `src/Shared/Content/Weapons.luau`
   (pídeselo a Programación).

---

## 3. Animación / Visual: animaciones

1. Anima en el Animation Editor con un rig R15 y **publica** la animación.
2. Crea un objeto `Animation` en `Assets/Animations`, ponle el `AnimationId` publicado y el nombre
   exacto de su entrada (p. ej. `ANIM_Sword_Slash1`).
3. En cuanto está, sustituye a la animación provisional (sin tocar código).

**Markers:** los ataques necesitan un Keyframe Marker **`Hit`** en el frame del impacto (las notas del
manifiesto dicen cuándo, p. ej. "Marker 'Hit' a 0,2 s"). Si el impacto no cae en ese tiempo, avisad a
Programación para ajustar el golpe (`StartTime` en `Server/Content/Abilities.luau`).

**Ataques solo de cintura para arriba:** anima solo torso, brazos y cabeza (sin caderas ni piernas) y usa
prioridad **Action**. Así las piernas siguen corriendo mientras atacas.

**Locomoción** (quieto, andar, correr, saltar, caer, trepar, nadar): `ANIM_Locomotion_*`. Ahora mismo se
usa el pack Ninja de Roblox; si colocáis las vuestras con esos nombres, lo sustituyen.
No añadáis scripts de animación propios (p. ej. un "LocomotionAnimate" de un kit): chocarían con el
sistema de velocidad y sprint del servidor. Basta con colocar las animaciones.

---

## 4. Animación / Visual: efectos (VFX)

1. Un `Model` o una `Part` con `ParticleEmitter`s (y lo que queráis: Beams, luces...).
2. Orientación: **hacia delante es -Z** (un rayo sale hacia -Z desde el personaje).
3. Nómbralo como su entrada (p. ej. `VFX_Kido_Byakurai`) y ponlo en `Assets/VFX`.
4. **Auras** (efectos `VFX_..._Hierro`, `BlutVene`, `BlutArterie`): se sueldan al personaje mientras
   dura el potenciador. Usad emisores **en continuo** (Enabled), no ráfagas; el juego los borra al acabar.
5. Opcional, como **atributos**:
   - En cada `ParticleEmitter`: `EmitCount` (partículas que lanza, 20 por defecto).
   - En el objeto: `Lifetime` (segundos antes de borrarse; por defecto duración + 2 s).

Dónde y cuándo sale cada efecto lo dicen `src/Shared/Content/Effects.luau` y `AbilityInfo.luau`.

---

## 5. Diseño / Programación: añadir contenido con datos

Cada tipo de contenido es una tabla en su archivo. Copia una entrada existente y cambia los valores.
Después, `lune run tests/runner`: los tests de contenido avisan si algo no cuadra (un ataque que no
existe, un color mal escrito, un aviso de área que no coincide con el golpe...).

| Quiero añadir… | Archivo | Notas |
|---|---|---|
| Un ataque, técnica o movimiento | `src/Server/Content/Abilities.luau` | Estado, requisitos, daño, hitbox, coste, cooldown, movimiento, animación |
| Su nombre y efectos visuales | `src/Shared/Content/AbilityInfo.luau` | Lo que ve el jugador en la barra |
| Un efecto visual | `src/Shared/Content/Effects.luau` | Provisional (rayo, estallido, círculo) + asset `VFX_` |
| Qué ataques usa una raza | `src/Shared/Content/Movesets.luau` | Cadena M1, pesado, esquiva, dash y hasta 4 técnicas |
| Una raza o su kit | `src/Shared/Content/Races.luau` | Moveset, arma, objetos iniciales; `Playable = true` para abrirla |
| Un hito de raza (evolución, desbloqueos) | `src/Shared/Content/Races.luau` (`Milestones`) | Nivel + estadísticas mínimas → técnicas nuevas (máx. 4 en la barra) |
| Una estadística que cuenta un hito | `src/Shared/Content/Stats.luau` | Nombre visible; la suman los golpes con `KillStat` |
| Un potenciador (menos daño recibido, más daño hecho) | `src/Server/Content/Abilities.luau` (`SelfModifier`) | Y un efecto `Aura` con la misma duración |
| Una zona de Reishi ambiental | `src/Server/Content/AmbientZones.luau` | Centro, radio y densidad |
| Un arma | `src/Shared/Content/Weapons.luau` | Modelo `MDL_`, posición en la mano, hoja provisional |
| Un enemigo o jefe | `src/Server/Content/Enemies.luau` | Vida, aggro, ataques con aviso, EXP, botín, fases |
| Dónde aparecen los enemigos | `src/Server/Content/EnemySpawns.luau` | Posición, cantidad, radio, reaparición |
| Un objeto | `src/Shared/Content/Items.luau` | Categoría, rareza, pila máxima, efecto si es consumible |
| Una misión | `src/Shared/Content/Quests.luau` | Objetivos, marcador, recompensa, misión siguiente |
| Un asset nuevo | `src/Shared/Content/Assets.luau` | Nombre `PREFIJO_Grupo_Nombre`, estado `TODO` y notas para Arte |
| Balance general | `src/Server/Config/*`, `src/Shared/Config/*` | Parry, bloqueo, velocidades, curva de EXP, rarezas |

**Nombres de la IP** (razas, técnicas, enemigos…) solo en archivos de carpetas `Content`
(constitución §4). Un test lo comprueba.

---

## 6. Lista rápida antes de publicar el lugar
- [ ] El objeto se llama exactamente como en el manifiesto y está en su carpeta.
- [ ] Output no muestra avisos `[Assets]` de nombres o carpetas.
- [ ] Los ataques nuevos tienen su marker `Hit`.
- [ ] Probado con Play (y, si es de combate, contra los muñecos de entrenamiento).
