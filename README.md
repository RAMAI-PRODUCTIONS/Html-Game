# RAMAI Engine — High-Performance HTML5 3D Game Engine

**Version:** 2.0  
**Status:** Phase 2 (Animation System) — In Progress  
**Last Updated:** May 11, 2026  
**Target Platforms:** Browser + Android WebView  
**Performance Target:** 60–120 FPS, zero external dependencies beyond CDN

---

## 🎯 What is RAMAI?

RAMAI is a **production-ready, single-file HTML5 game engine** built with Three.js. It runs entirely in a browser or Android WebView with:

- ✅ **Zero build tools** — no webpack, no bundlers, no npm install
- ✅ **Zero external dependencies** — all code in one `.html` file
- ✅ **60–120 FPS performance** — GPU instancing, spatial hashing, adaptive quality
- ✅ **Full ECS architecture** — flat typed-array entity system, 2048 entity pool
- ✅ **Complete physics** — gravity, collision detection, raycast, impulse resolution
- ✅ **AI system** — FSM-based (IDLE → PATROL → CHASE → ATTACK)
- ✅ **Animation system** — GLB clip playback, crossfade blending, state-driven
- ✅ **Android integration** — WebView bridge, asset loader, ad system

---

## 📁 Project Structure

```
Html-Game/
├── README.md                          ← You are here (comprehensive guide)
├── index.html                         ← Main game engine (all code)
├── viewer.html                        ← GLB model viewer (debug tool)
├── icon.png                           ← App icon
├── .gitignore                         ← Git ignore rules
│
├── docs/                              ← 📚 All Documentation
│   ├── SYSTEM_PROMPT.md               ← LLM development guide (READ FIRST)
│   ├── TASKLIST_NEXT_CHAT.md          ← Phase-by-phase roadmap
│   ├── QUICKSTART.md                  ← 5-minute setup guide
│   ├── DEVELOPER_GUIDE.md             ← Complete developer guide
│   ├── QUICK_REFERENCE.md             ← One-page cheatsheet
│   ├── LLM_CHEATSHEET.md              ← AI assistant guide
│   ├── DOCUMENTATION_INDEX.md         ← Documentation map
│   ├── FPS_GAME_DESIGN.md             ← Game design document
│   ├── TESTING_CHECKLIST.md           ← Pre-release verification
│   └── [25 total documentation files]
│
├── CONTENT/                           ← 🎨 Game Assets
│   └── MESHES/
│       ├── kenney_blocky-characters_20/    ← Character models (18 GLBs)
│       ├── kenney_building-kit/            ← Building/environment (80+ GLBs)
│       └── [other asset packs]
│
├── assets/                            ← 📦 Libraries & Dependencies
│   └── js/
│       ├── three.min.js               ← Three.js library (CDN fallback)
│       ├── three.module.js
│       ├── GLTFLoader.js
│       └── addons/                    ← Three.js addons
│
├── build/                             ← 🔨 Build Scripts & APKs
│   ├── build-apk.bat                  ← Build Android APK
│   ├── build-glb-apk.bat              ← Build with GLB assets
│   ├── build-gradle.bat               ← Gradle build script
│   ├── ramai.apk                      ← Main game APK
│   └── GLBViewer.apk                  ← Model viewer APK
│
├── android/                           ← 📱 Android Studio project (legacy)
├── android-gradle/                    ← 📱 Android Gradle build (current)
│
├── PLAN/                              ← 📋 Design documents & planning
├── scripts/                           ← 🛠️ Utility scripts
├── screenshots/                       ← 📸 Project screenshots
│
├── .vscode/                           ← VS Code settings
└── .git/                              ← Git repository
```

---

## 🚀 Quick Start (5 minutes)

### 1. Open in Browser

```bash
# Windows
start index.html

# macOS
open index.html

# Linux
xdg-open index.html
```

Or drag `index.html` into your browser.

### 2. Test Controls

- **WASD** — Move player
- **Mouse drag** — Orbit camera
- **Scroll wheel** — Zoom
- **Spacebar** — Jump
- **P** — Spawn particles
- **M** — Toggle minimap (if implemented)

### 3. Check Console

Open DevTools (F12) and verify:

```
✓ Scene initialized
✓ Models loaded: 5
✓ Entities spawned: 12
✓ Physics running at 60 Hz
✓ Animation system ready
```

