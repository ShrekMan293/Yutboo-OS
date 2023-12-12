[bits 16]
[org 0x7C00]

global setup_32

setup_32:
    cli
    mov sp, 0xFFFF
    mov bp, sp
    push dx

    lgdt[gdt_descriptor]

    mov eax, cr0
    or eax, 0x1
    mov cr0, eax

    jmp KCODE:setup_64

    hlt

[bits 32]
setup_64:
    mov ax, KDATA
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov eax, 100
    jmp $

gdt_descriptor:
    dw gdt_end - gdt_start - 1
    dq gdt_start

gdt_start:
    ; Null
    dq 0x0000000000000000
    Code_32:
    dq 0x00CF9B000000FFFF
    KCode:
    dq 0x00AF9B000000FFFF
    KData:
    dq 0x00CF93000000FFFF
    UCode:
    dq 0x00AFFF000000FFFF
    UData:
    dq 0x00CFF3000000FFFF
gdt_end:

CODE_32 equ Code_32 - gdt_start
KCODE equ KCode - gdt_start
KDATA equ KData - gdt_start
UCODE equ UCode - gdt_start
UDATA equ UData - gdt_start

times 510-($ - $$) db 0
db 0x55, 0xAA
