; Boot sector that transitions to protected mode before jumping to kernel
bits 16
org 0x7c00

start:
    ; Set up segments
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7000

    ; Save boot drive
    mov [bootdrive], dl

    ; Print message
    mov si, msg
    call print_string

    ; Reset disk system
    xor ax, ax
    int 0x13
    jc disk_error

    ; Load kernel (5 sectors)
    mov ah, 0x02        ; Read sectors
    mov al, 5           ; Number of sectors
    mov ch, 0           ; Cylinder 0
    mov cl, 2           ; Start from sector 2
    mov dh, 0           ; Head 0
    mov dl, [bootdrive] ; Drive number
    mov bx, 0x1000      ; Load to ES:BX = 0x1000:0
    mov es, bx
    xor bx, bx
    int 0x13
    jc disk_error

    ; Print transition message
    mov si, pmode_msg
    call print_string

    ; Disable interrupts before switching to protected mode
    cli

    ; Enable A20 line
    call enable_a20

    ; Load GDT
    lgdt [gdt_descriptor]

    ; Switch to protected mode
    mov eax, cr0
    or eax, 1
    mov cr0, eax

    ; Far jump to protected mode code
    jmp 0x08:protected_mode

disk_error:
    mov si, err_msg
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

enable_a20:
    in al, 0x92
    test al, 2
    jnz .done
    or al, 2
    out 0x92, al
.done:
    ret

[bits 32]
protected_mode:
    ; Set up protected mode segments
    mov ax, 0x10        ; Data segment selector
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov esp, 0x90000    ; Set up stack

    ; Jump to kernel loaded at 0x10000
    call 0x10000

.hang:
    cli
    jmp .hang

[bits 16]
; Data section
msg db "Loading kernel...", 13, 10, 0
pmode_msg db "Entering protected mode...", 13, 10, 0
err_msg db "Disk error!", 13, 10, 0
bootdrive db 0

; GDT
align 8
gdt_start:
    ; Null descriptor
    dd 0, 0

    ; Code segment (base=0, limit=0xFFFFF, 4KB granularity, 32-bit)
    dw 0xFFFF       ; limit low
    dw 0x0000       ; base low
    db 0x00         ; base middle
    db 10011010b    ; access byte (present, ring 0, code, readable)
    db 11001111b    ; flags + limit high (4KB granularity, 32-bit)
    db 0x00         ; base high

    ; Data segment (base=0, limit=0xFFFFF, 4KB granularity, 32-bit)
    dw 0xFFFF       ; limit low
    dw 0x0000       ; base low
    db 0x00         ; base middle
    db 10010010b    ; access byte (present, ring 0, data, writable)
    db 11001111b    ; flags + limit high (4KB granularity, 32-bit)
    db 0x00         ; base high
gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1  ; size
    dd gdt_start                ; offset

times 510-($-$$) db 0
dw 0xAA55