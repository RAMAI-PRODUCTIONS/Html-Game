# Implementation Guide — Next Steps

**Date:** May 8, 2026  
**Goal:** Turn placeholders into working systems

---

## 🎯 Priority 1: Core Gameplay (Week 1-2)

### 1️⃣ Collision Detection System

**Status:** 📝 Placeholder  
**Complexity:** High  
**Time Estimate:** 3-4 days

#### What's Already Done
- ✅ Component arrays defined (COLL_MINX/Y/Z, COLL_MAXX/Y/Z, COLL_RADIUS)
- ✅ System function stub (`collisionSystem(dt)`)
- ✅ Raycast function stub (`raycast(...)`)
- ✅ Integrated into game loop

#### Implementation Steps

**Step 1: AABB Bounds Calculation (1 day)**
```javascript
// In spawnEntity(), calculate AABB from mesh bounds
function spawnEntity(type, poolId, x, y, z) {
  var id = createEntity();
  // ... existing code ...
  
  // Calculate AABB from mesh pool geometry
  var p = meshPool[poolId];
  if(p && p.mesh.geometry){
    var geo = p.mesh.geometry;
    geo.computeBoundingBox();
    var box = geo.boundingBox;
    var size = box.getSize(new THREE.Vector3());
    
    COLL_MINX[id] = -size.x/2;
    COLL_MINY[id] = 0;
    COLL_MINZ[id] = -size.z/2;
    COLL_MAXX[id] = size.x/2;
    COLL_MAXY[id] = size.y;
    COLL_MAXZ[id] = size.z/2;
    COLL_RADIUS[id] = Math.max(size.x, size.y, size.z) / 2;
  }
  
  return id;
}
```

**Step 2: Spatial Hash Grid (1 day)**
```javascript
// Broad-phase: divide world into grid cells
var GRID_SIZE = 10.0;
var spatialGrid = {}; // key: "x,z" → [entity IDs]

function updateSpatialGrid() {
  spatialGrid = {};
  var top = _eid;
  for(var i = 0; i < top; i++){
    if(!(FLAGS[i] & F_ALIVE)) continue;
    if(COLL_RADIUS[i] <= 0) continue;
    
    var gx = Math.floor(PX[i] / GRID_SIZE);
    var gz = Math.floor(PZ[i] / GRID_SIZE);
    var key = gx + ',' + gz;
    
    if(!spatialGrid[key]) spatialGrid[key] = [];
    spatialGrid[key].push(i);
  }
}
```

**Step 3: AABB vs AABB Tests (1 day)**
```javascript
function collisionSystem(dt) {
  updateSpatialGrid();
  
  // Check each grid cell
  for(var key in spatialGrid){
    var cell = spatialGrid[key];
    
    // Check all pairs in cell
    for(var i = 0; i < cell.length; i++){
      var a = cell[i];
      if(FLAGS[a] & F_STATIC) continue;
      
      for(var j = i+1; j < cell.length; j++){
        var b = cell[j];
        
        // AABB test
        var aMinX = PX[a] + COLL_MINX[a];
        var aMaxX = PX[a] + COLL_MAXX[a];
        var aMinY = PY[a] + COLL_MINY[a];
        var aMaxY = PY[a] + COLL_MAXY[a];
        var aMinZ = PZ[a] + COLL_MINZ[a];
        var aMaxZ = PZ[a] + COLL_MAXZ[a];
        
        var bMinX = PX[b] + COLL_MINX[b];
        var bMaxX = PX[b] + COLL_MAXX[b];
        var bMinY = PY[b] + COLL_MINY[b];
        var bMaxY = PY[b] + COLL_MAXY[b];
        var bMinZ = PZ[b] + COLL_MINZ[b];
        var bMaxZ = PZ[b] + COLL_MAXZ[b];
        
        if(aMaxX > bMinX && aMinX < bMaxX &&
           aMaxY > bMinY && aMinY < bMaxY &&
           aMaxZ > bMinZ && aMinZ < bMaxZ){
          // Collision! Resolve it
          resolveCollision(a, b);
        }
      }
    }
  }
}
```

