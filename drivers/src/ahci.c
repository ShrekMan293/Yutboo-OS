#include "fis.h"
#include "int.h"
#include <stdbool.h>
#include <stdint.h>

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

void detect_ahci_drives() {
    for (uint8_t bus = 0; bus < 255; bus++) {
        for (uint8_t device = 0; device < 32; device++) {
            for (uint8_t func = 0; func < 8; func++) {
                uint32_t vendor_device_id = pci_read(bus, device, func, 0);

                if (vendor_device_id != 0xFFFFFFFF) {
                    uint16_t vendor_id = vendor_device_id & 0xFFFF;
                    uint16_t device_id = (vendor_device_id & 0xFFFF0000) >> 16;

                    // Check if it's an AHCI Controller
                    if (vendor_id == 0x8086) {
                        if (device_id == 0x3A22 || device_id == 0x3A20) {
                            asm volatile("mov $1, %r14");
                        }
                    }
                    else if (vendor_id == 0x1022) {
                        if (device_id == 0x7901) {
                            asm volatile("mov $1, %r14");
                        }
                    }
                    else if (vendor_id == 0x1B4B) {
                        if (device_id == 2382) {
                            asm volatile("mov $1, %r14");
                        }
                    }
                }
            }
        }
    }

    while(true);
}

//void init() __attribute__((section(".init")));

void drvmain() {

}

__attribute__((section(".magic_number")))
const char driver_magic[] = "Yboo";

void init() __attribute__((section(".init")));
//void init();

void init() {
    detect_ahci_drives();
}