# Browser-Based Level Editor
## Unreal Viewport-Inspired Scene Editor

---

## Overview

A browser-based level editor that runs in the same HTML file as the engine.
Toggle between **Play Mode** and **Editor Mode** with a single button.

```
┌─────────────────────────────────────────────────────────────────┐
│  [▶ PLAY] [⏸ PAUSE] [⏹ STOP]    RAMAI ENGINE EDITOR    [⚙ SETTINGS] │
├──────────────┬──────────────────────────────┬───────────────────┤
│              │                              │                   │
│  OUTLINER    │      3D VIEWPORT             │   PROPERTIES      │
│              │                              │                   │
│ ▼ World      │   [Perspective ▼] [Lit ▼]   │  Transform        │
│   ├ Player   │                              │  X: 0.00          │
│   ├ Enemy_01 │   (Three.js canvas)          │  Y: 0.00          │
│   ├ Building │                              │  Z: 0.00          │
│   └ Road_01  │                              │                   │
│              │                              │  Components       │
│  ASSET BROWSER│                             │  + MeshComponent  │
│  [Characters]│                              │  + RigidBody      │
│  [Vehicles]  │                              │  + Script         │
│  [Buildings] │                              │                   │
└──────────────┴──────────────────────────────┴───────────────────┘
│  CONSOLE: [INFO] Scene loaded. 42 actors, 3 lights.             │
└─────────────────────────────────────────────────────────────────┘
```

---

## 1. Editor Mode Toggle

```javascript
class Editor {
    static _active = false;
    static _gizmo = null;
    static _selectedActor = null;
    static _orbitControls = null;
    
    static toggle() {
        this._active = !this._active;
        
        if (this._active) {
            this._enter();
        } else {
            this._exit();
        }
    }
    
    static _enter() {
        // Pause game
        Time.timeScale = 0;
        
        // Show editor UI
        document.getElementById('editorUI').style.display = 'flex';
        
        // Enable orbit controls
        this._orbitControls = new THREE.OrbitControls(camera, renderer.domElement);
        this._orbitControls.enableDamping = true;
        
        // Enable gizmo
        this._gizmo = new TransformGizmo(scene, camera, renderer);
        
        // Enable click-to-select
        renderer.domElement.addEventListener('click', this._onViewportClick.bind(this));
        
        // Populate outliner
        this._refreshOutliner();
        
        console.log('[Editor] Entered editor mode');
    }
    
    static _exit() {
        Time.timeScale = 1;
        document.getElementById('editorUI').style.display = 'none';
        
        this._orbitControls?.dispose();
        this._gizmo?.dispose();
        renderer.domElement.removeEventListener('click', this._onViewportClick);
        
        console.log('[Editor] Exited editor mode');
    }
    
    static _onViewportClick(e) {
        // Raycast to select actor
        const hit = Raycast.fromScreen(e.clientX, e.clientY, camera);
        if (hit?.actor) {
            this.selectActor(hit.actor);
        } else {
            this.selectActor(null);
        }
    }
    
    static selectActor(actor) {
        this._selectedActor = actor;
        
        if (actor) {
            // Attach gizmo to selected actor
            this._gizmo.attach(actor.transform);
            
            // Show properties panel
            this._refreshProperties(actor);
            
            // Highlight in outliner
            this._highlightOutliner(actor.id);
        } else {
            this._gizmo.detach();
            this._clearProperties();
        }
    }
}
```

---

## 2. Transform Gizmo

