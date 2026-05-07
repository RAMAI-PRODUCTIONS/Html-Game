# AAA Mobile Engine — Best Code Template
## All Proven Patterns from This Codebase

> Every pattern here is either **PROVEN** (extracted verbatim from `viewer.html` / `MainActivity.java` / `build.gradle` and confirmed working on Android WebView) or **RECOMMENDED** (new patterns that follow the same architecture philosophy). Use this file as the canonical reference when building new game scenes.

---

## 1. Android WebView — fetch() + Image.src Patch (PROVEN)

**WHY:** Android WebView blocks `fetch()` on `file://` URLs by default. Three.js GLTFLoader uses `fetch()` for binary loading and `Image.src` for textures. Without this patch, nothing loads. This is the single most critical piece of the entire engine — it must run BEFORE Three.js is included.

```html
<!-- Stash native Image BEFORE any patches — Three.js must get the patched version -->
<script>window._NativeImage = window.Image;</script>

<script>
(function(){
    // ── PATCH 1: fetch() — intercepts GLB/bin binary loading ──────────────
    // Android WebView throws on fetch('file://...') so we route through XHR
    var _fetch = window.fetch;
    window.fetch = function(input, init){
        var url = (input && input.url) ? input.url : String(input);
        var isFile = url.indexOf('file://') === 0 || url.indexOf('file:///android_asset') === 0;
        var isRel  = url.indexOf('http') !== 0 && url.indexOf('data:') !== 0 && url.indexOf('blob:') !== 0;
        if (isFile || isRel){
            return new Promise(function(res,rej){
                var xhr = new XMLHttpRequest();
                xhr.open('GET', url, true);
                xhr.responseType = 'arraybuffer';
                xhr.onload = function(){
                    if(xhr.status===200||xhr.status===0){
                        var ext = url.split('.').pop().toLowerCase();
                        var ct  = {
                            glb:  'model/gltf-binary',
                            gltf: 'model/gltf+json',
                            bin:  'application/octet-stream',
                            png:  'image/png',
                            jpg:  'image/jpeg',
                            jpeg: 'image/jpeg'
                        }[ext] || 'application/octet-stream';
                        res(new Response(xhr.response, {
                            status: 200,
                            headers: {
                                'Content-Type':   ct,
                                'Content-Length': xhr.response.byteLength
                            }
                        }));
                    } else {
                        rej(new TypeError('fetch failed: ' + url));
                    }
                };
                xhr.onerror = function(){ rej(new TypeError('fetch error: ' + url)); };
                xhr.send();
            });
        }
        return _fetch ? _fetch.call(window, input, init) : Promise.reject(new Error('no fetch'));
    };

    // ── PATCH 2: Image.src — intercepts texture loading via Three.js ImageLoader ──
    // Three.js sets img.src = 'file://...' for textures; WebView blocks it.
    // We XHR the file as a blob, create an object URL, and set that instead.
    // Only intercept file:// and relative paths — blob:/data: pass through untouched.
    var NativeImg = window._NativeImage;
    var srcDesc = Object.getOwnPropertyDescriptor(NativeImg.prototype, 'src');
    if (srcDesc && srcDesc.set) {
        var _setSrc = srcDesc.set;
        var _getSrc = srcDesc.get;
        Object.defineProperty(NativeImg.prototype, 'src', {
            configurable: true,
            get: function() { return _getSrc.call(this); },
            set: function(url) {
                if (!url) { _setSrc.call(this, url); return; }
                var isFile = url.indexOf('file://') === 0;
                var isRel  = url.indexOf('http')  !== 0
                          && url.indexOf('data:') !== 0
                          && url.indexOf('blob:') !== 0
                          && url.length > 1;
                if (isFile || isRel) {
                    var self = this;
                    var xhr = new XMLHttpRequest();
                    xhr.open('GET', url, true);
                    xhr.responseType = 'blob';
                    xhr.onload = function() {
                        if (xhr.status === 200 || xhr.status === 0) {
                            _setSrc.call(self, URL.createObjectURL(xhr.response));
                        } else {
                            _setSrc.call(self, url); // fallback
                        }
                    };
                    xhr.onerror = function() { _setSrc.call(self, url); };
                    xhr.send();
                } else {
                    _setSrc.call(this, url); // blob:/data: — pass through
                }
            }
        });
    }
})();
</script>

<!-- Three.js and GLTFLoader AFTER the patches -->
<script src="assets/js/three.min.js"></script>
<script src="assets/js/GLTFLoader.js"></script>
```

