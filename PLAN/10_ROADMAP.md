# Implementation Roadmap
## Phased Plan: GLB Viewer → AAA Mobile Engine

---

## Phase 0 — Foundation Cleanup (Week 1)
**Goal:** Refactor current viewer.html into a clean engine skeleton

### Tasks:
- [ ] Split viewer.html into modular files: `engine/`, `game/`, `index.html`
- [ ] Upgrade Three.js from r128 to r165 (latest stable)
- [ ] Add OrbitControls from addons (already in `assets/js/addons/controls/`)
- [ ] Implement full AdaptiveQuality system (currently stubbed)
- [ ] Add proper error boundary and crash reporting
- [ ] Create `engine/core/Engine.js` entry point
- [ ] Create `engine/core/EventBus.js`
- [ ] Create `engine/core/Timer.js`
- [ ] Create `engine/core/ObjectPool.js`

### Deliverable:
`index.html` that boots the engine and shows the current viewer functionality, but with clean modular code.

---

## Phase 1 — World & ECS (Week 2)
**Goal:** Actor-Component system, game loop, state machine

### Tasks:
- [ ] `engine/world/World.js` — scene container
- [ ] `engine/world/Actor.js` — base game object
- [ ] `engine/world/Component.js` — base component
- [ ] `engine/world/Transform.js` — spatial data with dirty flags
- [ ] `engine/gameplay/StateMachine.js` — game flow FSM
- [ ] `engine/gameplay/EventBus.js` — full event system
- [ ] Fixed timestep game loop (physics + variable render)
- [ ] `MeshComponent` — sync Three.js objects to actors
- [ ] `CameraComponent` — camera actor
- [ ] `LightComponent` — light actor

### Deliverable:
Spawn 100 actors with MeshComponents, each with independent transforms. Game loop running at 60fps.

---

## Phase 2 — Input & Controls (Week 3)
**Goal:** Mobile-first input, virtual joystick, camera controls

### Tasks:
- [ ] `engine/input/InputSystem.js` — unified touch/keyboard
- [ ] `engine/input/VirtualJoystick.js` — on-screen joystick
- [ ] `engine/input/TouchInput.js` — tap, swipe, pinch gestures
- [ ] Replace current orbit controls with InputSystem-driven camera
- [ ] `engine/input/CameraController.js` — orbit, follow, FPS modes
- [ ] Action mapping system (configurable button bindings)

### Deliverable:
Player character that moves with virtual joystick. Camera follows player. Tap to interact.

---

## Phase 3 — Asset Pipeline (Week 4)
**Goal:** Proper asset loading, caching, streaming

### Tasks:
- [ ] `engine/assets/AssetManager.js` — unified loader
- [ ] Level manifest system
- [ ] Loading screen with progress bar
- [ ] Asset preloading bundles
- [ ] Memory budget tracking
- [ ] Texture atlas support
- [ ] LOD geometry generation (basic)

### Deliverable:
Level loads with progress bar. All Kenney assets accessible via catalog. Memory stays under 200MB.

---

## Phase 4 — Physics (Week 5-6)
**Goal:** Collision, rigid body, character controller

### Tasks:
- [ ] Integrate Rapier.js WASM (or cannon-es for simpler games)
- [ ] `engine/physics/PhysicsSystem.js`
- [ ] `engine/physics/RigidBodyComponent.js`
- [ ] `engine/physics/ColliderComponent.js`
- [ ] `engine/physics/CharacterController.js`
- [ ] `engine/physics/Raycast.js`
- [ ] Physics debug visualization (wireframe colliders)
- [ ] Collision event system

### Deliverable:
Player walks on ground, collides with buildings, can jump. Vehicles have physics.

---

## Phase 5 — Animation (Week 7)
**Goal:** Skeletal animation, blend trees, state machines

### Tasks:
- [ ] `engine/animation/AnimationSystem.js`
- [ ] `engine/animation/AnimatorComponent.js`
- [ ] Animation state machine (idle/walk/run/jump/death)
- [ ] Crossfade blending
- [ ] One-shot animations (attack, interact)
- [ ] Root motion support

### Deliverable:
Characters animate correctly. Idle → walk → run transitions smooth. Attack animation plays on tap.

---

## Phase 6 — Rendering Upgrade (Week 8-9)
**Goal:** Post-processing, LOD, advanced lighting