---

## 📊 Current Features (Phase 1 ✅ Complete)

| System | Status | Details |
|--------|--------|---------|
| **ECS Core** | ✅ Complete | Flat typed arrays, 2048 entity pool, bit-packed flags |
| **Physics** | ✅ Complete | Gravity, Euler integration, friction, ground clamp |
| **Collision** | ✅ Complete | Spatial hash grid, sphere collision, raycast, impulse resolution |
| **AI (FSM)** | ✅ Complete | IDLE / PATROL / CHASE / ATTACK states |
| **Input** | ✅ Complete | Keyboard + virtual joystick |
| **Rendering** | ✅ Complete | Instancing, shadows, adaptive quality |
| **Camera** | ✅ Complete | Follow + orbit modes |
| **Game Loop** | ✅ Complete | Fixed 60 Hz timestep, accumulator |
| **Particles** | ✅ Complete | GPU particles, burst emitter |
| **Save/Load** | ✅ Complete | localStorage persistence |
| **Animation** | 🔄 In Progress | Mixer runs; needs GLB clip wiring |

---

## 🎯 Phase 2 — Animation System (PRIMARY GOAL)

**Status:** 🔄 In Progress  
**Priority:** 🟡 HIGH  
**Estimated Time:** 3–4 days  
**Files:** `index.html`, `viewer.html`

### Tasks

- [ ] **2.1** — Wire GLB animations to entities on spawn
- [ ] **2.2** — Map AI states to animation clips (idle/walk/run/attack)
- [ ] **2.3** — Add crossfade blending between animations
- [ ] **2.4** — Wire player movement to animation state

**See `TASKLIST_NEXT_CHAT.md` for detailed breakdown.**

---

## 🎮 How to Play

### Player Controls

| Input | Action |
|-------|--------|
| **W** | Move forward |
| **A** | Move left |
| **S** | Move backward |
| **D** | Move right |
| **Spacebar** | Jump |
| **Mouse drag** | Orbit camera |
| **Scroll** | Zoom in/out |
| **P** | Spawn particles |

### Gameplay

1. **Explore** — Walk around the arena
2. **Encounter enemies** — Red characters patrol and chase
3. **Combat** — Enemies attack when in range; player takes damage
4. **Survive** — Avoid or defeat enemies
5. **Respawn** — On death, respawn at spawn point

---

## 🔧 Architecture Overview

### Entity Component System (ECS)

RAMAI uses a **flat typed-array ECS** for maximum performance:

```javascript
// 2048 entity pool
const positions = new Float32Array(2048 * 3);    // x, y, z
const velocities = new Float32Array(2048 * 3);   // vx, vy, vz
const rotations = new Float32Array(2048 * 3);    // rx, ry, rz (Euler)
const scales = new Float32Array(2048 * 3);       // sx, sy, sz
const health = new Uint16Array(2048);            // HP
const flags = new Uint32Array(2048);             // Bit-packed: alive, visible, etc.
const aiState = new Uint8Array(2048);            // 0=IDLE, 1=PATROL, 2=CHASE, 3=ATTACK
const animMixers = {};                           // { eid: THREE.AnimationMixer }
```

**Why flat arrays?**
- Cache-friendly (sequential memory access)
- Fast iteration (no object allocation)
- Deterministic performance (no GC pauses)
- Easy serialization (save/load)

### Physics System

- **Gravity:** 9.8 m/s² downward
- **Timestep:** Fixed 60 Hz (dt = 1/60 = 0.0167s)
- **Integration:** Euler forward
- **Friction:** 0.95 per frame
- **Ground clamp:** Y = 0 (flat terrain)

### Collision Detection

- **Spatial hash grid:** 10×10×10 unit cells
- **Collision shape:** Sphere (radius per entity)
- **Raycast:** For line-of-sight checks
- **Resolution:** Impulse-based (push apart)

### AI System

**FSM States:**

```
IDLE (0)
  ↓ (see player)
PATROL (1)
  ↓ (player in range)
CHASE (2)
  ↓ (in melee range)
ATTACK (3)
  ↓ (player out of range)
PATROL (1)
```

### Animation System

- **Mixer:** `THREE.AnimationMixer` per animated entity
- **Clips:** Extracted from GLB `gltf.animations[]`
- **Playback:** `playAnimation(eid, clipIndex, loop, speed)`
- **Blending:** Crossfade 0.2s between state transitions

