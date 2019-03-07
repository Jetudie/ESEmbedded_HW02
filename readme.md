HW02
===
This is the hw02 sample. Please follow the steps below.

# Build the Sample Program

1. Fork this repo to your own github account.

2. Clone the repo that you just forked.

3. Under the hw02 dir, use:

	* `make` to build.

	* `make clean` to clean the ouput files.

4. Extract `gnu-mcu-eclipse-qemu.zip` into hw02 dir. Under the path of hw02, start emulation with `make qemu`.

	See [Lecture 02 ─ Emulation with QEMU] for more details.

5. The sample is designed to help you to distinguish the main difference between the `b` and the `bl` instructions.  

	See [ESEmbedded_HW02_Example] for knowing how to do the observation and how to use markdown for taking notes.

# Build Your Own Program

1. Edit main.s.

2. Make and run like the steps above.

# HW02 Requirements

1. Please modify main.s to observe the `push` and the `pop` instructions:  

	Does the order of the registers in the `push` and the `pop` instructions affect the excution results?  

	For example, will `push {r0, r1, r2}` and `push {r2, r0, r1}` act in the same way?  

	Which register will be pushed into the stack first?

2. You have to state how you designed the observation (code), and how you performed it.  

	Just like how [ESEmbedded_HW02_Example] did.

3. If there are any official data that define the rules, you can also use them as references.

4. Push your repo to your github. (Use .gitignore to exclude the output files like object files or executable files and the qemu bin folder)

[Lecture 02 ─ Emulation with QEMU]: http://www.nc.es.ncku.edu.tw/course/embedded/02/#Emulation-with-QEMU
[ESEmbedded_HW02_Example]: https://github.com/vwxyzjimmy/ESEmbedded_HW02_Example

--------------------

- [x] **If you volunteer to give the presentation next week, check this.**

--------------------

Please take your note here.


## Statement in the manual
+ According to [ARM Architecture Reference Manual Thumb-2 Supplement]
	+ 4.6.99 PUSH
	``` 
	The registers are stored in sequence, the lowest-numbered register to the lowest memory address, through to the highest-numbered register to the highest memory address.
	```
	+ 4.6.98 POP
    ```
    The registers are loaded in sequence, the lowest-numbered register from the lowest memory address, through to the highest-numbered register from the highest memory address
    ```
+ Hence, we expect the assmebly `push {r0, r1, r2}` and `push {r2, r0, r1}` will behave in the same way. The precedence is `r2` -> `r1` -> `r0`. The highest number will be pushed first.

[ARM Architecture Reference Manual Thumb-2 Supplement]: http://www.nc.es.ncku.edu.tw/course/embedded/pdf/Thumb2.pdf

## Design main.s
In this experiment, r0-r3 are used to push into stack twice and pop to r4-r7.
The following is the procedure:
+ step 1. Use `movs` to initialize values stored in r0-r7.
	```
	$r0 = 10,  $r1 = 11,  $r2 = 12,  $r3 = 13
	$r4 = 14,  $r5 = 15,  $r6 = 16,  $r7 = 17
	```
+ step 2. `push {r0, r1, r2, r3}`
	The stack is expected to get the same result as we push in the order of r3, r2, r1, r0:
	```
	0x200000fc: 13
	0x200000f8: 12
	0x200000f4: 11
	0x200000f0: 10 <-sp
	```
+ step 3. Use `movs` to store difference values in r0-r3.
	```
	$r0 = 20,  $r1 = 21,  $r2 = 22,  $r3 = 23
	```
+ step 4. `push {r3, r1, r0, r2}`, try it in a different order. \
	It's expected to behave exactly like `push {r0, r1, r2, r3}`, so the memory would look like this:
	```
	0x200000fc: 13
	0x200000f8: 12
	0x200000f4: 11
	0x200000f0: 10
	0x200000ec: 23
	0x200000e8: 22
	0x200000e4: 21
	0x200000e0: 20 <- sp
	```
+ step 5. `pop {r4, r5, r6, r7}`
	We expect to get this:
	```
	$r4 = 20,  $r5 = 21,  $r6 = 22,  $r7 = 23
	```
