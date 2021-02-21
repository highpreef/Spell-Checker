
#=========================================================================
# Tokenizer
#=========================================================================
# Split a string into alphabetic, punctuation and space tokens
# 
# Inf2C Computer Systems
# 
# Siavash Katebzadeh
# 8 Oct 2018
# 
#
#=========================================================================
# DATA SEGMENT
#=========================================================================
.data
#-------------------------------------------------------------------------
# Constant strings
#-------------------------------------------------------------------------

input_file_name:        .asciiz  "input.txt"   
newline:                .asciiz  "\n"
        
#-------------------------------------------------------------------------
# Global variables in memory
#-------------------------------------------------------------------------
# 
content:                .space 2049     # Maximun size of input_file + NULL


# You can add your data here!
.align 0
tokens:                 .space 411849  # tokens[Maximun size of input_file + NULL][Maximun size of input_file + NULL]
        
#=========================================================================
# TEXT SEGMENT  
#=========================================================================
.text

#-------------------------------------------------------------------------
# MAIN code block
#-------------------------------------------------------------------------

.globl main                     # Declare main label to be globally visible.
                                # Needed for correct operation with MARS
main:
        
#-------------------------------------------------------------------------
# Reading file block. DO NOT MODIFY THIS BLOCK
#-------------------------------------------------------------------------

# opening file for reading

        li   $v0, 13                    # system call for open file
        la   $a0, input_file_name       # input file name
        li   $a1, 0                     # flag for reading
        li   $a2, 0                     # mode is ignored
        syscall                         # open a file
        
        move $s0, $v0                   # save the file descriptor 

# reading from file just opened

        move $t0, $0                    # idx = 0

READ_LOOP:                              # do {
        li   $v0, 14                    # system call for reading from file
        move $a0, $s0                   # file descriptor
                                        # content[idx] = c_input
        la   $a1, content($t0)          # address of buffer from which to read
        li   $a2,  1                    # read 1 char
        syscall                         # c_input = fgetc(input_file);
        blez $v0, END_LOOP              # if(feof(input_file)) { break }
        lb   $t1, content($t0)          
        addi $v0, $0, 10                # newline \n
        beq  $t1, $v0, END_LOOP         # if(c_input == '\n')
        addi $t0, $t0, 1                # idx += 1
        j    READ_LOOP
END_LOOP:
        sb   $0,  content($t0)

        li   $v0, 16                    # system call for close file
        move $a0, $s0                   # file descriptor to close
        syscall                         # fclose(input_file)
#------------------------------------------------------------------
# End of reading file block.
#------------------------------------------------------------------

tokenizer:
        li $t0, 0                       # index of content	
        li $t4, 0                       # index of row
        li $t5, 0                       # index of column

        lb $s0, content($t0)            # load first char into $s0
        beq $zero, $s0, output_tokens   # check for end of content

loop:   # do {
        slti $t1, $s0, 91               # check if c <= 'Z'
        li $t7, 65
        sge $t2, $s0, $t7               # check if c >= 'A'
        and $t1, $t1, $t2               # check if c >= 'A' && c <= 'Z'

        slti $t2, $s0, 123              # check if c <= 'z'
        li $t7, 97
        sge $t3, $s0, $t7               # check if c >= 'a'
        and $t2, $t2, $t3               # check if c >= 'a' && c <= 'z'

        or $t1, $t1, $t2                # check if c >= 'A' && c <= 'Z' || c >= 'a' && c <= 'z'
        bnez $t1, alpha	                # brach if alphabetic character

        li $t7, 44
        seq $t1, $s0, $t7               # check if c == ','
        li $t7, 46
        seq $t2, $s0, $t7               # check if c == '.'
        or $t1, $t1, $t2                # check if c == ',' || c == '.'

        li $t7, 33
        seq $t2, $s0, $t7               # check if c == '!'
        li $t7, 63
        seq $t3, $s0, $t7               # check if c == '?'
        or $t2, $t2, $t3                # check if c == '!' || c == '?'

        or $t1, $t1, $t2                # check if c == ',' || c == '.' || c == '!' || c == '?'
        bnez $t1, punct                 # branch if punctuation mark

        li $t7, 32
        seq $t1, $s0, $t7               # check if c == ' '
        bnez $t1, space                 # branch if space

        j loop			
	# } while (1);
