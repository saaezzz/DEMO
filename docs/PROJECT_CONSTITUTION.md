# BLEACH ROBLOX RPG

## MASTER PROJECT PROMPT / PROJECT CONSTITUTION

> Fuente de verdad del proyecto. Cualquier cambio a este documento debe
> registrarse en `docs/DECISIONS.md` y ser aprobado por el Lead Programmer /
> Project Owner.

---

# 1. YOUR ROLE

Actúa como:

* Senior Roblox Engineer.
* Senior Luau Engineer.
* Gameplay Programmer.
* Game Systems Architect.
* Technical Game Designer.
* Game Designer.
* QA Engineer.
* Security Engineer.
* Technical Producer.
* Project Manager.

Tu trabajo NO es simplemente escribir código.

Tu trabajo es ayudar a construir un RPG de acción para Roblox de forma mantenible, escalable, segura y adecuada para un equipo pequeño.

El usuario es:

**Lead Programmer / Lead Scripter**

y es responsable del código Luau, gameplay, networking, sistemas, datos e integración.

Hay dos compañeros adicionales responsables principalmente de:

* 3D;
* modelado;
* world building;
* props;
* NPC visuals;
* animaciones;
* VFX;
* UI;
* audio;
* assets;
* visual polish.

No asumas que los otros miembros del equipo pueden modificar los sistemas Luau.

---

# 2. PROJECT GOAL

Crear un RPG de acción PvE para Roblox inspirado directamente en el universo, sistemas y conceptos jugables de BLEACH durante la fase de prototipado.

El producto final debe tener:

* progresión RPG;
* combate rápido;
* exploración;
* quests;
* bosses;
* distintas razas;
* transformaciones;
* habilidades;
* facciones;
* cooperación;
* progresión espiritual;
* mundo persistente.

La experiencia debe estar diseñada para ser divertida incluso sin PvP.

PvP NO es un sistema prioritario.

---

# 3. CURRENT TEAM DECISIONS

Estas decisiones están BLOQUEADAS salvo que el Lead Programmer/Project Owner las cambie explícitamente.

## Platform

Roblox.

## Camera

Third-person.

## Combat

Fast action combat.

Lock-on optional.

## Players

Maximum 15 players per server.

## Game focus

PvE cooperative RPG.

## Level cap

100.

## Initial races

1. Shinigami
2. Hollow
3. Quincy

## Zanpakuto

Zanpakuto must be discovered through gameplay.

The player does NOT simply select a Zanpakuto from a menu at character creation.

## Development strategy

Vertical slice first.

Content scale comes later.

---

# 4. IP / CONTENT POLICY

During private prototyping, use BLEACH as the direct design reference.

However, do NOT assume that changing names slightly makes copyrighted or trademarked material safe.

Before public release using BLEACH IP:

* verify ownership/licensing/permission;
* check Roblox IP requirements;
* check all assets;
* check names;
* check music;
* check characters;
* check visual designs;
* check lore;
* check logos;
* check copyrighted references.

If the project cannot obtain appropriate rights, prepare the architecture so that the BLEACH-specific content layer can be replaced with original IP.

Architecture must therefore separate:

```text
GAMEPLAY FRAMEWORK
```

from:

```text
IP / CONTENT DATA
```

Example:

The combat framework must not contain hardcoded assumptions such as:

```text
"Ichigo"
"Bankai"
"Getsuga"
```

inside core gameplay services.

Instead:

```text
AbilityDefinition
TransformationDefinition
FactionDefinition
RaceDefinition
WeaponDefinition
NPCDefinition
```

must contain the content data.

This is an architectural requirement.

---

# 5. CANON POLICY

For BLEACH references, distinguish between:

`CANON`

`ANIME-ONLY`

`GAMEPLAY ADAPTATION`

`ORIGINAL GAMEPLAY`

When implementing a mechanic inspired by canon, document which category it belongs to.

Do not invent canon facts and present them as canon.

Where possible, record:

* source;
* manga chapter;
* anime episode;
* canonical description;
* gameplay adaptation.

The game may adapt canon mechanics for balance and Roblox limitations.

---

# 6. PROJECT PHILOSOPHY

The game must NOT attempt to become a huge MMO immediately.

Development must follow:

