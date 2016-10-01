/**
 * SNES Driver Library
 * requires the GPIO library
 * Authors: Timothy Mealey, David Sepulveda and Spencer Manzon
 */

// Input and output function codes for GPIO pins
.equ	IN_PIN, 0
.equ	OUT_PIN, 1

// GPIO pin numbers for latch, data, clock
.equ	LAT_PIN, 9
.equ	DAT_PIN, 10
.equ	CLK_PIN, 11

.global	InitSNES
.global readSNES

InitSNES:
	PUSH	{lr}			// preserve lr register

	MOV	r0, #DAT_PIN		// initialize data pin to input
	MOV	r1, #IN_PIN
	BL	initGPIO

	MOV	r0, #LAT_PIN		// initialize latch pin to output
	MOV	r1, #OUT_PIN
	BL	initGPIO

	MOV	r0, #CLK_PIN		// initialize clock pin to output
	MOV	r1, #OUT_PIN
	BL	initGPIO

	POP	{lr}			// restore lr register
	BX	lr			// branch back to calling code

/**
 * Main SNES subroutine that reads input from a SNES Controller
 * Returns the code of a pressed button in a register
 * @return:	r0 - SNES button register
 */
readSNES:
	PUSH	{r4-r6,lr}	// preserve registers

	MOV	r0, #1		// Turn on clock
	BL	writeClock

	MOV	r0, #1		// Turn on latch
	BL	writeLatch

	MOV	r0, #12		// Wait 12 micro seconds
	BL	wait
	
	MOV	r0, #0		// Turn off latch
	BL	writeLatch

	MOV	r5, #0		// Clear output register (moved to r0 at the end)
	MOV	r4, #0		// Declare loop counter

readSNESLoop:
	MOV	r0, #6		// Wait 6 micro seconds
	BL	wait

	MOV	r0, #0		// Turn off clock
	BL	writeClock

	MOV	r0, #6		// Wait 6 micro seconds
	BL	wait

	BL	readData	// Read data bit from SNES

	LSL	r0, r4		// Shift data bit to correct position
	ORR	r5, r0		// Store read data bit in r5 (output)

	MOV	r0, #1		// Turn on clock
	BL	writeClock

	ADD	r4, #1		// Increment loop counter
	CMP	r4, #12		// Loop guard (12 output bits that matter)
	BLT	readSNESLoop

	MOV	r0, r5		// Return the output

	POP	{r4-r6,lr}	// restore registers
	BX	lr		// branch back to calling code

/**
 * Write a bit to the GPIO latch line
 * @param:	r0 - (int) bit to be written
 */
writeLatch:
	MOV	r1, r0		// move pin to be written to r1
	MOV	r0, #LAT_PIN	// move pin number to r0
	PUSH	{lr}		// preserve lr register
	BL	writeGPIO	// write values
	POP	{lr}		// restore lr register

	BX	lr		// branch back to calling code

/**
 * Write a bit to the GPIO clock line
 * @param:	r0 - (int) bit to be written
 */
writeClock:
	MOV	r1, r0		// move pin to be written to r1
	MOV	r0, #CLK_PIN	// move pin number to r0
	PUSH	{lr}		// preserve lr register
	BL	writeGPIO	// write values
	POP	{lr}		// restore lr register

	BX	lr		// branch back to calling code

/** 
 * Reads a bit from the GPIO data line
 * @return:	r0 - (int) bit that has been read
 */
readData:
	MOV	r0, #DAT_PIN	// move pin number to be read
	PUSH	{lr}		// preserve lr register
	BL	readGPIO	// read pin - result goes to r0
	POP	{lr}		// restore lr register

	BX	lr		// branch back to calling code

