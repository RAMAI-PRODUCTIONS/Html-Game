# Android Build System — AAA Mobile APK
## WebView Optimization, Performance, AdMob, Release Pipeline

---

## 1. Enhanced MainActivity.java

```java
package com.ramai.engine;

import android.annotation.SuppressLint;
import android.content.pm.ActivityInfo;
import android.os.Build;
import android.os.Bundle;
import android.view.View;
import android.view.Window;
import android.view.WindowManager;
import android.webkit.*;
import android.widget.FrameLayout;
import androidx.appcompat.app.AppCompatActivity;
import com.google.android.gms.ads.*;
import com.google.android.gms.ads.interstitial.InterstitialAd;
import com.google.android.gms.ads.interstitial.InterstitialAdLoadCallback;

public class MainActivity extends AppCompatActivity {
    private WebView webView;
    private AdView bannerAdView;
    private InterstitialAd interstitialAd;
    
    // JavaScript interface for native features
    private GameBridge gameBridge;
    
    @SuppressLint("SetJavaScriptEnabled")
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        
        // ── Full screen, no title bar ──────────────────────────────
        requestWindowFeature(Window.FEATURE_NO_TITLE);
        getWindow().setFlags(
            WindowManager.LayoutParams.FLAG_FULLSCREEN,
            WindowManager.LayoutParams.FLAG_FULLSCREEN
        );
        
        // Keep screen on during gameplay
        getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
        
        // Lock to landscape (or portrait — your choice)
        setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_LANDSCAPE);
        
        // ── Layout ────────────────────────────────────────────────
        FrameLayout rootLayout = new FrameLayout(this);
        rootLayout.setLayoutParams(new FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.MATCH_PARENT,
            FrameLayout.LayoutParams.MATCH_PARENT
        ));
        
        // ── WebView ───────────────────────────────────────────────
        webView = new WebView(this);
        FrameLayout.LayoutParams webViewParams = new FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.MATCH_PARENT,
            FrameLayout.LayoutParams.MATCH_PARENT
        );
        webView.setLayoutParams(webViewParams);
        
        WebSettings settings = webView.getSettings();
        settings.setJavaScriptEnabled(true);
        settings.setDomStorageEnabled(true);
        settings.setAllowFileAccess(true);
        settings.setAllowContentAccess(true);
        settings.setAllowFileAccessFromFileURLs(true);
        settings.setAllowUniversalAccessFromFileURLs(true);
        settings.setMediaPlaybackRequiresUserGesture(false);
        settings.setCacheMode(WebSettings.LOAD_DEFAULT);
        settings.setMixedContentMode(WebSettings.MIXED_CONTENT_ALWAYS_ALLOW);
        
        // Performance settings
        settings.setRenderPriority(WebSettings.RenderPriority.HIGH);
        settings.setDatabaseEnabled(true);
        settings.setGeolocationEnabled(false);  // not needed
        
        // Hardware acceleration
        webView.setLayerType(View.LAYER_TYPE_HARDWARE, null);
        
        // Enable WebView debugging in debug builds
        if (BuildConfig.DEBUG) {
            WebView.setWebContentsDebuggingEnabled(true);
        }
        
        // ── JavaScript Bridge ─────────────────────────────────────
        gameBridge = new GameBridge(this, webView);
        webView.addJavascriptInterface(gameBridge, "AndroidBridge");
        
        webView.setWebViewClient(new WebViewClient() {
            @Override
            public boolean shouldOverrideUrlLoading(WebView view, String url) {
                return false;
            }
            
            @Override
            public void onPageFinished(WebView view, String url) {
                // Notify JS that native bridge is ready
                view.evaluateJavascript("window.dispatchEvent(new Event('androidReady'))", null);
            }
        });
        
        webView.setWebChromeClient(new WebChromeClient() {
            @Override
            public boolean onConsoleMessage(ConsoleMessage msg) {
                // Forward console.log to Android logcat
                android.util.Log.d("WebView", msg.message() + " -- From line " +
                    msg.lineNumber() + " of " + msg.sourceId());
                return true;
            }
        });
        
        webView.loadUrl("file:///android_asset/www/index.html");
        rootLayout.addView(webView);
        
        // ── AdMob ─────────────────────────────────────────────────
        MobileAds.initialize(this, initializationStatus -> {
            loadInterstitialAd();
        });
        
        // Banner ad
        bannerAdView = new AdView(this);
        bannerAdView.setAdSize(AdSize.BANNER);
        bannerAdView.setAdUnitId(BuildConfig.BANNER_AD_UNIT_ID);
        
        FrameLayout.LayoutParams adParams = new FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.WRAP_CONTENT,
            FrameLayout.LayoutParams.WRAP_CONTENT
        );
        adParams.gravity = android.view.Gravity.BOTTOM | android.view.Gravity.CENTER_HORIZONTAL;
        bannerAdView.setLayoutParams(adParams);
        rootLayout.addView(bannerAdView);
        
        AdRequest adRequest = new AdRequest.Builder().build();
        bannerAdView.loadAd(adRequest);
        
        setContentView(rootLayout);
    }
    
    private void loadInterstitialAd() {
        AdRequest adRequest = new AdRequest.Builder().build();
        InterstitialAd.load(this, BuildConfig.INTERSTITIAL_AD_UNIT_ID, adRequest,
            new InterstitialAdLoadCallback() {
                @Override
                public void onAdLoaded(InterstitialAd ad) {
                    interstitialAd = ad;
                }
                @Override
                public void onAdFailedToLoad(LoadAdError error) {
                    interstitialAd = null;
                }
            }
        );
    }
    
    // Called from JavaScript via AndroidBridge.showInterstitial()
    public void showInterstitialAd() {
        runOnUiThread(() -> {
            if (interstitialAd != null) {
                interstitialAd.show(this);
                interstitialAd = null;
                loadInterstitialAd();  // preload next
            }
        });
    }
    
    @Override
    public void onBackPressed() {
        if (webView.canGoBack()) {
            webView.goBack();
        } else {
            // Notify JS of back press
            webView.evaluateJavascript("window.dispatchEvent(new Event('androidBack'))", null);
        }
    }
    
    @Override protected void onPause()   { super.onPause();   bannerAdView?.pause();   webView.onPause(); }
    @Override protected void onResume()  { super.onResume();  bannerAdView?.resume();  webView.onResume(); }
    @Override protected void onDestroy() { super.onDestroy(); bannerAdView?.destroy(); webView.destroy(); }
}
```

