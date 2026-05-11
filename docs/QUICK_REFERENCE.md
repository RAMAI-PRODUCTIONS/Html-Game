# RAMAI Engine — Quick Reference Card

**Version:** 2.0 | **Last Updated:** May 11, 2026

---

## 🎯 ONE-PAGE CHEATSHEET

### File Structure
```
index.html          ← Main game (ALL CODE)
viewer.html         ← GLB viewer (debug)
CONTENT/MESHES/     ← 3D models (GLB)
README.md           ← Start here
SYSTEM_PROMPT.md    ← LLM guide
DEVELOPER_GUIDE.md  ← Human guide
```

### Console Commands
```javascript
// Entity count
Object.keys(animMixers).length

// Entity position
positions.slice(eid*3, eid*3+3)

// Force AI state
aiState[eid] = 0  // IDLE

// Teleport
positions[eid*3] = x; positions[eid*3+1] = y; positions[eid*3+2] = z;

// Query tags
window.getInstancesByTag('team_red')
```

### ECS Data Layout
```javascript
// Transform (Float32Array)
positions[eid*3]     // X
positions[eid*3+1]   // Y
positions[eid*3+2]   // Z

velocities[eid*3]    // VX
velocities[eid*3+1]  // VY
velocities[eid*3+2]  // VZ

// Gameplay (Uint16Array)
health[eid]          // HP
maxHealth[eid]       // Max HP
damage[eid]          // Damage dealt

// AI (Uint8Array)
aiState[eid]         // 0=IDLE, 1=PATROL, 2=CHASE, 3=ATTACK
team[eid]            // 0=neutral, 1=player, 2=enemy

// Flags (Uint32Array, bit-packed)
flags[eid] & FLAG_ALIVE
flags[eid] & FLAG_VISIBLE
flags[eid] & FLAG_ON_GROUND
```

### Common Tasks

#### Spawn Entity
```javascript
const eid = spawnEntity("character-b", x, y, z, vx, vy, vz);
```

#### Play Animation
```javascript
playAnimation(eid, clipIndex, loop, speed);
// clipIndex: 0=idle, 1=walk, 2=run, 3=attack
```

#### Raycast
```javascript
const hit = rayCast(fromX, fromY, fromZ, toX, toY, toZ);
// Returns { hit: bool, distance: float, entityId: uint }
```

#### Apply Damage
```javascript
health[eid] -= damage;
if (health[eid] <= 0) {
  flags[eid] &= ~FLAG_ALIVE;  // Kill entity
}
```

### AI States
```javascript
const AI_IDLE = 0;    // Standing still
const AI_PATROL = 1;  // Walking waypoints
const AI_CHASE = 2;   // Pursuing player
const AI_ATTACK = 3;  // In melee range
```

### Performance Rules
```
✅ DO:
- Use InstancedMesh for repeated geometry
- Set renderer.setPixelRatio(1) for mobile
- Use Float32Array/Uint8Array for ECS
- Batch draw calls (< 50 total)
- Update mixer.update(dt) every frame

❌ DON'T:
- Create individual Mesh for repeated objects
- Use window.devicePixelRatio on mobile
- Enable shadows without explicit config
- Allocate objects in hot loops
- Forget to call mixer.update(dt)
```

### Code Sections (index.html)
```
Section A — Startup Config (startupConfig object)
Section B — ECS Data Structures (typed arrays)
Section C — Systems (physics, AI, input, animation)
Section D — Rendering (Three.js bridge)
Section E — Asset Loading (GLB loader, spawnEntity)
Section F — Game Loop (requestAnimationFrame)
```

### Debugging
```javascript
// Pause physics
physicsSystem = () => {};

// Slow motion
FIXED_DT = 1/30;  // Half speed

// Show all entities
for (let i = 0; i < MAX_ENTITIES; i++) {
  if (flags[i] & FLAG_ALIVE) {
    console.log(`Entity ${i}: (${positions[i*3]}, ${positions[i*3+1]}, ${positions[i*3+2]})`);
  }
}
```

### Animation System
```javascript
// Create mixer (on spawn)
const mixer = new THREE.AnimationMixer(gltf.scene);
animMixers[eid] = mixer;
animClips[eid] = gltf.animations;

// Play clip
const action = mixer.clipAction(animClips[eid][clipIndex]);
action.setLoop(THREE.LoopRepeat);
action.play();

// Update (every frame)
mixer.update(dt);

// Crossfade
prevAction.crossFadeTo(newAction, 0.2, true);
```