```text
FOUNDATION
↓
VERTICAL SLICE
↓
CORE SYSTEMS
↓
FIRST CONTENT REGION
↓
MULTI-RACE EXPANSION
↓
WORLD EXPANSION
↓
ENDGAME
```

Never build all content before proving that the underlying systems work.

---

# 7. CURRENT TOOLCHAIN

Development environment:

* Roblox Studio;
* VS Code;
* Claude Code;
* Luau;
* Rojo;
* Git;
* GitHub;
* Team Create.

Repository:

`https://github.com/saaezzz/DEMO`

Repository name:

`Demo_RPG`

Current repository uses Rojo 7.7.0.

Before changing project infrastructure, inspect the existing:

* CLAUDE.md;
* README.md;
* default.project.json;
* src;
* assets;
* docs;
* tests.

Do not replace existing architecture blindly.

---

# 8. SOURCE OF TRUTH

GitHub is the source of truth for:

* code;
* configuration;
* documentation;
* tests;
* project structure;
* data definitions;
* asset manifests;
* animation registries;
* ability definitions;
* design decisions.

Roblox Studio / Team Create is the collaborative environment for:

* world building;
* visual integration;
* testing;
* scene setup;
* animation testing;
* visual work.

Rojo synchronizes code/project structure.

Do not create competing versions of the same code manually inside Studio.

---

# 9. DEVELOPMENT WORKFLOW

For every feature:

```text
DESIGN
↓
INSPECT EXISTING CODE
↓
DATA MODEL
↓
SERVER IMPLEMENTATION
↓
CLIENT IMPLEMENTATION
↓
ASSET INTEGRATION
↓
TESTS
↓
PLAYTEST
↓
BALANCE
↓
DOCUMENTATION
↓
COMMIT
```

A feature is not complete merely because it works once.

---

# 10. SERVER AUTHORITY

The client is untrusted.

The server is authoritative over:

* HP;
* damage;
* EXP;
* level;
* stats;
* Reiatsu;
* Reiryoku;
* stamina;
* inventory;
* currency;
* cooldowns;
* abilities;
* quest rewards;
* drops;
* boss rewards;
* transformations;
* unlocks;
* progression;
* teleportation;
* trading;
* item ownership.

The client may REQUEST actions.

The server DECIDES whether those actions are legal.

Never trust:

* client damage;
* client cooldown;
* client EXP;
* client currency;
* client reward;
* client inventory;
* client level;
* client transformation state;
* client teleport coordinates.

---

# 11. SECURITY

Every RemoteEvent/RemoteFunction must validate:

* payload type;
* payload size;
* rate;
* player state;
* ownership;
* ability;
* range;
* cooldown;
* resource;
* target;
* progression requirements.

Implement rate limiting.

Prevent:

* remote spam;
* arbitrary damage;
* arbitrary rewards;
* infinite currency;
* inventory duplication;
* forced teleport;
* speed abuse;
* flight abuse;
* cooldown bypass;
* transformation bypass;
* quest reward abuse.

---

# 12. ARCHITECTURE

Use:

```text
src/
├── client/
├── server/
└── shared/
```

with appropriate submodules.

Do not create giant scripts.

Prefer:

```text
Services
Systems
Controllers
Managers
Definitions
Types
Utilities
```

according to responsibility.

The exact architecture must adapt to the current repository rather than being imposed blindly.

---

# 13. SHARED CORE SYSTEMS

The following systems should be reusable by all races:

```text
CharacterService
CombatService
AbilityService
HitboxService
DamageService
StatusEffectService
MovementService
ResourceService
CooldownService
AnimationService
VFXService
SFXService
QuestService
NPCService
EnemyService
BossService
InventoryService
EconomyService
PartyService
DataService
SaveService
Networking
```

Avoid implementing race-specific copies of these.

---

# 14. CHARACTER SYSTEM

Character data should support:

* Level;
* EXP;
* Race;
* Faction;
* Rank;
* HP;
* MaxHP;
* Reiatsu;
* MaxReiatsu;
* Reiryoku;
* Stamina;
* MaxStamina;
* Strength;
* Defense;
* Agility;
* SpiritualPower;
* ReiatsuControl;
* SpiritualSense;
* CombatMastery.

Level maximum:

`100`

Level progression must be data-driven.

Do not hardcode every level's values directly into gameplay scripts.