```javascript
class TransformGizmo {
    // Translate/Rotate/Scale gizmo (like Unreal's viewport gizmo)
    _mode = 'translate';  // 'translate' | 'rotate' | 'scale'
    _target = null;
    _arrows = {};
    _isDragging = false;
    _dragAxis = null;
    
    constructor(scene, camera, renderer) {
        this._scene = scene;
        this._camera = camera;
        this._renderer = renderer;
        this._buildGizmo();
        this._setupEvents();
    }
    
    _buildGizmo() {
        this._group = new THREE.Group();
        this._group.visible = false;
        
        // X axis (red)
        this._arrows.x = this._createArrow(0xff0000, new THREE.Vector3(1,0,0));
        // Y axis (green)
        this._arrows.y = this._createArrow(0x00ff00, new THREE.Vector3(0,1,0));
        // Z axis (blue)
        this._arrows.z = this._createArrow(0x0000ff, new THREE.Vector3(0,0,1));
        
        this._group.add(this._arrows.x, this._arrows.y, this._arrows.z);
        this._scene.add(this._group);
    }
    
    _createArrow(color, direction) {
        const geo = new THREE.CylinderGeometry(0.05, 0.05, 1, 8);
        const mat = new THREE.MeshBasicMaterial({ color, depthTest: false });
        const mesh = new THREE.Mesh(geo, mat);
        
        // Cone tip
        const coneGeo = new THREE.ConeGeometry(0.1, 0.3, 8);
        const cone = new THREE.Mesh(coneGeo, mat);
        cone.position.y = 0.65;
        mesh.add(cone);
        
        // Orient along axis
        mesh.quaternion.setFromUnitVectors(new THREE.Vector3(0,1,0), direction);
        mesh.position.copy(direction.clone().multiplyScalar(0.5));
        
        mesh._axis = direction;
        mesh._color = color;
        return mesh;
    }
    
    attach(transform) {
        this._target = transform;
        this._group.visible = true;
        this._group.position.copy(transform.position);
    }
    
    detach() {
        this._target = null;
        this._group.visible = false;
    }
    
    setMode(mode) {
        this._mode = mode;
        this._buildGizmo();  // rebuild for mode
    }
    
    update() {
        if (!this._target) return;
        
        // Keep gizmo at actor position
        this._group.position.copy(this._target.position);
        
        // Scale gizmo with camera distance (constant screen size)
        const dist = this._camera.position.distanceTo(this._group.position);
        const scale = dist * 0.1;
        this._group.scale.setScalar(scale);
    }
}
```

---

## 3. Outliner Panel

```javascript
class OutlinerPanel {
    _el = null;
    
    create() {
        this._el = document.getElementById('outliner');
    }
    
    refresh(world) {
        this._el.innerHTML = '';
        
        const tree = document.createElement('div');
        tree.className = 'outliner-tree';
        
        world.actors.forEach((actor, id) => {
            const item = document.createElement('div');
            item.className = 'outliner-item';
            item.dataset.actorId = id;
            
            // Icon based on components
            const icon = actor.getComponent(MeshComponent) ? '🔷' :
                         actor.getComponent(LightComponent) ? '💡' : '📦';
            
            item.innerHTML = `
                <span class="icon">${icon}</span>
                <span class="name">${actor.name || `Actor_${id}`}</span>
                <span class="tags">${[...actor.tags].join(', ')}</span>
            `;
            
            item.onclick = () => Editor.selectActor(actor);
            
            tree.appendChild(item);
        });
        
        this._el.appendChild(tree);
    }
    
    highlight(actorId) {
        document.querySelectorAll('.outliner-item').forEach(el => {
            el.classList.toggle('selected', el.dataset.actorId == actorId);
        });
    }
}
```

---

## 4. Properties Panel

```javascript
class PropertiesPanel {
    _el = null;
    
    create() {
        this._el = document.getElementById('properties');
    }
    
    show(actor) {
        const t = actor.transform;
        
        this._el.innerHTML = `
            <div class="prop-section">
                <div class="prop-header">Transform</div>
                <div class="prop-row">
                    <label>X</label>
                    <input type="number" class="prop-input" data-prop="pos.x" 
                           value="${t.position.x.toFixed(2)}" step="0.1">
                </div>
                <div class="prop-row">
                    <label>Y</label>
                    <input type="number" class="prop-input" data-prop="pos.y" 
                           value="${t.position.y.toFixed(2)}" step="0.1">
                </div>
                <div class="prop-row">
                    <label>Z</label>
                    <input type="number" class="prop-input" data-prop="pos.z" 
                           value="${t.position.z.toFixed(2)}" step="0.1">
                </div>
            </div>
            
            <div class="prop-section">
                <div class="prop-header">Components</div>
                ${[...actor.components.entries()].map(([type, comp]) => `
                    <div class="prop-component">
                        <span class="comp-name">${type.name}</span>
                        <span class="comp-enabled">${comp.enabled ? '✓' : '✗'}</span>
                    </div>
                `).join('')}
                <button class="prop-btn" onclick="Editor.addComponent()">+ Add Component</button>
            </div>
            
            <div class="prop-section">
                <div class="prop-header">Tags</div>
                <div class="prop-tags">
                    ${[...actor.tags].map(tag => `
                        <span class="tag-chip">${tag} <button onclick="Editor.removeTag('${tag}')">×</button></span>
                    `).join('')}
                    <input type="text" placeholder="Add tag..." class="tag-input" 
                           onkeydown="if(event.key==='Enter') Editor.addTag(this.value)">
                </div>
            </div>
        `;
        
        // Wire property inputs
        this._el.querySelectorAll('.prop-input').forEach(input => {
            input.addEventListener('change', (e) => {
                const [obj, key] = e.target.dataset.prop.split('.');
                if (obj === 'pos') actor.transform.position[key] = parseFloat(e.target.value);
            });
        });
    }
}
```

