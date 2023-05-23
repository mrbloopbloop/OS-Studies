org 0x7C00
bits 16

%define ENDL 0X0D, 0X0A



start:
	jmp main


;
; Prints a string to the screen.
; Params:
;	- ds:si points to string
;

puts:
	push si
	push ax

.loop:
	lodsb
	or al, al
	jz .done
	
	mov ah, 0x0E
	mov bh, 0x00
	int 0x10
	
	jmp .loop

.done:
	pop ax
	pop si
	ret


main:
	; setup data segments
	mov ax, 0x00
	mov ds, ax
	mov es, ax

	; setup stack
	mov ss, ax
	mov sp, 0x7C00
	
	; print message
	mov si, msg_hello
	call puts

	hlt

.halt:
	jmp .halt

msg_hello: db 'Hello world!', ENDL, 0

times 510 - ($-$$) db 0x00
dw 0xAA55
