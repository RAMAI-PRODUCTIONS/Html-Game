# 📂 RAMAI Engine - Project Structure Guide

**Clean, organized, and professional project layout**

---

## 🎯 Overview

This document describes the complete project structure of the RAMAI Engine. The project follows a clean root directory approach with all files organized into logical subdirectories.

---

## 📁 Root Directory (Clean & Minimal)

```
Html-Game/
├── README.md                 ← Main project documentation
├── index.html                ← Main game engine
├── viewer.html               ← GLB model viewer
├── icon.png                  ← App icon
└── .gitignore                ← Git ignore rules
```

**Philosophy:** Only essential files at root level. Everything else is organized into subdirectories.

---

## 📚 Documentation (`docs/`)

**25+ documentation files organized by purpose**

```
docs/
├── README.md                          ← Documentation index (start here!)
│
├── Getting Started (4 files)
│   ├── START_HERE.md                  ← Absolute beginner's guide
│   ├── QUICKSTART.md                  ← 5-minute setup
│   ├── QUICK_REFERENCE.md             ← One-page cheatsheet
│   └── DEVELOPER_GUIDE.md             ← Complete developer guide
│
├── Development (6 files)
│   ├── SYSTEM_PROMPT.md               ← LLM development guide
│   ├── LLM_CHEATSHEET.md              ← AI assistant guide
│   ├── TASKLIST_NEXT_CHAT.md          ← Phase-by-phase roadmap
│   ├── TESTING_CHECKLIST.md           ← Pre-release verification
│   ├── FEATURES.md                    ← Feature list
│   └── PROJECT_ORGANIZATION.md        ← Project structure
│
├── Game Design (4 files)
│   ├── FPS_GAME_DESIGN.md             ← Game design document
│   ├── FPS_QUICK_REFERENCE.md         ← Quick reference
│   ├── FPS_IMPLEMENTATION_GUIDE.md    ← Implementation details
│   └── FPS_README.md                  ← FPS-specific README
│
├── Android/Deployment (3 files)
│   ├── README-GRADLE.md               ← Gradle build instructions
│   ├── DEPLOYMENT_REPORT.md           ← Deployment status
│   └── DEPLOYMENT_FIX.md              ← Troubleshooting
│
├── Graphics/Rendering (2 files)
│   ├── POST_PROCESSING.md             ← Post-processing guide
│   └── POST_PROCESSING_UPDATE.md      ← Latest updates
│
├── Meta/Documentation (3 files)
│   ├── DOCUMENTATION_INDEX.md         ← Complete doc map
│   ├── DOCUMENTATION_SUMMARY.md       ← Doc overview
│   └── DOCUMENTATION_VISUAL_MAP.md    ← Visual structure
│
└── History/Summaries (3 files)
    ├── FINAL_SUMMARY.md               ← Project summary
    ├── FPS_TRANSFORMATION_SUMMARY.md  ← Evolution history
    └── PLAN_VS_HTML_COMPARISON.md     ← Design vs implementation
```

**Total:** 25 documentation files, ~15,000+ lines

---

## 🔨 Build System (`build/`)

**Build scripts and compiled APKs**

```
build/
├── README.md                 ← Build instructions
│
├── Build Scripts
│   ├── build-apk.bat         ← Basic APK build
│   ├── build-glb-apk.bat     ← APK with GLB assets
│   └── build-gradle.bat      ← Gradle build (recommended)
│
└── Compiled APKs
    ├── ramai.apk             ← Main game APK
    └── GLBViewer.apk         ← Model viewer APK
```

---

## 🎨 Assets (`CONTENT/`)

**Game assets organized by type**

```
CONTENT/
└── MESHES/
    ├── CLEANUP_SUMMARY.md
    │
    ├── kenney_blocky-characters_20/
    │   ├── character-a.glb through character-r.glb (18 files)
    │   ├── README.md
    │   └── Textures/
    │
    ├── kenney_building-kit/
    │   ├── 80+ GLB files (walls, floors, doors, etc.)
    │   └── README.md
    │
    └── [other asset packs]/
```

**Total Assets:** 100+ GLB files, ~500 MB

---

## 📦 Libraries (`assets/`)

**Third-party libraries and dependencies**

```
assets/
└── js/
    ├── three.min.js          ← Three.js library
    ├── three.module.js       ← Three.js ES6 module
    ├── GLTFLoader.js         ← GLTF/GLB loader
    │
    └── addons/
        ├── controls/         ← Camera controls
        ├── loaders/          ← Additional loaders
        ├── math/             ← Math utilities
        └── utils/            ← Utility functions
```

---

## 📱 Android Projects

### Legacy Android Studio (`android/`)

```
android/
├── app/
│   ├── build.gradle
│   └── src/
│       └── main/
│           ├── AndroidManifest.xml
│           ├── java/
│           └── assets/
│
├── build.gradle
├── gradle/
├── gradle.properties
├── gradlew.bat
└── settings.gradle
```

### Current Gradle Build (`android-gradle/`)

