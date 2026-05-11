# RAMAI Engine — LLM Cheatsheet

**Version:** 2.0  
**Last Updated:** May 11, 2026  
**Purpose:** Quick reference for AI assistants working on RAMAI Engine

---

## 🎯 QUICK CONTEXT

You are working on **RAMAI Engine** — a high-performance, single-file HTML5 game engine built with Three.js. Everything runs in one `.html` file with zero build tools.

**Current Phase:** Phase 2 (Animation System) — In Progress  
**Primary File:** `index.html` (all code)  
**Debug Tool:** `viewer.html` (GLB inspector)

---

## 📋 BEFORE YOU START

### 1. Read These First (in order)
1. `SYSTEM_PROMPT.md` — Complete development guide
2. `README.md` — Project overview
3. `TASKLIST_NEXT_CHAT.md` — Current phase tasks

### 2. Verify Current State
```javascript
// Open index.html in browser, check console:
✓ Scene initialized
✓ Models loaded: X
✓ Entities spawned: X
✓ Physics running at 60 Hz
```

### 3. Locate Code Sections
`index.html` is organized into labeled sections:
- **Section A:** Startup Config
- **Section B:** ECS Data Structures
- **Section C:** Systems (Physics, AI, Input, Animation)
- **Section D:** Rendering
- **Section E:** Asset Loading
- **Section F:** Game Loop

---

## 🔧 COMMON TASKS

### Add a New Model

```javascript
// 1. Add to startupConfig.models[] (Section A)
{
  name: "enemy_tank",
  glbPath: "CONTENT/MESHES/tank.glb",
  instances: [
    {
      position: { x: 10, y: 0, z: 10 },
      rotation: { x: 0, y: 0, z: 0 },
      scale: { x: 1, y: 1, z: 1 },
      tags: ["enemy", "vehicle", "team_red"]
    }
  ],
  castShadow: true,
  receiveShadow: true
}

// 2. Reload page — model loads automatically
```

### Spawn a Dynamic Entity

```javascript
// Section E — spawnEntity() function
const eid = spawnEntity("character-b", x, y, z, vx, vy, vz);
// Entity now has physics, collision, AI
```

### Play Animation

```javascript
// Section C6 — playAnimation() function
playAnimation(eid, clipIndex, loop, speed);
// clipIndex: 0=idle, 1=walk, 2=run, 3=attack
```

### Add AI Behavior

```javascript
// Section C3 — aiSystem() function
if (aiState[eid] === AI_CHASE) {
  // Custom chase logic here
  const dx = targetX - positions[eid*3];
  const dz = targetZ - positions[eid*3+2];
  const dist = Math.sqrt(dx*dx + dz*dz);
  
  velocities[eid*3] += (dx/dist) * 0.1;
  velocities[eid*3+2] += (dz/dist) * 0.1;
}
```

### Query Entities by Tag

```javascript
// Exposed globally
const enemies = window.getInstancesByTag('team_red');
// Returns array of entity IDs
```

### Raycast for Line-of-Sight

```javascript
// Section C2 — rayCast() function
const hit = rayCast(fromX, fromY, fromZ, toX, toY, toZ);
// Returns { hit: bool, distance: float, entityId: uint }
```

---

## 🎨 ANIMATION SYSTEM (Phase 2)

### Current State
- ✅ `THREE.AnimationMixer` loop runs in `animationSystem(dt)`
- ✅ `playAnimation(eid, clipIndex, loop, speed)` function exists
- ✅ `animMixers{}` object exists
- ⬜ GLB clips not wired to entities yet

### Task 2.1 — Wire GLB Animations

**Location:** Section E → GLB load callback → `spawnEntity()`

```javascript
// In GLB load callback (after gltf loaded):
if (gltf.animations && gltf.animations.length > 0) {
  const mixer = new THREE.AnimationMixer(gltf.scene);
  animMixers[eid] = mixer;
  animClips[eid] = gltf.animations;
  
  // Play idle animation by default
  const action = mixer.clipAction(gltf.animations[0]);
  action.play();
  
  console.log(`✓ Entity ${eid} has ${gltf.animations.length} animations`);
}
```

### Task 2.2 — State-Driven Animation

**Location:** Section C3 → `aiSystem()` → state transition branches

```javascript
// Add AI_PREV_STATE array (Section B)
const AI_PREV_STATE = new Uint8Array(2048);

// In aiSystem(), detect state changes:
if (aiState[eid] !== AI_PREV_STATE[eid]) {
  // State changed — play new animation
  switch (aiState[eid]) {
    case AI_IDLE:   playAnimation(eid, 0, true, 1.0); break;  // idle
    case AI_PATROL: playAnimation(eid, 1, true, 1.0); break;  // walk
    case AI_CHASE:  playAnimation(eid, 2, true, 1.5); break;  // run
    case AI_ATTACK: playAnimation(eid, 3, false, 1.0); break; // attack
  }
  AI_PREV_STATE[eid] = aiState[eid];
}
```

