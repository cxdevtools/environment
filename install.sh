#!/bin/bash
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#

# Helper variables
cxdev_bashrc="${HOME}/.bashrc"
cxdev_zshrc="${ZDOTDIR:-${HOME}}/.zshrc"

# Global variables
export CXDEV_DOWNLOAD_URL="https://github.com/cxdevtools/environment/archive/refs/tags/"
export CXDEV_VERSION="1.3.5"
export CXDEV_HASH="daa22017c63c8d6408546453ace1dcfa"
export CXDEV_INSTALL_DIR="${CXDEV_INSTALL_DIR:-$HOME/.cxdev}"

_installCXDEVEnvironment () {
	echo "  ___  _  _  ____  ____  _  _ "
	echo " / __)( \\/ )(    \\(  __)/ )( \\"
	echo "( (__  )  (  ) D ( ) _) \\ \\/ /"
	echo " \\___)(_/\\_)(____/(____) \\__/ "
	echo "                   .__                                            __   ";
	echo "  ____   _______  _|__|______  ____   ____   _____   ____   _____/  |_ ";
	echo "_/ __ \\ /    \\  \\/ /  \\_  __ \\/  _ \\ /    \\ /     \\_/ __ \\ /    \\   __\\";
	echo "\\  ___/|   |  \\   /|  ||  | \\(  <_> )   |  \\  Y Y  \\  ___/|   |  \\  |  ";
	echo " \\___  >___|  /\\_/ |__||__|   \\____/|___|  /__|_|  /\\___  >___|  /__|  ";
	echo "     \\/     \\/                           \\/      \\/     \\/     \\/      ";
	echo ""
	echo "Welcome to CXDEV environment installer, v${CXDEV_VERSION}"
	echo ""

	# Check if already installed
	if [ -f "$CXDEV_INSTALL_DIR/.version" ]; then
		installedVersion=$(cat $CXDEV_INSTALL_DIR/.version)

		echo "You already have CXDEV environment installed."
		echo "- Path   : ${CXDEV_INSTALL_DIR}"
		echo "- Version: ${installedVersion}"
		echo ""

		if [[ "$installedVersion" == "$CXDEV_VERSION" ]]; then
			echo "This version is already installed."
			exit 0
		else
			runUpdate=$(_readYesNo "Do you want us to update your CXDEV environment with version ${CXDEV_VERSION}? [y/N] " "N")
			if [[ "Y" != "$runUpdate" && "y" != "$runUpdate" ]]; then
				echo "Installer aborted, CXDEV environment was not updated."
				exit 0
			else
				find ${CXDEV_INSTALL_DIR} -type f -not \( -name "dependencies" -prune \) -exec rm -rf {} \;
			fi
		fi
	fi

	# Sanity checks
	echo "Checking the following dependencies for CXDEV environment:"
	declare -i unresolved_dependencies=0

	if type awk 2>&1 > /dev/null ; then
		echo "- awk found!"
	else
		unresolved_dependencies+=1
		echo "- awk not found!"
	fi

	if type curl 2>&1 > /dev/null ; then
		echo "- curl found!"
	else
		unresolved_dependencies+=1
		echo "- curl not found!"
	fi

	if type md5sum 2>&1 > /dev/null ; then
		echo "- md5sum found!"
	else
		unresolved_dependencies+=1
		echo "- md5sum not found!"
	fi

	if type openssl 2>&1 > /dev/null ; then
		echo "- openssl found!"
	else
		unresolved_dependencies+=1
		echo "- openssl not found!"
	fi

	if type sed 2>&1 > /dev/null ; then
		echo "- sed found!"
	else
		unresolved_dependencies+=1
		echo "- sed not found!"
	fi

	if type unzip 2>&1 > /dev/null ; then
		echo "- unzip found!"
	else
		unresolved_dependencies+=1
		echo "- unzip not found!"
	fi

	if [ ! -z "$SDKMAN_DIR" ] ; then
		echo "- SDKman found!"
	else
		echo "- SDKman not found!"
		installSDKman=$(_readYesNo "  Do you want us to install SDKman for you? [Y/n] " "Y")
		if [[ "n" == "$installSDKman" || "N" == "$installSDKman" ]]; then
			echo "  SDKman installation skipped!"
			unresolved_dependencies+=1
		elif ! _installSDKman ; then
			unresolved_dependencies+=1
		fi
	fi

	if type nodenv 2>&1 > /dev/null ; then
		echo "- nodenv found!"
	else
		echo "- nodenv not found!"
		installNodenv=$(_readYesNo "  Do you want us to install nodenv for you? [Y/n] " "Y")
		if [[ "n" == "$installNodenv" || "N" == "$installNodenv" ]]; then
			echo "  nodenv installation skipped!"
			unresolved_dependencies+=1
		elif ! _installNodEnv; then
			unresolved_dependencies+=1
		fi
	fi

	if [ "$unresolved_dependencies" != "0" ]; then
		echo "$unresolved_dependencies unresolved dependencies."
		echo "Please install all dependencies on your system using your favourite package manager and then restart the installer."
		echo "- Linux example: sudo apt install curl jq openssl"
		echo "- MacOS example: brew install curl jq openssl"
		exit
	fi

	echo ""
	echo "Attempt to install CXDEV environment"
	echo "- version : ${CXDEV_VERSION}"
	echo "- location: ${CXDEV_INSTALL_DIR}"
	echo ""
    
	# Create structure
	mkdir -p $CXDEV_INSTALL_DIR
	mkdir -p $CXDEV_INSTALL_DIR/tmp

	# Download
	echo "Fetch CXDEV environment from: ${CXDEV_DOWNLOAD_URL}${CXDEV_VERSION}.zip"
	cxdev_zip_file="${CXDEV_INSTALL_DIR}/tmp/cxdev-${CXDEV_VERSION}.zip"
	curl --fail --location -o "$cxdev_zip_file" "${CXDEV_DOWNLOAD_URL}${CXDEV_VERSION}.zip"

	# check integrity
	ARCHIVE_OK=$(unzip -qt "$cxdev_zip_file" | grep 'No errors detected in compressed data')
	ARCHIVE_INTEGRITY=($(md5sum "$cxdev_zip_file"))
	if [[ -z "$ARCHIVE_OK" || "$ARCHIVE_INTEGRITY" != "$CXDEV_HASH" ]]; then
		echo "Downloaded ZIP archive is corrupt."
		echo "- Are you connected to the internet?"
		echo "- Are you using a proxy server?"
		echo "- Is the downloaded file valid?"
		exit 1
	fi

	# extract archive
	echo "Extract successfully downloaded ZIP archive."
	unzip -qo "$cxdev_zip_file" -d "$CXDEV_INSTALL_DIR/tmp"

	# copy over files
	echo "Copy files to installation location."
	cp -r "$CXDEV_INSTALL_DIR/tmp/environment-$CXDEV_VERSION/." "$CXDEV_INSTALL_DIR"

	# recreate private key
	rm -f "$CXDEV_INSTALL_DIR/certificates/local.cxdev.me.key"
	KEYPASS=$(grep "^tomcat\\.ssl\\.keystore\\.password=" "${CXDEV_INSTALL_DIR}/configuration/profiles/81-ssl.properties" | awk '{split($0, a, "="); print a[2]}')
	openssl pkcs12 -in "$CXDEV_INSTALL_DIR/certificates/local.cxdev.me.p12" -passin pass:$KEYPASS -nodes -nocerts -out "$CXDEV_INSTALL_DIR/tmp/local.cxdev.me.key"
	tail -n +5 "$CXDEV_INSTALL_DIR/tmp/local.cxdev.me.key" > $CXDEV_INSTALL_DIR/certificates/local.cxdev.me.key
	
	# store version
	echo "$CXDEV_VERSION" > "$CXDEV_INSTALL_DIR/.version"

	# clean up
	echo "Cleaning up temporary files."
	rm -rf "$CXDEV_INSTALL_DIR/tmp"

	# link in profile
	cxdev_init_snippet=$(cat <<-END
# CXDEV Environment
source "$CXDEV_INSTALL_DIR/cxdev.sh"
#export CXDEVSYNCDIR="/mnt/sapartefacts"
END
)
	if [ -w $cxdev_zshrc ] && ! grep -q "cxdev.sh" "$cxdev_zshrc"; then
		echo "Adding cxdev initialization snippet to: $cxdev_zshrc"
		echo -e "\n$cxdev_init_snippet" >> "$cxdev_zshrc"
	fi
	if [ -w $cxdev_bashrc ] && ! grep -q "cxdev.sh" "$cxdev_bashrc"; then
		echo "Adding cxdev initialization snippet to: $cxdev_bashrc"
		echo -e "\n$cxdev_init_snippet" >> "$cxdev_bashrc"
	fi

	echo ""
	echo "CXDEV environment setup is done!"
	echo ""
	echo "Now, you may want to set your CXDEVSYNCDIR in your terminal configuration file (.bashrc or .zshrc) to point to a shared folder (eg. OneDrive)."
	echo ""
	echo "Afterwards, please open a new terminal, or run the following in the existing one:"
	echo ""
	echo "   source \"${CXDEV_INSTALL_DIR}/cxdev.sh\""
	echo ""
	echo "Thank you for using CXDEV environment :)"
	echo ""
}