---

## 2. JavaScript ↔ Android Bridge

```java
// GameBridge.java — exposes native features to JavaScript
public class GameBridge {
    private Activity activity;
    private WebView webView;
    
    public GameBridge(Activity activity, WebView webView) {
        this.activity = activity;
        this.webView = webView;
    }
    
    // Show interstitial ad
    @JavascriptInterface
    public void showInterstitial() {
        ((MainActivity) activity).showInterstitialAd();
    }
    
    // Vibration feedback
    @JavascriptInterface
    public void vibrate(int ms) {
        Vibrator v = (Vibrator) activity.getSystemService(Context.VIBRATOR_SERVICE);
        if (v != null) v.vibrate(ms);
    }
    
    // Get device info
    @JavascriptInterface
    public String getDeviceInfo() {
        JSONObject info = new JSONObject();
        try {
            info.put("model", Build.MODEL);
            info.put("sdk", Build.VERSION.SDK_INT);
            info.put("ram", getAvailableRAM());
            info.put("cores", Runtime.getRuntime().availableProcessors());
        } catch (Exception e) {}
        return info.toString();
    }
    
    // Share score
    @JavascriptInterface
    public void shareScore(String text) {
        Intent intent = new Intent(Intent.ACTION_SEND);
        intent.setType("text/plain");
        intent.putExtra(Intent.EXTRA_TEXT, text);
        activity.startActivity(Intent.createChooser(intent, "Share Score"));
    }
    
    // Rate app
    @JavascriptInterface
    public void rateApp() {
        String packageName = activity.getPackageName();
        try {
            activity.startActivity(new Intent(Intent.ACTION_VIEW,
                Uri.parse("market://details?id=" + packageName)));
        } catch (Exception e) {
            activity.startActivity(new Intent(Intent.ACTION_VIEW,
                Uri.parse("https://play.google.com/store/apps/details?id=" + packageName)));
        }
    }
    
    private long getAvailableRAM() {
        ActivityManager.MemoryInfo mi = new ActivityManager.MemoryInfo();
        ((ActivityManager) activity.getSystemService(Context.ACTIVITY_SERVICE)).getMemoryInfo(mi);
        return mi.availMem;
    }
}
```

