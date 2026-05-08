# RAMAI Engine — System Architecture

**Date:** May 8, 2026  
**Status:** All systems added (4 working, 9 placeholders)

---

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                     RAMAI ENGINE v1.0                       │
│              Single HTML5 File — 1808 Lines                 │
└─────────────────────────────────────────────────────────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
        ▼                     ▼                     ▼
┌───────────────┐    ┌───────────────┐    ┌───────────────┐
│   SECTION A   │    │   SECTION B   │    │   SECTION C   │
│   CONSTANTS   │    │   ECS CORE    │    │    SYSTEMS    │
└───────────────┘    └───────────────┘    └───────────────┘
        │                     │                     │
        │                     │                     │
        ▼                     ▼                     ▼
┌───────────────┐    ┌───────────────┐    ┌───────────────┐
│   SECTION D   │    │   SECTION E   │    │   SECTION F   │
│   RENDERER    │    │    ASSETS     │    │     INIT      │
└───────────────┘    └───────────────┘    └───────────────┘
        │                     │                     │
        └─────────────────────┼─────────────────────┘
                              │
                              ▼
                    ┌───────────────┐
                    │   SECTION G   │
                    │   GAME LOOP   │
                    └───────────────┘
```

---

## 📦 Section Breakdown

### A — Constants & Config (50 lines)

```javascript
MAX_E = 2048              // Max entities
FIXED_DT = 1/60          // 60Hz physics
Entity types: T_PLAYER, T_ENEMY, T_VEHICLE, etc.
Flags: F_ALIVE, F_VISIBLE, F_PHYSICS, F_AI, etc.
AI states: AI_IDLE, AI_PATROL, AI_CHASE, AI_ATTACK
Quality configs: LOW, MED, HIGH
```

### B — ECS Core (100 lines)

```javascript
Component Arrays (typed):
  Position:  PX, PY, PZ
  Velocity:  VX, VY, VZ
  Rotation:  RY
  Health:    HP, HP_MAX
  Flags:     FLAGS (bit-packed)
  Type:      TYPE
  Mesh:      MESH_ID, MESH_IDX
  AI:        AI_STATE, AI_TIMER, AI_TARGET

Entity Lifecycle:
  createEntity()
  destroyEntity(id)
  queryFlag(flag) → _qBuf[0.._qLen-1]
```

### C — Systems (600+ lines)

#### ✅ Working Systems (4)

```javascript
C1: physicsSystem(dt)
    - Gravity, Euler integration
    - Ground clamp, friction
    - Dirty flag optimization

C2: renderSyncSystem()
    - Push dirty transforms to GPU
    - Zero work for static entities
    - InstancedMesh updates

C3: aiSystem(dt)
    - State machine (IDLE/PATROL/CHASE/ATTACK)
    - Distance checks, steering
    - Attack cooldowns

C4: inputSystem(dt)
    - Keyboard (WASD, arrows, space)
    - Virtual joystick (touch)
    - Player movement + jump
```

#### 📝 Placeholder Systems (9)

```javascript
C5: collisionSystem(dt)
    - AABB arrays: COLL_MINX/Y/Z, COLL_MAXX/Y/Z
    - Sphere collision: COLL_RADIUS
    - raycast(ox,oy,oz, dx,dy,dz, maxDist)

C6: animationSystem(dt)
    - ANIM_CLIP, ANIM_TIME, ANIM_SPEED
    - ANIM_LOOP, ANIM_BLEND
    - playAnimation(eid, clipId, loop, speed)

C7: audioSystem(dt)
    - audioContext, audioBuffers
    - activeSounds: {source, gain, panner, entity}
    - playSound(url, loop, volume, spatial, entityId)

C8: particleSystem(dt)
    - PART_LIFE, PART_MAXLIFE, PART_SIZE, PART_ALPHA
    - emitParticle(x,y,z, vx,vy,vz, lifetime, size)

C9: lodSystem()
    - LOD_LEVEL: 0=high, 1=med, 2=low
    - Distance thresholds: 20m, 50m
    - Mesh pool swapping

D1: Post-Processing
    - composer, bloomPass, dofPass, colorGradingPass
    - initPostProcessing(), updatePostProcessing()
    - renderWithPostProcessing()

D2: Canvas UI
    - uiCanvas, uiCtx, uiElements
    - drawCanvasUI() — health bar ✅ working
    - addUIElement(type, x, y, w, h, text, onClick)

