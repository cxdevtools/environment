# Global configurations
CXDEV_GLOBAL_DEPENDENCIES="$CXDEVHOME/dependencies"
CXDEV_GLOBAL_CERTIFICATES="$CXDEVHOME/certificates"
CXDEV_GLOBAL_CONFIGURATIONS="$CXDEVHOME/configuration"

yLoadWorkspace () {
	echo -e "${_yinfo}[INFO] CXDEV Tools Environment Setup for SAP Commerce Cloud${_yclear}"

	if [[ "" == "$1" ]]; then
		echo -e "${_yerror}[ERROR] CXDEV Tools cannot apply SAP Commerce workspace settings due to missing ${_ybold}path${_yreset} parameter!${_yclear}"
		_yLoadWorkspaceHelp
		return 1
	fi

	if [ ! -d "$1" ]; then
		echo -e "${_yerror}[ERROR] CXDEV Tools cannot find a SAP Commerce workspace at ${_yunderline}$1${_yreset}.${_yclear}"
		_yLoadWorkspaceHelp
		return 1
	fi

	# Workspace information
	CXDEV_WORKSPACE_HOME=$(realpath "$1" 2>/dev/null)
	CXDEV_WORKSPACE_NAME=
	if [[ "" != "$2" ]]; then
		CXDEV_WORKSPACE_NAME=$2
	else 
		CXDEV_WORKSPACE_NAME=`/usr/bin/basename $1`
	fi

	# Link SAP artefact dependencies
	if [ -d "$CXDEV_GLOBAL_DEPENDENCIES" ]; then
		if [ -L "$CXDEV_WORKSPACE_HOME/dependencies" ] && [[ $(readlink "$CXDEV_WORKSPACE_HOME/dependencies") == "$CXDEV_GLOBAL_DEPENDENCIES/sapartefacts" ]]; then
			echo -e "${_yinfo}[INFO] Global dependencies folder already linked, no optimization needed.${_yclear}"
		else
			if [ -d "$CXDEV_WORKSPACE_HOME/dependencies" ]; then 
				echo -e "${_yinfo}[INFO] Relink dependencies to global dependencies folder to save disk space!${_yclear}"
				rm -Rf "$CXDEV_WORKSPACE_HOME/dependencies"
			else
				echo -e "${_yinfo}[INFO] Link dependencies to global dependencies folder to save disk space!${_yclear}"
			fi
			ln -s "$CXDEV_GLOBAL_DEPENDENCIES/sapartefacts" "$CXDEV_WORKSPACE_HOME/dependencies"
		fi
	fi
	
	# Link global certificates
	if [ -d "$CXDEV_GLOBAL_CERTIFICATES" ]; then
		if [ -L "$CXDEV_WORKSPACE_HOME/certificates" ] && [[ $(readlink "$CXDEV_WORKSPACE_HOME/certificates") == "$CXDEV_GLOBAL_CERTIFICATES" ]]; then
			echo -e "${_yinfo}[INFO] Global certificates folder already linked, no optimization needed.${_yclear}"
		else
			if [ -d "$CXDEV_WORKSPACE_HOME/certificates" ]; then 
				echo -e "${_yinfo}[INFO] Use local certificates folder from workspace configuration! (Remove and rerun to use global certificates instead)${_yclear}"
			else 
				if [ -L "$CXDEV_WORKSPACE_HOME/certificates" ]; then 
					echo -e "${_yinfo}[INFO] Relink certificates to global certificates folder!${_yclear}"
					rm -Rf "$CXDEV_WORKSPACE_HOME/certificates"
				else
					echo -e "${_yinfo}[INFO] Link certificates to global certificates folder!${_yclear}"
				fi
				ln -s "$CXDEV_GLOBAL_CERTIFICATES" "$CXDEV_WORKSPACE_HOME/certificates"
			fi
		fi
	fi
	
	# Load Java environment
	CXDEV_JAVA_VERSION=
	CXDEV_JAVA_VERSION_FILE=$(find "$CXDEV_WORKSPACE_HOME" -maxdepth 3 -iname '.java-version' | head -1)
	if [ -f "$CXDEV_JAVA_VERSION_FILE" ]; then
		CXDEV_JAVA_VERSION=$(cat "$CXDEV_JAVA_VERSION_FILE")
		echo -e "${_yinfo}[INFO] Java version ${_ybold}$CXDEV_JAVA_VERSION${_yreset} defined in: ${_yunderline}$CXDEV_JAVA_VERSION_FILE${_yreset}${_yclear}"
		SDKMAN_JAVA_HOME=$(sdk home java $CXDEV_JAVA_VERSION)
		if [ ! -d "$SDKMAN_JAVA_HOME" ]; then
			echo -e "${_yinfo}[INFO] Java version ${_ybold}$CXDEV_JAVA_VERSION${_yreset} not available! Trying to install with SDKman:${_yclear}"
			echo -ne "${_ydebug}"
			sdk install java $CXDEV_JAVA_VERSION
			echo -ne "${_yclear}"

			SDKMAN_JAVA_HOME=$(sdk home java $CXDEV_JAVA_VERSION)
			if [ ! -d "$SDKMAN_JAVA_HOME" ]; then
				echo -e "${_yerror}[ERROR] Java version ${_ybold}$CXDEV_JAVA_VERSION${_yreset} cannot be installed!${_yclear}"
				return 2
			else
				echo -e "${_yinfo}[INFO] Java version ${_ybold}$CXDEV_JAVA_VERSION${_yreset} successfully installed with SDKman.${_yclear}"
			fi
		fi

		echo -e "${_yinfo}[INFO] Loading Java version ${_ybold}$CXDEV_JAVA_VERSION${_yreset} using SDKman.${_yclear}"
		sdk use java $CXDEV_JAVA_VERSION 2>&1 >> /dev/null
	else
		echo -e "${_ywarn}[WARN] No Java version configured within workspace, missing file: ${_yunderline}.java-version${_yclear}"
		if command -v java > /dev/null; then
			echo -e "${_ywarn}[WARN] Fallback to Java version configured in system environment!${_yclear}"
			CXDEV_JAVA_VERSION=$(java -version 2>&1 | head -1)
			echo -e "${_yinfo}[INFO] Detected Java version is ${_ybold}$CXDEV_JAVA_VERSION${_yclear}"
			echo -e "${_ywarn}[WARN] ${_yblink}Please verify that the Java version is the correct for your repository!${_yclear}"
		else
			echo -e "${_yerror}[ERROR] Cannot fallback to Java version of system, Java was not found!${_yclear}"
			return 2
		fi
	fi

	# Load node environment
	CXDEV_NODE_VERSION=
	CXDEV_NODE_VERSION_FILE=$(find "$CXDEV_WORKSPACE_HOME" -maxdepth 3 -iname '.node-version' | head -1)
	if [ -f "$CXDEV_NODE_VERSION_FILE" ]; then
		CXDEV_NODE_VERSION=$(cat "$CXDEV_NODE_VERSION_FILE")
		echo -e "${_yinfo}[INFO] Node version ${_ybold}$CXDEV_NODE_VERSION${_yreset} defined in: ${_yunderline}$CXDEV_NODE_VERSION_FILE${_yclear}"
		echo -e "${_yinfo}[INFO] Loading Node version ${_ybold}$CXDEV_NODE_VERSION${_yreset} using nodenv.${_yclear}"
		if ! nodenv shell $CXDEV_NODE_VERSION 2>&1 >> /dev/null ; then
			echo -e "${_ywarn}[WARN] Node version ${_ybold}$CXDEV_NODE_VERSION${_yreset} not available! Trying to install with nodenv:${_yclear}"
			echo -ne "${_ydebug}"
			nodenv install $CXDEV_NODE_VERSION
			echo -ne "${_yclear}"

			if ! nodenv shell $CXDEV_NODE_VERSION 2>&1 >> /dev/null ; then
				echo -e "${_ywarn}[WARN] Node version ${_ybold}$CXDEV_NODE_VERSION${_yreset} cannot be installed!${_yclear}"
				return 2
			else
				echo -e "${_yinfo}[INFO] Node version ${_ybold}$CXDEV_NODE_VERSION${_yreset} successfully installed with nodenv.${_yclear}"
			fi
		fi
	elif [ -d "$CXDEV_WORKSPACE_HOME/js-storefront" ]; then
		echo -e "${_ywarn}[WARN] No node version configured within workspace, missing file: ${_yunderline}.node-version${_yclear}"
		echo -e "${_ywarn}[WARN] Fallback to node version configured in system environment!${_yclear}"
		CXDEV_NODE_VERSION=$(nodenv version-name)
		echo -e "${_yinfo}[INFO] Detected node version is ${_ybold}$CXDEV_NODE_VERSION${_yclear}"
		echo -e "${_ywarn}[WARN] ${_yblink}Please verify that the node version is the correct for your project!${_yclear}"
	fi

	# Load gradle environment
	CXDEV_GRADLE_VERSION=
	if [ -f "$CXDEV_WORKSPACE_HOME/gradlew" ]; then
		CXDEV_GRADLE_VERSION=$("$CXDEV_WORKSPACE_HOME/gradlew" --version | grep "^Gradle " | awk '{print $2}')
		echo -e "${_yinfo}[INFO] Gradle wrapper found, gradle version: ${CXDEV_GRADLE_VERSION}!${_yclear}"
	else
		echo -e "${_yinfo}[WARN] No gradle wrapper found!${_yclear}"
		echo -e "${_ywarn}[WARN] ${_yblink}Please configure a gradle wrapper for your project!${_yclear}"
	fi

	# Detect platform structure (supported are classic, embedded or CCv2)
	CXDEV_PLATFORM_HOME=$CXDEV_WORKSPACE_HOME/server/hybris/bin/platform
	CXDEV_PLATFORM_HOME_ALTERNATIVE=$CXDEV_WORKSPACE_HOME/hybris/bin/platform
	if [ -d "$CXDEV_PLATFORM_HOME_ALTERNATIVE" ]; then
		CXDEV_PLATFORM_HOME=$CXDEV_PLATFORM_HOME_ALTERNATIVE
	fi
	CXDEV_PLATFORM_HOME_CCV2=$CXDEV_WORKSPACE_HOME/core-customize/hybris/bin/platform
	if [ -d "$CXDEV_WORKSPACE_HOME/core-customize" ]; then
		echo -e "${_yinfo}[INFO] Cloud repository structure detected!${_yclear}"
		CXDEV_PLATFORM_HOME=$CXDEV_PLATFORM_HOME_CCV2

		ySyncArtefacts "$CXDEV_WORKSPACE_HOME/core-customize/manifest.json"
	fi

	# Load SAP Commerce platform environment
	if [ -d "$CXDEV_PLATFORM_HOME" ]; then
		echo -e "${_yinfo}[INFO] SAP Commerce installation found at: ${_yunderline}$CXDEV_PLATFORM_HOME${_yclear}"

		# Load Ant environment
		if [ -f "$CXDEV_PLATFORM_HOME/setantenv.sh" ]; then
			echo -e "${_yinfo}[INFO] Loading Apache ant settings from platform.${_yclear}"
			echo -ne "${_ydebug}"
			cd "$CXDEV_PLATFORM_HOME"
			chmod +x setantenv.sh
			source setantenv.sh 2>&1 > >( _yindent )
			echo -ne "${_yclear}"
		else
			echo -e "${_ywarn}[WARN] ${_yblink}No Apache ant settings found, platform not installed correctly. Consider to re-run ysetup.${_yclear}"
		fi

		# Load SAP Commerce configuration
		if [ -f "$CXDEV_PLATFORM_HOME/env.properties" ]; then
			echo -e "${_yinfo}[INFO] Environment configuration found at: ${_yunderline}$CXDEV_PLATFORM_HOME/env.properties${_yclear}"
			RELATIVE_CONFIG_DIR=$(cat "$CXDEV_PLATFORM_HOME/env.properties" 2>/dev/null | grep HYBRIS_CONFIG_DIR | sed "s#HYBRIS_CONFIG_DIR=\\\${platformhome}#.#" | tr -d '\r\n')
			CXDEV_CONFIG_DIR=$(realpath "$CXDEV_PLATFORM_HOME/$RELATIVE_CONFIG_DIR" 2>/dev/null)
		else
			echo -e "${_yinfo}[WARN] No environment configuration found at: ${_yunderline}$CXDEV_PLATFORM_HOME/env.properties${_yclear}"
			RELATIVE_CONFIG_DIR=../../config
			CXDEV_CONFIG_DIR=$(realpath "$CXDEV_PLATFORM_HOME/$RELATIVE_CONFIG_DIR" 2>/dev/null)
		fi
		echo -e "${_yinfo}[INFO] Using configuration folder at: ${_yunderline}$CXDEV_CONFIG_DIR${_yclear}"
		if [ -d "$CXDEV_CONFIG_DIR/local-config" ]; then
			CXDEV_OPT_CONFIG_DIR="$CXDEV_CONFIG_DIR/local-config"
			echo -e "${_yinfo}[INFO] Additional local configuration found at: ${_yunderline}$CXDEV_OPT_CONFIG_DIR${_yclear}"
			
			# Relink global configuration profiles
			ENABLEDPROFILESHOME=$CXDEV_GLOBAL_CONFIGURATIONS/enabled
			echo -e "${_yinfo}[INFO] Relink global configuration profiles from: ${_yunderline}$ENABLEDPROFILESHOME${_yclear}"

			[ -f "$CXDEV_OPT_CONFIG_DIR/80-local.properties" ] && rm -f "$CXDEV_OPT_CONFIG_DIR/80-local.properties"
			[ -f "$CXDEV_OPT_CONFIG_DIR/81-local.properties" ] && rm -f "$CXDEV_OPT_CONFIG_DIR/81-local.properties"
			[ -f "$CXDEV_OPT_CONFIG_DIR/82-local.properties" ] && rm -f "$CXDEV_OPT_CONFIG_DIR/82-local.properties"
			[ -f "$CXDEV_OPT_CONFIG_DIR/83-local.properties" ] && rm -f "$CXDEV_OPT_CONFIG_DIR/83-local.properties"
			[ -f "$CXDEV_OPT_CONFIG_DIR/84-local.properties" ] && rm -f "$CXDEV_OPT_CONFIG_DIR/84-local.properties"
			[ -f "$CXDEV_OPT_CONFIG_DIR/85-local.properties" ] && rm -f "$CXDEV_OPT_CONFIG_DIR/85-local.properties"
			[ -f "$CXDEV_OPT_CONFIG_DIR/86-local.properties" ] && rm -f "$CXDEV_OPT_CONFIG_DIR/86-local.properties"
			[ -f "$CXDEV_OPT_CONFIG_DIR/87-local.properties" ] && rm -f "$CXDEV_OPT_CONFIG_DIR/87-local.properties"
			[ -f "$CXDEV_OPT_CONFIG_DIR/88-local.properties" ] && rm -f "$CXDEV_OPT_CONFIG_DIR/88-local.properties"
			[ -f "$CXDEV_OPT_CONFIG_DIR/89-local.properties" ] && rm -f "$CXDEV_OPT_CONFIG_DIR/89-local.properties"
			
			if [ -d "$ENABLEDPROFILESHOME" ]; then
				find "$ENABLEDPROFILESHOME" -type l -iname "8*-local.properties" | xargs -I {} cp -R {} "$CXDEV_OPT_CONFIG_DIR"
			fi
		else
			echo -e "${_yinfo}[INFO] No optional ${_ybold}local-config${_yreset} folder found at in your config folder.${_yclear}"
			echo -e "${_yinfo}[INFO] ${_yblink}Consider updating your workspace to make use of local-config folder!${_yclear}"
			CXDEV_OPT_CONFIG_DIR=
		fi

		# Exchange SAP JCO Library (if necessary)
		SAPJCO_LIB_PATH=$(realpath "$CXDEV_PLATFORM_HOME/../modules/sap-framework-core/sapcorejco/lib" 2>/dev/null)
		if [ -d "$SAPJCO_LIB_PATH" ]; then
			echo -e "${_yinfo}[INFO] SAP JCO Library found at: ${_yunderline}$SAPJCO_LIB_PATH${_yclear}"
			OS=$(/usr/bin/uname)
			CPU_ARCHITECTURE=$(/usr/bin/uname -m)
			if [ -d "$CXDEV_GLOBAL_DEPENDENCIES/sapjco/current/" ]; then
				if [[ "$OS" == "Darwin" && "$CPU_ARCHITECTURE" == "arm64" ]]; then
					echo -e "${_yinfo}[INFO] $OS/$CPU_ARCHITECTURE detected, replacing JCO Library with version from: ${_yunderline}$CXDEV_GLOBAL_DEPENDENCIES/sapjco/current${_yclear}"
					cp -f "$(find $CXDEV_GLOBAL_DEPENDENCIES/sapjco/current/ -type f -name '*.jar')" "$SAPJCO_LIB_PATH"
					cp -f "$(find $CXDEV_GLOBAL_DEPENDENCIES/sapjco/current/ -type f -name '*.mf')" "$SAPJCO_LIB_PATH"
					cp -f "$(find $CXDEV_GLOBAL_DEPENDENCIES/sapjco/current/ -type f -name '*.dylib')" "$SAPJCO_LIB_PATH"
				fi
				if [[ "$OS" == "Linux" && "$CPU_ARCHITECTURE" == "arm64" ]]; then
					echo -e "${_yinfo}[INFO] $OS/$CPU_ARCHITECTURE detected, replacing JCO Library with version from: ${_yunderline}$CXDEV_GLOBAL_DEPENDENCIES/sapjco/current${_yclear}"
					cp -f "$(find $CXDEV_GLOBAL_DEPENDENCIES/sapjco/current/ -type f -name '*.jar')" "$SAPJCO_LIB_PATH"
					cp -f "$(find $CXDEV_GLOBAL_DEPENDENCIES/sapjco/current/ -type f -name '*.mf')" "$SAPJCO_LIB_PATH"
					cp -f "$(find $CXDEV_GLOBAL_DEPENDENCIES/sapjco/current/ -type f -name '*.so')" "$SAPJCO_LIB_PATH"
				fi
			elif [[ "$CPU_ARCHITECTURE" == "arm64" ]]; then
				echo -e "${_yinfo}[INFO] No SAPJCO library found at ${_ybold}$CXDEV_GLOBAL_DEPENDENCIES/sapjco/current${_yreset}.${_yclear}"
				echo -e "${_ywarn}[WARN] ${_yblink}Consider downloading a SAPJCO library for your system architecture, see README file!${_yclear}"
			fi
		fi
	else
		echo -e "${_ywarn}[WARN] No hybris installation found at: ${_yunderline}$CXDEV_PLATFORM_HOME${_yclear}"
		CXDEV_PLATFORM_HOME=
		CXDEV_CONFIG_DIR=
		CXDEV_OPT_CONFIG_DIR=
	fi

	# Load storefront configuration
	CXDEV_STOREFRONT_HOME=
	if [ -d "$CXDEV_WORKSPACE_HOME/js-storefront" ]; then
		CXDEV_STOREFRONT_HOME=$(find "$CXDEV_WORKSPACE_HOME/js-storefront" -maxdepth 1 -type d -not -iname "js-storefront" -not -iname "bootstrap" -not -iname "build")
		echo -e "${_yinfo}[INFO] Composable storefront found at: ${_yunderline}$CXDEV_STOREFRONT_HOME${_yclear}"
	fi

	# Switch to workspace
	cd "$CXDEV_WORKSPACE_HOME"
	echo -e "${_yinfo}[INFO] Switched to workspace location: ${_yunderline}$CXDEV_WORKSPACE_HOME${_yclear}"
	echo -e "${_yinfo}[INFO] CXDEV Tools Environment Setup finished.${_yclear}"
	echo -n -e "\033]0;${CXDEV_WORKSPACE_NAME}\007"

	yShowWorkspace > >( _yindent )
	
	# Export environment variables
	export CXDEV_WORKSPACE_HOME
	export CXDEV_WORKSPACE_NAME
	export CXDEV_JAVA_VERSION
	export CXDEV_JAVA_VERSION_FILE
	export CXDEV_NODE_VERSION
	export CXDEV_NODE_VERSION_FILE
	export CXDEV_PLATFORM_HOME
	export CXDEV_CXDEV_CONFIG_DIR
	export CXDEV_OPT_CONFIG_DIR
	export CXDEV_STOREFRONT_HOME
	export CXDEV_GRADLE_VERSION
}

