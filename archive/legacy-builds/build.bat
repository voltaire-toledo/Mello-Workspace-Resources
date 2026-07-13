@echo off
echo Building Resource DLL...

REM Check for RC compiler
where rc >nul 2>nul
if %errorlevel% neq 0 (
    echo Error: 'rc.exe' not found. Please run this script from a Visual Studio Developer Command Prompt.
    exit /b 1
)

echo Compiling resources...
rc /fo MOResources.res ResourceMap.rc
if %errorlevel% neq 0 (
    echo Resource compilation failed.
    exit /b 1
)

echo Linking DLL...
link /nologo /dll /noentry /machine:x86 /out:MOResources.dll MOResources.res
if %errorlevel% neq 0 (
    echo Linking failed.
    exit /b 1
)

echo Success! MOResources.dll created.