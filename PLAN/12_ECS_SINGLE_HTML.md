# ECS Architecture — Single HTML File
## NES-Era Data-Oriented Design for the Browser

> **Core rule:** Everything lives in ONE `.html` file. No bundler, no npm, no modules.
> Architecture is inspired by NES/SNES era constraints: flat arrays, typed buffers,
> bit-packed flags, fixed-size pools, zero heap allocation in the hot loop.

---

## Philosophy: Think Like the NES

| NES Concept | Our Equivalent |
|-------------|---------------|
| OAM (sprite table) | `Float32Array` component arrays |
| CHR-ROM (tile bank) | Texture cache + InstancedMesh pool |
| PPU (picture processing) | Three.js renderer + instancing |
| CPU cycles budget | 16ms frame budget (60fps) |
| Zero-page RAM | Hot component arrays (cache-line friendly) |
| Bank switching | LOD / quality tier switching |
| Sprite flags byte | `Uint8Array` component flags (bit-packed) |
| Fixed sprite count | Pre-allocated entity pool (MAX_ENTITIES = 2048) |

---

## Single-HTML File Layout

```
game.html
├── <head>
│   └── <style>  ← ALL CSS inline
├── <body>
│   ├── <canvas id="c">
│   ├── <div id="hud">
│   ├── <div id="ui">
│   └── <script>  ← ALL JS inline, in order:
│       ├── 1. CONSTANTS & CONFIG
│       ├── 2. ANDROID PATCHES (fetch + Image.src)
│       ├── 3. THREE.JS (inlined or src=)
│       ├── 4. GLTFLOADER (inlined or src=)
│       ├── 5. ECS CORE  (World, entity IDs, component arrays)
│       ├── 6. SYSTEMS   (Render, Physics, Input, AI, Audio...)
│       ├── 7. ASSETS    (loader, texture cache, mesh pool)
│       ├── 8. GAME INIT (scene setup, entity spawning)
│       └── 9. GAME LOOP (requestAnimationFrame)
```

---

## ECS Core — Flat Typed Arrays (NES OAM Style)

```javascript
// ═══════════════════════════════════════════════════════════════════
// ECS CORE — all component data in flat typed arrays
// Entity = integer ID (0..MAX-1). No objects, no GC pressure.
// Like NES OAM: entity 5 → bytes [5*4 .. 5*4+3] in the sprite table.
// ═══════════════════════════════════════════════════════════════════

var MAX_E = 2048;          // max live entities — power of 2
var _eid  = 0;             // next entity ID counter
var _free = [];            // recycled IDs (dead entities)

// ── Component arrays — one slot per entity ───────────────────────
// Position/velocity: Float32Array for SIMD-friendly layout
var PX = new Float32Array(MAX_E);   // position X
var PY = new Float32Array(MAX_E);   // position Y
var PZ = new Float32Array(MAX_E);   // position Z
var VX = new Float32Array(MAX_E);   // velocity X
var VY = new Float32Array(MAX_E);   // velocity Y
var VZ = new Float32Array(MAX_E);   // velocity Z
var RY = new Float32Array(MAX_E);   // rotation Y (yaw only for most entities)

// Health / stats — Int16 saves memory vs Float32
var HP     = new Int16Array(MAX_E); // current health
var HP_MAX = new Int16Array(MAX_E); // max health

// Flags — bit-packed Uint8 (8 flags per entity, 1 byte each)
// Bit 0: ALIVE  Bit 1: VISIBLE  Bit 2: PHYSICS  Bit 3: AI
// Bit 4: PLAYER Bit 5: ENEMY    Bit 6: STATIC   Bit 7: DIRTY
var FLAGS = new Uint8Array(MAX_E);
var F_ALIVE   = 1 << 0;
var F_VISIBLE = 1 << 1;
var F_PHYSICS = 1 << 2;
var F_AI      = 1 << 3;
var F_PLAYER  = 1 << 4;
var F_ENEMY   = 1 << 5;
var F_STATIC  = 1 << 6;
var F_DIRTY   = 1 << 7;  // transform changed this frame

// Mesh handle — index into meshPool[] (which InstancedMesh + which instance slot)
var MESH_ID  = new Int16Array(MAX_E);  // which InstancedMesh (-1 = none)
var MESH_IDX = new Int16Array(MAX_E);  // which instance slot in that InstancedMesh

// Type tag — Uint8 (0=none 1=player 2=enemy 3=vehicle 4=building 5=pickup)
var TYPE = new Uint8Array(MAX_E);
var T_NONE     = 0;
var T_PLAYER   = 1;
var T_ENEMY    = 2;
var T_VEHICLE  = 3;
var T_BUILDING = 4;
var T_PICKUP   = 5;

// ── Entity lifecycle ─────────────────────────────────────────────
function createEntity() {
    var id = _free.length ? _free.pop() : _eid++;
    if (id >= MAX_E) { console.error('Entity pool full!'); return -1; }
    FLAGS[id] = F_ALIVE | F_VISIBLE;
    PX[id] = PY[id] = PZ[id] = 0;
    VX[id] = VY[id] = VZ[id] = 0;
    RY[id] = 0;
    HP[id] = HP_MAX[id] = 100;
    MESH_ID[id] = MESH_IDX[id] = -1;
    TYPE[id] = T_NONE;
    return id;
}

function destroyEntity(id) {
    FLAGS[id] = 0;          // clear ALIVE bit — systems skip it
    MESH_ID[id] = -1;
    _free.push(id);         // recycle the slot
}

// ── Query helpers — iterate only alive entities of a type ────────
// Returns a reused scratch array — do NOT store the reference.
var _queryBuf = new Int32Array(MAX_E);
var _queryLen = 0;

function queryType(type) {
    _queryLen = 0;
    for (var i = 0; i < _eid; i++) {
        if ((FLAGS[i] & F_ALIVE) && TYPE[i] === type) _queryBuf[_queryLen++] = i;
    }
    return _queryLen; // caller reads _queryBuf[0.._queryLen-1]
}

function queryFlag(flag) {
    _queryLen = 0;
    for (var i = 0; i < _eid; i++) {
        if (FLAGS[i] & flag) _queryBuf[_queryLen++] = i;
    }
    return _queryLen;
}
```

