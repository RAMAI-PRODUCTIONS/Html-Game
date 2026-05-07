# Engine Architecture — RAMAI Engine
## Unreal-Inspired Modular Design for HTML5 / Android

---

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        RAMAI ENGINE                             │
├──────────────┬──────────────┬──────────────┬────────────────────┤
│   CORE       │  RENDERING   │  GAMEPLAY    │   PLATFORM         │
│              │              │              │                    │
│ • Engine     │ • Renderer   │ • World      │ • Android WebView  │
│ • EventBus   │ • Materials  │ • Actor      │ • Input (Touch)    │
│ • AssetMgr   │ • Lighting   │ • Component  │ • Audio (WebAudio) │
│ • Timer      │ • Shadows    │ • System     │ • Storage          │
│ • Math       │ • PostFX     │ • Physics    │ • AdMob            │
│ • Pool       │ • Particles  │ • Animation  │ • Orientation      │
│              │ • LOD        │ • AI         │                    │
└──────────────┴──────────────┴──────────────┴────────────────────┘
```

---

## Module Breakdown

### 1. CORE MODULE (`engine/core/`)

#### Engine.js — Main entry point (like UE's GEngine)
```javascript
class Engine {
    static instance = null;
    
    constructor(config) {
        this.config = config;          // EngineConfig
        this.world = null;             // Active World
        this.renderer = null;          // RenderSystem
        this.physics = null;           // PhysicsSystem
        this.audio = null;             // AudioSystem
        this.input = null;             // InputSystem
        this.assets = null;            // AssetManager
        this.ui = null;                // UISystem
        this.timer = null;             // Timer
        this.eventBus = null;          // EventBus
        this._running = false;
        this._lastTime = 0;
    }
    
    async init() { /* boot all systems */ }
    start() { /* begin game loop */ }
    stop() { /* halt game loop */ }
    tick(deltaTime) { /* update all systems */ }
}
```

#### EventBus.js — Decoupled messaging (like UE's Delegates)
```javascript
class EventBus {
    // subscribe(event, callback, priority)
    // emit(event, data)
    // unsubscribe(event, callback)
    // emitDeferred(event, data)  // next frame
}
```

#### ObjectPool.js — Zero-GC object reuse (critical for mobile)
```javascript
class ObjectPool {
    // acquire(type)   → reuse or create
    // release(obj)    → return to pool
    // prewarm(type, count)
}
// Pools for: Bullets, Particles, Enemies, Projectiles, Decals
```

#### Timer.js — Game time management
```javascript
class Timer {
    deltaTime;      // seconds since last frame
    totalTime;      // total elapsed game time
    timeScale;      // 1.0 = normal, 0.5 = slow-mo, 0 = paused
    fixedDeltaTime; // 1/60 for physics
    frameCount;
}
```

---

### 2. WORLD / SCENE MODULE (`engine/world/`)

#### World.js — Container for all Actors (like UE's UWorld)
```javascript
class World {
    actors = new Map();          // id → Actor
    systems = [];                // ordered update systems
    camera = null;               // active CameraActor
    
    spawnActor(ActorClass, transform, config) { }
    destroyActor(actor) { }
    findActorsByTag(tag) { }
    findActorsByClass(ActorClass) { }
    tick(deltaTime) { }
    
    // Spatial queries
    lineTrace(origin, direction, maxDist) { }
    overlapSphere(center, radius) { }
    overlapBox(center, halfExtents) { }
}
```

#### Actor.js — Base game object (like UE's AActor)
```javascript
class Actor {
    id;                          // unique uint32
    name;                        // debug name
    tags = new Set();            // gameplay tags
    transform = new Transform(); // position, rotation, scale
    components = new Map();      // type → Component
    active = true;
    
    addComponent(ComponentClass, config) { }
    getComponent(ComponentClass) { }
    removeComponent(ComponentClass) { }
    
    // Lifecycle
    onSpawn() { }
    onDestroy() { }
    tick(deltaTime) { }
    
    // Convenience
    setPosition(x, y, z) { }
    setRotation(x, y, z) { }
    lookAt(target) { }
}
```

#### Component.js — Behavior unit (like UE's UActorComponent)
```javascript
class Component {
    actor = null;    // owning Actor
    enabled = true;
    
    onAttach(actor) { }
    onDetach() { }
    tick(deltaTime) { }
}

// Built-in Components:
// MeshComponent      — renders a GLB mesh
// CameraComponent    — perspective/ortho camera
// LightComponent     — point/spot/directional light
// RigidBodyComponent — physics body
// ColliderComponent  — collision shape
// AudioComponent     — spatial audio source
// AnimatorComponent  — skeletal animation controller
// ParticleComponent  — particle emitter
// ScriptComponent    — gameplay logic
```

---

### 3. TRANSFORM SYSTEM

```javascript
class Transform {
    // Stored as flat Float32Array for cache efficiency
    _data = new Float32Array(16); // 4x4 matrix
    
    position = new Vec3();
    rotation = new Quat();
    scale    = new Vec3(1,1,1);
    
    // Dirty flag — only recompute matrix when changed
    _dirty = true;
    
    getMatrix() { /* recompute if dirty */ }
    getWorldMatrix() { /* walk parent chain */ }
    
