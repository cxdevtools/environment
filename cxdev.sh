if [ -n "$BASH_VERSION" ]; then
    CXDEVINITSCRIPT=$(realpath "$BASH_SOURCE")
elif [ -n "$ZSH_VERSION" ]; then
    CXDEVINITSCRIPT=$(realpath "${(%):-%N}")
fi

export CXDEVHOME=$(dirname "$CXDEVINITSCRIPT")
export CXDEVSYNCDIR="$CXDEVHOME/dependencies/sapartefacts"

# Add each separately installed tool to PATH (tools/<name>/bin).
for _cxdev_tool_bin in "$CXDEVHOME"/tools/*/bin; do
	if [ -d "$_cxdev_tool_bin" ]; then
		case ":$PATH:" in
			*":$_cxdev_tool_bin:"*) ;;
			*) PATH="$_cxdev_tool_bin:$PATH" ;;
		esac
	fi
done
unset _cxdev_tool_bin
export PATH

# Include CX DEV environment files
source $CXDEVHOME/helper/format.sh
source $CXDEVHOME/helper/alias.sh
source $CXDEVHOME/helper/artefacts.sh
source $CXDEVHOME/helper/config.sh
source $CXDEVHOME/helper/workspace.sh
source $CXDEVHOME/helper/housekeeping.sh