---

## Systems — Each Is a Plain Function Called Each Frame

```javascript
// ═══════════════════════════════════════════════════════════════════
// SYSTEMS — pure functions over component arrays
// Called in fixed order from the game loop. No classes, no 'this'.
// ═══════════════════════════════════════════════════════════════════

// ── Physics System — Euler integration, AABB ground clamp ────────
// dt in seconds (fixed timestep: 1/60 = 0.01667)
function physicsSystem(dt) {
    var GRAVITY = -20.0;
    for (var i = 0; i < _eid; i++) {
        if (!(FLAGS[i] & F_ALIVE))    continue;
        if (!(FLAGS[i] & F_PHYSICS))  continue;
        if (FLAGS[i] & F_STATIC)      continue;

        // Gravity
        VY[i] += GRAVITY * dt;

        // Integrate
        PX[i] += VX[i] * dt;
        PY[i] += VY[i] * dt;
        PZ[i] += VZ[i] * dt;

        // Ground clamp (Y=0 is floor)
        if (PY[i] < 0) { PY[i] = 0; VY[i] = 0; }

        // Friction (horizontal only)
        VX[i] *= 0.88;
        VZ[i] *= 0.88;

        FLAGS[i] |= F_DIRTY; // mark transform changed
    }
}

// ── Render Sync System — push dirty transforms to InstancedMesh ──
// Only updates GPU matrices for entities that moved this frame.
var _tmpObj = new THREE.Object3D(); // reused dummy — zero alloc

function renderSyncSystem() {
    for (var i = 0; i < _eid; i++) {
        if (!(FLAGS[i] & F_ALIVE))   continue;
        if (!(FLAGS[i] & F_DIRTY))   continue;  // skip if not moved
        if (!(FLAGS[i] & F_VISIBLE)) continue;

        var mid = MESH_ID[i];
        var idx = MESH_IDX[i];
        if (mid < 0 || idx < 0) continue;

        _tmpObj.position.set(PX[i], PY[i], PZ[i]);
        _tmpObj.rotation.set(0, RY[i], 0);
        _tmpObj.updateMatrix();
        meshPool[mid].setMatrixAt(idx, _tmpObj.matrix);
        meshPool[mid].instanceMatrix.needsUpdate = true;

        FLAGS[i] &= ~F_DIRTY; // clear dirty bit
    }
}

// ── AI System — simple state machine per enemy ───────────────────
// States stored in Uint8Array — no objects, no closures
var AI_STATE  = new Uint8Array(MAX_E);  // 0=idle 1=patrol 2=chase 3=attack
var AI_TIMER  = new Float32Array(MAX_E); // state timer
var AI_TARGET = new Int16Array(MAX_E);   // target entity ID (-1=none)

var AI_IDLE   = 0;
var AI_PATROL = 1;
var AI_CHASE  = 2;
var AI_ATTACK = 3;

var CHASE_RANGE  = 20.0;  // units
var ATTACK_RANGE =  2.5;
var CHASE_SPEED  =  5.0;

function aiSystem(dt) {
    var n = queryFlag(F_AI);
    for (var q = 0; q < n; q++) {
        var i = _queryBuf[q];
        AI_TIMER[i] -= dt;

        // Find player (cached — only search once per frame)
        var pid = _playerEid; // set during init
        if (pid < 0) continue;

        var dx = PX[pid] - PX[i];
        var dz = PZ[pid] - PZ[i];
        var dist = Math.sqrt(dx*dx + dz*dz); // sqrt only for AI — acceptable

        switch (AI_STATE[i]) {
            case AI_IDLE:
                if (dist < CHASE_RANGE) { AI_STATE[i] = AI_CHASE; }
                else if (AI_TIMER[i] <= 0) {
                    AI_STATE[i] = AI_PATROL;
                    AI_TIMER[i] = 2.0 + Math.random() * 3.0;
                }
                break;

            case AI_PATROL:
                // Walk in a random direction until timer expires
                VX[i] += (Math.random() - 0.5) * 0.5;
                VZ[i] += (Math.random() - 0.5) * 0.5;
                if (dist < CHASE_RANGE || AI_TIMER[i] <= 0) AI_STATE[i] = AI_IDLE;
                break;

            case AI_CHASE:
                if (dist > CHASE_RANGE * 1.5) { AI_STATE[i] = AI_IDLE; break; }
                if (dist < ATTACK_RANGE)       { AI_STATE[i] = AI_ATTACK; AI_TIMER[i] = 0.5; break; }
                // Steer toward player
                var spd = CHASE_SPEED * dt;
                VX[i] = (dx / dist) * spd * 60; // pre-multiply by 60 so Euler works
                VZ[i] = (dz / dist) * spd * 60;
                RY[i] = Math.atan2(dx, dz);
                FLAGS[i] |= F_DIRTY;
                break;

            case AI_ATTACK:
                if (AI_TIMER[i] <= 0) {
                    HP[pid] -= 10;
                    AI_TIMER[i] = 0.8; // attack cooldown
                    if (dist > ATTACK_RANGE) AI_STATE[i] = AI_CHASE;
                }
                break;
        }
    }
}

// ── Input System — unified touch + keyboard ──────────────────────
// Stores input state in plain typed arrays — no event objects kept.
var _keys   = new Uint8Array(256);  // keyboard state (1=down)
var _touchX = 0, _touchY = 0;      // last touch position
var _joyX   = 0, _joyZ   = 0;      // virtual joystick output (-1..1)

function setupInput() {
    document.addEventListener('keydown', function(e) { _keys[e.keyCode & 0xFF] = 1; });
    document.addEventListener('keyup',   function(e) { _keys[e.keyCode & 0xFF] = 0; });

    // Virtual joystick — left half of screen
    var joyActive = false, joyBaseX = 0, joyBaseY = 0;
    var JOY_RADIUS = 60; // pixels

    document.addEventListener('touchstart', function(e) {
        for (var t = 0; t < e.changedTouches.length; t++) {
            var touch = e.changedTouches[t];
            if (touch.clientX < window.innerWidth * 0.5) {
                joyActive = true;
                joyBaseX  = touch.clientX;
                joyBaseY  = touch.clientY;
                _joyX = _joyZ = 0;
            }
        }
    }, { passive: true });

    document.addEventListener('touchmove', function(e) {
        if (!joyActive) return;
        for (var t = 0; t < e.changedTouches.length; t++) {
            var touch = e.changedTouches[t];
            if (touch.clientX < window.innerWidth * 0.5) {
                var dx = touch.clientX - joyBaseX;
                var dy = touch.clientY - joyBaseY;
                var len = Math.sqrt(dx*dx + dy*dy);
                if (len > JOY_RADIUS) { dx = dx/len*JOY_RADIUS; dy = dy/len*JOY_RADIUS; }
                _joyX = dx / JOY_RADIUS;  // -1..1
                _joyZ = dy / JOY_RADIUS;  // -1..1
            }
        }
    }, { passive: true });

    document.addEventListener('touchend', function() { joyActive = false; _joyX = _joyZ = 0; }, { passive: true });
}

function inputSystem(dt) {
    if (_playerEid < 0) return;
    var pid = _playerEid;
    var SPEED = 8.0;

    // Keyboard WASD / Arrow keys
    var kx = (_keys[68]||_keys[39]) - (_keys[65]||_keys[37]); // D/Right - A/Left
    var kz = (_keys[83]||_keys[40]) - (_keys[87]||_keys[38]); // S/Down  - W/Up

    // Combine keyboard + joystick
    var mx = kx + _joyX;
    var mz = kz + _joyZ;

    // Clamp to unit circle
    var mlen = Math.sqrt(mx*mx + mz*mz);
    if (mlen > 1) { mx /= mlen; mz /= mlen; }

    if (mlen > 0.05) {
        VX[pid] = mx * SPEED;
        VZ[pid] = mz * SPEED;
        RY[pid] = Math.atan2(mx, mz);
        FLAGS[pid] |= F_DIRTY;
    }

    // Jump — spacebar or tap right half
    if (_keys[32] && PY[pid] === 0) { VY[pid] = 10; _keys[32] = 0; }
}
```