### Task 2.3 — Crossfade Blending

**Location:** Section C6 → `playAnimation()` function

```javascript
// Store previous action per entity
const animPrevAction = {};  // { eid: THREE.AnimationAction }

function playAnimation(eid, clipIndex, loop, speed) {
  const mixer = animMixers[eid];
  if (!mixer || !animClips[eid]) return;
  
  const clip = animClips[eid][clipIndex];
  if (!clip) return;
  
  const newAction = mixer.clipAction(clip);
  newAction.setLoop(loop ? THREE.LoopRepeat : THREE.LoopOnce);
  newAction.timeScale = speed;
  
  // Crossfade from previous action
  if (animPrevAction[eid]) {
    animPrevAction[eid].crossFadeTo(newAction, 0.2, true);
  }
  
  newAction.play();
  animPrevAction[eid] = newAction;
}
```

### Task 2.4 — Player Animation

**Location:** Section C4 → Input system → player movement block

```javascript
// After player movement logic:
const playerSpeed = Math.sqrt(
  velocities[playerEid*3]**2 + 
  velocities[playerEid*3+2]**2
);

if (playerSpeed > 0.1) {
  playAnimation(playerEid, 1, true, 1.0);  // walk
} else {
  playAnimation(playerEid, 0, true, 1.0);  // idle
}

// On jump (spacebar):
if (keys['Space'] && onGround) {
  playAnimation(playerEid, 4, false, 1.0);  // jump (if clip exists)
}
```

---

## 🐛 DEBUGGING

### Console Commands

```javascript
// Entity count
Object.keys(animMixers).length

// Entity position
positions.slice(eid*3, eid*3+3)

// Force AI state
aiState[eid] = 0  // IDLE

// Teleport
positions[eid*3] = 10; positions[eid*3+1] = 0; positions[eid*3+2] = 10;

// Query tags
window.getInstancesByTag('team_red')

// Check animations
animClips[eid]  // Array of clips
animMixers[eid]  // Mixer instance
```

### Common Errors

| Error | Cause | Fix |
|-------|-------|-----|
| `animMixers[eid] is undefined` | Entity has no mixer | Check GLB has animations, verify mixer created on spawn |
| `Cannot read property 'clipAction' of undefined` | Mixer not initialized | Ensure `new THREE.AnimationMixer(gltf.scene)` called |
| `clip is undefined` | Invalid clip index | Check `animClips[eid].length`, use valid index |
| Animation plays once then stops | Loop not set | Set `action.setLoop(THREE.LoopRepeat)` |
| Animation too fast/slow | Wrong timeScale | Adjust `action.timeScale` (1.0 = normal) |

---

## 📊 ECS DATA LAYOUT

```javascript
// Section B — ECS Data Structures

// Entity pool (2048 max)
const MAX_ENTITIES = 2048;
const entities = new Uint32Array(MAX_ENTITIES);

// Transform components (3 floats per entity)
const positions = new Float32Array(MAX_ENTITIES * 3);   // x, y, z
const velocities = new Float32Array(MAX_ENTITIES * 3);  // vx, vy, vz
const rotations = new Float32Array(MAX_ENTITIES * 3);   // rx, ry, rz
const scales = new Float32Array(MAX_ENTITIES * 3);      // sx, sy, sz

// Gameplay components
const health = new Uint16Array(MAX_ENTITIES);           // HP (0-65535)
const maxHealth = new Uint16Array(MAX_ENTITIES);        // Max HP
const damage = new Uint16Array(MAX_ENTITIES);           // Damage dealt
const team = new Uint8Array(MAX_ENTITIES);              // 0=neutral, 1=player, 2=enemy

// Flags (bit-packed)
const flags = new Uint32Array(MAX_ENTITIES);
const FLAG_ALIVE = 1 << 0;
const FLAG_VISIBLE = 1 << 1;
const FLAG_COLLIDABLE = 1 << 2;
const FLAG_ON_GROUND = 1 << 3;

// AI state
const aiState = new Uint8Array(MAX_ENTITIES);           // 0=IDLE, 1=PATROL, 2=CHASE, 3=ATTACK
const aiTarget = new Uint32Array(MAX_ENTITIES);         // Target entity ID
const AI_PREV_STATE = new Uint8Array(MAX_ENTITIES);     // For state change detection

// Animation
const animMixers = {};  // { eid: THREE.AnimationMixer }
const animClips = {};   // { eid: [THREE.AnimationClip, ...] }
const animPrevAction = {};  // { eid: THREE.AnimationAction }

// Collision
const collisionRadius = new Float32Array(MAX_ENTITIES); // Sphere radius
const spatialHash = new Map();  // Grid-based spatial partitioning
```

---

## 🎮 GAME LOOP STRUCTURE

