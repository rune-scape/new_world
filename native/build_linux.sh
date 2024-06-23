scons platform=linux "$@" arch=x86_64 || { read -rsp $'Press any key to continue...\n' -n 1; exit 1; }
