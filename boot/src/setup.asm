[bits 16]
[org 0x7C00]

PML4_BASE   equ 0xAE00
PDPT_BASE   equ 0x9E00
PD_BASE     equ 0x8E00
PT_BASE     equ 0x7E00

global setup_32

setup_32:
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    cli
    mov sp, 0xFFFF
    mov bp, sp
    push dx

    pop dx

    lgdt[gdt_descriptor]

    mov eax, cr0
    or eax, 0x1
    mov cr0, eax

    jmp CODE_32:setup_64

    hlt     ; Code should not reach

[bits 32]
setup_64:
    mov ax, KDATA
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    mov esp, 0x9fc00
    mov ebp, esp

    call setup_page_tables
    mov eax, PML4_BASE
    mov cr3, eax

    mov eax, cr4
    or eax, (1 << 4) | (1 << 5) ; Set both PSE (bit 4) and PAE (bit 5)
    mov cr4, eax

    mov ecx, 0xC000080 ; EFER MSR Address
    rdmsr
    or edx, 1 << 8  ; Set LME bit
    wrmsr

    mov eax, cr0
    or eax, 0x80000000 ; Enable PG bit
    mov cr0, eax

    ;jmp CODE_32:te
    jmp KCODE:load_kernel

    hlt     ; Code should not reach here

te:
    mov eax, 102
    hlt

setup_page_tables:
    call setup_pml4
    call setup_pdpt
    call setup_pd
    call setup_pt
    ret

setup_pml4:
    mov eax, PML4_BASE
    mov bx, 0               ; Frame Number is also 0 so it checks out
    mov bx, 0110b           ; Execute - Enabled ;; User & Surpervisor ;; Writeable ;; Present = false
    add eax, 6              ; Byte offset
    mov [eax], bx           ; Write to PML4
    mov eax, PML4_BASE      ; Restore original value

    mov eax, 0xBE00 - 0x8   ; 8 bytes lower gets us to 511th PML4 entry

    mov bx, 511             ; Frame Number
    shl ebx, 4              ; 511 is max 9 bit number, shift left 4 to get 511 at the top of bx (12 bit)
    mov bx, 0011b           ; Execute - Enabled ;; Supervisor only ;; Writeable ;; Present
    add eax, 6              ; Offset
    mov [eax], bx           ; Write to PML4
    ret

setup_pdpt:
    mov eax, PDPT_BASE          ; Move to PDPT
    mov bx, 0                   ; Frame 0
    mov bx, 0010b               ; Execute - Enabled ;; Supervisor only ;; Writeable ;; Present = false
    add eax, 6                  ; Writing offset
    mov [eax], bx               ; Write to PDPT
    mov eax, PDPT_BASE          ; Restore value

    mov eax, PML4_BASE - 0x8    ; 511th PDPT entry

    mov bx, 511                 ; Frame number
    shl ebx, 4
    mov bx, 0011b               ; Execute - Enabled ;; Supervisor only ;; Writeable ;; Present
    add eax, 6                  ; Offset
    mov [eax], bx               ; Write to PDPT
    ret

setup_pd:
    mov eax, PD_BASE - 0x8  ; Move to PD entry 511
    mov bx, 511             ; Frame 511
    shl ebx, 4              ; Already explained
    mov bx, 0011b           ; Execute - Enabled ;; Supervisor only ;; Writeable ;; Present
    add eax, 6              ; Offset
    mov [eax], bx           ; Write to PD

    mov eax, PD_BASE - 0x10 ; Move to PD entry 510

    mov bx, 510
    shl ebx, 4
    mov bx, 1010b           ; Execute - Disabled ;; Supervisor only ;; Writeable ;; Not Present
    add eax, 6
    mov [eax], bx           ; Write to PD
    ret

setup_pt:
    mov eax, PT_BASE        ; Move to PT Base
    mov edx, 0              ; Frame 0
    top_loop:
    shl edx, 4              ; Not necessarily for 0 but for others
    mov ecx, edx
    mov bx, 0011b           ; Execute - Enabled ;; Supervisor Only ;; Writeable ;; Present
    mov cx, bx
    add eax, 6
    mov [eax], cx
    add eax, 2              ; Next one
    inc edx
    cmp edx, 512
    jl top_loop

    ret

[bits 64]
load_kernel:
    mov rax, 0xFEFE00000000FEFE
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
