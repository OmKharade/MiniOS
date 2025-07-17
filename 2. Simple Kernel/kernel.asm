bits 16
org 0x10000

section .text
start:
    ; Set up initial segments
    mov ax, cs
    mov ds, ax
    mov es, ax

    ; Load GDT
    cli
    lgdt [gdt_descriptor]

    ; Enable A20 line (with fallback)
    call enable_a20

    ; Switch to protected mode
    mov eax, cr0
    or eax, 1
    mov cr0, eax

    ; Far jump to 32-bit code (offset relative to 0x10000)
    jmp 0x08:protected_mode

enable_a20:
    ; Fast A20 method (port 0x92)
    in al, 0x92
    test al, 2
    jnz .done  ; Already enabled
    or al, 2
    out 0x92, al
.done:
    ret

align 8
gdt_start:
    ; Null descriptor
    dd 0, 0

    ; Code segment (Base=0x10000, Limit=0xFFFFF, 4KB granularity)
    dw 0xFFFF       ; Limit 0-15
    dw 0x0000       ; Base 0-15
    db 0x01         ; Base 16-23 (0x01 for 0x10000)
    db 10011010b    ; Access byte (code, ring 0)
    db 11001111b    ; Flags (4KB granularity), Limit 16-19
    db 0x00         ; Base 24-31

    ; Data segment (Base=0x00000000, Limit=0xFFFFF, 4KB granularity)
    dw 0xFFFF       ; Limit 0-15
    dw 0x0000       ; Base 0-15
    db 0x00         ; Base 16-23
    db 10010010b    ; Access byte (data, ring 0)
    db 11001111b    ; Flags (4KB granularity), Limit 16-19
    db 0x00         ; Base 24-31
gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1    ; Size
    dd gdt_start                  ; Base address

bits 32
protected_mode:
    ; Set up segment registers for data
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov esp, 0x90000  ; Stack at 0x90000

    ; Clear screen (access via data segment base 0)
    mov edi, 0xB8000
    mov ecx, 2000
    mov ax, 0x0720    ; Gray on black, space character
    rep stosw

    ; Print message
    mov esi, msg
    mov edi, 0xB8000
    call print_string

    ; Halt
    cli
    jmp hang

print_string:
    push eax
    push edi
.loop:
    lodsb
    test al, al
    jz .done
    mov ah, 0x0F    ; White on black
    mov [edi], ax
    add edi, 2
    jmp .loop
.done:
    pop edi
    pop eax
    ret

msg db "Protected Mode Active!", 0

hang:
    jmp hang

times 2560-($-$$) db 0   ; Pad to 5 sectors (512*5=2560 bytes)