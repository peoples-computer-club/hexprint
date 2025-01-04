// Hellorld.s written for a STM32F103RB CPU on a NUCLEO64 dev board
// Copyright (C) 2025 People's Computer Club, LLC
// 
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// 
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
// 
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

// The syntax, cpu, and thumb directives let the assembler know
// how to interpret and compile the ssembly language instructions
// in this file. Full documentation here:
// https://sourceware.org/binutils/docs/as/ARM-Directives.html

// This lets the assembler know what assembly language "dialect"
// we are using. Because of the long history of ARM CPUs, there
// are a few different syntaxes for their chips. Unified syntax
// was created by ARM to merge all those syntaxes into one, and
// is the current and recommended syntax that is in most
// documentation.

.syntax unified

// This is the CPU we are targeting. The ARM architecture of the
// Cortex-m3 is ARMv7-M, so specifying the CPU also specifies
// the architecture.
.cpu cortex-m3

// Even though the Cortex-M3 only supports Thumb, we need to
// let the assembler know that our assembly language should be
// interpreted as Thumb instructions not Arm instructions.
.thumb

// The data and text sections are mainly for the linker, to
// put the right things in the right place. There is a linker
// script which will tell the linker about the memory of the
// computer this program is intended for. Which sections are
// RAM and which are ROM, etc. Full documentation here:
// https://sourceware.org/binutils/docs/as/Ld-Sections.html

// For our purposes, this will be the RAM section, where variables
// and runtime stuff will go. In general, by convention, .bss
// section is for uninitialized (assumed 0) data, and .data is
// for data with an initialized value. This is more important
// in higher level languages like C. For our purposes it makes
// no difference. If you are interested in the history of "bss"
// here is the wikipedia article: https://en.wikipedia.org/wiki/.bss
.bss

// This is code and initialized data. For our purposes right now
// it will be what resides in ROM (Flash), but it doesn't have to.
// https://en.wikipedia.org/wiki/Code_segment
.text

// The STM32F103RB we are using has 128Kb of Flash, which makes it
// a "medium-density" device for purposes of the STM32F1 reference
// manual (page 46 of RM0008 rev 21).

// According to the STM32F10x Cortex-M3 programming manual (pg 15)
// "On reset, the processor loads the MSP with the value from address
// 0x00000000." So our first word should contain the value of the start
// of stack. Generally, stack starts at the top of RAM and moves down.
// In our linker script, we will define "_estack" which stands for
// "end of stack" by convention, but because we grow the stack down
// from the top of RAM, the end (from memory's perspective) is actually
// the beginning. So our first address is that value.

// Following that, the vector interrupt table on a Cortex-M3 contains a
// set of memory addresses to jump to when a given interrupt is called.
// The first of these is the "Reset" interrupt, which get calls when
// the CPU is started or reset. This is the one that we will use for now
// and it will point to the start of our code.
// (see table 63 in the STM32F1 reference manual, page 204)
vtable:
    .word _estack		        // 0 Top of Stack
                                // (_estack will be defined in linker script)
    .word reset_handler	        // 1 Reset interrupt
    // Fill directive has as arguments repeat #, size in bytes, and optional
    // value -- if unspecified it's 0.
    // (https://ftp.gnu.org/old-gnu/Manuals/gas-2.9.1/html_node/as_89.html)
    .fill 74, 4                 // We don't care about the rest right now

// This is data, but it is in the "text" section because it is a constant
// And thus will be in ROM/Flash.
string:
    // The tag .asciz indicates a null (zero) terminated string.
    // (https://ftp.gnu.org/old-gnu/Manuals/gas-2.9.1/html_node/as_71.html)
    .asciz "Hellorld!\r\n"

// Code must be aligned on a half word, in case the size of data above isn't
// a multiple of 2 bytes. We align on a word so the processor can fetch 32
// bits in one go (32 bit fetch has to be word aligned) rather than two
// 16 bit fetches. Not required, but a little speed boost maybe?
// (https://ftp.gnu.org/old-gnu/Manuals/gas-2.9.1/html_node/as_68.html)
.align 4

// This is required to define the entry point for the linker
_start:

