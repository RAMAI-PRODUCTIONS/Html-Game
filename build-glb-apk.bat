@echo off
setlocal EnableDelayedExpansion

REM ============================================================
REM  CONFIGURE THESE ONCE
REM ============================================================
set JAVA_HOME=C:\Program Files\Eclipse Adoptium\jdk-21.0.10.7-hotspot
set ANDROID_HOME=C:\Users\saura\AppData\Local\Android\Sdk
REM ============================================================

set PATH=%JAVA_HOME%\bin;%ANDROID_HOME%\cmdline-tools\latest\bin;%ANDROID_HOME%\platform-tools;%PATH%

echo.
echo  GLB Viewer APK Builder
echo  ----------------------
echo.

if not exist "viewer.html" (
    echo [ERROR] viewer.html not found in root directory.
    pause
    exit /b 1
)

if not exist "CONTENT" (
    echo [ERROR] CONTENT directory not found.
    pause
    exit /b 1
)

set APP_NAME=GLBViewer
set APP_ID=com.ramai.glbviewer

echo  App Name : %APP_NAME%
echo  Package  : %APP_ID%
echo.

REM ── Step 1: Setup Android project ──────────────────────────
echo  [1/4] Setting up Android project...

md "android\gradle\wrapper" 2>nul
md "android\app\src\main\java\com\ramai\glbviewer" 2>nul
md "android\app\src\main\res\values" 2>nul
md "android\app\src\main\res\mipmap" 2>nul
md "android\app\src\main\assets\www" 2>nul

REM ── Bootstrap Gradle wrapper jar ───
if not exist "android\gradle\wrapper\gradle-wrapper.jar" (
    echo        Downloading Gradle wrapper jar...
    curl -sL -o "android\gradle\wrapper\gradle-wrapper.jar" "https://github.com/gradle/gradle/raw/v8.2.0/gradle/wrapper/gradle-wrapper.jar"
    if errorlevel 1 (
        echo [ERROR] curl failed. Check internet connection.
        pause
        exit /b 1
    )
    echo        Done.
)

REM ── gradle-wrapper.properties ────
set GWP=android\gradle\wrapper\gradle-wrapper.properties
echo distributionBase=GRADLE_USER_HOME>                                                    "%GWP%"
echo distributionPath=wrapper/dists>>                                                      "%GWP%"
echo distributionUrl=https\://services.gradle.org/distributions/gradle-8.2-bin.zip>>      "%GWP%"
echo zipStoreBase=GRADLE_USER_HOME>>                                                       "%GWP%"
echo zipStorePath=wrapper/dists>>                                                          "%GWP%"
echo networkTimeout=10000>>                                                                "%GWP%"

REM ── gradlew.bat ──
set GW=android\gradlew.bat
echo @echo off>                                                                            "%GW%"
echo setlocal>>                                                                            "%GW%"
echo set JAVA_EXE=%JAVA_HOME%\bin\java.exe>>                                              "%GW%"
echo set WRAPPER_JAR=%%~dp0gradle\wrapper\gradle-wrapper.jar>>                            "%GW%"
echo "%%JAVA_EXE%%" -classpath "%%WRAPPER_JAR%%" org.gradle.wrapper.GradleWrapperMain %%*>> "%GW%"
echo exit /b %%ERRORLEVEL%%>>                                                             "%GW%"

REM ── AndroidManifest.xml ────────────────────────────────────
set MF=android\app\src\main\AndroidManifest.xml
echo ^<?xml version="1.0" encoding="utf-8"?^>>                                                                                     "%MF%"
echo ^<manifest xmlns:android="http://schemas.android.com/apk/res/android"^>>>                                                     "%MF%"
echo     ^<uses-permission android:name="android.permission.INTERNET" /^>>>                                                        "%MF%"
echo     ^<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" /^>>>                                            "%MF%"
echo     ^<application android:label="%APP_NAME%" android:icon="@mipmap/ic_launcher" android:usesCleartextTraffic="true" android:theme="@android:style/Theme.Black.NoTitleBar.Fullscreen"^>>> "%MF%"
echo         ^<meta-data android:name="com.google.android.gms.ads.APPLICATION_ID" android:value="ca-app-pub-3940256099942544~3347511713"/^>>>  "%MF%"
echo         ^<activity android:name=".MainActivity" android:configChanges="orientation|screenSize" android:hardwareAccelerated="true" android:exported="true"^>>> "%MF%"
echo             ^<intent-filter^>>>                                                                                                "%MF%"
echo                 ^<action android:name="android.intent.action.MAIN" /^>>>                                                      "%MF%"
echo                 ^<category android:name="android.intent.category.LAUNCHER" /^>>>                                              "%MF%"
echo             ^</intent-filter^>>>                                                                                               "%MF%"
echo         ^</activity^>>>                                                                                                        "%MF%"
echo     ^</application^>>>                                                                                                         "%MF%"
echo ^</manifest^>>>                                                                                                                "%MF%"

