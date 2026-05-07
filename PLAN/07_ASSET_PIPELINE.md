# Asset Pipeline & Management
## Loading, Streaming, Caching, LOD Generation

---

## 1. Asset Manager (Upgrade from Current texCache)

```javascript
class AssetManager {
    // Typed caches per asset type
    _glbCache     = new Map();  // url → { scene, animations, gltf }
    _textureCache = new Map();  // url → THREE.Texture
    _audioCache   = new Map();  // url → AudioBuffer
    _jsonCache    = new Map();  // url → Object
    
    // Loading queue with priority
    _queue    = [];
    _loading  = new Set();
    _maxConcurrent = 3;  // mobile: don't overload bandwidth
    
    // Memory tracking
    _memoryUsed = 0;
    _memoryBudget = 200 * 1024 * 1024;  // 200MB
    
    // ── GLB Loading ──────────────────────────────────────────────────
    async loadGLB(url, options = {}) {
        if (this._glbCache.has(url)) {
            return this._glbCache.get(url);
        }
        
        // XHR binary load (works on file:// Android WebView)
        const buffer = await this._loadBinary(url, options.onProgress);
        
        return new Promise((resolve, reject) => {
            const basePath = url.substring(0, url.lastIndexOf('/') + 1);
            const loader = new THREE.GLTFLoader();
            
            loader.parse(buffer, basePath, (gltf) => {
                const asset = {
                    scene:      gltf.scene,
                    animations: gltf.animations,
                    cameras:    gltf.cameras,
                    gltf
                };
                
                this._glbCache.set(url, asset);
                this._trackMemory(url, buffer.byteLength);
                resolve(asset);
            }, reject);
        });
    }
    
    // Clone a loaded GLB for instancing (share geometry, clone materials)
    cloneGLB(url) {
        const asset = this._glbCache.get(url);
        if (!asset) throw new Error(`GLB not loaded: ${url}`);
        
        // Deep clone scene, share geometries
        const clone = asset.scene.clone(true);
        
        // Clone materials so each instance can have unique properties
        clone.traverse(child => {
            if (child.isMesh) {
                child.material = child.material.clone();
            }
        });
        
        return clone;
    }
    
    // ── Texture Loading ──────────────────────────────────────────────
    async loadTexture(url, options = {}) {
        if (this._textureCache.has(url)) {
            return this._textureCache.get(url);
        }
        
        return new Promise((resolve, reject) => {
            const xhr = new XMLHttpRequest();
            xhr.open('GET', url, true);
            xhr.responseType = 'blob';
            xhr.onload = () => {
                if (xhr.status === 200 || xhr.status === 0) {
                    const blobUrl = URL.createObjectURL(xhr.response);
                    const img = new window._NativeImage();
                    img.onload = () => {
                        const tex = new THREE.Texture(img);
                        tex.wrapS = tex.wrapT = options.wrap ?? THREE.ClampToEdgeWrapping;
                        tex.minFilter = THREE.LinearMipMapLinearFilter;
                        tex.magFilter = THREE.LinearFilter;
                        tex.generateMipmaps = true;
                        tex.anisotropy = options.anisotropy ?? 4;
                        tex.needsUpdate = true;
                        
                        this._textureCache.set(url, tex);
                        resolve(tex);
                    };
                    img.onerror = () => reject(new Error(`Image load failed: ${url}`));
                    img.src = blobUrl;
                } else {
                    reject(new Error(`HTTP ${xhr.status}: ${url}`));
                }
            };
            xhr.onerror = () => reject(new Error(`XHR error: ${url}`));
            xhr.send();
        });
    }
    
    // ── Preload Bundle ───────────────────────────────────────────────
    // Load a set of assets with progress callback (like UE's async loading)
    async preloadBundle(manifest, onProgress) {
        const total = manifest.length;
        let loaded = 0;
        
        const results = {};
        
        // Load in batches of _maxConcurrent
        for (let i = 0; i < manifest.length; i += this._maxConcurrent) {
            const batch = manifest.slice(i, i + this._maxConcurrent);
            
            await Promise.all(batch.map(async (item) => {
                try {
                    switch (item.type) {
                        case 'glb':
                            results[item.key] = await this.loadGLB(item.url);
                            break;
                        case 'texture':
                            results[item.key] = await this.loadTexture(item.url);
                            break;
                        case 'audio':
                            results[item.key] = await AudioSystem.load(item.url);
                            break;
                        case 'json':
                            results[item.key] = await this.loadJSON(item.url);
                            break;
                    }
                } catch (e) {
                    console.warn(`[Assets] Failed to load ${item.url}:`, e);
                }
                
                loaded++;
                onProgress?.(loaded / total, item.url);
            }));
        }
        
        return results;
    }
    
    // ── Memory Management ────────────────────────────────────────────
    _trackMemory(url, bytes) {
        this._memoryUsed += bytes;
        
        if (this._memoryUsed > this._memoryBudget) {
            console.warn(`[Assets] Memory budget exceeded: ${(this._memoryUsed/1048576).toFixed(0)}MB`);
            this._evictLRU();
        }
    }
    
    // Evict least-recently-used assets
    _evictLRU() {
        // Sort by last access time, evict oldest
        // Only evict non-essential assets (not currently in scene)
    }
    
    // Dispose all assets for a level
    unloadLevel(levelId) {
        const levelAssets = this._levelManifests.get(levelId);
        if (!levelAssets) return;
        
        levelAssets.forEach(url => {
            const tex = this._textureCache.get(url);
            if (tex) { tex.dispose(); this._textureCache.delete(url); }
            
            const glb = this._glbCache.get(url);
            if (glb) {
                glb.scene.traverse(child => {
                    if (child.isMesh) {
                        child.geometry?.dispose();
                        child.material?.dispose();
                    }
                });
                this._glbCache.delete(url);
            }
        });
    }
    
    // ── Binary Loader (from current codebase) ───────────────────────
    _loadBinary(url, onProgress) {
        return new Promise((resolve, reject) => {
            const xhr = new XMLHttpRequest();
            xhr.open('GET', url, true);
            xhr.responseType = 'arraybuffer';
            xhr.onprogress = (e) => {
                if (onProgress && e.lengthComputable) {
                    onProgress(e.loaded / e.total);
                }
            };
            xhr.onload = () => {
                (xhr.status === 200 || xhr.status === 0)
                    ? resolve(xhr.response)
                    : reject(new Error(`HTTP ${xhr.status}: ${url}`));
            };
            xhr.onerror = () => reject(new Error(`XHR error: ${url}`));
            xhr.send();
        });
    }
}
```

