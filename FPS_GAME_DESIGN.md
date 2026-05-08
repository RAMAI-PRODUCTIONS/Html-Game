# Call of Duty-Style FPS Game - Complete Design Document

## Overview
Transform the RAMAI Engine into a full Call of Duty-style first-person shooter with urban combat, weapon systems, enemy AI, and proper level design using the available Kenney asset kits.

## Game Features

### 1. FPS Camera System
- **First-Person View**: Camera at player eye level (1.7m height)
- **Mouse Look**: Full 360° horizontal, -89° to +89° vertical
- **Head Bob**: Subtle camera movement when walking
- **Weapon Sway**: Realistic weapon movement
- **Recoil**: Camera kick when firing

### 2. Weapon System
- **Primary Weapon**: Assault Rifle (M4A1 style)
  - Damage: 25 per hit
  - Fire Rate: 600 RPM (0.1s between shots)
  - Magazine: 30 rounds
  - Reserve Ammo: 120 rounds
  - Reload Time: 2.5 seconds
  - Recoil Pattern: Vertical + horizontal spread

- **Shooting Mechanics**:
  - Raycasting for hit detection
  - Muzzle flash particle effect
  - Bullet tracer visualization
  - Impact particles on hit
  - Blood splatter on enemy hit
  - Damage numbers

### 3. Level Design - Urban Combat Zone

#### Buildings (using kenney_building-kit + kenney_modular-buildings)
```
Level Layout (100m x 100m):
┌─────────────────────────────────────┐
│  [Building A]    [Street]  [Building B] │
│                                     │
│  [Cover]  [Plaza]  [Cover]         │
│                                     │
│  [Building C]  [Alley]  [Building D]│
└─────────────────────────────────────┘
```

**Building Instances**:
- 4 Large Buildings (3-4 stories) - 20 instances each
- 8 Small Buildings (1-2 stories) - 10 instances each
- 12 Cover Objects (walls, barriers) - 5 instances each
- 1 Ground Plane (100m x 100m)

**Total Instances**: ~200 building pieces

#### Props (using kenney_prototype-kit + kenney_retro-urban-kit)
- Barriers: 30 instances
- Crates/Boxes: 40 instances
- Vehicles (cover): 10 instances
- Street lights: 20 instances
- Debris: 30 instances

**Total Props**: ~130 instances

### 4. Enemy AI System

#### Enemy Types
1. **Soldier** (using kenney_blocky-characters)
   - HP: 100
   - Damage: 15 per shot
   - Fire Rate: 1 shot/second
   - Accuracy: 60%
   - Speed: 4 m/s

2. **Elite Soldier** (different character model)
   - HP: 150
   - Damage: 20 per shot
   - Fire Rate: 1.5 shots/second
   - Accuracy: 75%
   - Speed: 5 m/s

#### AI States
```javascript
AI_IDLE      = 0  // Standing, looking around
AI_PATROL    = 1  // Walking between waypoints
AI_ALERT     = 2  // Heard gunfire, investigating
AI_COMBAT    = 3  // Engaging player
AI_COVER     = 4  // Taking cover, peeking to shoot
AI_RETREAT   = 5  // Low HP, falling back
AI_DEAD      = 6  // Ragdoll/death animation
```

#### Combat Behavior
- **Detection Range**: 50m visual, 30m audio
- **Engagement Range**: 5m - 40m
- **Cover System**: 
  - Find nearest cover within 10m
  - Peek out every 2-3 seconds to shoot
  - Suppress player with sustained fire
- **Flanking**: 20% chance to flank if player stationary
- **Grenade Throw**: Elite soldiers throw grenades (particle burst)

### 5. Player Systems

#### Movement
- **Walk Speed**: 5 m/s
- **Sprint Speed**: 8 m/s (Shift key)
- **Crouch Speed**: 2.5 m/s (Ctrl key)
- **Jump**: 3m height (Space key)
- **Stamina**: 100%, drains 10%/s when sprinting

#### Health System
- **Max HP**: 100
- **Regeneration**: Starts after 5s without damage, 10 HP/s
- **Death**: Respawn at checkpoint or game over

