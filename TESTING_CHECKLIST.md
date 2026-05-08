# RAMAI Engine — Testing Checklist

**Use this checklist to verify all systems are working correctly.**

---

## ✅ Basic Functionality

### File Loading
- [ ] Open `viewer.html` in browser
- [ ] Page loads without errors (check console F12)
- [ ] Model loads automatically (2000 instances)
- [ ] Grid and ground plane visible
- [ ] HUD shows stats (top-right)

### UI Buttons
- [ ] LOAD button works (reloads model)
- [ ] SPAWN button works (spawns 2000 instances)
- [ ] ECS button toggles (OFF → ON)
- [ ] SHADOW button toggles (ON → OFF → ON)
- [ ] EDITOR button toggles (OFF → ON → OFF)
- [ ] AUDIO button initializes (OFF → ON)
- [ ] SAVE button saves (shows "Game saved!" message)
- [ ] CLEAR button clears (removes all instances)

---

## ✅ ECS Mode (Gameplay)

### Activation
- [ ] Click "ECS: OFF" button
- [ ] Button changes to "ECS: ON"
- [ ] Health bar appears (bottom-left)
- [ ] Crosshair appears (center)
- [ ] ECS debug panel appears (top-left)
- [ ] First entity becomes player (you control it)

### Player Movement
- [ ] Press W — Player moves forward
- [ ] Press S — Player moves backward
- [ ] Press A — Player moves left
- [ ] Press D — Player moves right
- [ ] Arrow keys work (same as WASD)
- [ ] Player rotates to face movement direction
- [ ] Camera follows player smoothly

### Player Jump
- [ ] Press Space — Player jumps
- [ ] Player rises ~2-3 units
- [ ] Player falls back to ground
- [ ] Can't jump while in air (ground check works)

### Mobile Controls (Touch)
- [ ] Touch left side — Virtual joystick appears
- [ ] Drag joystick — Player moves
- [ ] Release joystick — Player stops
- [ ] Touch right side — Camera orbits
- [ ] Pinch — Camera zooms

---

## ✅ Physics System

### Gravity
- [ ] Player falls when jumping
- [ ] Player stops at Y=0 (ground)
- [ ] Enemies fall to ground on spawn

### Friction
- [ ] Player slows down when not moving
- [ ] Player doesn't slide forever

### Ground Clamp
- [ ] Entities don't fall through ground
- [ ] Y position never goes below 0

---

## ✅ AI System

### Enemy Behavior
- [ ] Enemies start in IDLE state
- [ ] Enemies PATROL randomly
- [ ] Enemies CHASE when player gets close (~20m)
- [ ] Enemies ATTACK when very close (~2.5m)
- [ ] Enemies rotate to face player when chasing

### Combat
- [ ] Player takes damage when attacked (HP decreases)
- [ ] Damage numbers appear (red "-10" text)
- [ ] Damage numbers float up and fade out
- [ ] Health bar updates in real-time
- [ ] Health bar color changes (green → yellow → red)

---

## ✅ Collision System

### Collision Detection
- [ ] Run into enemy — You bounce off
- [ ] Run into multiple enemies — All bounce
- [ ] Enemies collide with each other
- [ ] Static entities don't move on collision

### Collision Response
- [ ] Entities separate on collision
- [ ] Entities bounce slightly (restitution)
- [ ] No entities stuck inside each other

### Spatial Hash
- [ ] 2000 entities run at 60 FPS
- [ ] No lag when many entities collide
- [ ] HUD shows ~1000 collision checks/frame

---

## ✅ Particle System

### Spawning
- [ ] Press P — Particles spawn at player
- [ ] 15 particles spawn in burst
- [ ] Particles are orange cubes
- [ ] Particles spread in all directions

### Physics
- [ ] Particles fall with gravity
- [ ] Particles have velocity
- [ ] Particles bounce on ground (optional)

### Lifetime
- [ ] Particles fade out over ~1.2 seconds
- [ ] Particles shrink as they fade
- [ ] Particles disappear when dead
- [ ] PART counter in HUD updates