---

## 3. JavaScript Bridge Usage

```javascript
// AndroidBridge.js — JS side of the native bridge
class AndroidBridge {
    static isAvailable() {
        return typeof window.AndroidBridge !== 'undefined';
    }
    
    static showInterstitial() {
        if (this.isAvailable()) {
            window.AndroidBridge.showInterstitial();
        }
    }
    
    static vibrate(ms = 50) {
        if (this.isAvailable()) {
            window.AndroidBridge.vibrate(ms);
        } else if (navigator.vibrate) {
            navigator.vibrate(ms);  // Web API fallback
        }
    }
    
    static async getDeviceInfo() {
        if (this.isAvailable()) {
            return JSON.parse(window.AndroidBridge.getDeviceInfo());
        }
        return {
            model: navigator.userAgent,
            sdk: 0,
            ram: performance.memory?.totalJSHeapSize ?? 0,
            cores: navigator.hardwareConcurrency ?? 4
        };
    }
    
    static shareScore(score, gameName) {
        const text = `I scored ${score} in ${gameName}! Can you beat me?`;
        if (this.isAvailable()) {
            window.AndroidBridge.shareScore(text);
        } else if (navigator.share) {
            navigator.share({ text });
        }
    }
}

// Auto-detect device tier on startup
window.addEventListener('androidReady', async () => {
    const info = await AndroidBridge.getDeviceInfo();
    
    // Set quality based on device
    if (info.ram < 2 * 1024 * 1024 * 1024) {  // < 2GB RAM
        AdaptiveQuality.forceTier('LOW');
    } else if (info.cores <= 4) {
        AdaptiveQuality.forceTier('MED');
    } else {
        AdaptiveQuality.forceTier('HIGH');
    }
});
```

---

## 4. Build Gradle (Production)

