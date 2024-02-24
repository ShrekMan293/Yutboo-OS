[BITS 16]
[ORG 0x7C00]

setup32:
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    mov sp, 0x8000

    call enable_a20
    cli

    lgdt [gdt_descriptor]
    mov eax, cr0
    or eax, 0x1
    mov cr0, eax

    jmp CODE32:setup_pages

    jmp $

enable_a20:
    in al, 0x92
    or al, 2
    out 0x92, al
    ret

[bits 32]
setup_pages:
    mov ax, DATA32
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    
    jmp check_32
    mov eax, 0x010  ; Filler code

    check_32:
        jmp $

gdt_descriptor:
    dw gdt_end - gdt_start
    dd gdt_start

gdt_start:
    dq 0x0000000000000000   ; Null Descriptor

    CODE_32:
        db 0            ; Base
        db 11001111b    ; Flags and Limit (4 KiB gran, 32 bit, limit 0xF)
        db 10011010b    ; P, Kernel DPL, Code, Conforming false, Readable
        db 0            ; Base
        dw 0            ; Base
        dw 0xFFFF       ; Limit
    DATA_32:
        db 0            ; Base
        db 11001111b    ; Flags and Limit
        db 10000010b    ; P, Kernel DPL, Data, Grows up, writeable
        db 0            ; Base
        dw 0            ; Base
        dw 0xFFFF       ; Limit
    CODE_64:
        db 0            ; Base
        db 10101111b    ; Flags and Limit (4 KiB gran, 64 bit, limit 0xF)
        db 10011010b    ; P, Kernel DPL, Code, Conforming false, Readable
        db 0            ; Base
        dw 0            ; Base
        dw 0xFFFF       ; Limit
    DATA_64:
        db 0            ; Base
        db 11001111b    ; Flags and Limit
        db 10000010b    ; P, Kernel DPL, Data, Grows up, writeable
        db 0            ; Base
        dw 0            ; Base
        dw 0xFFFF       ; Limit
gdt_end:

CODE32 equ CODE_32 - gdt_start
DATA32 equ DATA_32 - gdt_start
CODE64 equ CODE_64 - gdt_start
DATA64 equ DATA_64 - gdt_start

times 510-($-$$) db 0
dw 0xAA55