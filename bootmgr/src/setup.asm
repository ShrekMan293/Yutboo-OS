[bits 16]
[org 0x7C00]

global setup_32

setup_32:
    mov sp, 0xFFFF
    mov bp, sp
    push dx

    mov ah, 02h     ; Read sectors
    mov al, 1       ; Read _ sector(s)
    mov ch, 0       ; Cylinder 0
    mov cl, 2       ; Sector 2
    pop dx
    mov dh, 0       ; Head 0
    push ax
    mov ax, 0       ; ES:bx for 0000:7E00
    mov es, ax
    mov bx, 0x7E00  ; Already explained
    pop ax
    push ax         ; Save number of sectors supposed to be read
    int 0x13        ; Read

    pop bx          ; Get AX value
    jc error
    cmp al, bl
    jne error

    cli
    lgdt[gdt_descriptor]

    mov eax, cr0
    or eax, 0x1
    mov cr0, eax

    jmp KCODE:setup_entries

    hlt

error:
    cli
    hlt

[bits 32]
setup_entries:
    mov ax, KDATA
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov esp, 0x9fc00
    mov ebp, esp

    jmp 0x7E00

    hlt

gdt_descriptor:
    dw gdt_end - gdt_start - 1
    dq gdt_start

gdt_start:
    ; Null
    dq 0x0000000000000000
    KCode:
    dq 0x00CF9B000000FFFF
    KData:
    dq 0x00CF93000000FFFF
    UCode:
    dq 0x00CFFF000000FFFF
    UData:
    dq 0x00CFF3000000FFFF
gdt_end:

KCODE equ KCode - gdt_start
KDATA equ KData - gdt_start
UCODE equ UCode - gdt_start
UDATA equ UData - gdt_start

times 510-($ - $$) db 0
db 0x55, 0xAA
