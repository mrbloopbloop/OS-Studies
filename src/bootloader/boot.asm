org 0x7C00
bits 16

%define ENDL 0X0D, 0X0A

jmp short start
nop



; --------------------------------------------------------------
; FAT12 header
; --------------------------------------------------------------

%include "src/bootloader/FAT12_HEADER.asm"



; --------------------------------------------------------------
; Code begin
; --------------------------------------------------------------

start:
	jmp 	main

; --------------------------------------------------------------
; Other functions
; --------------------------------------------------------------

%include "src/bootloader/puts.asm"                              ; puts function prints a string.
%include "src/bootloader/print_hex.asm"							; prints value in AX as a hex value.

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

    ; mov 	AX, 1                                               ; LBA=1, second sector from disk
    ; mov 	CL, 1                                               ; 1 sector to read
    ; mov 	BX, 0x7E00                                          ; data should be after the bootloader
    ; call 	disk_read
	
	; print message
	mov 	SI, msg_hello
	call 	puts
	push	AX
	mov 	AX, 0xFAB0
	call 	print_hex
	pop		AX
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

;%include "src/bootloader/disk_routines.asm"


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