alpha:
        mul $t6, $t4, 201               # row * row length
        add $t6, $t6, $t5               # index = (row * row length) + column 
        sb $s0, tokens($t6)             # store char in tokens array

        addi $t5, $t5, 1                # increase index of tokens array
        addi $t0, $t0, 1                # increase index of content

        lb $s0, content($t0)            # load next char
        beq $zero, $s0, output_tokens   # check for end of sentence

        slti $t1, $s0, 91               # check if c <= 'Z'
        li $t7, 65
        sge $t2, $s0, $t7               # check if c >= 'A'
        and $t1, $t1, $t2               # check if c >= 'A' && c <= 'Z'

        slti $t2, $s0, 123              # check if c <= 'z'
        li $t7, 97
        sge $t3, $s0, $t7               # check if c >= 'a'
        and $t2, $t2, $t3               # check if c >= 'a' && c <= 'z'

        or $t1, $t1, $t2                # check if c >= 'A' && c <= 'Z' || c >= 'a' && c <= 'z'
        bnez $t1, alpha	                # copy until char is not of the same type

        addi $t4, $t4, 1                # increase row index
        addi $t6, $t6, 1                # got to index of last char of token + 1
        sb $zero, tokens($t6)           # end row with \0
        li $t5, 0                       # reset column index

        j loop

punct:
        mul $t6, $t4, 201               # row * row length
        add $t6, $t6, $t5               # index = (row * row length) + column 
        sb $s0, tokens($t6)             # store char in tokens array

        addi $t5, $t5, 1                # increase index of tokens array
        addi $t0, $t0, 1                # increase index of content

        lb $s0, content($t0)            # load next char
        beq $zero, $s0, output_tokens   # check for end of sentence

        li $t7, 44
        seq $t1, $s0, $t7               # check if c == ','
        li $t7, 46
        seq $t2, $s0, $t7               # check if c == '.'
        or $t1, $t1, $t2                # check if c == ',' || c == '.'

        li $t7, 33
        seq $t2, $s0, $t7               # check if c == '!'
        li $t7, 63
        seq $t3, $s0, $t7               # check if c == '?'
        or $t2, $t2, $t3                # check if c == '!' || c == '?'

        or $t1, $t1, $t2                # check if c == ',' || c == '.' || c == '!' || c == '?'
        bnez $t1, punct	                # copy until char is not of the same type

        addi $t4, $t4, 1                # increase row index
        addi $t6, $t6, 1                # go to index of last char of token + 1
        sb $zero, tokens($t6)           # end row with \0
        li $t5, 0                       # reset column index

        j loop

space:
        mul $t6, $t4, 201               # row * row length
        add $t6, $t6, $t5               # index = (row * row length) + column 
        sb $s0, tokens($t6)             # store char in tokens array

        addi $t5, $t5, 1                # increase index of tokens array
        addi $t0, $t0, 1                # increase index of content

        lb $s0, content($t0)            # load next char
        beq $zero, $s0, output_tokens   # check for end of sentence

        li $t7, 32
        seq $t1, $s0, $t7	        # check if c == ' '
        bnez $t1, space			# copy until char is not of the same type

        addi $t4, $t4, 1                # increase column index
        addi $t6, $t6, 1                # go to index of last char of token + 1
        sb $zero, tokens($t6)           # end row with \0
        li $t5, 0                       # reset column index

        j loop

output_tokens:
        lb $s1, tokens($zero)           # load first char of first token token into $s1
        li $t0, 0                       # row index
        li $t1, 0                       # column index

loop2:
        seq $t3, $s1, $zero             # If all tokens are printed
        bnez $t3, main_end              # End program

        move $a0, $s1
        li $v0, 11
        syscall                         # Print char

        addi $t1, $t1, 1                # increase column index
 
        mul $t2, $t0, 201               # row * row length
        add $t2, $t2, $t1               # index = (row * row length) + column 

        lb $s1, tokens($t2)             # load next char
        seq $t2, $s1, $zero             # if null terminator
        bnez $t2, endOfRow              # branch to move to next token

        j loop2                         # continue to print current token

endOfRow:
        addi $t0, $t0, 1                # increase row index
        li $t1, 0                       # reset column index
        
        mul $t2, $t0, 201               # row * row length
        add $t2, $t2, $t1               # index = (row * row length) + column 
        lb $s1, tokens($t2)             # load first char of next token
        
        seq $t3, $s1, $zero             # If all tokens are printed
        bnez $t3, main_end              # End program

        la $a0, newline
        li $v0, 4
        syscall                         # Print new line
         
        j loop2
     
        
#------------------------------------------------------------------
# Exit, DO NOT MODIFY THIS BLOCK
#------------------------------------------------------------------
main_end:      
        li   $v0, 10          # exit()
        syscall

#----------------------------------------------------------------
# END OF CODE
#----------------------------------------------------------------