    // Unreal-style helpers
    getForwardVector() { }
    getRightVector() { }
    getUpVector() { }
    
    // Interpolation
    lerp(other, t) { }
    slerp(other, t) { }  // quaternion slerp for rotation
}
```

---

### 4. SYSTEM ARCHITECTURE (ECS-style)

Systems process components in bulk — data-oriented, cache-friendly:

```
Update Order (each frame):
1. InputSystem.update()          — read touch/keyboard
2. ScriptSystem.update()         — run gameplay scripts
3. PhysicsSystem.step()          — fixed timestep (1/60s)
4. AnimationSystem.update()      — bone transforms
5. ParticleSystem.update()       — GPU particle simulation
6. AudioSystem.update()          — spatial audio positions
7. RenderSystem.render()         — draw everything
8. UISystem.render()             — draw HUD on top
9. DebugSystem.render()          — perf HUD, gizmos
```

---

### 5. FILE STRUCTURE

```
engine/
├── core/
│   ├── Engine.js           ← main entry
│   ├── EventBus.js         ← messaging
│   ├── ObjectPool.js       ← zero-GC pooling
│   ├── Timer.js            ← game time
│   └── Math.js             ← Vec2/3/4, Quat, Mat4
├── world/
│   ├── World.js            ← scene container
│   ├── Actor.js            ← base game object
│   ├── Component.js        ← base component
│   └── Transform.js        ← spatial data
├── rendering/
│   ├── RenderSystem.js     ← main renderer
│   ├── MaterialSystem.js   ← PBR materials
│   ├── LightingSystem.js   ← lights + shadows
│   ├── PostFX.js           ← post-processing
│   ├── ParticleSystem.js   ← GPU particles
│   └── LODSystem.js        ← level of detail
├── physics/
│   ├── PhysicsSystem.js    ← world physics
│   ├── RigidBody.js        ← dynamic bodies
│   ├── Collider.js         ← shapes
│   └── Raycast.js          ← queries
├── animation/
│   ├── AnimationSystem.js  ← bone updates
│   ├── AnimationClip.js    ← keyframe data
│   ├── AnimationBlender.js ← blend trees
│   └── StateMachine.js     ← anim state machine
├── audio/
│   ├── AudioSystem.js      ← Web Audio context
│   ├── AudioSource.js      ← spatial emitter
│   └── AudioMixer.js       ← channels + effects
├── input/
│   ├── InputSystem.js      ← unified input
│   ├── TouchInput.js       ← mobile gestures
│   └── VirtualJoystick.js  ← on-screen controls
├── ui/
│   ├── UISystem.js         ← canvas 2D overlay
│   ├── UIElement.js        ← base widget
│   ├── UIButton.js         ← interactive button
│   ├── UILabel.js          ← text display
│   ├── UIProgressBar.js    ← health/progress
│   └── UIPanel.js          ← container
├── assets/
│   ├── AssetManager.js     ← load + cache
│   ├── GLBLoader.js        ← GLB/GLTF loading
│   ├── TextureLoader.js    ← texture loading
│   └── AudioLoader.js      ← audio loading
└── platform/
    ├── AndroidBridge.js    ← Java ↔ JS bridge
    ├── AdMob.js            ← ad integration
    └── Storage.js          ← localStorage wrapper
```

---

### 6. GAME LOOP DESIGN

```javascript
// Fixed timestep physics + variable render (like Unreal)
const FIXED_DT = 1 / 60;  // 16.67ms physics step
let accumulator = 0;

function gameLoop(timestamp) {
    requestAnimationFrame(gameLoop);
    
    const dt = Math.min((timestamp - lastTime) / 1000, 0.05); // cap at 50ms
    lastTime = timestamp;
    
    // Fixed physics steps
    accumulator += dt;
    while (accumulator >= FIXED_DT) {
        physics.step(FIXED_DT);
        accumulator -= FIXED_DT;
    }
    
    // Variable render with interpolation alpha
    const alpha = accumulator / FIXED_DT;
    
    input.update();
    scripts.update(dt);
    animation.update(dt);
    particles.update(dt);
    audio.update(dt);
    renderer.render(alpha);  // interpolate physics state
    ui.render();
    debug.render();
}
```

---

### 7. MEMORY BUDGET (Mobile AAA Target)

| System | Budget | Notes |
|--------|--------|-------|
| Three.js + Engine | 30 MB | Core runtime |
| Active Scene Meshes | 80 MB | GPU + CPU buffers |
| Texture Atlas | 64 MB | Compressed (ETC2/ASTC) |
| Physics World | 10 MB | Rapier WASM |
| Audio Buffers | 20 MB | Decoded PCM |
| UI + Misc | 10 MB | Canvas, DOM |
| **Total** | **~214 MB** | Target: <256 MB |

---

### 8. PERFORMANCE TARGETS

| Metric | Low-End (SD 720G) | Mid (SD 855) | High (SD 888) |
|--------|-------------------|--------------|---------------|
| FPS | 30 stable | 60 stable | 60 + effects |
| Draw Calls | <50 | <100 | <200 |
| Triangles | <200K | <500K | <1M |
| Shadow Map | 512 | 1024 | 2048 |
| Pixel Ratio | 0.75 | 1.0 | 1.5 |
| Post-FX | Off | Bloom only | Full stack |