yShowWorkspace () {
	echo -e "${_yinfo}"
	echo -e "${_ybold}Workspace Overview${_yreset}"
	echo -e "==============================================================================="
	echo -e "${_ybold}Workspace name${_yreset}           ${_yitalic}$CXDEV_WORKSPACE_NAME${_yreset}"
	echo -e "${_ybold}Workspace path${_yreset}           ${_yunderline}$CXDEV_WORKSPACE_HOME${_yreset}"
	echo -e "==============================================================================="
	echo -e "${_ybold}Platform home${_yreset}            ${_yunderline}$CXDEV_PLATFORM_HOME${_yreset}"
	echo -e "${_ybold}Hybris Configuration${_yreset}     ${_yunderline}$CXDEV_OPT_CONFIG_DIR${_yreset}"
	echo -e "${_ybold}Optional Configuration${_yreset}   ${_yunderline}$CXDEV_OPT_CONFIG_DIR${_yreset}"
	echo -e "${_ybold}Storefront home${_yreset}          ${_yunderline}$CXDEV_STOREFRONT_HOME${_yreset}"
	echo -e "==============================================================================="
	if command -v jq > /dev/null; then
		MANIFEST_FILE=$CXDEV_WORKSPACE_HOME/core-customize/manifest.json
		if [ -f "$MANIFEST_FILE" ]; then
			COMMERCESUITE_VERSION=$(jq '.commerceSuiteVersion' -r $MANIFEST_FILE)
			echo -e "SAP Commerce Suite (in manifest): $COMMERCESUITE_VERSION${_yreset}"
			echo -e "Extension Packs (in manifest):"
			for i in $(jq '.extensionPacks[]?.name' -c -r "$MANIFEST_FILE"); do
				EXTPACK_NAME=$i
				EXTPACK_VERSION=$(jq '.extensionPacks[]? | select(.name == "'${EXTPACK_NAME}'") | .version' -c -r "$MANIFEST_FILE")
				echo -e " - extension pack: $EXTPACK_NAME (version: $EXTPACK_VERSION)"
			done
			echo -e "==============================================================================="
		fi
	fi
	echo -e "${_ybold}Java version (detected)${_yreset}   ${_yitalic}$CXDEV_JAVA_VERSION${_yreset}"
	echo -e "${_ybold}Java version file${_yreset}         ${_yitalic}$CXDEV_JAVA_VERSION_FILE${_yreset}"
	echo -e "${_ybold}Node version (detected)${_yreset}   ${_yitalic}$CXDEV_NODE_VERSION${_yreset}"
	echo -e "${_ybold}Node version file${_yreset}         ${_yitalic}$CXDEV_NODE_VERSION_FILE${_yreset}"
	echo -e "${_ybold}Gradle version (detected)${_yreset} ${_yitalic}$CXDEV_GRADLE_VERSION${_yreset}"
	echo -e "==============================================================================="
	echo -e "${_yclear}"
}

_yLoadWorkspaceHelp () {
	echo
	echo -e         "        usage: yLoadWorkspace path [name]"
	echo 
	echo -e         "${_ybold}OPTION SUMMARY${_yreset}"
	echo 
	echo -e         "        path            the workspace path, typically the root directory"
	echo -e         "                        of the project's git repository used by SAP!"
	echo -e         "                        This folder should contain the root directories"
	echo -e         "                        ${_ybold}'core-customize'${_yreset} and optional 'js-storefront'."
	echo -e         "        name            the workspace name (optional parameter)"
	echo -e         "                        the name is used"
	echo -e         "                        - within the log messages"
	echo -e         "                        - title of the terminal window"
	echo -e "${_yreset}${_yclear}"
}