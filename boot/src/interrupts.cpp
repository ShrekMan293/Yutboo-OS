#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

extern "C" void div_by_zero()                  { asm("iretq"); }
extern "C" void debug()                        { asm("iretq"); }
extern "C" void non_maskable_interrupt()       { asm("iretq"); }
extern "C" void breakpoint()                   { asm("iretq"); }
extern "C" void overflow()                     { asm("iretq"); }
extern "C" void bound_range_exceeded()         { asm("iretq"); }
extern "C" void invalid_opcode()               { asm("iretq"); }
extern "C" void device_not_available()         { asm("iretq"); }
extern "C" void double_fault()                 { asm("iretq"); }
extern "C" void coprocessor_segment_overrun()  { asm("iretq"); }
extern "C" void invalid_tss()                  { asm("iretq"); }
extern "C" void segment_not_present()          { asm("iretq"); }
extern "C" void stack_segment_fault()          { asm("iretq"); }
extern "C" void general_protection_fault()     { asm("iretq"); }
extern "C" void page_fault()                   { asm("iretq"); }
extern "C" void reserved()                  { asm("iretq"); }
extern "C" void x87_floating_point()           { asm("iretq"); }
extern "C" void alignment_check()              { asm("iretq"); }
extern "C" void machine_check()                { asm("iretq"); }
extern "C" void simd_floating_point()          { asm("iretq"); }
extern "C" void virtualization()               { asm("iretq"); }
extern "C" void control_protection()           { asm("iretq"); }
extern "C" void hypervisor_injection()         { asm("iretq"); }
extern "C" void vmm_communication()            { asm("iretq"); }
extern "C" void security_exception()           { asm("iretq"); }
extern "C" void reserved_31()                  { asm("iretq"); }

// Define IDT entry (16 bytes)
struct [[gnu::packed]] IDTEntry {
    uint16_t offset_low;     // bits 0–15
    uint16_t selector;       // code segment selector
    uint8_t ist;             // bits 0–2 hold IST offset, rest 0
    uint8_t type_attr;       // type and attributes
    uint16_t offset_mid;     // bits 16–31
    uint32_t offset_high;    // bits 32–63
    uint32_t zero;           // reserved
};

// IDT pointer format
struct [[gnu::packed]] IDTPointer {
    uint16_t limit;
    uint64_t base;
};

// Declare 256-entry IDT
IDTEntry idt[256];

// Helper to encode an entry
void set_idt_entry(int vec, void (*handler)(), uint8_t ist = 0, uint8_t flags = 0x8E) {
    uintptr_t addr = reinterpret_cast<uintptr_t>(handler);
    idt[vec].offset_low = addr & 0xFFFF;
    idt[vec].selector = 0x08;              // Kernel code segment
    idt[vec].ist = ist & 0x7;
    idt[vec].type_attr = flags;            // Present, interrupt gate, DPL=0
    idt[vec].offset_mid = (addr >> 16) & 0xFFFF;
    idt[vec].offset_high = (addr >> 32) & 0xFFFFFFFF;
    idt[vec].zero = 0;
}

// Load IDT
extern "C" void lidt_func(void* ptr);

extern "C" void init_idt() {
    // Populate first 32 entries
    set_idt_entry(0x00, div_by_zero);
    set_idt_entry(0x01, debug);
    set_idt_entry(0x02, non_maskable_interrupt);
    set_idt_entry(0x03, breakpoint);
    set_idt_entry(0x04, overflow);
    set_idt_entry(0x05, bound_range_exceeded);
    set_idt_entry(0x06, invalid_opcode);
    set_idt_entry(0x07, device_not_available);
    set_idt_entry(0x08, double_fault);
    set_idt_entry(0x09, coprocessor_segment_overrun);
    set_idt_entry(0x0A, invalid_tss);
    set_idt_entry(0x0B, segment_not_present);
    set_idt_entry(0x0C, stack_segment_fault);
    set_idt_entry(0x0D, general_protection_fault);
    set_idt_entry(0x0E, page_fault);
    set_idt_entry(0x0F, reserved);
    set_idt_entry(0x10, x87_floating_point);
    set_idt_entry(0x11, alignment_check);
    set_idt_entry(0x12, machine_check);
    set_idt_entry(0x13, simd_floating_point);
    set_idt_entry(0x14, virtualization);
    set_idt_entry(0x15, control_protection);
    set_idt_entry(0x16, reserved);
    set_idt_entry(0x17, reserved);
    set_idt_entry(0x18, reserved);
    set_idt_entry(0x19, reserved);
    set_idt_entry(0x1A, reserved);
    set_idt_entry(0x1B, reserved);
    set_idt_entry(0x1C, hypervisor_injection);
    set_idt_entry(0x1D, vmm_communication);
    set_idt_entry(0x1E, security_exception);
    set_idt_entry(0x1F, reserved_31);

    // IDT pointer
    IDTPointer idt_ptr = {
        .limit = sizeof(idt) - 1,
        .base = reinterpret_cast<uint64_t>(&idt)
    };

    lidt_func(&idt_ptr);
}