/* Define the end of RAM and limit of stack memory */
/* (20KB SRAM on the STM32F103RB line, 20480 = 0x5000) */
/* (RAM starts at address 0x20000000) */
_estack = 0x20005000;

MEMORY
{
    FLASH ( rx )      : ORIGIN = 0x08000000, LENGTH = 128K
    SRAM ( rxw )      : ORIGIN = 0x20000000, LENGTH = 20K
}

SECTIONS {
	.text : {
		*(.text)
	} >FLASH

	.data (NOLOAD) : {
		*(.data)
	} >SRAM
}
