# Rendering Pipeline — AAA Mobile Quality
## PBR + Post-Processing + LOD + Instancing

---

## Rendering Architecture Overview

```
Scene Data
    │
    ▼
┌─────────────────────────────────────────────────────┐
│  VISIBILITY PASS                                    │
│  • Frustum Culling (AABB vs camera frustum)         │
│  • Occlusion Culling (hierarchical Z-buffer)        │
│  • LOD Selection (distance-based)                   │
└─────────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────────────┐
│  SHADOW PASS                                        │
│  • Cascaded Shadow Maps (CSM) — 2 cascades mobile  │
│  • PCF-Soft filtering                               │
│  • Shadow bias auto-calibration                     │
└─────────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────────────┐
│  GEOMETRY PASS (Opaque)                             │
│  • Instanced draw calls (InstancedMesh)             │
│  • PBR MeshStandardMaterial                         │
│  • Normal maps, roughness/metalness maps            │
│  • Vertex color support                             │
└─────────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────────────┐
│  LIGHTING PASS                                      │
│  • Hemisphere ambient (sky/ground)                  │
│  • Directional sun + shadows                        │
│  • Point lights (max 4 mobile, 8 high-end)          │
│  • Spot lights (max 2 mobile)                       │
│  • Environment map (IBL) — optional                 │
└─────────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────────────┐
│  TRANSPARENT PASS                                   │
│  • Sorted back-to-front                             │
│  • Additive particles                               │
│  • Alpha-blended glass/water                        │
└─────────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────────────┐
│  POST-PROCESSING STACK                              │
│  • Bloom (threshold + blur)                         │
│  • Tone Mapping (ACES filmic)                       │
│  • Color Grading (LUT)                              │
│  • Vignette                                         │
│  • FXAA (mobile anti-alias)                         │
│  • Motion Blur (optional, high-end only)            │
└─────────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────────────┐
│  UI PASS (Canvas 2D overlay)                        │
│  • HUD elements                                     │
│  • Menus                                            │
│  • Debug overlays                                   │
└─────────────────────────────────────────────────────┘
```

---

## 1. Renderer Setup (Upgrade from Current)

```javascript
// Current: basic WebGLRenderer
// Target: full pipeline with render targets

class RenderSystem {
    init(canvas) {
        this.renderer = new THREE.WebGLRenderer({
            canvas,
            antialias: false,          // FXAA in post instead
            powerPreference: 'high-performance',
            stencil: false,
            depth: true,
            logarithmicDepthBuffer: false  // off for mobile perf
        });
        
        // Tone mapping — ACES filmic (Unreal default)
        this.renderer.toneMapping = THREE.ACESFilmicToneMapping;
        this.renderer.toneMappingExposure = 1.0;
        this.renderer.outputColorSpace = THREE.SRGBColorSpace;
        
        // Shadow config
        this.renderer.shadowMap.enabled = true;
        this.renderer.shadowMap.type = THREE.PCFSoftShadowMap;
        
        // Render targets for post-processing
        this._setupRenderTargets();
        this._setupPostFX();
    }
    
    _setupRenderTargets() {
        const w = window.innerWidth, h = window.innerHeight;
        
        // Main HDR render target
        this.hdrTarget = new THREE.WebGLRenderTarget(w, h, {
            type: THREE.HalfFloatType,   // HDR for bloom
            format: THREE.RGBAFormat,
            minFilter: THREE.LinearFilter,
            magFilter: THREE.LinearFilter,
            generateMipmaps: false
        });
        
        // Bloom targets (half resolution)
        this.bloomTarget1 = new THREE.WebGLRenderTarget(w/2, h/2, {
            type: THREE.HalfFloatType,
            minFilter: THREE.LinearFilter,
            magFilter: THREE.LinearFilter
        });
        this.bloomTarget2 = new THREE.WebGLRenderTarget(w/2, h/2, {
            type: THREE.HalfFloatType,
            minFilter: THREE.LinearFilter,
            magFilter: THREE.LinearFilter
        });
    }
}
```

---

## 2. LOD System

