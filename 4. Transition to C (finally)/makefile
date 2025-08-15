CC = gcc
CFLAGS = -m32 -ffreestanding -fno-pie -nostdlib -Wall -Wextra -O0

all: boot.bin kernel.bin os.img

boot.bin: boot.asm
	nasm -f bin boot.asm -o boot.bin

kernel.o: kernel.asm
	nasm -f elf32 kernel.asm -o kernel.o

kmain.o: kmain.c
	$(CC) $(CFLAGS) -c kmain.c -o kmain.o

kernel.elf: kernel.o kmain.o linker.ld
	ld -m elf_i386 -T linker.ld kernel.o kmain.o -o kernel.elf

kernel.bin: kernel.elf
	objcopy -O binary kernel.elf kernel.bin

os.img: boot.bin kernel.bin
	dd if=/dev/zero of=os.img bs=512 count=2880
	dd if=boot.bin of=os.img conv=notrunc
	dd if=kernel.bin of=os.img bs=512 seek=1 conv=notrunc

run: os.img
	qemu-system-i386 -fda os.img

clean:
	rm -f *.o *.bin *.elf os.img