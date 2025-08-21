#include <memory.h>
#include <vga.h>


#define MEMMAP_COUNT_ADDR 0x8000
#define MEMMAP_BUFFER_ADDR 0x8002

static uint32_t* pmm_bitmap = NULL;
static uint32_t pmm_total_pages = 0;
static uint32_t pmm_used_pages = 0;
static uint32_t pmm_bitmap_size = 0;

void pmm_set_bit(uint32_t bit) {
    pmm_bitmap[bit / 32] |= (1 << (bit % 32));
}

void pmm_clear_bit(uint32_t bit) {
    pmm_bitmap[bit / 32] &= ~(1 << (bit % 32));
}

int pmm_test_bit(uint32_t bit) {
    return pmm_bitmap[bit / 32] & (1 << (bit % 32));
}

void pmm_init() {
    uint16_t map_entry_count = *(uint16_t*)MEMMAP_COUNT_ADDR;
    e820_entry_t* map = (e820_entry_t*)MEMMAP_BUFFER_ADDR;

    uint64_t total_memory = 0;
    for (uint16_t i = 0; i < map_entry_count; i++) {
        if (map[i].type == 1) { // Type 1 is usable RAM
            total_memory += map[i].length;
        }
    }

    pmm_total_pages = total_memory / PAGE_SIZE;
    pmm_bitmap_size = pmm_total_pages / 8; // Size in bytes
    if (pmm_bitmap_size * 8 < pmm_total_pages) {
        pmm_bitmap_size++;
    }

    // Find a place for the bitmap itself, after the kernel (kernel ends around 0x100000)
    extern uint32_t kernel_end; 
    pmm_bitmap = (uint32_t*)&kernel_end;

    // Mark all memory as used initially
    for (uint32_t i = 0; i < pmm_bitmap_size / 4; i++) {
        pmm_bitmap[i] = 0xFFFFFFFF;
    }

    // Mark usable regions as free
    for (uint16_t i = 0; i < map_entry_count; i++) {
        if (map[i].type == 1) {
            uint64_t base = map[i].base;
            uint64_t length = map[i].length;
            for (uint64_t j = 0; j < length; j += PAGE_SIZE) {
                pmm_clear_bit((base + j) / PAGE_SIZE);
            }
        }
    }

    // The bitmap starts right at kernel_end.
    uint32_t reserved_pages = ((uint32_t)&kernel_end + pmm_bitmap_size) / PAGE_SIZE;
    if (((uint32_t)&kernel_end + pmm_bitmap_size) % PAGE_SIZE != 0) {
        reserved_pages++;
    }

    // Mark all pages from 0 up to the end of our bitmap as used.
    k_print_string("Reserving pages for kernel and PMM bitmap...\n");
    for (uint32_t i = 0; i < reserved_pages; i++) {
        pmm_set_bit(i);
    }
    
    // Recalculate used pages
    pmm_used_pages = 0;
    for(uint32_t i=0; i < pmm_total_pages; i++){
        if(pmm_test_bit(i)) pmm_used_pages++;
    }

    k_print_string("PMM Initialized. Total Pages: ");
    k_print_dec(pmm_total_pages);
    k_print_string(", Used Pages: ");
    k_print_dec(pmm_used_pages);
    k_print_string("\n");
}

void* palloc() {
    for (uint32_t i = 0; i < pmm_total_pages / 32; i++) {
        if (pmm_bitmap[i] != 0xFFFFFFFF) {
            for (int j = 0; j < 32; j++) {
                if (!(pmm_bitmap[i] & (1 << j))) {
                    uint32_t page_num = i * 32 + j;
                    pmm_set_bit(page_num);
                    pmm_used_pages++;
                    return (void*)(page_num * PAGE_SIZE);
                }
            }
        }
    }
    return NULL; // Out of memory
}

void pfree(void* page) {
    if (page == NULL) return;
    uint32_t page_num = (uint32_t)page / PAGE_SIZE;
    if (pmm_test_bit(page_num)) {
        pmm_clear_bit(page_num);
        pmm_used_pages--;
    }
}

// --- Heap (malloc/free) ---

typedef struct heap_block_header {
    size_t size;
    int is_free;
    struct heap_block_header* next;
} heap_block_header_t;

static heap_block_header_t* heap_free_list_head = NULL;

void heap_init() {
    // Request initial page(s) for the heap
    void* heap_start = palloc();
    if (heap_start == NULL) {
        k_print_string("Heap init failed: No physical memory!\n");
        return;
    }

    heap_free_list_head = (heap_block_header_t*)heap_start;
    heap_free_list_head->size = PAGE_SIZE - sizeof(heap_block_header_t);
    heap_free_list_head->is_free = 1;
    heap_free_list_head->next = NULL;
    k_print_string("Heap Initialized.\n");
}

void* malloc(size_t size) {
    heap_block_header_t* current = heap_free_list_head;
    heap_block_header_t* prev = NULL;

    while (current) {
        if (current->is_free && current->size >= size) {
            // Found a block. Should we split it?
            if (current->size > size + sizeof(heap_block_header_t)) {
                heap_block_header_t* new_block = (heap_block_header_t*)((char*)current + sizeof(heap_block_header_t) + size);
                new_block->is_free = 1;
                new_block->size = current->size - size - sizeof(heap_block_header_t);
                new_block->next = current->next;
                current->next = new_block;
                current->size = size;
            }
            current->is_free = 0;
            return (void*)((char*)current + sizeof(heap_block_header_t));
        }
        prev = current;
        current = current->next;
    }
    // if no block is found .. todo
    return NULL; // Out of heap memory
}

void free(void* ptr) {
    if (ptr == NULL) return;

    heap_block_header_t* header = (heap_block_header_t*)((char*)ptr - sizeof(heap_block_header_t));
    header->is_free = 1;

    // Coalesce merge adjacent free blocks here for better memory reuse .. todo
}