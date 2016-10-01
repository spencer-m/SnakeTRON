// +------------------------------------------+
// | CPSC 359                                 |
// | Assignment #4: Snake inspired by TRON    |
// | TA: Abed Sarhan                          |
// | Timothy Mealey                           |
// | David Sepulveda                          |
// | Spencer Manzon                           |
// + -----------------------------------------+

.equ	TEXT_BACKGROUND, 9
.equ	MENU_POINTER, 10

.section	.init
.globl		_start
_start:
    	B       main
    
.section	.text

main:
	BL	initTable		// initializes the interrupt vector state and the stack pointer
	BL	EnableJTAG 		// Enable JTAG
	BL	InitUART   		// Initialize the UART
	BL	InitSNES		// Initialize the SNES controller
	BL	initFrameBuffer		// Initialize the screen

	BL	sysIRQ_enable		// enable IRQ interrupts

	MOV	r10, #0			// init "not drawn" --- if j _start is executed
	MOV	r9, #16			// init state movement --- if j_start is executed
 	MOV	r8, #0			// init pointer pos --- if j_start is executed

	LDR	r1, =gameState		
	MOV	r0, #2
	STR	r0, [r1]

controller:
	
	// Start of Added Lines since first submission
	// MAINTAINING THE INTERRUPT VECTOR TABLE
	PUSH	{r0-r10}

	LDR	r0, =ISRTable
	MOV	r1, #0x00000000
	LDMIA	r0!, {r2-r9}
	STMIA	r1!, {r2-r9}

	LDMIA	r0!, {r2-r9}
	STMIA	r1!, {r2-r9}

	POP	{r0-r10}

	// End of Added Lines since first submission

	// global delay
	LDR	r0, =80000
	BL	wait
	// check game state
	LDR	r1, =gameState
	LDR	r0, [r1]
	// go to play state
	CMP	r0, #0
	BEQ	stateGame
	// go to paused state
	CMP	r0, #1
	BEQ	statePaused
	// go to main menu state
	CMP	r0, #2
	BEQ	stateMainMenu
	// go to end game state
	CMP	r0, #3
	BEQ	stateEnd
	// go to exit game state
	CMP	r0, #4
	BEQ	quitGame

	// infinite loop catch when not a valid state
	B	controller

stateGame:

	BL	readSNES

	LDR	r1, =0xFFFFFF07		// clears every button except directional and start
	ORR	r0, r1
	ASR	r0, #3			// shifting so that smaller values for button checks
	CMP	r0, #-1
	BICEQ	r0, r9
	BEQ	stateGame_update	// if nothing is pressed do nothing

	TST	r0, #1			// start
	BEQ	stateGame_start
	TST	r0, #2			// up
	BEQ	stateGame_up
	TST	r0, #4			// down
	BEQ	stateGame_down
	TST	r0, #8			// left
	BEQ	stateGame_left
	TST	r0, #16			// right
	BEQ	stateGame_right

stateGame_start:

	LDR	r1, =gameState		// set game state to play state
	MOV	r0, #1
	STR	r0, [r1]

	B	controller

stateGame_up:

	CMP	r9, #4			// if direction is down do nothing
	LDREQ	r0, =0xFFFFFFFB
	B	stateGame_update

stateGame_down:

	CMP	r9, #2			// if direction up do nothing
	LDREQ	r0, =0xFFFFFFFD
	B	stateGame_update

stateGame_left:

	CMP	r9, #16			// if direction right do nothing
	LDREQ	r0, =0xFFFFFFEF
	B	stateGame_update

stateGame_right:

	CMP	r9, #8			// if direction left do nothing
	LDREQ	r0, =0xFFFFFFF7
	B	stateGame_update

stateGame_update:

	BL	moveSnake
	CMP	r0, #0
	MOV	r9, r0
	BLT	winGame
	BNE	didntDie

	LDR	r0, =1000000		// delay when dieded
	BL	wait

	MOV	r0, #-1
	BL	updateLives

	LDR	r1, =lives
	LDR	r2, [r1]
	CMP	r2, #0
	BEQ	loseGame
	STR	r2, [r1]

	MOV	r9, #16
	BL	resetSnake

didntDie:
	B	controller

loseGame:
	LDR	r1, =gameState
	MOV	r0, #3			// go to end state
	STR	r0, [r1]

	LDR	r1, =playerFlag
	MOV	r0, #1			// lose if playerFlag is 1
	STR	r0, [r1]

	B	controller

winGame:
	LDR	r1, =gameState
	MOV	r0, #3			// go to end state
	STR	r0, [r1]

	LDR	r1, =playerFlag
	MOV	r0, #2			// win if playerFlag is 2
	STR	r0, [r1]

	B	controller

