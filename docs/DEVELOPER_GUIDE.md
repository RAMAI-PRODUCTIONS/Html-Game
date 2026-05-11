# RAMAI Engine — Developer Guide

**Version:** 2.0  
**Last Updated:** May 11, 2026  
**Audience:** Human developers working on RAMAI Engine

---

## 👋 Welcome

This guide will help you understand, modify, and extend RAMAI Engine. Whether you're fixing bugs, adding features, or just exploring the codebase, this is your starting point.

---

## 📚 Table of Contents

1. [Getting Started](#getting-started)
2. [Project Structure](#project-structure)
3. [Architecture Overview](#architecture-overview)
4. [Code Organization](#code-organization)
5. [Common Tasks](#common-tasks)
6. [Debugging](#debugging)
7. [Performance Optimization](#performance-optimization)
8. [Testing](#testing)
9. [Deployment](#deployment)
10. [FAQ](#faq)

---

## 🚀 Getting Started

### Prerequisites

- **Browser:** Chrome, Firefox, Edge, or Safari (latest version)
- **Text Editor:** VS Code, Sublime, or any editor with HTML/JS support
- **Optional:** Android Studio (for APK builds)

### 5-Minute Setup

1. **Clone or download** the project
2. **Open `index.html`** in your browser
3. **Check console** (F12) for initialization logs
4. **Test controls:** WASD to move, mouse to orbit

That's it! No npm install, no build step, no configuration.

---

## 📁 Project Structure

```
Html-Game/
│
├── 📄 index.html                    ← Main game (ALL CODE HERE)
├── 📄 viewer.html                   ← GLB model viewer (debug tool)
│
├── 📚 Documentation
│   ├── README.md                    ← Project overview (start here)
│   ├── SYSTEM_PROMPT.md             ← LLM development guide
│   ├── LLM_CHEATSHEET.md            ← Quick reference for AI
│   ├── DEVELOPER_GUIDE.md           ← This file
│   ├── TASKLIST_NEXT_CHAT.md        ← Phase roadmap
│   ├── QUICKSTART.md                ← 5-minute setup
│   └── TESTING_CHECKLIST.md         ← Pre-release verification
│
├── 🎨 Assets
│   ├── CONTENT/MESHES/              ← 3D models (GLB format)
│   │   ├── kenney_blocky-characters_20/  ← 18 character models
│   │   └── kenney_building-kit/          ← 80+ building pieces
│   └── assets/js/                   ← Three.js libraries (CDN fallback)
│
├── 📱 Android
│   ├── android/                     ← Android Studio project (legacy)
│   └── android-gradle/              ← Gradle build (current)
│
└── 🛠️ Scripts
    ├── build-apk.bat                ← Build APK (Windows)
    ├── build-glb-apk.bat            ← Build with GLB assets
    └── build-gradle.bat             ← Gradle build wrapper
```

---

## 🏗️ Architecture Overview

### Entity Component System (ECS)

RAMAI uses a **data-oriented ECS** with flat typed arrays:

```javascript
// Instead of this (OOP):
class Entity {
  constructor() {
    this.position = { x: 0, y: 0, z: 0 };
    this.velocity = { x: 0, y: 0, z: 0 };
    this.health = 100;
  }
}
const entities = [new Entity(), new Entity(), ...];

// We do this (ECS):
const positions = new Float32Array(2048 * 3);  // x,y,z for 2048 entities
const velocities = new Float32Array(2048 * 3);
const health = new Uint16Array(2048);

// Access entity 5's position:
const x = positions[5*3];
const y = positions[5*3+1];
const z = positions[5*3+2];
```

**Why?**
- **Performance:** Cache-friendly, no object allocation, no GC pauses
- **Simplicity:** Easy to serialize (save/load)
- **Scalability:** 2048 entities with minimal overhead

### Systems

Systems are functions that process components:

```javascript
function physicsSystem(dt) {
  for (let eid = 0; eid < MAX_ENTITIES; eid++) {
    if (!(flags[eid] & FLAG_ALIVE)) continue;
    
    // Apply gravity
    velocities[eid*3+1] -= 9.8 * dt;
    
    // Update position
    positions[eid*3]   += velocities[eid*3] * dt;
    positions[eid*3+1] += velocities[eid*3+1] * dt;
    positions[eid*3+2] += velocities[eid*3+2] * dt;
    
    // Ground clamp
    if (positions[eid*3+1] < 0) {
      positions[eid*3+1] = 0;
      velocities[eid*3+1] = 0;
      flags[eid] |= FLAG_ON_GROUND;
    }
  }
}
```

### Game Loop

```javascript
let accumulator = 0;
const FIXED_DT = 1/60;  // 60 Hz physics

function gameLoop(currentTime) {
  requestAnimationFrame(gameLoop);
  
  const deltaTime = (currentTime - lastTime) / 1000;
  lastTime = currentTime;
  accumulator += deltaTime;
  
  // Fixed timestep for deterministic physics
  while (accumulator >= FIXED_DT) {
    inputSystem(FIXED_DT);
    physicsSystem(FIXED_DT);
    collisionSystem(FIXED_DT);
    aiSystem(FIXED_DT);
    animationSystem(FIXED_DT);
    accumulator -= FIXED_DT;
  }
  
  // Render at display refresh rate
  cameraSystem();
  renderSystem();
  hudSystem();
}
```

**Key Points:**
- Physics runs at **exactly 60 Hz** (deterministic)
- Rendering runs at **display refresh rate** (smooth)
- Accumulator handles variable frame times

---

## 📝 Code Organization

`index.html` is organized into labeled sections:

### Section A — Startup Config

```javascript
const startupConfig = {
  models: [...],    // 3D models to load
  camera: {...},    // Camera settings
  lights: [...],    // Scene lighting
  culling: {...},   // Performance settings
  fog: {...}        // Atmospheric fog
};
```

**This is the "data file" for your scene.** Change values here to modify the game without touching code.

### Section B — ECS Data Structures

```javascript
const MAX_ENTITIES = 2048;
const positions = new Float32Array(MAX_ENTITIES * 3);
const velocities = new Float32Array(MAX_ENTITIES * 3);
// ... all component arrays
```

**Add new components here** when extending the engine.

### Section C — Systems

- **C1:** Physics System
- **C2:** Collision System
- **C3:** AI System
- **C4:** Input System
- **C5:** Camera System
- **C6:** Animation System

**Modify gameplay logic here.**

### Section D — Rendering

```javascript
function renderSystem() {
  // Update Three.js scene from ECS data
  // Sync transforms, visibility, etc.
}
```

**Bridge between ECS and Three.js.**

### Section E — Asset Loading

```javascript
function loadGLBFromAssets(path) { ... }
function spawnEntity(modelName, x, y, z, vx, vy, vz) { ... }
```

**Handles GLB loading and entity spawning.**

### Section F — Game Loop

```javascript
function gameLoop(currentTime) { ... }
gameLoop(performance.now());
```

**Entry point — starts the engine.**

---

## 🛠️ Common Tasks

### 1. Add a New 3D Model

**Step 1:** Place GLB file in `CONTENT/MESHES/`

**Step 2:** Add to `startupConfig.models[]` (Section A):

```javascript
{
  name: "my_model",
  glbPath: "CONTENT/MESHES/my_model.glb",
  instances: [
    {
      position: { x: 0, y: 0, z: 0 },
      rotation: { x: 0, y: 0, z: 0 },
      scale: { x: 1, y: 1, z: 1 },
      tags: ["static", "ground"]
    }
  ],
  castShadow: false,
  receiveShadow: true
}
```

**Step 3:** Reload page — model loads automatically.

### 2. Spawn a Dynamic Entity

```javascript
// In Section E or wherever you need it:
const eid = spawnEntity("character-b", 10, 0, 10, 0, 0, 0);

// Entity now has:
// - Position (10, 0, 10)
// - Velocity (0, 0, 0)
// - Physics enabled
// - Collision enabled
// - AI enabled (if configured)
```

### 3. Add a New AI State

**Step 1:** Define state constant (Section B):

```javascript
const AI_IDLE = 0;
const AI_PATROL = 1;
const AI_CHASE = 2;
const AI_ATTACK = 3;
const AI_FLEE = 4;  // ← New state
```

**Step 2:** Add logic in `aiSystem()` (Section C3):

```javascript
case AI_FLEE:
  // Run away from player
  const dx = positions[eid*3] - positions[playerEid*3];
  const dz = positions[eid*3+2] - positions[playerEid*3+2];
  const dist = Math.sqrt(dx*dx + dz*dz);
  
  velocities[eid*3] += (dx/dist) * 0.15;  // Move away
  velocities[eid*3+2] += (dz/dist) * 0.15;
  
  // Transition back to patrol when far enough
  if (dist > 30) {
    aiState[eid] = AI_PATROL;
  }
  break;
```

**Step 3:** Trigger state change:

```javascript
// When entity takes damage:
if (health[eid] < maxHealth[eid] * 0.3) {
  aiState[eid] = AI_FLEE;  // Low HP → flee
}
```

### 4. Add a New Component

**Step 1:** Declare array (Section B):

```javascript
const stamina = new Float32Array(MAX_ENTITIES);  // 0-100
```

**Step 2:** Initialize on spawn (Section E):

```javascript
function spawnEntity(modelName, x, y, z, vx, vy, vz) {
  // ... existing code ...
  
  stamina[eid] = 100;  // Full stamina on spawn
  
  return eid;
}
```

**Step 3:** Use in systems (Section C):

```javascript
function inputSystem(dt) {
  // Sprint drains stamina
  if (keys['Shift'] && stamina[playerEid] > 0) {
    velocities[playerEid*3] *= 2;    // Double speed
    stamina[playerEid] -= 10 * dt;   // Drain stamina
  } else {
    stamina[playerEid] += 5 * dt;    // Regenerate
    stamina[playerEid] = Math.min(stamina[playerEid], 100);
  }
}
```

### 5. Play Animation

```javascript
// Play animation clip on entity
playAnimation(eid, clipIndex, loop, speed);

// Examples:
playAnimation(eid, 0, true, 1.0);   // Idle (loop, normal speed)
playAnimation(eid, 1, true, 1.5);   // Walk (loop, 1.5x speed)
playAnimation(eid, 3, false, 1.0);  // Attack (once, normal speed)
```

### 6. Query Entities by Tag

```javascript
// Get all enemies
const enemies = window.getInstancesByTag('team_red');

// Get all spawn points
const spawns = window.getInstancesByTag('spawn_1');

// Iterate results
enemies.forEach(eid => {
  console.log(`Enemy ${eid} at (${positions[eid*3]}, ${positions[eid*3+2]})`);
});
```

### 7. Raycast for Line-of-Sight

```javascript
// Check if entity can see player
const fromX = positions[eid*3];
const fromY = positions[eid*3+1] + 1;  // Eye height
const fromZ = positions[eid*3+2];

const toX = positions[playerEid*3];
const toY = positions[playerEid*3+1] + 1;
const toZ = positions[playerEid*3+2];

const hit = rayCast(fromX, fromY, fromZ, toX, toY, toZ);

if (!hit.hit) {
  // Clear line of sight — can see player
  aiState[eid] = AI_CHASE;
}
```

---

## 🐛 Debugging

### Console Commands

Open DevTools (F12) and try these:

```javascript
// Check entity count
Object.keys(animMixers).length

// Inspect entity position
console.log(positions.slice(eid*3, eid*3+3))

// Force AI state
aiState[5] = 0  // Set entity 5 to IDLE

// Teleport entity
positions[5*3] = 10;    // X
positions[5*3+1] = 0;   // Y
positions[5*3+2] = 10;  // Z

// Query entities by tag
window.getInstancesByTag('team_red')

// Show FPS
document.getElementById('fps').textContent

// Pause physics (in console, redefine function)
physicsSystem = () => {};

// Slow motion
FIXED_DT = 1/30;  // Half speed
```

### Common Issues

| Issue | Cause | Fix |
|-------|-------|-----|
| **Models not loading** | Wrong path or CORS | Check console for `✗ Error`, verify path in `startupConfig` |
| **Low FPS** | Too many entities or draw calls | Reduce entity count, check instancing, disable shadows |
| **Animations not playing** | Mixer not created or clip missing | Check `animMixers[eid]` exists, verify GLB has animations |
| **Physics glitchy** | Timestep too large or collision bugs | Check `FIXED_DT`, verify collision radius, inspect spatial hash |
| **Camera stuck** | Mouse listeners not working | Check browser console for errors, test on different browser |
| **Entities falling through floor** | Ground clamp disabled | Check `positions[eid*3+1] < 0` logic in `physicsSystem()` |

### Debugging Workflow

1. **Check console** — Look for `✗` errors
2. **Verify initialization** — All systems should log `✓ System initialized`
3. **Inspect HUD** — FPS, status, stats should update
4. **Test controls** — WASD, mouse, spacebar
5. **Check entity data** — Use console commands above
6. **Profile performance** — DevTools Performance tab
7. **Test in viewer.html** — Isolate model/animation issues

---

## ⚡ Performance Optimization

### Profiling

1. Open DevTools (F12)
2. Go to **Performance** tab
3. Click **Record**
4. Play game for 10 seconds
5. Click **Stop**
6. Analyze flame graph

**Look for:**
- Long frames (> 16ms)
- Frequent GC pauses
- Hot functions (called many times)

### Optimization Checklist

- [ ] **Use instancing** — `InstancedMesh` for repeated geometry
- [ ] **Reduce draw calls** — Batch materials, merge geometries
- [ ] **Disable shadows** — Unless visually critical
- [ ] **Lower pixel ratio** — `renderer.setPixelRatio(1)` on mobile
- [ ] **Frustum culling** — Skip off-screen objects
- [ ] **LOD system** — Reduce detail at distance
- [ ] **Spatial hashing** — O(1) collision queries
- [ ] **Object pooling** — Reuse entities instead of creating new
- [ ] **Typed arrays** — Use `Float32Array`, `Uint8Array` for ECS
- [ ] **Avoid allocations** — No `new` in hot loops

### Performance Targets

| Metric | Target | Current |
|--------|--------|---------|
| FPS | 60+ | ✅ 60+ |
| Frame time | < 16ms | ✅ ~10ms |
| Draw calls | < 50 | ✅ ~10 |
| Memory | < 100 MB | ✅ ~50 MB |
| Entity count | 500+ | ✅ 2048 pool |

---

## 🧪 Testing

### Manual Testing Checklist

See `TESTING_CHECKLIST.md` for full list. Quick version:

- [ ] Game loads without errors
- [ ] FPS counter shows 60+
- [ ] Player moves with WASD
- [ ] Camera orbits with mouse
- [ ] Enemies spawn and patrol
- [ ] Enemies chase player when close
- [ ] Enemies attack in melee range
- [ ] Collision works (can't walk through enemies)
- [ ] Animations play (idle, walk, run, attack)
- [ ] Health decreases when hit
- [ ] Player respawns on death
- [ ] Save/load works (localStorage)

### Automated Testing

Currently no automated tests. Future: add unit tests for systems.

---

## 🚀 Deployment

### Browser (Web)

1. **Upload `index.html`** to web server
2. **Upload `CONTENT/` folder** (assets)
3. **Upload `assets/` folder** (Three.js fallback)
4. **Test in browser** — verify CDN loads

**Note:** Ensure CORS headers allow loading GLB files.

### Android (APK)

**Step 1:** Build APK

```bash
cd android-gradle
./gradlew assembleRelease
```

**Step 2:** Sign APK (for release)

```bash
jarsigner -verbose -sigalg SHA256withRSA -digestalg SHA-256 \
  -keystore my-release-key.jks \
  app/build/outputs/apk/release/app-release-unsigned.apk \
  alias_name
```

**Step 3:** Align APK

```bash
zipalign -v 4 app-release-unsigned.apk app-release.apk
```

**Step 4:** Install on device

```bash
adb install app-release.apk
```

### Android WebView Integration

RAMAI detects Android WebView and uses:

- **AssetLoader** — Load GLBs from app assets
- **AndroidAds** — Show banner/interstitial ads
- **AndroidBridge** — Call native code from JS

See `android-gradle/app/src/main/java/` for Java bridge code.

---

## ❓ FAQ

### Q: Why one HTML file?

**A:** Simplicity. No build tools, no dependencies, no configuration. Just open and run.

### Q: Why typed arrays instead of objects?

**A:** Performance. Typed arrays are cache-friendly, avoid GC pauses, and enable 2048+ entities at 60 FPS.

### Q: Why fixed timestep?

**A:** Deterministic physics. Same inputs → same outputs, regardless of frame rate.

### Q: Can I use TypeScript?

**A:** Not directly (no build step). But you can develop in TS and compile to JS, then paste into `index.html`.

### Q: Can I add multiplayer?

**A:** Yes! Add WebSocket or WebRTC for networking. ECS state is easy to serialize.

### Q: Can I use other 3D formats (FBX, OBJ)?

**A:** GLB only. It's the most efficient format for web (binary, compressed, includes animations).

### Q: How do I add sound?

**A:** See Phase 3 in `TASKLIST_NEXT_CHAT.md`. Use Web Audio API with spatial audio.

### Q: Can I use this for commercial projects?

**A:** Yes! RAMAI is provided as-is. Assets (Kenney.nl) require attribution.

### Q: How do I contribute?

**A:** Fork the repo, make changes, test thoroughly, submit PR with clear description.

---

## 📞 Support

### Getting Help

1. **Check console** — Look for `✗` errors
2. **Read SYSTEM_PROMPT.md** — Most questions answered there
3. **Check TASKLIST_NEXT_CHAT.md** — See what's implemented
4. **Inspect index.html** — Code is fully commented
5. **Ask in discussions** — GitHub Discussions (if available)

### Reporting Bugs

Include:
- Browser/device info
- Console errors (copy-paste)
- Steps to reproduce
- Expected vs actual behavior
- Screenshots/video (if visual bug)

---

## 🎓 Learning Resources

- [Three.js Docs](https://threejs.org/docs/)
- [Three.js Examples](https://threejs.org/examples/)
- [ECS Pattern](https://www.gamedev.net/tutorials/programming/general/understanding-component-entity-systems-r3013/)
- [WebGL Performance](https://www.khronos.org/webgl/wiki/WebGL_Best_Practices)
- [Spatial Hashing](https://www.gamedev.net/tutorials/programming/general/spatial-hashing-r2697/)
- [Game Loop](https://gafferongames.com/post/fix_your_timestep/)

---

## 🔗 Quick Links

- **Main Game:** `index.html`
- **Model Viewer:** `viewer.html`
- **LLM Guide:** `SYSTEM_PROMPT.md`
- **LLM Cheatsheet:** `LLM_CHEATSHEET.md`
- **Roadmap:** `TASKLIST_NEXT_CHAT.md`
- **Assets:** `CONTENT/MESHES/`

---

**Happy coding! 🎮**

---

*Last Updated: May 11, 2026*
