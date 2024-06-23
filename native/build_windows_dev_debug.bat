scons platform=windows target=template_debug dev_build=yes optimize=debug arch=x86_64
@if %ERRORLEVEL% NEQ 0 (pause & exit 1)
