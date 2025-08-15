[bits 32]
global start
global vga_putc
global vga_clear
extern kmain

section .text
start:
    ; We're already in protected mode when we get here
    ; Setup 32-bit data segments
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov esp, 0x90000

    ; Clear screen and call C entry
    call vga_clear
    call kmain

.hang:
    cli
    jmp .hang

; VGA text mode constants
vga_base equ 0xB8000
screen_cols equ 80
screen_rows equ 25
cursor_pos dw 0

; VGA routines
vga_clear:
    push edi
    push ecx
    mov edi, vga_base
    mov eax, 0x0720
    mov ecx, screen_cols*screen_rows
    rep stosw
    mov word [cursor_pos], 0
    call vga_update_cursor
    pop ecx
    pop edi
    ret

vga_update_cursor:
    push eax
    push edx
    mov ax, [cursor_pos]
    mov dx, 0x3D4
    mov al, 0x0F
    out dx, al
    mov dx, 0x3D5
    mov al, byte [cursor_pos]
    out dx, al
    mov dx, 0x3D4
    mov al, 0x0E
    out dx, al
    mov dx, 0x3D5
    mov al, byte [cursor_pos+1]
    out dx, al
    pop edx
    pop eax
    ret

vga_putc:
    push eax
    push ebx
    push edi
    cmp al, 13
    je .newline
    mov ah, 0x0F
    movzx edi, word [cursor_pos]
    shl edi, 1
    add edi, vga_base
    mov [edi], ax
    inc word [cursor_pos]
    mov ax, [cursor_pos]
    cmp ax, screen_cols * screen_rows
    jl .update
    jmp .update
.newline:
    movzx eax, word [cursor_pos]
    xor edx, edx
    mov ebx, screen_cols
    div ebx
    inc eax
    imul eax, ebx
    mov word [cursor_pos], ax
.update:
    call vga_update_cursor
    pop edi
    pop ebx
    pop eax
    ret