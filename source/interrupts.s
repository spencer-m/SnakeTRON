/**
 * Interrupts
 * Authors: Timothy Mealey, David Sepulveda and Spencer Manzon
 */

.equ	IRQ_ENABLE1, 0x2000B210
.equ	IRQ_DISABLE1, 0x2000B21C
.equ	CLOCK_STATUS, 0x20003000
.equ	CLOCK, 0x20003004
.equ	COMPARE_CLOCK, 0x20003010
.equ	DELAY_TIME, 30000000

.global	initTable
.global disableIRQ
.global enableIRQ
.global sysIRQ_enable
.global sysIRQ_disable
.global	initTimer
.global	ISRTable			// Added line since first submission

.section	.text

// initialize time where to interrupt
initTimer:
	PUSH	{r4-r6, lr}

	LDR	r1, =CLOCK_STATUS			// acknowledge interrupt before init
	MOV	r0, #2
	STR	r0, [r1]

	LDR	r5, =CLOCK				// set current clock + delay to clock comparator
	LDR	r4, [r5]
	LDR	r5, =DELAY_TIME
	ADD	r4, r5
	LDR	r5, =COMPARE_CLOCK
	STR	r4, [r5]

	POP	{r4-r6, lr}
	BX	lr

// enable system timer interrupt
enableIRQ:
	PUSH	{r4-r5, lr}				

	LDR	r4, =IRQ_ENABLE1
	MOV	r5, #2
	STR	r5, [r4]

	POP	{r4-r5, lr}
	BX	lr

// disable system time interrupt
disableIRQ:
	PUSH	{r4-r5, lr}

	LDR	r4, =IRQ_DISABLE1
	MOV	r5, #2
	STR	r5, [r4]

	POP	{r4-r5, lr}
	BX	lr

// enable IRQ interrupts globally
sysIRQ_enable:
	PUSH	{r4, lr}

	// enable IRQ
	MRS	r4, cpsr
	BIC	r4, #0x80
	MSR	cpsr_c, r4

	POP	{r4, lr}
	BX	lr

// disable IRQ interrupts globally	
sysIRQ_disable:
	PUSH	{r4, lr}

	// disable IRQ
	MRS	r4, cpsr
	ORR	r4, #0x80
	MSR	cpsr_c, r4

	POP	{r4, lr}
	BX	lr


// IRQ Service Function for spawning value-packs over time
IRQService:
	PUSH	{r0-r12, lr}


	LDR	r1, =CLOCK_STATUS	// check if there is an interrupt
	LDR	r0, [r1]
	TST	r0, #2			// why SYS_CMP1? Its because SYS_CMP0 and SYS_CMP2 is being used by GPU
	BEQ	IRQNothing	


	// spawn a value pack
	BL	spawnValuePack
	BL	initTimer		// also acknowledges the interrupt

IRQNothing:
	POP	{r0-r12, lr}
	SUBS	pc, lr, #4		// if S and PC -> the S keeps the CPSR like nothing happened

	BX	lr


hangUH:
	B	hangUH
hangSH:
	B	hangSH
hangPH:
	B	hangPH
hangDH:
	B	hangDH
hangUUH:
	B	hangUUH
hangFIQ:
	B	hangFIQ

// Install interrupts table
initTable:
	LDR	r0, =ISRTable
	MOV	r1, #0x00000000
	LDMIA	r0!, {r2-r9}
	STMIA	r1!, {r2-r9}

	LDMIA	r0!, {r2-r9}
	STMIA	r1!, {r2-r9}

	MOV	r0, #0xD2		// disables interrupts
	MSR	cpsr_c, r0
	MOV	sp, #0x8000

	MOV	r0, #0xD3		// disable interrupts
	MSR	cpsr_c, r0
	MOV	sp, #0x8000000		// stack pointer

	BX	lr

.section	.data

ISRTable:
	LDR	pc, reset_handler
	LDR	pc, undefined_handler
	LDR	pc, swi_handler
	LDR	pc, prefectch_handler
	LDR	pc, data_handler
	LDR	pc, unused_handler
	LDR	pc, irq_handler
	LDR	pc, fiq_handler

reset_handler:		.word	initTable
undefined_handler:	.word	hangUH
swi_handler:		.word	hangSH
prefectch_handler: 	.word	hangPH
data_handler:		.word	hangDH
unused_handler:		.word	hangUUH
irq_handler:		.word	IRQService
fiq_handler:		.word	hangFIQ

