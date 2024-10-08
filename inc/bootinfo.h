#include <stdint.h>
#include <stdbool.h>
#include <stddef.h>

typedef struct {
    uint64_t base;
    uint64_t length;
    uint8_t type;
} memmap_entry;

typedef struct {
    uint64_t count;
    memmap_entry entries[];
} memmap_t;

typedef struct {
    uint64_t address;
    uint64_t width;
    uint64_t height;
    uint64_t pitch;
    uint16_t bpp;
    uint8_t memory_model;
    uint8_t red_mask_size;
    uint8_t red_mask_shift;
    uint8_t green_mask_size;
    uint8_t green_mask_shift;
    uint8_t blue_mask_size;
    uint8_t blue_mask_shift;
    uint8_t unused[7];
    uint64_t edid_size;
} framebuffer;

typedef struct {
    uint64_t count;
    framebuffer entries[];
} framebuffers;

struct boot_info {
    memmap_t memmap;
    const char* protocol = "limine";

    bool is_ahci;
    uint64_t disk_size;
    uint64_t partition_start;
    uint64_t partition_end;

    
};