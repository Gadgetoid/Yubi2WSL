# Yubi2WSL

Yubi2WSL is a bash script to set up tunneling of YubiKey GPG and SSH features from a Windows 10 Host into a WSL1 Guest.

Yubi2WSL supports features such as:

* SSH authentication- your SSH key will show in `ssh-add -L` when your YubiKey is plugged in
* Viewing/editing details of your YubiKey with `gpg --edit-card`

# Requirements

Yubi2WSL relies on the following packages, which can be automatically installed for you:

* GnuPG for Windows, or GPG4Win
* socat (installed into Linux)
* npiprelay.exe (modified fork by @NZSmartie) - https://github.com/NZSmartie/npiperelay
* wsl-ssh-pageant-amd64.exe - https://github.com/benpye/wsl-ssh-pageant

# Installing

Yubi2WSL must be installed in a path that's visible both to the Linux Guest and Windows 10 Host, ie somewhere in: `/mnt/c/`

* `--version` - Show name/version and quit
* `--help` - Show help and quit
* `--install-target` - Installation path, must be available in WSL and Windows (IE: /mnt/c/yubi2wsl)
* `--download-gpg4win` - Download GPG4WIN (GnuPG, Kleopatra, GPA, GpgOL, GpgEX and Compendium)
* `--install-gpg4win` - Download GPG4WIN and start installation
* `--download-gnupg` - Download GnuPG
* `--install-gnupg` - Download GnuPG and start installation
* `--force-update` - Force re-download of binary files
