; --------------------------------------------------------------
; Prints a string to the screen.
; Params:
;	- DS:SI points to string
; --------------------------------------------------------------
puts:
	push 	SI													; Push registers to the stack.
	push 	AX
	mov 	AH, 0x0E											; Display char

.loop:
	lodsb														; Load string int AL register.
	or 		AL, AL												; Check for zero value.
	jz 		.done												; If zero, jump to done.
	
	int 	0x10												; Video Services Interupt 10.0E	
	jmp 	.loop

.done:
	pop 	AX													; Pop registers from stack.
	pop 	SI
	ret