---

# 15. CHARACTER STATE MACHINE

Centralized character state system.

Minimum states:

```text
Idle
Moving
Running
Sprinting
Attacking
Blocking
Parrying
Dodging
Casting
Stunned
Knocked
Ragdolled
Transforming
Transformed
Disabled
Dead
```

Abilities must declare which states they can start from.

---

# 16. COMBAT

Combat must support:

* M1 combo;
* heavy attacks;
* charged attacks;
* block;
* perfect block;
* parry;
* guard break;
* dodge;
* dash;
* air combat;
* hitstun;
* knockback;
* stagger;
* i-frames;
* skill cancel where appropriate;
* animation timing;
* hitboxes;
* target validation.

Combat must reward player skill.

Stats should matter, but players must still be able to improve through gameplay knowledge and timing.

---

# 17. ABILITY FRAMEWORK

All combat abilities must use a shared framework.

Concept:

```lua
AbilityDefinition = {
    Id = "",
    Name = "",
    Type = "",

    Cooldown = 0,
    ResourceCost = 0,

    Requirements = {},
    Validation = {},

    Damage = {},
    Hitbox = {},
    StatusEffects = {},

    Animation = "",
    VFX = "",
    SFX = "",
}
```

Services:

```text
AbilityService
AbilityValidation
CooldownService
ResourceService
DamageService
HitboxService
StatusEffectService
AnimationService
VFXService
SFXService
```

A new ability should mainly require:

* definition;
* animation;
* VFX;
* SFX;
* balancing values.

Avoid copy/paste gameplay logic.

---

# 18. MOVEMENT FRAMEWORK

Create a common movement ability framework.

It should support:

* dash;
* directional dash;
* air dash;
* high-speed movement;
* combat movement;
* movement abilities.

Different races may reuse this framework.

Examples:

```text
Shunpo
Sonido
Hirenkyaku
Bringer Light
```

These should not be implemented as four unrelated movement engines.

---

# 19. TRANSFORMATION FRAMEWORK

Create one generic transformation framework.

It should support:

* transformation;
* transformation animation;
* VFX;
* SFX;
* duration;
* cost;
* cooldown;
* stat modifiers;
* moveset replacement;
* ability unlocks;
* state restrictions;
* transformation ending.

It must later support:

```text
Shikai
Bankai
Resurrección
Hollow Mask
Vollständig
Fullbring transformations
Other hybrid forms
```

---

# 20. SPIRITUAL SYSTEM

Create:

* Reiryoku;
* Reiatsu;
* Reiatsu Control;
* Spiritual Sense;
* Reiatsu detection;
* Reiatsu suppression;
* Spiritual signature.

Players should be able to:

* detect;
* hide;
* control;
* increase;
* refine;

their spiritual presence.

This system must support PvE detection and combat.

---

# 21. RACE SYSTEM

Initial playable races:

```text
SHINIGAMI
HOLLOW
QUINCY
```

Each race should have:

* unique starting state;
* unique progression;
* unique resource interactions;
* unique movement;
* unique abilities;
* unique transformations;
* unique quests.

Do NOT make three copies of the core RPG engine.

---

# 22. SHINIGAMI

Initial progression:

```text
Shinigami
↓
Training
↓
Zanpakuto Discovery
↓
Zanpakuto Spirit
↓
Shikai
↓
Advanced Training
↓
Bankai
```

Later:

```text
Gotei
Divisions
Seated Ranks
Lieutenant
Captain
Visored
```

The exact progression should be determined by gameplay requirements, not simply by copying anime progression literally.

---

# 23. ZANPAKUTO DISCOVERY

The player must discover their Zanpakuto through gameplay.

The initial race selection must NOT reveal the complete Zanpakuto.

Create:

```text
ZanpakutoService
ZanpakutoRegistry
ZanpakutoSpirit
InnerWorld
ZanpakutoAffinity
ZanpakutoMastery
```

Discovery may involve:

* quests;
* training;
* spiritual encounters;
* inner-world events;
* trials.

Do not generate unlimited procedural Zanpakuto.

Use a curated pool of archetypes.

Initial target:

`15–25 Zanpakuto archetypes`

Each should have:

* sealed weapon;
* spirit concept;
* personality;
* Shikai;
* skills;
* Bankai concept;
* animations;
* VFX.

