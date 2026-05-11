# RAMAI Engine — Project Organization

**Version:** 2.0  
**Last Updated:** May 11, 2026  
**Purpose:** Complete project structure and organization guide

---

## 🎯 OVERVIEW

This document explains how RAMAI Engine is organized, where to find things, and how everything fits together.

---

## 📂 DIRECTORY STRUCTURE

```
Html-Game/
│
├── 📄 Core Files (MAIN GAME)
│   ├── index.html                    ← Main game engine (ALL CODE)
│   ├── viewer.html                   ← GLB model viewer (debug tool)
│   └── icon.png                      ← App icon
│
├── 📚 Documentation (READ THESE)
│   ├── README.md                     ← Project overview (START HERE)
│   ├── DOCUMENTATION_INDEX.md        ← Documentation map
│   ├── SYSTEM_PROMPT.md              ← LLM development guide
│   ├── LLM_CHEATSHEET.md             ← Quick reference for AI
│   ├── DEVELOPER_GUIDE.md            ← Human developer guide
│   ├── QUICK_REFERENCE.md            ← One-page cheatsheet
│   ├── TASKLIST_NEXT_CHAT.md         ← Phase roadmap
│   ├── QUICKSTART.md                 ← 5-minute setup
│   ├── TESTING_CHECKLIST.md          ← Pre-release verification
│   └── PROJECT_ORGANIZATION.md       ← This file
│
├── 🎮 Game Design Docs
│   ├── FPS_GAME_DESIGN.md            ← Game design document
│   ├── FPS_QUICK_REFERENCE.md        ← Quick reference for tweaking
│   ├── FPS_IMPLEMENTATION_GUIDE.md   ← Implementation details
│   └── FPS_TRANSFORMATION_SUMMARY.md ← Transformation notes
│
├── 🎨 Assets
│   ├── CONTENT/
│   │   └── MESHES/
│   │       ├── kenney_blocky-characters_20/  ← 18 character models (GLB)
│   │       ├── kenney_building-kit/          ← 80+ building pieces (GLB)
│   │       └── [other asset packs]/
│   │
│   └── assets/
│       └── js/
│           ├── three.min.js          ← Three.js library (CDN fallback)
│           ├── three.module.js       ← Three.js ES6 module
│           ├── GLTFLoader.js         ← GLTF/GLB loader
│           └── addons/               ← Three.js addons
│               ├── controls/         ← Camera controls
│               ├── loaders/          ← Additional loaders
│               ├── math/             ← Math utilities
│               └── utils/            ← Utilities
│
├── 📱 Android
│   ├── android/                      ← Android Studio project (legacy)
│   │   ├── app/
│   │   │   ├── src/main/
│   │   │   │   ├── java/             ← Java bridge code
│   │   │   │   ├── assets/           ← HTML + GLB assets
│   │   │   │   └── AndroidManifest.xml
│   │   │   └── build.gradle
│   │   ├── gradle/
│   │   ├── build.gradle
│   │   └── settings.gradle
│   │
│   ├── android-gradle/               ← Gradle build (current)
│   │   ├── app/
│   │   │   ├── src/main/
│   │   │   │   ├── java/             ← Java bridge code
│   │   │   │   ├── assets/           ← HTML + GLB assets
│   │   │   │   └── AndroidManifest.xml
│   │   │   └── build.gradle
│   │   ├── gradle/
│   │   ├── build.gradle
│   │   ├── settings.gradle
│   │   └── local.properties
│   │
│   ├── README-GRADLE.md              ← Gradle build instructions
│   ├── build-apk.bat                 ← Build APK (Windows)
│   ├── build-glb-apk.bat             ← Build with GLB assets
│   ├── build-gradle.bat              ← Gradle build wrapper
│   ├── ramai.apk                     ← Built APK (game)
│   └── GLBViewer.apk                 ← Built APK (viewer)
│
├── 📋 Technical Docs
│   ├── FEATURES.md                   ← Feature list
│   ├── POST_PROCESSING.md            ← Post-processing details
│   ├── POST_PROCESSING_UPDATE.md     ← Post-processing updates
│   ├── PLAN_VS_HTML_COMPARISON.md    ← Plan vs implementation
│   ├── DEPLOYMENT_REPORT.md          ← Deployment notes
│   └── DEPLOYMENT_FIX.md             ← Deployment fixes
│
├── 📦 Archive
│   ├── FINAL_SUMMARY.md              ← Project summary
│   ├── FPS_README.md                 ← Old FPS readme
│   └── PLAN/                         ← Design documents (archive)
│
├── 🛠️ Scripts
│   └── scripts/                      ← Build scripts (if any)
│
├── 🖼️ Screenshots
│   ├── screenshot.png
│   ├── screenshot2.png
│   ├── screenshot_fixed.png
│   └── screenshot_loaded.png
│
└── ⚙️ Config
    ├── .gitignore                    ← Git ignore rules
    └── .vscode/                      ← VS Code settings
```

