# CX DEV Environment

CX Dev Tools is a suite of tools and extensions that provide best-in-class
enhancements of the standard CX products of SAP. The environment is a set
of configurations, alias and scripts that speeds up your local development
with SAP Commerce Cloud tremendously.

[Go directly to the installation](#installation)

## Core features

- Handling of multiple SAP Commerce projects with ease
- Sharing global configuration profiles between projects
- Sharing global dependencies & artefacts between projects
- Automatical local installation process of SAP Commerce Packages
- Reconfiguration of local environment with predefined profiles
- SSL profile with public wildcard certificate for front & backend
- SSO profile with preconfigured integration on Auth0 as IDP
- Development profiles for backoffice and smart edit development

## Daily workflow activities

| Task | Console command(s) | Description |
|------|--------------------|-------------|
| Load Project | `yLoadWorkspace path [NAME]` | Load and configures the SAP Commerce project at `path`. The `name` is optional and just for your convenience (used in title of terminal). <br> **Note: This command is a prerequisite for all the commands below!** |
| Workspace | `yinfo` | Shows the information of the currently loaded workspace. |
| Setup Project | `ysetup` | Performs the fundamental setup of the local development environment, including the extraction of the SAP Commerce Suite and integration packs which are configured within the `manifest.json`. <br> **Note: This command is typically used once in a while when you need to update your platform. It automates the whole setup process.** |
| Project navigation | `toworkspace` <br> `toplatform` <br> `toconfig` <br> `tostorefront` | Navigates to the specific folder within your local project. These commands use absolute paths, so you can call them from anywhere in the system. |
| Building the project | `yserver` <br> `ybuild` <br> `yrebuild`<br> `yinit` <br> `yreinit` <br> `yreformat` | Performs the given build operation while the mapping is as follows: <br> <ul><li>`yserver` => `ant customize server`</li><li>`ybuild` => `ant build server`</li><li>`yrebuild` => `ant clean customize all`</li><li>`yinit` => `ant initialize`</li><li>`yreinit` => `ant clean customize all initialize`</li></ul> <br> `yreformat` performs automated code conventions, if available. |
| Server start | `ystart` <br> `ydebug` <br> `ystorefront` <br> `ystorefrontssl` | Starting the local server without or with DEBUG mode enabled. The frontend can be started without or with SSL support. |
| Testing | `yunittest` <br> `yinttest` <br> `ytestresult` <br> `ymails` | Perform testing scenarios and open the test results in your system's browser or the folder with stored local email in your system's file browser. |
| Housekeeping | `yExtendLicense` | Perform house keeping tasks, like extending the valid days of your local instance. |

# How to use

## Preconditions

In order to make CX DEV environment work there are a couple of preconditions
that need to be fulfilled:

- Mac OS recommended package manager
- Required command line tools for the terminal
- SDKman for handling of Java versions
- nodenv for handling of Node versions
- The project layout must follow the CCv2 project template
- For some features smaller customizations within the project layout are necessary 

<details>
  <summary>Mac OS recommended package managere</summary>

Note: For Mac users, we still recommend to use the package manager "Homebrew"
for the installation. Homebrew can be installed easily by running the following
prompt:

```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Note: It is very important to keep nodenv up-to-date on a frequently base.
Another good reason to use a package manager for it. Homebrew updates with:

```
brew update
brew upgrade
```

That's it!
</details>

<details>
  <summary>Required Command line tools</summary>

The environment makes use of the following command line tools. Please make sure
you have installed them by using a package manager of your choice. Most linux
distributions will provide them out-of-the-box. Still, this list shall be a 
complete list as a reference:

#### Elementary (typically shipped with the linux distribution)

- `awk`
- `basename`
- `find`
- `grep`
- `ln`
- `md5sum`
- `readlink`
- `realpath`
- `sed`
- `tr`
- `uname`
- `unzip`

#### Recommended (you still may need to install them manually)

- `curl` (see https://curl.se/)
- `jq` (see https://jqlang.github.io/jq/)
- `openssl` (see https://www.openssl.org/)

Command for Ubuntu: `sudo apt install curl jq openssl`
Command for Mac OS: `brew install curl jq openssl`

#### Required (for Mac OS X)

For certain tools the Apple Developer Command Line Tools (xcode) are required.
You can request the installation by running the following command and follow
the instructions:

`xcode-select --install`
</details>

<details>
  <summary>SDKMAN</summary>

CXDEV uses SDKman for managing the Java versions (sapmachine) within the
projects. The installation is 100% automated by using the following prompt:

```
curl -s "https://get.sdkman.io" | bash
```

Afterwards to following lines have to be added to your shell run configuration
(`~/.bashrc` or `~/.zshrc`) file:

```
# Initialize SDKMAN
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"
```
</details>

<details>
  <summary>NODENV</summary>

CXDEV use nodenv for managing the Node versions within the projects. The
installation also runs 100% automated by using the following prompt:

```
curl -fsSL https://github.com/nodenv/nodenv-installer/raw/HEAD/bin/nodenv-installer | bash
```

Afterwards to following lines have to be added to your shell run configuration
(`~/.bashrc` or `~/.zshrc`) file:

```
# Initialize NODENV
export NODENV_DIR="$HOME/.nodenv"

[[ -f "$NODENV_DIR/bin/nodenv" ]] && "$NODENV_DIR/bin/nodenv" init
```
</details>

<details>
  <summary>Project layout</summary>

We typically setup our repositories by initializing the project from the
[CCv2 template provided by SAP](https://github.com/sap-commerce-tools/ccv2-project-template).

It is not necessary to run the bootstrap scripts from that template, but the
overall structure should follow the guidelines:

- core-customize: Folder for SAP Commerce Backend
- js-storefront: Folder for Composable Storefront

We have done the following customizations to tweak the environment for multi-
project scenarios:

- Introduced a global build.gradle.kts that wraps backend / frontend into one
  build and introduces code formatting tasks, incl. move of gradle wrapper to
  the root level
- Moved dependencies folder to the top level and use it as a link to a shared
  global directory
- Enhancements for package.json to start local storefront with certificates 
  from ../certificates by using `npm run cxdev`. The command is as follows:
  `"cxdev": "ng serve --watch --configuration development --host 0.0.0.0 --ssl true --ssl-key ../../certificates/local.cxdev.me.key --ssl-cert ../../certificates/local.cxdev.me.crt"`

We are looking forward to merge back the changes to the global repository.
Until then, we recommend to use the adjusted template from our repository:
[Adjusted CCv2 template](https://github.com/cxdevtools/ccv2-project-template).
</details>

## Installation<a name="installation"></a>

The installation of CXDEV is also very simple by running the following prompt:

```
bash <(curl -fsSL https://raw.githubusercontent.com/cxdevtools/environment/refs/heads/develop/install.sh)
```

Everything else will be done by the installer.

## Post-Installation topics

In order to use of the CXDEV environment, please make sure that you have
downloaded the installation artefacts from SAP that are references within your
`manifest.json` file.

Hint:
If you are running the CXDEV environment on a CI/CD pipeline, you can set the
environment variable `CXDEVCIMODE=y` to your `.bashrc` or `.zshrc` file to 
remove the ANSI color markers from the logging messages. This helps to keep the
CI/CD logs clean. The variable needs to be set before sourcing the `cxdev.sh`.

We encourage you to configure the CXDEVSYNCDIR environment variable to point
to a shared directory, eg. a company wide shared GDrive or OneDrive folder or
maybe you are using a mount on your machine. Per default, the CXDEVSYNCDIR 
points to your `$CXDEVHOME/dependencies/sapartefacts` folder and uses this.
So if you are only working on your own, feel free to keep your SAP artefacts
within this folder and organize them by artefact and year (if needed).

For more information please refer to the README.md files within the two
required and one optional artefacts:

- [SAP Artefacts](./dependencies/sapartefacts/README.md)
- [SAP JCO Connector](./dependencies/sapjco/README.md)

Restart your terminal once again and you are ready to start working with CXDEV!

Simply open your project by running `yLoadWorkspace path [name]`. You may
want to define aliases for one or even multiple projects like this:

```
alias yproject1='yLoadWorkspace /path/to/customerA/project1 "Customer Projekt1"'
alias yproject2='yLoadWorkspace /path/to/customerB/project2 "Customer Projekt2"'
alias yproject3='yLoadWorkspace /path/to/customerC/project3 "Customer Projekt3"'
```

Registering these aliases will allow you to simply type `yproject1` instead of
the long command every time. The second parameter `name` is optional, but
it will be printed and used as title for the terminal window. Therefore, it
helps to have a better overview over multiple projects in separate windows.

# Configuration

The preconfigured configuration profiles and the explaination of the mechanism
is part of the [configuration README.md](./configuration/README.md). Please go
there for further details about configuration options.

# Update

The environment improves continuously and can be updated easily by using the 
`yupdateenvironment` shortcut or by reexecuting the [installation command](#installation).
