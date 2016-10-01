/**
 * GPIO Operations Library
 * Compatible with Raspbery Pi 1 B+ and Raspberry Pi 2
 * Authors: Timothy Mealey, David Sepulveda and Spencer Manzon
 */

.equ	BASE_ADDR, 0x20200000	// Base address for GPIO registers

// GPIO register offsets
.equ	GPSET0, 28	
.equ	GPSET1, 32	// confirm offset for RPi 2
.equ	GPCLR0, 40
.equ	GPCLR1, 44	// confirm offset for RPi 2
.equ	GPLEV0, 52
.equ	GPLEV1, 56	// confirm offset for RPi 2

.global	initGPIO
.global	readGPIO
.global	writeGPIO

/**
 * Initializes a GPIO line
 * The line number and function code must be passed as parameters
 * @param:	r0 - (int) pin number
 * @param:	r1 - (int) function code
 */
initGPIO:
	PUSH	{r4, r5}		// preserve registers

	MOV	r4, r1			// preserve function code parameter
	MOV	r1, #10			// for division by 10
	PUSH	{lr}			// preserve lr register
	BL	udiv			// call udiv
	POP	{lr}			// restore lr register

	LSL	r0, #2			// multiply by 4 to obtain pin offset from base address
	LDR	r2, =BASE_ADDR		// load address of BASE_ADDR
	ADD	r0, r0, r2		// add offset to BASE_ADDR

	LDR	r5, [r0]		// get contents of BASE_ADDR + offset
	ADD	r1, r1, r1, LSL #1	// multiply r1 by 3 (gets the pin number in the current GPFSELn)
	MOV	r3, #7			// bit mask to be used to clear 3 bits
	LSL	r3, r1			// align bitmask to pin of interest
	LSL	r4, r1			// align function to pin of interest
	BIC	r5, r3			// clear function of pin of interest
	ORR	r5, r4			// set function of pin of interest
	STR	r5, [r0]		// store back to take effect

	POP	{r4, r5}		// restore registers
	BX	lr			// branch back to calling code


/**
 * Read a bit from a GPIO pin
 * @param:	r0 - (int) pin number
 * @return:	r0 - (int) value of pin given the pin number
 */
readGPIO:
	MOV	r1, #32			// dividing r0 (pin number) by 32
	PUSH	{lr}			// preserve lr register
	BL	udiv			// divide pin number by 32
	POP	{lr}			// restore lr

	LDR	r3, =BASE_ADDR		// store base address
	CMP	r0, #0			// check which GPLEV{n} to use
	ADDEQ	r3, #GPLEV0		// use GPLEV0 by adding the offset for it
	ADDNE	r3, #GPLEV1		// use GPLEV1 by adding the offset for it
	LDR	r0, [r3]		// load value of corresponding GPLEV{n}

	MOV	r2, #1			// move 1 to r2
	LSL	r2, r1			// shift r0 by offset
	AND	r1, r2, r0		// extract bit of interest
	CMP	r1, #0			// check bit of interest

	MOVEQ	r0, #0			// return 0 if bit of interest is 0
	MOVNE	r0, #1			// return 1 if bit of interest is 1

	BX	lr			// branch to calling code


/**
 * Write a bit to a GPIO pin
 * @param:	r0 - (int) pin number
 * @param:	r1 - (int) what bit to write
 */
writeGPIO:
	PUSH	{r4}			// preserve registers

	MOV	r4, r1			// save what bit to write to safe register
	MOV	r1, #32			// dividing r0 (pin number) by 32
	PUSH	{lr}			// preserve lr register
	BL	udiv			// divide pin number by 32
	POP	{lr}			// restore lr

	MOV	r2, #1			// move 1 to r2
	LSL	r2, r1			// align to the pin number (for the corresponding GPSET/CLR{n} register)
	STR	r2, [r3]		// set or clr the pin number (based on what address was stored)

	MOV	r2, #1			// move 1 to r2
	LSL	r2, r1			// align to the pin number (for the corresponding GPSET/CLR{n} register)
	STR	r2, [r3]		// set or clr the pin number (based on what address was stored)

	LDR	r3, =BASE_ADDR		// store base address
	CMP	r4, #0			// check the bit to write		
	BEQ	writeCLR		// branch to clear the bit, else fall to set the bit

writeSET:
	CMP	r0, #0			// check what GPSET{n} to use
	ADDEQ	r3, #GPSET0		// use GPSET0 by adding the offset for it	
	ADDNE	r3, #GPSET1		// use GPSET1 by adding the offset for it

	B	writeGPIO_end		// branch to end to do operation

writeCLR:
	CMP	r0, #0			// check what GPCLR{n} to use
	ADDEQ	r3, #GPCLR0		// use GPCLR0 by adding the offset for it
	ADDNE	r3, #GPCLR1		// use GPCLR1 by adding the offset for it

writeGPIO_end:
	MOV	r2, #1			// move 1 to r2
	LSL	r2, r1			// align to the pin number (for the corresponding GPSET/CLR{n} register)
	STR	r2, [r3]		// set or clr the pin number (based on what address was stored)

	POP	{r4}			// restore regsiters
	BX	lr			// branch back to calling code