```gradle
// app/build.gradle — Production configuration
apply plugin: 'com.android.application'

android {
    namespace 'com.ramai.engine'
    compileSdk 34
    
    defaultConfig {
        applicationId "com.ramai.engine"
        minSdk 24          // Android 7.0 — better WebGL support
        targetSdk 34
        versionCode 1
        versionName "1.0.0"
        
        // Build config fields for ad unit IDs
        buildConfigField "String", "BANNER_AD_UNIT_ID",
            '"ca-app-pub-3940256099942544/6300978111"'  // test
        buildConfigField "String", "INTERSTITIAL_AD_UNIT_ID",
            '"ca-app-pub-3940256099942544/1033173712"'  // test
    }
    
    buildTypes {
        debug {
            debuggable true
            minifyEnabled false
        }
        release {
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'),
                          'proguard-rules.pro'
            
            // Replace test ad IDs with real ones in release
            buildConfigField "String", "BANNER_AD_UNIT_ID",
                '"ca-app-pub-YOUR_ID/YOUR_BANNER_ID"'
            buildConfigField "String", "INTERSTITIAL_AD_UNIT_ID",
                '"ca-app-pub-YOUR_ID/YOUR_INTERSTITIAL_ID"'
        }
    }
    
    compileOptions {
        sourceCompatibility JavaVersion.VERSION_11
        targetCompatibility JavaVersion.VERSION_11
    }
    
    // Don't compress game assets
    aaptOptions {
        noCompress 'glb', 'gltf', 'bin', 'mp3', 'ogg', 'wav', 'json'
    }
    
    // Split APKs by ABI for smaller downloads
    splits {
        abi {
            enable true
            reset()
            include 'arm64-v8a', 'armeabi-v7a', 'x86_64'
            universalApk false
        }
    }
}

dependencies {
    implementation 'androidx.appcompat:appcompat:1.6.1'
    implementation 'com.google.android.gms:play-services-ads:22.6.0'
    
    // Optional: Firebase Analytics
    // implementation 'com.google.firebase:firebase-analytics:21.5.0'
    
    // Optional: Play Games Services
    // implementation 'com.google.android.gms:play-services-games:23.1.0'
}

// Auto-copy web assets before build
task copyWebAssets(type: Copy) {
    from '../../'  // workspace root
    into 'src/main/assets/www'
    include 'index.html'
    include 'assets/**'
    include 'CONTENT/**'
    include 'engine/**'
}

preBuild.dependsOn copyWebAssets
```

---

## 5. Performance Optimization for Android WebView

```javascript
// Critical optimizations for Android WebView performance

// 1. Prevent scroll bounce (kills performance)
document.body.style.overflow = 'hidden';
document.documentElement.style.overflow = 'hidden';

// 2. Disable text selection (causes lag on touch)
document.body.style.userSelect = 'none';
document.body.style.webkitUserSelect = 'none';

// 3. Prevent context menu on long press
document.addEventListener('contextmenu', e => e.preventDefault());

// 4. Prevent default touch behaviors
document.addEventListener('touchstart', e => {
    if (e.target === renderer.domElement) e.preventDefault();
}, { passive: false });

// 5. Request persistent storage (for save games)
if (navigator.storage && navigator.storage.persist) {
    navigator.storage.persist();
}

// 6. Preload critical assets before showing anything
async function preloadCritical() {
    // Show loading screen
    setStatus('Loading...');
    
    await AssetManager.preloadBundle([
        { key: 'player', type: 'glb', url: 'CONTENT/MESHES/kenney_blocky-characters_20/character-a.glb' },
        // ... other critical assets
    ], (progress) => {
        setStatus(`Loading... ${Math.round(progress * 100)}%`);
    });
    
    setStatus('');
    GameFSM.start('MENU');
}

// 7. Reduce GC pressure — pre-allocate reusable objects
const _tmpVec3 = new THREE.Vector3();
const _tmpQuat = new THREE.Quaternion();
const _tmpMat4 = new THREE.Matrix4();
const _tmpBox3 = new THREE.Box3();
// Use these instead of creating new objects in hot paths
```

---

## 6. Release Checklist

```
PRE-RELEASE:
□ Replace test AdMob IDs with real IDs
□ Set versionCode and versionName
□ Enable ProGuard/R8 minification
□ Test on low-end device (2GB RAM, SD 720G)
□ Test on mid-range device (4GB RAM, SD 855)
□ Verify all GLB files load correctly
□ Verify audio plays on first touch
□ Test save/load system
□ Test back button behavior
□ Verify no console errors in release build
□ Check APK size (target: <100MB)
□ Test offline mode (no internet)

SIGNING:
□ Generate keystore: keytool -genkey -v -keystore release.jks
□ Configure signing in build.gradle
□ Build release APK: gradlew assembleRelease
□ Verify APK with: apksigner verify release.apk

GOOGLE PLAY:
□ Create app listing
□ Upload AAB (preferred over APK): gradlew bundleRelease
□ Add screenshots (phone + tablet)
□ Write store description
□ Set content rating
□ Set target audience
□ Submit for review
```