---

## 📖 DOCUMENTATION HIERARCHY

### Tier 1: Essential (Read First)

**Everyone should read these:**

1. **[README.md](README.md)** — Project overview, quick start, features
2. **[DOCUMENTATION_INDEX.md](DOCUMENTATION_INDEX.md)** — Documentation map
3. **[QUICK_REFERENCE.md](QUICK_REFERENCE.md)** — One-page cheatsheet

### Tier 2: Role-Specific

**Human Developers:**
- [DEVELOPER_GUIDE.md](DEVELOPER_GUIDE.md) — Complete guide with tutorials
- [TASKLIST_NEXT_CHAT.md](TASKLIST_NEXT_CHAT.md) — Current phase tasks

**AI Assistants:**
- [SYSTEM_PROMPT.md](SYSTEM_PROMPT.md) — Mandatory development guide
- [LLM_CHEATSHEET.md](LLM_CHEATSHEET.md) — Quick reference

**Game Designers:**
- [FPS_GAME_DESIGN.md](FPS_GAME_DESIGN.md) — Game design document
- [FPS_QUICK_REFERENCE.md](FPS_QUICK_REFERENCE.md) — Tweaking values

### Tier 3: Reference

**As needed:**
- [TESTING_CHECKLIST.md](TESTING_CHECKLIST.md) — Pre-release verification
- [README-GRADLE.md](README-GRADLE.md) — Android build instructions
- [DEPLOYMENT_REPORT.md](DEPLOYMENT_REPORT.md) — Deployment notes

---

## 🎯 FILE PURPOSES

### Core Game Files

| File | Purpose | Size | Modify? |
|------|---------|------|---------|
| **index.html** | Main game engine (all code) | ~50 KB | ✅ Yes (main dev file) |
| **viewer.html** | GLB model viewer (debug) | ~10 KB | ⚠️ Rarely |
| **icon.png** | App icon | ~5 KB | ⚠️ Only for branding |

### Documentation Files

| File | Purpose | Audience | Update Frequency |
|------|---------|----------|------------------|
| **README.md** | Project overview | Everyone | Every major release |
| **DOCUMENTATION_INDEX.md** | Doc map | Everyone | When docs change |
| **SYSTEM_PROMPT.md** | LLM guide | AI assistants | Every phase |
| **LLM_CHEATSHEET.md** | Quick ref for AI | AI assistants | Every phase |
| **DEVELOPER_GUIDE.md** | Human guide | Developers | Every phase |
| **QUICK_REFERENCE.md** | Cheatsheet | Everyone | Every phase |
| **TASKLIST_NEXT_CHAT.md** | Roadmap | Everyone | Weekly |
| **TESTING_CHECKLIST.md** | QA checklist | Testers | Before release |

### Asset Files