```javascript
class LODSystem {
    // Distance thresholds for LOD switching
    static THRESHOLDS = [
        { dist: 20,  lod: 0 },   // Full detail
        { dist: 50,  lod: 1 },   // 50% triangles
        { dist: 100, lod: 2 },   // 25% triangles
        { dist: 200, lod: 3 },   // Billboard / impostor
    ];
    
    // For instanced meshes: use THREE.LOD or custom distance check
    updateLODs(camera, instancedMeshes) {
        const camPos = camera.position;
        
        instancedMeshes.forEach(iMesh => {
            // Per-instance LOD via custom shader attribute
            // or swap geometry at batch level
            const dist = iMesh.position.distanceTo(camPos);
            const lodLevel = this._getLODLevel(dist);
            
            if (iMesh._currentLOD !== lodLevel) {
                iMesh._currentLOD = lodLevel;
                iMesh.geometry = iMesh._lodGeometries[lodLevel];
            }
        });
    }
    
    // Generate LOD geometries from full-res mesh
    generateLODs(geometry) {
        return [
            geometry,                              // LOD0: full
            this._simplify(geometry, 0.5),         // LOD1: 50%
            this._simplify(geometry, 0.25),        // LOD2: 25%
            this._createBillboard(geometry),       // LOD3: billboard
        ];
    }
    
    // Simple vertex decimation (every Nth vertex)
    _simplify(geo, ratio) {
        // Implement: skip vertices, rebuild index buffer
        // For production: use meshoptimizer WASM
    }
}
```

---

## 3. Frustum Culling (Upgrade Current)

```javascript
class FrustumCuller {
    _frustum = new THREE.Frustum();
    _projScreenMatrix = new THREE.Matrix4();
    
    update(camera) {
        this._projScreenMatrix.multiplyMatrices(
            camera.projectionMatrix,
            camera.matrixWorldInverse
        );
        this._frustum.setFromProjectionMatrix(this._projScreenMatrix);
    }
    
    // For InstancedMesh: cull individual instances
    cullInstances(iMesh, boundingSpheres) {
        let visibleCount = 0;
        const dummy = new THREE.Object3D();
        const mat = new THREE.Matrix4();
        
        for (let i = 0; i < iMesh.count; i++) {
            iMesh.getMatrixAt(i, mat);
            const sphere = boundingSpheres[i];
            sphere.applyMatrix4(mat);
            
            if (this._frustum.intersectsSphere(sphere)) {
                // Swap to front of instance buffer
                iMesh.setMatrixAt(visibleCount, mat);
                visibleCount++;
            }
        }
        
        iMesh.count = visibleCount;  // render only visible
        iMesh.instanceMatrix.needsUpdate = true;
    }
}
```

---

## 4. Post-Processing Stack

### Bloom Shader
```glsl
// Threshold pass — extract bright pixels
uniform sampler2D tDiffuse;
uniform float threshold;
uniform float knee;

void main() {
    vec4 color = texture2D(tDiffuse, vUv);
    float brightness = dot(color.rgb, vec3(0.2126, 0.7152, 0.0722));
    
    // Soft threshold (Unreal-style)
    float rq = clamp(brightness - threshold + knee, 0.0, 2.0 * knee);
    rq = (rq * rq) / (4.0 * knee + 0.00001);
    float weight = max(rq, brightness - threshold) / max(brightness, 0.00001);
    
    gl_FragColor = vec4(color.rgb * weight, 1.0);
}
```

### ACES Tone Mapping (already in Three.js, but custom version)
```glsl
// ACES filmic tone mapping — same as Unreal Engine default
vec3 ACESFilm(vec3 x) {
    float a = 2.51;
    float b = 0.03;
    float c = 2.43;
    float d = 0.59;
    float e = 0.14;
    return clamp((x*(a*x+b))/(x*(c*x+d)+e), 0.0, 1.0);
}
```

### FXAA (Fast Approximate Anti-Aliasing)
```glsl
// Lightweight FXAA — better than MSAA on mobile
// Based on NVIDIA FXAA 3.11
uniform sampler2D tDiffuse;
uniform vec2 resolution;

void main() {
    vec2 texelSize = 1.0 / resolution;
    // ... FXAA implementation
    // Sample 9 neighbors, detect edges, blend
}
```

---

## 5. Material System