---

## 2. XHR Binary Loader (PROVEN)

**WHY:** Even with the fetch patch, having a direct XHR loader is useful for explicit binary loading with progress callbacks. Returns a Promise with an ArrayBuffer. Used by `loadAndSpawn()` to stream GLB files with a progress indicator.

```javascript
// ── XHR Binary Loader — avoids fetch() which is blocked on file:// ──────
// Returns Promise<ArrayBuffer>. onProg(0..1) called during download.
function loadBinary(url, onProg) {
    return new Promise(function(res, rej) {
        var xhr = new XMLHttpRequest();
        xhr.open('GET', url, true);
        xhr.responseType = 'arraybuffer';
        xhr.onprogress = function(e) {
            if (onProg && e.lengthComputable) onProg(e.loaded / e.total);
        };
        xhr.onload = function() {
            (xhr.status === 200 || xhr.status === 0)
                ? res(xhr.response)
                : rej(new Error('HTTP ' + xhr.status));
        };
        xhr.onerror = function() { rej(new Error('XHR error: ' + url)); };
        xhr.send();
    });
}

// Usage:
loadBinary('CONTENT/MESHES/kenney_car-kit/sedan.glb', function(p) {
    setStatus('Downloading... ' + Math.round(p * 100) + '%');
}).then(function(buffer) {
    // buffer is ArrayBuffer — pass to GLTFLoader.parse()
    var loader = new THREE.GLTFLoader();
    loader.parse(buffer, basePath, function(gltf) { /* ... */ }, function(err) { /* ... */ });
}).catch(function(err) {
    setStatus('Load error: ' + err.message);
});
```

---

## 3. Texture Cache (PROVEN)

**WHY:** Loading the same texture multiple times wastes memory and causes stutter. This cache uses XHR to fetch the texture as a blob, creates an object URL, loads it into a NativeImage (bypassing the patched Image.src), and stores the resulting THREE.Texture keyed by absolute URL. Like an NES CHR-ROM bank — load once, reuse everywhere.

```javascript
// ── Texture Cache — XHR → blob URL → NativeImage → THREE.Texture ─────────
// Key: absolute URL string. Value: THREE.Texture (already uploaded to GPU).
// Uses window._NativeImage to bypass the Image.src patch (we handle XHR ourselves).
var texCache = {};

function loadTextureCached(url) {
    if (texCache[url]) return Promise.resolve(texCache[url]);

    return new Promise(function(res, rej) {
        var xhr = new XMLHttpRequest();
        xhr.open('GET', url, true);
        xhr.responseType = 'blob';
        xhr.onload = function() {
            if (xhr.status === 200 || xhr.status === 0) {
                var blobUrl = URL.createObjectURL(xhr.response);
                var img = new window._NativeImage(); // use NATIVE Image, not patched
                img.onload = function() {
                    var tex = new THREE.Texture(img);
                    tex.needsUpdate = true;
                    // Clamp to power-of-two for WebGL1 compatibility
                    tex.wrapS      = tex.wrapT = THREE.ClampToEdgeWrapping;
                    tex.minFilter  = THREE.LinearMipMapLinearFilter;
                    tex.magFilter  = THREE.LinearFilter;
                    tex.generateMipmaps = true;
                    texCache[url] = tex;
                    res(tex);
                };
                img.onerror = function() { rej(new Error('img load failed: ' + url)); };
                img.src = blobUrl;
            } else {
                rej(new Error('XHR ' + xhr.status + ': ' + url));
            }
        };
        xhr.onerror = function() { rej(new Error('XHR error: ' + url)); };
        xhr.send();
    });
}
```

---

## 4. InstancedMesh Spawner (PROVEN)

**WHY:** Drawing 2000 individual meshes = 2000 draw calls = unplayable on mobile. InstancedMesh collapses all instances of the same geometry+material into ONE draw call. This is the core performance technique. The pattern: normalize model → group by material → merge geometries → build InstancedMesh → async texture upgrade.

