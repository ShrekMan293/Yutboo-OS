#include <efi.h>
#include <efilib.h>

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

    uefi_call_wrapper(SystemTable->BootServices->ExitBootServices, 0);

    asm("cli\n\t hlt");

    return EFI_SUCCESS;
}