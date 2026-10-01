if [ -n "$BASH_VERSION" ]; then
    CXDEVINITSCRIPT=$(realpath "$BASH_SOURCE")
elif [ -n "$ZSH_VERSION" ]; then
    CXDEVINITSCRIPT=$(realpath "${(%):-%N}")
fi

export CXDEVHOME=$(dirname "$CXDEVINITSCRIPT")
export CXDEVSYNCDIR="$CXDEVHOME/dependencies/sapartefacts"

# Include CX DEV environment files
source $CXDEVHOME/helper/format.sh
source $CXDEVHOME/helper/alias.sh
source $CXDEVHOME/helper/artefacts.sh
source $CXDEVHOME/helper/config.sh
source $CXDEVHOME/helper/workspace.sh
source $CXDEVHOME/helper/housekeeping.sh
