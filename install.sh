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
export CXDEV_INSTALL_DIR="${CXDEV_INSTALL_DIR:-$HOME/.cxdev}"

_installCXDEVEnvironment () (
	local release version archive_url installedVersion runUpdate stage_dir source_dir candidate keypass required

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
	echo "Welcome to CXDEV environment installer"
	echo ""

	# Both release downloads need these commands, even on a tools-only refresh.
	for required in curl jq unzip; do
		if ! command -v "$required" >/dev/null 2>&1; then
			echo "Please install $required and rerun the installer." >&2
			return 1
		fi
	done
	release=$(_latestRelease cxdevtools/environment) || return 1
	if ! version=$(jq -er '.tag_name | strings | select(length > 0)' <<<"$release"); then
		echo "The latest CXDEV release is missing its tag." >&2
		return 1
	fi
	# Older releases only have GitHub's automatically generated source ZIP.
	if ! archive_url=$(_releaseAssetUrl cxdevtools/environment "environment-${version#v}.zip" <<<"$release") \
		&& ! archive_url=$(jq -er '.zipball_url | strings | select(startswith("https://api.github.com/repos/cxdevtools/environment/zipball/"))' <<<"$release"); then
		echo "The latest CXDEV release has no downloadable ZIP." >&2
		return 1
	fi

	# Check if already installed
	if [ -f "$CXDEV_INSTALL_DIR/.version" ]; then
		installedVersion=$(cat "$CXDEV_INSTALL_DIR/.version")

		echo "You already have CXDEV environment installed."
		echo "- Path   : ${CXDEV_INSTALL_DIR}"
		echo "- Version: ${installedVersion}"
		echo ""

		if [[ "$installedVersion" == "$version" ]]; then
			echo "The CXDEV files are already current. Refreshing bundled tools."
			_refreshTools
			return $?
		else
			runUpdate=$(_readYesNo "Do you want us to update your CXDEV environment with version ${version}? [y/N] " "N")
			if [[ "Y" != "$runUpdate" && "y" != "$runUpdate" ]]; then
				echo "Installer aborted, CXDEV environment was not updated."
				exit 0
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
		exit 1
	fi

	echo ""
	echo "Attempt to install CXDEV environment"
	echo "- version : ${version}"
	echo "- location: ${CXDEV_INSTALL_DIR}"
	echo ""

	stage_dir=$(mktemp -d "${TMPDIR:-/tmp}/cxdev-environment.XXXXXXXX") || return 1
	trap 'rm -rf "$stage_dir"' EXIT
	_downloadReleaseZip "$archive_url" "$stage_dir" || return 1

	# Both ZIP formats have a top-level directory, with different naming schemes.
	for candidate in "$stage_dir"/extracted/*; do
		if [ -f "$candidate/cxdev.sh" ] && [ -d "$candidate/helper" ]; then
			source_dir=$candidate
			break
		fi
	done
	if [ -z "$source_dir" ]; then
		echo "The CXDEV release ZIP is missing cxdev.sh or helper/." >&2
		return 1
	fi

	# Prepare the local development key before copying the release over the installation.
	keypass=$(awk '/^tomcat\.ssl\.keystore\.password=/ {print substr($0, index($0, "=") + 1); exit}' \
		"$source_dir/configuration/profiles/81-ssl.properties") || return 1
	openssl pkcs12 -in "$source_dir/certificates/local.cxdev.me.p12" -passin "pass:$keypass" \
		-nodes -nocerts -out "$stage_dir/local.cxdev.me.key" || return 1
	(umask 077; tail -n +5 "$stage_dir/local.cxdev.me.key" > "$source_dir/certificates/local.cxdev.me.key") || return 1

	echo "Copy files to installation location."
	mkdir -p "$CXDEV_INSTALL_DIR" && cp -r "$source_dir/." "$CXDEV_INSTALL_DIR" || return 1

	# link in profile
	cxdev_init_snippet=$(cat <<-END
# CXDEV Environment
source "$CXDEV_INSTALL_DIR/cxdev.sh"
#export CXDEVSYNCDIR="/mnt/sapartefacts"
END
)
	if [ -w "$cxdev_zshrc" ] && ! grep -q "cxdev.sh" "$cxdev_zshrc"; then
		echo "Adding cxdev initialization snippet to: $cxdev_zshrc"
		echo -e "\n$cxdev_init_snippet" >> "$cxdev_zshrc"
	fi
	if [ -w "$cxdev_bashrc" ] && ! grep -q "cxdev.sh" "$cxdev_bashrc"; then
		echo "Adding cxdev initialization snippet to: $cxdev_bashrc"
		echo -e "\n$cxdev_init_snippet" >> "$cxdev_bashrc"
	fi

	# Record the environment update so a failed tool download can be retried on its own.
	echo "$version" > "$CXDEV_INSTALL_DIR/.version" || return 1
	if ! _refreshTools; then
		echo "CXDEV environment installed. Rerun the installer to refresh its tools." >&2
		return 1
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
)

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

_latestRelease () {
	local repository="$1"
	curl --fail --location --silent --show-error --proto '=https' --proto-redir '=https' \
		-H "Accept: application/vnd.github+json" \
		-H "X-GitHub-Api-Version: 2022-11-28" \
		"https://api.github.com/repos/$repository/releases/latest" || {
			echo "Could not fetch the latest GitHub release for $repository." >&2
			return 1
		}
}

_releaseAssetUrl () {
	local repository="$1" asset_name="$2"
	jq -er --arg name "$asset_name" --arg prefix "https://github.com/$repository/releases/download/" '
		.assets[] | select(.name == $name and .state == "uploaded") | .browser_download_url
		| strings | select(startswith($prefix))
	'
}

_downloadReleaseZip () {
	local url="$1" stage_dir="$2"
	local archive="$stage_dir/release.zip" entries

	echo "Downloading $url."
	if ! curl --fail --location --silent --show-error --proto '=https' --proto-redir '=https' \
		--output "$archive" "$url" || ! unzip -tq "$archive" >/dev/null; then
		echo "Could not download or validate the release ZIP." >&2
		return 1
	fi

	entries=$(unzip -Z1 "$archive") || return 1
	if grep -Eq '(^/|(^|/)\.\.(/|$))' <<<"$entries"; then
		echo "The release ZIP contains an unsafe path." >&2
		return 1
	fi
	unzip -q "$archive" -d "$stage_dir/extracted"
}

_refreshTools () (
	local tools_dir="$CXDEV_INSTALL_DIR/tools"
	local target_dir="$tools_dir/certtool"
	local release version asset_name asset_url stage_dir extract_dir init_file

	release=$(_latestRelease cxdevtools/certificate-exchange) || return 1
	version=$(jq -er '.tag_name | strings | select(length > 0) | ltrimstr("v")' <<<"$release") || return 1
	asset_name="certtool-$version.zip"
	if ! asset_url=$(_releaseAssetUrl cxdevtools/certificate-exchange "$asset_name" <<<"$release"); then
		echo "The latest certtool release is missing $asset_name." >&2
		return 1
	fi

	mkdir -p "$tools_dir" || return 1
	stage_dir=$(mktemp -d "$tools_dir/.certtool.XXXXXXXX") || return 1
	trap 'rm -rf "$stage_dir"' EXIT
	_downloadReleaseZip "$asset_url" "$stage_dir" || return 1
	extract_dir="$stage_dir/extracted"
	if [ ! -f "$extract_dir/bin/cxdev-certificates" ] || [ ! -f "$extract_dir/lib/certtool-$version.jar" ]; then
		echo "The certtool archive is missing its launcher or application JAR." >&2
		return 1
	fi
	chmod +x "$extract_dir/bin/cxdev-certificates" || return 1

	# The SAP CLI is provisioned separately from the certtool release.
	if [ -d "$target_dir/tools" ]; then
		mkdir -p "$extract_dir/tools" && cp -pR "$target_dir/tools/." "$extract_dir/tools" || return 1
	fi

	if [ -e "$target_dir" ] || [ -L "$target_dir" ]; then
		mv "$target_dir" "$stage_dir/previous" || return 1
	fi
	if ! mv "$extract_dir" "$target_dir"; then
		if { [ -e "$stage_dir/previous" ] || [ -L "$stage_dir/previous" ]; } \
			&& ! mv "$stage_dir/previous" "$target_dir"; then
			trap - EXIT
			echo "Could not restore certtool. The previous installation is in $stage_dir/previous." >&2
		fi
		return 1
	fi

	echo "Installed certtool $version in $target_dir."
)

_installCXDEVEnvironment
