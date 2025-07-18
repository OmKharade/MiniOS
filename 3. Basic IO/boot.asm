; same as 2. Simple Kernel/boot.asm
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

    ; Disable interrupts before jumping
    cli

    ; Jump to kernel
    jmp 0x1000:0x0000

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

msg db "Loading kernel...", 13, 10, 0
err_msg db "Disk error!", 13, 10, 0
bootdrive db 0

times 510-($-$$) db 0
dw 0xAA55