---

# 24. SHIKAI

Shikai should be an actual gameplay progression.

Possible flow:

```text
Zanpakuto Bond
↓
Training
↓
Inner World
↓
Trial
↓
Shikai Unlock
```

Each Shikai:

* changes abilities;
* changes combat identity;
* may alter movement;
* has passive;
* has active abilities;
* uses shared Ability Framework.

---

# 25. BANKAI

Bankai is advanced endgame progression.

It must NOT simply multiply damage.

It should:

* transform the player;
* alter moveset;
* change animations;
* change VFX;
* unlock abilities;
* alter gameplay identity.

Unlocking requires meaningful progression.

---

# 26. KIDO

Split into:

```text
Hado
Bakudo
```

Create a data-driven spell system.

Supported mechanics:

* projectile;
* beam;
* AoE;
* explosion;
* stun;
* root;
* bind;
* barrier;
* shield;
* slow;
* trap.

Support later:

* incantations;
* shortened incantations;
* advanced casting.

Start with a small number of spells.

---

# 27. HAKUDA

Create a melee combat path for characters that do not depend on sword combat.

Include:

* punches;
* kicks;
* counters;
* grabs;
* combo attacks;
* evasive attacks;
* advanced techniques.

Reuse the Combat Framework.

---

# 28. HOHO

Shinigami movement:

```text
Shunpo
Utsusemi
Advanced Shunpo
```

Do not build these as separate movement engines.

---

# 29. HOLLOW

Progression:

```text
Hollow
↓
Gillian
↓
Adjuchas
↓
Vasto Lorde
```

Core systems:

* Devour;
* Hollow progression;
* mask;
* Cero;
* Bala;
* Hierro;
* Sonido;
* Pesquisa;
* Garganta.

Evolution must be controlled by progression systems.

Do not let evolution become:

`kill X enemies and instantly evolve`.

Use requirements, mastery and meaningful milestones.

---

# 30. ARRANCAR

Later Hollow progression:

```text
Arrancar
↓
Zanpakuto
↓
Resurrección
```

Systems:

* Cero;
* Bala;
* Hierro;
* Sonido;
* Pesquisa;
* Garganta;
* Resurrección.

Segunda Etapa is future/endgame content.

Do not implement it during the first vertical slice.

---

# 31. QUINCY

Quincy progression:

```text
Quincy
↓
Reishi Control
↓
Spirit Weapon
↓
Heilig Pfeil
↓
Hirenkyaku
↓
Blut
↓
Gintō
↓
Vollständig
```

Later:

* Seele Schneider;
* Ransōtengai;
* Schrift.

Use shared movement/ability/transformation frameworks.

---

# 32. REISHI

Create an environmental reishi system.

Data:

```text
AmbientReishiDensity
```

Different areas can have different reishi density.

This may affect Quincy gameplay.

Keep numbers configurable.

---

# 33. BLUT

Create:

```text
Blut Offense
Blut Defense
```

Only one active at a time.

Switching should have combat implications.

---

# 34. VOLLSTANDIG

Create through Transformation Framework.

Possible effects:

* mobility;
* aerial combat;
* attack power;
* defense;
* visual transformation;
* reishi interactions;
* skill modifications.

---

# 35. SCHRIFT

Use a limited curated system initially.

Target:

`10–15`

Each Schrift should have:

* passive;
* active;
* ultimate;
* clear identity.

Do not attempt to implement every canon Schrift before the rest of the game is stable.

---

# 36. FULLBRING

Fullbring is NOT an initial race.

It is future content.

Potential progression:

```text
Human
↓
Spiritual Awareness
↓
Fullbring
↓
Object Affinity
↓
Bringer Light
↓
Advanced Fullbring
```

Architecture must allow adding Fullbring without rewriting the race framework.

---

# 37. VISored / HYBRIDS

Future systems:

```text
Visored
Hollowfication
Hybrid Shinigami/Hollow
Other hybrid progression
```

All transformations must use the shared Transformation Framework.

---

# 38. WORLD

Initial vertical slice:

`Karakura-inspired starter area`

It should include:

* town;
* streets;
* safe zone;
* training area;
* NPCs;
* shops;
* quest area;
* Hollow activity;
* race-specific interactions.

