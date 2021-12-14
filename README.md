# diavirt

diavirt implements all of the functionality of [Virtualization.framework](https://developer.apple.com/documentation/virtualization) in a command-line tool.

## Usage

diavirt takes in a configuration file which describes how to build up the virtual machine configuration.

```json
{
  "cpuCoreCount": 2,
  "memorySizeInBytes": 2147483648,
  "bootloader": {
    "linux": {
      "kernelFilePath": "vmlinux",
      "initialRamdiskPath": "initrd",
      "commandLine": "earlycon console=hvc0 root=/dev/vda1"
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
  ]
}
```

To run diavirt with the specified configuration:

```sh
$ diavirt -c machine.json
```