```javascript
// ── InstancedMesh Spawner ─────────────────────────────────────────────────
// Spawns `count` instances of a loaded GLTF scene using InstancedMesh.
// One InstancedMesh per unique material = one draw call per material group.
function buildInstances(gltfScene, basePath, count) {
    var SPREAD = 90; // half-width of spawn field in world units

    // ── Step 1: Normalisation matrix ──────────────────────────────────
    // Fit the whole model into a 2-unit cube sitting on Y=0.
    // This makes every model the same scale regardless of source units.
    var box    = new THREE.Box3().setFromObject(gltfScene);
    var size   = box.getSize(new THREE.Vector3());
    var center = box.getCenter(new THREE.Vector3());
    var modelScale = 2.0 / Math.max(size.x, size.y, size.z, 0.001);

    var normMat = new THREE.Matrix4()
        .makeTranslation(-center.x, -box.min.y, -center.z)
        .premultiply(new THREE.Matrix4().makeScale(modelScale, modelScale, modelScale));

    // ── Step 2: Group meshes by material/texture key ───────────────────
    // Meshes sharing the same texture become ONE InstancedMesh.
    var groups = {}; // texKey → { geos[], srcMat, texUrl, basePath }

    gltfScene.updateMatrixWorld(true);
    gltfScene.traverse(function(child) {
        if (!child.isMesh || !child.geometry) return;

        var srcMat = Array.isArray(child.material) ? child.material[0] : child.material;
        var texUrl = null;
        var texKey = 'solid_' + (srcMat && srcMat.color ? srcMat.color.getHexString() : 'cccccc');

        if (srcMat && srcMat.map && srcMat.map.image && srcMat.map.image.src) {
            texUrl = srcMat.map.image.src;
            texKey = 'tex_' + texUrl;
        } else if (srcMat && srcMat.map) {
            texKey = 'tex_' + basePath;
        }

        // Clone geometry and bake world transform + normalisation into vertex data
        var geo = child.geometry.clone();
        var worldMat = child.matrixWorld.clone();
        worldMat.premultiply(normMat);
        geo.applyMatrix4(worldMat);

        if (!groups[texKey]) {
            groups[texKey] = { geos: [], srcMat: srcMat, texUrl: texUrl, basePath: basePath };
        }
        groups[texKey].geos.push(geo);
    });

    if (Object.keys(groups).length === 0) { setStatus('No meshes found!'); return; }

    // ── Step 3: Pre-compute instance matrices ONCE (shared OAM table) ─
    // Grid layout with random jitter + rotation + scale variation.
    // Computed once and reused for every InstancedMesh group.
    var cols    = Math.ceil(Math.sqrt(count));
    var spacing = (SPREAD * 2) / cols;
    var matrices = new Array(count);
    var tmpDummy = new THREE.Object3D();

    for (var i = 0; i < count; i++) {
        var col = i % cols;
        var row = Math.floor(i / cols);
        tmpDummy.position.set(
            -SPREAD + col * spacing + (Math.random() - 0.5) * spacing * 0.55,
            0,
            -SPREAD + row * spacing + (Math.random() - 0.5) * spacing * 0.55
        );
        tmpDummy.rotation.set(0, Math.random() * Math.PI * 2, 0);
        var s = 0.75 + Math.random() * 0.5;
        tmpDummy.scale.set(s, s, s);
        tmpDummy.updateMatrix();
        matrices[i] = tmpDummy.matrix.clone();
    }

    // ── Step 4: Build InstancedMesh per group, async texture upgrade ──
    Object.keys(groups).forEach(function(key) {
        var grp = groups[key];

        // Merge all sub-geometries into one (one draw call per material)
        var mergedGeo = grp.geos.length === 1 ? grp.geos[0] : mergeGeometries(grp.geos);

        // Start with solid colour — renders immediately, no texture stall
        var srcMat = grp.srcMat;
        var instMat = new THREE.MeshStandardMaterial({
            color:     srcMat && srcMat.color ? srcMat.color.clone() : new THREE.Color(0xcccccc),
            roughness: srcMat && srcMat.roughness != null ? srcMat.roughness : 0.8,
            metalness: srcMat && srcMat.metalness != null ? srcMat.metalness : 0.05,
            side:      THREE.FrontSide,
        });

        var iMesh = new THREE.InstancedMesh(mergedGeo, instMat, count);
        iMesh.castShadow    = true;
        iMesh.receiveShadow = true;
        iMesh.instanceMatrix.setUsage(THREE.StaticDrawUsage); // hint GPU: matrices won't change

        for (var i = 0; i < count; i++) iMesh.setMatrixAt(i, matrices[i]);
        iMesh.instanceMatrix.needsUpdate = true;
        scene.add(iMesh);
        instancedMeshes.push(iMesh);

        // Async texture upgrade — swap solid colour for real texture when ready
        if (grp.texUrl) {
            // Texture already loaded by GLTFLoader
            if (srcMat && srcMat.map) { instMat.map = srcMat.map; instMat.needsUpdate = true; }
        } else if (srcMat && srcMat.map && srcMat.map.image) {
            // GLTFLoader embedded the image
            instMat.map = srcMat.map; instMat.needsUpdate = true;
        } else if (srcMat && srcMat.map && srcMat.map.name) {
            // Try to resolve texture by convention: basePath + Textures/ + name.png
            var guessUrl = grp.basePath + 'Textures/' + srcMat.map.name + '.png';
            loadTextureCached(guessUrl).then(function(tex) {
                instMat.map = tex; instMat.needsUpdate = true;
            }).catch(function(e) { console.warn('Texture load failed:', e.message); });
        }
    });

    totalInstances = count;
    document.getElementById('hInst').textContent = count.toLocaleString();
}

---

## 5. Geometry Merger (PROVEN)

**WHY:** Three.js `BufferGeometryUtils.mergeBufferGeometries()` is a separate addon with version-matching issues. This inline merger does the same job with zero dependencies — flat typed arrays, one concat pass. Like packing sprites into a NES sprite sheet.

```javascript
// ── Geometry Merger — no BufferGeometryUtils dependency ──────────────────
// Merges an array of BufferGeometry into one. Handles position/normal/uv + index.
// Uses flat Float32Array typed arrays for zero-copy performance.
function mergeGeometries(geos) {
    var totalVerts = 0, totalIdx = 0, hasIndex = false;
    geos.forEach(function(g) {
        totalVerts += g.attributes.position.count;
        if (g.index) { totalIdx += g.index.count; hasIndex = true; }
    });

    var positions = new Float32Array(totalVerts * 3);
    var normals   = new Float32Array(totalVerts * 3);
    var uvs       = new Float32Array(totalVerts * 2);
    var indices   = hasIndex ? new Uint32Array(totalIdx) : null;

    var vOff = 0, iOff = 0, vBase = 0;
    geos.forEach(function(g) {
        var pos = g.attributes.position.array;
        var nor = g.attributes.normal ? g.attributes.normal.array : null;
        var uv  = g.attributes.uv     ? g.attributes.uv.array     : null;
        var vc  = g.attributes.position.count;

        positions.set(pos, vOff * 3);
        if (nor) normals.set(nor, vOff * 3);
        if (uv)  uvs.set(uv,  vOff * 2);

        if (hasIndex && g.index) {
            var idx = g.index.array;
            for (var j = 0; j < idx.length; j++) indices[iOff + j] = idx[j] + vBase;
            iOff += idx.length;
        }
        vBase += vc;
        vOff  += vc;
    });

    var merged = new THREE.BufferGeometry();
    merged.setAttribute('position', new THREE.BufferAttribute(positions, 3));
    merged.setAttribute('normal',   new THREE.BufferAttribute(normals,   3));
    merged.setAttribute('uv',       new THREE.BufferAttribute(uvs,       2));
    if (indices) merged.setIndex(new THREE.BufferAttribute(indices, 1));
    return merged;
}
```

---

## 7. Renderer Setup (PROVEN)

**WHY:** These exact settings are the result of trial-and-error on Android WebView. `powerPreference: 'high-performance'` requests the discrete GPU on devices that have one. `stencil: false` saves memory. `PCFSoftShadowMap` gives smooth shadow edges without the cost of VSM. `SRGBColorSpace` + ACES tone mapping makes colors look correct and cinematic.

```javascript
// ── WebGLRenderer — mobile-optimised config ───────────────────────────────
renderer = new THREE.WebGLRenderer({
    antialias:       false,          // off by default; quality system may enable
    powerPreference: 'high-performance', // request discrete GPU if available
    stencil:         false,          // saves ~4MB on mobile
    depth:           true
});
renderer.setSize(window.innerWidth, window.innerHeight);
renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2)); // cap at 2x — 3x kills perf

