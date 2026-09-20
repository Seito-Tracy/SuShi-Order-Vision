@echo off

REM Stop the PrintServerEngine Java process
echo Stopping PrintServerEngine...

powershell -Command "Get-CimInstance Win32_Process -Filter \"Name='java.exe'\" | Where-Object { $_.CommandLine -like '*PrintServerEngine*' } | ForEach-Object { Write-Host ('Killing PID ' + $_.ProcessId); Stop-Process -Id $_.ProcessId -Force }"

echo Done.
pause
