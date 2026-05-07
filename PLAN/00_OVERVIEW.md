# AAA Mobile Game Engine — Master Plan
## From GLB Viewer → Unreal-Class HTML5 Game Engine for Android

**Date:** May 2026  
**Codebase:** Three.js r128 + Android WebView + Kenney Asset Library  
**Goal:** Build a production-grade, modular HTML5 game engine capable of shipping AAA mobile titles

---

## What We Have Today

| System | Status | Notes |
|--------|--------|-------|
| WebGL Renderer | ✅ Working | Three.js r128, PCF shadows, instancing |
| GLB Asset Loading | ✅ Working | XHR binary loader, texture cache |
| Instanced Rendering | ✅ Working | 2000+ objects, 1 draw call per material |
| Touch/Mouse Orbit | ✅ Working | Spherical coords, pinch zoom |
| Performance HUD | ✅ Working | FPS, draw calls, tris, memory, ECS debug |
| Adaptive Quality | ✅ Working | 3-tier system, auto FPS-based switching |
| Android Build | ✅ Working | Gradle + WebView + AdMob |
| Asset Library | ✅ Rich | 2000+ GLB models, 20+ kits |
| **ECS Core** | ✅ **Complete** | Flat typed arrays, 2048 entity pool |
| **Physics System** | ✅ **Complete** | Gravity, Euler integration, ground clamp, friction |
| **AI System** | ✅ **Complete** | State machine (IDLE/PATROL/CHASE/ATTACK) |
| **Input System** | ✅ **Complete** | Keyboard + virtual joystick, unified |
| **Fixed Timestep Loop** | ✅ **Complete** | 60Hz physics, variable render, accumulator |
| **Object Pool** | ✅ **Complete** | Zero-alloc spawning, mesh slot recycling |
| **Follow Camera** | ✅ **Complete** | Smooth lerp tracking in ECS mode |
| Collision Detection | ❌ Missing | No AABB, no raycasting |
| Animation | ❌ Missing | No skeletal, no keyframes |
| Audio | ❌ Missing | No Web Audio integration |
| Particles | ❌ Missing | No GPU particles |
| Post-Processing | ❌ Missing | No bloom, DOF, color grading |
| LOD System | ❌ Missing | All models at full detail |
| UI Framework | ⚠️ Basic | HTML buttons + HUD, no canvas UI |
| Scene Editor | ❌ Missing | No level design tools |
| Save/Load | ❌ Missing | No persistence |

---

## The Vision: "RAMAI Engine"

A **modular, data-oriented HTML5 game engine** that:
- Runs at **60 FPS on mid-range Android** (Snapdragon 720G+)
- Supports **AAA visual quality** via PBR, post-processing, dynamic shadows
- Has an **Unreal-inspired architecture**: World, Actors, Components, Systems
- Ships as a **single HTML file** (or small bundle) packaged into an APK
- Includes a **browser-based level editor** (like Unreal's viewport)
- Supports **multiple game genres** from the same engine base

---

## Document Index

| File | Status | Contents |
|------|--------|----------|
| `00_OVERVIEW.md` | ✅ Current | This file — project vision and goals |
| `STATUS.md` | ✅ **NEW** | **Detailed implementation status** — what's done, what's next |
| `10_ROADMAP.md` | ✅ Updated | Phased implementation plan with completion tracking |
| `12_ECS_SINGLE_HTML.md` | ✅ Complete | **IMPLEMENTED** — ECS architecture + NES-era data patterns |
| `TEMPLATE_BEST_CODE.md` | ✅ Reference | All proven patterns from current codebase |
| `01_ARCHITECTURE.md` | 📝 Planned | Full engine architecture, module breakdown |
| `02_RENDERING_PIPELINE.md` | 📝 Planned | Renderer, shaders, post-processing, LOD |
| `03_PHYSICS_SYSTEM.md` | 📝 Planned | Collision, rigid body, raycasting |
| `04_ECS_GAMEPLAY.md` | 📝 Planned | Advanced gameplay systems |
| `05_ANIMATION_SYSTEM.md` | 📝 Planned | Skeletal animation, blending, state machines |
| `06_AUDIO_SYSTEM.md` | 📝 Planned | Web Audio API, spatial audio, music |
| `07_UI_FRAMEWORK.md` | 📝 Planned | Canvas HUD, menus, dialogs |
| `08_ASSET_PIPELINE.md` | 📝 Planned | Loading, streaming, LOD generation |
| `09_EDITOR.md` | 📝 Planned | Browser-based level editor |

---

## Core Design Principles

1. **Zero dependencies beyond Three.js** — no npm, no bundler, works from file://
2. **Data-oriented** — flat arrays, typed buffers, cache-friendly layouts
3. **Mobile-first** — every decision optimized for 60fps on Android WebView
4. **Modular** — each system is a self-contained JS module, opt-in
5. **Single-file deployable** — entire engine + game fits in one HTML file
6. **Unreal-inspired API** — familiar to AAA developers
