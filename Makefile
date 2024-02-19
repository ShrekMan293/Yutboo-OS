CFLAGS := gcc -Wall -Wextra -nostdlib -fno-stack-protector -I./bootmgr/inc --entry start -m32 -fno-builtin -O1

SRCFILES := ./bootmgr/src/bootmgr.c
BINFILE := ./bootmgr/bin/bootmgr.bin

gcc:
	$(CFLAGS) $(SRCFILES) -o $(BINFILE)
	objcopy --only-section=.text --only-section=.data --only-section=.bss -O binary $(BINFILE)

efibuild:
	gcc -Ignu-efi/inc -fpic -ffreestanding -fno-stack-protector -fno-stack-check -fshort-wchar -mno-red-zone -maccumulate-outgoing-args -c ./efi/src/main.c -o ./efi/obj/main.o
	ld -shared -Bsymbolic -Lgnu-efi/x86_64/lib -Lgnu-efi/x86_64/gnuefi -Tgnu-efi/gnuefi/elf_x86_64_efi.lds gnu-efi/x86_64/gnuefi/crt0-efi-x86_64.o ./efi/obj/main.o -o ./efi/obj/main.so -lgnuefi -lefi
	objcopy -j .text -j .sdata -j .data -j .rodata -j .dynamic -j .dynsym  -j .rel -j .rela -j .rel.* -j .rela.* -j .reloc --target efi-app-x86_64 --subsystem=10 ./efi/obj/main.so ./efi/bin/BOOTX64.efi

run:
	qemu-system-x86_64 -display sdl -monitor stdio -cpu qemu64 \
  	-drive if=pflash,format=raw,unit=0,file=./test/OVMF_CODE.fd,readonly=on \
  	-drive if=pflash,format=raw,unit=1,file=./test/OVMF_VARS.fd \
	-drive if=ide,format=raw,file=./test/disc.vhd -net none

build:
	nasm -f bin ./bootmgr/src/setup.asm -o ./bootmgr/bin/setup.bin

asm: build write run