---

## Fixed Timestep Game Loop

```javascript
// ═══════════════════════════════════════════════════════════════════
// GAME LOOP — fixed physics timestep, variable render
// Physics runs at exactly 60Hz regardless of render FPS.
// Render interpolates between physics steps for smooth visuals.
// Same pattern used by NES (fixed 60Hz NTSC) and Quake engine.
// ═══════════════════════════════════════════════════════════════════

var FIXED_DT    = 1 / 60;       // 16.667ms physics step
var MAX_STEPS   = 5;            // max physics steps per frame (prevents spiral of death)
var _accumulator = 0;
var _lastTime    = 0;

// Frame timing — rolling average over 60 frames
var _fpsRing  = new Float32Array(60);
var _fpsHead  = 0;
var _fpsSum   = 0;
var currentFps = 60;
var currentMs  = 16;

function gameLoop(now) {
    requestAnimationFrame(gameLoop);

    var dt = Math.min((now - _lastTime) * 0.001, 0.1); // cap at 100ms
    _lastTime = now;

    // ── FPS rolling average ───────────────────────────────────────
    _fpsSum -= _fpsRing[_fpsHead];
    _fpsRing[_fpsHead] = dt;
    _fpsSum += dt;
    _fpsHead = (_fpsHead + 1) % 60;
    currentFps = Math.round(60 / _fpsSum);
    currentMs  = dt * 1000;

    // ── Fixed timestep physics ────────────────────────────────────
    _accumulator += dt;
    var steps = 0;
    while (_accumulator >= FIXED_DT && steps < MAX_STEPS) {
        inputSystem(FIXED_DT);
        physicsSystem(FIXED_DT);
        aiSystem(FIXED_DT);
        _accumulator -= FIXED_DT;
        steps++;
    }

    // ── Variable render ───────────────────────────────────────────
    renderSyncSystem();
    renderer.render(scene, camera);

    // ── HUD update (every 16 frames = ~4x/sec) ────────────────────
    if ((_fpsHead & 15) === 0) updateHUD();

    // ── Adaptive quality (every 120 frames = ~2x/sec) ─────────────
    if ((_fpsHead & 63) === 0) adaptiveQuality();
}

// Kick off
_lastTime = performance.now();
requestAnimationFrame(gameLoop);
```