**Step 4: Collision Response (0.5 day)**
```javascript
function resolveCollision(a, b) {
  // Simple separation response
  var dx = PX[b] - PX[a];
  var dz = PZ[b] - PZ[a];
  var dist = Math.sqrt(dx*dx + dz*dz);
  
  if(dist < 0.001) return;
  
  var overlap = (COLL_RADIUS[a] + COLL_RADIUS[b]) - dist;
  var nx = dx / dist;
  var nz = dz / dist;
  
  // Push apart (50/50 split)
  PX[a] -= nx * overlap * 0.5;
  PZ[a] -= nz * overlap * 0.5;
  PX[b] += nx * overlap * 0.5;
  PZ[b] += nz * overlap * 0.5;
  
  FLAGS[a] |= F_DIRTY;
  FLAGS[b] |= F_DIRTY;
  
  // Bounce velocity
  var relVX = VX[b] - VX[a];
  var relVZ = VZ[b] - VZ[a];
  var velAlongNormal = relVX*nx + relVZ*nz;
  
  if(velAlongNormal < 0){
    var restitution = 0.5;
    VX[a] -= nx * velAlongNormal * restitution;
    VZ[a] -= nz * velAlongNormal * restitution;
    VX[b] += nx * velAlongNormal * restitution;
    VZ[b] += nz * velAlongNormal * restitution;
  }
}
```

**Step 5: Raycasting (0.5 day)**
```javascript
function raycast(ox, oy, oz, dx, dy, dz, maxDist) {
  var closestDist = maxDist;
  var closestEid = -1;
  
  var top = _eid;
  for(var i = 0; i < top; i++){
    if(!(FLAGS[i] & F_ALIVE)) continue;
    if(COLL_RADIUS[i] <= 0) continue;
    
    // Ray vs sphere test (fast)
    var ex = PX[i] - ox;
    var ey = PY[i] - oy;
    var ez = PZ[i] - oz;
    
    var t = ex*dx + ey*dy + ez*dz;
    if(t < 0) continue;
    
    var px = ox + dx*t;
    var py = oy + dy*t;
    var pz = oz + dz*t;
    
    var dist2 = (px-PX[i])*(px-PX[i]) + 
                (py-PY[i])*(py-PY[i]) + 
                (pz-PZ[i])*(pz-PZ[i]);
    
    if(dist2 < COLL_RADIUS[i]*COLL_RADIUS[i] && t < closestDist){
      closestDist = t;
      closestEid = i;
    }
  }
  
  return closestEid;
}
```

---

### 2️⃣ Animation System

**Status:** 📝 Placeholder  
**Complexity:** High  
**Time Estimate:** 4-5 days

#### What's Already Done
- ✅ Component arrays defined (ANIM_CLIP, ANIM_TIME, ANIM_SPEED, etc.)
- ✅ System function stub (`animationSystem(dt)`)
- ✅ Play function stub (`playAnimation(...)`)
- ✅ Integrated into game loop

#### Implementation Steps

**Step 1: Load Animations from GLB (1 day)**
```javascript
// In buildInstances(), extract animations
function buildInstances(gltfScene, basePath, count, forEcs) {
  // ... existing code ...
  
  // Extract animations
  if(gltf.animations && gltf.animations.length){
    gltf.animations.forEach(function(clip){
      var clipData = {
        name: clip.name,
        duration: clip.duration,
        tracks: []
      };
      
      clip.tracks.forEach(function(track){
        clipData.tracks.push({
          nodeName: track.name.split('.')[0],
          property: track.name.split('.')[1], // position, rotation, scale
          times: track.times,
          values: track.values
        });
      });
      
      animClips.push(clipData);
    });
  }
}
```