### Editor Mode
- [ ] Press E to enter editor
- [ ] Press G — Particles spawn at selected entity
- [ ] Particles work same as player spawn

---

## ✅ Audio System

### Initialization
- [ ] Click "AUDIO: OFF" button
- [ ] Button changes to "AUDIO: ON"
- [ ] Console shows "Audio initialized"
- [ ] No errors in console

### Spatial Audio (Future)
- [ ] Sounds play (when implemented)
- [ ] Sounds pan left/right based on position
- [ ] Sounds get quieter with distance
- [ ] SND counter in HUD updates

---

## ✅ Animation System

### Integration
- [ ] AnimationMixer created for entities
- [ ] playAnimation() function exists
- [ ] stopAnimation() function exists
- [ ] No errors when calling functions

### Playback (Future)
- [ ] Animations play (when GLB has animations)
- [ ] Animations loop correctly
- [ ] Animation speed adjustable

---

## ✅ LOD System

### Distance Tracking
- [ ] LOD_LEVEL array populated
- [ ] Entities have LOD level (0/1/2)
- [ ] LOD level changes with distance
- [ ] No performance impact

### Thresholds
- [ ] LOD 0 (High) — < 20m from camera
- [ ] LOD 1 (Med) — 20-50m from camera
- [ ] LOD 2 (Low) — > 50m from camera

---

## ✅ Canvas UI

### Health Bar
- [ ] Appears at bottom-left
- [ ] Shows current HP / max HP
- [ ] Color changes with HP (green/yellow/red)
- [ ] Updates in real-time
- [ ] Text is readable

### Damage Numbers
- [ ] Appear when player takes damage
- [ ] Show "-10" in red/yellow
- [ ] Float upward
- [ ] Fade out over 1.5 seconds
- [ ] Multiple numbers don't overlap (much)

### Crosshair
- [ ] Appears in center (ECS mode only)
- [ ] White cross, 20px size
- [ ] Visible against background
- [ ] Disappears in viewer mode

### Editor Overlay
- [ ] Cyan circle around selected entity
- [ ] Entity info displayed (ID, type, HP)
- [ ] Help text at top-left
- [ ] Updates when selection changes

---

## ✅ Scene Editor

### Toggle
- [ ] Press E — Editor mode activates
- [ ] Button changes to "EDITOR: ON"
- [ ] Help text appears (top-left)
- [ ] ECS mode pauses (gameplay stops)

### Shortcuts
- [ ] Press E again — Editor mode deactivates
- [ ] Press Delete — Selected entity removed
- [ ] Press G — Particles spawn at entity
- [ ] All shortcuts work as expected

### Save/Load
- [ ] Save scene — JSON file downloads
- [ ] JSON contains entity data
- [ ] Load scene — Entities restored (future)

---

## ✅ Save/Load System

### Save
- [ ] Click SAVE button
- [ ] "Game saved!" message appears
- [ ] Message disappears after 1.5s
- [ ] localStorage contains save data
- [ ] Check: Open DevTools → Application → localStorage

### Load (Future)
- [ ] Refresh page
- [ ] Click LOAD button (future)
- [ ] Entities restored from save
- [ ] Player position restored

### Data
- [ ] Save includes player state
- [ ] Save includes entity positions
- [ ] Save includes HP values
- [ ] Save includes AI states

---

## ✅ Performance

### FPS
- [ ] HUD shows FPS (top-right)
- [ ] FPS is 60 (green) or close
- [ ] FPS doesn't drop below 30
- [ ] FPS counter updates every ~0.25s

### Draw Calls
- [ ] HUD shows DRAW count
- [ ] DRAW is 1-5 (instanced rendering)
- [ ] DRAW doesn't increase with entity count

### Memory
- [ ] HUD shows MEM (JS heap)
- [ ] MEM is stable (no leaks)
- [ ] MEM doesn't grow over time

### Quality
- [ ] HUD shows QUAL (LOW/MED/HIGH)
- [ ] Quality auto-adjusts based on FPS
- [ ] Quality badge shows current tier

---

## ✅ Adaptive Quality