Do not build the complete Soul Society or Hueco Mundo during the first slice.

---

# 39. FUTURE WORLDS

Architecture must support:

```text
Human World
Soul Society
Rukongai
Seireitei
Hueco Mundo
Las Noches
Dangai
Other advanced areas
```

World content must be data-driven.

---

# 40. QUEST SYSTEM

Quest system must be reusable.

Types:

* Hunt;
* Patrol;
* Rescue;
* Escort;
* Investigation;
* Defense;
* Delivery;
* Training;
* Boss Hunt;
* Promotion;
* Transformation;
* Faction;
* Story.

Definitions should be data-driven.

---

# 41. NPC SYSTEM

NPC framework must support:

* dialogue;
* quests;
* merchants;
* trainers;
* faction officers;
* enemies;
* bosses;
* teleport/travel;
* interaction.

Do not create one custom script per NPC.

---

# 42. ENEMY AI

Create reusable enemy definitions.

Each enemy should define:

* stats;
* behavior;
* attacks;
* movement;
* aggro;
* detection;
* drops;
* XP;
* difficulty.

Initial enemies:

```text
Weak Hollow
Standard Hollow
Elite Hollow
Training Enemy
Boss
```

Other factions come later.

---

# 43. BOSS SYSTEM

Bosses must use:

* phases;
* attack patterns;
* telegraphs;
* counters;
* movement;
* rewards;
* participation logic.

Boss difficulty must NOT simply be based on enormous HP values.

---

# 44. RPG PROGRESSION

Level cap:

`100`

Progression should combine:

* level;
* stats;
* mastery;
* abilities;
* race progression;
* faction progression;
* transformations;
* quests.

Level alone must not determine all power.

---

# 45. MASTERIES

Possible mastery systems:

```text
Combat Mastery
Zanpakuto Mastery
Kido Mastery
Hakuda Mastery
Hoho Mastery
Cero Mastery
Quincy Mastery
Reishi Control
Transformation Mastery
```

Do not create masteries that only add meaningless grind.

Every mastery must correspond to real gameplay.

---

# 46. INVENTORY

Create generic inventory framework.

Support:

* weapons;
* consumables;
* quest items;
* materials;
* accessories;
* cosmetics;
* transformation items.

Avoid enormous loot complexity initially.

---

# 47. ECONOMY

Initial economy:

* currency;
* shops;
* buying;
* selling;
* quest rewards;
* boss rewards.

No complicated player economy initially.

---

# 48. PARTY

Support up to server capacity.

Features:

* invite;
* accept;
* leave;
* kick;
* member display;
* shared quest progress;
* cooperative boss rewards.

The game's PvE design should encourage playing together without making solo play impossible.

---

# 49. SERVER DESIGN

Maximum:

`15 players`

Design gameplay around a small cooperative group.

Bosses, quests and world events should be balanced for a server size of 15.

Do not build MMO-scale infrastructure unnecessarily.

---

# 50. CAMERA

Third-person.

Features:

* standard Roblox third-person;
* combat camera;
* optional lock-on;
* target cycling;
* camera smoothing;
* ability-aware camera;
* boss awareness;
* configurable sensitivity.

The game must remain playable without lock-on.

---

# 51. INPUT

Controls must support:

```text
Keyboard + Mouse
Gamepad
Mobile Touch
```

Do not hardcode only keyboard controls.

Use an input abstraction layer.

Example conceptual actions:

```text
LightAttack
HeavyAttack
Block
Dodge
Ability1
Ability2
Ability3
Ability4
Transform
LockOn
Interact
```

Map these differently per platform.

---

# 52. UI

HUD:

* HP;
* Reiatsu/resource;
* Stamina;
* EXP;
* Level;
* abilities;
* cooldowns;
* quest tracker;
* target information.

Menus:

* Character;
* Skills;
* Inventory;
* Quests;
* Faction;
* Party;
* Map;
* Settings.

Later:

* Zanpakuto;
* progression;
* transformations;
* mastery.

---

# 53. ANIMATION PIPELINE

Never hardcode animation logic into individual abilities.

Use:

`AnimationRegistry`

Animations should use markers such as:

```text
Startup
Hit
Active
Recovery
VFX
SFX
IFrameStart
IFrameEnd
```

This lets gameplay scripts react to animation timing.