_readYesNo () {
	local prompt="$1"
	local default="$2"
	local answer

	if [[ -n "$NONINTERACTIVE" ]]; then
		answer="Y"
	else
		read -r -p "$prompt" answer </dev/tty
	fi

	if [[ -z "$answer" ]]; then
		answer="$default"
	fi

	echo "$answer"
}

_installSDKman () {
	echo "==============================================================================="
	echo "Trying to install SDKman using installer script"
	echo "Executing: curl -s \"https://get.sdkman.io\" | bash"
	echo ""
	
	curl -s "https://get.sdkman.io" | bash > >( _indentInstallerOutput )
	sdkmanInstallResultCode=$?
	if [[ "$sdkmanInstallResultCode" == "0" ]]; then
		echo "" 
		echo "Installation of SDKman was successful."

		# link in profile
		sdkman_init_snippet=$(cat <<-END
# Initialize SDKMAN
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"
END
)
		if [ -w $cxdev_zshrc ] && ! grep -q "SDKMAN_DIR" "$cxdev_zshrc"; then
			echo "Adding SDKman initialization snippet to: $cxdev_zshrc"
			echo -e "\n$sdkman_init_snippet" >> "$cxdev_zshrc"
		fi
		if [ -w $cxdev_bashrc ] && ! grep -q "SDKMAN_DIR" "$cxdev_bashrc"; then
			echo "Adding SDKman initialization snippet to: $cxdev_bashrc"
			echo -e "\n$sdkman_init_snippet" >> "$cxdev_bashrc"
		fi

		echo "==============================================================================="
		return 0
	else 
		echo "" 
		echo "Installation of SDKman not successful (Status: $sdkmanInstallResultCode)."
		echo "==============================================================================="
		return 1
	fi
}

