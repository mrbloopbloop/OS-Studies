org 0x7C00
bits 16

%define ENDL 0X0D, 0X0A

jmp short start
nop



; --------------------------------------------------------------
; FAT12 header
; --------------------------------------------------------------

bdb_oem:						db 'MSWIN4.1'					; 8 Bytes long
bdb_bytes_per_sector:			dw 0x0200						; 512 Bytes
bdb_sectors_per_cluster:		db 0x01							; 1
bdb_reserved_sectors:			dw 0x0001						; 1
bdb_fat_count:					db 0x02							; 2
bdb_dir_entries_count:			dw 0xE0							; 244
bdb_total_sectors:				dw 0x0B40						; 2880
bdb_media_descriptor_type:		db 0x0F0						; 0xF0 = 3.5" floppy disk
bdb_sectors_per_fat:			dw 0x0009						; 9 sectors/fat
bdb_sectors_per_track:			dw 0x0012						; 18 sectors/track
bdb_heads:						dw 0x0002						; 2
bdb_hidensectors:				dd 0x00000000					; 0
bdb_large_sector_count:			dd 0x00000000					; 0

; extended boot record
ebr_drive_number:				db 0x00							; 0x00 floppy, 0x80 hdd
win_NT_flags:					db 0x00							; reserved
ebr_signature:					db 0x29
ebr_volume_id:					db 0x01, 0x24, 0x19, 0x96		; Serial number
ebr_volume_label:				db 'OS Studies '				; 11 bytes long, space padded
ebr_system_id:					db 'FAT12   '					; 8 bytes long, space padded



; --------------------------------------------------------------
; Code begin
; --------------------------------------------------------------

start:
	jmp 	main



; --------------------------------------------------------------
; Prints a string to the screen.
; Params:
;	- DS:SI points to string
; --------------------------------------------------------------
puts:
	push 	SI													; Push registers to the stack.
	push 	AX

.loop:
	lodsb														; Load string int AL register.
	or 		AL, AL												; Check for zero value.
	jz 		.done												; If zero, jump to done.
	
	mov 	AH, 0x0E											; Display char
	int 	0x10												; Video Services Interupt 10.0E
	
	jmp 	.loop

.done:
	pop 	AX													; Pop registers from stack.
	pop 	SI
	ret



; --------------------------------------------------------------
; Main Execution
; --------------------------------------------------------------
main:
	; setup data segments
	mov 	AX, 0x00											; Cannot set DS and ES directly
	mov 	DS, AX												;
	mov 	ES, AX												;

	; setup stack
	mov 	SS, AX
	mov 	SP, 0x7C00											; Stack grows downwards from
																; where we are loaded in memory.

	; read something from floppy disk
    ; BIOS should set DL to drive number
    mov 	[ebr_drive_number], DL

    mov 	AX, 1                                               ; LBA=1, second sector from disk
    mov 	CL, 1                                               ; 1 sector to read
    mov 	BX, 0x7E00                                          ; data should be after the bootloader
    call 	disk_read
	
	; print message
	mov 	SI, msg_hello
	call 	puts
	cli															; Disable interrupts to aid halting.

.halt:
	hlt
	jmp 	.halt



; --------------------------------------------------------------
; Error handlers
; --------------------------------------------------------------

floppy_error:
    mov 	SI, msg_read_failed
    call 	puts
    jmp 	wait_key_and_reboot

wait_key_and_reboot:
    mov 	AH, 0x00
    int 	0x16                    							; wait for keypress
    jmp 	0FFFFh:0                							; jump to beginning of BIOS, should reboot

.halt:
    cli                         								; disable interrupts, this way CPU can't get out of "halt" state
    hlt



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


; --------------------------------------------------------------
; Constants
; --------------------------------------------------------------

msg_hello: 						db 'Hello world!', ENDL, 0
msg_read_failed:        		db 'Read from disk failed!', ENDL, 0



; --------------------------------------------------------------
; Boot Signature
; --------------------------------------------------------------

times 510 - ($-$$) db 0x00
dw 0xAA55