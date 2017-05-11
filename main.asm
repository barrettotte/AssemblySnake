TITLE Snake V1							(main.asm)
; Barrett Otte
; Snake - Made with MASM x86 and Irvine32
;
;
; This project is meant to get myself back into assembly programming so I can
;		learn more complicated topics in cyber security.
; I chose to pick a game of Snake because it was complicated (for my skill level with assembly) and gave me something
;		challenging to try to complete.
;
;
;
; Reading:
;		Irvine32 Documentation: http://programming.msjc.edu/asm/help/index.html?page=source%2Fabout.htm
;		GetKeyState: https://msdn.microsoft.com/en-us/library/windows/desktop/ms646301(v=vs.85).aspx
;		Instruction Set Reference: http://www.felixcloutier.com/x86/
;		ASCII Art Generator: http://patorjk.com/software/taag/
;
;
;
; To Do:
;	- Snake's color can be changed from main menu.
;	- Spawned food is a random character.
;	- Collision with self ends game (lea? Buffer?) ***** Need to do this!
;	- Weird bug where it defaults to game over?
;	- A menu to restart the game with a key press.
;	- A pause menu with [ESC] and nav to main menu.
;
;
;
; Features:
;	- Basic controls with arrow keys
;	- Speed of snake can be chosen (difficulty)
;	- Score tracking 
;	- Player name input
;	- When "colliding" with food, the snake grows by 1 character.
;	- Uses Irvine32 and user32.lib
;
;
;
; Errors:				
;	- Have not found anything yet
;
;
;
;
;			LAST UPDATED: 11-09-2016





; Files:
INCLUDE		Irvine32.inc									; GoToXY, Random32, Randomize
INCLUDELIB	user32.lib										; GetKeyState





; Macros:
mGotoxy MACRO X:REQ, Y:REQ									; Reposition cursor to x,y position
		PUSH	EDX
		MOV		DH, Y
		MOV		DL, X
		CALL	Gotoxy
		POP		EDX
ENDM


mWrite MACRO text:REQ										; Write string literals.
	LOCAL string
	.data
		string BYTE text, 0
	.code
		PUSH	EDX
		MOV		EDX, OFFSET string
		CALL	WriteString
		POP		EDX
ENDM


mWriteString MACRO buffer:REQ								; Write string variables
		PUSH	EDX
		MOV		EDX, OFFSET buffer
		CALL	WriteString
		POP		EDX
ENDM


mReadString MACRO var:REQ									; Read string from console
		PUSH	ECX
		PUSH	EDX
		MOV		EDX, OFFSET var
		MOV		ECX, SIZEOF var
		CALL	ReadString
		POP		EDX
		POP		ECX
ENDM





; Structs:
AXIS STRUCT													; Struct used to spawn food and keep track of snake body.
    x BYTE 0
    y BYTE 0
AXIS ENDS



; KeyCodes:
	VK_LEFT		  EQU		000000025h
	VK_UP		  EQU		000000026h
	VK_RIGHT	  EQU		000000027h
	VK_DOWN		  EQU		000000028h


; Game "Window" Setup:
	maxX		  EQU       79								; Fits standard console size
	maxY		  EQU       23
	wallHor       EQU       "--------------------------------------------------------------------------------"
	wallVert      EQU       '|'
	maxSize		  EQU       255
															
	

; Prototypes:
GetKeyState PROTO, nVirtKey:DWORD





.data





	foodPoint	 AXIS    <0,0>								; The spawn point of the food
	SnakeBody    AXIS    maxSize DUP(<0,0>)					; The snake's body of chars
    
    score        DWORD   0
	speed		 DWORD   60									; How fast we update the sleep function in ms
															; This is how fast the snake travels.
	foodChar     BYTE   '0'
	snakeChar	 BYTE	'#'
    playerName   BYTE    13 + 1 DUP (?)
    currentX	 BYTE    40									; spawn point x
    currentY	 BYTE    10									; spawn point y
    choice       BYTE    0									; menu selection variable
    headIndex    BYTE    3   
    tailIndex    BYTE    0 
    LEFT         BYTE    0
    RIGHT        BYTE    1									; Initialize with snake moving right
    UP           BYTE    0
    DOWN         BYTE    0		
					




