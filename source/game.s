/* Game Code */

.equ	APPLE_REQ, 20

//empty, wall, border, exit, reserved, reserved, reserved, reserved, reserved, text_background, menu_pointer, life_icon, reserved, reserved, reserved, reserved, apple, value 1, value 2, value 3, value 4, reserved, reserved, reserved, reserved, reserved, snake_up, down, left, right, trail_vert, horiz, left_down, right_up, up_right, down_right, reserved, reserved, reserved, reserved, reserved, reserved, reserved, reserved, reserved, reserved, reserved, reserved

.equ	EMPTY, 0
.equ	WALL, 1
.equ	BORDER, 2
.equ	EXIT, 3

.equ	ORANGE_SELECTION, 4
.equ	GREEN_SELECTION, 5
.equ	PINK_SELECTION, 6

.equ	TEXT_BACKGROUND, 9
.equ	MENU_POINTER, 10
.equ	LIFE_ICON, 11

.equ	APPLE, 16
.equ	VALUE_PACK1, 17
.equ	VALUE_PACK2, 18
.equ	VALUE_PACK3, 19
.equ	VALUE_PACK4, 20

.equ	FIRST_SNAKE_ITEM, 26

.equ	SNAKE_UP, 26
.equ	SNAKE_DOWN, 27
.equ	SNAKE_LEFT, 28
.equ	SNAKE_RIGHT, 29

.equ	TRAIL_UP, 30
.equ	TRAIL_DOWN, 31
.equ	TRAIL_LEFT, 32
.equ	TRAIL_RIGHT, 33
.equ	TRAIL_RIGHT_DOWN, 34
.equ	TRAIL_UP_LEFT, 35
.equ	TRAIL_RIGHT_UP, 36
.equ	TRAIL_DOWN_LEFT, 37
.equ	TRAIL_UP_RIGHT, 38
.equ	TRAIL_LEFT_DOWN, 39
.equ	TRAIL_DOWN_RIGHT, 40
.equ	TRAIL_LEFT_UP, 41

.equ	FIRST_TRAIL_END, 42
.equ	LAST_TRAIL_END, 54

.equ	LAST_SNAKE_ITEM, 54

.global fillScreenWithItem
.global	initGame
.global	startGame
.global moveSnake
.global resetSnake
.global	score
.global	lives
.global updateLives
.global redrawArea
.global drawMap		// for testing
.global drawItem
.global spawnValuePack
.global changeBikeColor
.global drawBikeColor
.global	changeMap
.global drawMapLabel

.section	.text

/* init game
 */
initGame:
	PUSH	{r4-r10, lr}
	MOV	r4, #0
	
startLoop:

	LDR	r0, =score
	MOV	r1, #0
	STR	r1, [r0]

	LDR	r0, =lives
	MOV	r1, #0
	STR	r1, [r0]

	LDR	r0, =apples
	MOV	r1, #0
	STR	r1, [r0]
	
// initialize and draw the map
drawTheMap:

	LDR	r3, =mapStructure
	MOV	r4, #0
	MOV	r5, #0
