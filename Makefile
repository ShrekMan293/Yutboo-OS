write:
	dd ./boot/bin/boot.bin ./test/disc.img 0 1

disc:
	qemu-img create -f raw ./test/disc.img 1G

run:
	qemu-system-x86_64 -display sdl -monitor stdio -drive file=./test/disc.img,format=raw

build:
	nasm -f bin ./boot/src/setup.asm -o ./boot/bin/boot.bin

asm: build write run