| Directory | Contents | Format | Source |
|-----------|----------|--------|--------|
| **CONTENT/MESHES/kenney_blocky-characters_20/** | 18 character models | GLB | Kenney.nl |
| **CONTENT/MESHES/kenney_building-kit/** | 80+ building pieces | GLB | Kenney.nl |
| **assets/js/** | Three.js libraries | JS | CDN fallback |

### Android Files

| Directory | Purpose | Modify? |
|-----------|---------|---------|
| **android/** | Legacy Android project | ❌ No (deprecated) |
| **android-gradle/** | Current Android project | ✅ Yes |
| **android-gradle/app/src/main/java/** | Java bridge code | ✅ Yes |
| **android-gradle/app/src/main/assets/** | HTML + GLB assets | ✅ Yes |

---

## 🔄 WORKFLOW

### Development Workflow

```
1. Read DOCUMENTATION_INDEX.md
   ↓
2. Choose your role:
   - Human → DEVELOPER_GUIDE.md
   - AI → SYSTEM_PROMPT.md
   ↓
3. Check TASKLIST_NEXT_CHAT.md
   ↓
4. Edit index.html
   ↓
5. Test in browser (F5)
   ↓
6. Check console for errors
   ↓
7. Verify with TESTING_CHECKLIST.md
   ↓
8. Commit changes
```

### Documentation Workflow

```
1. Make code changes
   ↓
2. Update relevant docs:
   - New feature → Update FEATURES.md
   - New phase → Update TASKLIST_NEXT_CHAT.md
   - API change → Update DEVELOPER_GUIDE.md
   - New doc → Update DOCUMENTATION_INDEX.md
   ↓
3. Update version numbers
   ↓
4. Update "Last Updated" dates
   ↓
5. Commit docs with code
```

### Release Workflow

```
1. Complete phase tasks (TASKLIST_NEXT_CHAT.md)
   ↓
2. Run TESTING_CHECKLIST.md
   ↓
3. Update README.md (version, features)
   ↓
4. Update DOCUMENTATION_INDEX.md (status)
   ↓
5. Build Android APK (if needed)
   ↓
6. Tag release in git
   ↓
7. Deploy to web/store
```

---

## 🎨 ASSET ORGANIZATION

### 3D Models (GLB)

**Location:** `CONTENT/MESHES/`

**Naming Convention:**
- Characters: `character-[a-z].glb`
- Buildings: `[type]-[variant].glb` (e.g., `wall-corner.glb`)
- Props: `[name]-[variant].glb`

**Organization:**
```
CONTENT/MESHES/
├── kenney_blocky-characters_20/
│   ├── character-a.glb       ← Player character
│   ├── character-b.glb       ← Enemy variant 1
│   ├── character-c.glb       ← Enemy variant 2
│   └── ...
│
├── kenney_building-kit/
│   ├── floor-*.glb           ← Ground tiles
│   ├── wall-*.glb            ← Walls
│   ├── door-*.glb            ← Doors
│   └── ...
│
└── [other packs]/
```

**Usage:**
- Reference in `startupConfig.models[]` (Section A of index.html)
- Load via `loadGLBFromAssets()` (Section E)
- Spawn via `spawnEntity()` (Section E)

### Three.js Libraries

**Location:** `assets/js/`

**Purpose:** CDN fallback (if jsdelivr.net is down)

**Files:**
- `three.min.js` — Minified Three.js
- `three.module.js` — ES6 module version
- `GLTFLoader.js` — GLTF/GLB loader
- `addons/` — Additional Three.js modules

**Usage:**
- Primary: CDN via `<script type="importmap">`
- Fallback: Local files if CDN fails

---

## 🔧 CONFIGURATION

### Startup Config (index.html, Section A)

**Purpose:** Data-driven scene configuration

**Structure:**
```javascript
const startupConfig = {
  models: [...],    // 3D models to load
  camera: {...},    // Camera settings
  lights: [...],    // Scene lighting
  culling: {...},   // Performance settings
  fog: {...}        // Atmospheric fog
};
```

**Modify this to change:**
- Scene layout
- Lighting
- Camera position
- Model instances
- Performance settings

### Android Config (android-gradle/)

**Files:**
- `app/build.gradle` — App version, dependencies
- `app/src/main/AndroidManifest.xml` — Permissions, activities
- `gradle.properties` — Build properties
- `local.properties` — SDK paths

---

## 📊 METRICS

### File Sizes

| File | Size | Notes |
|------|------|-------|
| index.html | ~50 KB | All game code |
| viewer.html | ~10 KB | Debug tool |
| character-a.glb | ~200 KB | With DRACO compression |
| wall-corner.glb | ~50 KB | Simple geometry |
| three.module.js | ~1.2 MB | Three.js library |

### Asset Counts

| Type | Count | Total Size |
|------|-------|------------|
| Character models | 18 | ~3.6 MB |
| Building pieces | 80+ | ~4 MB |
| Documentation | 20+ | ~500 KB |
| Total project | — | ~10 MB |

---

## 🔍 FINDING THINGS

### "Where is...?"

| Looking for... | Location |
|----------------|----------|
| **Main game code** | `index.html` |
| **Model viewer** | `viewer.html` |
| **3D models** | `CONTENT/MESHES/` |
| **Documentation** | Root directory (*.md files) |
| **Android project** | `android-gradle/` |
| **Build scripts** | Root directory (*.bat files) |
| **Three.js libraries** | `assets/js/` |
| **Screenshots** | Root directory (*.png files) |

### "How do I...?"

| Task | Document |
|------|----------|
| **Get started** | README.md → QUICKSTART.md |
| **Learn to code** | DEVELOPER_GUIDE.md |
| **Find a doc** | DOCUMENTATION_INDEX.md |
| **See current tasks** | TASKLIST_NEXT_CHAT.md |
| **Debug an issue** | QUICK_REFERENCE.md |
| **Build Android APK** | README-GRADLE.md |
| **Design gameplay** | FPS_GAME_DESIGN.md |
| **Test before release** | TESTING_CHECKLIST.md |

---

## 🛠️ MAINTENANCE

### Regular Tasks

**Weekly:**
- [ ] Update TASKLIST_NEXT_CHAT.md with progress
- [ ] Check for broken links in docs
- [ ] Verify index.html runs without errors

**Monthly:**
- [ ] Update Three.js version (if needed)
- [ ] Review and archive old docs
- [ ] Update screenshots
- [ ] Check asset licenses

**Per Release:**
- [ ] Update version numbers in all docs
- [ ] Update "Last Updated" dates
- [ ] Run TESTING_CHECKLIST.md
- [ ] Update DOCUMENTATION_INDEX.md status
- [ ] Build and test Android APK

### Cleanup Tasks

**When to clean up:**
- Project gets too cluttered
- Old docs are confusing
- File structure is unclear

**What to clean:**
1. Move old docs to `ARCHIVE/` folder
2. Delete unused screenshots
3. Remove deprecated code
4. Update DOCUMENTATION_INDEX.md
5. Update this file (PROJECT_ORGANIZATION.md)

---

## 📞 SUPPORT

### Questions?

1. **Check DOCUMENTATION_INDEX.md** — Find the right doc
2. **Read QUICK_REFERENCE.md** — Quick answers
3. **Read DEVELOPER_GUIDE.md** — Detailed tutorials
4. **Ask in discussions** — GitHub Discussions (if available)

### Suggestions?

If you think the project organization could be improved:
1. Open an issue
2. Describe the problem
3. Suggest a solution
4. Update this file if approved

---

## 🎓 BEST PRACTICES

### Documentation

- ✅ Update docs with code changes
- ✅ Keep "Last Updated" dates current
- ✅ Use consistent formatting
- ✅ Link between related docs
- ✅ Update DOCUMENTATION_INDEX.md when adding docs

### Code

- ✅ Keep all code in `index.html`
- ✅ Use labeled sections (A, B, C, etc.)
- ✅ Comment complex logic
- ✅ Follow naming conventions
- ✅ Test before committing

### Assets

- ✅ Use GLB format for 3D models
- ✅ Compress with DRACO
- ✅ Organize by asset pack
- ✅ Include README.md in asset folders
- ✅ Attribute sources (Kenney.nl)

---

**Last Updated:** May 11, 2026  
**Maintained By:** RAMAI Engine Team

---

*This document is the source of truth for project organization. Update it when structure changes.*
