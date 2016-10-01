/**
 * Utilities
 * Authors: Timothy Mealey, David Sepulveda and Spencer Manzon
 */

.equ	CLOCK, 0x20003004	// clock register address

.global atoi
.global itoa
//.global	eudiv // not working
.global rand
.global	rand32
.global randSeed
.global	udiv
.global wait

/**
 * Unsigned Integer Division
 * Divides r0 by r1 and the quotient and remainder is returned
 * @param:	r0 - (int) dividend
 * @param:	r1 - (int) divisor
 * @return:	r0 - quotient
 * @return:	r1 - remainder
 * v1.0
 */
udiv:
	// r0 = dividend
	// r1 = divisor
	// if divisor is 0, return -1, 0

	cmp	r1, #0
	moveq	r0, #-1
	moveq	r1, #0
	beq	udivRet

	// start loop
	mov     r2, #0
	b       udivTest
udivLoop:
	// subtract divisor and add to quotient
	sub     r0, r1
	add     r2, #1

udivTest:
	cmp     r0, r1
	bge     udivLoop
	// return quotient and remainder
	mov     r1, r0
	mov     r0, r2

udivRet:
	// r0 = quotient, -1 if error
	// r1 = remainder, 0 if error
	mov     pc, lr



/** 
 * Efficient Unsigned Integer Division 
 * Divides r0 by r1 and the quotient and remainder is returned 
 * @param: r0 - (int) dividend 
 * @param: r1 - (int) divisor 
 * @return: r0 - quotient 
 * @return: r1 - remainder 
 * v.0.8 ALPHA
 */ 
eudiv: // r0 = dividend // r1 = divisor // if divisor is 0, return -1, 0 PUSH {r4, r5, r6, r7, r8, lr} MOV r4, r1 MOV r5, #0 MOV r8, #10

	PUSH	{r4-r8, lr}	

	CMP	r1, #0 
	MOVEQ	r0, #-1 
	MOVEQ	r1, #0 
	BEQ	retHere

	MOV	r2, #0 // counter

	PUSH	{r0} 		// push number onto stack
	ADD	r2, #1 		// increment counter
	MOV	r3, r0		// move number into r3

pushLoop: 
	MOV	r0, r3
	MOV	r1, #10	 
	PUSH	{r2}
	BL	udiv		// divide number by 10
	POP	{r2}

	CMP	r1, #0		// compare remainder to 0, if 0 this is hte last didit
	BEQ	popLoop

	MOV	r3, r0		// update r3
	PUSH 	{r3}
	ADD 	r2, #1		// increment counter
	B 	pushLoop

popLoop: 
	CMP	r2, #0		// if all values popped, done 
	BEQ	endPop

	MUL	r5, r5, r8	// update significant digits of the overall quotient
	MUL	r1, r1, r8	// update significant digits of the previous remainder 
	SUB	r2, #1 		// decrement counter 
	POP	{r3} 		// pop current x 
	MOV	r7, r3 		// save current x 
	SUB	r3, r6 		// current x = current x - previous x 
	ADD	r0, r1, r3 	// current x = current x + remainder of previous x - previous x 
	MOV	r1, r4 		// divide current x by divisor

	PUSH	{r2}
	BL	udiv
	POP	{r2}
	ADD	r5, r0		// add quotient of current x and divisor to overall quotient
	MUL	r6, r7, r8	// multiply current x by 10 and save it in the previous x register
	B	popLoop

endPop: 
	MOV	r0, r5
retHere:
	POP	{r4-r8, lr}
	BX	lr


/** 
 * Waits for a time interval, passed as a parameter
 * @param:	r0 - (int) time interval in microseconds
 */
wait:
	LDR	r3, =CLOCK	// load address of clock
	LDR	r2, [r3]	// load value of clock
	ADD	r1, r0, r2	// add desired time

waitLoop:
	LDR	r2, [r3]	// reload value of clock
	CMP	r1, r2		// compare against desired value of clock
	BGT	waitLoop	// if desired value is greater than clock, loop back

	BX	lr		// branch back to calling code