// Shadow map — PCFSoft gives smooth edges, cheaper than VSM
renderer.shadowMap.enabled = true;
renderer.shadowMap.type    = THREE.PCFSoftShadowMap;

// Color space — SRGBColorSpace is correct for r152+; LinearEncoding for older builds
renderer.outputColorSpace = THREE.SRGBColorSpace || THREE.LinearEncoding;

// Tone mapping — ACES gives filmic look, prevents blown-out highlights
renderer.toneMapping         = THREE.ACESFilmicToneMapping;
renderer.toneMappingExposure = 1.0;

document.body.appendChild(renderer.domElement);

// Resize handler — always update both camera AND renderer
window.addEventListener('resize', function() {
    camera.aspect = window.innerWidth / window.innerHeight;
    camera.updateProjectionMatrix();
    renderer.setSize(window.innerWidth, window.innerHeight);
});
```

---

## 8. Lighting Setup (PROVEN)

**WHY:** Three-point lighting adapted for outdoor scenes. HemisphereLight provides free sky/ground bounce with zero draw calls. The directional sun casts shadows with a carefully sized frustum — too large and shadow resolution is wasted, too small and objects outside cast no shadow. Fill light prevents the shadow side from going pure black.

```javascript
// ── Lighting — outdoor three-point setup ─────────────────────────────────

