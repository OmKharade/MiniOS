Write-Host "Assembling bootloader..." -ForegroundColor Yellow
nasm -f bin boot.asm -o boot.bin
Write-Host "Starting QEMU emulator..." -ForegroundColor Yellow
qemu-system-x86_64 -fda boot.bin
Write-Host ""
Write-Host "Build and run completed!" -ForegroundColor Green 