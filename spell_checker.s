
#=========================================================================
# Spell checker 
#=========================================================================
# Marks misspelled words in a sentence according to a dictionary
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
dictionary_file_name:   .asciiz  "dictionary.txt"
newline:                .asciiz  "\n"
        
#-------------------------------------------------------------------------
# Global variables in memory
#-------------------------------------------------------------------------
# 
content:                .space 2049     # Maximun size of input_file + NULL
.align 4                                # The next field will be aligned
dictionary:             .space 200001   # Maximum number of words in dictionary *
                                        # maximum size of each word + NULL
  
.align 0
tokens_buffer:          .space 203     # buffer array for temporary saving of tokens (accounts for '_' chars)
.align 0
tokens:                 .space 415947  # tokens[Maximun size of input_file + NULL][Maximun size of input_file + NULL + 2] (accounts for '_' chars)                                   



# You can add your data here!
        
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
        sb   $0,  content($t0)          # content[idx] = '\0'

        # Close the file 

        li   $v0, 16                    # system call for close file
        move $a0, $s0                   # file descriptor to close
        syscall                         # fclose(input_file)


        # opening file for reading

        li   $v0, 13                    # system call for open file
        la   $a0, dictionary_file_name  # input file name
        li   $a1, 0                     # flag for reading
        li   $a2, 0                     # mode is ignored
        syscall                         # fopen(dictionary_file, "r")
        
        move $s0, $v0                   # save the file descriptor 

        # reading from file just opened

        move $t0, $0                    # idx = 0

READ_LOOP2:                             # do {
        li   $v0, 14                    # system call for reading from file
        move $a0, $s0                   # file descriptor
                                        # dictionary[idx] = c_input
        la   $a1, dictionary($t0)       # address of buffer from which to read
        li   $a2,  1                    # read 1 char
        syscall                         # c_input = fgetc(dictionary_file);
        blez $v0, END_LOOP2             # if(feof(dictionary_file)) { break }
        lb   $t1, dictionary($t0)               
        lb   $t1, dictionary($t0)               
        beq  $t1, $0,  END_LOOP2        # if(c_input == '\n')
        addi $t0, $t0, 1                # idx += 1
        j    READ_LOOP2
END_LOOP2:
        sb   $0,  dictionary($t0)       # dictionary[idx] = '\0'

        # Close the file 

        li   $v0, 16                    # system call for close file
        move $a0, $s0                   # file descriptor to close
        syscall                         # fclose(dictionary_file)
#------------------------------------------------------------------
# End of reading file block.
#------------------------------------------------------------------




# You can add your code here!

main_spell_checker:
        jal tokenizer                   # call tokenizer
        jal checker                     # call spelling checker
        j print                         # print checked tokens

#### Start of tokenizer Function ####
tokenizer:
        addi $sp, $sp, -8               # reserve memory
        sw $ra, 4($sp)                  # push $ra onto stack
        sw $s0, 0($sp)                  # push $s0 onto stack

        li $t0, 0                       # index of content	
        li $t4, 0                       # index of row
        li $t5, 0                       # index of column
        
        lb $s0, content($t0)            # load first char into $a1
        beq $zero, $s0, end             # check for end of content

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
        mul $t6, $t4, 203               # row * row length
        add $t6, $t6, $t5               # index = (row * row length) + column 
        sb $s0, tokens($t6)             # store char in tokens array

        addi $t5, $t5, 1                # increase index of tokens array
        addi $t0, $t0, 1                # increase index of content

        lb $s0, content($t0)            # load next char
        beq $zero, $s0, end             # check for end of sentence

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
        li $t5, 0

        j loop

punct:
        mul $t6, $t4, 203               # row * row length
        add $t6, $t6, $t5               # index = (row * row length) + column 
        sb $s0, tokens($t6)             # store char in tokens array

        addi $t5, $t5, 1                # increase index of tokens array
        addi $t0, $t0, 1                # increase index of content

        lb $s0, content($t0)            # load next char
        beq $zero, $s0, end             # check for end of sentence

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
        addi $t6, $t6, 1                # got to index of last char of token + 1
        sb $zero, tokens($t6)           # end row with \0
        li $t5, 0

        j loop

