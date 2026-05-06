# GLB Viewer - Gradle Android Build

This is a pure Gradle-based Android project that packages your HTML GLB viewer with all 3D models into an APK.

## Features

✅ **Pure Gradle Build System** - No manual file copying or complex batch scripts
✅ **Automatic Asset Management** - Gradle automatically copies HTML and all GLB files
✅ **AdMob Integration** - Banner ads included (test ads by default)
✅ **Hardware Accelerated WebView** - Optimized for 3D rendering
✅ **No Compression for GLB** - Large 3D files handled correctly
✅ **Clean Project Structure** - Standard Android project layout

## Project Structure

```
android-gradle/
├── app/
│   ├── build.gradle              # App-level build config with asset copying
│   ├── proguard-rules.pro        # ProGuard rules
│   └── src/main/
│       ├── AndroidManifest.xml   # App manifest with permissions
│       ├── java/com/ramai/glbviewer/
│       │   └── MainActivity.java # WebView + AdMob activity
│       └── res/
│           └── values/
│               ├── strings.xml
│               └── colors.xml
├── gradle/wrapper/               # Gradle wrapper files
├── build.gradle                  # Root build config
├── settings.gradle               # Project settings
├── gradle.properties             # Build optimization settings
├── gradlew.bat                   # Gradle wrapper script (Windows)
└── local.properties              # SDK location (auto-generated)
```

## How It Works

### 1. Asset Copying (Automatic)
The `app/build.gradle` file contains a custom task `copyWebAssets` that:
- Copies `viewer.html` → `app/src/main/assets/www/index.html`
- Copies entire `CONTENT/` directory → `app/src/main/assets/www/CONTENT/`
- Runs automatically before each build via `preBuild.dependsOn copyWebAssets`

### 2. GLB File Handling
```gradle
aaptOptions {
    noCompress 'glb', 'gltf', 'bin'
}
```
This ensures large GLB files are stored uncompressed in the APK for direct access.

### 3. WebView Configuration
The `MainActivity.java` is configured for optimal 3D performance:
- JavaScript enabled
- Hardware acceleration enabled
- File access enabled for loading local GLB files
- Mixed content allowed for CDN resources (Three.js)

## Quick Start

### Prerequisites
- Java JDK 8 or higher
- Android SDK (API 34)
- Set `ANDROID_HOME` environment variable

### Build Commands

#### Windows (Simple)
```batch
build-gradle.bat
```

#### Manual Gradle Commands
```batch
cd android-gradle

# Clean build
gradlew.bat clean

# Build debug APK
gradlew.bat assembleDebug

# Build release APK
gradlew.bat assembleRelease

# Install on connected device
gradlew.bat installDebug
```

### Output Location
- Debug APK: `android-gradle/app/build/outputs/apk/debug/app-debug.apk`
- Release APK: `android-gradle/app/build/outputs/apk/release/app-release.apk`

## Customization

### Change App Name
Edit `android-gradle/app/src/main/res/values/strings.xml`:
```xml
<string name="app_name">Your App Name</string>
```

### Change Package Name
1. Edit `android-gradle/app/build.gradle`:
```gradle
namespace 'com.yourcompany.yourapp'
defaultConfig {
    applicationId "com.yourcompany.yourapp"
}
```

2. Rename Java package directory and update `MainActivity.java` package declaration

3. Update `AndroidManifest.xml` activity name if needed

### Add App Icon
Place your icon files in:
- `android-gradle/app/src/main/res/mipmap-mdpi/ic_launcher.png` (48x48)
- `android-gradle/app/src/main/res/mipmap-hdpi/ic_launcher.png` (72x72)
- `android-gradle/app/src/main/res/mipmap-xhdpi/ic_launcher.png` (96x96)
- `android-gradle/app/src/main/res/mipmap-xxhdpi/ic_launcher.png` (144x144)
- `android-gradle/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png` (192x192)

### Configure Real AdMob Ads
Edit `android-gradle/app/src/main/AndroidManifest.xml`:
```xml
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-YOUR_PUBLISHER_ID~YOUR_APP_ID"/>
```

Edit `MainActivity.java`:
```java
adView.setAdUnitId("ca-app-pub-YOUR_PUBLISHER_ID/YOUR_AD_UNIT_ID");
```

## Build Optimization

The `gradle.properties` file includes optimizations:
- **Parallel builds** - Faster multi-module builds
- **Build caching** - Reuse outputs from previous builds
- **Gradle daemon** - Keep Gradle running in background
- **2GB heap** - Sufficient memory for large projects

## Troubleshooting

### Build Fails - SDK Not Found
Edit `android-gradle/local.properties`:
```properties
sdk.dir=C\:\\Users\\YourUsername\\AppData\\Local\\Android\\Sdk
```

### Out of Memory During Build
Increase heap size in `gradle.properties`:
```properties
org.gradle.jvmargs=-Xmx4096m -Dfile.encoding=UTF-8
```

### GLB Files Not Loading
Check that:
1. Files are in `CONTENT/MESHES/` directory
2. Paths in `viewer.html` match the directory structure
3. `noCompress` is set for `.glb` extension

### WebView Shows Blank Screen
Enable WebView debugging in `MainActivity.java`:
```java
if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
    WebView.setWebContentsDebuggingEnabled(true);
}
```
Then use Chrome DevTools: `chrome://inspect`

## Advantages Over Batch Script

| Feature | Batch Script | Gradle |
|---------|-------------|--------|
| Asset Management | Manual copying | Automatic |
| Dependency Management | Manual | Automatic |
| Build Caching | No | Yes |
| Incremental Builds | No | Yes |
| IDE Integration | No | Full support |
| Multi-variant Builds | Complex | Built-in |
| Signing Configuration | Manual | Integrated |
| Testing Support | No | Full support |

## Next Steps

1. **Add Signing Config** for release builds
2. **Enable ProGuard** for code optimization
3. **Add Build Variants** (free/paid, different model sets)
4. **Implement App Bundle** (.aab) for Google Play
5. **Add Unit Tests** for Java code
6. **Configure CI/CD** (GitHub Actions, etc.)

## License

This build configuration is provided as-is for your project.
