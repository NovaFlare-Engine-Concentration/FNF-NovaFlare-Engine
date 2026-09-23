@echo off
rem ============================================================
rem  One-click rebuild of the NovaFlare installer.
rem  (filename is Chinese on purpose; content stays pure ASCII so
rem   cmd can parse it on any locale - no codepage issues)
rem
rem  Workflow: re-export windows build -> run this file.
rem  build.bat now packs payload.rar AUTOMATICALLY from
rem  export\legacy-gc\windows\bin (only the files the game needs;
rem  user data such as crash\ logs\ mods\ is skipped), so the old
rem  manual "create NovaFlare Engine.rar with WinRAR" step is gone.
rem
rem  Tools: WinRAR's Rar.exe is required for the payload step
rem         (the installer embeds UnRAR 7.00 and reads RAR5).
rem ============================================================
setlocal
cd /d "%~dp0"

echo ================================================
echo   NovaFlare Installer - one-click rebuild
echo   (???????? - see file name)
echo ================================================
echo  [1/1] calling NovaFlareEngineInstaller\build.bat ...
echo        (auto-packs payload.rar from the windows build
echo         output, compiles, appends the payload,
echo         verifies the footer, updates dist\)
echo.

call "NovaFlareEngineInstaller\build.bat"
if errorlevel 1 (
  echo.
  echo  [FAILED] build error - see log above.
  pause
  exit /b 1
)

echo.
echo ================================================
echo  DONE. Latest single-file installer:
echo    NovaFlareEngineInstaller\dist\NovaFlareEngine-1.2.1ButLushiFuFixedsss-Installer.exe
for %%F in ("NovaFlareEngineInstaller\dist\NovaFlareEngine-1.2.1ButLushiFuFixedsss-Installer.exe") do echo    size: %%~zF bytes
echo ================================================
pause
endlocal