### Auto-Switching
- [ ] Starts at HIGH quality
- [ ] Drops to MED if FPS < 25
- [ ] Drops to LOW if FPS < 25 again
- [ ] Rises to MED if FPS > 55
- [ ] Rises to HIGH if FPS > 55 again

### Visual Changes
- [ ] LOW — Pixelated (0.75 pixel ratio)
- [ ] MED — Normal (1.0 pixel ratio)
- [ ] HIGH — Sharp (2.0 pixel ratio)
- [ ] Shadow quality changes (512/1024/2048)

---

## ✅ HUD Stats

### Top-Right Panel
- [ ] FPS — Updates, color-coded
- [ ] MS — Frame time in milliseconds
- [ ] DRAW — Draw calls per frame
- [ ] TRIS — Triangles (in thousands)
- [ ] INST — Total instances
- [ ] ENT — Alive entities
- [ ] PART — Active particles
- [ ] SND — Active sounds
- [ ] MEM — JS heap size
- [ ] QUAL — Quality tier
- [ ] STEP — Physics steps per frame

### ECS Debug Panel (Top-Left)
- [ ] Alive — Total alive entities
- [ ] Player — Player ID + HP
- [ ] Enemy — Enemy count
- [ ] Static — Static entity count
- [ ] Dirty — Entities with dirty transforms
- [ ] Steps — Physics steps last frame

---

## ✅ Model Loading

### Dropdown
- [ ] Select "Character A" — Loads
- [ ] Select "Character B" — Loads
- [ ] Select "Sedan" — Loads
- [ ] Select "Race Car" — Loads
- [ ] Select "Building A" — Loads
- [ ] All models load without errors

### Instance Count
- [ ] 2000 instances spawn
- [ ] Instances arranged in grid
- [ ] Instances have random rotation
- [ ] Instances have random scale

---

## ✅ Rendering

### Shadows
- [ ] Shadows visible on ground
- [ ] Shadows follow entities
- [ ] Shadows soft (PCF)
- [ ] Toggle button works

### Fog
- [ ] Distant entities fade
- [ ] Fog color matches sky
- [ ] Fog density adjusts with quality

### Materials
- [ ] PBR materials (roughness, metalness)
- [ ] Textures load (if present)
- [ ] Colors correct

---

## ✅ Browser Compatibility

### Desktop
- [ ] Chrome — Works
- [ ] Firefox — Works
- [ ] Edge — Works
- [ ] Safari — Works

### Mobile
- [ ] Chrome Android — Works
- [ ] Safari iOS — Works
- [ ] 60 FPS on mid-range device

---

## ✅ Error Handling

### Console
- [ ] No errors on load
- [ ] No errors during gameplay
- [ ] No errors when spawning particles
- [ ] No errors when toggling editor

### Graceful Degradation
- [ ] Audio fails gracefully (if not supported)
- [ ] Post-processing disabled (if not available)
- [ ] Textures fallback to colors (if missing)

---

## 🎯 Final Checklist

### Core Functionality
- [ ] All 13 systems present
- [ ] All systems callable
- [ ] No JavaScript errors
- [ ] 60 FPS with 2000 entities

### Gameplay
- [ ] Player movement works
- [ ] Enemies chase and attack
- [ ] Collision detection works
- [ ] Particles spawn and fade

### UI
- [ ] All buttons work
- [ ] HUD updates correctly
- [ ] Canvas UI renders
- [ ] Editor mode works

### Performance
- [ ] 60 FPS stable
- [ ] No memory leaks
- [ ] Adaptive quality works
- [ ] Spatial hash optimizes collision

---

## 🎉 Success Criteria

**All checkboxes checked?** → ✅ **ENGINE IS PRODUCTION READY!**

**Some checkboxes unchecked?** → Check console for errors, verify file paths

**Major issues?** → Open browser DevTools (F12), check console for errors

---

## 🚀 Next Steps

Once all tests pass:
1. **Ship it!** — Engine is production-ready
2. **Build your game** — Modify `viewer.html`
3. **Deploy** — Browser, Android APK, Desktop
4. **Share** — Show the world what you built!

---

**Happy Testing!** 🎮
