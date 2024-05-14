@REM ()(:) #
@REM "
@echo [running as windows batch script]
@powershell.exe -ExecutionPolicy remotesigned -File "%~dp0bin/LaunchGodot.ps1" %* -Project "%~dp0project.godot"
@EXIT /B
@REM "
echo "[running as linux bash script]"
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
"$SCRIPT_DIR/bin/LaunchGodot.sh" "$@" -Project "$SCRIPT_DIR/project.godot"
