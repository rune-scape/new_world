call build_windows.bat target=template_debug optimize=debug use_hot_reload=yes
call build_windows.bat target=template_release optimize=speed use_hot_reload=yes
call build_linux.bat target=template_debug optimize=debug use_hot_reload=yes
call build_linux.bat target=template_release optimize=speed use_hot_reload=yes
call build_android.bat target=template_debug optimize=debug use_hot_reload=yes
call build_android.bat target=template_release optimize=speed use_hot_reload=yes
