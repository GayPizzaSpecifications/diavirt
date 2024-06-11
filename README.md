# diavirt

diavirt implements all of the functionality of [Virtualization.framework](https://developer.apple.com/documentation/virtualization) in a command-line tool.

## Usage

diavirt takes in a configuration file which describes how to build up the virtual machine configuration.

```json
{
  "cpuCoreCount": 2,
  "memorySizeInBytes": 2147483648,
  "platform": {
    "genericPlatform": {
      "enableNestedVirtualization": true
    }
  },
  "bootLoader": {
    "efiBootLoader": {
      "efiVariableStore": {
        "variableStorePath": "efi.vars"
      }
    }
  },
  "graphicsDevices": [
    {
      "virtioGraphicsDevice": {
        "scanouts": [
          {
            "widthInPixels": 1280,
            "heightInPixels": 720
          }
        ]
      }
    }
  ],
  "keyboardDevices": [
    {
      "usbKeyboardDevice": {}
    }
  ],
  "pointingDevices": [
    {
      "usbScreenCoordinatePointingDevice": {}
    }
  ],
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
  "directorySharingDevices": []
}
```

To run diavirt with the specified configuration:

```sh
$ diavirt -v -c machine.json
```
