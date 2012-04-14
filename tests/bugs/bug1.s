	.file	"bug1.ll"
	.text
	.globl	func
	.align	2
	.type	func,@function
func:                                   ; @func
; BB#0:
	push 	r28
	push 	r29
	in 	r28, 0x3D
	in 	r29, 0x3E
	ldi	r24, 1
	pop 	r29
	pop 	r28
	ret
.Ltmp0:
	.size	func, .Ltmp0-func

	.globl	main
	.align	2
	.type	main,@function
main:                                   ; @main
; BB#0:
	push 	r28
	push 	r29
	in 	r28, 0x3D
	in 	r29, 0x3E
	in 	r30, 0x3D
	sbci 	r30, 2
	out 	0x3D, r30
	mov 	r0, r24
	std	y+1, r0
	mov 	r24, r0
	call	func
	out 	0x3E, r24
	in 	r24, 0x3E
	add 	r24, r0
	pop 	r29
	pop 	r28
	ret
.Ltmp1:
	.size	main, .Ltmp1-main


