# Implementation Roadmap
## Phased Plan: GLB Viewer → AAA Mobile Engine

---

## ✅ Phase 0 — ECS Foundation (COMPLETE)
**Goal:** Implement core ECS architecture with NES-era data-oriented design

**Status:** ✅ **COMPLETE** (Commits: 7df8279, 29bdbe5)  
**Date Completed:** May 2026

### Completed Tasks:
- ✅ Flat typed array component storage (Float32, Int16, Uint8)
- ✅ 2048 entity pool with free-list recycling
- ✅ Bit-packed flags (8 booleans in 1 byte)
- ✅ Query system with reused scratch buffer
- ✅ Physics system (gravity, Euler integration, ground clamp, friction)
- ✅ Render sync system (dirty-flag pattern, batch GPU updates)
- ✅ AI system (state machine: IDLE/PATROL/CHASE/ATTACK)
- ✅ Input system (keyboard + virtual joystick)
- ✅ Fixed timestep game loop (60Hz physics, variable render)
- ✅ Object pool (zero-alloc spawning, mesh slot recycling)
- ✅ Adaptive quality system (3-tier, FPS-based auto-switching)
- ✅ Follow camera (smooth lerp tracking in ECS mode)
- ✅ Performance HUD (FPS, MS, DRAW, TRIS, INST, ENT, MEM, QUAL, STEP)
- ✅ ECS debug panel (alive, player, enemy, static, dirty, steps)

### Deliverable:
✅ `viewer.html` with full ECS gameplay — player movement, enemy AI, physics, camera follow

### Performance Achieved:
- 2000 instances @ 60fps on mid-range Android
- ~87KB ECS data (negligible memory footprint)
- Zero GC pressure in hot loop
- Physics dead-zone optimization (only sync moved entities)
- AI squared distance checks (sqrt only for steering)

### What Works:
- Toggle ECS mode on/off with button
- Player controlled by WASD/arrows + virtual joystick
- Enemies patrol, chase, and attack player
- Smooth follow camera in ECS mode
- Orbit camera in viewer mode
- Real-time quality adjustment based on FPS

---

## 🔄 Phase 1 — Collision & Physics Upgrade (Week 1-2)
**Goal:** Add AABB collision, raycasting, and proper character controller

**Status:** 🔄 **NEXT PRIORITY**

### Tasks:
- [ ] AABB collision detection (entity vs entity)
- [ ] Spatial hash grid for broad-phase culling (divide world into cells)
- [ ] Raycast system (ground detection, line-of-sight)
- [ ] Character controller (slope handling, step-up)
- [ ] Collision response (push-out, bounce)
- [ ] Collision events (onCollisionEnter, onCollisionStay, onCollisionExit)
- [ ] Trigger volumes (invisible collision zones for gameplay)
- [ ] Physics debug visualization (wireframe boxes, collision normals)
- [ ] Collision layers/masks (player vs enemy, player vs building, etc.)

### Technical Approach:
- Keep it simple — no physics engine dependency
- AABB only (no rotation, sufficient for most games)
- Spatial hash: 10×10 unit cells, O(1) broad-phase
- Narrow-phase: SAT (Separating Axis Theorem) for AABB
- Store collision data in typed arrays (same ECS pattern)

### New ECS Components:
```javascript
var COLL_X = new Float32Array(MAX_E);  // collider center X offset
var COLL_Y = new Float32Array(MAX_E);  // collider center Y offset
var COLL_Z = new Float32Array(MAX_E);  // collider center Z offset
var COLL_W = new Float32Array(MAX_E);  // collider width (X extent)
var COLL_H = new Float32Array(MAX_E);  // collider height (Y extent)
var COLL_D = new Float32Array(MAX_E);  // collider depth (Z extent)
var COLL_LAYER = new Uint8Array(MAX_E); // collision layer (0-255)
var COLL_MASK  = new Uint8Array(MAX_E); // collision mask (bitfield)
```

### Deliverable:
Player collides with enemies and buildings. Enemies can't walk through walls. Raycasting for ground detection. Debug mode shows collision boxes.

---

## 📝 Phase 2 — Animation System (Week 3-4)
**Goal:** Skeletal animation with blend trees

**Status:** 📝 **PLANNED**