+ step 6. `pop {r6, r5, r7, r4}`
	The expected result:
	```
	$r4 = 10,  $r5 = 11,  $r6 = 12,  $r7 = 13
	```

## Observation
Compile and observe its behavior use gdb
1. `make` to build.
2. `make qemu` to start the qemu server
	And get the output warning message
	```
	main.s: Assembler messages:
	main.s:31: Warning: register range not in ascending order
	main.s:31: Warning: register range not in ascending order
	main.s:34: Warning: register range not in ascending order
	main.s:34: Warning: register range not in ascending order
	```
3. Check main.s, those are the lines that I designed to test the different order
	```
	...
	31: push	{r3, r1, r0, r2}
	...
	34: pop		{r6, r5, r7, r4}
	```
4. `arm-none-eabi-objdump -D main.elf` to see the disassembled info. \
	As expected, `push {r3, r1, r0, r2}` has been changed to `push {r0, r1, r2, r3}`\
	And `pop {r6, r5, r7, r4}` becomes `pop {r4, r5, r6, r7}`
5. Open another terminal, launch gdb `arm-none-eabi-gdb`
	Connect to qemu server `target remote 127.0.0.1:1234` \
	`layout regs` shows register and assembly
6. Set up tracks
```
// for registers
(gdb) display /d {$r0, $r1, $r2, $r3}
(gdb) display /d {$r4, $r5, $r6, $r7}
(gdb) display /z $sp
// $sp starts from 0x20000100, and 8 registers will be pushed to the stack
// so we are monitoring 0x200000e0 - 0x20000100
(gdb) display *0x200000e0@8
```
7. Observe the result of each step
+ step 1. after initializing r0-r7, the track the value looks like this
	```
	4: *0x200000e0@8 = {0, 0, 0, 0, 0, 0, 0, 0}
	3: /z $sp = 0x20000100
	2: /d {$r4, $r5, $r6, $r7} = {14, 15, 16, 17}
	1: /d {$r0, $r1, $r2, $r3} = {10, 11, 12, 13}
	```
+ step 2. after `push {r0, r1, r2, r3}` the value stored in `sp` changed and the register and the order is 
	```
	4: *0x200000e0@8 = {0, 0, 0, 0, 10, 11, 12, 13}
	3: /z $sp = 0x200000f0
	2: /d {$r4, $r5, $r6, $r7} = {14, 15, 16, 17}
	1: /d {$r0, $r1, $r2, $r3} = {10, 11, 12, 13}
	```
+ step 3-4. change the values of r0-r3 and `push {r3, r1, r0, r2}` \
	The order is `r3`->`r2`->`r1`->`r0`, just like `push {r0, r1, r2, r3}`
	```
	4: *0x200000e0@8 = {20, 21, 22, 23, 10, 11, 12, 13}
	3: /z $sp = 0x200000e0
	2: /d {$r4, $r5, $r6, $r7} = {14, 15, 16, 17}
	1: /d {$r0, $r1, $r2, $r3} = {20, 21, 22, 23}
	```
+ step 5. `pop {r4, r5, r6, r7}`
	The order is `r4`->`r5`->`r6`->`r7`
	```
	4: *0x200000e0@8 = {20, 21, 22, 23, 10, 11, 12, 13}
	3: /z $sp = 0x200000f0
	2: /d {$r4, $r5, $r6, $r7} = {20, 21, 22, 23}
	1: /d {$r0, $r1, $r2, $r3} = {20, 21, 22, 23}
	```
+ step 6. `pop {r6, r5, r7, r4}`
	The order is `r4`->`r5`->`r6`->`r7`, which is same as `pop {r4, r5, r6, r7}`
	```
	4: *0x200000e0@8 = {20, 21, 22, 23, 10, 11, 12, 13}
	3: /z $sp = 0x20000100
	2: /d {$r4, $r5, $r6, $r7} = {10, 11, 12, 13}
	1: /d {$r0, $r1, $r2, $r3} = {20, 21, 22, 23}
	```