### Tasks:
- [ ] Render targets for post-processing
- [ ] Bloom effect (threshold + blur)
- [ ] ACES tone mapping (upgrade from current)
- [ ] FXAA anti-aliasing
- [ ] Vignette effect
- [ ] LOD system (3 levels per mesh)
- [ ] Frustum culling for instances
- [ ] Procedural sky shader
- [ ] Time-of-day system
- [ ] Dynamic point lights (up to 8)

### Deliverable:
Scene looks AAA quality. Bloom on lights, proper tone mapping, LOD reduces draw calls by 60%.

---

## Phase 7 — Audio (Week 10)
**Goal:** Spatial audio, music, SFX

### Tasks:
- [ ] `engine/audio/AudioSystem.js` — Web Audio context
- [ ] `engine/audio/AudioSource.js` — spatial emitter component
- [ ] `engine/audio/AudioMixer.js` — channels + volume
- [ ] Background music with crossfade
- [ ] SFX with pitch variation
- [ ] Footstep system (surface-based)
- [ ] Audio occlusion (muffled through walls)

### Deliverable:
Game has music, footsteps, collision sounds. Audio fades with distance.

---

## Phase 8 — UI Framework (Week 11)
**Goal:** Canvas HUD, HTML menus, damage numbers

### Tasks:
- [ ] `engine/ui/UISystem.js` — canvas 2D overlay
- [ ] Health bar component
- [ ] Score display with animated counter
- [ ] Minimap
- [ ] Crosshair
- [ ] Damage numbers (floating text)
- [ ] Main menu screen (HTML)
- [ ] Pause menu
- [ ] Game over screen
- [ ] Settings screen (volume, quality)
- [ ] Loading screen

### Deliverable:
Complete UI flow: main menu → loading → gameplay HUD → pause → game over.

---

## Phase 9 — AI & Gameplay (Week 12)
**Goal:** Enemy AI, game mechanics, save system

### Tasks:
- [ ] `engine/ai/AISystem.js` — steering behaviors
- [ ] Behavior tree implementation
- [ ] Enemy patrol, chase, attack states
- [ ] `engine/gameplay/HealthComponent.js`
- [ ] `engine/gameplay/MovementComponent.js`
- [ ] `engine/gameplay/InventorySystem.js`
- [ ] `engine/gameplay/ScoreSystem.js`
- [ ] `engine/gameplay/SaveSystem.js`
- [ ] Spawn system (waves, random placement)

### Deliverable:
Enemies patrol, chase player, attack. Player has health, can die. Score tracked. Game saves.

---

## Phase 10 — Editor (Week 13-14)
**Goal:** Browser-based level editor

### Tasks:
- [ ] Editor mode toggle (play/edit)
- [ ] Transform gizmo (translate/rotate/scale)
- [ ] Outliner panel
- [ ] Properties panel
- [ ] Asset browser
- [ ] Level save/load (JSON)
- [ ] Undo/redo system
- [ ] Grid snapping
- [ ] Copy/paste actors

### Deliverable:
Can build levels visually in browser. Save as JSON. Load in game.

---

## Phase 11 — Polish & Release (Week 15-16)
**Goal:** AAA quality, performance, store submission

### Tasks:
- [ ] Performance profiling on real devices
- [ ] Memory leak audit
- [ ] Crash reporting (window.onerror → AndroidBridge)
- [ ] Analytics integration
- [ ] Real AdMob IDs
- [ ] App icon and splash screen
- [ ] Store screenshots
- [ ] ProGuard configuration
- [ ] Release APK signing
- [ ] Google Play submission

---

## Game Templates (Post-Engine)

Once the engine is complete, these game types can be built in 1-2 weeks each:

| Game Type | Assets Needed | Key Systems |
|-----------|--------------|-------------|
| City Builder | Buildings, Roads | Placement, Economy |
| Racing Game | Cars, Roads | Vehicle Physics, Lap Timer |
| Tower Defense | Characters, Buildings | Pathfinding, Waves |
| Third-Person Action | Characters, Weapons | Combat, Camera |
| Endless Runner | Characters, Obstacles | Procedural Gen, Speed |
| Space Shooter | Space Station Kit | 2D Physics, Bullets |

---

## Technology Stack Summary

```
RUNTIME:
├── Three.js r165          — WebGL rendering
├── Rapier.js 0.12         — Physics (WASM)
├── Web Audio API          — Audio (native browser)
└── Canvas 2D API          — UI overlay

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
