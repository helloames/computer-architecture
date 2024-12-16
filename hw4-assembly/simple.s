# Example for ECE 250 (thanks to Prof. Alvin Lebeck)
# Program to add together list of 9 numbers
# Updated by Tyler Bletsch 2020-05-17

# Walks through array of ints at label 'list' and sums them, reporting progress as we go.

.text                           # Code segment
.align 2                        # ensure data segment items align to 2^2 = 4 bytes

.globl main                     # indicate that 'main' label is a function and not just an private inner label
main:                           # MAIN procedure Entrance
    # here's all registers we're using -- initalizing them: 
    la $t0, list                # t0 is pointer that walks through list
    la $t1, endoflist           # t1 is end of list pointer
                                # t2 is current value (not initialized here)
    li $t3, 0                   # t3 is running total
    
_again:
    beq     $t0, $t1, _end      # break loop when pointer goes to end of list
    lw      $t2, 0($t0)         # load this value
    add     $t3, $t3, $t2       # sum = sum + this

    li      $v0, 4              #\
    la      $a0, msg            # >  Print a string
    syscall                     #/
    li      $v0, 1              #\
    move    $a0, $t3            # >  Print a number
    syscall                     #/
    li      $v0, 4              #\
    la      $a0, nln            # > Print a string (eol)
    syscall                     #/
    
    addu    $t0, $t0, 4         # increment pointer to next word
    b       _again              # unconditional go to top of loop
    
_end:

    li      $v0, 4              #\
    la      $a0, done_msg       # >  Print a string
    syscall                     #/
    
    li      $v0, 0              # \ return 0 from main 
    jr      $ra                 # / 
.end main                       #  end of main function



.data                           # Start of data segment
list:   .word   35, 16, 42, 19, 55, 91, 24, 61, 53
endoflist: # this label points to the first piece of data after the list, and is used to tell when to stop the loop

msg:    .asciiz "The sum is "

done_msg: .asciiz "Program done!"

nln:    .asciiz "\n"