# diavirt

[![GitHub Workflow](https://github.com/GayPizzaSpecifications/diavirt/actions/workflows/macos.yml/badge.svg)](https://github.com/GayPizzaSpecifications/diavirt/actions/workflows/macos.yml)
[![Latest Build](https://shields.io/badge/download-nightly-blue)](https://nightly.link/GayPizzaSpecifications/diavirt/workflows/macos/main/diavirt)
[![Latest Release](https://shields.io/github/v/release/GayPizzaSpecifications/diavirt?display_name=tag&sort=semver)](https://github.com/GayPizzaSpecifications/diavirt/releases/latest)

diavirt implements all of the functionality of [Virtualization.framework](https://developer.apple.com/documentation/virtualization) in a command-line tool.

## Usage

### Install with Homebrew

1. Install [Homebrew](https://brew.sh)
2. Install diavirt with Homebrew: `brew install gaypizzaspecifications/made/diavirt`

diavirt takes in a configuration file which describes how to build up the virtual machine configuration.

```json
{
  "cpuCoreCount": 2,
  "memorySizeInBytes": 2147483648,
  "platform": {
    "genericPlatform": {}
  },
  "bootLoader": {
    "linuxBootLoader": {
      "kernelFilePath": "vmlinux",
      "initialRamdiskPath": "initrd",
      "commandLine": "console=hvc0 root=/dev/vda1"
    }
  },
  "serialPorts": [
    {
      "virtioConsoleDevice": {},
      "stdioSerialAttachment": {}
    }
  ],
  "storageDevices": [
    {
      "diskImageAttachment": {
        "imageFilePath": "disk.raw"
      },
      "virtioBlockDevice": {}
    }
  ],
  "entropyDevices": [
    {
      "virtioEntropyDevice": {}
    }
  ],
  "memoryBalloonDevices": [
    {
      "virtioTraditionalMemoryBalloonDevice": {}
    }
  ],
  "networkDevices": [
    {
      "natNetworkAttachment": {},
      "virtioNetworkDevice": {}
    }
  ],
  "directorySharingDevices": [
    {
      "virtioFileSystemDevice": {
        "tag": "mac-users"
      },
      "directoryShare": {
        "singleDirectoryShare": {
          "directory": {
            "path": "/Users"
          }
        }
      }
    }
  ]
}
```

To run diavirt with the specified configuration:

```sh
$ diavirt -c machine.json
```
