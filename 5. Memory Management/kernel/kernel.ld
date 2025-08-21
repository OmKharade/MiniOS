ENTRY(start)
OUTPUT_FORMAT("elf32-i386")

SECTIONS {
    /* The kernel will be loaded by the bootloader at 1MB + 64K = 0x10000 */
    . = 0x10000;

    .text : {
        /* Place the entry point object first */
        *(.text.start) /* For a more specific section if needed */
        *(.text)
    }

    /* Read-only data, aligned to a page boundary */
    .rodata ALIGN(4096) : {
        *(.rodata)
    }

    /* Initialized data, aligned to a page boundary */
    .data ALIGN(4096) : {
        *(.data)
    }

    /* Uninitialized data (BSS), aligned to a page boundary */
    .bss ALIGN(4096) : {
        bss_start = .;
        *(.bss)
        *(COMMON)
        bss_end = .; 
    }

    /*
     * The PMM bitmap and other dynamic structures will start here.
     */
    PROVIDE(kernel_end = .);

    /DISCARD/ : {
        *(.comment)
        *(.eh_frame)
    }
}