// Sky/ground hemisphere — free ambient bounce, no shadow cost
var hemi = new THREE.HemisphereLight(
    0xb0d8ff,  // sky color (light blue)
    0x4a7c3f,  // ground color (dark green)
    0.6        // intensity
);
scene.add(hemi);

// Main directional sun — casts + receives shadows
sun = new THREE.DirectionalLight(0xfff5e0, 1.2); // warm white, intensity 1.2
sun.position.set(40, 80, 30);
sun.castShadow = true;

// Shadow camera frustum — must cover the entire playfield
// Too large = wasted shadow map resolution; too small = missing shadows
var sc = sun.shadow.camera;
sc.left = sc.bottom = -120;
sc.right = sc.top   =  120;
sc.near  = 1;
sc.far   = 300;

// Shadow map resolution — 2048 for HIGH quality, adaptive system may lower it
sun.shadow.mapSize.set(2048, 2048);
sun.shadow.bias       = -0.0005; // prevents shadow acne
sun.shadow.normalBias =  0.02;   // prevents self-shadowing on curved surfaces
scene.add(sun);
scene.add(sun.target); // target stays at origin by default

// Fill light — prevents shadow side from going pure black
var fill = new THREE.DirectionalLight(0xaaccff, 0.3); // cool blue fill
fill.position.set(-30, 20, -20);
// fill.castShadow = false; // never cast shadows from fill light
scene.add(fill);
```

---

## 9. Touch + Mouse Orbit Controls (PROVEN)

**WHY:** OrbitControls.js is a large addon with version-matching issues. This 60-line spherical coordinate orbit handles single-finger drag, two-finger pinch zoom, mouse drag, and mouse wheel — everything needed for a mobile 3D viewer. No dependencies, no version conflicts.

```javascript
// ── Spherical Coordinate Orbit Controls ──────────────────────────────────
// sph.theta = horizontal angle, sph.phi = vertical angle, sph.r = distance
// Single touch = orbit, two-finger pinch = zoom, mouse drag = orbit, wheel = zoom
function setupControls() {
    var sph    = { theta: 0.5, phi: 0.9, r: 45 };
    var target = new THREE.Vector3(0, 0, 0);
    var drag = false, px = 0, py = 0, pinchD = 0;

    function applyCamera() {
        camera.position.set(
            target.x + sph.r * Math.sin(sph.phi) * Math.sin(sph.theta),
            target.y + sph.r * Math.cos(sph.phi),
            target.z + sph.r * Math.sin(sph.phi) * Math.cos(sph.theta)
        );
        camera.lookAt(target);
    }
    applyCamera(); // set initial position

    var el = renderer.domElement;

    // ── Touch events ──────────────────────────────────────────────────
    el.addEventListener('touchstart', function(e) {
        if (e.touches.length === 1) {
            drag = true; px = e.touches[0].clientX; py = e.touches[0].clientY;
        }
        if (e.touches.length === 2) {
            drag = false;
            pinchD = Math.hypot(
                e.touches[0].clientX - e.touches[1].clientX,
                e.touches[0].clientY - e.touches[1].clientY
            );
        }
    }, { passive: true });

    el.addEventListener('touchmove', function(e) {
        if (drag && e.touches.length === 1) {
            sph.theta -= (e.touches[0].clientX - px) * 0.004;
            sph.phi    = Math.max(0.05, Math.min(Math.PI - 0.05,
                             sph.phi + (e.touches[0].clientY - py) * 0.004));
            px = e.touches[0].clientX; py = e.touches[0].clientY;
            applyCamera();
        }
        if (e.touches.length === 2) {
            var d = Math.hypot(
                e.touches[0].clientX - e.touches[1].clientX,
                e.touches[0].clientY - e.touches[1].clientY
            );
            sph.r  = Math.max(5, Math.min(200, sph.r * (pinchD / d)));
            pinchD = d;
            applyCamera();
        }
    }, { passive: true });

    el.addEventListener('touchend', function() { drag = false; }, { passive: true });

    // ── Mouse events ──────────────────────────────────────────────────
    el.addEventListener('mousedown', function(e) { drag = true; px = e.clientX; py = e.clientY; });
    el.addEventListener('mousemove', function(e) {
        if (!drag) return;
        sph.theta -= (e.clientX - px) * 0.004;
        sph.phi    = Math.max(0.05, Math.min(Math.PI - 0.05,
                         sph.phi + (e.clientY - py) * 0.004));
        px = e.clientX; py = e.clientY;
        applyCamera();
    });
    el.addEventListener('mouseup',  function() { drag = false; });
    el.addEventListener('wheel',    function(e) {
        sph.r = Math.max(5, Math.min(200, sph.r + e.deltaY * 0.05));
        applyCamera();
    });
}
```

---

## 10. Adaptive Quality System (PROVEN PATTERN)

**WHY:** Mobile GPUs vary wildly — a flagship runs at 60fps on HIGH, a budget phone needs LOW to stay playable. The 3-tier config array lets you tune all quality knobs in one place. The adaptive monitor checks FPS every 2 seconds and steps quality down/up automatically. Pixel ratio has the biggest impact: 0.75 vs 2.0 is a 7x difference in pixel fill rate.

```javascript
// ── 3-Tier Quality Config ─────────────────────────────────────────────────
// Each tier controls: pixel ratio, shadow map size, fog density, antialias.
// Tune these numbers for your target device range.
var QUALITY_CONFIGS = [
    // LOW  — budget phones, 30fps target
    { pr: 0.75, shadowMap: 512,  fog: 0.018, antialias: false },
    // MED  — mid-range phones, 45fps target
    { pr: 1.0,  shadowMap: 1024, fog: 0.010, antialias: false },
    // HIGH — flagship phones, 60fps target
    { pr: Math.min(window.devicePixelRatio, 2), shadowMap: 2048, fog: 0.006, antialias: true }
];

