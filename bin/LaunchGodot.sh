if ! pwsh --version &> /dev/null; then
	RED='\033[0;31m'
	NC='\033[0m' # No Color
	echo -e "${RED} ~ powershell not installed${NC}"
	echo -e " ~ try installing it with 'sudo snap install powershell --classic'"
	exit 1
fi

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
pwsh -ExecutionPolicy remotesigned -File "$SCRIPT_DIR/LaunchGodot.ps1" "$@"