.code





main PROC
		CALL	StartGame
		RET
main ENDP





SetDirection PROC, R:BYTE, L:BYTE, U:BYTE, D:BYTE			; Values set in KeySync, either 0 or 1
		MOV		DL, R										
		MOV		RIGHT, DL
    
		MOV		DL, L										; Called when a key is pressed
		MOV		LEFT, DL									; Set Direction Bytes appropriately
    
		MOV		DL, U
		MOV		UP, DL
    
		MOV		DL, D
		MOV		DOWN, DL
		RET
SetDirection ENDP





KeySync PROC												; Handles arrow key presses

  	X00:
        MOV		AH, 0
        INVOKE GetKeyState, VK_DOWN						
        CMP		AH, 0										; Pressed? AH is 1 --> Key Is Pressed
        JE		X01											; IF not pressed, jump to next logic
        CMP		currentY, maxY								; Are we in bounds?
        JNL		X01											; IF not within bounds jump to next logic
        INC		currentY									; IF in bounds, Increment y index
        INVOKE	SetDirection, 0, 0, 0, 1					; Travel in -y direction, DOWN is set
        RET

  	X01:
        MOV     AH, 0										; All key presses work the same way
        INVOKE  GetKeyState, VK_UP							; If you are not within bounds you fall through to
        CMP     AH, 0										;		the bottom
        JE      X02
        CMP     currentY, 0
        JNG     X02  
        DEC     currentY
        INVOKE  SetDirection, 0, 0, 1, 0
        RET

    X02:     
        MOV     AH, 0										; See  X01 comments
        INVOKE  GetKeyState, VK_LEFT						
        CMP     AH, 0   
        JE      X03
        CMP     currentX, 0
        JNG     X03 
        DEC     currentX
        INVOKE  SetDirection, 0, 1, 0, 0
        RET

    X03:  
        MOV		AH, 0										; See  X01 comments
        INVOKE  GetKeyState, VK_RIGHT
        CMP     AH, 0   
        JE      X04
        CMP     currentX, maxX
        JNL     X04 
        INC     currentX
        INVOKE  SetDirection, 1, 0, 0, 0
        RET

    X04:     
        CMP     RIGHT, 0									; Has RIGHT been set?
        JE      X05											; IF RIGHT has not been set jump to next logic
        CMP     currentX, maxX								; Are we out of bounds?
        JNL     X05											; IF out of bounds, jump to next logic
        INC     currentX									; IF in bounds, travel x direction
    
	X05:
        CMP     LEFT, 0										; See X04 comments
        JE		X06
        CMP     currentX, 0
        JNG     X06
        DEC     currentX
    
	X06:
        CMP     UP, 0										; See X04 comments
        JE      X07
        CMP     currentY, 0
        JNG     X07
        DEC     currentY

    X07:
        CMP     DOWN, 0										; See X04 comments
        JE      X08
        CMP     currentY, maxY
        JNL     X08
        INC     currentY

    X08:													
        RET													
KeySync ENDP





Grow PROC													; Check if we "collide" with food
		MOV     AH, currentX
        MOV     AL, currentY

        CMP     AH, FoodPoint.x								; Is my X equal to the Food X
        JNE     X00											; IF not, Exit PROC
        CMP     AL, FoodPoint.y								; Is my y equal to the Food Y
        JNE     X00

        CALL    GenerateFood								; IF we are "colliding" with Food
        INC     headIndex									; Move head index for new growth
        ADD     score, 10									; Score is incremented after eating
   
	X00:
        RET
Grow ENDP





PrintWalls PROC												; Draw Walls to screen
		mGotoxy 0, 1     
		mWrite	wallHor
		mGotoxy 0, maxY										; Draw top and bottom walls
		mWrite	wallHor    
		MOV		CL, maxY - 1								; Prepare CL for vertical wall placement
	
	X00:
		CMP		CL, 1										; WHILE CL != 0
		JE		X01											; IF it does, exit WHILE loop
        mGotoxy 0, CL										; Write left wall piece
        mWrite	wallVert								
        mGotoxy maxX, CL
        mWrite	wallVert									; Write right wall piece
        DEC		CL											; travel up the screen until all are placed
		JMP		X00											; Jump to top of WHILE loop
    
	X01:
		RET
