CFLAGS := gcc -Wall -Wextra -nostdlib -fno-stack-protector -I./bootmgr/inc --entry start -m32 -fno-builtin -O1

SRCFILES := ./bootmgr/src/bootmgr.c
BINFILE := ./bootmgr/bin/bootmgr.bin
MESSAGE := ""

ELFSRCS := ./setup/src/kmain.c

gcc:
	$(CFLAGS) $(SRCFILES) -o $(BINFILE)
	objcopy --only-section=.text --only-section=.data --only-section=.bss -O binary $(BINFILE)

#efibuild:
#	gcc -Ignu-efi/inc -fpic -ffreestanding -fno-stack-protector -fno-stack-check -fshort-wchar -mno-red-zone -maccumulate-outgoing-args -c ./efi/src/main.c -o ./efi/obj/main.o
#	ld -shared -Bsymbolic -Lgnu-efi/x86_64/lib -Lgnu-efi/x86_64/gnuefi -Tgnu-efi/gnuefi/elf_x86_64_efi.lds gnu-efi/x86_64/gnuefi/crt0-efi-x86_64.o ./efi/obj/main.o -o ./efi/obj/main.so -lgnuefi -lefi
#	objcopy -j .text -j .sdata -j .data -j .rodata -j .dynamic -j .dynsym  -j .rel -j .rela -j .rel.* -j .rela.* -j .reloc --target efi-app-x86_64 --subsystem=10 ./efi/obj/main.so ./efi/bin/BOOTX64.efi

run:
	qemu-system-x86_64 -display sdl -monitor stdio -cpu max -m 1G \
  	-drive if=pflash,format=raw,unit=0,file=./test/OVMF_CODE.fd,readonly=on \
  	-drive if=pflash,format=raw,unit=1,file=./test/OVMF_VARS.fd \
	-drive id=disk,file=./test/disc.vhd,if=none,format=raw \
	-device ahci,id=ahci -device ide-hd,drive=disk,bus=ahci.0 \
	-net none

build:
	nasm -f bin ./bootmgr/src/setup.asm -o ./bootmgr/bin/setup.bin

git:
	git add ./
	git commit -a -m "$(MESSAGE)"
	git push

sync:
	git add ./
	git commit -a -m "$(MESSAGE)""
	git pull
	git push

efi_reset:
	git checkout HEAD -- ./test/OVMF_VARS.fd

liminebuild:
	x86_64-elf-gcc -Isetup/inc -ffreestanding -fno-stack-protector -fno-stack-check -nostdlib -nostartfiles -T./setup/linker.ld -Wall -Wextra $(ELFSRCS) -o ./setup/bin/setup.elf

limine: liminebuild
	copy /b .\setup\bin\setup.elf E:\limine\yutboo\\

asm: build write run
efi: liminebuild run

#	ld -shared -Bsymbolic -Lgnu-efi/x86_64/lib -Lgnu-efi/x86_64/gnuefi -Tgnu-efi/gnuefi/elf_x86_64_efi.lds gnu-efi/x86_64/gnuefi/crt0-efi-x86_64.o ./efi/obj/main.o -o ./efi/obj/main.so -lgnuefi -lefi
#	objcopy -j .text -j .sdata -j .data -j .rodata -j .dynamic -j .dynsym  -j .rel -j .rela -j .rel.* -j .rela.* -j .reloc --target efi-app-x86_64 --subsystem=10 ./efi/obj/main.so ./efi/bin/BOOTX64.efi