_installNodEnv () {
	echo "==============================================================================="
	echo "Trying to install nodenv using installer script"
	echo "Executing: curl -fsSL \"https://github.com/nodenv/nodenv-installer/raw/HEAD/bin/nodenv-installer\" | bash"
	echo ""
	curl -fsSL "https://github.com/nodenv/nodenv-installer/raw/HEAD/bin/nodenv-installer" | bash > >( _indentInstallerOutput )
	nodenvInstallResultCode=$?
	if [[ "$nodenvInstallResultCode" == "0" ]]; then
		echo "" 
		echo "Installation of nodenv was successful."

		# link in profile
		if [ -w $cxdev_zshrc ] && ! grep -q "nodenv init" "$cxdev_zshrc"; then
			echo "Adding nodenv initialization snippet to: $cxdev_zshrc"
			echo -e "\n# Initialize NODENV" >> "$cxdev_zshrc"
			echo "export PATH=\"${ZDOTDIR:-${HOME}}/.nodenv/bin:\$PATH\"" >> "$cxdev_zshrc"
			echo 'eval "$(nodenv init - zsh)"' >> "$cxdev_zshrc"
		fi
		if [ -w $cxdev_bashrc ] && ! grep -q "nodenv init" "$cxdev_bashrc"; then
			echo "Adding nodenv initialization snippet to: $cxdev_bashrc"
			echo -e "\n# Initialize NODENV" >> "$cxdev_bashrc"
			echo "export PATH=\"${ZDOTDIR:-${HOME}}/.nodenv/bin:\$PATH\"" >> "$cxdev_bashrc"
			echo 'eval "$(nodenv init - bash)"' >> "$cxdev_bashrc"
		fi

		echo "==============================================================================="
		return 0
	else
		echo "" 
		echo "Installation of nodenv not successful (Status: $nodenvInstallResultCode)."
		echo "==============================================================================="
		return 1
	fi
}

_indentInstallerOutput () {
	sed 's/^/[INSTALLER] /'
}

_installCXDEVEnvironment