```javascript
class MaterialSystem {
    // Material presets (like UE Material Instances)
    static PRESETS = {
        OPAQUE_PBR: {
            type: 'MeshStandardMaterial',
            roughness: 0.8,
            metalness: 0.0,
            envMapIntensity: 0.5
        },
        METAL: {
            type: 'MeshStandardMaterial',
            roughness: 0.2,
            metalness: 0.9,
            envMapIntensity: 1.0
        },
        GLASS: {
            type: 'MeshPhysicalMaterial',
            roughness: 0.0,
            metalness: 0.0,
            transmission: 0.9,
            transparent: true,
            opacity: 0.3
        },
        EMISSIVE: {
            type: 'MeshStandardMaterial',
            emissive: 0xffffff,
            emissiveIntensity: 2.0
        },
        UNLIT: {
            type: 'MeshBasicMaterial'
        }
    };
    
    // Material cache — never create duplicates
    _cache = new Map();
    
    getMaterial(preset, overrides = {}) {
        const key = JSON.stringify({ preset, overrides });
        if (this._cache.has(key)) return this._cache.get(key);
        
        const config = { ...MaterialSystem.PRESETS[preset], ...overrides };
        const mat = new THREE[config.type](config);
        this._cache.set(key, mat);
        return mat;
    }
    
    // Dispose unused materials
    gc() {
        this._cache.forEach((mat, key) => {
            if (mat._refCount === 0) {
                mat.dispose();
                this._cache.delete(key);
            }
        });
    }
}
```

---

## 6. Dynamic Lighting

```javascript
class LightingSystem {
    // Max lights per quality tier
    static MAX_LIGHTS = { LOW: 2, MED: 4, HIGH: 8 };
    
    // Light pool — reuse Three.js light objects
    _pointLightPool = [];
    _spotLightPool  = [];
    
    // Unreal-style light priority: distance + intensity
    _sortLightsByPriority(lights, cameraPos) {
        return lights.sort((a, b) => {
            const distA = a.position.distanceTo(cameraPos) / a.intensity;
            const distB = b.position.distanceTo(cameraPos) / b.intensity;
            return distA - distB;
        });
    }
    
    // Activate only the N most important lights
    updateActiveLights(allLights, camera, quality) {
        const maxLights = LightingSystem.MAX_LIGHTS[quality];
        const sorted = this._sortLightsByPriority(allLights, camera.position);
        
        sorted.forEach((light, i) => {
            light.threeLight.visible = i < maxLights;
        });
    }
    
    // Baked lightmap support (for static geometry)
    applyLightmap(mesh, lightmapTexture) {
        mesh.material.lightMap = lightmapTexture;
        mesh.material.lightMapIntensity = 1.0;
    }
}
```

---

## 7. Adaptive Quality System (Full Implementation)

```javascript
class AdaptiveQuality {
    // Quality tiers — like UE's scalability settings
    static TIERS = {
        POTATO: { pr: 0.5,  shadow: 256,  fog: 0.025, lights: 1, postfx: false, particles: false },
        LOW:    { pr: 0.75, shadow: 512,  fog: 0.018, lights: 2, postfx: false, particles: true  },
        MED:    { pr: 1.0,  shadow: 1024, fog: 0.010, lights: 4, postfx: true,  particles: true  },
        HIGH:   { pr: 1.5,  shadow: 2048, fog: 0.006, lights: 8, postfx: true,  particles: true  },
        ULTRA:  { pr: 2.0,  shadow: 4096, fog: 0.004, lights: 8, postfx: true,  particles: true  },
    };
    
    _fpsHistory = new Float32Array(60);  // rolling 60-frame window
    _historyIdx = 0;
    _currentTier = 'MED';
    _lastAdjust = 0;
    _COOLDOWN = 3000; // ms between adjustments
    
    update(fps, now) {
        this._fpsHistory[this._historyIdx++ % 60] = fps;
        
        if (now - this._lastAdjust < this._COOLDOWN) return;
        
        const avgFps = this._fpsHistory.reduce((a,b) => a+b) / 60;
        
        if (avgFps < 25 && this._currentTier !== 'POTATO') {
            this._downgrade();
        } else if (avgFps > 55 && this._currentTier !== 'ULTRA') {
            this._upgrade();
        }
    }
    
    _downgrade() {
        const tiers = ['POTATO','LOW','MED','HIGH','ULTRA'];
        const idx = tiers.indexOf(this._currentTier);
        if (idx > 0) this._applyTier(tiers[idx - 1]);
    }
    
    _upgrade() {
        const tiers = ['POTATO','LOW','MED','HIGH','ULTRA'];
        const idx = tiers.indexOf(this._currentTier);
        if (idx < tiers.length - 1) this._applyTier(tiers[idx + 1]);
    }
    
    _applyTier(tier) {
        this._currentTier = tier;
        this._lastAdjust = performance.now();
        const cfg = AdaptiveQuality.TIERS[tier];
        
        renderer.setPixelRatio(cfg.pr);
        sun.shadow.mapSize.set(cfg.shadow, cfg.shadow);
        sun.shadow.map = null;
        scene.fog.density = cfg.fog;
        
        console.log(`[Quality] → ${tier}`);
        EventBus.emit('quality:changed', { tier, config: cfg });
    }
}
```

