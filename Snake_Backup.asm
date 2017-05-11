TITLE Snake V1							(main.asm)
; Barrett Otte
; Snake MASM x86
;
; This project is meant to get myself back into assembly programming so I can
;		learn more complicated topics in cyber security.
; I chose to pick a game of Snake because it was complicated and gave me something
;		challenging to try to complete.


; Reading:
;		Irvine32 Documentation: http://programming.msjc.edu/asm/help/index.html?page=source%2Fabout.htm
;		GetKeyState: https://msdn.microsoft.com/en-us/library/windows/desktop/ms646301(v=vs.85).aspx
;		Instruction Set Reference: http://www.felixcloutier.com/x86/
;		ASCII Art Generator: http://patorjk.com/software/taag/


; TO DO:
;	- Snake's color can be changed
;	- Log highscore to text file
;	- food is a random character
;	- sound?
;	- Collision with self ends game (lea? Buffer?
;	- Switch conditionals to Loops and jumps
;
; Features:
;	- Basic controls with arrow keys
;	- Main menu, pause menu, and game over menu
;	- Speed of snake can be chosen (difficulty)
;	- Score tracking 
;	- Player name input
;	- When "colliding" with food, the snake grows by 1 character.
;	- Uses Irvine32 and user32.lib





; Files:
INCLUDE Irvine32.inc								; GoToXY, Random32, Randomize
INCLUDELIB user32.lib								; GetKeyState





; Macros:
mGotoxy MACRO X:REQ, Y:REQ							; Reposition cursor to x,y position
	PUSH EDX
	MOV DH, Y
	MOV DL, X
	CALL Gotoxy
	POP EDX
ENDM


mWrite MACRO text:REQ								; Write string literals.
	LOCAL string
	.data
		string BYTE text, 0
	.code
		PUSH EDX
		MOV EDX, OFFSET string
		CALL WriteString
		POP EDX
ENDM


mWriteString MACRO buffer:REQ						; Write string variables
	PUSH EDX
	MOV EDX, OFFSET buffer
	CALL WriteString
	POP EDX
ENDM


mReadString MACRO var:REQ							; Read string from console
	PUSH ECX
	PUSH EDX
	MOV EDX, OFFSET var
	MOV ECX, SIZEOF var
	CALL ReadString
	POP EDX
	POP ECX
ENDM





; Structs:
AXIS STRUCT 
    x BYTE 0
    y BYTE 0
AXIS ENDS



;KeyCodes:
	VK_LEFT		  EQU		000000025h
	VK_UP		  EQU		000000026h
	VK_RIGHT	  EQU		000000027h
	VK_DOWN		  EQU		000000028h
	VK_ESCAPE     EQU		00000001bh


;Game "Window" Setup:
	maxX		  EQU       79
	maxY		  EQU       48
	wallHor       EQU       "--------------------------------------------------------------------------------"
	wallVert      EQU       '|'
	maxSize		  EQU       255
													; Change this to an array or macro soon...
	titleChunk0	  EQU	"  ___                 _            __   __      _  "
	titleChunk1	  EQU	" / __|  _ _    __ _  | |__  ___    \ \ / /     / | "
	titleChunk2   EQU   " \__ \ | ' \  / _` | | / / / -_)    \ V /   _  | | "
	titleChunk3   EQU	" |___/ |_||_| \__,_| |_\_\ \___|     \_/   (_) |_| "


GetKeyState PROTO, nVirtKey:DWORD





.data


	foodPoint	 AXIS    <0,0>
	SnakeBody    AXIS    maxSize DUP(<0,0>)
    
    score        DWORD   0
	speed		 DWORD   60

	foodChar     BYTE   '0'
	snakeChar	 BYTE	'#'
    playerName   BYTE    13 + 1 DUP (?)
    currentX	 BYTE    40							; spawn point x
    currentY	 BYTE    10							; spawn point y
    choice       BYTE    0							;
    headIndex    BYTE    3   
    tailIndex    BYTE    0 
    LEFT         BYTE    0
    RIGHT        BYTE    1							; Initialize with snake moving right.
    UP           BYTE    0
    DOWN         BYTE    0		
					




.code


main PROC
	CALL StartGame
	RET
main ENDP





SetDirection PROC, R:BYTE, L:BYTE, U:BYTE, D:BYTE	; Values set in KeySync, either 0 or 1
    MOV DL, R										
    MOV RIGHT, DL
    
    MOV DL, L
    MOV LEFT, DL									; Set Direction Bytes appropriately
    
    MOV DL, U
    MOV UP, DL
    
    MOV DL, D
    MOV DOWN, DL
    RET
SetDirection ENDP





KeySync PROC

    MOV AH, 0
    INVOKE GetKeyState, VK_ESCAPE
	;.IF AH											
        MOV EAX, -1									; Triggers Game Pause
        RET
  	;.ENDIF
    
    MOV AH, 0
    INVOKE GetKeyState, VK_DOWN
	.IF AH && currentY < maxY						; Make sure we are within bounds
        INC currentY								; If the high bit is 1, the key is down
        INVOKE SetDirection, 0, 0, 0, 1				; Otherwise it is up
        RET
  	.ENDIF

    MOV AH, 0
	INVOKE GetKeyState, VK_UP
    .IF AH && currentY > 0
        DEC currentY
        INVOKE SetDirection, 0, 0, 1, 0
        RET
    .ENDIF     

    MOV AH, 0
	INVOKE GetKeyState, VK_LEFT
    .IF AH && currentX > 0
        DEC currentX
        INVOKE SetDirection, 0, 1, 0, 0
        RET
    .ENDIF  

    MOV AH, 0
	INVOKE GetKeyState, VK_RIGHT
    .IF AH && currentX < maxX
        INC currentX
        INVOKE SetDirection, 1, 0, 0, 0
        RET
    .ENDIF     
    
    .IF RIGHT && currentX < maxX
        INC currentX
    .ELSEIF LEFT && currentX > 0
        DEC currentX
    .ELSEIF UP && currentY > 0
        DEC currentY
    .ELSEIF DOWN && currentY < maxY
        INC currentY
    .ENDIF
    
    RET
KeySync ENDP





EatAndGrow PROC
    MOV AH, currentX								; Move for check
    MOV AL, currentY

    .IF AH == foodPoint.x && AL == foodPoint.y		; If we are at the location of the food
        CALL GenerateFood							; Make a new food object
        INC headIndex								; Grow    
        ADD score, 10								; Increment score
    .ENDIF
    
    RET
EatAndGrow ENDP





PrintWall PROC
    mGotoxy 0, 0     
    mWrite wallHor
    mGotoxy 0, maxY									; Top and bottom walls are pretty easy
    mWrite wallHor    

    MOV CL, maxY - 1 

    .while CL
        mGotoxy 0, CL								; Write left wall piece
        mWrite wallVert								
        mGotoxy maxX, CL
        mWrite wallVert								; Write right wall piece
        DEC CL										; travel up the screen until all are placed
    .endw

    RET
PrintWall ENDP





isGameOver PROC										; Did we "collide" with anything?
    .IF currentX == 0 || currentY == 0 || currentX == maxX || currentY == maxY
        MOV EAX, 1
        RET
    .ENDIF
    MOV EAX, 0 

    RET
isGameOver ENDP





printSnake2 PROC
    MOV ECX, 0
    MOV CL, headIndex								; Head position in array
    
    MOV AL, currentX
    MOV AH, currentY								; Load current x and y pos 

    MOV SnakeBody[2 * ECX].x, AL					; load snake body to new x/y positions
    MOV SnakeBody[2 * ECX].y, AH					
													; Move snake body to new position
													; Collision with self logic here!!!

    mGotoxy SnakeBody[2 * ECX].x, SnakeBody[2 * ECX].y
    MOV AL, snakeChar								
    CALL WriteChar										
    
    INVOKE Sleep, speed
      
    MOV ECX, 0  
    MOV CL, tailIndex
    .IF SnakeBody[2 * ECX].x != 0
        mGotoxy SnakeBody[2 * ECX].x, SnakeBody[2 * ECX].y
        mWrite " " 
    .ENDIF
    
    INC tailIndex
    INC headIndex
    
    .IF tailIndex == maxSize						; Reposition head and tail appropriately
        MOV tailIndex, 0
    .ENDIF

    .IF headIndex == maxSize
        MOV headIndex, 0
    .ENDIF

    RET
printSnake2 ENDP





printInfo PROC

    mGotoxy 2, maxY + 1								; Display "HUD" information
    mWrite "Score:  "    
    MOV  EAX, score
    CALL WriteInt

    mGotoxy 17, maxY + 1
    mWrite "Name: "
    mWriteString OFFSET playerName
    
    mGotoxy 37, maxY + 1    
    mWrite "Speed: "
    MOV  EAX, speed
    CALL WriteInt

    mGotoxy 57, maxY + 1
    mWrite "PRESS [ESC] TO PAUSE"
    mGotoxy 0, 0     

    RET
printInfo ENDP





front PROC											; Writes the title screen stuff, nothing special
    CALL ClrScr
    CALL PrintWall

    mGotoxy 15, 2									; Either make this into an array or a macro
    mWrite titleChunk0	
	mGotoxy 15, 3
	mWrite titleChunk1
	mGotoxy 15, 4
	mWrite titleChunk2
	mGotoxy 15, 5
	mWrite titleChunk3	
									
    mGotoxy 30, 10
    mWrite "Barrett Otte 2016"
	mGotoxy 32, 12
	mWrite "Assembly(x86)"
	mGotoxy 30, 14
	mWrite "MASM and Irvine32"
    mGotoxy 25, 30

    CALL WaitMsg
    mGotoxy 0, 0  
	   
    RET
front ENDP





mainMenu PROC										; Game settings initializing for speed

    CALL ClrScr
    CALL PrintWall

    mGotoxy 30, 5									; Main Menu display and name prompt
    mWrite "--MAIN MENU--"
    mGotoxy 30, 7
    mWrite "Enter Name: "
    mReadString playerName
    mGotoxy 30, 10
    mWrite "--DIFFICULTY--"
    mGotoxy 30, 12  
    mWrite "1) Beginner   -----> 0"						
    mGotoxy 30, 13 
    mWrite "2) Normal     -----> 1"
    mGotoxy 30, 14 
    mWrite "3) Hard	    -----> 2"
    mGotoxy 30, 15 
    mWrite "4) Nightmare  -----> 3"					; Change speed dependent on keypress
    mGotoxy 30, 16 
    mWrite "Selection: "

    CALL ReadChar    
    MOV  choice, AL 
    CALL WriteChar

    .IF choice == '0'								
        MOV speed, 100 
    .ELSEIF choice == '1'
        MOV speed, 75 
    .ELSEIF choice == '2'
        MOV speed, 50 
    .ELSEIF choice == '3'
        MOV speed, 25 
	.ELSE
		CALL mainMenu
    .ENDIF

    INVOKE Sleep, 100
    mGotoxy 0, 0									; Reset cursor, clear screen
    CALL ClrScr

    RET
mainMenu ENDP





pausedView PROC
    CALL ClrScr
    CALL PrintWall

    mGotoxy 30, 7									; Display Pause Menu
    mWrite "--PAUSED--"
    mGotoxy 30, 9  
    mWrite "1) Resume    -----> 0"
    mGotoxy 30, 10  
    mWrite "2) Restart   -----> 1"
    mGotoxy 30, 11 
    mWrite "3) Main Menu -----> 2"
    mGotoxy 30, 12 
    mWrite "4) Exit      -----> 3"
    mGotoxy 30, 14 
    mWrite "Selection: "

    CALL ReadChar
    MOV choice, AL  
    CALL WriteChar
    INVOKE Sleep, 100
    
    .IF choice == '0'								; Get Choice
        MOV EAX, 0
    .ELSEIF choice == '1'
        MOV EAX, 1
    .ELSEIF choice == '2'
        MOV EAX, 2
    .ELSEIF choice == '3'
        MOV EAX, 3
	.ELSE
		CALL pausedView
    .ENDIF

    mGotoxy 0,0  
	    
    RET
pausedView ENDP





gameOverView PROC   
    CALL Clrscr
    CALL PrintWall
    mGotoxy 30, 7									
    mWrite "--GAME OVER--"
    mGotoxy 30, 9  
    mWrite "Final Score:"
	mGotoxy 45, 10

    MOV EAX, score									; Reset screen and display score
    CALL WriteInt

    mGotoxy 27, 13 
    mWrite "1) Restart   -----> 0"					; Display basic menu
    mGotoxy 27, 14
    mWrite "2) Main Menu -----> 1"
    mGotoxy 27, 15 
    mWrite "3) Exit      -----> 2"
    mGotoxy 27, 17 
    mWrite "Selection: "
    
    MOV EAX, 0  
    CALL ReadChar
    MOV  choice, AL									; Make a choice
    CALL WriteChar
    INVOKE Sleep, 100
        
    .IF choice == '0'
        MOV EAX, 0    
    .ELSEIF choice == '1'
        MOV EAX, 1
    .ELSEIF choice == '2'
        MOV EAX, 2
	.ELSE
		CALL gameOverView
    .ENDIF
        
    mGotoxy 0,0  
	   
    RET 
gameOverView ENDP





ResetData PROC										; Self explanatory, reset back to initial game state
    MOV currentX, 40
    MOV currentY, 10 
    MOV headIndex, 3
    MOV tailIndex, 0
    MOV score, 0
    INVOKE SetDirection, 1,0,0,0

    RET
ResetData ENDP





GenerateFood PROC
    CALL Randomize									; Produce new random seed
													
													; Random X Coordinate
    CALL Random32									; Return random (0 to FFFFFFFFh) in EAX	
    XOR EDX, EDX									; Quickly clears EDX
    MOV ECX, maxX - 1								
    DIV ECX											; DIV EAX by ECX, then store EAX=Quotient, EDX=Remainder
    INC DL											
    MOV foodPoint.x, DL								; Store new Random X Coordinate for Food

    CALL Random32									; Random Y Coordinate, same deal
    XOR EDX,EDX
    MOV ECX, maxY - 1
    DIV ECX
    INC DL
    MOV foodPoint.y, DL
    
    mGotoxy foodPoint.x, foodPoint.y				; Move cursor to calculated random coordinate
    MOV AL, foodChar								
    CALL WriteChar									; Load and write food character to screen

    RET
GenerateFood ENDP





StartGame PROC										; Handles main game state logic and loop.
    CALL front										; Load Title Screen
    
    StartFromMenu:
		CALL mainMenu
    
    Restart:
		CALL ClrScr									; ReInitialize game
		CALL GenerateFood
		CALL PrintWall
   
    foreverLoop:									; Main Game Loop
        CALL EatAndGrow								; Did I "collide" with food
        CALL KeySync

        .IF EAX == -1								; Was escape pressed?
            JMP GamePaused
        .ENDIF

        CALL isGameOver
        .IF EAX == 1								; Did I "collide" with anything harmful?
            JMP GameOver
        .ENDIF
        
        CALL printSnake2  
        CALL printInfo
        INC score
		JMP foreverLoop
   

    GamePaused:
        INVOKE Sleep, 100
        CALL pausedView
        MOV choice, AL

        .IF choice == 0								; Resume the game
            JMP Restart
        .ELSEIF choice == 1							; Restart the game
            CALL ResetData
            JMP Restart
        .ELSEIF choice == 2							; Return to Main Menu
            CALL ResetData
            JMP StartFromMenu
        .ELSE										; Exit Game
            CALL ClrScr
            INVOKE ExitProcess, 0
        .ENDIF

        JMP foreverLoop
   

    GameOver:
        INVOKE Sleep, 100
        CALL gameOverView 
        MOV choice, AL					            ; if we dont store value in memory .IF will change EAX while processing

        .IF choice == 0								; Restart the game
            CALL ResetData
            CALL Restart
            RET
        .ELSEIF choice == 1							; Return to Main Menu
            CALL ResetData
            JMP StartFromMenu
        .ELSE										; Exit Game
            CALL ClrScr
            INVOKE ExitProcess, 0
        .ENDIF

        JMP foreverLoop

	RET
StartGame ENDP


	

END main