statePaused:

	CMP	r10, #0
	BNE	statePaused_drawn

	LDR	r0, =pictureTemp
	MOV	r1, #416
	STR	r1, [r0, #0]
	MOV	r1, #384
	STR	r1, [r0, #4]
	MOV	r1, #192
	STR	r1, [r0, #8]
	MOV	r1, #64
	STR	r1, [r0, #12]
	LDR	r1, =pause_menu
	STR	r1, [r0, #16]
	BL	drawPicture

	MOV	r0, #12
	MOV	r1, #12
	MOV	r2, #MENU_POINTER
	BL	drawItem
	
	MOV	r0, #12
	MOV	r1, #13
	MOV	r2, #TEXT_BACKGROUND
	BL	drawItem

	MOV	r8, #0
	MOV	r10, #1

	LDR	r0, =80000
	BL	wait

	BL	disableIRQ

statePaused_drawn:

	BL	readSNES

	LDR	r1, =0xFFFFFEC7		// clears every button except up, down, start and A
	ORR	r0, r1
	CMP	r0, #-1
	BEQ	controller


statePaused_A:

	TST	r0, #256		// when A is pressed
	BNE	statePaused_down

	CMP	r8, #0
	BEQ	statePaused_restartGame
	BNE	statePaused_mainMenu

	B	controller

statePaused_down:

	TST	r0, #32			// when down is pressed
	BNE	statePaused_up

	CMP	r8, #0
	MOVEQ	r8, #1
	MOVNE	r8, #0

	B	statePaused_updatePointer

statePaused_up:

	TST	r0, #16			// when up is pressed
	BNE	statePaused_start

	CMP	r8, #0
	MOVEQ	r8, #1
	MOVNE	r8, #0

statePaused_updatePointer:

	MOV	r0, #12
	MOV	r1, #12
	MOV	r2, #TEXT_BACKGROUND
	BL	drawItem

	MOV	r0, #12
	MOV	r1, #13
	MOV	r2, #TEXT_BACKGROUND
	BL	drawItem

	MOV	r0, #12
	ADD	r1, r8, #12
	MOV	r2, #MENU_POINTER
	BL	drawItem

	B	controller

statePaused_start:

	TST	r0, #8			// start button
	BNE	controller

	LDR	r1, =gameState
	MOV	r0, #0
	STR	r0, [r1]

	MOV	r0, #12
	MOV	r1, #12
	MOV	r2, #7
	MOV	r3, #2
	BL	redrawArea
	MOV	r10, #0

	LDR	r0, =80000
	BL	wait

	BL	initTimer
	BL	enableIRQ

	B	controller


statePaused_restartGame:	
	// restart game when EQ
	LDR	r1, =gameState
	MOV	r0, #0
	STR	r0, [r1]
	MOV	r9, #16			// state of movement up down left right
	BL	randSeed
	BL	initGame		// Initialize the game
	BL	startGame		// Start the game
	MOV	r10, #0

	BL	initTimer
	BL	enableIRQ

	B	controller

statePaused_mainMenu:
	// go to main menu when NE
	LDR	r1, =gameState
	MOV	r0, #2
	STR	r0, [r1]
	MOV	r10, #0

	B	controller

stateMainMenu:

	CMP	r10, #0
	BNE	stateMainMenu_drawn

	MOVEQ	r0, #TEXT_BACKGROUND
	BLEQ	fillScreenWithItem

	LDR	r0, =pictureTemp
	MOV	r1, #416
	STR	r1, [r0, #0]
	MOV	r1, #384
	STR	r1, [r0, #4]
	MOV	r1, #192
	STR	r1, [r0, #8]
	MOV	r1, #64
	STR	r1, [r0, #12]
	LDR	r1, =main_menu
	STR	r1, [r0, #16]
	BL	drawPicture

	MOV	r0, #12
	MOV	r1, #12
	MOV	r2, #MENU_POINTER
	BL	drawItem
	
	MOV	r0, #12
	MOV	r1, #13
	MOV	r2, #TEXT_BACKGROUND
	BL	drawItem

	LDR	r0, =pictureTemp
	MOV	r1, #288
	STR	r1, [r0, #0]
	MOV	r1, #32
	STR	r1, [r0, #4]
	MOV	r1, #384
	STR	r1, [r0, #8]
	MOV	r1, #94
	STR	r1, [r0, #12]
	LDR	r1, =title
	STR	r1, [r0, #16]
	BL	drawPicture

	LDR	r0, =pictureTemp
	MOV	r1, #160
	STR	r1, [r0, #0]
	MOV	r1, #736
	STR	r1, [r0, #4]
	MOV	r1, #608
	STR	r1, [r0, #8]
	MOV	r1, #32
	STR	r1, [r0, #12]
	LDR	r1, =creators_text
	STR	r1, [r0, #16]
	BL	drawPicture

	LDR	r0, =pictureTemp
	MOV	r1, #352
	STR	r1, [r0, #0]
	MOV	r1, #224
	STR	r1, [r0, #4]
	MOV	r1, #256
	STR	r1, [r0, #8]
	MOV	r1, #64
	STR	r1, [r0, #12]
	LDR	r1, =cpsc_359_text
	STR	r1, [r0, #16]
	BL	drawPicture

	BL	drawBikeColor
	BL	drawMapLabel

	MOV	r8, #0
	MOV	r10, #1

	BL	disableIRQ

stateMainMenu_drawn:

	BL	readSNES

	LDR	r1, =0xFFFFFE0B		// clears every button except directional, select and A
	ORR	r0, r1
	CMP	r0, #-1
	BEQ	controller


stateMainMenu_SEL:

	TST	r0, #4			// when select is pressed
	BNE	stateMainMenu_left

	BL	changeBikeColor

	B	controller

stateMainMenu_left:

	TST	r0, #64			// when left is pressed
	BNE	stateMainMenu_right

	MOV	r0, #0
	BL	changeMap

	B	controller

stateMainMenu_right:

	TST	r0, #128		// when right is pressed
	BNE	stateMainMenu_down

	MOV	r0, #1
	BL	changeMap

	B	controller


stateMainMenu_down:

	TST	r0, #32			// when down is pressed
	BNE	stateMainMenu_up

	CMP	r8, #0
	MOVEQ	r8, #1
	MOVNE	r8, #0

	B	stateMainMenu_updatePointer

stateMainMenu_up:

	TST	r0, #16			// when up is pressed
	BNE	stateMainMenu_A

	CMP	r8, #0
	MOVEQ	r8, #1
	MOVNE	r8, #0

	B	stateMainMenu_updatePointer


stateMainMenu_updatePointer:

	MOV	r0, #12
	MOV	r1, #12
	MOV	r2, #TEXT_BACKGROUND
	BL	drawItem

	MOV	r0, #12
	MOV	r1, #13
	MOV	r2, #TEXT_BACKGROUND
	BL	drawItem

	MOV	r0, #12
	ADD	r1, r8, #12
	MOV	r2, #MENU_POINTER
	BL	drawItem

	B	controller

stateMainMenu_A:

	TST	r0, #256			// when A is pressed
	BNE	controller

	CMP	r8, #0

	BEQ	stateMainMenu_startGame
	BNE	stateMainMenu_exitGame
	B	controller

stateMainMenu_startGame:

	// start game when EQ
	LDR	r1, =gameState
	MOV	r0, #0
	STR	r0, [r1]
	MOV	r9, #16			// state of movement up down left right
	BL	randSeed
	BL	initGame		// Initialize the game
	BL	startGame		// Start the game
	MOV	r10, #0

	BL	initTimer
	BL	enableIRQ

	B	controller

stateMainMenu_exitGame:

	// exit game
	BL	disableIRQ

	LDR	r1, =gameState
	MOV	r0, #4
	STR	r0, [r1]


	MOV	r0, #TEXT_BACKGROUND
	BL	fillScreenWithItem
	MOV	r10, #0
	B	controller


stateEnd:

	CMP	r10, #0
	BNE	stateEnd_drawn

	LDR	r1, =playerFlag
	LDR	r0, [r1]

	BL	disableIRQ

	// when lose
	CMP	r0, #1
	BNE	stateEnd_notLose

	MOV	r0, #TEXT_BACKGROUND
	BL	fillScreenWithItem

	LDR	r0, =pictureTemp
	MOV	r1, #336
	STR	r1, [r0, #0]
	MOV	r1, #224
	STR	r1, [r0, #4]
	MOV	r1, #288
	STR	r1, [r0, #8]
	MOV	r1, #64
	STR	r1, [r0, #12]
	LDR	r1, =you_lose
	STR	r1, [r0, #16]
	BL	drawPicture

	LDR	r0, =pictureTemp
	MOV	r1, #336
	STR	r1, [r0, #0]
	MOV	r1, #704
	STR	r1, [r0, #4]
	MOV	r1, #288
	STR	r1, [r0, #8]
	MOV	r1, #64
	STR	r1, [r0, #12]
	LDR	r1, =press_any_key
	STR	r1, [r0, #16]
	BL	drawPicture

stateEnd_notLose:

	// when win
	CMP	r0, #2
	BNE	stateEnd_notWin

	// fancy snek exit
	MOV	r0, #TEXT_BACKGROUND
	BL	fillScreenWithItem

	LDR	r0, =pictureTemp
	MOV	r1, #352
	STR	r1, [r0, #0]
	MOV	r1, #224
	STR	r1, [r0, #4]
	MOV	r1, #256
	STR	r1, [r0, #8]
	MOV	r1, #64
	STR	r1, [r0, #12]
	LDR	r1, =you_win
	STR	r1, [r0, #16]
	BL	drawPicture

	LDR	r0, =pictureTemp
	MOV	r1, #336
	STR	r1, [r0, #0]
	MOV	r1, #704
	STR	r1, [r0, #4]
	MOV	r1, #288
	STR	r1, [r0, #8]
	MOV	r1, #64
	STR	r1, [r0, #12]
	LDR	r1, =press_any_key
	STR	r1, [r0, #16]
	BL	drawPicture

stateEnd_notWin:

	MOV	r10, #1

stateEnd_drawn:

	BL	readSNES

	LDR	r1, =0xFFFFF000		// clears no button
	ORR	r0, r1
	CMP	r0, #-1
	BEQ	controller

	LDR	r1, =gameState
	MOV	r0, #2
	STR	r0, [r1]
	MOV	r10, #0

	B	controller


quitGame:
	BL	sysIRQ_disable

haltLoop:
	B	haltLoop

.section	.data

.align 2
gameState:
	.int	0
playerFlag:
	.int	0
