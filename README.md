# MiniOS
A functional OS

### Simple Bootloader

- load at address `0x7C00` (standard)
- exactly 512 bytes long
- append boot signature `0xAA55`, tells bios that this sector is bootable
- simple print routine

### Simple Kernel

- loaded by the bootloader at physical address `0x10000` (`0x1000:0`)
- padded to exactly 5 sectors (2560 bytes)
- enable A20 to access > 1MB memory
- set up minimal global descriptor table (GDT)
- switch from real-mode to protected-mode
- clear text mode screen
- simple print routine