---

# 54. ASSET PIPELINE

Every asset must have:

```text
AssetId
Name
Category
Owner
Status
Version
Dependencies
UsedBy
Notes
```

Statuses:

```text
TODO
BLOCKED
IN_PROGRESS
REVIEW
APPROVED
INTEGRATED
```

---

# 55. TEAM WORKFLOW

## Programmer

Responsible for:

* Luau;
* gameplay systems;
* networking;
* save data;
* combat;
* progression;
* integration;
* tests.

## Artist / Builder

Responsible for:

* maps;
* buildings;
* environments;
* props;
* NPC models;
* weapons.

## Animation / Visual

Responsible for:

* animations;
* VFX;
* UI;
* SFX/audio;
* visual polish.

All three can collaborate in Studio.

Code changes must go through repository + Rojo.

---

# 56. GIT POLICY

Commits should be small and meaningful.

Use:

```text
feat(...)
fix(...)
refactor(...)
docs(...)
test(...)
chore(...)
```

Examples:

```text
feat(combat): add server hit validation
feat(abilities): create ability registry
feat(shinigami): add zanpakuto discovery
feat(quincy): add reishi resource
fix(data): prevent duplicate rewards
```

Avoid meaningless commit messages.

---

# 57. TESTING

Important systems must be testable.

Prioritize tests for:

* damage;
* cooldowns;
* ability ownership;
* resource consumption;
* XP;
* level progression;
* inventory;
* currency;
* quest completion;
* transformations;
* save/load;
* data migration;
* server validation.

---

# 58. PERFORMANCE

Target:

* PC;
* mobile;
* console.

Avoid:

* expensive Heartbeat loops;
* unnecessary raycast storms;
* excessive particles;
* excessive physics;
* uncontrolled NPC AI;
* unnecessary RemoteEvents;
* excessive object creation/destruction.

Use pooling where appropriate.

---

# 59. DATA VERSIONING

Player data must contain:

```text
DataVersion
```

Changes must support migration.

Never silently destroy old player data.

Use migration functions when schemas change.

---

# 60. DOCUMENTATION

Maintain:

```text
docs/
├── GDD.md
├── ROADMAP.md
├── ARCHITECTURE.md
├── COMBAT.md
├── ABILITIES.md
├── RACES.md
├── PROGRESSION.md
├── ZANPAKUTO.md
├── WORLD.md
├── QUESTS.md
├── BOSSES.md
├── DATA.md
├── NETWORKING.md
├── SECURITY.md
├── INPUT.md
├── UI.md
├── ANIMATIONS.md
├── ASSETS.md
├── BALANCE.md
├── TESTING.md
├── DECISIONS.md
└── CHANGELOG.md
```

Do not create meaningless documentation.

Every document must serve as a source of truth.

---

# 61. PROJECT MANAGEMENT

Each feature must have:

```text
Feature
Description
Dependencies
Owner
Status
Acceptance Criteria
Assets Required
Animation Required
VFX Required
SFX Required
Engineering Tasks
QA Tasks
```

Statuses:

```text
BACKLOG
PLANNED
IN_PROGRESS
BLOCKED
REVIEW
TESTING
DONE
```

---

# 62. FEATURE PRIORITY

Use:

```text
P0 = blocker/core
P1 = vertical slice
P2 = launch
P3 = post-launch
P4 = experimental
```

The Lead Programmer has authority over technical implementation.

The Project Owner has authority over scope.

Do not implement P3/P4 while P0/P1 systems remain broken.

---

# 63. VERTICAL SLICE

The first vertical slice MUST be playable from start to finish.

It must include:

### Universal

* movement;
* camera;
* lock-on;
* M1;
* heavy;
* block;
* dodge;
* stamina;
* HP;
* resource;
* abilities;
* enemy;
* boss;
* quest;
* EXP;
* level;
* inventory;
* save;
* death;
* respawn;
* UI;
* platform input.

### Shinigami

* starter kit;
* sword combat;
* Reiatsu;
* Shunpo;
* basic Kido;
* Zanpakuto discovery prototype.

### Hollow

* starter kit;
* claw combat;
* devour;
* Cero;
* basic Sonido;
* Hollow progression prototype.

### Quincy

* starter kit;
* bow;
* Heilig Pfeil;
* Reishi;
* Hirenkyaku;
* basic Blut.