D3: Scene Editor
    - editorMode, editorSelection, editorGizmo
    - toggleEditor(), editorUpdate(), editorRender()
    - editorSaveScene(), editorLoadScene(json)

D4: Save/Load
    - saveGame() → localStorage ✅ working
    - loadGame() ← localStorage ✅ working
    - deleteSave()
```

### D — Renderer (200 lines)

```javascript
Three.js Setup:
  - WebGLRenderer (high-performance, no antialias)
  - Scene (sky blue background, fog)
  - PerspectiveCamera (55° FOV)
  - DirectionalLight (sun + shadows)
  - HemisphereLight (ambient)
  - Ground plane + grid

Quality System:
  - 3 tiers: LOW, MED, HIGH
  - Adaptive switching based on FPS
  - Pixel ratio, shadow map size, fog density
```

### E — Assets (300 lines)

```javascript
Texture Cache:
  - texCache: url → THREE.Texture
  - loadTextureCached(url) → Promise<Texture>

Mesh Pool:
  - meshPool[id]: {mesh, maxCount, used, freeSlots}
  - registerMeshPool(iMesh, maxCount) → poolId
  - allocMeshSlot(poolId) → slot
  - freeMeshSlot(poolId, slot)

Entity Spawning:
  - spawnEntity(type, poolId, x, y, z) → eid
  - despawnEntity(eid)

GLB Loading:
  - loadBinary(url, onProg) → Promise<ArrayBuffer>
  - buildInstances(gltfScene, basePath, count, forEcs)
  - mergeGeometries(geos) → BufferGeometry
```

### F — Init (150 lines)

```javascript
bootScene():
  - Create renderer, scene, camera
  - Setup lighting (sun, hemi, fill)
  - Create ground plane + grid
  - Setup input (keyboard, joystick, orbit)
  - Wire UI buttons
  - Apply quality tier
  - Start game loop
  - Auto-load first model

UI Wiring:
  - btnLoad, btnSpawn, btnClear
  - btnEcs, btnShadow
  - btnEditor ✅ NEW
  - btnSave ✅ NEW
```

### G — Game Loop (200 lines)

```javascript
gameLoop(now):
  1. Calculate dt (capped at 0.1s)
  2. Update FPS rolling average
  
  3. FIXED TIMESTEP (60Hz physics):
     if(ecsMode){
       while(_accumulator >= FIXED_DT){
         inputSystem(FIXED_DT)
         physicsSystem(FIXED_DT)
         aiSystem(FIXED_DT)
         collisionSystem(FIXED_DT)    ✅ NEW
         animationSystem(FIXED_DT)    ✅ NEW
         particleSystem(FIXED_DT)     ✅ NEW
       }
       renderSyncSystem()
       followCamera()
     }
  
  4. VARIABLE TIMESTEP (per-frame):
     audioSystem(dt)           ✅ NEW
     lodSystem()               ✅ NEW
     editorUpdate()            ✅ NEW
     updatePostProcessing()    ✅ NEW
  
  5. RENDER:
     renderWithPostProcessing()  ✅ NEW
     editorRender()              ✅ NEW
     drawCanvasUI()              ✅ NEW
  
  6. HUD update (every 16 frames)
  7. Adaptive quality (every 120 frames)
```

### H — Input (200 lines)

```javascript
Keyboard:
  - _keys: Uint8Array(256)
  - WASD, arrows, space

Virtual Joystick:
  - Touch-based, left half of screen
  - _joyX, _joyZ: -1 to 1
  - Visual feedback (base + knob)

Orbit Controls:
  - Mouse + touch, right half of screen
  - Spherical coordinates (theta, phi, r)
  - Pinch zoom support
```

---

## 🔄 Data Flow

```
┌─────────────┐
│   INPUT     │ Keyboard, Touch, Mouse
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ INPUT SYS   │ Update player velocity
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ PHYSICS SYS │ Integrate velocity → position
└──────┬──────┘
       │
       ▼
┌─────────────┐
│   AI SYS    │ Update enemy behavior
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ COLLISION   │ Detect + resolve collisions
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ ANIMATION   │ Update skeletal poses
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ PARTICLES   │ Update particle lifetime
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ RENDER SYNC │ Push dirty transforms to GPU
└──────┬──────┘
       │
       ▼
┌─────────────┐
│   AUDIO     │ Update spatial audio positions
└──────┬──────┘
       │
       ▼
┌─────────────┐
│     LOD     │ Swap mesh pools by distance
└──────┬──────┘
       │
       ▼
