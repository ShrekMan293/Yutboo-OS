#include "limine.h"
#include "int.h"
#include "utils.h"
#include "bootinfo.h"
#include <stddef.h>
#include <stdbool.h>
#include <stdint.h>

__attribute__((used, section(".requests")))
static volatile LIMINE_BASE_REVISION(2);

__attribute__((used, section(".requests")))
static volatile struct limine_memmap_request
    memmap_request = {
        .id = LIMINE_MEMMAP_REQUEST
    };

__attribute__((used, section(".requests")))
static volatile struct limine_framebuffer_request
    framebuffer_request = {
        .id = LIMINE_FRAMEBUFFER_REQUEST
    };

__attribute__((used, section(".requests_start_marker")))
static volatile LIMINE_REQUESTS_START_MARKER;

__attribute__((used, section(".requests_end_marker")))
static volatile LIMINE_REQUESTS_END_MARKER;

__attribute__((section(".text")))
const char limine_magic[] = "Limi";

void hcf() {
    for (;;) {
        asm("hlt");
    }
}
uint64_t strlen(const char* string) {
    uint64_t length = 0;
    while (string[length] != '\0') {
        length++;
    }

    return length;
}

// void handle_error(const char* message) {
//     if (terminal_request.response == NULL || terminal_request.response->terminal_count < 1) {
//         hcf();
//     }
//     else {
//         terminal_request.response->write(terminal_request.response, message, strlen(message));
//     }
// }

#define PCI_CONFIG_ADDRESS 0xCF8
#define PCI_CONFIG_DATA 0xCFC

static inline uint32_t pci_read(uint8_t bus, uint8_t device, uint8_t func, uint8_t off) {
    uint32_t address;
    uint32_t data;

    address = (bus << 16) | (device << 11) | (func << 8) | (off & 0xFC) | (1 << 31);
    asm volatile("outl %0, %1" :: "a"(address), "Nd"(PCI_CONFIG_ADDRESS));
    asm volatile("inl %1, %0" : "=a"(data) : "Nd"(PCI_CONFIG_DATA));
    return data;
}

bool detect_ahci_drives() {
    for (uint8_t bus = 0; bus < 255; bus++) {
        for (uint8_t device = 0; device < 32; device++) {
            for (uint8_t func = 0; func < 8; func++) {
                uint32_t class_info = pci_read(bus, device, func, 0x08);

                uint8_t class_code = (class_info >> 24) & 0xFF;
                uint8_t subclass = (class_info >> 16) & 0xFF;
                uint8_t prog_if = (class_info >> 8) & 0xFF;

                if (class_code == 0x01 && subclass == 0x06 && prog_if == 0x01) return true;
            }
        }
    }

    return false;
}

bool detect_ide_drives() {
    for (uint8_t bus = 0; bus < 255; bus++) {
        for (uint8_t device = 0; device < 32; device++) {
            for (uint8_t func = 0; func < 8; func++) {
                uint32_t class_info = pci_read(bus, device, func, 0x08);

                uint8_t class_code = (class_info >> 24) & 0xFF;
                uint8_t subclass = (class_info >> 16) & 0xFF;
                uint8_t prog_if = (class_info >> 8) & 0xFF;

                if (class_code == 0x01 && subclass == 0x01) return true;
            }
        }
    }

    return false;
}

memmap_entry convert_memmap_entry(struct limine_memmap_entry entry) {
    memmap_entry new_entry;
    new_entry.base = entry.base;
    new_entry.length = entry.length;
    new_entry.type = entry.type;

    return new_entry;
}

memmap_t convert_memmap(struct limine_memmap_response map) {
    memmap_t memmap;
    memmap.count = map.entry_count;

    for (uint64_t i = 0; i < map.entry_count; i++)
    {
        memmap.entries[i] = convert_memmap_entry(*map.entries[i]);
    }
    
    return memmap;
}

framebuffer convert_framebuffer(struct limine_framebuffer fb) {
    framebuffer f;
    f.address = (u64)fb.address;
    f.blue_mask_shift = fb.blue_mask_shift;
    f.blue_mask_size = fb.blue_mask_size;
    f.bpp = fb.bpp;
    f.green_mask_shift = fb.green_mask_shift;
    f.green_mask_size = fb.green_mask_size;
    f.height = fb.height;
    f.memory_model = fb.memory_model;
    f.pitch = fb.pitch;
    f.red_mask_shift = fb.red_mask_shift;
    f.red_mask_size = fb.red_mask_size;
    return f;
}

framebuffers convert_framebuffers(struct limine_framebuffer_response fb) {
    framebuffers fbs;
    fbs.count = fb.framebuffer_count;
    
    for (uint64_t i = 0; i < fb.entry_count; i++)
    {
        fbs.entries[i] = convert_framebuffer(*fb.framebuffers[i]);
    }
    
    return fbs;
}

void triple_fault() {
    asm("cli");

    const uint64_t idt_ptr[2] = { 0xffffffff80008000, 0};
    asm volatile("lidt %0" :: "m"(idt_ptr));
    asm volatile("int $0x10");
}

void setup() {
    if (LIMINE_BASE_REVISION_SUPPORTED == false) triple_fault();
    if (memmap_request.response != NULL) {
        for (uint64_t i = 0; i < memmap_request.response->entry_count; i++)
        {
            if (memmap_request.response->entries[i]->type == LIMINE_MEMMAP_USABLE) {
                if (memmap_request.response->entries[i]->length < 0x40000000) triple_fault();

                break;
            }
        }
    }
    else {
        triple_fault();
    }
    if (framebuffer_request.response != NULL) {
        convert_framebuffers(framebuffer_request.response);
    }

    bool ahci = detect_ahci_drives();
    bool ide;

    if (ahci) {
        asm volatile("mov $0x90, %rdx");
        ide = false;
        hcf();
    }
    else {
        ide = detect_ide_drives();
        if (ide) {
            asm volatile("mov $0x80, %rdx");
            hcf();
        }
        else {
            triple_fault();
        }
    }

    if (ide) ide_load_kernel();
    else if (ahci) ahci_load_kernel();
    else triple_fault();
    
    while (1);
}