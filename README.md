# Yubi2WSL

Yubi2WSL is a bash script to set up tunneling of YubiKey GPG and SSH features from a Windows 10 Host into a WSL1 Guest.

Yubi2WSL supports features such as:

* SSH authentication- your SSH key will show in `ssh-add -L` when your YubiKey is plugged in
* Viewing/editing details of your YubiKey with `gpg --edit-card`

What it does:

* Downloads, installs and configures your chosen GPG service for windows
* Installs `socat` if it's not available
* Downloads npiprelay and pageant
* Creates `start.sh` and `stop.sh` for starting/stopping the services
* Creates `env.sh` for exporting necessary environment variables

Everything but the GPG service (installation of which is managed in Windows) is installed to the `--install-target`.

Why?

Having SSH and GPG passed through to WSL allows git commits to be signed and securely pushed without dropping to Windows or switching to a Linux client. It's convoluted- for sure- but I'm sure I am not alone in using WSL as part of my workflow in this way.

# Requirements

Yubi2WSL relies on the following packages, which can be automatically installed for you:

* GnuPG for Windows, or GPG4Win
* socat (installed into Linux)
* npiprelay.exe (modified fork by @NZSmartie) - https://github.com/NZSmartie/npiperelay
* wsl-ssh-pageant-amd64.exe - https://github.com/benpye/wsl-ssh-pageant

# Installing

Yubi2WSL must be installed in a path that's visible both to the Linux Guest and Windows 10 Host, ie somewhere in: `/mnt/c/`

A typical installation will include either GPG4WIN (`--install-gpg4win`) or GnuPG for Windows (`--install-gnupg`).

For example:

```
./yubi-to-wsl --install-target /mnt/c/yubi2wsl
```

Once installed and running, plug in your YubiKey and verify operation of SSH with:

```
ssh-add -l
```

And GPG with:

```
gpg --edit-card
```

Don't forget to run `fetch` when editing the card, to fetch the public keys from the keyserver and install them locally.

# Installer Options

* `--version` - Show name/version and quit
* `--help` - Show help and quit
* `--install-target` - Installation path, must be available in WSL and Windows (IE: /mnt/c/yubi2wsl)
* `--download-gpg4win` - Download GPG4WIN (GnuPG, Kleopatra, GPA, GpgOL, GpgEX and Compendium)
* `--install-gpg4win` - Download GPG4WIN and start installation
* `--download-gnupg` - Download GnuPG
* `--install-gnupg` - Download GnuPG and start installation
* `--force-update` - Force re-download of binary files

# References

I wrote this after reviewing the YubiKey 5Ci and finding the Windows to WSL process somewhat more complex than I was willing to try at the time: https://www.gadgetoid.com/2020/07/08/yubikey-5ci-reviewed/

This tool wouldn't have been possible without the instructions at CodingNest: https://codingnest.com/how-to-use-gpg-with-yubikey-wsl/#wslgpgbridge

The arg parsing code was borrowed heavily from Fan SHIM's service installer: https://github.com/pimoroni/fanshim-python/blob/master/examples/install-service.sh

Colour-coded output messages were borrowed from Pimoroni's get scripts: https://github.com/pimoroni/get/tree/master/installers