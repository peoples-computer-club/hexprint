arm-none-eabi-as -g -a=hexprint.list hexprint.s -o hexprint.o
arm-none-eabi-ld -g hexprint.o -T./stm32f103rb.ld -o hexprint.elf
arm-none-eabi-objcopy -O binary hexprint.elf hexprint.bin
# Can also use nm or readelf -S
objdump -t hexprint.elf > hexprint.sym
st-flash write hexprint.bin 0x8000000
