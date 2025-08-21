#include <vga.h>
#include <memory.h>

void kmain() {
    vga_clear();
    k_print_string("MiniOS: Memory Management\n");
    k_print_string("------------------------\n");

    pmm_init();

    heap_init();
    
    k_print_string("\n--- PMM Allocation ---\n");
    void* p1 = palloc();
    k_print_string("Allocated page 1 at: "); k_print_hex((uint32_t)p1); k_print_string("\n");
    void* p2 = palloc();
    k_print_string("Allocated page 2 at: "); k_print_hex((uint32_t)p2); k_print_string("\n");
    
    pfree(p1);
    k_print_string("Freed page 1. Now re-allocating...\n");
    
    void* p3 = palloc();
    k_print_string("Allocated page 3 at: "); k_print_hex((uint32_t)p3); k_print_string("\n");
    
    pfree(p2);
    pfree(p3);

    k_print_string("\n--- Heap (malloc) ---\n");
    char* str1 = (char*)malloc(20);
    k_print_string("Malloc'd 20 bytes at: "); k_print_hex((uint32_t)str1); k_print_string("\n");
    
    int* num_array = (int*)malloc(sizeof(int) * 5);
    k_print_string("Malloc'd 5 ints at: "); k_print_hex((uint32_t)num_array); k_print_string("\n");

    free(str1);
    k_print_string("Freed 20-byte string.\n");

    char* str2 = (char*)malloc(10);
    k_print_string("Malloc'd 10 bytes at: "); k_print_hex((uint32_t)str2); k_print_string("\n");
    
    free(num_array);
    free(str2);

    k_print_string("\nKernel setup complete. Halting.\n");

    // Halt 
    while (1) {
        __asm__ volatile("hlt");
    }
}