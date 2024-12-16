.data
    buffer: .space 64     # buffer for reading player names
    parPrompt: .asciiz "Enter the par for the course: "
    namePrompt: .asciiz "Enter player name (or 'DONE' to finish): "
    scorePrompt: .asciiz "Enter player score: "
    plus: .asciiz "+"
    space: .asciiz " "
    newLine: .asciiz "\n"
    done: .asciiz "DONE\n"

    # GolfPlayer structure: name(64 bytes) + score(4 bytes) + next(4 bytes) = 72 bytes
    playerSize: .word 72

.text 

main:
    addi $sp, $sp, -12 # allocates space for 3 registers in the stack
    # subtracts 8 from stack pointer to do so
    sw $ra, 0($sp) # stores the return address ($ra) at the address in $sp
    sw $s0, 4($sp) # holds par
    sw $s1, 8($sp) # holds head of linked list

# logic: 
# 1. read the par
# 2. read the player names and scores
# 3. insert players into the sorted list
# 4. print the sorted list

    # read the par number
    li $v0, 4
    la $a0, parPrompt
    syscall
    
     # store par in $s0
    li $v0, 5
    syscall
    move $s0, $v0 

    # initialize the head of the linked list
    move $s1, $zero  # $s1 will store the head of the list (initially NULL)
    move $a2, $s1   # move $s1 into $a2 for loop; aka move head of list into a2
    move $a0, $s0 # move par to $a0
    
    jal read_players # begin asking for inputs of players and their scores, read_players will call print_list when reading is DONE

    lw $ra, 0($sp)
    lw $s0, 4($sp)
    lw $s1, 8($sp)
    addi $sp, $sp, 12

    jr $ra
    

read_players: # begin asking for inputs of players and their scores
    addi $sp, $sp, -20
    sw $ra, 0($sp)
    sw $s0, 4($sp) # used to hold player's score 
    sw $s1, 8($sp) # holds original par
    sw $s2, 12($sp) # holds address of the new player node
    sw $s3, 16($sp) # holds the head of the list

    move $s1, $a0 # store original par in $s1
    move $s3, $a2 # store head of the list

_read_loop:
    # prompt for player name
    li $v0, 4
    la $a0, namePrompt
    syscall

     # read in the player's name
    li $v0, 8
    la $a0, buffer
    li $a1, 64
    syscall

    # check if the loaded player name was "DONE"
    la $a2, buffer
    la $a3, done
    jal strcomp
    beqz $v0, finish_read

    # player name was not "DONE" therefore scan and read in their score
    li $v0, 4
    la $a0, scorePrompt
    syscall

    li $v0, 5
    syscall
    move $s0, $v0 # store their score in $s0

    # calculate the player's relative score
    sub $s0, $s0, $s1

    # allocate memory in heap for new player/create node
    li $v0, 9
    lw $a0, playerSize
    syscall
    move $s2, $v0  # $s2 now holds the address of the new player node

    # store player name in the node
    la $a0, buffer # a0 is address of the start of the node, aka start of the string
    move $a1, $s2 # a1 is a register with a value pointing to the start of the buffer
    jal strcopy

    # store score in a node
    sw $s0, 64($s2)

    # set its next pointer to null
    sw $zero, 68($s2)

    # insert the player into sorted list
    move $a0, $s3  # current head of the list
    move $a1, $s2  # new player node
    jal insert_player
    move $s3, $v0  # update head of the list

    j _read_loop

finish_read:
    move $a0, $s3 # head
    move $a1, $s1 # par score
    jal print_list

    lw $ra, 0($sp)
    lw $s0, 4($sp) # used to hold player's score 
    lw $s1, 8($sp) # holds original par
    lw $s2, 12($sp) # holds address of the new player node
    lw $s3, 16($sp) 
    addi $sp, $sp, 20
    jr $ra


print_list: # print out the sorted list
    # $a0: head of list
    # $a1: par score
    
    addi $sp, $sp, -12
    sw $ra, 0($sp)
    sw $t0, 4($sp) # used to contain current node
    sw $t1, 8($sp)

    move $t0, $a0 # t0 now contains current node
    move $t1, $a1

_print_loop:
    beqz $t0, finish_print

    # make sure name doesn't have the last null character
    move $a0, $t0
    jal remove_null
    move $a0, $v0

    # print the name
    move $a0, $t0
    li $v0, 4
    syscall

    lw $t2, 64($t0) # load score for testing if it's negative or not
    blez $t2, _no_plus_print

    # print the plus sign
    li $v0, 4       
    la $a0, plus   
    syscall          

_no_plus_print: # print score
    lw $a0, 64($t0) # load the score
    li $v0, 1
    syscall
    
    lw $t0, 68($t0) # move onto the next node
    
    # print the new line
    li $v0, 11
    li $a0, 10 # ascii for new line
    syscall

    j _print_loop

finish_print:
    lw $ra, 0($sp)
    lw $t0, 4($sp)
    lw $t1, 8($sp)
    addi $sp, $sp, 12
    jr $ra

remove_null: # removes the last (null) character of the string for name and replaces with a space
    # a0: the string
    addi $sp, $sp, -12
    sw $ra, 0($sp)
    sw $t0, 4($sp)
    sw $t1, 8($sp)

_find_loop:
    lb $t0, 0($a0)
    beqz $t0, _found_end # if $t0 is the null terminator, we have found the end
    addi $a0, $a0, 1    # move onto the next character if it wasn't a null terminator
    j _find_loop