var qualityLevel  = 2;    // start HIGH, step down if needed
var lastQualCheck = 0;
var QUAL_INTERVAL = 2000; // check every 2 seconds

function applyQuality() {
    var cfg = QUALITY_CONFIGS[qualityLevel];
    renderer.setPixelRatio(cfg.pr);
    if (sun && sun.shadow) {
        sun.shadow.mapSize.set(cfg.shadowMap, cfg.shadowMap);
        sun.shadow.map = null;                  // force shadow map rebuild
        renderer.shadowMap.needsUpdate = true;
    }
    if (scene.fog) scene.fog.density = cfg.fog;
    console.log('Quality → ' + ['LOW','MED','HIGH'][qualityLevel]
        + ' (PR:' + cfg.pr + ' ShadowMap:' + cfg.shadowMap + ')');
}

// ── Adaptive quality monitor — call from render loop ─────────────────────
function adaptiveQuality(now) {
    if (now - lastQualCheck < QUAL_INTERVAL) return;
    lastQualCheck = now;

    var qEl = document.getElementById('hQual');

    if (currentFps < 25 && qualityLevel > 0) {
        qualityLevel--;
        applyQuality();
        qEl.textContent = ['LOW','MED','HIGH'][qualityLevel];
        qEl.className   = 'val warn';
    } else if (currentFps > 55 && qualityLevel < 2) {
        qualityLevel++;
        applyQuality();
        qEl.textContent = ['LOW','MED','HIGH'][qualityLevel];
        qEl.className   = 'val good';
    } else {
        qEl.textContent = ['LOW','MED','HIGH'][qualityLevel];
        qEl.className   = currentFps >= 30 ? 'val good' : 'val warn';
    }
}
```

---

## 11. Performance HUD (PROVEN)

**WHY:** You cannot optimize what you cannot measure. This HUD shows FPS, frame time, draw calls, triangle count, instance count, and JS heap memory — all the numbers you need to diagnose performance problems. Color-coded spans (green/yellow/red) let you spot problems at a glance without reading numbers.

```html
<!-- HUD HTML — fixed position overlay -->
<div id="hud">
    <div>FPS  <span class="val" id="hFps">--</span></div>
    <div>MS   <span class="val" id="hMs">--</span></div>
    <div>DRAW <span class="val" id="hDraw">--</span></div>
    <div>TRIS <span class="val" id="hTris">--</span></div>
    <div>INST <span class="val" id="hInst">0</span></div>
    <div>MEM  <span class="val" id="hMem">--</span></div>
    <div>QUAL <span class="val" id="hQual">--</span></div>
