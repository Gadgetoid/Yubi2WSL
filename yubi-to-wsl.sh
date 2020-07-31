#!/bin/bash
# Copyright 2020 Phil Howard <yubi2wsl@gadgetoid.com>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

NAME="Yubi2WSL"
VERSION="0.0.1"

INSTALL_TARGET=`pwd`/yubi2wsl
FORCE_UPDATE="no"
POSITIONAL_ARGS=()

USERNAME=`cmd.exe /c "echo|set /p=%USERNAME%"`

BIN_NPIPRELAY=npiperelay.exe
BIN_PAGEANT=wsl-ssh-pageant-amd64.exe
URL_NPIPRELAY=https://github.com/NZSmartie/npiperelay/releases/download/v0.1/$BIN_NPIPRELAY
URL_PAGEANT=https://github.com/benpye/wsl-ssh-pageant/releases/download/20190513.14/$BIN_PAGEANT
BIN_GPG4WIN=gpg4win-3.1.11.exe
URL_GPG4WIN=https://files.gpg4win.org/$BIN_GPG4WIN
BIN_GNUPG=gnupg-w32-2.2.20_20200320.exe
URL_GNUPG=ftp://ftp.gnupg.org/gcrypt/binary/$BIN_GNUPG
DOWNLOAD_GPG4WIN="no"
DOWNLOAD_GNUPG="no"
SH_START=start.sh
SH_STOP=stop.sh
SH_ENV=env.sh
SSH_SOCK_FILE=ssh-agent.sock
GPG_AGENT_SOCK_FILE=$HOME/.gnupg/S.gpg-agent
GPG_AGENT_SOCK_FILE_WIN=C:/Users/$USERNAME/AppData/Roaming/gnupg/S.gpg-agent
GPG_AGENT_EXTRA_SOCK_FILE=$HOME/.gnupg/S.gpg-agent.extra
GPG_AGENT_EXTRA_SOCK_FILE_WIN=C:/Users/$USERNAME/AppData/Roaming/gnupg/S.gpg-agent.extra
PID_FILE_PAGEANT=pageant.pid
PID_FILE_SOCAT=socat.pid


EXE_GPGCONF="/mnt/c/Program Files (x86)/GnuPG/bin/gpgconf.exe"

read -r -d '' USAGE << EOF
$NAME $VERSION

yubi-to-wsl.sh --install-target /mnt/c/some/dir

Installer to route GPG Agent and SSH Agent support from Windows 10 to a WSL container.

Options:
--version          - Show name/version and quit
--help             - Show this help and quit
--install-target   - Installation path, must be available in WSL and Windows (IE: /mnt/c/yubi2wsl)
--download-gpg4win - Download $BIN_GPG4WIN (GnuPG, Kleopatra, GPA, GpgOL, GpgEX and Compendium)
--install-gpg4win  - Download $BIN_GPG4WIN and start installation
--download-gnupg   - Download $BIN_GNUPG (GnuPG from $URL_GNUPG)
--install-gnupg    - Download $BIN_GNUPG and start installation
--force-update     - Force re-download of binary files
EOF

confirm() {
    if [ "$FORCE" == '-y' ]; then
        true
    else
        read -r -p "$1 [y/N] " response < /dev/tty
        if [[ $response =~ ^(yes|y|Y)$ ]]; then
            true
        else
            false
        fi
    fi
}

prompt() {
        read -r -p "$1 [y/N] " response < /dev/tty
        if [[ $response =~ ^(yes|y|Y)$ ]]; then
            true
        else
            false
        fi
}

success() {
    echo -e "$(tput setaf 2)$1$(tput sgr0)"
}

inform() {
    echo -e "$(tput setaf 6)$1$(tput sgr0)"
}

warning() {
    echo -e "$(tput setaf 1)$1$(tput sgr0)"
}

function apt_pkg_install {
	PACKAGES=()
	PACKAGES_IN=("$@")
	for ((i = 0; i < ${#PACKAGES_IN[@]}; i++)); do
		PACKAGE="${PACKAGES_IN[$i]}"
		printf "Checking for $PACKAGE :"
		dpkg -L $PACKAGE > /dev/null 2>&1
		if [ "$?" == "1" ]; then
			PACKAGES+=("$PACKAGE")
            inform " REQUIRED"
        else
            success " FOUND"
		fi
	done
	PACKAGES="${PACKAGES[@]}"
	if ! [ "$PACKAGES" == "" ]; then
		echo "Installing missing packages: $PACKAGES"
		sudo apt update
		sudo apt install -y $PACKAGES
	fi
}

while [[ $# -gt 0 ]]; do
	K="$1"
	case $K in
    --version)
        echo "$NAME $VERSION"
        exit 0
        ;;
    --help)
        echo "$USAGE"
        exit 0
        ;;
    --download-gpg4win)
        DOWNLOAD_GPG4WIN="yes"
        shift
        ;;
    --download-gnupg)
        DOWNLOAD_GNUPG="yes"
        shift
        ;;
    --install-gpg4win)
        INSTALL_GPG4WIN="yes"
        DOWNLOAD_GPG4WIN="yes"
        shift
        ;;
    --install-gnupg)
        INSTALL_GNUPG="yes"
        DOWNLOAD_GNUPG="yes"
        shift
        ;;
    -f|--force-update)
        FORCE_UPDATE="yes"
        shift
        ;;
	-o|--install-target)
		INSTALL_TARGET="$2"
		shift
		shift
		;;
	*)
		if [[ $1 == -* ]]; then
			printf "Unrecognised option: $1\n";
			printf "Usage: $USAGE\n";
			exit 1
		fi
		POSITIONAL_ARGS+=("$1")
		shift
	esac