_found_end:
    addi $a0, $a0, -1 # go back one character aka to last non-null character
    li $t1, 32    # put the space in t1
    sb $t1, 0($a0)   # store the space at that current address

    move $t2, $a0
    move $v0, $t2
    lw $ra, 0($sp)
    lw $t0, 4($sp)
    lw $t1, 8($sp)
    addi $sp, $sp, 12
    jr $ra

insert_player:
    # $a0: head of list
    # $a1: new player node
    # returns $v0: new head of list
    addi $sp, $sp, -24
    sw $ra, 0($sp)
    sw $s0, 4($sp)  # new player's score
    sw $s1, 8($sp)  # current node's score
    sw $s2, 12($sp) # holds current node
    sw $s3, 16($sp) # next node (the node after current)
    sw $s4, 20($sp) # new player node

    move $s4, $a1   # store new player node in $s4
    lw $s0, 64($s4) # new player's score

    # when we know list is empty or new node should come first
    beqz $a0, _insert_at_head            # if existing list head is null, new node should become head
    lw $s1, 64($a0)                     # store head's score in $s1
    blt $s0, $s1, _insert_at_head       # if new player's score is less than head's score, store new node as head 
    beq $s0, $s1, _compare_names_head   # if new player score and head score are equal, then compare the names (head's name and new player's name)

    # find insertion point
    move $s2, $a0   # $s2 is current node

_insert_loop:
    lw $s3, 68($s2)         # load next node into $s3
    beqz $s3, _insert_at_end # if next is null, insert new node at end
    
    lw $s1, 64($s3)                 # load next node's score into $s1
    blt $s0, $s1, _insert_between   # if new player's score is less than next node's score, store new node in between current and next
    beq $s0, $s1, _compare_names    # if new node's score is equal to next node's score, compare their names
    
    # move to next node
    move $s2, $s3                   # if none of that worked, move next to current (traverse by one node)
    j _insert_loop                   # repeat this loop

_compare_names_head:    # compares the strings at head node and new node
    # load things into argument registers
    move $a2, $a0             # head node (current string)
    move $a3, $s4             # new node (new string)
    jal strcomp               # finish string compare
    bgtz $v0, _insert_at_head # when new node needs to come before head node

    # when that doesn't work (ie new node comes after head/current, but we don't know if directly after, just continue the search for where to put it) 
    j _continue_search

_compare_names:    # compare new node's string and next node's string
    # load things into argument registers
    move $a2, $s4  # new node (new string)
    move $a3, $s3  # next node (current string)
    jal strcomp    # finish string compare
    blez $v0, _insert_between # when new node needs to come before head node
    
    # when new node comes after next node 
    # move to next node
    move $s2, $s3
    j _insert_loop

_continue_search:
    move $s2, $a0
    j _insert_loop

_insert_between:
    # insert new node between current and next
    sw $s3, 68($s4)  # new node's next = current's next
    sw $s4, 68($s2)  # current's next = new node
    move $v0, $a0    # return original head
    j _end_insert

_insert_at_end:
    sw $s4, 68($s2)  # current's next = new node
    move $v0, $a0    # return original head
    j _end_insert

_insert_at_head:
    sw $a0, 68($s4)  # new node's next = old head
    move $v0, $s4    # return new head

_end_insert:
    lw $ra, 0($sp)
    lw $s0, 4($sp)
    lw $s1, 8($sp)
    lw $s2, 12($sp)
    lw $s3, 16($sp)
    lw $s4, 20($sp)
    addi $sp, $sp, 24
    jr $ra


# compares two strings alphabetically
# registers:
# - $a0 (argument): Pointer to the first input, moved as we loop
# - $a1 (argument): Pointer to the second input, moved as we loop
# - $t0: Current character from 0($a0)
# - $t1: Current character from 0($a1)
# - $v0 (return): =0 if strings are equal, <0 if $a0 < $a1, >0 if $a0 > $a1


# leaf function, so using caller-saved to avoid needing to save any registers
strcomp: # note that $a2 = string1, $a3 = string2
    lb $t0, ($a2)         # load a byte from string1, head node
    lb $t1, ($a3)         # load a byte from string2, new node
    bne $t0, $t1, done_with_strcomp    # if chars differ, finish loop
    addi $a2, $a2, 1      # move to next char in first string
    addi $a3, $a3, 1      # move to next char in second string
    bnez $t0, strcomp

done_with_strcomp: # if chars differ, or we've reached the end, return 
    sub $v0, $t0, $t1
    jr $ra 


# copies a string from one location to another
# registers:
# - $a0 (argument): pinter to the input string
# - $a1 (argument): pointer to the destination
# - $t0: curre t character of the string
# loop over the input string until we reach the NULL character, copying one character at a time
# modify $a0 and $a1 as we go to point to each character's initial and final location


# leaf function, so using caller-saved to avoid needing to save any registers
strcopy: 

_strcpy_loop:
    # copy the character from the source to the destination
    lb $t0, 0($a0)
    sb $t0, 0($a1)
    # check if we've reached the end of the string
    beqz $t0, _strcpy_done
    # increment our pointers and loop
    addi $a0, $a0, 1
    addi $a1, $a1, 1
    b _strcpy_loop

_strcpy_done: # return
    jr $ra