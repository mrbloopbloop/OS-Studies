; --------------------------------------------------------------
; Print Hex Value
; --------------------------------------------------------------

; --------------------------------------------------------------
; Prints value in AX as hexidecimal value.
; Params:
;   - AX
; --------------------------------------------------------------

print_hex:
    pusha
    mov     CX, 0x0000                                          ; Initialize CX as incrementor
    mov     DX, AX                                              ; Move AX to DX to preserve data
.placeholder_str:               db '0x0000', ENDL, 0x00         ; Create template for output
.loop:
    mov     AX, DX                                              ; Move DL to AL
    cmp     CX, 0x0004                                          ; Check to see if we have read 16 bits.
    je      .endloop                                            ; Jump to the end of the loop if we have.
    and     AX, 0x000F                                          ; Isolate last 4 bits.
    add     AX, 0x0030                                          ; Add 30 to AX
    cmp     AX, 0x0039                                          ; Compare the AX to 39
    jle     .place_char                                         ; Place char if value was less than or equal to 9
    add     AX, 0x0007                                          ; Add 7 more to AX if value was more than 9

.place_char:
    mov     BX, .placeholder_str                                ; Move address of template to BX
    add     BX, 5                                               ; Add 5 to BX
    sub     BX, CX                                              ; Subtract the current count in CX from BX
    mov     [BX], AL                                            ; Dereference the address in BX and store AL there
    ror     DX, 4                                               ; Shift bits 4 to the right

    add     CX, 1                                               ; Increment counter
    jmp     .loop                                               ; Jump to the begining of the loop

.endloop:
    mov     SI, .placeholder_str                                ; Place address to result in SI
    call    puts                                                ; Print result

    popa                                                        ; Restore registers
    ret                                                         ; Return