initMapLoop:
	MOV	r2, #EMPTY

	CMP	r5, #1
	MOVEQ	r2, #TEXT_BACKGROUND

	CMP	r5, #2
	MOVEQ	r2, #TEXT_BACKGROUND

	CMP	r4, #0
	MOVEQ	r2, #BORDER

	CMP	r4, #31
	MOVEQ	r2, #BORDER

	CMP	r5, #0
	MOVEQ	r2, #BORDER

	CMP	r5, #3
	MOVEQ	r2, #BORDER

	CMP	r5, #23
	MOVEQ	r2, #BORDER

	STRB	r2, [r3], #1
	
	ADD	r4, #1
	CMP	r4, #32
	BLT	initMapLoop

	MOV	r4, #0
	ADD	r5, #1
	CMP	r5, #24
	BLT	initMapLoop

	// get the current map offset
	LDR	r1, =map
	LDR	r0, [r1]

	// get all of the map subroutines
	LDR	r1, =maps
	LSL	r0, #3
	ADD	r1, r0

	// branch to the current map subroutine
	LDR	r0, [r1]
	MOV	lr, pc
	MOV	pc, r0

	// actually draw the map
	BL	drawMap


	// draw "SCORE:"
	LDR	r0, =pictureTemp
	MOV	r1, #96
	STR	r1, [r0, #0]
	MOV	r1, #48
	STR	r1, [r0, #4]
	MOV	r1, #160
	STR	r1, [r0, #8]
	MOV	r1, #32
	STR	r1, [r0, #12]
	LDR	r1, =score_text
	STR	r1, [r0, #16]
	BL	drawPicture

	// draw "LIVES:"
	LDR	r0, =pictureTemp
	MOV	r1, #620
	STR	r1, [r0, #0]
	MOV	r1, #48
	STR	r1, [r0, #4]
	LDR	r1, =lives_text
	STR	r1, [r0, #16]
	BL	drawPicture

	// draw 0 for score
	MOV	r0, #256
	MOV	r1, #48
	MOV	r2, #0
	BL	drawInteger

	// set lives to 3 and draw them
	MOV	r0, #3
	BL	updateLives

endInit:
	POP	{r4-r10, lr}
	BX	lr


startGame:
	// initialize the snake
	PUSH	{lr}
	LDR	r0, =tailPointer
	MOV	r1, #2
	STR	r1, [r0]

	BL	resetSnake

	// spawn first apple
	MOV	r0, #APPLE
	BL	spawnItem

/*
	BL	spawnValuePack
	BL	spawnValuePack
	BL	spawnValuePack
	BL	spawnValuePack
	BL	spawnValuePack
	BL	spawnValuePack
	BL	spawnValuePack
	BL	spawnValuePack
*/

	POP	{lr}

	BX	lr


//subroutine to create the hell strip map
setupHellStripMap:
	// get the map structure and starting point for the lines
	LDR	r3, =mapStructure
	LDR	r2, =386
	ADD	r0, r3, r2
	LDR	r2, =414
	ADD	r1, r3, r2

	// get the value for the wall to draw
	MOV	r2, #WALL

hellStripLoop:
	// make the lines
	STRB	r2, [r0, #64]
	STRB	r2, [r0], #1
	CMP	r0, r1
	BLT	hellStripLoop

	BX	lr


// r0: top left of box to draw
setupBabyBox:
	MOV	r1, #WALL
	STRB	r1, [r0], #1
	STRB	r1, [r0]
	STRB	r1, [r0, #31]
	STRB	r1, [r0, #32]
	BX	lr


// subroutine to create the baby map
setupBabyMap:
	PUSH	{lr}
	// get the map structure
	LDR	r3, =mapStructure

	LDR	r0, =295
	ADD	r0, r3

	BL	setupBabyBox
	ADD	r0, #15
	BL	setupBabyBox
	ADD	r0, #223
	BL	setupBabyBox
	SUB	r0, #17
	BL	setupBabyBox

	MOV	r1, #WALL
	LDR	r0, =399
	ADD	r0, r3
	STRB	r1, [r0]
	STRB	r1, [r0, #1]
	STRB	r1, [r0, #64]
	STRB	r1, [r0, #65]

	POP	{lr}
	BX	lr

// r0: itemID
// sets condition flags for it and returns 0 or 1
isSnake:
	MOV	r1, r0
	MOV	r0, #1

	CMP	r1, #FIRST_SNAKE_ITEM
	MOVLT	r0, #0
	BLT	isSnakeRet

	CMP	r1, #LAST_SNAKE_ITEM
	MOVGT	r0, #0

isSnakeRet:
	CMP	r0, #1
	BX	lr



// r0: itemID
// sets condition flags for it and returns 0 or 1
isTrailEnd:
	MOV	r1, r0
	MOV	r0, #1

	CMP	r1, #FIRST_TRAIL_END
	MOVLT	r0, #0
	BLT	isTrailEndRet

	CMP	r1, #LAST_TRAIL_END
	MOVGT	r0, #0

isTrailEndRet:
	CMP	r0, #1
	BX	lr





// r0: itemID
// sets condition flags for it and returns 0 or 1
isValuePack:
	MOV	r1, r0
	MOV	r0, #1

	CMP	r1, #VALUE_PACK1
	MOVLT	r0, #0
	BLT	isValuePackRet

	CMP	r1, #VALUE_PACK4
	MOVGT	r0, #0

isValuePackRet:
	CMP	r0, #1
	BX	lr







// delete the snake from the map structure and snake structure and reset it in the top left of the screen.
resetSnake:
	PUSH	{r4-r10, lr}

	// get snake structure start and end
	LDR	r4, =snakeStructure
	LDR	r5, =1140
	ADD	r5, r4
	MOV	r6, #EMPTY

	// get map structure
	LDR	r7, =mapStructure

resetSnakeStructure:
	// get next position in snake structure
	LDRB	r0, [r4]
	LDRB	r1, [r4, #1]

	// save temporarily
	MOV	r8, r0
	MOV	r9, r1

	// get map array index for position
	BL	coordToMap
	MOV	r10, r0

	// check type of position in map
	LDRB	r0, [r7, r10]
	BL	isSnake
	BNE	dontReset

	// clear position in map
	STRB	r6, [r7, r10]

	// get position back
	MOV	r0, r8
	MOV	r1, r9

	// clear cell
	MOV	r2, r6
	BL	drawItem

dontReset:

	// clear position in snake structure
	STRH	r6, [r4], #2

	// loop through snake structure
	CMP	r4, r5
	BLT	resetSnakeStructure

gohere:

	// store initial position of snake head in map structure
	MOV	r6, #SNAKE_RIGHT
	STRB	r6, [r7, #129]

	// get snake structure head
	LDR	r4, =snakeStructure

	// store initial position of snake head in snake structure
	MOV	r0, #1
	STRB	r0, [r4]
	MOV	r1, #4
	STRB	r1, [r4, #1]

	// draw snake head
	MOV	r2, #SNAKE_RIGHT
	BL	drawItem

	POP	{r4-r10, lr}
	BX	lr



// r0: map position
// remainder is x, quotient is y
mapToCoord:
	PUSH	{lr}
	
	MOV	r1, #32
	BL	udiv

	MOV	r2, r0
	MOV	r0, r1
	MOV	r1, r2

	POP	{lr}
	BX	lr



// r0: x
// r1: y
// return r0: position in array
coordToMap:
	LSL	r1, #5		// multiply by 32
	ADD	r0, r1

	BX	lr



// 0:		empty
// 1:		wall
// 2: 		snake
// 3:		exit door
// 4:		reserved
// 5:		apple
// 6+:		reserved
drawMap:
	PUSH	{r4-r9, lr}

	LDR	r9, =mapStructure
	MOV	r5, #0			// start of draw
	
drawMapLoop:
	LDRB	r4, [r9], #1

	MOV	r0, r5
	BL	mapToCoord

	MOV	r2, r4
	BL	drawItem

drawMapLoopGuard:
	ADD	r5, #1
	LDR	r7, =768
	CMP	r5, r7
	BLT	drawMapLoop
	
	POP	{r4-r9, lr}
	BX	lr


// sets the second piece of the snake to the correct image (for turning and moving in different directions)
setSecondPiece:
	PUSH	{r4-r10, lr}

	// get snake structure
	LDR	r3, =snakeStructure

	x1	.req	r4
	y1	.req	r5
	x2	.req	r6
	y2	.req	r7
	x3	.req	r8
	y3	.req	r9

	// get x1 and y1
	LDRB	x1, [r3, #0]
	LDRB	y1, [r3, #1]

	// get x3 and y3
	LDRB	x2, [r3, #2]
	LDRB	y2, [r3, #3]

	// get x2 and y2
	LDRB	x3, [r3, #4]
	LDRB	y3, [r3, #5]

	CMP	x1, x3
	BEQ	case1

	CMP	y1, y3
	BEQ	case2

	CMP	x1, x3
	BLT	case3
	B	case4

case1:
	CMP	y1, y3
	BLT	case1_2
case1_1:
	MOV	r10, #TRAIL_UP
	B	setSecondPiece_ret
case1_2:
	MOV	r10, #TRAIL_DOWN
	B	setSecondPiece_ret

case2:
	CMP	x1, x3
	BLT	case2_2
case2_1:
	MOV	r10, #TRAIL_RIGHT
	B	setSecondPiece_ret
case2_2:
	MOV	r10, #TRAIL_LEFT
	B	setSecondPiece_ret

case3:
	CMP	y1, y3
	BLT	case3_2
case3_1:
	CMP	x1, x2
	BNE	case3_1_2
case3_1_1:
	MOV	r10, #TRAIL_LEFT_DOWN
	B	setSecondPiece_ret
case3_1_2:
	MOV	r10, #TRAIL_DOWN_LEFT
	B	setSecondPiece_ret
case3_2:
	CMP	x1, x2
	BNE	case3_2_2
case3_2_1:
	MOV	r10, #TRAIL_LEFT_UP
	B	setSecondPiece_ret
case3_2_2:
	MOV	r10, #TRAIL_UP_LEFT
	B	setSecondPiece_ret

case4:
	CMP	y1, y3
	BLT	case4_2
case4_1:
	CMP	y1, y2
	BNE	case4_1_2
case4_1_1:
	MOV	r10, #TRAIL_DOWN_RIGHT
	B	setSecondPiece_ret
case4_1_2:
	MOV	r10, #TRAIL_RIGHT_DOWN
	B	setSecondPiece_ret
case4_2:
	CMP	y1, y2
	BNE	case4_2_2
case4_2_1:
	MOV	r10, #TRAIL_UP_RIGHT
	B	setSecondPiece_ret
case4_2_2:
	MOV	r10, #TRAIL_RIGHT_UP
	B	setSecondPiece_ret

setSecondPiece_ret:

	MOV	r0, x2
	MOV	r1, y2
	BL	coordToMap

	MOV	r2, r10

	LDR	r10, =mapStructure
	STRB	r2, [r10, r0]

	MOV	r0, x2
	MOV	r1, y2
	BL	drawItem

	.unreq	x1
	.unreq	y1
	.unreq	x2
	.unreq	y2
	.unreq	x3
	.unreq	y3

	POP	{r4-r10, lr}
	BX	lr



//r0: pack eaten
eatValuePack:
	PUSH	{r4-r10, lr}

	CMP	r0, #VALUE_PACK1
	BEQ	eatValuePack1

	CMP	r0, #VALUE_PACK2
	BEQ	eatValuePack2

	CMP	r0, #VALUE_PACK3
	BEQ	eatValuePack3

	CMP	r0, #VALUE_PACK4
	BEQ	eatValuePack4

// lots of points
eatValuePack1:
	MOV	r7, #50

	B	eatValuePackRet

// extra life
eatValuePack2:
	MOV	r0, #1
	BL	updateLives

	MOV	r7, #10

	B	eatValuePackRet

// half length
eatValuePack3:
	LDR	r4, =tailPointer
	LDR	r0, [r4]
	LSR	r0, #1
	BL	shrink

	MOV	r7, #10
	
	B	eatValuePackRet

// add 3 length
eatValuePack4:
	LDR	r4, =tailPointer
	LDR	r5, [r4]
	ADD	r5, #3
	STR	r5, [r4]

	MOV	r7, #20

	B	eatValuePackRet

eatValuePackRet:
	LDR	r5, =score
	LDR	r4, [r5]
	ADD	r4, r7
	STR	r4, [r5]

	MOV	r0, #256
	MOV	r1, #48
	MOV	r2, r4
	BL	drawInteger

	POP	{r4-r10, lr}
	BX	lr





//shrinks the snake by r0 pieces
// r0: length to remove
shrink:
	PUSH	{r4-r10, lr}

	MOV	r10, r0

	LDR	r4, =tailPointer
	LDR	r5, [r4]

shrinkLoop:
	CMP	r5, #3
	BLT	shrinkRet

	LDR	r6, =snakeStructure
	ADD	r6, r5, LSL #1
	LDRB	r0, [r6], #1
	LDRB	r1, [r6]

	MOV	r8, r0
	MOV	r9, r1

	BL	coordToMap
	PUSH	{r0}

	LDR	r7, =mapStructure
	LDRB	r0, [r7, r0]
	BL	isSnake

	POP	{r0}

	BNE	dontShrink

	MOV	r2, #EMPTY
	STRB	r2, [r7, r0]

	MOV	r0, r8
	MOV	r1, r9
	BL	drawItem
dontShrink:

	SUB	r5, #1
	SUBS	r10, #1
	BGT	shrinkLoop
shrinkRet:
	STR	r5, [r4]

	POP	{r4-r10, lr}
	BX	lr






// hides the map - unused- was for unimplemented value pack
hideMap:
	PUSH	{r4-r10, lr}

	MOV	r4, #1
	MOV	r5, #4

	MOV	r6, #31
	MOV	r7, #23

	LDR	r8, =mapStructure

hideMapLoop:
	LDRB	r9, [r8]

	CMP	r9, #WALL
	BEQ	actuallyHideMapCell
	CMP	r9, #EMPTY
	BEQ	actuallyHideMapCell

	B	hideMapLoopGuard
actuallyHideMapCell:
	MOV	r0, r4
	MOV	r1, r5
	MOV	r2, #TEXT_BACKGROUND
	BL	drawItem

hideMapLoopGuard:
	ADD	r4, #1
	CMP	r4, r6
	BLT	hideMapLoop

	MOV	r4, #1
	ADD	r5, #1
	CMP	r5, r7
	BLT	hideMapLoop

	POP	{r4-r10, lr}
	BX	lr





// sets the trail end to the correct piece (for the fading images)
setTrailEnd:
	PUSH	{r4-r10, lr}

	LDR	r4, =snakeStructure

	// get tail position
	LDR	r6, =tailPointer
	LDR	r5, [r6]
	LSL	r5, #1
	ADD	r5, r4

	// get coordinates
	LDRB	r0, [r5], #1
	LDRB	r1, [r5]

	// store temporarily
	MOV	r6, r0
	MOV	r7, r1

	// add 12 to value stored in map (change to end trail)
	BL	coordToMap
	LDR	r5, =mapStructure
	LDRB	r2, [r5, r0]

	MOV	r0, r2
	BL	isTrailEnd
	BEQ	setTrailEndRet

	MOV	r0, r2
	BL	isSnake
	BNE	setTrailEndRet

	ADD	r2, #12
	STRB	r2, [r5, r0]

	// draw end trail
	MOV	r0, r6
	MOV	r1, r7
	BL	drawItem

setTrailEndRet:
	POP	{r4-r10, lr}
	BX	lr



// moves the whole snake and handles eating valuepacks/apples and colliding with walls and exit doors
// main game method
// r0: direction data
moveSnake:

	PUSH	{r4-r10, lr}
	
	// get offset to tail
	LDR	r3, =tailPointer
	LDR	r1, [r3]
	// get pointer to head
	LDR	r2, =snakeStructure
	// multiply offset by 2 (2 bytes per segment)
	LSL	r1, #1
	// add offset to head
	ADD	r1, r2

	// shift snake segments right
moveSnakeLoop:
	// get current segment
	LDRH	r3, [r1]
	// store current segment one to right
	STRH	r3, [r1, #2]

	// subtract loop counter
	SUB	r1, #2

	// loop guard (stops after head)
	CMP	r2, r1
	BLE	moveSnakeLoop

	// save registers for subroutine call
	PUSH	{r0-r3}
afterSnakeLoop:
	// get previous tail position
	LDR	r6, =tailPointer
	LDR	r5, [r6]
	ADD	r5, #1
	LSL	r5, #1
	ADD	r5, r2

	// get position
	LDRB	r0, [r5], #1
	LDRB	r1, [r5]

	// save temporarily
	MOV	r7, r0
	MOV	r8, r1

	// get the map position
	BL	coordToMap
	MOV	r10, r0

	// set map position to empty
	LDR	r6, =mapStructure
	LDRB	r0, [r6, r10]
	BL	isSnake
	MOV	r0, r10
	BNE	dontClear

	// clear
	MOV	r4, #EMPTY
	STRB	r4, [r6, r0]

	// get position back
	MOV	r0, r7
	MOV	r1, r8

	// clear position
	MOV	r2, #EMPTY
	BL	drawItem

dontClear:

	PUSH	{r0-r3}
	BL	setTrailEnd
	POP	{r0-r3}

	// get saved registers back
	POP	{r0-r3}

	LDRB	r4, [r2]
	LDRB	r5, [r2, #1]

	// interpret input
	TST	r0, #2
	BEQ	moveUp

	TST	r0, #4
	BEQ	moveDown

	TST	r0, #8
	BEQ	moveLeft

	TST	r0, #16
	BEQ	moveRight

	// if direction is up
moveUp:
	SUB	r5, #1
	MOV	r10, #2

	B	moveSnakeHead
	// if direction is down
moveDown:
	ADD	r5, #1
	MOV	r10, #4

	B	moveSnakeHead
	// if direction is left
moveLeft:
	SUB	r4, #1
	MOV	r10, #8

	B	moveSnakeHead
	// if direction is right
moveRight:
	ADD	r4, #1
	MOV	r10, #16

	B	moveSnakeHead
moveSnakeHead:
	// get map
	LDR	r6, =mapStructure

	// get array position for next head
	MOV	r0, r4
	MOV	r1, r5
	BL	coordToMap

	// get value in map at next head position
	LDRB	r7, [r6, r0]

	// check if wall
	CMP	r7, #WALL
	MOVEQ	r10, #0
	BEQ	moveSnakeRet

	// check if apple
	CMP	r7, #APPLE
	BEQ	extend

	PUSH	{r0-r3}
	MOV	r0, r7
	BL	isValuePack
	POP	{r0-r3}
	
	BNE	notValuePack

	PUSH	{r0-r3}
	MOV	r0, r7
	BL	eatValuePack
	POP	{r0-r3}

	B	actuallyMoveHead
notValuePack:
	
	CMP	r7, #EXIT
	MOVEQ	r10, #-1
	BEQ	moveSnakeRet

	CMP	r7, #EMPTY
	MOVNE	r10, #0
	BNE	moveSnakeRet

	B	actuallyMoveHead
extend:
	//MOV	r8, #EMPTY
	//STRB	r8, [r6, r0]

	LDR	r7, =tailPointer
	LDR	r6, [r7]
	ADD	r6, #1
	STR	r6, [r7]

	LDR	r7, =apples
	LDR	r6, [r7]
	ADD	r6, #1
	STR	r6, [r7]

	PUSH	{r0-r3}

	CMP	r6, #APPLE_REQ
	MOVEQ	r0, #EXIT
	BLEQ	spawnItem

	LDR	r7, =score
	LDR	r6, [r7]
	ADD	r6, #5
	STR	r6, [r7]

	MOV	r0, #256
	MOV	r1, #48
	MOV	r2, r6
	BL	drawInteger

	MOV	r0, #APPLE
	BL	spawnItem
	POP	{r0-r3}	

actuallyMoveHead:
	// store moved x and y back to snake
	STRB	r4, [r2]
	STRB	r5, [r2, #1]

	// push for drawing head
	PUSH	{r0-r3}

	// get position for new head
	LDRB	r0, [r2], #1
	LDRB	r1, [r2]

	// save position temporarily
	MOV	r4, r0
	MOV	r5, r1

	// draw new head
	LSR	r2, r10, #1
	SUB	r2, #1
	CMP	r10, #16
	MOVEQ	r2, #3
	ADD	r2, #SNAKE_UP
	MOV	r9, r2
	BL	drawItem

	// get map index for position
	MOV	r0, r4
	MOV	r1, r5
	BL	coordToMap

	// set map position to snake
	LDR	r6, =mapStructure
	STRB	r9, [r6, r0]

	POP	{r0-r3}

	// return
	B	moveSnakeRet

moveSnakeRet:
	BL	setSecondPiece

	MOV	r0, r10

	POP	{r4-r10, lr}
	BX	lr



// Kawash giveth, and Kawash taketh away
// r0: number of lives to add
updateLives:
	PUSH	{r4-r10, lr}

	MOV	r4, r0

	LDR	r6, =bikeColor
	LDR	r5, [r6]
	ADD	r0, r5, #LIFE_ICON
//	MOV	r0, #LIFE_ICON
	BL	itemToImage

	CMP	r4, #0
	MOVGE	r5, r0
	LDRLT	r5, =text_background
	MOVGE	r6, #1
	MOVLT	r6, #-1
	MOVGE	r7, r4
	MVNLT	r7, r4
	ADDLT	r7, #1

	LDR	r8, =lives
	LDR	r9, [r8]
updateLivesLoop:
	CMP	r6, #0
	BLT	over_updateLives

	CMP	r9, #5
	BGE	updateLivesRet

over_updateLives:

	LDR	r3, =pictureTemp

	CMP	r6, #0

	ADDLT	r9, r6
	MOV	r4, #768
	ADD	r4, r9, LSL #5
	ADDGT	r9, r6


	STR	r4, [r3, #0]
	MOV	r4, #48
	STR	r4, [r3, #4]
	MOV	r4, #32
	STR	r4, [r3, #8]
	STR	r4, [r3, #12]
	STR	r5, [r3, #16]
	MOV	r0, r3
	BL	drawPicture

	SUBS	r7, #1
	BGT	updateLivesLoop
updateLivesRet:
	STR	r9, [r8]

	POP	{r4-r10, lr}
	BX	lr




spawnValuePack:
	PUSH	{r4-r10, lr}

	BL	rand32

	CMP	r0, #8
	MOVLT	r0, #VALUE_PACK1
	BLT	spawnValuePackRet

	CMP	r0, #16
	MOVLT	r0, #VALUE_PACK2
	BLT	spawnValuePackRet

	CMP	r0, #24
	MOVLT	r0, #VALUE_PACK3
	BLT	spawnValuePackRet

	CMP	r0, #32
	MOVLT	r0, #VALUE_PACK4
	BLT	spawnValuePackRet

spawnValuePackRet:
	BL	spawnItem

	POP	{r4-r10, lr}
	BX	lr





spawnItem:
	PUSH	{r4-r10, lr}

	MOV	r5, r0

yLoop:
	BL	rand32
	MOV	r6, r0

	CMP	r0, #23
	MOVGE	r1, #23	
	BLGE	udiv
	MOVGE	r0, r1

	CMP	r0, #3
	BLE	yLoop

	MOV	r7, r0

xLoop:
	BL	rand32
	MOV	r6, r0

	CMP	r0, #0
	BEQ	xLoop

	CMP	r0, #31
	BEQ	xLoop

	CMP	r0, #1
	BNE	over
	CMP	r7, #4
	BEQ	yLoop

over:
	MOV	r8, r0
	MOV	r1, r7
	BL	coordToMap

	LDR	r4, =mapStructure
	LDRB	r6, [r4, r0]
	
	CMP	r6, #EMPTY
	BNE	yLoop

	STRB	r5, [r4, r0]
	MOV	r2, r5
	MOV	r0, r8
	MOV	r1, r7
	BL	drawItem


	POP	{r4-r10, lr}
	BX	lr


// r0 - item id
itemToImage:

	LDR	r1, =itemIDs
	LSL	r0, #2
	LDR	r0, [r1, r0]
	
	BX	lr

// r0 - x
// r1 - y
// r2 - item
drawItem:
	PUSH	{r4-r8, lr}

	MOV	r7, r0
	MOV	r8, r1

	MOV	r0, r2
	BL	isSnake
	BNE	justDrawIt

	LDR	r5, =bikeColor
	LDR	r4, [r5]

	// multiply r4 by 28
	LSL	r5, r4, #5
	LSL	r6, r4, #2
	SUB	r4, r5, r6
	ADD	r2, r4

justDrawIt:
	MOV	r0, r7
	MOV	r1, r8

	LSL	r0, #5
	LSL	r1, #5
	
	LDR	r3, =pictureTemp
	STR	r0, [r3]
	STR	r1, [r3, #4]
	MOV	r0, #32
	STR	r0, [r3, #8]
	STR	r0, [r3, #12]

	MOV	r0, r2

	BL	itemToImage

	STR	r0, [r3, #16]

	MOV	r0, r3
	BL	drawPicture

	POP	{r4-r8, lr}
	BX	lr


// redraws an area of the map (mainly for the pause mnenu)
// r0 - initial x
// r1 - initial y
// r2 - width
// r3 - height
redrawArea:

	PUSH	{r4-r10, lr}
	MOV	r4, r0
	MOV	r5, r1

	ADD	r6, r0, r2
	ADD	r7, r1, r3

	MOV	r8, r0
	LDR	r9, =mapStructure
	ADD	r9, r1, LSL #5
structureLoop:
	MOV	r4, r8
	CMP	r5, r7
	BGE	structureRedrawn

xStructureLoop:
	CMP	r4, r6
	ADDGE	r5, #1
	ADDGE	r9, #32
	BGE	structureLoop

	LDRB	r2, [r9, r4]
	MOV	r0, r4
	MOV	r1, r5
	BL	drawItem
	
	ADD	r4, #1
	B	xStructureLoop

structureRedrawn:

	POP	{r4-r10, lr}
	BX	lr


// fill the screen with a specific item (for clear screen with correct background color)
// r0: item
fillScreenWithItem:
	PUSH	{r4-r10, lr}

	MOV	r4, r0
	MOV	r5, #0
	MOV	r6, #0

fillScreenWithItemLoop:
	MOV	r0, r5
	MOV	r1, r6
	MOV	r2, r4
	BL	drawItem

	ADD	r5, #1
	CMP	r5, #32
	BLT	fillScreenWithItemLoop

	MOV	r5, #0
	ADD	r6, #1
	CMP	r6, #24
	BLT	fillScreenWithItemLoop

	POP	{r4-r10, lr}
	BX	lr





// draw the selected bike side profile in the menu
drawBikeColor:
	PUSH	{lr}
	
	// get current bike color
	LDR	r1, =bikeColor
	LDR	r0, [r1]

	// add as offset to base
	MOV	r1, #ORANGE_SELECTION
	ADD	r0, r1

	// get the image pointer
	BL	itemToImage
	MOV	r2, r0

	// draw the image
	LDR	r0, =pictureTemp
	MOV	r1, #160
	STR	r1, [r0, #0]
	MOV	r1, #512
	STR	r1, [r0, #4]
	MOV	r1, #128
	STR	r1, [r0, #8]
	MOV	r1, #128
	STR	r1, [r0, #12]
	STR	r2, [r0, #16]
	BL	drawPicture

	POP	{lr}
	BX	lr




// draw the selected map label in the main menu
drawMapLabel:
	PUSH	{lr}

	LDR	r2, =map
	LDR	r1, [r2]

	LDR	r2, =maps
	LSL	r1, #3
	ADD	r1, r2
	ADD	r1, #4

	LDR	r0, [r1]
	MOV	r2, r0

	// draw the image
	LDR	r0, =pictureTemp
	MOV	r1, #352
	STR	r1, [r0, #0]
	MOV	r1, #560
	STR	r1, [r0, #4]
	MOV	r1, #512
	STR	r1, [r0, #8]
	MOV	r1, #32
	STR	r1, [r0, #12]
	STR	r2, [r0, #16]
	BL	drawPicture

	POP	{lr}
	BX	lr




// change the current selected map
// r0: "direction" to change (0 or 1)
changeMap:
	PUSH	{lr}

	LDR	r2, =map
	LDR	r1, [r2]

	CMP	r0, #0
	SUBEQ	r1, #1
	ADDNE	r1, #1

	CMP	r1, #2
	MOVEQ	r1, #0

	CMP	r1, #-1
	MOVEQ	r1, #1

	STR	r1, [r2]
	
	BL	drawMapLabel

	POP	{lr}
	BX	lr




// change the current selected bike (cycle through)
changeBikeColor:
	PUSH	{lr}

	LDR	r1, =bikeColor
	LDR	r0, [r1]
	ADD	r0, #1

	CMP	r0, #3
	MOVEQ	r0, #0

	STR	r0, [r1]

	BL	drawBikeColor

	POP	{lr}
	BX	lr







.section	.data

// snake structure is a simple queue-like array system for storing the positions of the snake sections
snakeStructure:
	.rept	1140		// 30*19*2
	.byte	0
	.endr
// map structure contains current game states
mapStructure:
	.rept	768		// 32*24
	.byte	0
	.endr
// item ids for drawItem method
itemIDs:
	.word	floor, white_glowing_box, blue_glowing_box, green_glowing_box, orange_selection, green_selection, pink_selection, 0, 0
	.word	text_background, menu_pointer, orange_life, green_life, pink_life, 0, 0
	.word	disk, value_pack, value_pack, value_pack, value_pack, 0, 0, 0, 0, 0

	.word	bike_up, bike_down, bike_left, bike_right, trail_vertical, trail_vertical, trail_horizontal, trail_horizontal, trail_right_down, trail_right_down, trail_right_up, trail_right_up, trail_up_right, trail_up_right, trail_down_right, trail_down_right, trail_down_end, trail_up_end, trail_left_end, trail_right_end, trail_right_down_end, trail_up_left_end, trail_right_up_end, trail_down_left_end, trail_up_right_end, trail_left_down_end, trail_down_right_end, trail_left_up_end

	.word	green_bike_up, green_bike_down, green_bike_left, green_bike_right, green_trail_vertical, green_trail_vertical, green_trail_horizontal, green_trail_horizontal, green_trail_right_down, green_trail_right_down, green_trail_right_up, green_trail_right_up, green_trail_up_right, green_trail_up_right, green_trail_down_right, green_trail_down_right, green_trail_down_end, green_trail_up_end, green_trail_left_end, green_trail_right_end, green_trail_right_down_end, green_trail_up_left_end, green_trail_right_up_end, green_trail_down_left_end, green_trail_up_right_end, green_trail_left_down_end, green_trail_down_right_end, green_trail_left_up_end

	.word	pink_bike_up, pink_bike_down, pink_bike_left, pink_bike_right, pink_trail_vertical, pink_trail_vertical, pink_trail_horizontal, pink_trail_horizontal, pink_trail_right_down, pink_trail_right_down, pink_trail_right_up, pink_trail_right_up, pink_trail_up_right, pink_trail_up_right, pink_trail_down_right, pink_trail_down_right, pink_trail_down_end, pink_trail_up_end, pink_trail_left_end, pink_trail_right_end, pink_trail_right_down_end, pink_trail_up_left_end, pink_trail_right_up_end, pink_trail_down_left_end, pink_trail_up_right_end, pink_trail_left_down_end, pink_trail_down_right_end, pink_trail_left_up_end


// array of maps and their labels
maps:
	.word	setupHellStripMap, hell_strip_map, setupBabyMap, baby_map


.align 2

// global variables
tailPointer:
	.word	2
//playerFlag:
//	.int	0	// 0 is playing, 1 is loser, 2 is win
lives:
	.int	0	// starts with 0, loses one on death
score:
	.int	0	// starts at 0, increments with value packs and apples
apples:
	.int	0
bikeColor:
	.int	0
map:
	.int	0