</div>
```

```css
/* HUD CSS */
#hud {
    position: fixed; top: 52px; right: 8px; z-index: 100;
    background: rgba(0,0,0,0.78); border: 1px solid #333;
    border-radius: 6px; padding: 8px 12px; min-width: 180px;
    font-size: 11px; color: #ccc; line-height: 1.7;
    font-family: 'Courier New', monospace;
}
#hud .val  { color: #0ff; font-weight: bold; }  /* cyan = default */
#hud .warn { color: #f90; }                      /* orange = warning */
#hud .bad  { color: #f44; }                      /* red = bad */
#hud .good { color: #4f4; }                      /* green = good */
```

```javascript
// ── FPS counter with rolling average ─────────────────────────────────────
var frameCount = 0, lastFpsTime = performance.now(), lastFrameTime = performance.now();
var currentFps = 60, currentMs = 16;

function animate() {
    requestAnimationFrame(animate);

    var now = performance.now();
    currentMs     = now - lastFrameTime;
    lastFrameTime = now;

    renderer.render(scene, camera);

    // Count frames, update HUD once per second
    frameCount++;
    if (now - lastFpsTime >= 1000) {
        currentFps  = Math.round(frameCount * 1000 / (now - lastFpsTime));
        frameCount  = 0;
        lastFpsTime = now;
        updateHUD(now);
    }

    adaptiveQuality(now);
}

function updateHUD(now) {
    var info = renderer.info;

    // FPS — color-coded: green ≥30, orange ≥20, red <20
    var fpsEl = document.getElementById('hFps');
    fpsEl.textContent = currentFps;
    fpsEl.className   = currentFps >= 30 ? 'val good' : currentFps >= 20 ? 'val warn' : 'val bad';

    document.getElementById('hMs').textContent   = currentMs.toFixed(1) + ' ms';
    document.getElementById('hDraw').textContent = info.render.calls;
    document.getElementById('hTris').textContent = (info.render.triangles / 1000).toFixed(1) + 'k';
    document.getElementById('hInst').textContent = totalInstances.toLocaleString();

    // JS heap memory — only available in Chrome/WebView (not Firefox/Safari)
    if (performance.memory) {
        var mb = (performance.memory.usedJSHeapSize / 1048576).toFixed(0);
        document.getElementById('hMem').textContent = mb + ' MB';
    } else {
        document.getElementById('hMem').textContent = 'n/a';
    }
}
```

---

## 12. Android build.gradle (PROVEN)

**WHY:** `noCompress 'glb', 'gltf', 'bin'` is critical — without it, Android compresses your GLB files in the APK and they become unreadable at runtime. `compileSdk 34` + `targetSdk 34` is required for Play Store submission in 2024+. The `copyWebAssets` task automates copying `viewer.html` and the `CONTENT/` folder into the assets directory before every build.

```groovy
plugins {
    id 'com.android.application'
}

