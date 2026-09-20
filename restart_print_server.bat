@echo off

set PRGDIR=%~dp0
set HOMEDIR=%PRGDIR%

REM --- Stop existing PrintServerEngine ---
echo Stopping PrintServerEngine...

powershell -Command "Get-CimInstance Win32_Process -Filter \"Name='java.exe'\" | Where-Object { $_.CommandLine -like '*PrintServerEngine*' } | ForEach-Object { Write-Host ('Killing PID ' + $_.ProcessId); Stop-Process -Id $_.ProcessId -Force }"

echo Waiting for process to terminate...
timeout /t 2 /nobreak >nul

REM --- Start PrintServerEngine ---
echo Starting PrintServerEngine...

start "" "S:\seito\jre8\bin\java" ^
 -Dprint_server^
 -Xmx512M^
 -Duser.language=en^
 -XX:+ForceTimeHighResolution^
 -cp %HOMEDIR%*;%HOMEDIR%lib\*;%HOMEDIR%lib\window\64bit\*^
 -Djava.library.path=.\lib\window\64bit^
 -Dwindow.mode=WINDOW^
 -Dwindow.minimize=true^
 -Dcom.sun.management.jmxremote^
 -Djava.rmi.server.hostname=127.0.0.1^
 -Dcom.seito.disable.ms=false^
 -Dawt.useSystemAAFontSettings=on^
 ps.seito.main.PrintServerEngine -p S:/seitodata/config/pos82x/print_server.ini

echo PrintServerEngine restarted.
pause