// This is what will get called when the CPU is reset (and the Reset interrupt
// is triggered)
reset_handler:
    // What do we need to do to set up things? I don't feel that the reference
    // documents give a good answer, without digging into every section.
    // So in cases such as this, looking a code is the easiest. The most "official"
    // code is the CMSIS is an ARM standard way to interface with different
    // ARM Cortex-M CPUs by different manufacturers, but using the same code
    // (C, generally). So all the low-level drivers/init/etc. is coded by
    // the manufacturers. In this case, ST, and it's located here:
    // (https://github.com/STMicroelectronics/cmsis-device-f1/tree/master)
    // We can look at the code here to guide the way. Starting with the
    // startup assembler code, which implements the vector table and the
    // reset code:
    // (https://github.com/STMicroelectronics/cmsis-device-f1/blob/master/Source/Templates/gcc/startup_stm32f102xb.s)
    // The reset handler there does a few things like copying initialized data
    // from Flash to RAM, and initializing un-initialized RAM to 0's. Right
    // now we don't really care about, as it's basically for C and higher
    // level languages and their expectations and standards.
    // All we care about right now is the call to SystemInit. It is defined in
    // the main C file here:
    // (https://github.com/STMicroelectronics/cmsis-device-f1/blob/master/Source/Templates/system_stm32f1xx.c)
    // We aren't using external RAM, nor relocating the vector table, so
    // there isn't anything we have to do, despite the comment that it
    // "Setups the system clock".
    // Even so, we don't need to setup the system clock, as we are just going
    // to use the internal 16MHz clock, which is the default. We'll dive
    // into using external clocks later.

    // So we don't HAVE to do anything. But for our example we want to print some text
    // on some sort of output. We don't have video output yet. Like the earliest personal
    // computers, like the Altair 8080 we just have a serial connection. In fact,
    // it's basically the same as the Altair... its a USART interface. The cool thing about
    // the Nucleo board is that the top part is a connection to the CPU-system that
    // gives us a bunch of stuff for free -- putting this code into the Flash, and
    // also exposing a USART that we can easily connect to on the host computer.
    // In section 6.8 of the NUCLEO-64 User's guide, it talks about how the device
    // exposes USART2 to the ST-LINK and thus the host computer.

    // We need to initialize USART2, and create a routine to send characters
    // to it. And then we'll have our program.

    // bl is like "gosub" -- it branches while putting the next address in the link
    // register -- bl = branch with link. This way we can return from the function
    // and continue running at the next address.
    bl uart2_init

    // We can pass arguments to functions any way we like, but ARM has a standard
    // called the "procedure call standard" so that different software can interact
    // with each other and know what to expect. That standard specifies that
    // "the first four registers r0-r3 (a1-a4) are used to pass argument values into
    // a subroutine and to return a result value from a function". See:
    // (https://github.com/ARM-software/abi-aa/releases/download/2024Q3/aapcs32.pdf)

    // We will make a function that takes the address of a null-terminated string
    // and outputs it to UART2. So first we load r0 with the address (that's what
    // the = means, the address of the label). This is actually a pseudo-instruction
    // (https://developer.arm.com/documentation/dui0041/c/Babbfdih) and it converts
    // it to another instruction, for example a PC-relative offset, so that the code
    // can be position-indepenent, and also because every ARM instruction is at most
    // 32 bits, and an ARM Cortex-M address is 32-bits wide in and of itself.
loop:
    ldr r0, =string
    // Now we keep calling our print string function over and over
    bl uart2_print_str
    b loop


