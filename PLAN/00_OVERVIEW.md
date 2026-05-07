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
| Performance HUD | ✅ Working | FPS, draw calls, tris, memory |
| Adaptive Quality | ⚠️ Stubbed | Framework exists, locked to HIGH |
| Android Build | ✅ Working | Gradle + WebView + AdMob |
| Asset Library | ✅ Rich | 2000+ GLB models, 20+ kits |
| Physics | ❌ Missing | No collision, gravity, dynamics |
| Animation | ❌ Missing | No skeletal, no keyframes |
| ECS / Gameplay | ❌ Missing | No entities, components, systems |
| Audio | ❌ Missing | No Web Audio integration |
| Particles | ❌ Missing | No GPU particles |
| Post-Processing | ❌ Missing | No bloom, DOF, color grading |
| LOD System | ❌ Missing | All models at full detail |
| UI Framework | ❌ Missing | Only raw HTML buttons |
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

| File | Contents |
|------|----------|
| `01_ARCHITECTURE.md` | Full engine architecture, module breakdown |
| `02_RENDERING_PIPELINE.md` | Renderer, shaders, post-processing, LOD |
| `03_PHYSICS_SYSTEM.md` | Collision, rigid body, raycasting |
| `04_ECS_GAMEPLAY.md` | Entity-Component-System, game loop |
| `05_ANIMATION_SYSTEM.md` | Skeletal animation, blending, state machines |
| `06_AUDIO_SYSTEM.md` | Web Audio API, spatial audio, music |
| `07_UI_FRAMEWORK.md` | HUD, menus, dialogs, input |
| `08_ASSET_PIPELINE.md` | Loading, streaming, LOD generation |
| `09_EDITOR.md` | Browser-based level editor |
| `10_ANDROID_BUILD.md` | APK pipeline, performance, AdMob |
| `11_ROADMAP.md` | Phased implementation plan |
| `TEMPLATE_BEST_CODE.md` | All best patterns from current codebase |

---

## Core Design Principles

1. **Zero dependencies beyond Three.js** — no npm, no bundler, works from file://
2. **Data-oriented** — flat arrays, typed buffers, cache-friendly layouts
3. **Mobile-first** — every decision optimized for 60fps on Android WebView
4. **Modular** — each system is a self-contained JS module, opt-in
5. **Single-file deployable** — entire engine + game fits in one HTML file
6. **Unreal-inspired API** — familiar to AAA developers
