@echo off
set WORKDIR=%CD%\client
set game=run\debug\win32\GloryProject.exe
start %game% -workdir %WORKDIR% -resolution 1280x720 -position 400,180
exit