```javascript
// Section F — Game Loop

let accumulator = 0;
const FIXED_DT = 1/60;  // 60 Hz physics

function gameLoop(currentTime) {
  requestAnimationFrame(gameLoop);
  
  const deltaTime = (currentTime - lastTime) / 1000;
  lastTime = currentTime;
  accumulator += deltaTime;
  
  // Fixed timestep physics
  while (accumulator >= FIXED_DT) {
    inputSystem(FIXED_DT);
    physicsSystem(FIXED_DT);
    collisionSystem(FIXED_DT);
    aiSystem(FIXED_DT);
    animationSystem(FIXED_DT);  // ← Update mixers here
    accumulator -= FIXED_DT;
  }
  
  // Render at display refresh rate
  cameraSystem();
  renderSystem();
  hudSystem();
}
```

---

## 🎯 PERFORMANCE RULES

### Always Do
- ✅ Use `InstancedMesh` for repeated geometry
- ✅ Set `renderer.setPixelRatio(1)` for mobile
- ✅ Disable `frustumCulled` on instanced meshes (handle manually)
- ✅ Use `Float32Array` / `Uint8Array` for ECS data
- ✅ Batch draw calls (< 50 total)
- ✅ Update `mixer.update(dt)` every frame
- ✅ Clamp animation speeds (0.5–2.0 range)

### Never Do
- ❌ Create individual `THREE.Mesh` for repeated objects
- ❌ Use `window.devicePixelRatio` on mobile
- ❌ Enable shadows without explicit config
- ❌ Allocate objects in hot loops
- ❌ Use `eval()` or `Function()` constructors
- ❌ Forget to call `mixer.update(dt)`
- ❌ Create multiple mixers for same entity

---

## 📝 CODE STYLE

### Console Logging
```javascript
console.log('✓ Success message');
console.error('✗ Error message');
console.warn('⚠ Warning message');
```

### Comments
```javascript
// Section C3 — AI System
// Brief description of what this block does

// Inline comments for complex logic
const dist = Math.sqrt(dx*dx + dz*dz);  // Euclidean distance
```

### Naming Conventions
- **Constants:** `UPPER_SNAKE_CASE` (e.g., `MAX_ENTITIES`, `AI_IDLE`)
- **Variables:** `camelCase` (e.g., `playerEid`, `deltaTime`)
- **Functions:** `camelCase` (e.g., `spawnEntity()`, `playAnimation()`)
- **Arrays:** Plural nouns (e.g., `positions`, `velocities`)

---

## 🔗 FILE REFERENCES

### Main Files
- `index.html` — Game engine (all code)
- `viewer.html` — GLB model viewer

### Documentation
- `SYSTEM_PROMPT.md` — Complete dev guide
- `README.md` — Project overview
- `TASKLIST_NEXT_CHAT.md` — Phase roadmap
- `LLM_CHEATSHEET.md` — This file
- `DEVELOPER_GUIDE.md` — Human developer reference

### Assets
- `CONTENT/MESHES/kenney_blocky-characters_20/*.glb` — Characters
- `CONTENT/MESHES/kenney_building-kit/*.glb` — Buildings

---

## 🚀 QUICK START PROMPT

Copy-paste this to start a new session:

```
Continue RAMAI Engine development — Phase 2: Animation System.

Current state:
- Collision detection FULLY implemented
- THREE.AnimationMixer loop runs in animationSystem(dt)
- playAnimation(eid, clipIndex, loop, speed) exists
- animMixers{} and animClips{} exist

Tasks:
1. Wire GLB animations to entities on spawn
2. Map AI states to animation clips
3. Add crossfade blending
4. Wire player movement to animations

Files: index.html (Section E, C3, C4, C6)
Reference: LLM_CHEATSHEET.md, TASKLIST_NEXT_CHAT.md

Start with Task 2.1 — Wire GLB Animations.
```

---

## 📞 WHEN STUCK

1. **Check console** — Look for `✗` errors
2. **Verify mixer exists** — `console.log(animMixers[eid])`
3. **Check clip count** — `console.log(animClips[eid].length)`
4. **Test in viewer.html** — Load GLB, verify animations exist
5. **Read SYSTEM_PROMPT.md** — Section on Animation System
6. **Check TASKLIST_NEXT_CHAT.md** — See detailed task breakdown

---

## 🎓 KEY CONCEPTS

### ECS (Entity Component System)
- **Entity:** Just an ID (uint32)
- **Component:** Data in typed arrays (positions, velocities, etc.)
- **System:** Function that processes components (physicsSystem, aiSystem, etc.)

### Fixed Timestep
- Physics runs at exactly 60 Hz (0.0167s per step)
- Rendering runs at display refresh rate (60/120/144 Hz)
- Accumulator ensures deterministic physics

### Spatial Hashing
- World divided into 10×10×10 unit grid cells
- Entities hashed by position
- Collision checks only within same/adjacent cells
- O(1) query time

### Animation Mixer
- One mixer per animated entity
- Mixer manages multiple animation clips
- Call `mixer.update(dt)` every frame
- Actions control playback (play, stop, crossfade)

---

**End of Cheatsheet**

---

*Keep this file open while coding. Refer to SYSTEM_PROMPT.md for deep dives.*
