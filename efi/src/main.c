#include <efi.h>
#include <efilib.h>

#define PCI_VENDOR_ID_OFFSET 0x00
#define PCI_DEVICE_ID_OFFSET 0x02
#define PCI_CLASS_CODE_OFFSET 0x0B

#define AHCI_VENDOR_ID 0x1B4B
#define AHCI_DEVICE_ID 0x91A2
#define IDE_VENDOR_ID 0x8086
#define IDE_DEVICE_ID 0x2922

#define AHCI_CLASS_CODE 0x010601
#define IDE_CLASS_CODE 0x01018A


#define PCI_CONFIG_ADDR  0xCF8  // Configuration address register
#define PCI_CONFIG_DATA  0xCFC  // Configuration data register

UINT8 getStorageType();
void read_pci_config(uint32_t bus, uint32_t slot, uint32_t func, uint32_t offset, uint32_t* value);
UINT8 DetectStorageController(EFI_HANDLE ImageHandle);

typedef struct {
    UINTN memSize;
    UINTN discSize;
    UINTN blockSize;
    UINT16 pageSize;
    UINT8 detectedDisc;
} BootInfo;

EFI_STATUS
EFIAPI
efi_main (EFI_HANDLE ImageHandle, EFI_SYSTEM_TABLE *SystemTable)
{
    BootInfo boot;
    boot.pageSize = 4096;

    InitializeLib(ImageHandle, SystemTable);
    Print(L"Hello World!\n");

    // Clear the screen
    uefi_call_wrapper(ST->ConOut->ClearScreen, 1, ST->ConOut);

    EFI_STATUS Status;
    int retry = -1;
    EFI_MEMORY_DESCRIPTOR MemoryMap[4096];
    UINTN MemoryMapSize;
    UINTN MapKey;
    UINTN DescriptorSize;
    UINT32 DescriptorVersion;
    UINTN MemorySize = 0;

    do
    {
        retry++;

        Status = uefi_call_wrapper(
            SystemTable->BootServices->GetMemoryMap,
            5,
            &MemoryMapSize,
            MemoryMap,
            &MapKey,
            &DescriptorSize,
            &DescriptorVersion
        );
    } while (EFI_ERROR(Status) && retry <= 100);
    

    if (EFI_ERROR(Status) && retry > 100) {
        Print(L"Failed to get memory map: %r\n", Status);
        while (EFI_ERROR(Status)) Status = uefi_call_wrapper(SystemTable->BootServices->Stall, 1, 1000000);
        return Status;
    }

    UINTN NumberOfPages = 0;

    EFI_MEMORY_DESCRIPTOR* MemoryMapEntry = MemoryMap;
    for (UINTN i = 0; i < MemoryMapSize / DescriptorSize; i++) {
        NumberOfPages += MemoryMapEntry->NumberOfPages;
        MemorySize += MemoryMapEntry->NumberOfPages * EFI_PAGE_SIZE;
        MemoryMapEntry = (EFI_MEMORY_DESCRIPTOR *)((UINTN)MemoryMapEntry + DescriptorSize);
    }

    boot.memSize = MemorySize;

    retry = -1;
    do
    {
        EFI_GUID blockIoProtocolGuid = EFI_BLOCK_IO_PROTOCOL_GUID;
        EFI_BLOCK_IO_PROTOCOL *BlockIo;
        retry++;

        // Locate the Block I/O Protocol handle for the disk device
        Status = uefi_call_wrapper(
            SystemTable->BootServices->LocateProtocol,
            3,
            &blockIoProtocolGuid,
            NULL,
            (VOID **)&BlockIo
        );
        if (EFI_ERROR(Status)) {
            Print(L"Failed to locate Block I/O Protocol: %r\n", Status);
            while (EFI_ERROR(Status)) Status = uefi_call_wrapper(SystemTable->BootServices->Stall, 1, 1000000);
            return Status;
        }

        // Check if the Block I/O device is present
        if (BlockIo->Media->MediaPresent) {
            // Get the size of the disk
            UINT64 DiskSize = BlockIo->Media->LastBlock * BlockIo->Media->BlockSize;
            boot.discSize = DiskSize;
            break;
        } else {
            Print(L"Block I/O device not present, please restart with a drive\n");
        }

    } while (EFI_ERROR(Status) && retry <= 100);
    
    boot.detectedDisc = DetectStorageController(ImageHandle);

    if (boot.detectedDisc == 255) return EFI_SUCCESS;
    else if (boot.detectedDisc == 0) asm("cli\n\t hlt");
    else if (boot.detectedDisc == 1) asm volatile("mov $0x90, %eax\n\t cli\n\t hlt");
    else if (boot.detectedDisc == 2) asm volatile("mov $1, %r9\n\t cli\n\t hlt");
    else while (1);

    uefi_call_wrapper(SystemTable->BootServices->ExitBootServices, 0);

    asm("cli\n\t hlt");

    return EFI_SUCCESS;
}


