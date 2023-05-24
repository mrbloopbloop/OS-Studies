; --------------------------------------------------------------
; Disk Routines
; --------------------------------------------------------------

; --------------------------------------------------------------
; Converts an LBA address to a CHS address
; Parameters:
; 	- AX: LBA address
; Returns:
;	- CX [bits 0-5]: sector number
;	- CX [bits 6-15]: cylinder
;	- DH: head
; --------------------------------------------------------------
lba_to_chs:
	push	AX
	push	DX

	xor 	DX, DX												; DX = 0
	div 	word [bdb_sectors_per_track]						; AX = LBA / SectorsPerTrack
																; DX = LBA % SectorsPerTrack
	
	inc 	DX													; DX = (LBA % SectorsPerTrack + 1) = sector
	mov 	CX, DX												; CX = sector

	xor 	DX, DX												; DX = 0
	div 	word [bdb_heads]									; AX = (LBA / SectorsPerTrack) / Heads = cylinder
																; DX = (LBA / SectorsPerTrack) % Heads = head
	mov 	DH, DL 												; DH = head
	mov 	CH, AL												; CH = cylinder (lower 8 bits)
	shl 	AH, 6
	or 		CL, AH												; put uper 2 bits of cylinder in CL

	pop		AX
	mov		DL, AL												; Restore DL.
	pop		AX
	ret



; --------------------------------------------------------------
; Reads sectors from a disk
; Parameters:
;   - AX: LBA address
;   - CL: number of sectors to read (up to 128)
;   - DL: drive number
;   - ES:BX: memory address where to store read data
; --------------------------------------------------------------
disk_read:

    push 	AX                             						; save registers we will modify
    push 	BX
    push 	CX
    push 	DX
    push 	DI

    push 	CX                             						; temporarily save CL (number of sectors to read)
    call 	lba_to_chs                    					 	; compute CHS
    pop 	AX                              					; AL = number of sectors to read
    
    mov 	AH, 0x02
    mov 	DI, 3                           					; retry count

.retry:
    pusha                               						; save all registers, we don't know what bios modifies
    stc                                 						; set carry flag, some BIOS'es don't set it
    int 	0x13                             					; carry flag cleared = success
    jnc 	.done                           					; jump if carry not set

    ; read failed
    popa
    call disk_reset

    dec 	DI
    test 	DI, DI
    jnz 	.retry

.fail:
    ; all attempts are exhausted
    jmp 	floppy_error

.done:
    popa

    pop 	DI
    pop 	DX
    pop 	CX
    pop 	BX
    pop 	AX                             						; restore registers modified
    ret


; --------------------------------------------------------------
; Resets disk controller
; Parameters:
;	- DL: drive number
; --------------------------------------------------------------
disk_reset:
    pusha
    mov 	AH, 0x00
    stc
    int 	0x13
    jc 		floppy_error
    popa
    ret