space:
        mul $t6, $t4, 203               # row * row length
        add $t6, $t6, $t5               # index = (row * row length) + column 
        sb $s0, tokens($t6)             # store char in tokens array

        addi $t5, $t5, 1                # increase index of tokens array
        addi $t0, $t0, 1                # increase index of content

        lb $s0, content($t0)            # load next char
        beq $zero, $s0, end             # check for end of sentence

        li $t7, 32
        seq $t1, $s0, $t7	        # check if c == ' '
        bnez $t1, space			# copy until char is not of the same type

        addi $t4, $t4, 1                # increase row index
        addi $t6, $t6, 1                # got to index of last char of token + 1
        sb $zero, tokens($t6)           # end row with \0
        li $t5, 0

        j loop

end:
        lw $s0, 0($sp)                  # recover $s0
        lw $ra, 4($sp)                  # recover $ra 
        addi $sp, $sp, 8                # pop the memory off the stack
        jr $ra                          # end function call
#### End of tokenizer funtion ####

#### Start of spell_checker function ####
checker:
        addi $sp, $sp, -16              # reserve memory
        sw $ra, 12($sp)                 # push $ra onto stack
        sw $s0, 8($sp)                  # push $s0 onto stack
        sw $s1, 4($sp)                  # push $s1 onto stack
        sw $s2, 0($sp)                  # push $s2 onto stack

        li $t0, 0                       # index of row

loop_start:
        li $t1, 0                       # index of column
        li $t9, 0                       # 'correct' boolean
        li $t8, 0                       # dictionary index

        mul $t2, $t0, 203               # row * row length
        add $t2, $t2, $t1               # index = (row * row length) + column 

        lb $s0, tokens($t2)             # load char into $a1
        beq $zero, $s0, check_end       # check for end of sentence

        jal toLower                     # make spell checking case insensitive

        li $t7, 44
        seq $t3, $s0, $t7               # check if c == ','
        li $t7, 46
        seq $t4, $s0, $t7               # check if c == '.'
        or $t3, $t3, $t4                # check if c == ',' || c == '.'

        li $t7, 33
        seq $t4, $s0, $t7               # check if c == '!'
        li $t7, 63
        seq $t5, $s0, $t7               # check if c == '?'
        or $t4, $t4, $t5                # check if c == '!' || c == '?'

        or $t3, $t3, $t4                # check if c == ',' || c == '.' || c == '!' || c == '?'

        li $t7, 32
        seq $t4, $s0, $t7               # check if c == ' '
        or $t3, $t3, $t4                # check if c == ',' || c == '.' || c == '!' || c == '?' || c == ' '

        bnez $t3, nonAlpha              # branch if non Alpha char

Alpha: 
        lb $s1, dictionary($t8)         # load dictionary char
        beqz $s1, correctness           # Branch out if dictionary is fully searched

        seq $t3, $t8, $zero             # check if dictionary_index == 0
        bnez $t3, firstDictWord         # branch if checking against first dictionary word

        li $v0, 10                      # check if current dictionary char is '\n'
        bne $s1, $v0, dictionaryMove    # move dictionary index up by one until it is

        addi $t8, $t8, 1                # get index of first char of current dictionary word

        j isMatch                       # check if words match

firstDictWord:
        j isMatch                       # check if words match

isMatch:			
        lb $s2, dictionary($t8)         # load first char of current dictionary word into $s2

        li $v0, 10
        seq $t2, $s2, $v0               # currentDictWord[idx] == '\n'
        seq $t3, $s0, $zero             # c == '\0'

        and $t2, $t2, $t3               # dictionary[current_index] == '\n' && c == '\0'
        bnez $t2, match	                # branch if a match was found

        li $v0, 10
        seq $t2, $s2, $v0               # dictionary[current_index] == '\n'
        sne $t3, $s0, $zero             # c != '\0'

        and $t2, $t2, $t3               # dictionary[current_index + 1] == '\n' && c == '\0'
        bnez $t2, notRightWord          # branch if dictionary word had part of token in it

        sne $t4, $s2, $s0               # if (dictionary[current_index+1] != c)
        bnez $t4, notRightWord          # branch out if first char of current dictionary word != c

        seq $t3, $s2, $s0               # if (dictionary[current_index+1] == c)
        bnez $t3, rightWord             # branch out if first char of current dictionary word == c

        addi $t8, $t8, 1                # for loop add to dictionary index
        j Alpha

rightWord:
        addi $t1, $t1, 1                # increase column index
        mul $t2, $t0, 203               # row * row length
        add $t2, $t2, $t1               # index = (row * row length) + column 

        lb $s0, tokens($t2)             # load next char of token into $s0

        jal toLower                     # make spell checking case insensitive

        addi $t8, $t8, 1                # add to dictionary index

        j isMatch                       # return to main loop

