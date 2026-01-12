@echo off
REM VisiWin 7 Git Merge Driver
REM Routes .vw7 files to VisiWin ProjectCompare and other files to Visual Studio

set REMOTE=%1
set LOCAL=%2
set BASE=%3
set MERGED=%4

set file_ext=%~x1
if "%file_ext%"==".vw7" (
    "C:\Program Files (x86)\INOSOFT GmbH\VisiWin 7\Development\bin\VisiWin7.ProjectCompare.exe" -m %REMOTE% %LOCAL% %MERGED%
) else (
    "C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\IDE\CommonExtensions\Microsoft\TeamFoundation\Team Explorer\vsdiffmerge.exe" %REMOTE% %LOCAL% %BASE% %MERGED% /m
)