### Tasks:
- [ ] Parse GLB skeletal animation data
- [ ] Animation clip storage (keyframes in typed arrays)
- [ ] Animation state machine (idle/walk/run/jump/death)
- [ ] Crossfade blending (lerp between two animations)
- [ ] Animation events (footstep sounds, attack hit frames)
- [ ] One-shot animations (attack, interact)
- [ ] Root motion support (animation drives movement)
- [ ] Animation speed control (slow-mo, fast-forward)

### New ECS Components:
```javascript
var ANIM_CLIP  = new Int16Array(MAX_E);  // current animation clip ID
var ANIM_TIME  = new Float32Array(MAX_E); // playback time (seconds)
var ANIM_SPEED = new Float32Array(MAX_E); // playback speed multiplier
var ANIM_BLEND = new Float32Array(MAX_E); // blend weight (0-1)
var ANIM_NEXT  = new Int16Array(MAX_E);   // next clip (for crossfade)
```

### Deliverable:
Characters animate correctly. Idle → walk → run transitions smooth. Attack animation plays on tap. Footstep sounds sync to animation.

---

## 📝 Phase 3 — Audio System (Week 5)
**Goal:** Spatial audio, music, SFX

**Status:** 📝 **PLANNED**

### Tasks:
- [ ] Web Audio API context setup
- [ ] Audio asset loader (MP3/OGG)
- [ ] Spatial audio (3D positional sound)
- [ ] Audio mixer (master, music, SFX channels)
- [ ] Background music with crossfade
- [ ] SFX with pitch variation (avoid repetition)
- [ ] Footstep system (surface-based: grass, concrete, metal)
- [ ] Audio occlusion (muffled through walls)
- [ ] Audio pooling (reuse AudioBufferSourceNode)

### New ECS Components:
```javascript
var AUDIO_ID   = new Int16Array(MAX_E);   // audio clip ID
var AUDIO_VOL  = new Float32Array(MAX_E); // volume (0-1)
var AUDIO_LOOP = new Uint8Array(MAX_E);   // loop flag
var AUDIO_3D   = new Uint8Array(MAX_E);   // spatial audio flag
```

### Deliverable:
Game has music, footsteps, collision sounds. Audio fades with distance. Muffled when behind walls.

---

## 📝 Phase 4 — Rendering Upgrade (Week 6-7)
**Goal:** Post-processing, LOD, advanced lighting

**Status:** 📝 **PLANNED**

### Tasks:
- [ ] Render targets for post-processing
- [ ] Bloom effect (threshold + Gaussian blur)
- [ ] FXAA anti-aliasing (shader-based, cheap)
- [ ] Vignette effect
- [ ] Color grading LUT
- [ ] LOD system (3 levels per mesh: HIGH/MED/LOW)
- [ ] Frustum culling for instances
- [ ] Procedural sky shader (gradient + sun)
- [ ] Time-of-day system (sun angle, fog color)
- [ ] Dynamic point lights (up to 8, forward rendering)

### Deliverable:
Scene looks AAA quality. Bloom on lights, FXAA smooths edges, LOD reduces draw calls by 60%. Day/night cycle.

---

## 📝 Phase 5 — UI Framework (Week 8)
**Goal:** Canvas HUD, HTML menus, damage numbers

**Status:** 📝 **PLANNED**

### Tasks:
- [ ] Canvas 2D overlay (HUD layer)
- [ ] Health bar component (animated fill)
- [ ] Score display with animated counter
- [ ] Minimap (top-down view)
- [ ] Crosshair
- [ ] Damage numbers (floating text, fade out)
- [ ] Main menu screen (HTML)
- [ ] Pause menu
- [ ] Game over screen
- [ ] Settings screen (volume, quality)
- [ ] Loading screen with progress bar

### Deliverable:
Complete UI flow: main menu → loading → gameplay HUD → pause → game over. Damage numbers pop up on hit.

---

## 📝 Phase 6 — Advanced Gameplay (Week 9-10)
**Goal:** Combat, inventory, progression

**Status:** 📝 **PLANNED**

