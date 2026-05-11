# Task List — Next Chat Session
**Updated:** May 8, 2026  
**Project:** RAMAI Engine — HTML5 Game Engine  
**Current Phase:** Phase 1 (Collision) ✅ DONE → Phase 2 Starting

---

## ✅ Already Implemented (Do NOT re-do)

| System | Status | Notes |
|--------|--------|-------|
| ECS Core | ✅ Complete | Flat typed arrays, 2048 entity pool, bit-packed flags |
| Physics | ✅ Complete | Gravity, Euler integration, friction, ground clamp |
| AI (FSM) | ✅ Complete | IDLE / PATROL / CHASE / ATTACK |
| Input | ✅ Complete | Keyboard + virtual joystick |
| Rendering | ✅ Complete | Instancing, shadows, adaptive quality |
| Camera | ✅ Complete | Follow + orbit modes |
| Game Loop | ✅ Complete | Fixed 60 Hz timestep, accumulator |
| Particles | ✅ Complete | GPU particles, burst emitter, P key |
| Save / Load | ✅ Complete | localStorage, player + entity state |
| **Collision Detection** | ✅ Complete | Spatial hash grid, sphere collision, raycast, resolveCollision |
| **Animation (mixer)** | ✅ Partial | THREE.AnimationMixer loop runs; `playAnimation()` exists; needs GLB clip wiring |

---

## 🎯 Phase 2 — Animation System (PRIMARY GOAL)

**Priority:** 🟡 HIGH — Characters are static; animation gives AAA feel  
**Estimated Time:** 3–4 days  
**Files:** `index.html`, `viewer.html`

### Task 2.1 — Wire GLB Animations to Entities

- [ ] In `spawnEntity()` / GLB load callback, extract `gltf.animations[]`
- [ ] Store clips in `animClips[]` array (or per-entity in `animMixers`)
- [ ] Create `THREE.AnimationMixer` for each spawned entity that has animations
- [ ] Store mixer in `animMixers[eid]`
- [ ] Call `playAnimation(eid, 0, true, 1.0)` on spawn (idle clip)
- [ ] **Test:** Spawn a character-a.glb and verify it animates

**Code location:** Section E (Asset System) → GLB load callback → `spawnEntity()`

---

### Task 2.2 — State-Driven Animation

- [ ] Map AI states to animation clips:
  - `AI_IDLE (0)` → clip "idle" or index 0
  - `AI_PATROL (1)` → clip "walk" or index 1
  - `AI_CHASE (2)` → clip "run" or index 2
  - `AI_ATTACK (3)` → clip "attack" or index 3
- [ ] In `aiSystem()`, call `playAnimation()` when state changes
- [ ] Add `AI_PREV_STATE` array (Uint8Array) to detect state transitions
- [ ] **Test:** Enemy transitions from walk → run → attack as player approaches

**Code location:** Section C3 (AI System) → state transition branches

---

### Task 2.3 — Crossfade Blending

- [ ] In `playAnimation()`, use `action.crossFadeTo(newAction, 0.2, true)` instead of hard-cut
- [ ] Keep reference to previous action for crossfade
- [ ] **Test:** Smooth blend between idle and walk

**Code location:** Section C6 (Animation System) → `playAnimation()`

---

### Task 2.4 — Player Animation

- [ ] Detect player movement (velocity magnitude > 0.1)
- [ ] Play walk/run clip when moving, idle when still
- [ ] Play jump clip on spacebar (if clip exists)
- [ ] **Test:** Player character animates while moving

**Code location:** Section C4 (Input System) → player movement block

---

## 🎯 Phase 3 — Audio System

**Priority:** 🟡 MEDIUM — No sound currently  
**Estimated Time:** 2–3 days  
**Files:** `index.html`, `viewer.html`

### Task 3.1 — Init Web Audio Context

- [ ] Create `AudioContext` on first user gesture (click/touch)
- [ ] Store in `audioContext` variable (stub already exists)
- [ ] Load audio files via XHR + `decodeAudioData`
- [ ] Cache in `audioBuffers` map (stub already exists)
- [ ] **Test:** `audioContext.state === 'running'` after first click

---

### Task 3.2 — Play SFX

- [ ] Implement `playSound(name, x, y, z, volume, pitch)` (stub exists)
- [ ] Create `PannerNode` for 3D spatial audio
- [ ] Set panner position from entity world position
- [ ] Apply random pitch variation (±10%)
- [ ] **Test:** Play footstep sound at player position

---

### Task 3.3 — Footstep System

- [ ] Detect player on ground + moving
- [ ] Trigger footstep every 0.4s (timer-based)
- [ ] Vary pitch slightly each step
- [ ] **Test:** Hear footsteps while walking

---

### Task 3.4 — Combat Sounds

- [ ] Play attack sound on AI entering ATTACK state
- [ ] Play hit sound on collision between player and enemy
- [ ] Play death sound on HP reaching 0
- [ ] **Test:** Hear sounds during combat

---

## 🎯 Phase 4 — Visual Polish

**Priority:** 🟢 LOW — Nice to have  
**Estimated Time:** 2 days

### Task 4.1 — Post-Processing (Bloom + FXAA)

