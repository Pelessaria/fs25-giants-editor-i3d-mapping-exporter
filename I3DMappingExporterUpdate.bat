@echo off
setlocal
set "language=%~2"
if not defined language set "language=de"
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -STA -WindowStyle Hidden -File "%~dp0I3DMappingExporterUpdate.ps1" -TargetXml "%~1" -Language "%language%"
exit /b %errorlevel%