---

## 5. Asset Browser

```javascript
class AssetBrowser {
    _el = null;
    _category = 'characters';
    
    create() {
        this._el = document.getElementById('assetBrowser');
        this._buildCategoryTabs();
        this._showCategory('characters');
    }
    
    _buildCategoryTabs() {
        const tabs = ['Characters', 'Vehicles', 'Buildings', 'Roads', 'Props'];
        const tabBar = document.createElement('div');
        tabBar.className = 'asset-tabs';
        
        tabs.forEach(tab => {
            const btn = document.createElement('button');
            btn.textContent = tab;
            btn.onclick = () => this._showCategory(tab.toLowerCase());
            tabBar.appendChild(btn);
        });
        
        this._el.appendChild(tabBar);
    }
    
    _showCategory(category) {
        const assets = ASSET_CATALOG[category] ?? [];
        const grid = document.createElement('div');
        grid.className = 'asset-grid';
        
        Object.values(assets).flat().forEach(asset => {
            const item = document.createElement('div');
            item.className = 'asset-item';
            item.innerHTML = `
                <div class="asset-preview">🔷</div>
                <div class="asset-name">${asset.key}</div>
            `;
            
            // Drag to viewport to spawn
            item.draggable = true;
            item.addEventListener('dragstart', (e) => {
                e.dataTransfer.setData('assetUrl', asset.url);
                e.dataTransfer.setData('assetKey', asset.key);
            });
            
            // Double-click to spawn at origin
            item.ondblclick = () => {
                Editor.spawnAsset(asset.url, new THREE.Vector3(0, 0, 0));
            };
            
            grid.appendChild(item);
        });
        
        // Replace content
        const existing = this._el.querySelector('.asset-grid');
        if (existing) existing.remove();
        this._el.appendChild(grid);
    }
}
```

---

## 6. Level Save/Load (JSON format)

```javascript
// Save level to JSON
function saveLevel() {
    const levelData = {
        version: '1.0',
        name: 'My Level',
        actors: []
    };
    
    World.actors.forEach(actor => {
        levelData.actors.push({
            id: actor.id,
            name: actor.name,
            tags: [...actor.tags],
            transform: {
                position: actor.transform.position.toArray(),
                rotation: actor.transform.rotation.toArray(),
                scale: actor.transform.scale.toArray()
            },
            components: [...actor.components.entries()].map(([type, comp]) => ({
                type: type.name,
                config: comp.serialize?.() ?? {}
            })),
            assetUrl: actor._assetUrl
        });
    });
    
    const json = JSON.stringify(levelData, null, 2);
    
    // Download as file
    const blob = new Blob([json], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = 'level.json';
    a.click();
}

// Load level from JSON
async function loadLevel(levelData) {
    World.clear();
    
    for (const actorData of levelData.actors) {
        const actor = World.spawnActor(Actor, {
            name: actorData.name,
            tags: actorData.tags
        });
        
        actor.transform.position.fromArray(actorData.transform.position);
        actor.transform.rotation.fromArray(actorData.transform.rotation);
        actor.transform.scale.fromArray(actorData.transform.scale);
        
        if (actorData.assetUrl) {
            const gltf = await AssetManager.loadGLB(actorData.assetUrl);
            const mesh = actor.addComponent(MeshComponent);
            mesh.setMesh(gltf.scene.clone());
            actor._assetUrl = actorData.assetUrl;
        }
    }
}
```