#### HUD Elements
```
┌─────────────────────────────────────┐
│ HP: ████████░░ 80/100               │
│ AMMO: 24/30  [120]                  │
│ ENEMIES: 12/20                      │
│                                     │
│           [+] Crosshair             │
│                                     │
│ OBJECTIVE: Eliminate all enemies    │
└─────────────────────────────────────┘
```

### 6. Gameplay Loop

#### Mission Structure
1. **Spawn**: Player starts at insertion point
2. **Objective**: Eliminate all 20 enemies
3. **Waves**: Enemies spawn in 4 waves of 5
4. **Completion**: All enemies dead = Victory
5. **Failure**: Player death = Game Over

#### Difficulty Scaling
- **Easy**: 15 enemies, 75% accuracy
- **Normal**: 20 enemies, 60% accuracy
- **Hard**: 25 enemies, 80% accuracy, faster reactions

### 7. Visual Effects

#### Particle Systems
- **Muzzle Flash**: 5 particles, 0.1s lifetime, yellow-orange
- **Bullet Tracer**: Line renderer, 0.2s fade
- **Impact Spark**: 10 particles, 0.3s lifetime, white-yellow
- **Blood Splatter**: 15 particles, 0.5s lifetime, red
- **Smoke Grenade**: 100 particles, 5s lifetime, gray
- **Explosion**: 50 particles, 1s lifetime, orange-red

#### Post-Processing
- **Bloom**: Muzzle flashes, explosions
- **Vignette**: Increases when low HP
- **Color Grading**: Desaturate when low HP
- **Motion Blur**: Subtle when sprinting

### 8. Audio System

#### Sound Effects
- **Weapon Sounds**:
  - Gunshot: 3D spatial, 50m range
  - Reload: 2D, player only
  - Empty Click: 2D, player only
  
- **Impact Sounds**:
  - Bullet Hit Metal: 3D, 20m range
  - Bullet Hit Concrete: 3D, 20m range
  - Bullet Hit Flesh: 3D, 15m range

- **Enemy Sounds**:
  - Footsteps: 3D, 10m range
  - Voice Lines: 3D, 30m range
  - Death Scream: 3D, 40m range

- **Ambient**:
  - Wind: 2D loop, low volume
  - Distant Gunfire: 2D loop, very low volume

### 9. Controls

#### Keyboard
```
W/A/S/D     - Move
Mouse       - Look
Left Click  - Shoot
Right Click - Aim Down Sights (ADS)
R           - Reload
Shift       - Sprint
Ctrl        - Crouch
Space       - Jump
E           - Interact
Tab         - Scoreboard
Esc         - Pause Menu
```

#### Mobile (Touch)
```
Left Joystick  - Move
Right Joystick - Look
Fire Button    - Shoot (bottom right)
Reload Button  - Reload (bottom left)
Sprint Button  - Sprint (top left)
Jump Button    - Jump (bottom right, above fire)
```

### 10. Implementation Plan

#### Phase 1: Core FPS Mechanics (2 hours)
1. Convert camera to first-person
2. Implement mouse look
3. Add weapon model to camera
4. Implement shooting raycast
5. Add crosshair and basic HUD

#### Phase 2: Level Design (2 hours)
1. Create urban layout with buildings
2. Place cover objects strategically
3. Add props and details
4. Set up spawn points
5. Add lighting and atmosphere

#### Phase 3: Enemy AI (3 hours)
1. Implement AI state machine
2. Add cover detection system
3. Implement shooting mechanics
4. Add pathfinding for flanking
5. Test and balance AI difficulty

#### Phase 4: Polish (2 hours)
1. Add particle effects
2. Implement audio system
3. Add post-processing
4. Create UI/HUD
5. Add game over/victory screens

### 11. Asset Usage

#### Characters (kenney_blocky-characters_20)
- Player: character-a.glb (not visible in FPS)
- Enemy Soldiers: character-b through character-r (17 variations)
- **Instancing**: 1 InstancedMesh per character type, 5 instances each

#### Buildings (kenney_building-kit + kenney_modular-buildings)
- Walls: wall.glb, wall-window.glb, wall-door.glb
- Floors: floor.glb
- Roofs: roof-flat.glb
- **Instancing**: 1 InstancedMesh per piece type, 10-20 instances

#### Props (kenney_prototype-kit)
- Crates: crate.glb, crate-color.glb
- Barriers: wall-low.glb
- Columns: column.glb
- **Instancing**: 1 InstancedMesh per prop type, 5-10 instances

