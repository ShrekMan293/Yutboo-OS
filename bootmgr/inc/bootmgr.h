typedef unsigned short u16;
typedef unsigned char u8;
typedef unsigned int u32;

typedef struct {
    char name[24];
    u32 kernel_lba;
    u32 depen1_lba;
    u32 depen2_lba;
    u32 depen1_size;
    u32 depen2_size;
    u32 kernel_size;
    u32 eax_value;
    u32 ebx_value;
    u32 ecx_value;
    u32 edx_value;
} boot_entry;