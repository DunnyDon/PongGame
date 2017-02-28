;Conor Donohue, Senan Carrol, Paul Meaney
;R0 -> PADDLE
;R2 -> 16d -> Mem address for paddle
;R3 -> WALL
;R4 -> 28d -> WALL
;R5 -> Ball_x
;R6 -> Ball_y
;R7 -> Ball direction 
;Bit(2), Low-> Left. 
;Bit(2), High -> Right
;Bit(0), Low -> Down.
;Bit(0), High -> Up
;Bit(1), Straight Up/Down 
;28d -> Mem address for wall
;If R2 and R4 and changed then 16d and 28d must be reloaded into them before
;updating memory

;Spare Registers for calculations: R1, (R2 and R4 can be used if needs be)

main: CALL 15
CALL 35
END	               	; end main program

setupTimer1Sec: ORG 15
INV R5, R5	; 0000h -> FFFFh
SHRL R5, 4	; FFFFh -> 0FFFh
ROTR R5, 1	; 0FFFh -> 87FFh
CLRBR R5, 6	; 87FFh -> 87BFh
INV R6, R6	; 0000h -> FFFFh
SHLL R6, 9	; FFFFh -> FE00h
INVBR R6, 1	; FE00h -> FE02h
SETBR R6, 7	; FE02h -> FE82h

MOVRSFR SFR7, R6 ;LOAD THRH_LDVAL
MOVRSFR SFR6, R5;LOAD TMRL_LDVAL 
MOVRSFR SFR2, R6 ;LOAD THRH
MOVRSFR SFR1, R5;LOAD TMRL
SETBSFR SFR0, 5     ; set timer auto reload
SETBSFR SFR0, 3     ;set timer interrupt enable
SETBSFR SFR0, 4     ; set enable timer
XOR R5,R5,R5
XOR R6,R6,R6
;THESE REGISTERS CAN BE RE-USED AND CLEARED AS SOON AS THIS FUNCTION IS FINISHED
RET

InitGame: ORG 35
XOR R0, R0, R0
XOR R2, R2, R2
XOR R3, R3, R3
XOR R1, R1, R1		; Clear all registers when a new
XOR R4, R4, R4		; game begins
XOR R5, R5, R5
XOR R6, R6, R6
XOR R7, R7, R7
INV R0, R0
SHLL R0,11 
SETBR R2, 4                       ; R2 = 16d (ADDRESS FOR MEM ACCESS)
INV R3, R3                        ; WALL FOR GAME
ADDI R4,R4,7		; MEM ADDRESS FOR WALL 
SHLL R4,2			; R4 = 28D
SETBR R5, 13 		; Create Ball
MOVRR R6,R2			; Set up memory slot for ball
ADDI R6,R6,1		; Old ball will be one above paddle
MOVBAMEM @R6,R1		; CLEAR ball FROM memory
MOVBAMEM @R2, R1		; CLEAR Paddle FROM memory
MOVBAMEM @R4, R1 		; CLEAR wall FROM memory
INC R6,R6			; Start the ball 2 above the paddle
SETBSFR SFR0, 1	    	; enable sw(0) interrupt
SETBSFR SFR0, 2	    	; enable sw(1) interrupt
SETBSFR SFR0, 0	    	; enable global interrupt

MOVBAMEM @R6,R5		; Push ball into memory
MOVBAMEM @R2, R0		; push Paddle into memory
MOVBAMEM @R4, R3 		; push wall into memory
SETBR R7,2
SETBR R7,0
RET
 

;shift paddle left
ORG 92                     	; ISR(0)  5Ch, 92d. ISR0 start address (switch(0) interrupt). Could use 5Ch
XOR R1, R1, R1		; clear reg
INC R1, R1                        ; set LSB
AND R1, R0, R1 		;see if paddle is at the wall 
JNZ R1, 2                    	; Compare paddle (R0) and side wall (R1(0))
SHRL R0, 1			;move paddle right
MOVBAMEM @R2, R0		;Update memory 
RETI