**Step 2: Sample Keyframes (2 days)**
```javascript
function animationSystem(dt) {
  var top = _eid;
  for(var i = 0; i < top; i++){
    if(!(FLAGS[i] & F_ALIVE)) continue;
    if(ANIM_CLIP[i] < 0) continue;
    
    ANIM_TIME[i] += dt * ANIM_SPEED[i];
    
    var clip = animClips[ANIM_CLIP[i]];
    if(!clip) continue;
    
    // Loop handling
    if(ANIM_LOOP[i] && ANIM_TIME[i] > clip.duration){
      ANIM_TIME[i] = ANIM_TIME[i] % clip.duration;
    }
    
    // Sample each track
    clip.tracks.forEach(function(track){
      var value = sampleTrack(track, ANIM_TIME[i]);
      applyTrackValue(i, track.nodeName, track.property, value);
    });
  }
}

function sampleTrack(track, time) {
  // Find keyframe indices
  var times = track.times;
  var values = track.values;
  
  if(time <= times[0]) return values.slice(0, 3); // first keyframe
  if(time >= times[times.length-1]) return values.slice(-3); // last keyframe
  
  // Binary search for keyframe
  var i = 0;
  while(i < times.length && times[i] < time) i++;
  
  var t0 = times[i-1];
  var t1 = times[i];
  var alpha = (time - t0) / (t1 - t0);
  
  // Linear interpolation
  var v0 = values.slice((i-1)*3, i*3);
  var v1 = values.slice(i*3, (i+1)*3);
  
  return [
    v0[0] + (v1[0]-v0[0])*alpha,
    v0[1] + (v1[1]-v0[1])*alpha,
    v0[2] + (v1[2]-v0[2])*alpha
  ];
}
```

**Step 3: Apply to Skeleton (1 day)**
```javascript
function applyTrackValue(eid, nodeName, property, value) {
  // Get skeleton for entity
  var skeleton = skeletons[eid];
  if(!skeleton) return;
  
  // Find bone by name
  var bone = skeleton.getBoneByName(nodeName);
  if(!bone) return;
  
  // Apply value
  if(property === 'position'){
    bone.position.set(value[0], value[1], value[2]);
  } else if(property === 'rotation'){
    bone.quaternion.set(value[0], value[1], value[2], value[3]);
  } else if(property === 'scale'){
    bone.scale.set(value[0], value[1], value[2]);
  }
  
  bone.updateMatrix();
}
```

**Step 4: Blend Between Animations (1 day)**
```javascript
// Add second clip for blending
var ANIM_CLIP2 = new Int16Array(MAX_E);
var ANIM_TIME2 = new Float32Array(MAX_E);

function blendAnimations(eid, clipA, clipB, blend) {
  ANIM_CLIP[eid] = clipA;
  ANIM_CLIP2[eid] = clipB;
  ANIM_BLEND[eid] = blend; // 0=clipA, 1=clipB
}

// In animationSystem(), sample both clips and lerp
```

---

### 3️⃣ Audio System

**Status:** 📝 Placeholder  
**Complexity:** Medium  
**Time Estimate:** 2-3 days

#### Implementation Steps

**Step 1: Load Audio Files (1 day)**
```javascript
function loadSound(url) {
  if(audioBuffers[url]) return Promise.resolve(audioBuffers[url]);
  
  return new Promise(function(res, rej){
    var xhr = new XMLHttpRequest();
    xhr.open('GET', url, true);
    xhr.responseType = 'arraybuffer';
    xhr.onload = function(){
      if(xhr.status === 200 || xhr.status === 0){
        audioContext.decodeAudioData(xhr.response, function(buffer){
          audioBuffers[url] = buffer;
          res(buffer);
        }, rej);
      } else {
        rej(new Error('HTTP ' + xhr.status));
      }
    };
    xhr.onerror = rej;
    xhr.send();
  });
}
```

