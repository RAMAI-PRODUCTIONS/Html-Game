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
echo  HTML to APK Builder
echo  -------------------
echo.

if not exist "index.html" (
    echo [ERROR] index.html not found in root directory.
    pause
    exit /b 1
)

REM ── Ask for app name ───────────────────────────────────────
set /P APP_NAME="  Enter App Name (e.g. football): "
if "%APP_NAME%"=="" set APP_NAME=MyApp

REM Remove spaces from APP_NAME
set APP_NAME=%APP_NAME: =%

set APP_ID=com.ramai.%APP_NAME%

echo.
echo  App Name : %APP_NAME%
echo  Package  : %APP_ID%
echo.

REM ── Step 1: Setup Android project ──────────────────────────
echo  [1/4] Setting up Android project...

md "android\gradle\wrapper" 2>nul
md "android\app\src\main\java\com\ramai\%APP_NAME%" 2>nul
md "android\app\src\main\res\values" 2>nul
md "android\app\src\main\res\mipmap" 2>nul
md "android\app\src\main\res\layout" 2>nul
md "android\app\src\main\assets\www" 2>nul

REM ── Bootstrap Gradle wrapper jar (tiny ~59KB, only once) ───
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

REM ── gradle-wrapper.properties (line by line, no blocks) ────
set GWP=android\gradle\wrapper\gradle-wrapper.properties
echo distributionBase=GRADLE_USER_HOME>                                                    "%GWP%"
echo distributionPath=wrapper/dists>>                                                      "%GWP%"
echo distributionUrl=https\://services.gradle.org/distributions/gradle-8.2-bin.zip>>      "%GWP%"
echo zipStoreBase=GRADLE_USER_HOME>>                                                       "%GWP%"
echo zipStorePath=wrapper/dists>>                                                          "%GWP%"
echo networkTimeout=10000>>                                                                "%GWP%"

REM ── gradlew.bat (expand JAVA_HOME now, use %% for gradlew's own vars) ──
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

REM ── MainActivity.java with AdMob (using PowerShell script) ──
set JF=android\app\src\main\java\com\ramai\%APP_NAME%\MainActivity.java
echo        Generating MainActivity.java...
if not exist "android\app\src\main\java\com\ramai\%APP_NAME%" mkdir "android\app\src\main\java\com\ramai\%APP_NAME%"
powershell -ExecutionPolicy Bypass -File "scripts\gen_admob_mainactivity.ps1" "%JF%" "com.ramai.%APP_NAME%"

if not exist "%JF%" (
    echo [ERROR] MainActivity.java was not generated.
    pause
    exit /b 1
)
echo        MainActivity.java with AdMob OK.

REM ── res/layout/activity_main.xml ───────────────────────────
set LY=android\app\src\main\res\layout\activity_main.xml
echo ^<?xml version="1.0" encoding="utf-8"?^>>                                                    "%LY%"
echo ^<FrameLayout xmlns:android="http://schemas.android.com/apk/res/android">>                   "%LY%"
echo     android:layout_width="match_parent" android:layout_height="match_parent"^>>>             "%LY%"
echo ^</FrameLayout^>>>                                                                            "%LY%"

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
echo     namespace 'com.ramai.%APP_NAME%'>>                                                       "%ABG%"
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
echo        Copying web assets...
copy /Y "index.html" "android\app\src\main\assets\www\index.html" >nul
robocopy "assets" "android\app\src\main\assets\www\assets" /E /NFL /NDL /NJH /NJS >nul 2>&1

REM ── Icon ───────────────────────────────────────────────────
if exist "icon.png" (
    echo  [2/4] Setting app icon...
    copy /Y "icon.png" "android\app\src\main\res\mipmap\ic_launcher.png" >nul
) else (
    echo  [2/4] No icon.png found, skipping.
)

REM ── SDK components ─────────────────────────────────────────
echo  [3/4] Checking Android SDK components...
call sdkmanager "platforms;android-34" "build-tools;34.0.0" >nul 2>&1

REM ── Build ──────────────────────────────────────────────────
echo  [4/4] Building APK...
echo        (First run: Gradle ~102MB downloads once to %USERPROFILE%\.gradle)
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
