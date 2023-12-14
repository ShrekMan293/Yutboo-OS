CFLAGS := gcc -Wall -Wextra -nostdlib -fno-stack-protector -I./bootmgr/inc --entry start -m32 -fno-builtin -O1

SRCFILES := ./bootmgr/src/bootmgr.c
BINFILE := ./bootmgr/bin/bootmgr.bin

all: build write c run

c: gcc c_write

gcc:
	$(CFLAGS) $(SRCFILES) -o $(BINFILE)
	objcopy --only-section=.text --only-section=.data --only-section=.bss -O binary $(BINFILE)

c_write:
	dd ./bootmgr/bin/bootmgr.bin ./test/disc.img 1 1

write:
	dd ./bootmgr/bin/setup.bin ./test/disc.img 0 1

disc:
	qemu-img create -f raw ./test/disc.img 1G

run:
	qemu-system-x86_64 -display sdl -monitor stdio -drive file=./test/disc.img,format=raw

build:
	nasm -f bin ./bootmgr/src/setup.asm -o ./bootmgr/bin/setup.bin

asm: build write run