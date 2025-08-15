extern void vga_putc(char c);

void kmain(){
    const char *msg = "Hello from C!\n";
    while(*msg){
        vga_putc(*msg++);
    }
    while(1){
        __asm__ volatile("hlt");
    }
}