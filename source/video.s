/**
 * Graphics Operations Library
 */

 .equ	WIDTH, 1024
 .equ	HEIGHT, 768
 .equ	backgroundColor, 0x0FF0

.global initFrameBuffer
.global drawPixel
.global drawHorizonalLine
.global coordToArray
.global arrayToCoord
.global	FrameBufferInfo
.global movePixel
.global getPixel
.global clearPixel
.global drawPicture
.global stampPicture
.global	pictureTemp
.global	drawInteger


/**
 * Initialize Frame Buffer
 */
initFrameBuffer:
	PUSH	{lr}

	LDR	r0, =FrameBufferInfo
	ADD	r0, #0x40000000
	ORR	r0, #0b0001

	BL	writeMailbox

	MOV	r0, #1
	BL	readMailbox

	CMP	r0, #0
	MOVNE	r0, #0
	BNE	initFrameBuffer

	LDR	r0, =FrameBufferInfo
	ADD	r0, #32
	
initFrameBufferPointerLoop:
	LDR	r1, [r0]
	CMP	r1, #0
	BEQ	initFrameBufferPointerLoop

	LDR	r2, =frameBufferPointer
	STR	r1, [r2]

	MOV	r0, #1
	
initFrameBufferRet:
	POP	{lr}
	BX	lr


/**
 * Coordinate to Array Address
 * Parameters:
 *	r0:	x
 *	r1:	y
 */
coordToArray:
	MOV	r2, #WIDTH
	MUL	r1, r1, r2
	ADD	r0, r1

	LSL	r0, #1

	BX	lr


/**
 * Draw a pixel
 * Parameters:
 *	r0:	x
 *	r1:	y
 *	r2:	Pixel Color
 */
drawPixel:
	PUSH	{r4, lr}
	MOV	r4, r2

	CMP	r0, #WIDTH
	MOVGE	r0, #0
	BGE	drawPixelRet

	CMP	r1, #HEIGHT
	MOVGE	r0, #0
	BGE	drawPixelRet

	BL	coordToArray

	LDR	r1, =frameBufferPointer
	LDR	r3, [r1]
	STRH	r4, [r3, r0]
	MOV	r0, #1
	
drawPixelRet:
	POP	{r4, lr}
	BX	lr


/**
 * Draw a horizonal line
 * Parameters:
 *	r0:	Start of line (x coordinate)
 *	r1:	Start of line (y coordinate)
 *	r2:	Line Width
 *	r3:	Pixel Color
 */
drawHorizonalLine:
	PUSH	{r4-r7, lr}
	MOV	r4, r0
	MOV	r5, r1
	MOV	r6, r2
	MOV	r7, r3

	ADD	r6, r0
fruitLoops:
	MOV	r0, r4
	MOV	r1, r5
	MOV	r2, r7
	BL	drawPixel

	ADD	r4, #1

	CMP	r4, r6
	BLE	fruitLoops

	POP	{r4-r7, lr}
	BX	lr






	// r0: x
	// r1: y
	// r2: dx
	// r3: dy
movePixel:
	PUSH	{r4-r5,lr}

	// gets color of pixel being moved
	PUSH	{r0-r3}
	BL	getPixel
	MOV	r4, r0
	POP	{r0-r3}

	// clears the current pixel
	PUSH	{r0-r3}
	BL	clearPixel
	POP	{r0-r3}

	MOV	r0, r2
	MOV	r1, r3
	MOV	r2, r4

	PUSH	{r0-r3}
	BL	drawPixel
	POP	{r0-r3}

	POP	{r4-r5, lr}
	BX	lr



	// r0: x
	// r1: y
clearPixel:
	PUSH	{lr}
	LDR	r2, =backgroundColor
	BL	drawPixel
	POP	{lr}
	BX	lr



	// r0: x
	// r1: y
	// returns pixel data
getPixel:
	PUSH	{lr}

	// range checks the index
	CMP	r0, #WIDTH
	MOVGE	r0, #0
	BGE	getPixelRet

	CMP	r1, #HEIGHT
	MOVGE	r0, #0
	BGE	getPixelRet

	BL	coordToArray

	LDR	r1, =frameBufferPointer
	LDR	r3, [r1]

	LDRH	r2, [r3, r0]
	MOV	r0, r2

getPixelRet:
	POP	{lr}
	BX	lr



	// r0: x
	// r1: y
	// r2: width
	// r3: height
	// r4: dx
	// r5: dy
moveRectangle:
	

	// r0 - address of memory struct
	// x1: start coord x (upper left) [r4]
	// y1: start coord y (upper right)
	// w: image width
	// h: image height
	// addr: address of ascii structure [r8]