---

## 2. Level Manifest System

```javascript
// Level manifest — defines what to load for each level
// Like UE's Level Streaming

const LEVEL_MANIFESTS = {
    level_01: {
        name: 'City Streets',
        skybox: 'assets/skybox/day.jpg',
        terrain: 'CONTENT/MESHES/kenney_city-kit-roads/',
        
        assets: [
            // Static geometry (load once, instance many)
            { key: 'building_a',  type: 'glb', url: 'CONTENT/MESHES/kenney_city-kit-commercial_2.1/building-a.glb' },
            { key: 'building_b',  type: 'glb', url: 'CONTENT/MESHES/kenney_city-kit-commercial_2.1/building-b.glb' },
            { key: 'road_straight', type: 'glb', url: 'CONTENT/MESHES/kenney_city-kit-roads/road-straight.glb' },
            { key: 'road_corner',   type: 'glb', url: 'CONTENT/MESHES/kenney_city-kit-roads/road-corner.glb' },
            
            // Characters
            { key: 'player',    type: 'glb', url: 'CONTENT/MESHES/kenney_blocky-characters_20/character-a.glb' },
            { key: 'enemy_a',   type: 'glb', url: 'CONTENT/MESHES/kenney_blocky-characters_20/character-b.glb' },
            
            // Vehicles
            { key: 'car_police', type: 'glb', url: 'CONTENT/MESHES/kenney_car-kit/police.glb' },
            { key: 'car_sedan',  type: 'glb', url: 'CONTENT/MESHES/kenney_car-kit/sedan.glb' },
            
            // Audio
            { key: 'music_city',  type: 'audio', url: 'assets/audio/city_ambient.mp3' },
            { key: 'sfx_footstep', type: 'audio', url: 'assets/audio/footstep.mp3' },
            { key: 'sfx_gunshot',  type: 'audio', url: 'assets/audio/gunshot.mp3' },
        ],
        
        // Spawn points
        playerSpawn: { x: 0, y: 0, z: 0 },
        
        // Level data (procedural or hand-placed)
        layout: 'assets/levels/level_01.json'
    }
};
```

