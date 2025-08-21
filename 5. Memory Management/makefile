# thank god for this makefile

# --- Toolchain (from your old Makefile) ---
CC = gcc
AS = nasm
LD = ld
OBJCOPY = objcopy

# --- Directories (for new project structure) ---
SRC_DIR_BOOT = boot
SRC_DIR_KRNL = kernel/src
INC_DIR_KRNL = kernel/include
OBJ_DIR = obj
BIN_DIR = bin

# --- Compiler and Assembler Flags ---
# Flags from your old Makefile, with the include path added
CFLAGS = -m32 -ffreestanding -fno-pie -nostdlib -Wall -Wextra -O0 -I$(INC_DIR_KRNL)
ASFLAGS_KRNL = -f elf32
ASFLAGS_BOOT = -f bin
LDFLAGS = -m elf_i386

# --- Source Files and Object Files (Automatic discovery) ---
KRNL_C_SOURCES = $(wildcard $(SRC_DIR_KRNL)/*.c)
KRNL_ASM_SOURCES = $(wildcard $(SRC_DIR_KRNL)/*.asm)
KRNL_C_OBJS = $(patsubst $(SRC_DIR_KRNL)/%.c, $(OBJ_DIR)/%.o, $(KRNL_C_SOURCES))
KRNL_ASM_OBJS = $(patsubst $(SRC_DIR_KRNL)/%.asm, $(OBJ_DIR)/%.o, $(KRNL_ASM_SOURCES))
KRNL_OBJS = $(KRNL_C_OBJS) $(KRNL_ASM_OBJS)

# --- Targets ---

# Default target
all: os.img

# Create the final disk image using your dd method
os.img: $(BIN_DIR)/boot.bin $(BIN_DIR)/kernel.bin
	@echo "Creating disk image os.img..."
	@dd if=/dev/zero of=os.img bs=512 count=2880
	@dd if=$(BIN_DIR)/boot.bin of=os.img conv=notrunc
	@dd if=$(BIN_DIR)/kernel.bin of=os.img bs=512 seek=1 conv=notrunc

# Create the final flat binary kernel
$(BIN_DIR)/kernel.bin: $(BIN_DIR)/kernel.elf
	@echo "Converting ELF to binary..."
	@$(OBJCOPY) -O binary $< $@

# Link the kernel using your ld method
$(BIN_DIR)/kernel.elf: $(KRNL_OBJS) kernel/kernel.ld
	@echo "Linking kernel..."
	@mkdir -p $(dir $@)
	@$(LD) $(LDFLAGS) -T kernel/kernel.ld $(KRNL_OBJS) -o $@

# Rule to compile C kernel files
$(OBJ_DIR)/%.o: $(SRC_DIR_KRNL)/%.c
	@echo "Compiling $<..."
	@mkdir -p $(dir $@)
	@$(CC) $(CFLAGS) -c $< -o $@

# Rule to assemble assembly kernel files
$(OBJ_DIR)/%.o: $(SRC_DIR_KRNL)/%.asm
	@echo "Assembling $<..."
	@mkdir -p $(dir $@)
	@$(AS) $(ASFLAGS_KRNL) $< -o $@

# Assemble the bootloader
$(BIN_DIR)/boot.bin: $(SRC_DIR_BOOT)/boot.asm
	@echo "Assembling bootloader..."
	@mkdir -p $(dir $@)
	@$(AS) $(ASFLAGS_BOOT) $< -o $@

# Run with QEMU
run: os.img
	@qemu-system-i386 -fda os.img

# Clean up all build files
clean:
	@echo "Cleaning up..."
	@rm -rf $(OBJ_DIR) $(BIN_DIR) os.img

# Declare targets that are not actual files
.PHONY: all run clean