# === Config ===
AS         := nasm
CC         := g++
LD         := ld

SRC_DIR    := ./boot/src
BUILD_DIR  := ./boot/build
ISO_DIR    := iso
GRUB_DIR   := $(ISO_DIR)/boot/grub

CFLAGS     := -ffreestanding -m64 -nostdlib -nostdinc -fno-builtin -fno-exceptions -fno-rtti -O2 -Wall -Wextra -I./inc
LDFLAGS    := -T linker.ld -nostdlib

# === Files ===
SOURCES    := $(wildcard $(SRC_DIR)/*.s)
C_SOURCES  := $(wildcard $(SRC_DIR)/*.cpp)
OBJS       := $(SOURCES:.s=.o) $(C_SOURCES:.cpp=.o)
OBJS       := $(patsubst $(SRC_DIR)/%, $(BUILD_DIR)/%, $(OBJS))

KERNEL_BIN := $(BUILD_DIR)/yutbook.elf
ISO_IMAGE  := ./test/disc.vhd

# === Targets ===
all: $(ISO_IMAGE)

# Compile assembly files
$(BUILD_DIR)/%.o: $(SRC_DIR)/%.s
	mkdir -p $(BUILD_DIR)
	$(AS) -felf64 -o $@ $<

# Compile C files
$(BUILD_DIR)/%.o: $(SRC_DIR)/%.cpp
	mkdir -p $(BUILD_DIR)
	$(CC) $(CFLAGS) -c $< -o $@

# Link kernel
$(KERNEL_BIN): $(OBJS) linker.ld
	$(LD) $(LDFLAGS) -o $@ $(OBJS)

# Create ISO
$(ISO_IMAGE): $(KERNEL_BIN)
	sudo cp $(KERNEL_BIN) ./test/mnt/boot/yutboo

clean:
	rm -rf $(BUILD_DIR)
	rm ./OVMF_VARS_4M.fd
	cp /usr/share/OVMF/OVMF_VARS_4M.fd ./

run: all
	./run

.PHONY: all clean
