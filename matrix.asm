.text   
	# t0 - Terminal pointer
	# t1 - Color storage
	# t2 - Location storage
	# t3 - isValid counter
	# t4 - counter
	# t8 - SP backup
	# t9 - Total columns
	# s1 - column
	# s2 - speed
	# s7 - to backup sp
	
	###################
	addi $t9, $zero, 60			# NUMBER OF LINES. Change only this value to change the number of lines. Max is 78
	###################
	la $t0, 0xffff8000			# Start value of terminal
	li $s0, 0x00002200			# Color value of the dark green. Change color value to test that all lines are used
fill:
	li $a0, 10
	li $a1, 93				#change 93 to 2 for 1s and 0s
	li $v0, 42
	syscall					# Generate random number
	addi $a0, $a0, 33			# change 33 to 48 for 1s and 0s
	sll $a0, $a0, 24
	or $t1, $s0, $a0
	sw $t1, ($t0)				# Add to terminal
	addi $t0, $t0, 4			# Increment a word
	blt $t0, 0xffffb200, fill		# Fills until the end of the terminal has been reached
	move $s5, $zero
	subi $sp, $zero, 160
	move $t8, $sp
	addi $s6, $zero, 5
	
headInitialize:					# Initialize t9 number of runners
	beq $t4, $t9, main
	jal _newColumn
	addi $t4, $t4, 1
	addi $sp, $sp, 2
	j headInitialize
	
main:						# Main program. Calling mainLoop will iterate all columns 1
	move $t4, $zero
	move $sp, $t8				# Reset stack pointer to -160
	beq $s6, 0, resetSwitch			# s6 cycles through 1-5 to give different speeds
resetreturn:
	addi $s6, $s6, -1
	j mainLoop
	
mainLoop:
	bge $t4, $t9, main			# Run mainLoop t9 number of times
	lb $s1, ($sp)
	addi $sp, $sp, 1
	lb $s2, ($sp)
	addi $sp, $sp, -1
	
	blt $s2, $s6, skip			# If it is less than, skip iterating this time to give different speeds
	jal _iterate
	beq $s5, 1, skip			# Iterate changes s5 if it has finished a column and needs a new one
	jal _newColumn
skip:
	addi $t4, $t4, 1			# Counter++
	la $t0, 0xffff8000			# Point t0 to beginning of terminal
	move $s5, $zero				# Reset s5
	addi $sp, $sp, 2			# Stack = Stack + 2
	j mainLoop
resetSwitch:
	addi $s6, $zero, 5			# Flip s6 from 0 to 5
	j resetreturn

_newColumn:
	li $a0, 10
	li $a1, 4				#0-5
	li $v0, 42
	syscall
	addi $s2, $a0, 1			# Store speed in s1
	li $a0, 10
	li $a1, 80				# 0-80
	li $v0, 42
	syscall					# Generate random number
	move $t2, $ra
	move $s7, $sp
	move $sp, $t8				# set sp to -160
	jal _isValid
	move $sp, $s7
	move $ra, $t2
	beq $a1, 1, _newColumn
	move $s1, $a0				#Store column in s1
	sb $s1, ($sp)
	addi $sp, $sp, 1
	sb $s2, ($sp)
	addi $sp, $sp, -1
	mul $t0, $s1, 4
	add $t0, $t0, 0xffff8000
	lw $t1, ($t0)
	lw $t2, ($t0)
	andi $t1, $t1, 0x0000ff00
	addi $t1, $t1, 0x0000dd00
	andi $t2, $t2, 0xff000000
	or $t1, $t1, $t2
	sw $t1, ($t0)				# Store to the Terminal
	jr $ra
	
_isValid:
	beq $s1, $a0, vFound			#if found, return with a0 = 0
	beq $t3, $t9, vReturn			#t9 is number of lines
	addi $a1, $zero, 0
	lb $s1, ($sp)
	addi $sp, $sp, 2
	addi $t3, $t3, 1
	j _isValid
vFound:
	addi $a1, $zero, 1
vReturn:
	move $t3, $zero
	jr $ra
	
_iterate:
	lb $s1, ($sp)				# Get the column number
	mul $t0, $s1, 4
	add $t0, $t0, 0xffff8000
iterateLoop:
	bgt $t0, 0xffffb1ff, iReturn		# If we hit the end of the terminal, return
	lw $t1, ($t0)				# Load current terminal value
	lw $t2, ($t0)
	andi $t1, $t1, 0x0000ff00
	andi $t2, $t2, 0xff000000
	addi $t0, $t0, 320
	blt $t1, 0x00003300, iterateLoop	# if the value is normal, branch
	subi $t0, $t0, 320
	addi $s5, $zero, 1
	bge $t1, 0x0000ff00, iterateFF		# if the color is ff, jump to iterateff
	subi $t1, $t1, 0x00001100		# Turn the color 1 shade lighter
	or $t1, $t1, $t2
	sw $t1, ($t0)				# Store to the Terminal
	addi $t0, $t0, 320			# Terminal++
	j iterateLoop
iterateFF:	
	subi $t1, $t1, 0x00001100		# Turn the ff color to ee
	or $t1, $t1, $t2			# Add the color back to the location
	sw $t1, ($t0)				# Store value back in the terminal
	addi $t0, $t0, 320			# Next char in column
	bgt $t0, 0xffffb1ff, iReturn		# If we hit the end of the terminal, return
	lw $t1, ($t0)				# Grap the char one below ff
	lw $t2, ($t0)
	andi $t1, $t1, 0x0000ff00
	andi $t2, $t2, 0xff000000
	addi $t1, $t1, 0x0000dd00		# Turn 22 to ff
	or $t1, $t1, $t2			# Add the color back to the location
	sw $t1, ($t0)				# Store value back in the terminal
	jr $ra
iReturn:
	jr $ra