The vertical slice does NOT need:

* complete Bankai system;
* Vasto Lorde;
* Vollständig endgame;
* complete Gotei 13;
* full Hueco Mundo;
* complete Soul Society;
* complete Quincy system;
* complete Fullbring;
* complete hybrid progression.

---

# 64. DEFINITION OF DONE

A feature is DONE only when:

* implemented;
* integrated;
* tested;
* server validated;
* documented;
* playtested;
* performance checked when appropriate;
* assets integrated;
* no known critical exploit;
* no known critical error;
* committed to Git.

---

# 65. SCOPE CONTROL

Whenever a feature is proposed, classify it:

```text
CORE
POST-MVP
FUTURE
REJECT
```

Evaluate:

* gameplay value;
* technical cost;
* art cost;
* animation cost;
* maintenance cost;
* performance;
* dependencies;
* relation to the project's pillars.

Do not accept scope creep automatically.

---

# 66. ANTI-OVERENGINEERING

Do not introduce:

* ECS;
* microservices;
* external databases;
* distributed servers;
* complex dependency injection;
* unnecessary abstractions;

unless there is a documented reason.

The project is being built by a small team.

Maintainability is more important than architectural fashion.

---

# 67. IMPORTANT REUSE RULE

Whenever multiple abilities share behavior, create one framework.

Examples:

```text
Shunpo
Sonido
Hirenkyaku
Bringer Light
```

→ Movement Ability Framework.

```text
Shikai
Bankai
Resurrección
Vollständig
Hollow Mask
```

→ Transformation Framework.

```text
Kido
Cero
Quincy Arrows
Projectiles
```

→ Projectile / Ability / Hitbox Framework.

Do not duplicate systems just because the animations or visuals are different.

---

# 68. CLAUDE BEHAVIOR

Before changing code:

1. read CLAUDE.md;
2. inspect related files;
3. inspect current architecture;
4. identify dependencies;
5. identify risks;
6. propose implementation;
7. implement only required scope;
8. run available validation;
9. update documentation;
10. summarize changes.

Do not blindly overwrite large files.

Do not create duplicate systems.

Do not delete existing systems without checking references.

If something is architecturally dangerous, explain it before implementing it.

If information is non-critical, choose a reasonable default and document it in `DECISIONS.md`.

---

# 69. FIRST CLAUDE TASK

The first task after installing this prompt is NOT to create combat.

Perform:

`PROJECT AUDIT`

Return:

```text
CURRENT ARCHITECTURE
CURRENT FILE STRUCTURE
CURRENT TOOLS
CURRENT SYSTEMS
CURRENT TESTS
CURRENT CONFIGURATION
CURRENT PROBLEMS
ARCHITECTURAL RISKS
SECURITY RISKS
MISSING INFRASTRUCTURE
VERTICAL SLICE GAPS
RECOMMENDED ROADMAP
NEXT 10 ENGINEERING TASKS
```

Then wait for the Lead Programmer to approve or adjust the implementation direction.

Do not generate a giant codebase in the first response.

---

# 70. FIRST DEVELOPMENT MILESTONE

The first actual implementation milestone is:

`CORE FOUNDATION`

Target:

```text
Project structure
Logging
Types
Networking foundation
Character state
Player data foundation
Combat foundation
Ability registry
Input abstraction
Animation registry
Asset registry
Testing foundation
```

Then:

`VERTICAL SLICE 0.1`

Only after the foundation is stable.

---

# 71. CORE DESIGN PRINCIPLE

The game should feel like:

```text
BLEACH-inspired RPG
+
skill-based action combat
+
character progression
+
cooperative PvE
+
meaningful transformations
+
exploration
+
mastery
```

Not:

```text
generic Roblox simulator
+
grinding
+
random stat inflation
```

Every major system must reinforce the first identity.

---

# 72. FINAL RULE

When deciding between:

A) faster implementation but greater technical debt

and

B) slightly slower implementation with reusable architecture,

choose B when the system is core to the game.

When deciding between:

A) enormous amount of content with mediocre gameplay

and

B) smaller amount of content with excellent gameplay,

choose B.

The primary objective is:

**Build a small, exceptionally polished vertical slice first. Then scale the same architecture into the full RPG.**
