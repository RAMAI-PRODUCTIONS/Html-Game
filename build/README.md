# 🔨 Build Scripts & APKs

This folder contains all build-related files for the RAMAI Engine project.

---

## 📦 Contents

### Build Scripts
- **build-apk.bat** — Build Android APK (basic)
- **build-glb-apk.bat** — Build Android APK with GLB assets
- **build-gradle.bat** — Build using Gradle (recommended)

### Compiled APKs
- **ramai.apk** — Main game APK (latest build)
- **GLBViewer.apk** — Model viewer APK (debug tool)

---

## 🚀 Quick Start

### Windows

```bash
# Navigate to build folder
cd build

# Run Gradle build (recommended)
build-gradle.bat
```

### Linux/macOS

```bash
# Navigate to android-gradle folder
cd ../android-gradle

# Run Gradle build
./gradlew assembleRelease
```

---

## 📱 Build Instructions

### Method 1: Gradle Build (Recommended)

**Windows:**
```bash
cd build
build-gradle.bat
```

**Linux/macOS:**
```bash
cd android-gradle
./gradlew assembleRelease
```

**Output:** `android-gradle/app/build/outputs/apk/release/app-release.apk`

### Method 2: Basic APK Build

**Windows:**
```bash
cd build
build-apk.bat
```

**Output:** `build/ramai.apk`

### Method 3: GLB Asset Build

**Windows:**
```bash
cd build
build-glb-apk.bat
```

**Output:** `build/ramai.apk` (with embedded GLB assets)

---

## 🔧 Build Requirements

### Prerequisites
- **Android SDK** — API Level 21+ (Android 5.0+)
- **Gradle** — Version 7.0+ (included in android-gradle)
- **Java JDK** — Version 11+ (for Gradle)

### Optional
- **Android Studio** — For GUI-based builds
- **ADB** — For device testing

---

## 📊 APK Information

### ramai.apk
- **Version:** 2.0
- **Min SDK:** 21 (Android 5.0)
- **Target SDK:** 33 (Android 13)
- **Size:** ~5-10 MB (varies with assets)
- **Architecture:** Universal (ARM, ARM64, x86, x86_64)

### GLBViewer.apk
- **Version:** 1.0
- **Min SDK:** 21 (Android 5.0)
- **Target SDK:** 33 (Android 13)
- **Size:** ~3-5 MB
- **Purpose:** Debug tool for viewing GLB models

---

## 🐛 Troubleshooting

### Build Fails

**Issue:** Gradle build fails with "SDK not found"
**Solution:** Set `ANDROID_HOME` environment variable
```bash
# Windows
set ANDROID_HOME=C:\Users\YourName\AppData\Local\Android\Sdk

# Linux/macOS
export ANDROID_HOME=~/Android/Sdk
```

**Issue:** Java version mismatch
**Solution:** Install Java JDK 11+
```bash
# Check Java version
java -version

# Should show version 11 or higher
```

**Issue:** Gradle daemon fails
**Solution:** Kill Gradle daemon and retry
```bash
cd android-gradle
./gradlew --stop
./gradlew assembleRelease
```

### APK Installation Fails

**Issue:** "App not installed" error
**Solution:** Enable "Install from unknown sources" in Android settings

**Issue:** "Parse error" when installing
**Solution:** APK may be corrupted, rebuild from source

---

## 📱 Testing APKs

### Install on Device

**Via ADB:**
```bash
# Install ramai.apk
adb install build/ramai.apk

# Install GLBViewer.apk
adb install build/GLBViewer.apk
```

**Via File Transfer:**
1. Copy APK to device
2. Open file manager on device
3. Tap APK file
4. Follow installation prompts

### Run on Device

**Via ADB:**
```bash
# Launch ramai
adb shell am start -n com.ramai.game/.MainActivity

# Launch GLBViewer
adb shell am start -n com.ramai.glbviewer/.MainActivity
```

**Via Device:**
1. Open app drawer
2. Tap "RAMAI" or "GLB Viewer" icon

---

## 🔍 Build Output Locations

### Gradle Build
```
android-gradle/
└── app/
    └── build/
        └── outputs/
            └── apk/
                ├── debug/
                │   └── app-debug.apk
                └── release/
                    └── app-release.apk
```

### Script Build
```
build/
├── ramai.apk
└── GLBViewer.apk
```

---

## 📚 Additional Resources

- **Android Build Guide:** [../docs/README-GRADLE.md](../docs/README-GRADLE.md)
- **Deployment Report:** [../docs/DEPLOYMENT_REPORT.md](../docs/DEPLOYMENT_REPORT.md)
- **Deployment Fixes:** [../docs/DEPLOYMENT_FIX.md](../docs/DEPLOYMENT_FIX.md)
- **Main README:** [../README.md](../README.md)

---

## 🎯 Quick Commands

```bash
# Build release APK
cd build && build-gradle.bat

# Install on device
adb install build/ramai.apk

# Run on device
adb shell am start -n com.ramai.game/.MainActivity

# View logs
adb logcat | grep RAMAI

# Uninstall
adb uninstall com.ramai.game
```

---

**Last Updated:** May 11, 2026  
**Build System:** Gradle 7.0+  
**Target Platform:** Android 5.0+ (API 21+)

---

**Happy Building! 📱**
