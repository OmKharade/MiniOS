bits 16
org 0x7c00

MEMMAP_COUNT equ 0x8000      
MEMMAP_BUFFER equ 0x8002     

start:
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7000

    mov [bootdrive], dl

    mov si, msg
    call print_string

    xor ax, ax
    int 0x13
    jc disk_error

    mov ah, 0x02        
    mov al, 32          
    mov ch, 0           
    mov cl, 2           
    mov dh, 0           
    mov dl, [bootdrive] ; Drive number
    mov bx, 0x1000      
    mov es, bx
    xor bx, bx
    int 0x13
    jc disk_error

    mov si, mem_msg
    call print_string
    xor ax, ax          
    mov es, ax          
    call detect_memory

    mov si, pmode_msg
    call print_string

    cli 

    mov eax, gdt_start  
    mov [gdt_descriptor + 2], eax 
    lgdt [gdt_descriptor]

    call enable_a20

    mov eax, cr0
    or eax, 1
    mov cr0, eax

    jmp 0x08:protected_mode_start

disk_error:
    mov si, err_msg
    call print_string
    cli
    hlt

mem_error:
    mov si, mem_err_msg
    call print_string
    cli
    hlt

print_string:
    mov ah, 0x0E
.loop:
    lodsb
    test al, al
    jz .done
    int 0x10
    jmp .loop
.done:
    ret

detect_memory:
    xor ebx, ebx
    mov di, MEMMAP_BUFFER
    mov word [MEMMAP_COUNT], 0
.loop:
    mov eax, 0xE820
    mov ecx, 20
    mov edx, 0x534D4150
    int 0x15
    jc .error
    cmp eax, 0x534D4150
    jne .error
    add di, 20
    inc word [MEMMAP_COUNT]
    cmp ebx, 0
    jne .loop
    jmp .done
.error:
    jmp mem_error
.done:
    ret

enable_a20:
    in al, 0x92
    test al, 2
    jnz .done
    or al, 2
    out 0x92, al
.done:
    ret

[bits 32]
protected_mode_start:
    mov ax, 0x10        
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov esp, 0x90000    

    call 0x10000

.hang:
    cli
    jmp .hang

[bits 16]
msg db "Loading kernel...", 13, 10, 0
mem_msg db "Detecting memory map...", 13, 10, 0
pmode_msg db "Entering protected mode...", 13, 10, 0
err_msg db "Disk error!", 13, 10, 0
mem_err_msg db "Memory detection failed!", 13, 10, 0
bootdrive db 0

align 8 
gdt_start:
    dd 0, 0

    dw 0xFFFF, 0x0000
    db 0x00, 10011010b, 11001111b, 0x00

    dw 0xFFFF, 0x0000
    db 0x00, 10010010b, 11001111b, 0x00
gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1  
    dd 0                        

times 510-($-$$) db 0
dw 0xAA55