```
android-gradle/
├── app/
│   ├── build.gradle
│   ├── proguard-rules.pro
│   └── src/
│       └── main/
│           ├── AndroidManifest.xml
│           ├── java/
│           └── assets/
│
├── build.gradle
├── gradle/
├── gradle.properties
├── gradlew.bat
├── local.properties
└── settings.gradle
```

---

## 📋 Planning (`PLAN/`)

**Design documents and planning materials**

```
PLAN/
├── architecture/
├── design/
├── roadmap/
└── [planning documents]
```

---

## 🛠️ Utilities (`scripts/`)

**Utility scripts for development**

```
scripts/
├── asset-processing/
├── build-helpers/
└── [utility scripts]
```

---

## 📸 Screenshots (`screenshots/`)

**Project screenshots and images**

```
screenshots/
├── screenshot.png
├── screenshot2.png
├── screenshot_fixed.png
└── screenshot_loaded.png
```

---

## 🔧 Configuration Files

### Git (`.git/`)
- Git repository data
- Commit history
- Branches

### VS Code (`.vscode/`)
- Editor settings
- Launch configurations
- Task definitions

### Git Ignore (`.gitignore`)
- Ignored files and folders
- Build artifacts
- Temporary files

---

## 📊 Directory Statistics

| Directory | Files | Size | Purpose |
|-----------|-------|------|---------|
| **Root** | 5 | ~5 MB | Essential files only |
| **docs/** | 26 | ~2 MB | All documentation |
| **build/** | 6 | ~15 MB | Build scripts & APKs |
| **CONTENT/** | 100+ | ~500 MB | Game assets |
| **assets/** | 50+ | ~5 MB | Libraries |
| **android/** | 50+ | ~10 MB | Android (legacy) |
| **android-gradle/** | 50+ | ~10 MB | Android (current) |
| **PLAN/** | 20+ | ~1 MB | Planning docs |
| **scripts/** | 10+ | ~500 KB | Utility scripts |
| **screenshots/** | 4 | ~2 MB | Images |

**Total:** ~300+ files, ~550 MB

---

## 🎯 Design Principles

### 1. Clean Root Directory
- Only essential files at root level
- No clutter or temporary files
- Easy to navigate

### 2. Logical Organization
- Related files grouped together
- Clear folder names
- Consistent structure

### 3. Comprehensive Documentation
- Every folder has a README
- Clear navigation paths
- Multiple entry points

### 4. Separation of Concerns
- Code separate from assets
- Documentation separate from code
- Build artifacts isolated

### 5. Scalability
- Easy to add new files
- Clear where things belong
- Maintainable structure

---

## 🔍 Finding Files

### "Where is...?"

- **Main game code?** → `index.html`
- **Documentation?** → `docs/`
- **Build scripts?** → `build/`
- **3D models?** → `CONTENT/MESHES/`
- **Libraries?** → `assets/js/`
- **Android project?** → `android-gradle/`
- **Screenshots?** → `screenshots/`
- **Planning docs?** → `PLAN/`

### Quick Navigation

```bash
# View root structure
ls -la

# Browse documentation
cd docs && ls

# Check build files
cd build && ls

# View assets
cd CONTENT/MESHES && ls

# Android project
cd android-gradle && ls
```

---

## 📚 Related Documentation

- **Main README:** [README.md](README.md)
- **Documentation Index:** [docs/README.md](docs/README.md)
- **Build Guide:** [build/README.md](build/README.md)
- **Developer Guide:** [docs/DEVELOPER_GUIDE.md](docs/DEVELOPER_GUIDE.md)

---

## 🎓 Best Practices

### Adding New Files

1. **Determine category** — Where does it belong?
2. **Check existing structure** — Follow patterns
3. **Update README** — Document new files
4. **Keep root clean** — Avoid root clutter

### Maintaining Structure

1. **Regular cleanup** — Remove unused files
2. **Update documentation** — Keep READMEs current
3. **Follow conventions** — Consistent naming
4. **Review periodically** — Ensure organization

### Working with Team

1. **Document changes** — Update structure docs
2. **Communicate moves** — Notify team of reorganization
3. **Use relative paths** — Avoid hardcoded paths
4. **Keep it simple** — Don't over-organize

---

## 🚀 Quick Commands

```bash
# View project structure
tree -L 2

# Count files by directory
find . -type f | cut -d/ -f2 | sort | uniq -c

# Find large files
find . -type f -size +10M

# List recent changes
git log --name-only --oneline -10

# Check disk usage
du -sh */
```

---

## 📈 Evolution

### Before Reorganization
- 40+ files in root directory
- Documentation scattered
- Build files mixed with source
- Hard to navigate

### After Reorganization
- 5 files in root directory
- All docs in `docs/`
- Build files in `build/`
- Clean and professional

**Result:** 87% reduction in root clutter, 100% improvement in organization

---

## 🎯 Future Improvements

- [ ] Add `tests/` directory for unit tests
- [ ] Create `examples/` for code samples
- [ ] Add `tools/` for development tools
- [ ] Organize `PLAN/` into subdirectories
- [ ] Add `dist/` for distribution builds

---

**Last Updated:** May 11, 2026  
**Maintained By:** RAMAI Engine Team  
**Status:** ✅ Clean & Organized

---

**Keep it clean! 🧹**
