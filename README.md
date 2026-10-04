# android-rom-dump

Dump every partition from an Android phone's `/dev/block/bootdevice/by-name` into `ROMbkp/` as raw `.img` files, using `adb` + `dd`.

Bash ports of the original Windows batch scripts (`StartDump.bat`, `getimg.bat`, `clean.bat`), which are kept alongside for reference.

Sourced from https://xdaforums.com/t/guide-tool-dump-full-rom-to-pc-via-adb.3531866/post-85191389

## Requirements

- bash
- `adb` (Android platform-tools) — Arch: `pacman -S android-tools`
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

- `clean.sh` deletes previous `ROMbkp/*.img` — `StartDump.sh` runs it automatically at startup.
- Dumps are written to `ROMbkp/` next to the scripts, regardless of your current directory.
- Failed dumps are renamed to `ROMbkp/<partition>.txt` with the `dd` error output inside.
- Many partitions are only readable as root — permission errors show up in that `.txt` file.