/**
 * atoi Function
 * A funtion that converts ASCII characters to its corresponding integer value.
 * Parameters:
 *	r0 - starting address of the ascii character sequence
 *	r1 - length of the ascii character sequence
 * Return values:
 * 	r0 - the integer value of the ascii character sequence
 *	r1 - error flag - it is set when the ascii character sequence is invalid
 * v1.0
 */
atoi:
	// r0 will be address of buffer
	// r1 will be how many characters read
	// r2 will be temp variable
	// r3 will be temp variable
	// r4 will be the multiplier
	// r5 will be the value 10
	// r9 will be the accumulator
	// r10 will be the flag

	PUSH	{r4-r10}		// register preservation

	MOV	r10, #0			// initialize flag

	LDRB	r2, [r0]		// load value at start address
	CMP	r2, #45			// check if '-'
	BNE	atoi_prep		// proceed if not '-'
	MOV	r10, #1			// set negative flag
	SUB	r1, #1			// decrease length
	ADD	r0, #1			// adjust address

atoi_prep:				// prepare values for operation
	SUB	r1, #1			// subtract 1 to length (making it an index)
	ADD	r0, r1			// offset buffer using index value
	MOV	r4, #1			// set multiplier
	MOV	r5, #10			// constant value for multiplication
	MOV	r9, #0			// reset the accumlator

