#ifndef MEMORY_H
#define MEMORY_H

#include <types.h>

#define PAGE_SIZE 4096

// Structure for E820 memory map entries from the bootloader
typedef struct {
    uint64_t base;
    uint64_t length;
    uint32_t type;
} __attribute__((packed)) e820_entry_t;

// --- Physical Memory Manager (PMM) ---
void pmm_init();
void* palloc(); // Allocate one physical page
void pfree(void* page);
void pmm_dump_stats();

// --- Heap (malloc/free) ---
void heap_init();
void* malloc(size_t size);
void free(void* ptr);

#endif // MEMORY_H