---

## 3. Streaming System (for large open worlds)

```javascript
class StreamingSystem {
    // Divide world into chunks, load/unload based on player position
    _chunkSize = 100;  // world units per chunk
    _loadRadius = 3;   // chunks to keep loaded around player
    _loadedChunks = new Map();  // "x,z" → ChunkData
    
    update(playerPos) {
        const cx = Math.floor(playerPos.x / this._chunkSize);
        const cz = Math.floor(playerPos.z / this._chunkSize);
        
        // Determine which chunks should be loaded
        const needed = new Set();
        for (let dx = -this._loadRadius; dx <= this._loadRadius; dx++) {
            for (let dz = -this._loadRadius; dz <= this._loadRadius; dz++) {
                needed.add(`${cx + dx},${cz + dz}`);
            }
        }
        
        // Load new chunks
        needed.forEach(key => {
            if (!this._loadedChunks.has(key)) {
                this._loadChunk(key);
            }
        });
        
        // Unload distant chunks
        this._loadedChunks.forEach((chunk, key) => {
            if (!needed.has(key)) {
                this._unloadChunk(key);
            }
        });
    }
    
    async _loadChunk(key) {
        const [cx, cz] = key.split(',').map(Number);
        const url = `assets/chunks/chunk_${cx}_${cz}.json`;
        
        try {
            const data = await AssetManager.loadJSON(url);
            const chunk = await this._buildChunk(data, cx, cz);
            this._loadedChunks.set(key, chunk);
        } catch (e) {
            // Chunk doesn't exist — empty area
        }
    }
    
    _unloadChunk(key) {
        const chunk = this._loadedChunks.get(key);
        if (chunk) {
            chunk.objects.forEach(obj => {
                scene.remove(obj);
                obj.geometry?.dispose();
            });
            this._loadedChunks.delete(key);
        }
    }
}
```

---

## 4. Asset Manifest for All Kenney Kits

```javascript
// Complete catalog of available assets
const ASSET_CATALOG = {
    characters: {
        blocky: [
            'character-a', 'character-b', 'character-c', 'character-d',
            'character-e', 'character-f', 'character-g', 'character-h',
            'character-i', 'character-j', 'character-k', 'character-l',
            'character-m', 'character-n', 'character-o', 'character-p',
            'character-q', 'character-r'
        ].map(n => ({
            key: n,
            url: `CONTENT/MESHES/kenney_blocky-characters_20/${n}.glb`,
            type: 'character'
        })),
        mini: [] // kenney_mini-characters
    },
    
    vehicles: {
        cars: ['sedan', 'sedan-sports', 'race', 'race-future', 'police',
               'ambulance', 'firetruck', 'taxi', 'van', 'truck', 'truck-flat',
               'delivery', 'delivery-flat', 'garbage-truck', 'hatchback-sports',
               'suv', 'suv-luxury', 'tractor', 'tractor-police', 'tractor-shovel']
            .map(n => ({
                key: n,
                url: `CONTENT/MESHES/kenney_car-kit/${n}.glb`,
                type: 'vehicle'
            }))
    },
    
    buildings: {
        commercial: ['building-a','building-b','building-c','building-d','building-e',
                     'building-skyscraper-a','building-skyscraper-b']
            .map(n => ({
                key: n,
                url: `CONTENT/MESHES/kenney_city-kit-commercial_2.1/${n}.glb`,
                type: 'building'
            })),
        suburban: [],   // kenney_city-kit-suburban_20
        industrial: [], // kenney_city-kit-industrial_1.0
        modular: []     // kenney_modular-buildings
    },
    
    roads: {
        city: [] // kenney_city-kit-roads — 80+ pieces
    },
    
    environment: {
        space: [],   // kenney_space-station-kit
        pirate: [],  // kenney_pirate-kit
        retro: []    // kenney_retro-urban-kit
    }
};
```
