. ./build_windows.sh target=template_debug optimize=debug use_hot_reload=yes
. ./build_windows.sh target=template_release optimize=speed use_hot_reload=yes
. ./build_linux.sh target=template_debug optimize=debug use_hot_reload=yes
. ./build_linux.sh target=template_release optimize=speed use_hot_reload=yes
. ./build_android.sh target=template_debug optimize=debug use_hot_reload=yes
. ./build_android.sh target=template_release optimize=speed use_hot_reload=yes
