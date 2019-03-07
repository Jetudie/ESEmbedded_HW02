.syntax unified

.word 0x20000100
.word _start

.global _start
.type _start, %function
_start:
	//
	// initialize data in r0-r7
	//
	movs	r0, 	#10
	movs	r1, 	#11
	movs	r2, 	#12
	movs	r3, 	#13
	movs	r4, 	#14
	movs	r5, 	#15
	movs	r6, 	#16
	movs	r7, 	#17

	//
	// push and pop
	//
	push	{r0, r1, r2, r3}

	movs	r0, 	#20
	movs	r1, 	#21
	movs	r2, 	#22
	movs	r3, 	#23
	
	push	{r3, r1, r0, r2}
	
	pop		{r4, r5, r6, r7}
	pop		{r6, r5, r7, r4}

	b		sleep

sleep:
	nop
	b	.