### Collision Detection
```javascript
// Spatial hash grid (10×10×10 cells)
const cellX = Math.floor(positions[eid*3] / 10);
const cellY = Math.floor(positions[eid*3+1] / 10);
const cellZ = Math.floor(positions[eid*3+2] / 10);
const cellKey = `${cellX},${cellY},${cellZ}`;

// Check collision (sphere-sphere)
const dx = positions[eid1*3] - positions[eid2*3];
const dy = positions[eid1*3+1] - positions[eid2*3+1];
const dz = positions[eid1*3+2] - positions[eid2*3+2];
const dist = Math.sqrt(dx*dx + dy*dy + dz*dz);
const minDist = collisionRadius[eid1] + collisionRadius[eid2];

if (dist < minDist) {
  // Collision detected
}
```

### Startup Config Template
```javascript
const startupConfig = {
  models: [
    {
      name: "model_name",
      glbPath: "CONTENT/MESHES/model.glb",
      instances: [
        {
          position: { x: 0, y: 0, z: 0 },
          rotation: { x: 0, y: 0, z: 0 },
          scale: { x: 1, y: 1, z: 1 },
          tags: ["tag1", "tag2"]
        }
      ],
      castShadow: false,
      receiveShadow: true
    }
  ],
  camera: {
    position: { x: 0, y: 10, z: 20 },
    lookAt: { x: 0, y: 0, z: 0 },
    fov: 75,
    near: 0.1,
    far: 1000
  },
  lights: [
    { type: "directional", color: "#ffe8d0", intensity: 1.8, position: {x:10,y:20,z:10}, castShadow: true },
    { type: "hemisphere", skyColor: "#87CEEB", groundColor: "#4a4a4a", intensity: 0.7 },
    { type: "ambient", color: "#ffffff", intensity: 0.4 }
  ],
  fog: {
    enabled: true,
    color: "#a0a0a0",
    near: 30,
    far: 80
  }
};
```

### Game Loop Pattern
```javascript
let accumulator = 0;
const FIXED_DT = 1/60;

function gameLoop(currentTime) {
  requestAnimationFrame(gameLoop);
  
  const deltaTime = (currentTime - lastTime) / 1000;
  lastTime = currentTime;
  accumulator += deltaTime;
  
  while (accumulator >= FIXED_DT) {
    inputSystem(FIXED_DT);
    physicsSystem(FIXED_DT);
    collisionSystem(FIXED_DT);
    aiSystem(FIXED_DT);
    animationSystem(FIXED_DT);
    accumulator -= FIXED_DT;
  }
  
  renderSystem();
}
```

### Controls
```
WASD        — Move player
Mouse drag  — Orbit camera
Scroll      — Zoom
Spacebar    — Jump
P           — Spawn particles
```

### Performance Targets
```
FPS:         60+
Frame time:  < 16ms
Draw calls:  < 50
Memory:      < 100 MB
Entities:    500+
```

### Common Errors
```
✗ animMixers[eid] is undefined
  → Check GLB has animations, verify mixer created

✗ Cannot read property 'clipAction' of undefined
  → Mixer not initialized, check new THREE.AnimationMixer()

✗ clip is undefined
  → Invalid clip index, check animClips[eid].length

✗ Models not loading
  → Check console, verify GLB path in startupConfig

✗ Low FPS
  → Reduce entities, disable shadows, check instancing
```

### Documentation Map
```
README.md              → Project overview (start here)
SYSTEM_PROMPT.md       → LLM development guide (mandatory for AI)
LLM_CHEATSHEET.md      → Quick reference for AI assistants
DEVELOPER_GUIDE.md     → Human developer guide (tutorials)
QUICK_REFERENCE.md     → This file (one-page cheatsheet)
TASKLIST_NEXT_CHAT.md  → Phase roadmap (what's next)
TESTING_CHECKLIST.md   → Pre-release verification
```

### Phase Status
```
Phase 0: ECS + Physics + AI + Input + Rendering  ✅ Done
Phase 1: Collision Detection                     ✅ Done
Phase 2: Animation System                        🔄 In Progress
Phase 3: Audio System                            ⬜ Not started
Phase 4: Post-Processing + LOD                   ⬜ Not started
Phase 5: UI (minimap, damage numbers)            ⬜ Not started
Phase 6: Scene Editor                            ⬜ Not started
Phase 7: Polish + Store Release                  ⬜ Not started
```

### Next Steps
```
1. Read SYSTEM_PROMPT.md (if AI) or DEVELOPER_GUIDE.md (if human)
2. Open index.html in browser
3. Check console for initialization logs
4. Review TASKLIST_NEXT_CHAT.md for current phase
5. Start coding!
```

---

**Print this page and keep it next to your keyboard! 📄**
