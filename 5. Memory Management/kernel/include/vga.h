#ifndef VGA_H
#define VGA_H

#include <types.h>

// From kernel.asm
extern void vga_putc(char c);
extern void vga_clear(void);

// From vga.c
void k_print_string(const char* str);
void k_print_hex(uint32_t n);
void k_print_dec(uint32_t n);

#endif // VGA_H