drawPicture:
	/*POP	{r1}
	STR	r1, [r0]
	POP	{r1}
	STR	r1, [r0, #4]
	POP	{r1}
	STR	r1, [r0, #8]
	POP	{r1}
	STR	r1, [r0, #12]
	POP	{r1}
	STR	r1, [r0, #16]*/



	PUSH	{r4-r10, lr}
	
	LDR	r4, [r0]
	LDR	r5, [r0, #4]
	LDR	r6, [r0, #8]
	LDR	r7, [r0, #12]
	LDR	r8, [r0, #16]

	MOV	r9, r4
	ADD	r6, r4
	ADD	r7, r5

drawPicLoop:
	MOV	r0, r4
	MOV	r1, r5
	LDRH	r2, [r8], #2
	BL	drawPixel

	ADD	r4, #1
	CMP	r4, r6
	BLT	drawPicLoop

	ADD	r5, #1
	MOV	r4, r9
	CMP	r5, r7
	BLT	drawPicLoop

	POP	{r4-r10, lr}
	BX	lr


	// PASSED THROUGH STACK
	// x1: start coord x (upper left) [r4]
	// y1: start coord y (upper right)
	// w: image width hell cockulator
	// h: image height
	// addr: address of ascii structure [r8]
stampPicture:
	LDR	r0, =pictureTemp
	POP	{r1}
	STR	r1, [r0]
	POP	{r1}
	STR	r1, [r0, #4]
	POP	{r1}
	STR	r1, [r0, #8]
	POP	{r1}
	STR	r1, [r0, #12]
	POP	{r1}
	STR	r1, [r0, #16]

	PUSH	{r4-r10, lr}
	
	LDR	r4, [r0]
	LDR	r5, [r0, #4]
	LDR	r6, [r0, #8]
	LDR	r7, [r0, #12]
	LDR	r8, [r0, #16]

	MOV	r9, r4
	ADD	r6, r4
	ADD	r7, r5

drawStampLoop:
	MOV	r0, r4
	MOV	r1, r5
	LDRH	r2, [r8], #2
	BL	drawPixel

	ADD	r4, #1
	CMP	r4, r6
	BLT	drawStampLoop

	ADD	r5, #1
	MOV	r4, r9
	CMP	r5, r7
	BLT	drawStampLoop
/*
	//clear picture init
	LDR	r0, =pictureTemp
	LDR	r4, [r0]
	LDR	r5, [r0, #4]
	LDR	r6, [r0, #8]
	LDR	r7, [r0, #12]
	LDR	r8, [r0, #16]

	MOV	r9, r4
	ADD	r6, r4
	ADD	r7, r5

clearStampLoop:
	MOV	r0, r4
	MOV	r1, r5
	LDRH	r2, =backgroundColor
	BL	drawPixel

	ADD	r4, #1
	CMP	r4, r6
	BLT	clearStampLoop

	ADD	r5, #1
	MOV	r4, r9
	CMP	r5, r7
	BLT	clearStampLoop
*/
	POP	{r4-r10, lr}
	BX	lr









	// r0: x
	// r1: y
	// r2: integer
drawInteger:
	PUSH	{r4-r10, lr}

	MOV	r4, r0
	MOV	r5, r1

	LDR	r0, =integerStringBuffer
	MOV	r1, r2
	BL	itoa

	MOV	r9, r0
	MOV	r7, r1

drawIntegerLoop:
	LDRB	r2, [r9], #1
	SUB	r2, #48
	LSL	r2, #2

	LDR	r3, =digitArray
	LDR	r8, [r3, r2]

	LDR	r6, =pictureTemp
	STR	r8, [r6, #16]

	STR	r4, [r6, #0]
	ADD	r4, #32
	STR	r5, [r6, #4]
	MOV	r2, #32
	STR	r2, [r6, #8]
	STR	r2, [r6, #12]
	MOV	r0, r6
	BL	drawPicture

	SUBS	r7, #1
	BGT	drawIntegerLoop

	POP	{r4-r10, lr}
	BX	lr


.align	4
FrameBufferInfo:
	.int	WIDTH		//0 - Width
	.int	HEIGHT		//4 - Height
	.int	WIDTH		//8 - vWidth
	.int	HEIGHT*2	//12 - vHeight
	.int	0		//16 - GPU - Pitch
	.int	1		//20 - Bit Depth
	.int	0		//24 - vX
	.int	0		//28 - vY
	.int	0		//32 - FB Pointer
	.int	0		//36 - FB Size

frameBufferPointer:
	.int	0

.section	.data

integerStringBuffer:
	.rept	32
	.byte	0
	.endr

.align	2
font:
	.incbin	"font.bin"

pictureTemp:
	.word	0,0,0,0,0

.align	2
digitArray:
	.word	text_0, text_1, text_2, text_3, text_4, text_5, text_6, text_7, text_8, text_9
