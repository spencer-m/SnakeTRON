/**
 * Mailboxes interface
 * Authors: Timothy Mealey, David Sepulveda and Spencer Manzon
 */

.equ	BASE_ADDR, 0x2000B880
.equ	PEEK, 0x10
.equ	READ, 0x00
.equ	WRITE, 0x20
.equ	STATUS, 0x18
.equ	SENDER, 0x14
.equ	CONFIG, 0x1C

.global	readMailbox
.global writeMailbox

// r0: channel number
// returns data from mailbox
readMailbox:
	LDR	r2, =BASE_ADDR
	
readWaitLoop:
	LDR	r1, [r2, #STATUS]
	TST	r1, #0x40000000
	BNE	readWaitLoop

	LDR	r3, [r2, #READ]

	AND	r1, r3, #0xF
	CMP	r1, r0
	BNE	readMailbox
	LSR	r0, r3, #4
	
	BX	lr

// r0: data
writeMailbox:
	LDR	r1, =BASE_ADDR
	
writeWaitLoop:
	LDR	r2, [r1, #STATUS]
	TST	r2, #0x80000000
	BNE	writeWaitLoop

	STR	r0, [r1, #WRITE]

	BX	lr