REM ── MainActivity.java ──
set JF=android\app\src\main\java\com\ramai\glbviewer\MainActivity.java
(
echo package com.ramai.glbviewer;
echo import android.annotation.SuppressLint;
echo import android.os.Bundle;
echo import android.view.View;
echo import android.webkit.*;
echo import android.widget.FrameLayout;
echo import androidx.appcompat.app.AppCompatActivity;
echo import com.google.android.gms.ads.*;
echo public class MainActivity extends AppCompatActivity {
echo     private WebView webView;
echo     private AdView adView;
echo     @SuppressLint("SetJavaScriptEnabled"^)
echo     @Override
echo     protected void onCreate(Bundle savedInstanceState^) {
echo         super.onCreate(savedInstanceState^);
echo         FrameLayout rootLayout = new FrameLayout(this^);
echo         rootLayout.setLayoutParams(new FrameLayout.LayoutParams(FrameLayout.LayoutParams.MATCH_PARENT, FrameLayout.LayoutParams.MATCH_PARENT^)^);
echo         webView = new WebView(this^);
echo         FrameLayout.LayoutParams webViewParams = new FrameLayout.LayoutParams(FrameLayout.LayoutParams.MATCH_PARENT, FrameLayout.LayoutParams.MATCH_PARENT^);
echo         webView.setLayoutParams(webViewParams^);
echo         WebSettings webSettings = webView.getSettings(^);
echo         webSettings.setJavaScriptEnabled(true^);
echo         webSettings.setDomStorageEnabled(true^);
echo         webSettings.setAllowFileAccess(true^);
echo         webSettings.setAllowContentAccess(true^);
echo         webSettings.setMediaPlaybackRequiresUserGesture(false^);
echo         webSettings.setCacheMode(WebSettings.LOAD_DEFAULT^);
echo         webSettings.setMixedContentMode(WebSettings.MIXED_CONTENT_ALWAYS_ALLOW^);
echo         webView.setLayerType(View.LAYER_TYPE_HARDWARE, null^);
echo         webView.setWebViewClient(new WebViewClient(^) { @Override public boolean shouldOverrideUrlLoading(WebView view, String url^) { return false; } }^);
echo         webView.setWebChromeClient(new WebChromeClient(^)^);
echo         webView.loadUrl("file:///android_asset/www/index.html"^);
echo         rootLayout.addView(webView^);
echo         MobileAds.initialize(this, initializationStatus -^> {}^);
echo         adView = new AdView(this^);
echo         adView.setAdSize(AdSize.BANNER^);
echo         adView.setAdUnitId("ca-app-pub-3940256099942544/6300978111"^);
echo         FrameLayout.LayoutParams adParams = new FrameLayout.LayoutParams(FrameLayout.LayoutParams.WRAP_CONTENT, FrameLayout.LayoutParams.WRAP_CONTENT^);
echo         adParams.gravity = android.view.Gravity.BOTTOM ^| android.view.Gravity.CENTER_HORIZONTAL;
echo         adView.setLayoutParams(adParams^);
echo         rootLayout.addView(adView^);
echo         AdRequest adRequest = new AdRequest.Builder(^).build(^);
echo         adView.loadAd(adRequest^);
echo         setContentView(rootLayout^);
echo     }
echo     @Override public void onBackPressed(^) { if (webView.canGoBack(^)^) { webView.goBack(^); } else { super.onBackPressed(^); } }
echo     @Override protected void onPause(^) { if (adView != null^) { adView.pause(^); } super.onPause(^); }
echo     @Override protected void onResume(^) { super.onResume(^); if (adView != null^) { adView.resume(^); } }
echo     @Override protected void onDestroy(^) { if (adView != null^) { adView.destroy(^); } super.onDestroy(^); }
echo }
) > "%JF%"

REM ── res/values/strings.xml ─────────────────────────────────
set ST=android\app\src\main\res\values\strings.xml
echo ^<?xml version="1.0" encoding="utf-8"?^>>                                                    "%ST%"
echo ^<resources^>>>                                                                               "%ST%"
echo     ^<string name="app_name"^>%APP_NAME%^</string^>>>                                        "%ST%"
echo ^</resources^>>>                                                                              "%ST%"

