.data # text makes sure that you tell spim where your instructions
    prompt: .asciiz "Enter a non-negative integer: "
    newline: .asciiz "\n"

.text

main:
# allocates space in stack for 2 registers and their values
    addi $sp, $sp, -8 # allocates space for 2 registers in the stack
    # subtracts 8 from stack pointer to do so
    sw $ra, 0($sp) # stores the return address ($ra) at the address in $sp
    sw $s0, 4($sp) # stores the value in $s0 at the address $sp + 4

    # print prompt
    li $v0, 4
    la $a0, prompt
    syscall

    # read integer
    li $v0, 5
    syscall
    move $s0, $v0 # store input in $s0

    # call recursion
    move $a0, $s0 # store the input in argument register
    jal recursion # jump to recursion
    # move $s0, $v0 # store the result in $s0

    # print result
    move $a0, $v0 # move $a0, $s0
    li $v0, 1
    syscall

    # print new line
    li $v0, 4
    la $a0, newline
    syscall

_end_main:
    # collapse memory
    li $v0, 0 # loads 0 into $v0 as the return value of main
    lw $ra, 0($sp)
    lw $s0, 4($sp)
    addi $sp, $sp, 8 # adds 8 to $sp to deallocate the stack space
    jr $ra

recursion:
    addi $sp, $sp, -12 # decrements the stack pointer by 8 bytes
    sw $ra, 0($sp) # stores value of the return address register at the memory location pointed to by the current stack pointer 
    sw $s0, 4($sp) # stores the value of register $s0 at the memory location that is 4 bytes above the current stack pointer ($sp)
    sw $s1, 8($sp) # allocate another register

    # store argument v in $s0
    move $s0, $a0 

    # check for base case, ie check if v == 0
    beqz $s0, base_case # if $s0 (v) is zero, then go to base_case

    # recursive case
    # calculate 2 * (v + 1)
    addi $t0, $s0, 1 # increment $s0 and store in temperary register $t0
    sll $s1, $t0, 1  # multiplies by 2 by adding the value in $t0 to itself

    # $s1 contains 2(v+1)

    # recursive call for recursion(v-1)
    addi $a0, $s0, -1 # decrement $s0 by 1 and store in $a0

    # $a0 contains (v-1) 
    jal recursion # calls recursion and store in $ra

    move $t1, $v0 # return value from recursive call $v0 is moved to $t1
    sll $t2, $t1, 1 # t2 = 2 * recursion(v-1)
    add $t1, $t1, $t2 # t1 = 3 * recursion(v-1)

    # add 2*(v+1) + 3*recursion(v-1) - 17
    add $v0, $s1, $t1 # $v0 = 2*(v+1) + 3*recursion(v-1)
    addi $v0, $v0, -17 # subtract 17
    
    j recurse_end

base_case: # base case, aka if $s0 (v) is zero
    li $v0, 2 # save 2 to the destination register of $v0
    j recurse_end

recurse_end: # increment the stack, restore everything
    lw $ra, 0($sp) 
    lw $s0, 4($sp) 
    lw $s1, 8($sp)
    addi $sp, $sp, 12
    jr $ra