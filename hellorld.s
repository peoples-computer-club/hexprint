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

// Directives
.syntax unified
.cpu cortex-m3
.thumb

// Code section
.text

// Vector interrupt table, all we care about is reset right now
vtable:
    .word _estack		            // 0 Top of Stack
    .word reset_handler	        // 1 Reset interrupt
    .fill 74, 4                 // We don't care about the rest right now

string:
    .asciz "Hellorld!\r\n"

.align 4

_start:
reset_handler:
    // Initialize the USART connected to the ST-Link device
    bl uart2_init
loop:
    // uart2_print_str takes the address of the string to print
    ldr r0, =string
    bl uart2_print_str
    // Now we keep calling our print string function over and over
    b loop


uart2_init:
  // First we need to enable the USART2 peripheral
  ldr r0, =0x40021000           // RCC register base
  ldr r1, [r0, 0x1C]            // RCC_APB1ENR
  orr r1, r1, #0x20000          // USART2 enable bit
  str r1, [r0, 0x1C]

  // Next, enable GPIO port A
  ldr r1, [r0, 0x18]            // RCC_APB2ENR
  orr r1, r1, #0x04             // GPIO port A enable bit
  str r1, [r0, 0x18]

  // Configure PA2 (TX) and PA3 (RX) pins
  ldr r0, =0x40010800           // GPIOA_CRL register
  ldr r1, [r0]
  bic r1, r1, #0xFF00
  orr r1, r1, #0x2B00           // PA2 alt func push-pull output, PA3 input pull-up/pull-down
  str r1, [r0]

  // Configure USART2
  ldr r0, =0x40004400           // USART2 register base

  // Enable USART2
  ldr r1, [r0, #0x0C]           // USART2_CR1 register
  orr r1, r1, #0x2000           // USART2 enable is bit 13
  str r1, [r0, #0x0C]

  // Set word length of 8 bits
  ldr r1, [r0, #0x0C]           // USART_CR1 register, again
  bic r1, r1, #0x1000
  str r1, [r0, #0x0C]

  // Set the stop bits to 1 (parity of None is default)
  ldr r1, [r0, #0x10]           // USART_CR2 register
  bic r1, r1, #0x3000
  str r1, [r0, #0x10]

  // Set the baud rate to 9600, assuming an 8MHz default clock
  mov r1, 0x341
  str r1, [r0, #0x08]           // USART_BRR register

  // Set the Transmit Enable bit
  ldr r1, [r0, #0x0C]           // USART_CR1, again
  orr r1, r1, #0x8
  str r1, [r0, #0x0C]
  bx lr


// Transmit a character put into R0 to USART2
uart2_tx_chr:
  ldr r1, =0x40004400           // USART2 register base
uart2_tx_wait:
  // Wait for transmit clear to be set, letting us know it's ok to send
  ldr r2, [r1]
  tst r2, #0x40
  beq uart2_tx_wait
  
  // We are ready to send, output the character in r0
  str r0, [r1, 0x04]            // USART2_DR register
  bx lr


// Address of null-terminated string in r0
uart2_print_str:
  push {r4, lr}
  // Move our string pointer to r4 so we can use r0 to as an argument to functions
  mov r4, r0
uart2_str_loop:
  ldrb r0, [r4]
  cmp r0, #0x00
  beq usart2_str_done
  // If not, transmit the character
  bl uart2_tx_chr
  add r4, 0x01
  b uart2_str_loop

usart2_str_done:
  pop {r4, pc}