---

## Object Pool — Zero Allocation Spawning

```javascript
// ═══════════════════════════════════════════════════════════════════
// OBJECT POOL — pre-allocate everything at startup
// Like NES hardware sprites: fixed count, reuse slots.
// No 'new' in the hot path = no GC pauses.
// ═══════════════════════════════════════════════════════════════════

// meshPool[i] = { mesh: InstancedMesh, used: Int16Array(count), freeSlots: [] }
var meshPool = [];

function registerMeshPool(instancedMesh, maxCount) {
    var entry = {
        mesh:      instancedMesh,
        maxCount:  maxCount,
        used:      new Uint8Array(maxCount),  // 1 = slot taken
        freeSlots: []
    };
    // Pre-fill free list
    for (var i = maxCount - 1; i >= 0; i--) entry.freeSlots.push(i);
    meshPool.push(entry);
    return meshPool.length - 1; // pool ID
}

function allocMeshSlot(poolId) {
    var p = meshPool[poolId];
    if (!p.freeSlots.length) return -1; // pool exhausted
    var slot = p.freeSlots.pop();
    p.used[slot] = 1;
    return slot;
}

function freeMeshSlot(poolId, slot) {
    var p = meshPool[poolId];
    p.used[slot] = 0;
    p.freeSlots.push(slot);
    // Hide the instance by scaling to zero
    _tmpObj.position.set(0, -9999, 0);
    _tmpObj.scale.set(0, 0, 0);
    _tmpObj.updateMatrix();
    p.mesh.setMatrixAt(slot, _tmpObj.matrix);
    p.mesh.instanceMatrix.needsUpdate = true;
}

// ── Spawn helper — creates entity + grabs mesh slot ──────────────
function spawnEntity(type, poolId, x, y, z) {
    var id   = createEntity();
    var slot = allocMeshSlot(poolId);
    if (id < 0 || slot < 0) return -1;

    TYPE[id]     = type;
    PX[id] = x;  PY[id] = y;  PZ[id] = z;
    MESH_ID[id]  = poolId;
    MESH_IDX[id] = slot;
    FLAGS[id]   |= F_DIRTY | F_PHYSICS;
    return id;
}

function despawnEntity(id) {
    var mid = MESH_ID[id];
    var idx = MESH_IDX[id];
    if (mid >= 0 && idx >= 0) freeMeshSlot(mid, idx);
    destroyEntity(id);
}
```

