#include <vga.h>
#include <types.h>

void k_print_string(const char* str) {
    while (*str) {
        vga_putc(*str++);
    }
}

void k_print_hex(uint32_t n) {
    k_print_string("0x");
    char buffer[9];
    char* hex_chars = "0123456789ABCDEF";
    buffer[8] = '\0';
    for (int i = 7; i >= 0; i--) {
        buffer[i] = hex_chars[n & 0xF];
        n >>= 4;
    }
    k_print_string(buffer);
}

void k_print_dec(uint32_t n) {
    if (n == 0) {
        vga_putc('0');
        return;
    }
    char buffer[11];
    buffer[10] = '\0';
    int i = 9;
    while (n > 0) {
        buffer[i--] = (n % 10) + '0';
        n /= 10;
    }
    k_print_string(&buffer[i + 1]);
}