atoi_main:				// conversion proper
	CMP	r1, #0			// check r1 to 0
	BLT	atoi_error		// branch if r1 is less than 0

	LDRB	r2, [r0]		// load value in address r0 (which is the buffer address) to r2

	CMP	r2, #48			// range check ascii character
	BLT	atoi_error		// branch to error if out of range (if < '0')
	CMP	r2, #57			// range check ascii character
	BGT	atoi_error		// branch to error if out of range (if > '9')

	SUB	r2, #48			// convert ascii to integer value
	MUL	r3, r2, r4		// put number into place (by multiplying by 10^x)
	ADD	r9, r3			// add to accumulator
	MUL	r4, r5			// placeholder multiplied by 10
	SUB	r1, #1			// decrease length
	CMP	r1, #-1			// check if all the characters have been processed 
	BEQ	atoi_ok			// branch to finish if all the characters have been processed
	LDRB	r2, [r0, #-1]!		// load previous byte (the number to the left)
	B	atoi_main		// repeat process

atoi_error:				
	MOV	r0, #0			// atoi in C standard
	MOV	r1, #1			// error flag
	B	atoi_end		// branch to end

atoi_ok:				
	MOV	r0, #-1			// -1 placeholder
	CMP	r10, #1			// check negative flag
	MULEQ	r9, r0			// multiply value(r9) by -1 when negative
	MOV	r0, r9			// put value to r0
	MOV	r1, #0			// error flag
		
atoi_end:				
	POP	 {r4-r10}		// register restoration
	BX	lr			// Returns back to calling code
	
/**
 * itoa Function
 * A function that converts an integer to an ascii character sequence
 * It is assumed that an integer is passed
 * Parameters:
 *	r0 - starting address of the buffer to be used
 *	r1 - the integer to be converted
 * Return values:
 *	r0 - address of the buffer used
 *	r1 - length of the ascii character sequence
 * v1.0
 */
itoa:
	PUSH	{r4-r10}		// Perserves registers
	MOV	r4, r0			// Moves starting address at r0 to r4
	MOV	r6, r0			// Moves starting address at r0 to r6
	MOV	r5, r1			// Moves integer to be converted at r1 to r5

	// r4 is the address of the buffer
	// r5 is the integer to be converted
	// r6 is the address of the buffer (untouched)
	// r7 is the counter
	// r8 is the place value holder
	// r9 is a constant (for multiplication)
	// r10 is the length of the integer

	MOV	r7, #0			// Initializes counter
	MOV	r8, #1			// Initializes place value holder
	MOV	r9, #10			// Initializes constant (for multiplication)
	MOV	r10, #1			// Initializes length of integer

itoa_prep:				// SETS UP THE PLACE VALUE HOLDER VALUE (i.e.  PVH=100 when integer is 123 or 234)
	MOV	r0, r5			// Moves integer to be converted to r0
	MOV	r1, r8			// Moves place value holder to r1
	PUSH	{lr}			// Perserves lr
	BL	udiv			// Divides integer by place value holder
	POP	{lr}			// Pops perserved lr

	CMP	r0, #10			// Compares result of division to 10
	BLT	itoa_main		// Continues to itoa_main (conversion stage) if result < 10
	MUL	r8, r9			// Multiplies place value holder by 10
	ADD	r10, #1			// Adds 1 to length of integer
	B	itoa_prep		// Loops back to itoa_prep

itoa_main:
	CMP	r7, r10			// Compares counter to length of integer
	BGE	itoa_end		// Continus to itoa_end (end stage) if r7 >= r10

					// gets the leftmost integer value
	MOV	r0, r5			// Moves integer to be converted to r0
	MOV	r1, r8			// Moves place value holder to r1
	PUSH	{lr}			// Perserves lr
	BL	udiv			// Divides integer by place value holder
	POP	{lr}			// Pops perserved lr
	
	ADD	r0, #48			// Converts integer to ASCII
	MOV	r5, r1			// moves remainder to be the new integer to be converted
	STRB	r0, [r4]		// Stores converted integer in the buffer
	ADD	r4, #1			// Increments buffer

					// adjust place value holder to the next integer to be extracted
	MOV	r0, r8			// Moves place value holder to r0
	MOV	r1, r9			// Moves constant ro r1
	PUSH	{lr}			// Perserves lr
	BL	udiv			// Divides place value holder by 10
	POP	{lr}			// Pops perserved lr
	MOV	r8, r0			// Moves returned result to r8

	ADD	r7, #1			// Increments counter

	B	itoa_main		// Loops back to itoa_main

itoa_end:
	MOV	r0, r6		// address of the buffer
	MOV	r1, r10		// length of the integer
	POP	{r4-r10}	// Pop perserved registers
	BX	lr		// Returns back to calling code



randSeed:
	LDR	r1, =CLOCK
	LDR	r0, [r1]

	LDR	r1, =randVariables

	AND	r2, r0, #0x3F
	STR	r2, [r1]
	LSR	r0, #8
	
	AND	r2, r0, #0x3F
	STR	r2, [r1, #4]
	LSR	r0, #8

	AND	r2, r0, #0x3F
	STR	r2, [r1, #8]
	LSR	r0, #8

	AND	r2, r0, #0x3F
	STR	r2, [r1, #12]

	BX	lr

/* Random Number Generator
 * r0 - bitmask
 * These state variables must be initialized so that they are not all zero. 
 * x 
 * y 
 * z 
 * w 
 * @return w in r0, (int) random number 
 */ 
rand: 
	
	PUSH	{r4, r5, lr} // maybe delete
	MOV	r5, r0

	LDR	r0, randVariables 
	LDR	r4, [r0] // t = x

	EOR	r4, r4, LSL #11	// t ^= t << 11 
	EOR	r4, r4, ASR #8	// t ^= t >> 8

	// maybe optimize 
	LDR	r1, [r0, #4] // r1 = y 
	LDR	r2, [r0, #8] // r2 = z 
	LDR	r3, [r0, #12] // r3 = w 
	
	STR	r1, [r0] // x = y 
	STR	r2, [r0, #4] // y = z 
	STR	r3, [r0, #8] // z = w

	EOR	r3, r3, ASR #19 // w ^= w >> 19 
	EOR	r3, r3, r4 // w ^= t

	STR	r3, [r0, #12] // update w 
	MOV	r0, r3 // return = w

	AND	r0, r5	
	
	POP	{r4, r5, lr} // maybe delete

	BX	lr

// Rand function, modified to our specific needs
rand32:
	PUSH	{lr}

	MOV	r0, #0x1F
	BL	rand

	POP	{lr}
	BX	lr


.align 4	// These state variables must be initialized so that they are not all zero. 
		// Using hard coded ones as place holders to avoid problems. 
randVariables: 
	.word 1, 1, 1, 1
	//.int 1 // 0  - X 
	//.int 1 // 4  - Y 
	//.int 1 // 8  - Z 
	//.int 1 // 12 - W

