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
    call vga_clear

    ; Print message
    mov esi, msg
    call print_string

    ; Halt
    ; cli
    ; jmp hang

input_loop:
    call keyboard_getchar
    test al, al
    jz input_loop

    cmp al, 27
    je hang

    call vga_putc
    jmp input_loop

print_string:
    push esi
.loop:
    lodsb
    test al, al
    jz .done
    call vga_putc
    jmp .loop
.done:
    pop esi
    ret

msg db "Basic I/O Test (Press ESC to hang) : ", 0

hang:
    jmp hang

; VGA TEXT-MODE DRIVER CONSTANTS
vga_base equ 0xB8000
screen_cols equ 80
screen_rows equ 25

cursor_pos dw 0                ; Current cursor position (0-based index into 80×25 text buffer)

; VGA Utility Routines

vga_clear:
    push edi
    push ecx
    mov edi, vga_base
    mov eax, 0x0720            ; Space, gray on black
    mov ecx, screen_cols*screen_rows
    rep stosw                  ; Fill entire screen
    mov word [cursor_pos], 0
    call vga_update_cursor
    pop ecx
    pop edi
    ret

vga_scroll:
    push esi
    push edi
    push ecx
    mov esi, vga_base + screen_cols*2      ; Second text row
    mov edi, vga_base                      ; First text row
    mov ecx, (screen_rows-1)*screen_cols   ; Number of words to copy
    rep movsw                              ; Shift rows up
    mov eax, 0x0720                        ; Clear last line
    mov ecx, screen_cols
    rep stosw
    sub word [cursor_pos], screen_cols     ; Move cursor up one row
    pop ecx
    pop edi
    pop esi
    ret

vga_update_cursor:
    push eax
    push edx
    mov ax, [cursor_pos]
    mov dx, 0x3D4
    mov al, 0x0F
    out dx, al                 ; Select low cursor byte
    mov dx, 0x3D5
    mov al, byte [cursor_pos]
    out dx, al                 ; Send low byte
    mov dx, 0x3D4
    mov al, 0x0E
    out dx, al                 ; Select high cursor byte
    mov dx, 0x3D5
    mov al, byte [cursor_pos+1]
    out dx, al                 ; Send high byte
    pop edx
    pop eax
    ret

vga_putc:
    push eax
    push ebx
    push edi
    cmp al, 13                ; Newline?
    je .newline
    mov ah, 0x0F               ; Attribute: white on black
    movzx edi, word [cursor_pos]
    shl edi, 1                 ; Each character cell is 2 bytes
    add edi, vga_base
    mov [edi], ax              ; Write character & attribute
    inc word [cursor_pos]
    mov ax, [cursor_pos]
    cmp ax, screen_cols * screen_rows
    jl .update
    call vga_scroll
    jmp .update

.newline:
    movzx   eax, word [cursor_pos] ; load current position, upper half = 0
    xor     edx, edx               ; make the dividend 0:EAX (32-bit)
    mov     ebx, screen_cols       ; 80
    div     ebx                    ; EAX=row, EDX=col (we don't need col)
    inc     eax                    ; next row
    imul    eax, ebx               ; row * cols  → column 0
    mov     word [cursor_pos], ax
    jmp     .update

.update:
    call vga_update_cursor
    pop edi
    pop ebx
    pop eax
    ret

; BASIC KEYBOARD INPUT ROUTINES

keyboard_getchar:
    push edx
.wait_key:
    in al, 0x64                ; Status port
    test al, 1
    jz .wait_key               ; Buffer empty
    in al, 0x60                ; Read scancode
    cmp al, 0x80               ; Ignore break codes
    jae .wait_key
    movzx edx, al
    mov al, [scancode_table + edx]
    pop edx
    ret

; Scancode → ASCII lookup table (set 1), unknowns = 0
scancode_table:
    db 0                       ; 0x00
    db 27                      ; 0x01  ESC
    db '1','2','3','4','5','6','7','8','9','0','-','=' ; 0x02-0x0D
    db 8                       ; 0x0E  Backspace
    db 9                       ; 0x0F  Tab
    db 'q','w','e','r','t','y','u','i','o','p','[',']' ; 0x10-0x1B
    db 13                      ; 0x1C  Enter
    db 0                       ; 0x1D  Ctrl (unused)
    db 'a','s','d','f','g','h','j','k','l', 59, 39, 96 ; 0x1E-0x28 (39 = apostrophe, 96 = `)
    db 0                       ; 0x29  Left Shift
    db 92                      ; 0x2B  Backslash '\'
    db 'z','x','c','v','b','n','m',',','.','/'         ; 0x2C-0x35
    db 0                       ; 0x36  Right Shift
    db '*'                     ; 0x37  Keypad *
    db 0                       ; 0x38  Alt
    db ' '                     ; 0x39  Space
    times 128-($-scancode_table) db 0                  ; Pad remaining entries with zeros

times 2560-($-$$) db 0   ; Pad to 5 sectors (512*5=2560 bytes)