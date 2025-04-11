[bits 64]

extern kmain
extern init_idt

; Start marker
limine_requests_start_marker:
dq 0xf6b8f4b39de7d1ae
dq 0xfab91a6940fcb9cf
dq 0x785c6ed015d3e316
dq 0x181e920a7852b9d9

limine_requests:
dq 0xf9562b2d5c95a6c8
dq 0x6a7b384944536bdc
dq (3)
align 8
limine_framebuffer_request:
dq 0xc7b1dd30df4c8b88
dq 0x0a82e883a194f07b
dq 0x9d5827dcd881dd75
dq 0xa3148604f6fab11b
dq 3
dq 0
align 8
limine_memory_request:
dq 0xc7b1dd30df4c8b88
dq 0x0a82e883a194f07b
dq 0x67cf3d9d378a806f
dq 0xe304acdfc50c3c62
dq 3
dq 0

limine_requests_end_marker:
dq 0xadc0e0531bb10d03
dq 0x9572709f31764c62

global start
start:
    mov rsp, 0xffffffff80001ff0
    mov rbp, rsp
    push 5
    pop rbx
    mov rbx, 0

    mov ax, KDATA
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov rax, 0

    lgdt[gdt_descriptor]
    mov r14, limine_framebuffer_request
    mov r15, limine_memory_request
    call init_idt
    call kmain
    jmp $

global lidt_func
lidt_func:
    lidt [rdi]
    ret

global translate_addr
translate_addr: ; This function only works with HHDM, the standard for Limine protocol
    ; RAX holds table
    ; RBX is address buffer
    ; RDI is original address
    ; RCX is math and logic buffer
    ; RDX is the shift value
    xor rax, rax
    mov rax, cr3
    add rax, 0xFFFFFFFF80000000 ; Add base address of HHDM
    mov rcx, 0x0000FF8000000000
    mov rbx, rdi
    and rbx, rcx    ; Now holds PML4 offset
    shr rbx, 39
    mov rcx, 8  ; Gonna multiply RBX by RCX
    imul rcx, rbx
    add rax, rcx
    mov rax, [rax]  ; Get the pointer to the PDPT entry

    mov rcx, 0x0000003FE0000000 ; AND factor
    mov rbx, rdi
    and rbx, rcx    ; Now holds PDPT offset
    shr rbx, 39
    mov rcx, 8  ; Gonna multiply RBX by RCX
    imul rcx, rbx
    add rax, rcx
    mov rax, [rax]  ; Get the pointer to the PD entry

    mov rcx, 0x000000001FF00000 ; AND factor
    mov rbx, rdi
    and rbx, rcx    ; Now holds PD offset
    shr rbx, 39
    mov rcx, 8  ; Gonna multiply RBX by RCX
    imul rcx, rbx
    add rax, rcx
    mov rax, [rax]  ; Get the pointer to the PT entry
    ret

gdt_descriptor:
    dw gdt_end - gdt_start - 1
    dq gdt_start

gdt_start:
    ; Null segment
    dq 0

    ; Kernel Code
    kcode:
    dq 0x00CF9A000000FFFF
    ; Kernel Data
    kdata:
    dq 0x00CF92000000FFFF
    ; User code
    ucode:
    dq 0x00CFFA000000FFFF
    ; User data
    udata:
    dq 0x00CF92000000FFFF
    ; TSS Descriptor
    tss:
    dd 0    ; Reserved
    dd 0    ; Base
    db 0    ; Base
    db 0xCF ; Flags (0b1100) and Limit (0xF)
    db 0x90 ; Access Byte
    db 0    ; Base
    dw 0    ; Base
    dw 0xFFFF ; Limit

    ; To anybody asking, "why is the TSS defined specifically but everything else is compact?"
    ; Cause I memorized the others
gdt_end:

KCODE equ kcode - gdt_start
KDATA equ kdata - gdt_start
UCODE equ ucode - gdt_start
UDATA equ udata - gdt_start
TSS equ tss - gdt_start

section .note.GNU-stack