notRightWord:
        li $t1, 0                       # reset column index
        mul $t2, $t0, 203               # row * row length
        add $t2, $t2, $t1               # index = (row * row length) + column 

        lb $s0, tokens($t2)             # load first char of token back into $s0

        jal toLower                     # make spell checking case insensitive

        beqz $t8, notRightWord_end      # if first char of dictionary is not equal to first char of token branch

        j Alpha                         # return and load next dictionary word index

notRightWord_end:
        addi $t8, $t8, 1                # increase dictionary index
        
        j Alpha                         # return and load next dictionary word index

match:
        li $t9, 1                       # set correct to true
        j correctness                  

dictionaryMove:
        addi $t8, $t8, 1                # add 1 to dictionary index
        j Alpha

correctness:
        li $t1, 0                       # reset column index

        beqz $t9, buffer                # branch if token has incorrect spelling

        addi $t0, $t0, 1                # increase row index
        j loop_start                    # brute force check on next token

buffer:
        mul $t2, $t0, 203               # row * row length
        add $t2, $t2, $t1               # index = (row * row length) + column 

        lb $s0, tokens($t2)             # load char into $s0
        beqz $s0, buffer_end            # if end of token, branch

        sb $s0, tokens_buffer($t1)      # store char in buffer

        addi $t1, $t1, 1                # increase column index
        j buffer

buffer_end:
        sb $zero, tokens_buffer($t1)    # store null terminator in buffer
        li $t1, 0                       # reset column index

        mul $t2, $t0, 203               # row * row length
        add $t2, $t2, $t1               # index = (row * row length) + column 

        li $t3, 95                      # load '_' char into $t3
        sb $t3, tokens($t2)             # add preceding '_'

notCorrect:
        mul $t2, $t0, 203               # row * row length
        add $t2, $t2, $t1               # index = (row * row length) + column 

        lb $s0, tokens_buffer($t1)      # load char into $s0
        beqz $s0, succeeding            # add succeeding '_'

        addi $t2, $t2, 1                # add offset of 1
        sb $s0, tokens($t2)             # move char by one to the right

        addi $t1, $t1, 1                # increase column index
        j notCorrect

succeeding:
        addi $t2, $t2, 1                # add offset of 1
        li $t3, 95                      # load '_' char into $t3
        sb $t3, tokens($t2)             # add succeeding '_'
        addi $t2, $t2, 1                # add offset of 1

        sb $zero, tokens($t2)           # add null terminator to token row
        addi $t0, $t0, 1                # increase row index
        j loop_start	

nonAlpha:
        li $t1, 0                       # reset column index
        addi $t0, $t0, 1                # increase row index
        j loop_start                    # brute force check on next token

toLower:
        li $t7, 65
        sge $t3, $s0, $t7               # c >= 'A'
        li $t7, 90
        sle $t4, $s0, $t7               # c <= 'Z'
        and $t3, $t3, $t4               # c >= 'A' && c <= 'Z'

        beqz $t3, toLowerEnd            # if lowercase end function call

        addi $s0, $s0, 32               # make char lowercase
        jr $ra                          # end function call

toLowerEnd:
        jr $ra

check_end:
        lw $s2, 0($sp)                  # recover $s2
        lw $s1, 4($sp)                  # recover $s1
        lw $s0, 8($sp)                  # recover $s0
        lw $ra, 12($sp)                 # recover $ra 
        addi $sp, $sp, 16               # pop the memory off the stack
        jr $ra                          # end function call
#### End of spell_checker function ####
	
print:
        lb $s1, tokens($zero)
        li $t0, 0			# row index
        li $t1, 0			# column index

loop2:
        seq $t3, $s1, $zero             # If all tokens are printed
        bnez $t3, main_end              # End program

        move $a0, $s1
        li $v0, 11
        syscall                         # Print char

        addi $t1, $t1, 1                # increase column offset by 1
 
        mul $t2, $t0, 203               # row * row length
        add $t2, $t2, $t1               # index = (row * row length) + column 

        lb $s1, tokens($t2)             # load next char
        seq $t2, $s1, $zero             # if null terminator
        bnez $t2, endOfRow              # branch to move to next token

        j loop2                         # continue to print current token

endOfRow:
        addi $t0, $t0, 1                # increase row offset by 1
        li $t1, 0                       # reset column offset

        mul $t2, $t0, 203               # row * row length
        add $t2, $t2, $t1               # index = (row * row length) + column 
       
        lb $s1, tokens($t2)             # load first char of next token
      
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