#### Vehicles (kenney_car-kit)
- Cover: sedan.glb, suv.glb, truck.glb
- **Instancing**: 1 InstancedMesh per vehicle, 3-5 instances

### 12. Performance Targets

- **FPS**: 60 FPS on Snapdragon 720G+
- **Draw Calls**: < 50 (instanced rendering)
- **Entities**: ~50 active (20 enemies, 30 props)
- **Particles**: < 200 active
- **Memory**: < 100 MB GPU

### 13. Code Structure

```javascript
// ═══ FPS GAME SYSTEMS ═══

// Weapon System
var WEAPON_DAMAGE = 25;
var WEAPON_FIRERATE = 0.1;
var WEAPON_AMMO_MAG = 30;
var WEAPON_AMMO_RESERVE = 120;
var WEAPON_RELOAD_TIME = 2.5;
var weaponAmmo = 30;
var weaponReserve = 120;
var weaponReloading = false;
var weaponLastFire = 0;

function shootWeapon() {
  if(weaponReloading || weaponAmmo <= 0) return;
  if(performance.now() - weaponLastFire < WEAPON_FIRERATE * 1000) return;
  
  weaponAmmo--;
  weaponLastFire = performance.now();
  
  // Raycast from camera
  var raycaster = new THREE.Raycaster();
  raycaster.setFromCamera(new THREE.Vector2(0, 0), camera);
  
  // Check hit
  var hit = raycastEnemies(raycaster);
  if(hit >= 0){
    HP[hit] -= WEAPON_DAMAGE;
    showDamageNumber(PX[hit], PY[hit], PZ[hit], WEAPON_DAMAGE);
    emitBloodSplatter(PX[hit], PY[hit] + 1, PZ[hit]);
    if(HP[hit] <= 0) killEnemy(hit);
  }
  
  // Effects
  emitMuzzleFlash();
  playSound('gunshot.mp3', false, 1.0, true, _playerEid);
  applyRecoil();
}

// Enemy AI Combat
function enemyCombatAI(id, dt) {
  if(AI_STATE[id] !== AI_COMBAT) return;
  
  AI_TIMER[id] -= dt;
  
  // Find cover if exposed
  if(!isInCover(id) && Math.random() < 0.3){
    var cover = findNearestCover(id);
    if(cover) moveToPosition(id, cover.x, cover.z);
  }
  
  // Shoot at player
  if(AI_TIMER[id] <= 0 && hasLineOfSight(id, _playerEid)){
    shootAtPlayer(id);
    AI_TIMER[id] = 1.0 + Math.random() * 0.5;
  }
  
  // Flank if player stationary
  if(Math.random() < 0.01){
    var flankPos = getFlankPosition(_playerEid);
    if(flankPos) moveToPosition(id, flankPos.x, flankPos.z);
  }
}

// Level Generation
function generateUrbanLevel() {
  // Create buildings
  var buildingPool = loadBuildingKit();
  
  // 4 large buildings at corners
  spawnBuilding(buildingPool, -40, 0, -40, 3); // stories
  spawnBuilding(buildingPool,  40, 0, -40, 4);
  spawnBuilding(buildingPool, -40, 0,  40, 3);
  spawnBuilding(buildingPool,  40, 0,  40, 4);
  
  // Cover objects in center
  for(var i = 0; i < 20; i++){
    var x = (Math.random() - 0.5) * 60;
    var z = (Math.random() - 0.5) * 60;
    spawnCover(x, 0, z);
  }
  
  // Spawn enemies
  for(var i = 0; i < 20; i++){
    var x = (Math.random() - 0.5) * 80;
    var z = (Math.random() - 0.5) * 80;
    spawnEnemy(x, 0, z);
  }
}
```

### 14. Next Steps

To implement this FPS game:

1. **Copy viewer.html to fps-game.html**
2. **Replace camera system** with FPS camera
3. **Add weapon system** with shooting mechanics
4. **Implement enemy AI** with cover system
5. **Build urban level** using building kits
6. **Add HUD** with health, ammo, objectives
7. **Test and balance** gameplay

This design provides a complete, production-ready FPS game using the existing RAMAI Engine architecture and Kenney asset library.
