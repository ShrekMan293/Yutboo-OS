DRVFILES := ./drivers/src/ahci.c
DRVBIN := ./drivers/bin/diskDriver.elf
MESSAGE := ""

ELFSRCS := ./setup/src/kmain.c

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

run-ide:
	qemu-system-x86_64 -display sdl -monitor stdio -cpu max -m 1G \
  	-drive if=pflash,format=raw,unit=0,file=./test/OVMF_CODE.fd,readonly=on \
  	-drive if=pflash,format=raw,unit=1,file=./test/OVMF_VARS.fd \
	-drive id=disk,file=./test/disc.vhd,if=ide,format=raw \
	-net none

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
	x86_64-elf-gcc -I./inc -ffreestanding -fno-stack-protector -fno-stack-check -nostdlib -nostartfiles -lgcc -T./setup/linker.ld -Wall -Wextra $(ELFSRCS) -o ./setup/bin/setup.elf

limine_wsl: liminebuild
	copy /b .\setup\bin\setup.elf "\\wsl.localhost\Ubuntu\mnt\esp\limine\yutboo"
	copy /b .\test\limine.conf "\\wsl.localhost\Ubuntu\mnt\esp\limine\limine.conf"
limine: liminebuild
	copy /b .\setup\bin\setup.elf "E:\limine\yutboo\setup.elf"
	copy /b .\test\limine.conf "E:\limine\limine.conf"

driver:
	x86_64-elf-gcc -I./inc -I./drivers/inc -ffreestanding -fpic -fno-stack-protector -fno-stack-check -nostdlib -nostartfiles -lgcc -T./drivers/linker.ld -Wall -Wextra $(DRVFILES) -o $(DRVBIN)

build_wsl: limine_wsl driver
	copy /b .\drivers\bin\diskDriver.elf "\\wsl.localhost\Ubuntu\mnt\esp\limine\yutboo"

build: limine driver
	copy /b .\drivers\bin\diskDriver.elf "E:\limine\yutboo\diskDriver.elf"

all: build run

#	ld -shared -Bsymbolic -Lgnu-efi/x86_64/lib -Lgnu-efi/x86_64/gnuefi -Tgnu-efi/gnuefi/elf_x86_64_efi.lds gnu-efi/x86_64/gnuefi/crt0-efi-x86_64.o ./efi/obj/main.o -o ./efi/obj/main.so -lgnuefi -lefi
#	objcopy -j .text -j .sdata -j .data -j .rodata -j .dynamic -j .dynsym  -j .rel -j .rela -j .rel.* -j .rela.* -j .reloc --target efi-app-x86_64 --subsystem=10 ./efi/obj/main.so ./efi/bin/BOOTX64.efi