PrintWalls ENDP





IsCollision PROC											; Did we "collide" with a wall?
		CMP		currentX, 0									; Did we hit the left wall?
		JE		X00											
		CMP		currentY, 2									; Did we hit the top wall?
		JE		X00
		CMP		currentX, maxX								; Did we hit the right wall?
		JE		X00
		CMP		currentY, maxY								; Did we hit the bottom wall?
		JE		X00

		JMP		X01											; Jump if we did not hit any walls
	
	X00:
		MOV		EAX, 1										; EAX holds whether game is over or not
		RET

	X01:
		MOV		EAX, 0										; 0 = game is NOT over
		RET
IsCollision ENDP





MoveSnake PROC
		MOV		ECX, 0
		MOV		CL, headIndex								; Head position in array
    
		MOV		AL, currentX
		MOV		AH, currentY								; Load current x and y pos 

		MOV		SnakeBody[2 * ECX].x, AL					; load snake body to new x/y positions
		MOV		SnakeBody[2 * ECX].y, AH					
															
		mGotoxy SnakeBody[2 * ECX].x, SnakeBody[2 * ECX].y
		MOV		AL, snakeChar								; Move snake body to new position
		CALL	WriteChar									; Write the snakechar to screen
    
		INVOKE	Sleep, speed								; Using sleep, speed can be affected
      
		MOV		ECX, 0  
		MOV		CL, tailIndex
		CMP		SnakeBody[2 * ECX].x, 0						; Overwrite the previous snake char to sim. movement
		JE		X00
        mGotoxy SnakeBody[2 * ECX].x, SnakeBody[2 * ECX].y
        mWrite	" " 
    
	X00:
		INC		tailIndex
		INC		headIndex
		CMP		tailIndex, maxSize
		JNE		X01
		MOV		tailIndex, 0

	X01:
		CMP		headIndex, maxSize							; Reset head index
		JNE		X02
		MOV		headIndex, 0

	X02:
		RET
MoveSnake ENDP





DrawHUD PROC												; Display "HUD" information

		mGotoxy	2, 0									
		mWrite	"Score:  "    
		MOV		EAX, score									; Displays all info on bottom of screen
		CALL	WriteInt									; This is all pretty self explanatory

		mGotoxy 18, 0
		mWrite	"Name: "
		mWriteString OFFSET playerName   

		RET
DrawHUD ENDP





DrawTitleScreen PROC										; Writes the title screen stuff, nothing special
		CALL	ClrScr
		CALL	PrintWalls
		
		mGotoxy 15, 4										; Draw ASCII Title
		mWrite	"  ___                 _            __   __      _  "	
		mGotoxy 15, 5
		mWrite	" / __|  _ _    __ _  | |__  ___    \ \ / /     / | "
		mGotoxy 15, 6
		mWrite	" \__ \ | ' \  / _` | | / / / -_)    \ V /   _  | | "
		mGotoxy 15, 7
		mWrite	" |___/ |_||_| \__,_| |_\_\ \___|     \_/   (_) |_| "
					
		mGotoxy 30, 12										; Pretty self explanatory
		mWrite	"Barrett Otte 2016"
		mGotoxy 32, 14
		mWrite	"Assembly(x86)"
		mGotoxy 30, 16
		mWrite	"MASM and Irvine32"
		mGotoxy 25, 20

		CALL	WaitMsg
		mGotoxy 0, 0  
	   
		RET
DrawTitleScreen ENDP





