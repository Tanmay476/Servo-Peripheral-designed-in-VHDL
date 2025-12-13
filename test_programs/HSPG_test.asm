; -------------------------------------------------------------
; Multi-Rate 4-Servo Demo – ECE 2031
; Servo0 updates every 0.2 s, Servo1 every 0.4 s,
; Servo2 every 0.6 s, Servo3 every 0.8 s.
; Each sweeps 0 -> MaxCodeVal -> 0 repeatedly.
; Uses 10 Hz Timer (0.1 s ticks).
; -------------------------------------------------------------

        ORG     0

Start:
        ; init positions = 0, directions = up(0)
        LOADI   0
        STORE   Pos0
        STORE   Pos1
        STORE   Pos2
        STORE   Pos3
        STORE   Dir0
        STORE   Dir1
        STORE   Dir2
        STORE   Dir3

        ; preload countdowns from period constants
        LOAD    P0PER
        STORE   Cnt0
        LOAD    P1PER
        STORE   Cnt1
        LOAD    P2PER
        STORE   Cnt2
        LOAD    P3PER
        STORE   Cnt3

MainLoop:
        ; wait one 0.1 s base tick
        OUT     Timer              ; reset timer to 0
WaitTick:
        IN      Timer
        JZERO   WaitTick           ; spin until >=1 (≈0.1 s elapsed)

        ; ----- service Servo0 -----
        LOAD    Cnt0
        ADDI    -1
        STORE   Cnt0
        JPOS    S0_Done            ; still counting
        CALL    Servo0_Step
        LOAD    P0PER
        STORE   Cnt0
S0_Done:

        ; ----- service Servo1 -----
        LOAD    Cnt1
        ADDI    -1
        STORE   Cnt1
        JPOS    S1_Done
        CALL    Servo1_Step
        LOAD    P1PER
        STORE   Cnt1
S1_Done:

        ; ----- service Servo2 -----
        LOAD    Cnt2
        ADDI    -1
        STORE   Cnt2
        JPOS    S2_Done
        CALL    Servo2_Step
        LOAD    P2PER
        STORE   Cnt2
S2_Done:

        ; ----- service Servo3 -----
        LOAD    Cnt3
        ADDI    -1
        STORE   Cnt3
        JPOS    S3_Done
        CALL    Servo3_Step
        LOAD    P3PER
        STORE   Cnt3
S3_Done:

        JUMP    MainLoop           ; repeat forever


; =============================================================
; Per-servo step subroutines
; DirX = 0 means count up, DirX != 0 means count down.
; When an endpoint is reached, clamp and flip direction.
; Position code sent directly to HSPG instance.
; =============================================================

Servo0_Step:
        LOAD    Dir0
        JZERO   S0_Up

S0_Down:
        LOAD    Pos0
        ADDI    -1
        STORE   Pos0
        JPOS    S0_Send            ; >0 still going down
        LOADI   0                  ; hit 0 or below
        STORE   Pos0
        LOADI   0
        STORE   Dir0               ; change direction to up
        JUMP    S0_Send

S0_Up:
        LOAD    Pos0
        ADDI    1
        STORE   Pos0
        LOAD    Pos0
        SUB     MaxCodeVal
        JPOS    S0_ClampTop        ; >Max -> clamp & flip
        JUMP    S0_Send
S0_ClampTop:
        LOAD    MaxCodeVal
        STORE   Pos0
        LOADI   1
        STORE   Dir0               ; now go down

S0_Send:
        LOAD    Pos0
        OUT     Servo0
        RETURN


Servo1_Step:
        LOAD    Dir1
        JZERO   S1_Up

S1_Down:
        LOAD    Pos1
        ADDI    -1
        STORE   Pos1
        JPOS    S1_Send
        LOADI   0
        STORE   Pos1
        LOADI   0
        STORE   Dir1
        JUMP    S1_Send

S1_Up:
        LOAD    Pos1
        ADDI    1
        STORE   Pos1
        LOAD    Pos1
        SUB     MaxCodeVal
        JPOS    S1_ClampTop
        JUMP    S1_Send
S1_ClampTop:
        LOAD    MaxCodeVal
        STORE   Pos1
        LOADI   1
        STORE   Dir1

S1_Send:
        LOAD    Pos1
        OUT     Servo1
        RETURN


Servo2_Step:
        LOAD    Dir2
        JZERO   S2_Up

S2_Down:
        LOAD    Pos2
        ADDI    -1
        STORE   Pos2
        JPOS    S2_Send
        LOADI   0
        STORE   Pos2
        LOADI   0
        STORE   Dir2
        JUMP    S2_Send

S2_Up:
        LOAD    Pos2
        ADDI    1
        STORE   Pos2
        LOAD    Pos2
        SUB     MaxCodeVal
        JPOS    S2_ClampTop
        JUMP    S2_Send
S2_ClampTop:
        LOAD    MaxCodeVal
        STORE   Pos2
        LOADI   1
        STORE   Dir2

S2_Send:
        LOAD    Pos2
        OUT     Servo2
        RETURN


Servo3_Step:
        LOAD    Dir3
        JZERO   S3_Up

S3_Down:
        LOAD    Pos3
        ADDI    -1
        STORE   Pos3
        JPOS    S3_Send
        LOADI   0
        STORE   Pos3
        LOADI   0
        STORE   Dir3
        JUMP    S3_Send

S3_Up:
        LOAD    Pos3
        ADDI    1
        STORE   Pos3
        LOAD    Pos3
        SUB     MaxCodeVal
        JPOS    S3_ClampTop
        JUMP    S3_Send
S3_ClampTop:
        LOAD    MaxCodeVal
        STORE   Pos3
        LOADI   1
        STORE   Dir3

S3_Send:
        LOAD    Pos3
        OUT     Servo3
        RETURN


; =============================================================
; Data / constants  (moved to safe address > code region)
; =============================================================
        ORG     &H100              ; <<< moved from &H30 to avoid overlap

Pos0        DW      0
Pos1        DW      0
Pos2        DW      0
Pos3        DW      0

Dir0        DW      0            ; 0=up, nonzero=down
Dir1        DW      0
Dir2        DW      0
Dir3        DW      0

Cnt0        DW      0            ; countdown (ticks) to next update
Cnt1        DW      0
Cnt2        DW      0
Cnt3        DW      0

; per-servo update periods in 0.1 s ticks
P0PER       DW      1           ; 0.1 s
P1PER       DW      4           ; 0.4 s
P2PER       DW      8           ; 0.8 s
P3PER       DW      10          ; 1.0 s

MaxCodeVal  DW      127          ; match HSPG 0–127 command range

; ---- I/O map ----
Switches    EQU     000
LEDs        EQU     001
Timer       EQU     002
Hex0        EQU     004
Servo0      EQU     &H50
Servo1      EQU     &H51
Servo2      EQU     &H52
Servo3      EQU     &H53