---

## 8. GPU Particle System

```javascript
class ParticleSystem {
    // GPU-simulated particles via custom shader
    // Position/velocity stored in texture (GPGPU pattern)
    
    createEmitter(config) {
        const {
            maxParticles = 1000,
            emitRate = 100,       // per second
            lifetime = 2.0,       // seconds
            startSize = 0.1,
            endSize = 0.0,
            startColor = 0xffffff,
            endColor = 0xff8800,
            gravity = -9.8,
            spread = 0.5,
            texture = null,
            blending = THREE.AdditiveBlending
        } = config;
        
        // Particle data in typed arrays (cache-friendly)
        const positions  = new Float32Array(maxParticles * 3);
        const velocities = new Float32Array(maxParticles * 3);
        const lifetimes  = new Float32Array(maxParticles);
        const sizes      = new Float32Array(maxParticles);
        
        const geometry = new THREE.BufferGeometry();
        geometry.setAttribute('position', new THREE.BufferAttribute(positions, 3));
        geometry.setAttribute('size',     new THREE.BufferAttribute(sizes, 1));
        
        const material = new THREE.ShaderMaterial({
            uniforms: {
                uTexture: { value: texture },
                uTime:    { value: 0 }
            },
            vertexShader: PARTICLE_VERT_SHADER,
            fragmentShader: PARTICLE_FRAG_SHADER,
            blending,
            depthWrite: false,
            transparent: true
        });
        
        return new THREE.Points(geometry, material);
    }
}

// Particle vertex shader
const PARTICLE_VERT_SHADER = `
    attribute float size;
    varying float vAlpha;
    
    void main() {
        vec4 mvPosition = modelViewMatrix * vec4(position, 1.0);
        gl_PointSize = size * (300.0 / -mvPosition.z);
        gl_Position = projectionMatrix * mvPosition;
        vAlpha = size;  // fade with size
    }
`;

const PARTICLE_FRAG_SHADER = `
    uniform sampler2D uTexture;
    varying float vAlpha;
    
    void main() {
        vec4 color = texture2D(uTexture, gl_PointCoord);
        gl_FragColor = vec4(color.rgb, color.a * vAlpha);
    }
`;
```

---

## 9. Environment & Sky

```javascript
// Procedural sky (like UE's Sky Atmosphere)
class SkySystem {
    createProceduralSky(scene) {
        // Sky shader — Rayleigh + Mie scattering
        const skyGeo = new THREE.SphereGeometry(500, 32, 15);
        const skyMat = new THREE.ShaderMaterial({
            uniforms: {
                uSunDirection: { value: new THREE.Vector3(0.5, 0.8, 0.3) },
                uSunColor:     { value: new THREE.Color(1.0, 0.9, 0.7) },
                uSkyColor:     { value: new THREE.Color(0.4, 0.6, 1.0) },
                uHorizonColor: { value: new THREE.Color(0.8, 0.85, 1.0) },
            },
            vertexShader: SKY_VERT,
            fragmentShader: SKY_FRAG,
            side: THREE.BackSide
        });
        
        return new THREE.Mesh(skyGeo, skyMat);
    }
    
    // Time-of-day system
    setTimeOfDay(hours) {
        // 0-24 hours
        // Adjust sun position, sky colors, fog color, light intensity
        const angle = (hours / 24) * Math.PI * 2 - Math.PI / 2;
        const sunDir = new THREE.Vector3(
            Math.cos(angle),
            Math.sin(angle),
            0.3
        ).normalize();
        
        // Lerp sky colors based on time
        // Dawn: orange/pink, Noon: blue, Dusk: orange/red, Night: dark blue
    }
}
```