┌─────────────┐
│   RENDER    │ Three.js render call
└──────┬──────┘
       │
       ▼
┌─────────────┐
│  CANVAS UI  │ Draw health bar, HUD
└─────────────┘
```

---

## 🎮 ECS Component Layout

Each entity is an integer ID (0-2047) that indexes into component arrays:

```
Entity 5:
  PX[5] = 10.5        // Position X
  PY[5] = 0.0         // Position Y
  PZ[5] = -3.2        // Position Z
  VX[5] = 2.0         // Velocity X
  VY[5] = 0.0         // Velocity Y
  VZ[5] = 0.0         // Velocity Z
  RY[5] = 1.57        // Rotation Y (radians)
  HP[5] = 80          // Health
  HP_MAX[5] = 100     // Max health
  FLAGS[5] = 0b10111111  // Bit-packed flags
  TYPE[5] = T_ENEMY   // Entity type
  MESH_ID[5] = 0      // Mesh pool ID
  MESH_IDX[5] = 12    // Instance slot
  AI_STATE[5] = AI_CHASE
  AI_TIMER[5] = 0.5
  AI_TARGET[5] = 0    // Chasing player (entity 0)
```

**Memory per entity:** ~80 bytes  
**Total memory (2048 entities):** ~160 KB

---

## 🚀 Performance Characteristics

| Metric | Value | Notes |
|--------|-------|-------|
| **Max Entities** | 2,048 | Power of 2, cache-friendly |
| **Physics Rate** | 60 Hz | Fixed timestep, NES-style |
| **Render Rate** | Variable | Catches up or skips |
| **Memory (ECS)** | 160 KB | All component arrays |
| **Memory (Meshes)** | ~50 MB | 2000 instances, textures |
| **Draw Calls** | 1-5 | Instanced rendering |
| **Triangles** | 100k-500k | Depends on model |
| **Target FPS** | 60 | On Snapdragon 720G+ |

---

## 🎯 System Dependencies

```
┌──────────────┐
│   Physics    │ No dependencies
└──────┬───────┘
       │
       ▼
┌──────────────┐
│  Collision   │ Depends on: Physics (positions)
└──────┬───────┘
       │
       ▼
┌──────────────┐
│      AI      │ Depends on: Physics (positions)
└──────┬───────┘
       │
       ▼
┌──────────────┐
│  Animation   │ Depends on: AI (state for anim selection)
└──────┬───────┘
       │
       ▼
┌──────────────┐
│  Particles   │ Depends on: Physics (emitter positions)
└──────┬───────┘
       │
       ▼
┌──────────────┐
│ Render Sync  │ Depends on: All above (final transforms)
└──────┬───────┘
       │
       ▼
┌──────────────┐
│     LOD      │ Depends on: Camera position
└──────┬───────┘
       │
       ▼
┌──────────────┐
│    Audio     │ Depends on: Entity positions, camera
└──────────────┘
```

---

## 📊 System Complexity

| System | Lines | Complexity | Priority |
|--------|-------|------------|----------|
| Physics | 30 | Low | ✅ Done |
| Render Sync | 25 | Low | ✅ Done |
| AI | 50 | Medium | ✅ Done |
| Input | 40 | Low | ✅ Done |
| Collision | 80 | High | 🔥 P1 |
| Animation | 100 | High | 🔥 P1 |
| Audio | 60 | Medium | 🔥 P1 |
| Particles | 70 | Medium | ⚡ P2 |
| LOD | 50 | Medium | ⚡ P2 |
| Post-Process | 80 | Medium | ⚡ P2 |
| Canvas UI | 100 | Medium | 💡 P3 |
| Editor | 150 | High | 💡 P3 |
| Save/Load | 40 | Low | ✅ Done |

---

## 🏆 Design Principles

1. **Data-Oriented** — Flat arrays, cache-friendly, SIMD-ready
2. **Zero-Allocation** — No GC pressure in hot path
3. **Mobile-First** — Every decision optimized for 60fps on Android
4. **Modular** — Each system is independent, can be disabled
5. **Single-File** — No bundler, works from file://
6. **NES-Era** — Fixed timestep, bit-packed flags, component arrays

---

## 🎉 Achievement

**RAMAI Engine v1.0** — All systems added!

- ✅ 13 total systems (4 working, 9 placeholders)
- ✅ 1,808 lines of code
- ✅ 160 KB ECS memory
- ✅ Single HTML file
- ✅ Ready for implementation

**Next:** Implement collision detection! 🚀