done

WIN_TARGET=$(realpath $INSTALL_TARGET | sed 's/\//\\/g' | sed 's/\\mnt\\c/C:/')

echo -e "\nAttempting install to: $INSTALL_TARGET ($WIN_TARGET)\n"

if [[ $DOWNLOAD_GNUPG == "yes" ]]; then
    if [ ! -f $INSTALL_TARGET/$BIN_GNUPG ] || [ $FORCE_UPDATE == "yes" ]; then
        echo -e "Fetching $BIN_GNUPG"
        wget --quiet --show-progress --output-document=$INSTALL_TARGET/$BIN_GNUPG $URL_GNUPG
    fi
fi
if [[ $INSTALL_GNUPG == "yes" ]]; then
    explorer.exe $WIN_TARGET\\$BIN_GNUPG
fi

if [[ $DOWNLOAD_GPG4WIN == "yes" ]]; then
    if [ ! -f $INSTALL_TARGET/$BIN_GPG4WIN ] || [ $FORCE_UPDATE == "yes" ]; then
        echo -e "Fetching $BIN_GPG4WIN"
        echo -e "Don't forget to donate: https://www.gpg4win.org/get-gpg4win.html"
        wget --quiet --show-progress --output-document=$INSTALL_TARGET/$BIN_GPG4WIN $URL_GPG4WIN
    fi
fi
if [[ $INSTALL_GPG4WIN == "yes" ]]; then
    explorer.exe $WIN_TARGET\\$BIN_GPG4WIN
fi

printf "Checking for $EXE_GPGCONF : "
"$EXE_GPGCONF" --version > /dev/null 2>&1
GPGCONF=$?
if [[ $GPGCONF == "0" ]]; then
    success "FOUND"
    echo -e "Configuring GPG: Enabling SSH and Putty support"
    # $EXE_GPGCONF --kill gpg-agent
    echo "enable-ssh-support:1:1" | "$EXE_GPGCONF" --change-options gpg-agent > /dev/null 2>&1
    echo "enable-putty-support:1:1" | "$EXE_GPGCONF" --change-options gpg-agent > /dev/null 2>&1
    # $EXE_GPGCONF --launch gpg-agent
    "$EXE_GPGCONF" --reload gpg-agent
else
    warning "NOT FOUND"
    warning "Make sure GnuPG or GPG4WIN is installed, and that \"$EXE_GPGCONF\" is present on your system."
    exit 1
fi

apt_pkg_install socat