;shift paddle right
ORG 104                    	; ISR(1)  68h, 104d. ISR0 start address (switch(1) interrupt). Could use 68h
XOR R1, R1, R1                    ; clear reg
SETBR R1, 15                      ; set MSB
AND R1, R0, R1		;see if paddle is at the wall 
JNZ R1, 2                      	; Compare paddle (R0) and side wall (R1(15))
SHLL R0, 1			; move paddle left
MOVBAMEM @R2, R0
RETI

;1 sec interrupt
ORG 116                    	; Timer ISR 74h 116d. ISR2 start address (timer interrupt). Could use 74h     
CALL 420           
RETI       	                	; return from interrupt

BallHits_l_r_Wall: ORG 119
XOR R1, R1, R1                    ; clear reg
SETBR R1, 15                      ; set MSB
SETBR R1,0
AND R1, R5, R1		;see if BALL is at the wall 
JZ R1, 2                      	; Compare BALL (R0) and side wall (R1(15))
INVBR R7, 2			; move BALL left
RET

BallHitsTopWall: ORG 150
XOR R1, R1, R1                    ; clear reg
SUB R1, R4, R6		;R4 y co-ordinate of wall, R6 y co-ordinate                      
DEC R1, R1
JNZ R1, 6                      	;If not Zero the R6 < R4
INVBR R7, 0
XOR R1,R1,R1		;Clear r1
INV R1,R5			
AND R3,R3,R1		; IF ball hits the wall the wall piece will disappear
MOVBAMEM @R4, R3 		; push wall into memory
RET

ballOnPaddle: ORG 200
XOR R2, R2, R2
SETBR R2, 4
SUB R1, R6, R2
DEC R1, R1
JNZ R1, return 		; IF BALL IN LINE WITH PADDLE

INVBR R7, 0                     	; PADDLE HIT, TOGGLE UP/DOWN
SETBR R7, 1                  	; GO STRAIGHT UP/DOWN

AND R1, R0, R5                   	; IF BALL IN CONTACT WITH PADDLE
JZ R1, InitGame        	; looser

XOR R1, R1, R1
XOR R2, R2, R2

loop: SHLL R5, 1  		; WHERE ON PADDLE ARE WE
INC R1, R1
AND R2, R5, R0
JNZ R2, loop

INC R2, R2
SUB R2, R1, R2
JZ R2, invbitsLR
XOR R2, R2, R2
ADDI R2, R2, 5
SUB R2, R2, R1
JZ R2, invbitsLR

loop1: SHRL R5, 1
DEC R1, R1
JNZ R1, loop1

return: RET

invbitsLR: ORG 250
CLRBR R7, 1                  	; GOING AT AN ANGLE
INVBR R7, 2                    	; TOGGLE L/R DIRECTION
RET

;Move Ball
MoveBall: ORG 420            	; UP/DOWN
CALL 119                         	; LEFT RIGHT WALL
CALL 150                         	; TOP WALL
CALL 200                         	; BOTTOM WALL
XOR R1,R1,R1		; Clear Reg
MOVBAMEM @R6,R1		; Remove previous ball position
SETBR R1, 0                   	; set bit to check against R7(0) 
AND R1, R1, R7                 	; and, if 1 ball moving up
JNZ R1, 2                        	
DEC R6, R6                       	; move down
JZ R1, 2  		 	
INC R6, R6			; move up
                                 	; S
XOR R1, R1, R1
SETBR R1, 1
AND R1, R1, R7
JNZ R1, updateMem
                                  ; L/R
XOR R1, R1, R1
SETBR R1, 2
AND R1, R1, R7
JNZ R1, 2
SHLL R5, 1
JZ R1, 2
SHRL R5, 1
updateMem: MOVBAMEM @R6, R5         ; push to mem
RET

