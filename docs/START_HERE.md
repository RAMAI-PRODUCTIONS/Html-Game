# 🚀 START HERE — RAMAI Engine

**Welcome to RAMAI Engine!** This is your entry point to the project.

---

## ⚡ 30-Second Quick Start

```bash
1. Open index.html in your browser
2. Press WASD to move, mouse to orbit
3. Check console (F12) for logs
```

**That's it!** No installation, no build tools, no configuration.

---

## 📖 I Want To...

### Learn About the Project
👉 **[README.md](README.md)** — Project overview, features, architecture

### Start Coding (Human Developer)
👉 **[DEVELOPER_GUIDE.md](DEVELOPER_GUIDE.md)** — Complete guide with tutorials  
👉 **[QUICK_REFERENCE.md](QUICK_REFERENCE.md)** — One-page cheatsheet (keep open!)

### Start Coding (AI Assistant)
👉 **[SYSTEM_PROMPT.md](SYSTEM_PROMPT.md)** — Mandatory development guide  
👉 **[LLM_CHEATSHEET.md](LLM_CHEATSHEET.md)** — Quick reference for AI

### Find Documentation
👉 **[DOCUMENTATION_INDEX.md](DOCUMENTATION_INDEX.md)** — Complete documentation map

### See Current Tasks
👉 **[TASKLIST_NEXT_CHAT.md](TASKLIST_NEXT_CHAT.md)** — Phase roadmap, next steps

### Understand Project Structure
👉 **[PROJECT_ORGANIZATION.md](PROJECT_ORGANIZATION.md)** — File structure, organization

### Design Gameplay
👉 **[FPS_GAME_DESIGN.md](FPS_GAME_DESIGN.md)** — Game design document

### Build Android APK
👉 **[README-GRADLE.md](README-GRADLE.md)** — Android build instructions

### Test Before Release
👉 **[TESTING_CHECKLIST.md](TESTING_CHECKLIST.md)** — Pre-release verification

---

## 🎯 Recommended Reading Order

### Day 1: Overview (20 minutes)
1. **[README.md](README.md)** — 10 min
2. **[QUICK_REFERENCE.md](QUICK_REFERENCE.md)** — 5 min
3. Open `index.html` in browser — 5 min

### Day 2: Deep Dive (90 minutes)
1. **[DEVELOPER_GUIDE.md](DEVELOPER_GUIDE.md)** — 30 min
2. **[DOCUMENTATION_INDEX.md](DOCUMENTATION_INDEX.md)** — 10 min
3. Read `index.html` source code — 50 min

### Day 3: Current Work (30 minutes)
1. **[TASKLIST_NEXT_CHAT.md](TASKLIST_NEXT_CHAT.md)** — 15 min
2. **[PROJECT_ORGANIZATION.md](PROJECT_ORGANIZATION.md)** — 10 min
3. Start coding! — ∞

---

## 📚 Documentation Map

```
START_HERE.md (you are here)
    ↓
README.md ← Project overview
    ↓
┌───────────────┬───────────────┬───────────────┐
│               │               │               │
DEVELOPER_GUIDE SYSTEM_PROMPT   DOCUMENTATION_  
(humans)        (AI)            INDEX (map)
│               │               │
↓               ↓               ↓
QUICK_REFERENCE LLM_CHEATSHEET  PROJECT_
(cheatsheet)    (AI ref)        ORGANIZATION
│               │               │
↓               ↓               ↓
TASKLIST_NEXT_  TASKLIST_NEXT_  TESTING_
CHAT (roadmap)  CHAT (roadmap)  CHECKLIST
```

---

## 🎮 What is RAMAI?

**RAMAI Engine** is a high-performance, single-file HTML5 3D game engine built with Three.js.

**Key Features:**
- ✅ **Zero build tools** — no webpack, no bundlers, no npm
- ✅ **60–120 FPS** — GPU instancing, spatial hashing
- ✅ **Full ECS** — flat typed-array entity system
- ✅ **Complete physics** — gravity, collision, raycast
- ✅ **AI system** — FSM-based (IDLE → PATROL → CHASE → ATTACK)
- ✅ **Animation** — GLB clip playback, crossfade blending
- ✅ **Android ready** — WebView bridge, asset loader