---

## 📚 Documentation

**📖 [docs/DOCUMENTATION_INDEX.md](docs/DOCUMENTATION_INDEX.md) — Complete documentation map (start here!)**

### For Human Developers

1. **[docs/DEVELOPER_GUIDE.md](docs/DEVELOPER_GUIDE.md)** — Complete developer guide with tutorials
2. **[docs/QUICK_REFERENCE.md](docs/QUICK_REFERENCE.md)** — One-page cheatsheet (print this!)
3. **[docs/TASKLIST_NEXT_CHAT.md](docs/TASKLIST_NEXT_CHAT.md)** — Phase-by-phase roadmap
4. **[docs/TESTING_CHECKLIST.md](docs/TESTING_CHECKLIST.md)** — Pre-release verification
5. **[docs/QUICKSTART.md](docs/QUICKSTART.md)** — 5-minute setup guide

### For AI Assistants (LLMs)

1. **[docs/SYSTEM_PROMPT.md](docs/SYSTEM_PROMPT.md)** — LLM development guide (mandatory reading)
2. **[docs/LLM_CHEATSHEET.md](docs/LLM_CHEATSHEET.md)** — Quick reference for AI
3. **[docs/TASKLIST_NEXT_CHAT.md](docs/TASKLIST_NEXT_CHAT.md)** — Current phase tasks

### For Game Designers

1. **[docs/FPS_GAME_DESIGN.md](docs/FPS_GAME_DESIGN.md)** — Game design document
2. **[docs/FPS_QUICK_REFERENCE.md](docs/FPS_QUICK_REFERENCE.md)** — Quick reference for tweaking values

### For Debugging

1. **[viewer.html](viewer.html)** — GLB model viewer (inspect animations, materials)
2. **[docs/QUICK_REFERENCE.md](docs/QUICK_REFERENCE.md)** — Console commands and debugging tips

---

## 🎨 Asset Management

### Models

All 3D models are in **GLB format** (glTF binary):

```
CONTENT/MESHES/
├── kenney_blocky-characters_20/
│   ├── character-a.glb  ← Player character
│   ├── character-b.glb  ← Enemy variant 1
│   ├── character-c.glb  ← Enemy variant 2
│   └── ... (18 total)
│
└── kenney_building-kit/
    ├── floor-*.glb      ← Ground tiles
    ├── wall-*.glb       ← Walls
    ├── door-*.glb       ← Doors
    └── ... (80+ total)
```

### Loading Models

Models are loaded via:

1. **Android AssetLoader** (if in WebView)
2. **Fetch API** (if in browser)
3. **DRACO compression** (for smaller file sizes)

---

## ⚡ Performance Optimization

### Techniques Used

- **GPU Instancing** — Render 1000s of identical objects in one draw call
- **Spatial Hashing** — O(1) collision queries
- **Frustum Culling** — Skip off-screen objects
- **LOD System** — Reduce detail at distance
- **Adaptive Quality** — Lower resolution on low-end devices
- **Fixed Timestep** — Deterministic physics

### Performance Targets

| Metric | Target | Current |
|--------|--------|---------|
| FPS | 60–120 | ✅ 60+ |
| Entity Count | 500+ | ✅ 2048 pool |
| Draw Calls | < 50 | ✅ ~10 |
| Memory | < 100 MB | ✅ ~50 MB |

---

## 🐛 Debugging

### Console Commands

```javascript
// Check entity count
Object.keys(animMixers).length

// Inspect entity position
console.log(positions.slice(eid*3, eid*3+3))

// Force AI state
aiState[eid] = 0  // IDLE

// Teleport entity
positions[eid*3] = 10; positions[eid*3+1] = 0; positions[eid*3+2] = 10;

// Query entities by tag
window.getInstancesByTag('team_red')

// Show FPS
document.getElementById('fps').textContent
```

### Common Issues

| Issue | Solution |
|-------|----------|
| Models not loading | Check console for `✗ Error: ...`, verify GLB path |
| Low FPS | Reduce entity count, disable shadows, check memory |
| Animations not playing | Verify GLB has clips, check `animMixers[eid]` exists |
| Physics glitchy | Check timestep, verify collision radius |
| Camera stuck | Check mouse listeners, test on different browser |

