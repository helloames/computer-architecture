.text

main:
    addi $sp, $sp, -4 # allocates space for 2 registers in the stack
    sw $ra, 0($sp) # stores the return address ($ra) at the address in $sp

    # print prompt
    li $v0, 4 # 4 is syscall for printing
    la $a0, prompt
    syscall

    # read integer
    li $v0, 5 # 5 is syscall for reading an integer from the user
    syscall
    move $a0, $v0  # move input to $a0 for power function

    # call powerThree
    jal power

    # print result message
    li $v0, 4
    la $a0, message
    syscall

    # print result
    move $a0, $v1  # move result to $a0 for printing
    li $v0, 1 # load immediate function; syscall prints an int
    syscall

    # print newline
    li $v0, 4
    la $a0, newline
    syscall

    # increment stack/restore it
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

power:
    # $a0: v (exponent)
    # $v1: result (multiplication)

    addi $sp, $sp, -12 # allocates space in stack for 3 registers
    sw $ra, 8($sp)
    sw $s0, 4($sp)
    sw $s1, 0($sp)

    move $s0, $a0  # s0 = v from 3^v
    li $s1, 1      # s1 = multiplication = 1

    # check if v == 0
    li $t0, 0              # i = 0; set in case we have to loop later
    bnez $s0, _power_loop

    # when v == 0, we have base case
    addi $v1, $s1, -3 # return 1 -3 = -2
    j _power_end

_power_loop:
    bge $t0, $s0, _end_loop # if the value in $t0 is greater than or equal to the value in $s0, then branch to the label end_loop
    mul $s1, $s1, 3  # multiplication *= 3
    addi $t0, $t0, 1  # i++
    j _power_loop

_end_loop:
    # subtract 3 from result
    addi $v1, $s1, -3
    j _power_end

_power_end:
    lw $s1, 0($sp)
    lw $s0, 4($sp)
    lw $ra, 8($sp)
    addi $sp, $sp, 12
    jr $ra

.data
    prompt:     .asciiz "Enter a non-negative integer: "
    message: .asciiz "Result: "
    newline:    .asciiz "\n"
