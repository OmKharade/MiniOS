bits 16
org 0x7c00

start:
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7000
    mov si, msg
.print:
    lodsb
    test al, al
    jz .done
    mov ah, 0x0E
    int 0x10
    jmp .print
.done:
    jmp $

msg db "Hello, World!", 0

times 510-($-$$) db 0
dw 0xaa55