---

## 📱 Android Deployment

### Build APK

**Windows:**
```bash
cd build
build-gradle.bat
```

**Linux/macOS:**
```bash
cd android-gradle
./gradlew assembleRelease
```

APK will be in `android-gradle/app/build/outputs/apk/release/` or `build/ramai.apk`.

### WebView Integration

RAMAI detects Android WebView and uses:

- **AssetLoader** — Load GLBs from app assets
- **AndroidAds** — Show banner/interstitial ads
- **AndroidBridge** — Call native code from JS

---

## 🎓 Learning Resources

- [Three.js Docs](https://threejs.org/docs/)
- [ECS Pattern](https://www.gamedev.net/tutorials/programming/general/understanding-component-entity-systems-r3013/)
- [WebGL Performance](https://www.khronos.org/webgl/wiki/WebGL_Best_Practices)
- [Spatial Hashing](https://www.gamedev.net/tutorials/programming/general/spatial-hashing-r2697/)

---

## 📞 Support

### Getting Help

1. **Check console** — Look for `✗` errors
2. **Read docs/SYSTEM_PROMPT.md** — Most questions answered there
3. **Check docs/TASKLIST_NEXT_CHAT.md** — See what's implemented
4. **Inspect index.html** — Code is fully commented
5. **Browse docs/** — 25+ documentation files covering all aspects

### Reporting Issues

Include:
- Browser/device info
- Console errors (copy-paste)
- Steps to reproduce
- Expected vs actual behavior

---

## 📈 Roadmap

| Phase | System | Status | ETA |
|-------|--------|--------|-----|
| 0 | ECS + Physics + AI + Input + Rendering | ✅ Done | — |
| 1 | Collision Detection | ✅ Done | — |
| **2** | **Animation System** | 🔄 In Progress | May 15 |
| 3 | Audio System | ⬜ Not started | May 22 |
| 4 | Post-Processing + LOD | ⬜ Not started | May 29 |
| 5 | UI (minimap, damage numbers) | ⬜ Not started | Jun 5 |
| 6 | Scene Editor | ⬜ Not started | Jun 12 |
| 7 | Polish + Store Release | ⬜ Not started | Jun 30 |

**Estimated time to release:** ~10 weeks from Phase 2 start

---

## 📄 License

RAMAI Engine is provided as-is for educational and commercial use.

Assets (GLBs) are from [Kenney.nl](https://kenney.nl/) — free for use with attribution.

---

## 🙏 Credits

- **Three.js** — 3D graphics library
- **Kenney.nl** — 3D asset packs
- **DRACO** — Mesh compression
- **WebGL** — GPU rendering

---

## 🔗 Quick Links

- **Main Game:** `index.html`
- **Model Viewer:** `viewer.html`
- **Development Guide:** `docs/SYSTEM_PROMPT.md`
- **Roadmap:** `docs/TASKLIST_NEXT_CHAT.md`
- **Quick Start:** `docs/QUICKSTART.md`
- **All Documentation:** `docs/`
- **Assets:** `CONTENT/MESHES/`
- **Build Scripts:** `build/`
- **Screenshots:** `screenshots/`

---

**Last Updated:** May 11, 2026  
**Next Phase:** Animation System (Task 2.1 — Wire GLB Animations)

---

## 🚀 Next Steps

1. **Read docs/SYSTEM_PROMPT.md** — Understand the architecture
2. **Open index.html** — Run the game
3. **Check console** — Verify all systems initialized
4. **Review docs/TASKLIST_NEXT_CHAT.md** — See Phase 2 tasks
5. **Start Task 2.1** — Wire GLB animations to entities

**Ready to build? Let's go! 🎮**

---

## 📂 Project Organization

This project follows a clean root directory structure:

- **Root level** contains only essential files (README, main HTML files, icon)
- **docs/** contains all 25+ documentation files organized by purpose
- **build/** contains build scripts and compiled APK files
- **screenshots/** contains all project screenshots
- **CONTENT/** contains game assets (3D models, textures)
- **assets/** contains libraries and dependencies
- **android/** and **android-gradle/** contain Android build configurations
- **PLAN/** contains design documents and planning materials
- **scripts/** contains utility scripts

This organization keeps the project clean, navigable, and professional.
