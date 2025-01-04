arm-none-eabi-as -g -a=hellorld.list hellorld.s -o hellorld.o
arm-none-eabi-ld -g hellorld.o -T./stm32f103rb.ld -o hellorld.elf
arm-none-eabi-objcopy -O binary hellorld.elf hellorld.bin
# Can also use nm or readelf -S
objdump -t hellorld.elf > hellorld.sym
st-flash write hellorld.bin 0x8000000
