# android-rom-dump

Dump every partition from an Android phone's `/dev/block/bootdevice/by-name` into `ROMbkp/` as raw `.img` files, using `adb` + `dd`.

The repo keeps the original Windows batch scripts (`StartDump.bat`, `getimg.bat`, `clean.bat`) alongside these bash ports.

Sourced from https://xdaforums.com/t/guide-tool-dump-full-rom-to-pc-via-adb.3531866/post-85191389

## Requirements

- bash
- `adb` (Android platform-tools). On Arch, install it with `pacman -S android-tools`
- A phone with USB debugging enabled and authorized

## Usage

```sh
./StartDump.sh        # ask before extracting each partition
./StartDump.sh s      # extract everything, fetch a fresh partition list
./StartDump.sh n      # extract everything, reuse cached ROMbkp/by-name.txt
```

Or dump a single partition:

```sh
./getimg.sh boot      # asks y/n before extracting
./getimg.sh boot s    # extract without prompting
```

- `clean.sh` deletes previous `ROMbkp/*.img`. `StartDump.sh` runs it at startup.
- Run the scripts from any directory. They write into `ROMbkp/` beside themselves.
- When a dump fails, the script renames it to `ROMbkp/<partition>.txt` and drops the `dd` error output inside.
- You need root to read most partitions. Permission errors end up in that `.txt` file.