// To use one of the perpherals on the CPU-system, we have to turn it on and then
// initialize it. Otherwise it stays off as if it didn't exist. This is nice, because
// we only have to deal with things as we need them. We can pretend this system just
// has a CPU and a UART chip (and memory of course), like a 6502 CPU and and 6551 UART
// chip. The only difference is it's all on one chip.
uart2_init:
  // First we need to enable the USART2 peripheral. Looking at the System architecture
  // in section 3.1 of the reference manual, you cansee that USART2 hangs off the APB1
  // bus, and we will need to enable the USART2 first.
  // To do that, we will need to find the APB1 registers, specifically the enable register
  // and flip the bit to enable USART2. That is found in section 7.3.8 APB1 peripheral
  // clock enable register (RCC_APB1ENR). ARM registers are memory-addressed, and
  // the address shown is 0x1C. However that is just an offset to the base value for
  // the set of RCC (Reset and Clock Control) registers. Turning the clock on for
  // a peripheral is what turns it on. Without a "heartbeat" the peripheral is dead.
  // The base address for the RCC registers is found in the memory map in section
  // 3.3 Memory Map. The first address listed is the base address of the registers,
  // and for the RCC registers, it's 0x40021000. So the address of the RCC_APB1ENR
  // register is 0x40021000 + 0x1C or 0x4002101C.

  // First, we'll load the address of the register into a CPU register. We can use
  // any CPU register we want, but to make things easier, the ARM procedure call
  // standard is: "A subroutine must preserve the contents of the registers r4-r8,
  // r10, r11 and SP (and r9 in PCS variants that designate r9 as v6)". We can
  // therefore use r0-r3 without special care.

  // Note that we are using the pseudo-instruction to load a 32 bit number.
  // We will load the base address of the RCC registers and do an offset load.
  ldr r0, =0x40021000

  // Next, we'll load the value at that address so that we can manipulate it
  ldr r1, [r0, 0x1C]

  // From the reference manual, USART2 enable is bit 17 set to 1. To do that
  // without modifying any other digit, we can OR it with the number 2^17
  orr r1, r1, #0x20000

  // Move modified value back to RCC_APB1ENR
  str r1, [r0, 0x1C]

  // Then, going back to the NUCLEO documentation, it notes that it taps PA2 and PA3 for
  // USART2, which are the default ports for USART2 (see section 9.3.8 USART alternate
  // function remapping in the reference manual). So in addition we need to enable the
  // Port A, which is on the APB2 bus. Section 7.3.7 APB2 peripheral clock enable
  // register (RCC_APB2ENR) shows the offset is 0x18 and bit 2 is IO port A clock enable.
  ldr r1, [r0, 0x18]
  orr r1, r1, #0x04
  str r1, [r0, 0x18]

  // We also need to configure PA2 and PA3 for use by the USART2. This is done with the
  // GPIOA_CRL (configuration register low) register. The GPIOA registers have a base
  // of 0x40010800, and the GPIOA_CRL register has an offset of 0x0. We need to set PA2
  // output mode (MODE2 set to 11) and alternate function push-pull (CNF2 set to 10),
  // AND PA3 to input mode (MODE3 set to 00) and input mode with pull-up/pull-down
  // (CNF3 set to 10). This means putting 00101011 in bits 8-15 of GPIOA_CRL.
  ldr r0, =0x40010800
  ldr r1, [r0]
  // We put a specific bit pattern into a section of a word by first clearing that section
  // setting them all to 0, and then setting any binary 1's in that section.
  // Clear bits 8-15 (0xFF00 is 1111 1111 0000 0000)
  bic r1, r1, #0xFF00 
  // And then set the 1's in bits 8-15 (0x2B00 is 0010 1011 0000 0000)
  orr r1, r1, #0x2B00
  // Store back
  str r1, [r0]

  // Now we need to configure USART2, with the baud rate, stop bits, etc.
  // The base address of the USART2 registers, from the Memory Map again,
  // is 0x4000 4400
  ldr r0, =0x40004400

  // Section 27, the USART section of the STM32F1 reference manual, describes the
  // peripheral. In section 27.3.2 Transmitter, it describes the procedure we need
  // to follow to transmit on a USART. Here it is:
  // 
  // 1. Enable the USART by writing the UE bit in USART_CR1 register to 1.
  // The offset for the USART2_CR1 register is 0x0C and the UE bit is 13
  ldr r1, [r0, #0x0C]
  orr r1, r1, #0x2000
  str r1, [r0, #0x0C]

  // 2.Program the M bit in USART_CR1 to define the word length.
  // We will be configuring 9600 baud, 8 bits, no parity, 1 stop bit
  // which is a classic speed and configuration. Eventually, we'll want
  // faster, but this is what you would have seen typically directly
  // connected to an Altair 8080 using a MITS 88-2SIO serial interface card.
  // The M bit is bit 12, and we want it set to 0 for 8 bits.
  ldr r1, [r0, #0x0C]

  // The bic (bit clear) instruction does effectively the opposite or orr.
  // It will clear the bits with 1 in the given bit mask.
  bic r1, r1, #0x1000
  str r1, [r0, #0x0C]

  // 3.Program the number of stop bits in USART_CR2.
  // The offset of USART_CR2 is 0x10, and the stop bits are in bits 12 and 13.
  // One stop bit would be setting both to 0.
  ldr r1, [r0, #0x10]
  bic r1, r1, #0x3000
  str r1, [r0, #0x10]

  // 4.Select DMA enable (DMAT) in USART_CR3 if Multi buffer Communication is to take
  // place. Configure the DMA register as explained in multibuffer communication.
  // We won't be using Multi-buffer communication, so we can ignore this one.

  // 5.Select the desired baud rate using the USART_BRR register.
  // The USART_BRR register offset 0x08. We calculate the baud rate based on the clock
  // rate. The F103 has an internal 8MHz clock, which is what is on by default, since
  // the nucleo board doesn't have an external crystal.
  // From section 27.3.4 Fractional baud rate generation of the reference manual,
  // The value in this register is calculated by:
  // Tx/Rx baud = Fck / (16 * USART_DIV)
  // The baud we want is 9600, the clock rate is 8MHz, so:
  // 9600 = 8MHz / (16 * USART_DIV)
  // Solving for USART_DIV gives us:
  // USART_DIV = 8,000,000 / (9600 * 16)
  // or 52.083333
  // This is coded as a 12 bit mantissa (52) and a 4 bit fraction (.08333, expressed as sixteenths)
  // 52 is 0x34, and .08333 * 16 is 1.3333 or 1, so the value to put into
  // USART_DIV will be 0x341. We don't need to save any other bits, so we can just stuff
  // that value into the register
  mov r1, 0x341
  str r1, [r0, #0x08]

  // 6.Set the TE bit in USART_CR1 to send an idle frame as first transmission.
  // USART_CR1 offset is 0x0C, and the TE bit is bit 3
  ldr r1, [r0, #0x0C]
  orr r1, r1, #0x8
  str r1, [r0, #0x0C]

  // This will move the link register to the pc, which is "return"
  bx lr


// Transmit a character put into R0 to USART2
uart2_tx_chr:
  // The final two instructions in section 27.3.2 Transmitter say:
  // 7.Write the data to send in the USART_DR register (this clears the TXE bit). Repeat this
  // for each data to be transmitted in case of single buffer.
  // 8.After writing the last data into the USART_DR register, wait until TC=1. This indicates
  // that the transmission of the last frame is complete. This is required for instance when
  // the USART is disabled or enters the Halt mode to avoid corrupting the last
  // transmission.
  // However, we are going to reverse this, as we only want to send when it is ready
  // So we will wait until TC=1 in the USART_SR register. This is bit 6, and the register
  // offset is 0x00.
  // Storing the address of the register in r1, since r0 has our data
  ldr r1, =0x40004400
uart2_tx_wait:
  // load the contents of USART_SR so we can see if bit 6 is 1.
  ldr r2, [r1]
  // We and r2 and r3, which will either leave 0x0 in r2 or 0x80 if TC=1.
  tst r2, #0x40
  // and'ing will set the zero flag of the status register if the result is 0, so
  // if that flag is set, then we aren't ready
  beq uart2_tx_wait
  
  // We are ready to send, which means putting the 8 bit value in r0 into the USART_DR
  // register. The offset is 0x04.
  str r0, [r1, 0x04]

  // And return
  bx lr


// This will allow us to print the zero-terminated string pointed to by the address
// in r0. This is a nice to have function to iterate over a string and print out.
uart2_print_str:
  // This is a very common pattern... iterating over a set of addresses sequentially.
  // We will store an index value in r1, incrementing it after each character has
  // be transmitted. If the character we need to transmit is a 0x0, that means we
  // are at the end of the string.
  // Because this function calls other functions (usart2_tx_chr) which expects a character
  // in r0, and the ARM procedure calling standard says r0-r3 may not be preserved,
  // but that "a subroutine must preserve the contents of the registers r4-r8, r10, r11
  // and SP". So we push the registers who we use, and then pop when we are done.
  push {r4, lr}
  // Move our string pointer to r4 so we can use r0 to as an argument to functions
  mov r4, r0
uart2_str_loop:
  // Load the byte at r4 into r0
  ldrb r0, [r4]
  // Compare the loaded byte with 0. If it is, we are done.
  cmp r0, #0x00
  beq usart2_str_done
  // If not, transmit the character
  bl uart2_tx_chr
  // Increment the index
  add r4, 0x01
  // And loop
  b uart2_str_loop

usart2_str_done:
  // Pop the registers back. Since we saved lr, and popped back to pc,
  // this is a shortcut for having to call bx lr.
  pop {r4, pc}