---

## Bit-Width Data Sizing Guide

```
CHOOSE THE SMALLEST TYPE THAT FITS:

Position (world units 0..1000):  Float32  — 4 bytes, ±3.4e38, 7 sig digits
Velocity (-100..100 u/s):        Float32  — same
Rotation (0..2π):                Float32  — same
Health (0..32767):               Int16    — 2 bytes, saves 50% vs Int32
Entity ID (0..2047):             Int16    — 2 bytes (MAX_E = 2048)
Flags (8 booleans):              Uint8    — 1 byte, bit-packed
Type tag (0..255):               Uint8    — 1 byte
AI state (0..7):                 Uint8    — 1 byte
Mesh pool ID (0..127):           Int8     — 1 byte
Instance slot (0..32767):        Int16    — 2 bytes
Animation frame (0..255):        Uint8    — 1 byte
Score (0..4294967295):           Uint32   — 4 bytes

AVOID:
- Float64 (double) — 8 bytes, never needed for game data
- Regular JS arrays for hot data — untyped, GC pressure
- Objects in tight loops — cache misses, GC
- String keys in hot paths — hash lookup overhead
```

---

## Single-HTML `<script>` Tag Order (Canonical)

```html
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1,user-scalable=no">
<title>RAMAI Engine</title>
<style>
/* ALL CSS HERE — no external stylesheet */
* { margin:0; padding:0; box-sizing:border-box; }
body { background:#000; overflow:hidden; }
canvas { display:block; }
#hud { position:fixed; top:8px; right:8px; /* ... */ }
#joystick { position:fixed; bottom:40px; left:40px; /* ... */ }
</style>
</head>
<body>

<!-- UI elements -->
<div id="hud"></div>
<div id="joystick"></div>

<!-- 1. STASH NATIVE IMAGE — must be first, before any patches -->
<script>window._NativeImage = window.Image;</script>

<!-- 2. ANDROID PATCHES — fetch() + Image.src XHR bypass -->
<script>
// ... (Pattern #1 from TEMPLATE_BEST_CODE.md)
</script>

<!-- 3. THREE.JS — after patches so it gets patched Image -->
<script src="assets/js/three.min.js"></script>
<script src="assets/js/GLTFLoader.js"></script>

<!-- 4. ALL GAME CODE — one big script block -->
<script>
'use strict';

// ── SECTION A: CONSTANTS ──────────────────────────────────────────
var MAX_E    = 2048;
var FIXED_DT = 1/60;
// ... all other constants

// ── SECTION B: ECS ARRAYS ────────────────────────────────────────
var PX = new Float32Array(MAX_E);
// ... all component arrays

// ── SECTION C: RENDERER + SCENE ──────────────────────────────────
var renderer, scene, camera, sun;
// ... renderer setup (Pattern #7)

// ── SECTION D: SYSTEMS ───────────────────────────────────────────
function physicsSystem(dt) { /* ... */ }
function renderSyncSystem()  { /* ... */ }
function aiSystem(dt)        { /* ... */ }
function inputSystem(dt)     { /* ... */ }

// ── SECTION E: ASSET LOADER + MESH POOLS ─────────────────────────
var meshPool = [];
// ... loadBinary, buildInstances, registerMeshPool

// ── SECTION F: GAME INIT ─────────────────────────────────────────
var _playerEid = -1;
function initGame() {
    // spawn player, enemies, buildings...
    _playerEid = spawnEntity(T_PLAYER, PLAYER_POOL, 0, 0, 0);
    FLAGS[_playerEid] |= F_PLAYER;
}

// ── SECTION G: GAME LOOP ─────────────────────────────────────────
function gameLoop(now) { /* fixed timestep loop */ }

// ── BOOT ─────────────────────────────────────────────────────────
// Load assets first, then init, then start loop
loadBinary('CONTENT/MESHES/kenney_blocky-characters_20/character-a.glb')
    .then(function(buf) { return parseGLB(buf, 'CONTENT/MESHES/kenney_blocky-characters_20/'); })
    .then(function(gltf) {
        buildInstances(gltf.scene, 'CONTENT/MESHES/kenney_blocky-characters_20/', 64);
        initGame();
        requestAnimationFrame(gameLoop);
    });
</script>

</body>
</html>
```

