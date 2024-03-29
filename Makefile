CFLAGS := gcc -Wall -Wextra -nostdlib -fpic -ffreestanding -fno-stack-protector \
 			-fno-stack-check -fshort-wchar -mno-red-zone -maccumulate-outgoing-args -I./inc \
 			--entry start -m32 -fno-builtin -O1

DRVSRCFILES := ./drivers/src/ahci.c
DRVBINFILE := ./drivers/bin/ahci.bin

driver: driverbuild driverwrite

driverbuild:
	$(CFLAGS) $(DRVSRCFILES) -o $(DRVBINFILE)
	objcopy --only-section=.text --only-section=.data --only-section=.bss -O binary $(DRVBINFILE)
driverwrite:
	dd $(DRVBINFILE) ./test/disc.vhd 204800 4

efibuild:
	gcc -Ignu-efi/inc -fpic -ffreestanding -fno-stack-protector -fno-stack-check -fshort-wchar -mno-red-zone -maccumulate-outgoing-args -e efi_main -c ./efi/src/main.c -o ./efi/obj/main.o
	ld -shared -Bsymbolic -Lgnu-efi/x86_64/lib -Lgnu-efi/x86_64/gnuefi -Tgnu-efi/gnuefi/elf_x86_64_efi.lds gnu-efi/x86_64/gnuefi/crt0-efi-x86_64.o ./efi/obj/main.o -o ./efi/obj/main.so -lgnuefi -lefi
	objcopy -j .text -j .sdata -j .data -j .rodata -j .dynamic -j .dynsym  -j .rel -j .rela -j .rel.* -j .rela.* -j .reloc --target efi-app-x86_64 --subsystem=10 ./efi/obj/main.so ./efi/bin/BOOTX64.efi

run-efi:
	qemu-system-x86_64 -display sdl -monitor stdio -cpu max -m 8G \
  	-drive if=pflash,format=raw,unit=0,file=./test/OVMF_CODE.fd,readonly=on \
  	-drive if=pflash,format=raw,unit=1,file=./test/OVMF_VARS.fd \
	-drive id=disk,file=./test/disc.vhd,if=none,format=raw \
	-device ahci,id=ahci -device ide-hd,drive=disk,bus=ahci.0 \
	-net none

run-bios:
	qemu-system-x86_64 -display sdl -monitor stdio -cpu max -m 8G \
	-drive id=disk,file=./test/bios.vhd,if=none,format=raw \
	-device ahci,id=ahci -device ide-hd,drive=disk,bus=ahci.0 \
	-net none

drive:
	qemu-img create -f raw ./test/bios.vhd 2G

build:
	nasm -f bin ./bios/src/setup.asm -o ./bios/bin/setup.bin
write:
	dd ./bios/bin/setup.bin ./test/bios.vhd 0 1

asm: build write run-bios