### Tasks:
- [ ] Combat system (melee, ranged)
- [ ] Weapon system (equip, switch, ammo)
- [ ] Inventory system (pickup, drop, use)
- [ ] Health/damage system (already basic version exists)
- [ ] XP/leveling system
- [ ] Ability system (cooldowns, mana)
- [ ] Quest system (objectives, rewards)
- [ ] Save/load system (localStorage JSON)
- [ ] Spawn system (waves, random placement)

### Deliverable:
Player can pick up weapons, attack enemies, gain XP, level up. Quests tracked. Game saves progress.

---

## 📝 Phase 7 — Editor (Week 11-12)
**Goal:** Browser-based level editor

**Status:** 📝 **PLANNED**

### Tasks:
- [ ] Editor mode toggle (play/edit)
- [ ] Transform gizmo (translate/rotate/scale)
- [ ] Outliner panel (entity hierarchy)
- [ ] Properties panel (component inspector)
- [ ] Asset browser (drag-drop spawning)
- [ ] Level save/load (JSON)
- [ ] Undo/redo system
- [ ] Grid snapping
- [ ] Copy/paste entities
- [ ] Camera bookmarks

### Deliverable:
Can build levels visually in browser. Save as JSON. Load in game. Undo/redo works.

---

## 📝 Phase 8 — Polish & Release (Week 13-14)
**Goal:** AAA quality, performance, store submission

**Status:** 📝 **PLANNED**

### Tasks:
- [ ] Performance profiling on real devices (Snapdragon 720G, 730G, 845)
- [ ] Memory leak audit (Chrome DevTools heap snapshots)
- [ ] Crash reporting (window.onerror → AndroidBridge)
- [ ] Analytics integration (Firebase or custom)
- [ ] Real AdMob IDs (replace test IDs)
- [ ] App icon (1024×1024 PNG)
- [ ] Splash screen (1920×1080 PNG)
- [ ] Store screenshots (5-8 images)
- [ ] Store description (short + long)
- [ ] ProGuard configuration (R8 minification)
- [ ] Release APK signing (keystore)
- [ ] Google Play submission

### Deliverable:
APK submitted to Google Play. Passes all checks. Ready for public release.

---

## Game Templates (Post-Engine)

Once the engine is complete, these game types can be built in 1-2 weeks each:

| Game Type | Assets Needed | Key Systems | Estimated Time |
|-----------|--------------|-------------|----------------|
| **City Builder** | Buildings, Roads | Placement, Economy, Pathfinding | 2 weeks |
| **Racing Game** | Cars, Tracks | Vehicle Physics, Lap Timer, Checkpoints | 1 week |
| **Tower Defense** | Characters, Towers | Pathfinding, Waves, Upgrades | 2 weeks |
| **Third-Person Action** | Characters, Weapons | Combat, Camera, Combos | 2 weeks |
| **Endless Runner** | Characters, Obstacles | Procedural Gen, Speed Curve | 1 week |
| **Top-Down Shooter** | Characters, Weapons | Twin-stick controls, Bullet hell | 1 week |

---

## Technology Stack Summary

```
RUNTIME:
├── Three.js r128          — WebGL rendering
├── Web Audio API          — Audio (native browser)
├── Canvas 2D API          — UI overlay
└── Custom ECS             — Game logic (no framework)

BUILD:
├── Gradle 8.2             — Android build
├── Android SDK 34         — Target platform
├── Java 11                — Native code
└── AdMob 22.6             — Monetization

ASSETS:
├── Kenney GLB kits        — 2000+ models
├── Custom shaders (GLSL)  — Visual effects
└── JSON level files       — Level data

DEPLOYMENT:
├── Android APK/AAB        — Primary target
├── Browser (HTML)         — Development/testing
└── iOS (WKWebView)        — Future target
```

---

## Current Status Summary

**✅ COMPLETE:**
- ECS core architecture
- Physics system (basic)
- AI system (state machine)
- Input system (keyboard + touch)
- Rendering (instancing, shadows, quality tiers)
- Performance monitoring

**🔄 IN PROGRESS:**
- Nothing (Phase 0 complete, Phase 1 not started)

**📝 PLANNED:**
- Collision detection
- Animation system
- Audio system
- Post-processing
- UI framework
- Advanced gameplay
- Level editor
- Store release

**Estimated Completion:** 14 weeks from Phase 1 start