---

## Memory Budget (Target: 200MB Total)

```
BUDGET BREAKDOWN (mid-range Android, 3GB RAM):

ECS arrays (MAX_E=2048):
  Float32 arrays × 7  = 2048 × 4 × 7  =  57 KB
  Int16 arrays   × 5  = 2048 × 2 × 5  =  20 KB
  Uint8 arrays   × 5  = 2048 × 1 × 5  =  10 KB
  TOTAL ECS data                       =  87 KB  ← negligible

Three.js + GLTFLoader (minified):        ~600 KB
GPU: InstancedMesh matrices (2048×64B):  ~128 KB per pool
GPU: Textures (512×512 RGBA):            ~1 MB each
GPU: Shadow map (2048×2048):             ~16 MB

TARGETS:
  JS heap:     < 80 MB
  GPU memory:  < 100 MB
  Total:       < 200 MB
```

---

## Key Rules for the Hot Loop

1. **No `new` inside `gameLoop`** — pre-allocate everything at init
2. **No string operations** — use integer type/flag comparisons
3. **No `Array.forEach` on component data** — use `for (var i=0; ...)` with typed arrays
4. **No `Math.sqrt` in physics** — use squared distances for comparisons; only sqrt for AI steering (once per enemy per frame)
5. **Dirty flag pattern** — only sync transforms that actually changed (`F_DIRTY`)
6. **Batch GPU uploads** — set all matrices, then one `needsUpdate = true` per mesh
7. **HUD update throttle** — update DOM every 16 frames, not every frame
8. **Fixed timestep** — physics always runs at 60Hz; render catches up or skips
