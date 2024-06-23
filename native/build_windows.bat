scons platform=windows %* arch=x86_64
@if %ERRORLEVEL% NEQ 0 (pause & exit 1)
