scons platform=android %* arch=arm64
@if %ERRORLEVEL% NEQ 0 (pause & exit 1)
