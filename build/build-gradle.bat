@echo off
setlocal EnableDelayedExpansion

echo.
echo ============================================
echo  GLB Viewer - Gradle APK Builder
echo ============================================
echo.

REM Check if viewer.html exists
if not exist "viewer.html" (
    echo [ERROR] viewer.html not found in root directory.
    pause
    exit /b 1
)

REM Check if CONTENT directory exists
if not exist "CONTENT" (
    echo [ERROR] CONTENT directory with GLB files not found.
    pause
    exit /b 1
)

echo [1/3] Checking Gradle wrapper...
if not exist "android-gradle\gradle\wrapper\gradle-wrapper.jar" (
    echo        Downloading Gradle wrapper jar...
    curl -sL -o "android-gradle\gradle\wrapper\gradle-wrapper.jar" "https://github.com/gradle/gradle/raw/v8.2.0/gradle/wrapper/gradle-wrapper.jar"
    if errorlevel 1 (
        echo [ERROR] Failed to download Gradle wrapper. Check internet connection.
        pause
        exit /b 1
    )
    echo        Done.
)

echo [2/3] Preparing assets...
echo        This will copy viewer.html and all GLB files (~%SIZE% MB)
echo        Gradle will handle this automatically during build.

echo [3/3] Building APK with Gradle...
echo        First run: Gradle will download dependencies (~150MB)
echo        This may take a few minutes...
echo.

cd android-gradle

REM Run Gradle build
call gradlew.bat assembleDebug

if errorlevel 1 (
    echo.
    echo [ERROR] Build failed. Check Gradle output above.
    cd ..
    pause
    exit /b 1
)

cd ..

REM Copy APK to root
set APK_SRC=android-gradle\app\build\outputs\apk\debug\app-debug.apk
set APK_OUT=GLBViewer.apk

if exist "%APK_SRC%" (
    copy /Y "%APK_SRC%" "%APK_OUT%" >nul
    
    echo.
    echo ============================================
    echo  BUILD SUCCESSFUL!
    echo ============================================
    echo  APK: %APK_OUT%
    
    REM Get file size
    for %%A in ("%APK_OUT%") do set SIZE=%%~zA
    set /A SIZE_MB=!SIZE! / 1048576
    echo  Size: !SIZE_MB! MB
    echo ============================================
    echo.
    
    REM Check for connected device
    adb devices 2>nul | findstr /R "device$" >nul
    if errorlevel 1 (
        echo  No device connected.
        echo  To install: adb install -r %APK_OUT%
    ) else (
        echo  Device detected! Installing...
        adb install -r "%APK_OUT%" 2>nul
        if errorlevel 1 (
            echo  Install failed, trying to uninstall first...
            adb uninstall com.ramai.glbviewer >nul 2>&1
            adb install "%APK_OUT%"
        )
        
        if not errorlevel 1 (
            echo  Launching app...
            adb shell am start -n com.ramai.glbviewer/.MainActivity
            echo.
            echo  App installed and launched successfully!
        )
    )
) else (
    echo [ERROR] APK not found at expected location.
)

echo.
pause