android {
    namespace 'com.ramai.glbviewer'
    compileSdk 34

    defaultConfig {
        applicationId "com.ramai.glbviewer"
        minSdk 21        // Android 5.0+ — covers 99%+ of active devices
        targetSdk 34
        versionCode 1
        versionName "1.0"
    }

    buildTypes {
        release {
            minifyEnabled false
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
        debug {
            debuggable true
        }
    }

    compileOptions {
        sourceCompatibility JavaVersion.VERSION_1_8
        targetCompatibility JavaVersion.VERSION_1_8
    }

    sourceSets {
        main {
            assets { srcDirs = ['src/main/assets'] }
        }
    }

    // CRITICAL: do NOT compress GLB/GLTF/BIN files — they must be read as raw bytes
    aaptOptions {
        noCompress 'glb', 'gltf', 'bin'
    }
}

dependencies {
    implementation 'androidx.appcompat:appcompat:1.6.1'
    implementation 'com.google.android.material:material:1.11.0'
    // AdMob — use exact version to avoid Play Services conflicts
    implementation 'com.google.android.gms:play-services-ads:22.6.0'
}

// ── Auto-copy web assets before every build ───────────────────────────────
task copyWebAssets(type: Copy) {
    description = 'Copy HTML viewer and GLB files to assets directory'

    from('../viewer.html') {
        into 'www'
        rename { 'index.html' }
    }
    from('../CONTENT') {
        into 'www/CONTENT'
    }
    into 'src/main/assets'

    doLast { println "Copied web assets and GLB files to assets directory" }
}

preBuild.dependsOn copyWebAssets

task cleanWebAssets(type: Delete) {
    delete 'src/main/assets/www'
}
clean.dependsOn cleanWebAssets
```

---

## 13. MainActivity.java (PROVEN)

**WHY:** `setAllowFileAccess(true)` lets the WebView read files from the APK assets. `setAllowUniversalAccessFromFileURLs(true)` lets `file://` pages make XHR requests to other `file://` URLs — without this, the fetch/XHR patches cannot load GLB files. `LAYER_TYPE_HARDWARE` enables GPU compositing for the WebView. AdMob lifecycle methods (pause/resume/destroy) prevent memory leaks and ad billing issues.

```java
package com.ramai.glbviewer;

import android.annotation.SuppressLint;
import android.os.Bundle;
import android.view.View;
import android.webkit.WebChromeClient;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.FrameLayout;
import androidx.appcompat.app.AppCompatActivity;
import com.google.android.gms.ads.AdRequest;
import com.google.android.gms.ads.AdSize;
import com.google.android.gms.ads.AdView;
import com.google.android.gms.ads.MobileAds;

public class MainActivity extends AppCompatActivity {

    private WebView webView;
    private AdView  adView;

    @SuppressLint("SetJavaScriptEnabled")
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        FrameLayout rootLayout = new FrameLayout(this);
        rootLayout.setLayoutParams(new FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.MATCH_PARENT,
            FrameLayout.LayoutParams.MATCH_PARENT
        ));

        webView = new WebView(this);
        webView.setLayoutParams(new FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.MATCH_PARENT,
            FrameLayout.LayoutParams.MATCH_PARENT
        ));

        WebSettings ws = webView.getSettings();
        ws.setJavaScriptEnabled(true);           // REQUIRED — runs the engine
        ws.setDomStorageEnabled(true);           // localStorage support
        ws.setAllowFileAccess(true);             // read APK assets via file://
        ws.setAllowContentAccess(true);
        ws.setAllowUniversalAccessFromFileURLs(true); // CRITICAL — XHR from file:// to file://
        ws.setAllowFileAccessFromFileURLs(true);      // CRITICAL — same origin for file://
        ws.setMediaPlaybackRequiresUserGesture(false); // allow audio autoplay
        ws.setCacheMode(WebSettings.LOAD_DEFAULT);
        ws.setMixedContentMode(WebSettings.MIXED_CONTENT_ALWAYS_ALLOW);

        // GPU compositing — essential for smooth 3D rendering
        webView.setLayerType(View.LAYER_TYPE_HARDWARE, null);

        webView.setWebViewClient(new WebViewClient() {
            @Override
            public boolean shouldOverrideUrlLoading(WebView view, String url) {
                return false; // handle all URLs in-WebView
            }
        });
        webView.setWebChromeClient(new WebChromeClient());

        // Load from APK assets — path matches copyWebAssets task output
        webView.loadUrl("file:///android_asset/www/index.html");
        rootLayout.addView(webView);

        // ── AdMob setup ───────────────────────────────────────────────
        MobileAds.initialize(this, initializationStatus -> { /* ready */ });

        adView = new AdView(this);
        adView.setAdSize(AdSize.BANNER);
        adView.setAdUnitId("ca-app-pub-3940256099942544/6300978111"); // TEST ID — replace for prod

        FrameLayout.LayoutParams adParams = new FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.WRAP_CONTENT,
            FrameLayout.LayoutParams.WRAP_CONTENT
        );
        adParams.gravity = android.view.Gravity.BOTTOM | android.view.Gravity.CENTER_HORIZONTAL;
        adView.setLayoutParams(adParams);
        rootLayout.addView(adView);
        adView.loadAd(new AdRequest.Builder().build());

        setContentView(rootLayout);
    }

    @Override
    public void onBackPressed() {
        if (webView.canGoBack()) webView.goBack();
        else super.onBackPressed();
    }

    // ── AdMob lifecycle — MUST implement all three to avoid memory leaks ──
    @Override protected void onPause()   { if (adView != null) adView.pause();   super.onPause(); }
    @Override protected void onResume()  { super.onResume();  if (adView != null) adView.resume(); }
    @Override protected void onDestroy() { if (adView != null) adView.destroy(); super.onDestroy(); }
}
```

