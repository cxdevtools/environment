yGlobalConfig () {
	local ACTION=$1
	if [[ "$ACTION" != "enable" && "$ACTION" != "disable" && "$ACTION" != "list" ]]; then
		echo -e "${_yerror}[ERROR] Action must be enable or disable.${_yclear}"
		_yGlobalConfigHelp
		return 1
	fi

	shift
	if [[ "$ACTION" == "list" ]] || [[ "$#" -eq 0 ]]; then
		_yGlobalConfigList
		return 0
	fi

	for ARG in "$@"; do
		if ! RESOLVED=$(_yResolveProfile "$ARG"); then
			echo -e "${_ywarn}[WARN] Unknown profile: $ARG${_yclear}"
			continue
		fi

		read PROFILE PROFILENAME <<< "$RESOLVED"
		_yApplyProfile "$ACTION" "$PROFILE" "$PROFILENAME"
	done

	if [[ -n "$CXDEV_WORKSPACE_HOME" ]]; then
		echo -e "${_yinfo}[INFO] Applying configuration...${_yclear}"
		yreload
	else
		echo -e "${_ywarn}[WARN] No workspace loaded.${_yclear}"
	fi
}

_yApplyProfile () {
	local ACTION=$1
	local PROFILE=$2
	local PROFILENAME=$3

	local PROFILESHOME="$CXDEVHOME/configuration/profiles"
	local ENABLEDPROFILESHOME="$CXDEVHOME/configuration/enabled"
	local SOURCE="$PROFILESHOME/$PROFILE-$PROFILENAME.properties"
	local TARGET="$ENABLEDPROFILESHOME/$PROFILE-local.properties"

	if [[ ! -f "$SOURCE" ]]; then
		echo -e "${_ywarn}[WARN] Profile $PROFILENAME ($PROFILE) not found.${_yclear}"
		return 1
	fi

	mkdir -p "$ENABLEDPROFILESHOME"

	if [[ "$ACTION" == "enable" ]]; then
		if [[ -f "$TARGET" ]]; then
			echo -e "${_yinfo}[INFO] $PROFILENAME ($PROFILE) already enabled.${_yclear}"
		else
			ln -s "$SOURCE" "$TARGET"
			echo -e "${_yinfo}[INFO] Enabled $PROFILENAME ($PROFILE).${_yclear}"
		fi
	else
		if [[ -f "$TARGET" ]]; then
			rm "$TARGET"
			echo -e "${_yinfo}[INFO] Disabled $PROFILENAME ($PROFILE).${_yclear}"
		else
			echo -e "${_yinfo}[INFO] $PROFILENAME ($PROFILE) already disabled.${_yclear}"
		fi
	fi
}

_yResolveProfile () {
	case "$1" in
		"80" | "localdev")   echo "80 localdev" ;;
		"81" | "ssl")        echo "81 ssl" ;;
		"83" | "backoffice") echo "83 backoffice" ;;
		"84" | "smartedit")  echo "84 smartedit" ;;
		"88" | "sso")        echo "88 sso" ;;
		*) return 1 ;;
	esac
}

_yGlobalConfigHelp () {
	echo
	echo -e         "        usage: yGlobalConfig [action] ([config] [config]...)"
	echo 
	echo -e         "${_ybold}OPTION SUMMARY${_yreset}"
	echo 
	echo -e         "        action          action can be either of the following"
	echo -e         "                        ${_ybold}list${_yreset} - lists configuration profile overview"
	echo -e         "                        ${_ybold}enable${_yreset} - enables the given configuration profile"
	echo -e         "                        ${_ybold}disable${_yreset} - disables the given configuration profile"
	echo -e         "        config          config can be either"
	echo -e         "                        an ID of an existing configuration profile"
	echo -e         "                        an alias of an existing configuration profile"
	echo 
	echo -e         "        Calling yGlobalConfig without options will show all avaliable configuration profiles."
	echo -e "${_yreset}${_yclear}"
}

_yGlobalConfigList () {
	local PROFILESHOME=$CXDEVHOME/configuration/profiles
	local ENABLEDPROFILESHOME=$CXDEVHOME/configuration/enabled

	# For ZSH we need to set the bash_rematch option
	if command -v setopt > /dev/null && [[ ! -o bash_rematch ]]; then
		setopt local_options bash_rematch
	fi

	# Parse and split configuration profiles
	local profileRegEx="^.*\/([^\/]*\/[^\/]*\/(.*)-(.*)\.properties)$"
	echo -e "${_yinfo}[INFO] Available profiles are:${_yclear}"
	echo -e "       +----+---------------+---------+--------------------------------------------------------+"
	echo -e "       + ID + Alias         + Enabled + File                                                   +"
	echo -e "       +----+---------------+---------+--------------------------------------------------------+"
	for i in $(find "$CXDEVHOME/configuration/profiles" -type f -iname "*.properties" | sort -V); do 
		if [[ "$i" =~ $profileRegEx ]]; then
			if [ -f "$CXDEVHOME/configuration/enabled/${BASH_REMATCH[@]:2:1}-local.properties" ]; then
				local PARAMS=(${BASH_REMATCH[@]:2:1} ${BASH_REMATCH[@]:3:1} "true" ${BASH_REMATCH[@]:1:1})
				printf "       | %2d | %-13s | ${_yinfo}%-7s${_yclear} | %-54s |\n" $PARAMS
			else
				local PARAMS=(${BASH_REMATCH[@]:2:1} ${BASH_REMATCH[@]:3:1} "false" ${BASH_REMATCH[@]:1:1})
				printf "       | %2d | %-13s | ${_yerror}%-7s${_yclear} | %-54s |\n" $PARAMS
			fi
		fi
	done
	echo -e "       +----+---------------+---------+--------------------------------------------------------+"
}