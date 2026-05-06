@echo off
setlocal
set JAVA_EXE=C:\Program Files\Eclipse Adoptium\jdk-21.0.10.7-hotspot\bin\java.exe
set WRAPPER_JAR=%~dp0gradle\wrapper\gradle-wrapper.jar
"%JAVA_EXE%" -classpath "%WRAPPER_JAR%" org.gradle.wrapper.GradleWrapperMain %*
exit /b %ERRORLEVEL%
