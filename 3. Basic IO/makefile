boot.bin: boot.asm
	nasm -f bin boot.asm -o boot.bin

kernel.bin: kernel.asm
	nasm -f bin kernel.asm -o kernel.bin

disk.img: boot.bin kernel.bin
	cat boot.bin kernel.bin > disk.img

run: disk.img
	qemu-system-i386 -fda disk.img -monitor stdio

clean:
	rm -f boot.bin kernel.bin disk.img