- [ ] Add `THREE.EffectComposer` (needs addon — check if available in `assets/js/addons/`)
- [ ] Add `UnrealBloomPass` (threshold 0.8, strength 0.3, radius 0.5)
- [ ] Add `ShaderPass` with FXAA shader
- [ ] Wire POST-FX button to toggle composer on/off
- [ ] **Test:** Toggle post-processing, verify bloom on bright areas

---

### Task 4.2 — LOD System

- [ ] Implement `lodSystem()` (stub exists, LOD_LEVEL array exists)
- [ ] Calculate distance from camera to each entity
- [ ] Set LOD_LEVEL: 0 = HIGH (<20u), 1 = MED (<50u), 2 = LOW (>50u)
- [ ] Swap InstancedMesh or reduce draw calls per tier
- [ ] **Test:** FPS improves with 500+ entities at distance

---

## 🎯 Phase 5 — UI Framework

**Priority:** 🟡 MEDIUM  
**Estimated Time:** 3 days

### Task 5.1 — Minimap

- [ ] Draw minimap on canvas overlay (bottom-right corner, 120×120px)
- [ ] Draw player as white dot
- [ ] Draw enemies as red dots
- [ ] Draw buildings as grey squares
- [ ] Update every 10 frames
- [ ] **Test:** Minimap shows correct positions

---

### Task 5.2 — Damage Numbers

- [ ] On hit, create floating text at entity position
- [ ] Animate upward + fade out over 1s
- [ ] Color: white = normal, yellow = crit, red = player damage
- [ ] **Test:** Numbers appear on attack

---

### Task 5.3 — Enemy Health Bars

- [ ] Draw health bar above each visible enemy (canvas 2D)
- [ ] Only show when HP < MAX_HP
- [ ] Fade out after 3s of no damage
- [ ] **Test:** Health bars appear when enemies take damage

---

## 🎯 Phase 6 — Scene Editor

**Priority:** 🟢 LOW  
**Estimated Time:** 4 days

### Task 6.1 — Entity Selection

- [ ] Raycast from mouse click into scene
- [ ] Highlight selected entity (outline or color change)
- [ ] Show entity ID + component values in panel
- [ ] **Test:** Click entity, see its data

---

### Task 6.2 — Transform Gizmo

- [ ] Draw XYZ arrows at selected entity
- [ ] Drag arrow to move entity
- [ ] Update ECS position arrays
- [ ] **Test:** Drag entity in editor mode

---

### Task 6.3 — Save Scene

- [ ] Serialize all alive entities to JSON
- [ ] Save to localStorage (or download as file)
- [ ] Load scene on startup if saved
- [ ] **Test:** Save scene, reload page, entities restored

---

## 📋 Pre-Session Checklist

Before starting Phase 2, verify:
- [ ] Open `index.html` in browser — game runs at 60fps
- [ ] Player moves with WASD
- [ ] Enemies chase and attack player
- [ ] Collision works (player can't walk through enemies)
- [ ] Check browser console — no errors
- [ ] Confirm `animMixers` object exists in console: `Object.keys(animMixers)`
- [ ] Confirm GLB characters have animations: load `character-a.glb` in viewer.html

---

## 🎯 Success Criteria — Phase 2 Complete

- ✅ Characters animate (idle, walk, run, attack)
- ✅ Smooth crossfade between animation states
- ✅ Player animates based on movement
- ✅ Enemies animate based on AI state
- ✅ FPS stays above 30 with animations running
- ✅ No console errors

---

## 💡 Quick-Start Prompt for Next Chat

Copy-paste this to start immediately:

```
Continue RAMAI Engine development — Phase 2: Animation System.

Current state:
- Collision detection is FULLY implemented (spatial hash, sphere collision, raycast)
- THREE.AnimationMixer loop runs in animationSystem(dt)
- playAnimation(eid, clipIndex, loop, speed) function exists
- animMixers{} object exists

Tasks:
1. Wire GLB animations to entities on spawn (extract gltf.animations, create mixer)
2. Map AI states to animation clips (idle/walk/run/attack)
3. Add crossfade blending in playAnimation()
4. Wire player movement to animation state

Files: index.html, viewer.html
GLB characters: CONTENT/MESHES/kenney_blocky-characters_20/character-a.glb (etc.)
Reference: TASKLIST_NEXT_CHAT.md

Start with Task 2.1 — Wire GLB Animations to Entities.
```

---

## 📊 Overall Progress

| Phase | System | Status | Priority |
|-------|--------|--------|----------|
| 0 | ECS + Physics + AI + Input + Rendering | ✅ Done | — |
| 1 | Collision Detection | ✅ Done | — |
| **2** | **Animation System** | 🔄 In Progress | 🟡 HIGH |
| 3 | Audio System | ⬜ Not started | 🟡 MEDIUM |
| 4 | Post-Processing + LOD | ⬜ Not started | 🟢 LOW |
| 5 | UI (minimap, damage numbers) | ⬜ Not started | 🟡 MEDIUM |
| 6 | Scene Editor | ⬜ Not started | 🟢 LOW |
| 7 | Polish + Store Release | ⬜ Not started | — |

**Estimated time to release:** ~10 weeks from Phase 2 start

---

**Updated:** May 8, 2026  
**Total remaining tasks:** ~25 tasks across 5 phases
