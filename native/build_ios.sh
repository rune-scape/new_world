scons platform=ios "$@" || { read -rsp $'Press any key to continue...\n' -n 1; exit 1; }
