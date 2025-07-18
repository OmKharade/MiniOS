Write-Host "Building OS..." -ForegroundColor Green

# Compile bootloader
Write-Host "Compiling bootloader..." -ForegroundColor Yellow
nasm -f bin "boot.asm" -o boot.bin
if (-not $?) {
    Write-Host "Error compiling bootloader!" -ForegroundColor Red
    exit 1
}

# Compile kernel
Write-Host "Compiling kernel..." -ForegroundColor Yellow
nasm -f bin "kernel.asm" -o kernel.bin
if (-not $?) {
    Write-Host "Error compiling kernel!" -ForegroundColor Red
    exit 1
}

# Create disk image
Write-Host "Creating disk image..." -ForegroundColor Yellow
try {
    (Get-Content -Path boot.bin -Raw -Encoding Byte), 
    (Get-Content -Path kernel.bin -Raw -Encoding Byte) | 
    Set-Content -Path disk.img -Encoding Byte
}
catch {
    Write-Host "Error creating disk image: $_" -ForegroundColor Red
    exit 1
}

# Run QEMU with debug output
Write-Host "Starting QEMU..." -ForegroundColor Yellow
qemu-system-i386 -fda disk.img -monitor stdio

Write-Host "Done!" -ForegroundColor Green