REM ── app/build.gradle ───────────────────────────────────────
set ABG=android\app\build.gradle
echo apply plugin: 'com.android.application'>                                                     "%ABG%"
echo android {>>                                                                                   "%ABG%"
echo     namespace 'com.ramai.glbviewer'>>                                                        "%ABG%"
echo     compileSdk 34>>                                                                           "%ABG%"
echo     defaultConfig {>>                                                                         "%ABG%"
echo         applicationId "%APP_ID%">>                                                           "%ABG%"
echo         minSdk 21>>                                                                           "%ABG%"
echo         targetSdk 34>>                                                                        "%ABG%"
echo         versionCode 1>>                                                                       "%ABG%"
echo         versionName "1.0">>                                                                   "%ABG%"
echo     }>>                                                                                       "%ABG%"
echo     compileOptions {>>                                                                        "%ABG%"
echo         sourceCompatibility JavaVersion.VERSION_1_8>>                                         "%ABG%"
echo         targetCompatibility JavaVersion.VERSION_1_8>>                                         "%ABG%"
echo     }>>                                                                                       "%ABG%"
echo     aaptOptions { noCompress 'glb', 'gltf', 'bin' }>>                                        "%ABG%"
echo }>>                                                                                           "%ABG%"
echo dependencies {>>                                                                              "%ABG%"
echo     implementation 'androidx.appcompat:appcompat:1.6.1'>>                                    "%ABG%"
echo     implementation 'com.google.android.gms:play-services-ads:22.6.0'>>                       "%ABG%"
echo }>>                                                                                           "%ABG%"

REM ── root build.gradle ──────────────────────────────────────
set RBG=android\build.gradle
echo buildscript {>                                                                                "%RBG%"
echo     repositories { google(); mavenCentral() }>>                                              "%RBG%"
echo     dependencies { classpath 'com.android.tools.build:gradle:8.2.0' }>>                      "%RBG%"
echo }>>                                                                                           "%RBG%"
echo allprojects { repositories { google(); mavenCentral() } }>>                                  "%RBG%"

REM ── settings.gradle ────────────────────────────────────────
echo include ':app'>                                                                               "android\settings.gradle"

REM ── gradle.properties ──────────────────────────────────────
set GP=android\gradle.properties
echo android.useAndroidX=true>                                                                     "%GP%"
echo android.enableJetifier=true>>                                                                 "%GP%"
echo org.gradle.jvmargs=-Xmx2048m -Dfile.encoding=UTF-8>>                                         "%GP%"
echo org.gradle.parallel=true>>                                                                    "%GP%"
echo org.gradle.caching=true>>                                                                     "%GP%"

REM ── Copy web assets ────────────────────────────────────────
echo  [2/4] Copying web assets (this may take a while for large GLB files^)...
copy /Y "viewer.html" "android\app\src\main\assets\www\index.html" >nul
echo        Copying CONTENT directory...
robocopy "CONTENT" "android\app\src\main\assets\www\CONTENT" /E /NFL /NDL /NJH /NJS >nul 2>&1

REM ── SDK components ─────────────────────────────────────────
echo  [3/4] Checking Android SDK components...
call sdkmanager "platforms;android-34" "build-tools;34.0.0" >nul 2>&1

REM ── Build ──────────────────────────────────────────────────
echo  [4/4] Building APK...
echo        (First run: Gradle downloads once to %USERPROFILE%\.gradle^)
echo.
cd android
call gradlew.bat assembleDebug
if errorlevel 1 (
    echo.
    echo [ERROR] Build failed. See Gradle output above.
    cd ..
    pause
    exit /b 1
)
cd ..

REM ── Save APK ───────────────────────────────────────────────
set APK_SRC=android\app\build\outputs\apk\debug\app-debug.apk
set APK_OUT=%APP_NAME%.apk
copy /Y "%APK_SRC%" "%APK_OUT%" >nul

echo.
echo  ================================
echo   BUILD SUCCESSFUL
echo   APK : %APK_OUT%
echo  ================================
echo.

REM ── Check for connected device ─────────────────────────────
adb devices 2>nul | findstr /R "device$" >nul
if errorlevel 1 (
    echo  No device connected. APK saved to %APK_OUT%
    echo  Connect device and run: adb install -r %APK_OUT%
    goto :done
)

echo  Device detected! Installing...
adb install -r "%APK_OUT%" 2>nul
if errorlevel 1 (
    echo  Install failed, trying to uninstall first...
    adb uninstall %APP_ID% >nul 2>&1
    adb install "%APK_OUT%"
    if errorlevel 1 (
        echo  [ERROR] Install failed. APK saved to %APK_OUT%
        goto :done
    )
)

echo  Launching app...
adb shell am start -n %APP_ID%/.MainActivity
echo.
echo  App installed and launched successfully!

:done
echo.
pause
