# RAMAI Engine — Quick Start Guide

**Get started in 5 minutes!** 🚀

---

## 🎮 Step 1: Open the Engine

1. **Open `viewer.html` in your browser**
   - Chrome, Firefox, Edge, Safari all supported
   - Works from `file://` — no server needed!

2. **Wait for auto-load**
   - Engine loads first model automatically
   - 2000 instances spawn in grid pattern

---

## 🕹️ Step 2: Enable Gameplay

1. **Click "ECS: OFF" button** → Changes to "ECS: ON"
   - Enables gameplay mode
   - First entity becomes player (you!)
   - Rest become AI enemies

2. **Controls appear:**
   - Health bar (bottom-left)
   - Crosshair (center)
   - HUD stats (top-right)

---

## 🎯 Step 3: Play!

### Movement
- **WASD** or **Arrow Keys** — Move player
- **Space** — Jump
- **P** — Spawn particle burst

### Mobile
- **Left side** — Virtual joystick (move)
- **Right side** — Camera orbit (look)

### Watch Out!
- Enemies will **chase** you when you get close (20m range)
- They **attack** when very close (2.5m range)
- You take **10 damage** per hit
- Red damage numbers appear when hit

---

## 🎨 Step 4: Try Different Models

1. **Click dropdown** (top-left)
2. **Select a model:**
   - Characters (A-N)
   - Vehicles (Sedan, Race Car, Police, etc.)
   - Buildings (Skyscraper, etc.)
3. **Click "LOAD"**
4. **Watch 2000 instances spawn!**

---

## ✨ Step 5: Test Features

### Particles
- **Press P** — Spawn orange particle burst
- Watch them fall with gravity
- They fade out over 1.2 seconds

### Collision
- **Run into enemies** — You bounce off!
- **Jump on them** — Physics response
- Spatial hash grid keeps it fast

### Editor Mode
- **Press E** — Toggle editor
- **Press G** — Spawn particles at entity
- **Press Delete** — Remove entity
- **Press E again** — Exit editor

### Audio (Future)
- **Click "AUDIO: OFF"** — Initialize Web Audio
- Requires user gesture (browser security)
- Spatial audio follows entities

### Save/Load
- **Click "SAVE"** — Save to localStorage
- Refresh page
- **Click "LOAD"** — Restore state (future)

---

## 📊 Step 6: Monitor Performance

### HUD (Top-Right)
- **FPS** — Should be 60 (green)
- **MS** — Should be ~16ms
- **DRAW** — Should be 1-5 calls
- **TRIS** — Triangles rendered
- **ENT** — Alive entities
- **PART** — Active particles
- **SND** — Active sounds

### Quality
- **Auto-adjusts** based on FPS
- **LOW** — < 25 FPS
- **MED** — 25-55 FPS
- **HIGH** — > 55 FPS

---

## 🎮 Gameplay Tips

### Survival
1. **Keep moving** — Enemies are slower than you
2. **Jump away** — Escape when surrounded
3. **Use particles** — Visual distraction (press P)
4. **Watch health bar** — Green = safe, Red = danger

### Performance
1. **Reduce instances** — Edit code: change 2000 → 500
2. **Disable shadows** — Click "SHADOW: ON" → OFF
3. **Lower quality** — Happens automatically

### Fun Experiments
1. **Spawn 5000 entities** — Edit code, test limits
2. **Change gravity** — Edit `GRAVITY = -20.0`
3. **Faster enemies** — Edit `CHASE_SPEED = 5.0`
4. **More damage** — Edit `HP[pid] -= 10`

---

## 🛠️ Step 7: Customize

### Easy Tweaks (No Coding)
1. **Model selection** — Try all 2000+ models
2. **Instance count** — Line 1050: `loadAndSpawn(..., 2000)`
3. **Shadow toggle** — Click button
4. **Quality tier** — Auto or manual

### Code Tweaks (Basic)
```javascript
// Line ~240: Physics constants
var GRAVITY = -20.0;        // Change gravity
var PLAYER_SPEED = 8.0;     // Change player speed

// Line ~280: AI constants
var CHASE_RANGE = 20.0;     // Change chase distance
var ATTACK_RANGE = 2.5;     // Change attack distance
var CHASE_SPEED = 5.0;      // Change enemy speed

// Line ~1050: Spawn count
loadAndSpawn(..., 2000);    // Change instance count
```

### Advanced Tweaks
- Add new entity types (T_PICKUP, T_PROJECTILE)
- Add new AI states (AI_FLEE, AI_WANDER)
- Add new systems (inventory, quests)
- Add new input (gamepad, VR)

---

## 🚀 Step 8: Build Your Game!

### Game Ideas
1. **Survival** — Waves of enemies, health pickups
2. **Racing** — Use vehicle models, lap timer
3. **Exploration** — Large world, collectibles
4. **Puzzle** — Physics-based challenges
5. **Strategy** — Top-down, unit control

### Next Steps
1. **Read `FEATURES.md`** — Full feature list
2. **Read `SYSTEM_ARCHITECTURE.md`** — How it works
3. **Read `IMPLEMENTATION_GUIDE.md`** — Add features
4. **Edit `viewer.html`** — Make it yours!

---

## 🎯 Common Issues

### "Nothing loads"
- Check browser console (F12)
- Ensure `assets/` folder exists
- Ensure `CONTENT/MESHES/` folder exists

### "Low FPS"
- Reduce instance count (2000 → 500)
- Disable shadows (click button)
- Close other browser tabs

### "Controls don't work"
- Click "ECS: OFF" to enable gameplay
- Ensure page has focus (click canvas)
- Check keyboard layout (QWERTY)

### "Audio doesn't work"
- Click "AUDIO: OFF" button first
- Browser requires user gesture
- Check browser console for errors

---

## 📚 Resources

### Documentation
- `FEATURES.md` — Complete feature list
- `SYSTEM_ARCHITECTURE.md` — Architecture diagrams
- `IMPLEMENTATION_GUIDE.md` — Add new features
- `00_OVERVIEW.md` — Project overview

### Code Sections
- **Section A** — Constants (line ~200)
- **Section B** — ECS Core (line ~250)
- **Section C** — Systems (line ~300)
- **Section D** — Renderer (line ~700)
- **Section E** — Assets (line ~800)
- **Section F** — Init (line ~1000)
- **Section G** — Game Loop (line ~1200)
- **Section H** — Input (line ~1400)

---

## 🎉 You're Ready!

The RAMAI Engine is now running on your machine. Time to build something amazing! 🚀

**Questions?** Check the docs or read the code — it's all in one file!

**Have fun!** 🎮