DrawMainMenu PROC											; Game settings initializing for speed

		CALL	ClrScr
		CALL	PrintWalls

		mGotoxy 30, 5										; Main Menu display and name prompt
		mWrite	"--MAIN MENU--"
		mGotoxy 30, 7
		mWrite	"Enter Name: "
		mReadString playerName								; Get player name
		mGotoxy 30, 10
		mWrite	"--DIFFICULTY--"							; Difficulty Prompt
		mGotoxy 30, 12  
		mWrite	"0) Easy"						
		mGotoxy 30, 13 
		mWrite	"1) Normal"
		mGotoxy 30, 14 
		mWrite	"2) Hard"
		mGotoxy 30, 15 
		mWrite	"Selection: "

		CALL	ReadChar    
		MOV		choice, AL									; Get difficulty choice
		CALL	WriteChar
															; Pretty much a switch(choice)
		CMP		choice, '0'									; case: '0'
		JNE		X00											; IF it was not '0' check other cases
		MOV		speed, 100									; IF it was, set speed to 100
		JMP		X02											; Jump to logic at bottom

	X00:
		CMP		choice, '1'									; Same as above case
		JNE		X01
		MOV		speed, 75
		JMP		X02

	X01:
		CMP		choice, '2'									; Same as above case
		JNE		X02
		MOV		speed, 50
		JMP		X02

	X02:
		INVOKE	Sleep, 100
		mGotoxy 0, 0										; Reset cursor, clear screen
		CALL	ClrScr										; Exit main menu

		RET
DrawMainMenu ENDP





DrawGameOver PROC											; Draw game over screen with score
		CALL	Clrscr
		CALL	PrintWalls
		mGotoxy 30, 7									
		mWrite	"--GAME OVER--"
		mGotoxy 30, 9  
		mWrite	"Final Score:"
		mGotoxy 42, 9

		MOV		EAX, score									; Reset screen and display score
		CALL	WriteInt
		INVOKE	Sleep, 100
															
		mGotoxy	25,20
		
		RET													
DrawGameOver ENDP





ResetData PROC												; Self explanatory, reset back to initial game state
		MOV		currentX, 40
		MOV		currentY, 10 
		MOV		headIndex, 3
		MOV		tailIndex, 0
		MOV		score, 0
		INVOKE	SetDirection, 1,0,0,0

		RET
ResetData ENDP





GenerateFood PROC											; Put food on a random point
		CALL	Randomize									; Produce new random seed
													
															; Random X Coordinate
		CALL	Random32									; Return random (0 to FFFFFFFFh) in EAX	
		XOR		EDX, EDX									; Quickly clears EDX
		MOV		ECX, maxX - 1								
		DIV		ECX											; DIV EAX by ECX, then store EAX=Quotient, EDX=Remainder
		INC		DL											
		MOV		foodPoint.x, DL								; Store new Random X Coordinate for Food

		CALL	Random32									; Random Y Coordinate, same deal
		XOR		EDX, EDX
		MOV		ECX, maxY - 1
		DIV		ECX
		INC		DL
		MOV		foodPoint.y, DL
    
		mGotoxy foodPoint.x, foodPoint.y					; Move cursor to calculated random coordinate
		MOV		AL, foodChar								
		CALL	WriteChar									; Load and write food character to screen

		RET
GenerateFood ENDP





StartGame PROC												; Handles main game state logic and loop.
		CALL	DrawTitleScreen								; Load Title Screen
    
    X00:													; Initial start game
		CALL	DrawMainMenu									

    X01:													; ReInitialize game
		CALL	ClrScr										
		CALL	GenerateFood
		CALL	PrintWalls
   
    X02:													; Main Game Loop
        CALL	Grow										; Did I "collide" with food?
        CALL	KeySync										; Did I press any keys?

	X03:
		CALL	IsCollision									; Is the game over?
		CMP		EAX, 1										
		JNE		X04											; IF the game is not over
		JMP		X05											; IF game is over, display game over menu

	X04:      
        CALL	MoveSnake									; IF game is not over, continue playing
        CALL	DrawHUD
        INC		score
		JMP		X02											; Loop back to main game loop
   
    X05:													; Game Over screen
        INVOKE	Sleep, 100
        CALL	DrawGameOver																												
		INVOKE	ExitProcess, 0

		RET
StartGame ENDP



	

END main