**Current Phase:** Phase 2 (Animation System) — In Progress

---

## 🛠️ Tech Stack

- **Three.js 0.158.0** — 3D graphics
- **Vanilla JavaScript** — No frameworks
- **HTML5 Canvas** — Rendering
- **Web Audio API** — Sound (Phase 3)
- **Android WebView** — Mobile deployment

---

## 📁 Project Structure

```
Html-Game/
├── index.html              ← Main game (ALL CODE)
├── viewer.html             ← GLB viewer (debug)
├── CONTENT/MESHES/         ← 3D models (GLB)
├── assets/js/              ← Three.js libraries
├── android-gradle/         ← Android project
└── [20+ documentation files]
```

---

## 🎯 Current Status

| Phase | System | Status |
|-------|--------|--------|
| 0 | ECS + Physics + AI + Input + Rendering | ✅ Done |
| 1 | Collision Detection | ✅ Done |
| **2** | **Animation System** | 🔄 **In Progress** |
| 3 | Audio System | ⬜ Not started |
| 4 | Post-Processing + LOD | ⬜ Not started |
| 5 | UI (minimap, damage numbers) | ⬜ Not started |
| 6 | Scene Editor | ⬜ Not started |
| 7 | Polish + Store Release | ⬜ Not started |

**Next Task:** Wire GLB animations to entities on spawn

---

## 🚀 Quick Commands

### Browser
```bash
# Open game
start index.html  (Windows)
open index.html   (macOS)

# Open viewer
start viewer.html
```

### Console (F12)
```javascript
// Entity count
Object.keys(animMixers).length

// Entity position
positions.slice(eid*3, eid*3+3)

// Query entities
window.getInstancesByTag('team_red')
```

### Android
```bash
cd android-gradle
./gradlew assembleRelease
```

---

## 🎮 Controls

| Input | Action |
|-------|--------|
| **WASD** | Move player |
| **Mouse drag** | Orbit camera |
| **Scroll** | Zoom |
| **Spacebar** | Jump |
| **P** | Spawn particles |

---

## 📞 Need Help?

1. **Check [DOCUMENTATION_INDEX.md](DOCUMENTATION_INDEX.md)** — Find the right doc
2. **Read [QUICK_REFERENCE.md](QUICK_REFERENCE.md)** — Quick answers
3. **Read [DEVELOPER_GUIDE.md](DEVELOPER_GUIDE.md)** — Detailed tutorials
4. **Check console** — Look for `✗` errors

---

## 🎓 Learning Path

### Beginner
1. Read README.md
2. Open index.html in browser
3. Experiment with controls
4. Read QUICK_REFERENCE.md

### Intermediate
1. Read DEVELOPER_GUIDE.md
2. Read index.html source code
3. Make small changes
4. Check TASKLIST_NEXT_CHAT.md

### Advanced
1. Read SYSTEM_PROMPT.md
2. Understand ECS architecture
3. Implement new features
4. Contribute to project

---

## 🔗 Essential Links

- **Main Game:** [index.html](index.html)
- **Model Viewer:** [viewer.html](viewer.html)
- **Documentation Map:** [DOCUMENTATION_INDEX.md](DOCUMENTATION_INDEX.md)
- **Developer Guide:** [DEVELOPER_GUIDE.md](DEVELOPER_GUIDE.md)
- **Quick Reference:** [QUICK_REFERENCE.md](QUICK_REFERENCE.md)
- **Current Tasks:** [TASKLIST_NEXT_CHAT.md](TASKLIST_NEXT_CHAT.md)

---

## ✨ Ready to Start?

### For Humans:
1. Read **[README.md](README.md)** (10 min)
2. Read **[DEVELOPER_GUIDE.md](DEVELOPER_GUIDE.md)** (30 min)
3. Open `index.html` and start coding!

### For AI:
1. Read **[SYSTEM_PROMPT.md](SYSTEM_PROMPT.md)** (mandatory)
2. Read **[LLM_CHEATSHEET.md](LLM_CHEATSHEET.md)** (quick ref)
3. Read **[TASKLIST_NEXT_CHAT.md](TASKLIST_NEXT_CHAT.md)** (current phase)
4. Start implementing!

---

**Welcome aboard! Let's build something amazing! 🎮**

---

*Last Updated: May 11, 2026*