UINT8 DetectStorageController(EFI_HANDLE ImageHandle) {
    EFI_STATUS Status;
    EFI_PCI_IO_PROTOCOL *PciIo;
    UINT16 DeviceID, VendorID, ClassCode;
    UINT8 ClassCodeBase, ClassCodeSub;

    // Locate the PCI I/O protocol
    Status = gBS->HandleProtocol(ImageHandle, &gEfiPciIoProtocolGuid, (VOID **)&PciIo);
    if (EFI_ERROR(Status)) {
        return 2;
    }

    // Read PCI configuration space to get device and vendor IDs
    Status = PciIo->Pci.Read(
        PciIo,
        EfiPciIoWidthUint16,
        PCI_VENDOR_ID_OFFSET,
        1,
        &VendorID
    );
    if (EFI_ERROR(Status)) {
        return 2;
    }

    Status = PciIo->Pci.Read(
        PciIo,
        EfiPciIoWidthUint16,
        PCI_DEVICE_ID_OFFSET,
        1,
        &DeviceID
    );
    if (EFI_ERROR(Status)) {
        return 2;
    }

    // Read PCI configuration space to get class code
    Status = PciIo->Pci.Read(
        PciIo,
        EfiPciIoWidthUint8,
        PCI_CLASS_CODE_OFFSET,
        1,
        &ClassCodeBase
    );
    if (EFI_ERROR(Status)) {
        return 2;
    }

    Status = PciIo->Pci.Read(
        PciIo,
        EfiPciIoWidthUint8,
        PCI_CLASS_CODE_OFFSET + 1,
        1,
        &ClassCodeSub
    );
    if (EFI_ERROR(Status)) {
        return 2;
    }

    // Combine base and sub class codes
    ClassCode = (ClassCodeBase << 8) | ClassCodeSub;

    // Check if the controller is AHCI or IDE
    if (VendorID == AHCI_VENDOR_ID && DeviceID == AHCI_DEVICE_ID && ClassCode == AHCI_CLASS_CODE) {
        return 1;
    } else if (VendorID == IDE_VENDOR_ID && DeviceID == IDE_DEVICE_ID && ClassCode == IDE_CLASS_CODE) {
        return 0;
    } else {
        return 255;
    }
}

UINT8 getStorageType() {
    uint32_t class_code;
    uint32_t subclass_code;

    // Iterate through PCI buses, slots, and functions
    for (uint32_t bus = 0; bus < 256; bus++) {
        for (uint32_t slot = 0; slot < 32; slot++) {
            for (uint32_t func = 0; func < 8; func++) {
                uint32_t value;
                read_pci_config(bus, slot, func, 0x08, &value); // Read class code register
                class_code = value & 0xFF000000; // Mask upper 8 bits
                subclass_code = value & 0x00FF0000; // Mask middle 8 bits

                // Check for AHCI controller
                if (class_code == 0x01060000 && subclass_code == 0x00010000) {
                    return 1;
                }

                // Check for IDE controller
                else if (class_code == 0x01010000 && subclass_code == 0x00010000) {
                    return 0;
                }

                else return 255;
            }
        }
    }
}

void outl(uint16_t address, uint32_t value) {
    asm volatile("outl %1, %0"
                :
                : "d" (address), "a" (value)
                :);
}

uint32_t inl(uint16_t address) {
    uint32_t data;

    // Input: address - The I/O port address
    // Output: data    - The value read from the I/O port
    asm volatile("inl %1, %0"
                : "=a"(data)  // Use the "a" constraint for the accumulator register
                : "d"(address) // Use the "d" constraint for the I/O port address
                : "memory");

    return data;
}

void read_pci_config(uint32_t bus, uint32_t slot, uint32_t func, uint32_t offset, uint32_t* value) {
    uint32_t address = (0x1 << 31) | (bus << 16) | (slot << 11) | (func << 8) | (offset & 0xFC);
    outl(PCI_CONFIG_ADDR, address);
    *value = inl(PCI_CONFIG_DATA + (offset & 0x03));
}