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

### Basic IO

- basic VGA text-mode driver for screen output
- clears screen, moves cursor, write character, scrolls screen
- reads scancodes from port `0x60/0x64` and converts to ASCII

### Transition to C

- set up linker script
- set up makefile
- in bootloader - transition from 16-bit to 32-bit, disable interrupts, enable A20 line, load GDT, far jump
- in asm kernel - VGA routines
- transfer control to an external C kernal (`kmain`)