if ! [[ $INSTALL_TARGET == /mnt/c/* ]]; then
    warning "Failed: Install target should be in /mnt/c/\n"
    exit 1
fi

mkdir -p $INSTALL_TARGET

printf "Checking for $BIN_NPIPRELAY : "
if [ ! -f $INSTALL_TARGET/$BIN_NPIPRELAY ] || [ $FORCE_UPDATE == "yes" ]; then
    warning "REQUIRED"
    wget --quiet --show-progress --output-document=$INSTALL_TARGET/$BIN_NPIPRELAY $URL_NPIPRELAY
else
    success "FOUND"
fi

printf "Checking for $BIN_PAGEANT : "
if [ ! -f $INSTALL_TARGET/$BIN_PAGEANT ] || [ $FORCE_UPDATE == "yes" ]; then
    warning "REQUIRED"
    wget --quiet --show-progress --output-document=$INSTALL_TARGET/$BIN_PAGEANT $URL_PAGEANT
else
    success "FOUND"
fi

read -r -d '' START_FILE << EOF
cd $INSTALL_TARGET

if [[ -f $PID_FILE_SOCAT ]] && kill -0 \$(cat $PID_FILE_SOCAT) >> /dev/null 2>&1; then
    SOCAT_PID=\$(cat $PID_FILE_SOCAT)
    echo "socat/npirelay running with PID \$SOCAT_PID"
else
    rm -f "$GPG_AGENT_SOCK_FILE"
    rm -f "$PID_FILE_SOCAT"
    socat UNIX-LISTEN:"$GPG_AGENT_SOCK_FILE,fork" EXEC:'$INSTALL_TARGET/$BIN_NPIPRELAY -ei -ep -s -a "$GPG_AGENT_SOCK_FILE_WIN"',nofork </dev/null &>/dev/null &
    SOCAT_PID=\$!
    echo "\$SOCAT_PID" > $PID_FILE_SOCAT
    echo "socat/npirelay started with PID \$SOCAT_PID"
fi

if [[ -f $PID_FILE_SOCAT_EXTRA ]] && kill -0 \$(cat $PID_FILE_SOCAT_EXTRA) >> /dev/null 2>&1; then
    SOCAT_PID=\$(cat $PID_FILE_SOCAT_EXTRA)
    echo "socat/npirelay (extra) running with PID \$SOCAT_PID"
else
    rm -f "$GPG_AGENT_EXTRA_SOCK_FILE"
    rm -f "$PID_FILE_SOCAT_EXTRA"
    socat UNIX-LISTEN:"$GPG_AGENT_EXTRA_SOCK_FILE,fork" EXEC:'$INSTALL_TARGET/$BIN_NPIPRELAY -ei -ep -s -a "$GPG_AGENT_EXTRA_SOCK_FILE_WIN"',nofork </dev/null &>/dev/null &
    SOCAT_PID=\$!
    echo "\$SOCAT_PID" > $PID_FILE_SOCAT_EXTRA
    echo "socat/npirelay (extra) started with PID \$SOCAT_PID"
fi

if [[ -f $PID_FILE_PAGEANT ]] && kill -0 \$(cat $PID_FILE_PAGEANT) >> /dev/null 2>&1; then
    PAGEANT_PID=\$(cat $PID_FILE_PAGEANT)
    echo "Pageant running with PID \$PAGEANT_PID"
else
    rm -f "$SSH_SOCK_FILE"
    rm -f "$PID_FILE_PAGEANT"
    ./$BIN_PAGEANT --wsl "$WIN_TARGET\\$SSH_SOCK_FILE" &
    PAGEANT_PID=\$!
    echo "\$PAGEANT_PID" > $PID_FILE_PAGEANT
    echo "Pageant started with PID \$PAGEANT_PID"
fi

echo "Now run \"source $INSTALL_TARGET/env.sh\""
EOF

read -r -d '' STOP_FILE << EOF
cd $INSTALL_TARGET

if [[ -f $PID_FILE_SOCAT ]]; then
    if kill -0 \$(cat $PID_FILE_SOCAT) >> /dev/null 2>&1; then
        kill \$(cat $PID_FILE_SOCAT)
        echo "Stopped npiprelay and socat"
    else
        echo "npiprelay and socat not running (removing $PID_FILE_SOCAT)"
        rm -rf $PID_FILE_SOCAT
    fi
else
    echo "npiprelay and socat not running ($PID_FILE_SOCAT not found)"
fi

if [[ -f $PID_FILE_SOCAT_EXTRA ]]; then
    if kill -0 \$(cat $PID_FILE_SOCAT_EXTRA) >> /dev/null 2>&1; then
        kill \$(cat $PID_FILE_SOCAT_EXTRA)
        echo "Stopped npiprelay and socat (extra)"
    else
        echo "npiprelay and socat (extra) not running (removing $PID_FILE_SOCAT_EXTRA)"
        rm -rf $PID_FILE_SOCAT_EXTRA
    fi
else
    echo "npiprelay and socat (extra) not running ($PID_FILE_SOCAT_EXTRA not found)"
fi

if [[ -f $PID_FILE_PAGEANT ]]; then
    if kill -0 \$(cat $PID_FILE_PAGEANT) >> /dev/null 2>&1; then
        kill \$(cat $PID_FILE_PAGEANT)
        echo "Stopped Pageant"
    else
        echo "Pageant not running (removing $PID_FILE_PAGEANT)"
        rm -rf $PID_FILE_PAGEANT
    fi
else
    echo "Pageant not running ($PID_FILE_PAGEANT not found)"
fi
EOF

read -r -d '' ENV_FILE << EOF
export GPG_TTY=\$(tty)
export SSH_AUTH_SOCK=$INSTALL_TARGET/$SSH_SOCK_FILE
EOF

echo "Creating: $INSTALL_TARGET/$SH_ENV"
echo "$ENV_FILE" > $INSTALL_TARGET/$SH_ENV
echo "Creating: $INSTALL_TARGET/$SH_START"
echo "$START_FILE" > $INSTALL_TARGET/$SH_START
echo "Creating: $INSTALL_TARGET/$SH_STOP"
echo "$STOP_FILE" > $INSTALL_TARGET/$SH_STOP

success "\nInstall Done!"
echo "Now add the following to your ~/bashrc:"
echo "$INSTALL_TARGET/$SH_START"
cat "$INSTALL_TARGET/$SH_ENV"