**Step 2: Play Sounds (0.5 day)**
```javascript
function playSound(url, loop, volume, spatial, entityId) {
  if(!audioContext) initAudio();
  
  loadSound(url).then(function(buffer){
    var source = audioContext.createBufferSource();
    source.buffer = buffer;
    source.loop = loop || false;
    
    var gain = audioContext.createGain();
    gain.gain.value = volume || 1.0;
    
    var panner = null;
    if(spatial && entityId >= 0){
      panner = audioContext.createPanner();
      panner.panningModel = 'HRTF';
      panner.distanceModel = 'inverse';
      panner.refDistance = 1;
      panner.maxDistance = 100;
      panner.setPosition(PX[entityId], PY[entityId], PZ[entityId]);
      
      source.connect(panner);
      panner.connect(gain);
    } else {
      source.connect(gain);
    }
    
    gain.connect(audioContext.destination);
    source.start(0);
    
    activeSounds.push({source:source, gain:gain, panner:panner, entity:entityId});
    
    source.onended = function(){
      var idx = activeSounds.indexOf(this);
      if(idx >= 0) activeSounds.splice(idx, 1);
    };
  });
}
```

**Step 3: Update Spatial Audio (0.5 day)**
```javascript
function audioSystem(dt) {
  if(!audioContext) return;
  
  // Update listener to camera
  if(camera){
    audioContext.listener.setPosition(
      camera.position.x,
      camera.position.y,
      camera.position.z
    );
    
    var forward = new THREE.Vector3(0,0,-1);
    forward.applyQuaternion(camera.quaternion);
    var up = new THREE.Vector3(0,1,0);
    up.applyQuaternion(camera.quaternion);
    
    audioContext.listener.setOrientation(
      forward.x, forward.y, forward.z,
      up.x, up.y, up.z
    );
  }
  
  // Update spatial sounds
  for(var i = activeSounds.length-1; i >= 0; i--){
    var snd = activeSounds[i];
    if(snd.entity >= 0 && (FLAGS[snd.entity] & F_ALIVE)){
      if(snd.panner){
        snd.panner.setPosition(
          PX[snd.entity],
          PY[snd.entity],
          PZ[snd.entity]
        );
      }
    }
  }
}
```

---

## ⚡ Priority 2: Visual Polish (Week 3-4)

### 4️⃣ Particle System (2 days)
### 5️⃣ Post-Processing (2 days)
### 6️⃣ LOD System (2 days)

---

## 💡 Priority 3: Tools (Week 5-6)

### 7️⃣ Canvas UI (3 days)
### 8️⃣ Scene Editor (4 days)
### 9️⃣ Save/Load Extensions (1 day)

---

## 🧪 Testing Checklist

After implementing each system:

- [ ] System runs without errors
- [ ] FPS stays above 30 on target device
- [ ] Memory usage is stable (no leaks)
- [ ] System can be disabled without breaking others
- [ ] HUD shows relevant debug info
- [ ] Code follows data-oriented patterns
- [ ] No allocations in hot path

---

## 📚 Resources

- **Three.js Docs:** https://threejs.org/docs/
- **Web Audio API:** https://developer.mozilla.org/en-US/docs/Web/API/Web_Audio_API
- **AABB Collision:** https://developer.mozilla.org/en-US/docs/Games/Techniques/3D_collision_detection
- **Skeletal Animation:** https://threejs.org/docs/#api/en/animation/AnimationMixer

---

## 🎯 Success Metrics

| System | Metric | Target |
|--------|--------|--------|
| Collision | Checks/frame | < 1000 |
| Animation | Bones/entity | 20-50 |
| Audio | Active sounds | < 32 |
| Particles | Active particles | < 1000 |
| LOD | Swaps/frame | < 10 |

---

## 🚀 Let's Build!

Start with **Collision Detection** — it's the foundation for gameplay! 🎮
