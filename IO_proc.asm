TITLE low-level I/O procedures   (IO_proc.asm)

; Author: Alex Wilson
; Last Modified: 5/31/2020
; OSU email address: wilsoal9@oregonstate.edu
; Course number/section:271/400
; Description:
; 1) Implements ReadVal and WriteVal procedures for signed integers. 
; 2) Implements macros getString and displayString.  
;		o getString displays a prompt, then gets the user’s keyboard input into a memory location 
;		o displayString prints the string which is stored in a specified memory location. 
;		o readVal invokes the getString macro to get the user’s string of digits.  It then converts the digit string to numeric, while validating the user’s input. 
;		o writeVal converts a numeric value to a string of digits, and invokes the displayString macro to produce the output. 
; Gets 10 valid integers from the user and stores the numeric values in an array.  The program then displays the integers, their sum, and their average. 

INCLUDE Irvine32.inc

getString MACRO prompt 
	push	edx
	push	ecx
	mov		edx, prompt 
	call	WriteString 
	mov		edx, OFFSET user_string
	mov		ecx, BUFFER_SIZE
	call	ReadString
	pop		ecx 
	pop		edx
	push	OFFSET user_string
ENDM

displayString MACRO user_string 
	push	edx 
	mov		edx, user_string 
	call	WriteString 
	pop		edx 
ENDM

BUFFER_SIZE = 256
ARRAYSIZE=10
.data
programTitle	BYTE	"Designing low-level I/O procedures", 0
programmer		BYTE	"Programmed by Alex Wilson", 0
instruction_1	BYTE	"Please provide 10 signed decimal integers.", 0
instruction_2	BYTE	"Each number needs to be small enough to fit inside a 32 bit register.", 0
instruction_3	BYTE	"After you have finished inputting the raw numbers, I will display a list of the integers, their sum, and their average values.", 0
input_1			BYTE	"Please enter a signed number: ",0
error_1			BYTE	"ERROR: You did not enter a signed number or your number was too big",0 
nums_entered	BYTE	"You entered the following numbers: ",0
string_sum		BYTE	"The sum of these numbers is: ",0
string_mean		BYTE	"The rounded average is: ",0
num_array		SDWORD	ARRAYSIZE	DUP(?)
goodbye			BYTE	"Thanks for playing!", 0 
user_string		BYTE	BUFFER_SIZE DUP(0)
user_num		SDWORD	?
nums_accum		DWORD	?
nums_mean		DWORD	0
loop_stop		DWORD	0 
space			BYTE	"  ",0
num_string		BYTE	11 DUP(?)

.code
main PROC
; introduces programmer and displays instructions 
push	OFFSET  programTitle 
push	OFFSET	programmer 
push	OFFSET	instruction_1 
push	OFFSET	instruction_2 
push	OFFSET	instruction_3 
call	introduction

; gets users string of digits and converts it to a numberic value
push	user_num
push	ARRAYSIZE 
push	OFFSET	num_array
push	OFFSET	input_1
push	OFFSET	error_1
call	readVal

; converts numbers entered by user to string and uses display string Macro to display
push	loop_stop
push	OFFSET num_string 
push	OFFSET string_mean 
push	OFFSET	string_sum
push	nums_mean
push	nums_accum
push	ARRAYSIZE
push	OFFSET	num_array
push	OFFSET	nums_entered
push	OFFSET	space
call	writeVal

; gets says goodbye to user 
push	OFFSET	goodbye 
call	farewell

	exit	; exit to operating system
main ENDP

;------------------------------------------------------------------------------
;introduction 
;Procedure that introduces program to user 
;recieves: address of programTitle, programmer and instructions 1,2, 3 via stack
;returns: prints programmer name, program title and instructions 
;preconditions: none 
;postcontditions: none
;registers changed: edx 
;------------------------------------------------------------------------------
introduction PROC
; displays programmer and program title 
	push	ebp
	mov		ebp, esp
	displayString		[ebp+24]
	call	Crlf
	displayString		[ebp+20]
	call	Crlf
; displays instructions for user 
	displayString		[ebp+16]
	call	Crlf
	displayString		[ebp+12]
	call	Crlf
	displayString		[ebp+8]
	call	Crlf
	pop		ebp
	ret		20
introduction ENDP

;------------------------------------------------------------------------------
;readVal  
;Procedure that gets numbers entered by user as strings, converts to numbers and fills array. Array size = 10.
;recieves: Address of input string, error message, number array and empty number variable via stack 
;returns: none 
;preconditions: User must enter a number and number must fit in 32-bit register 
;postcontditions: Fills number array with numbers entered by user 
;registers changed: eax, ebx, ecx, edx, esi, edi
;------------------------------------------------------------------------------

readVal PROC 
	push	edi 
	push	esi
	push	edx
	push	eax
	push	ebx 
	push	ecx 
	push	ebp
	mov		ebp, esp
	call	Crlf
	mov		edi, [ebp+40] ; address of num_array
	mov		ecx, [ebp+44] ; size of number array(10)

; gets number string from user and pops result into esi to be converted to number
get_num:
	getString	[ebp+36] 
	pop		esi
	xor		ebx, ebx 
	xor		eax, eax 
	xor		edx, edx 
	mov		[ebp+48], ebx ; sets number variable to 0
	jmp		through_string

; adds number to array, loops to get new number or jumps to end of procedure when array is filled  
final_num:
	mov		[edi], eax 
	add		edi, 4
	loop	get_num 
	jmp		end_read

; advances through string character by character
; with each character, checks if character is number and for sign 
; if character is a number, converted to number to be added to array  
through_string:
	lodsb
	cmp		ebx, 0 ; checks if al points to first character in string 
	jg		character_check
	cmp		al, 0 ; checks if string is empty
	je		error_message_3
	cmp		al, 43 ;checks if al == "+"
	je		positive_num
	cmp		al, 45 ;checks if al == "-"
	je		negative_num
	mov		ebx, 3
; checks if character is a number or another character. If not a number, jumps to error message.
character_check: 
	cmp		al, 0 ; checks if at end of string 
	je		end_string  
	cmp		al, 48 ;checks if al is not 0
	jl		error_message_3
	cmp		al, 57 ;checks if al is not 9
	jg		error_message_3 
; character is a valid character, converts to number value and moves to user_num variable on stack.
convert_character:
	push	ecx 
	sub		al, 48
	push	eax 
	mov		ecx, 10
	xor		edx, edx 
	mov		eax, [ebp+48]
	imul	ecx 
	cmp		edx, 0
	jnz		error_message_1
	mov		edx, eax 
	pop		eax 
	mov		ecx, eax 
	add		edx, ecx
	jo		error_message_2
	mov		[ebp+48], edx
	xor		eax, eax 
	pop		ecx
	jmp		through_string  

; end of string is reached, if number is negative it is converted if not it is added to array as present value 
end_string:
	mov		eax, [ebp+48]
	cmp		ebx, 1
	jg		final_num
	neg		eax
	jo		error_message_3
	jmp		final_num

; if string is negative, assigns ebx to one to comapare and negate later 
negative_num: 
	mov		ebx, 1
	jmp		through_string

; string entered is a positive number, ebx is set to 2 to keep number positive
positive_num:
	mov		ebx, 2
	jmp		through_string

; error message dispalyed if character is not a number or number too large for 32 bit register 	
error_message_1:
	pop		eax 
error_message_2:
	pop		ecx
error_message_3: 
	mov		edx, [ebp+32]
	call	WriteString 
	call	Crlf
	jmp		get_num

end_read:
	pop		ebp
	pop		ecx
	pop		ebx
	pop		eax 
	pop		edx 
	pop		esi	
	pop		edi
	ret		20
readVal	ENDP

;------------------------------------------------------------------------------
;writeVal 
;Procedure that converts users numbers to strings to be displayed. Calculates sum and mean and displays them as strings 
;recieves: address of number array, number string variable, nums entered, nums sum, nums mean, and space string 
;returns: numbers entered by user, there sum and there mean in string formate
;preconditions: user must have entered 10 valid numbers  
;postcontditions: none 
;registers changed: eax, ebx, ecx, edx, esi 
;------------------------------------------------------------------------------
writeVal PROC
	push	edi
	push	esi
	push	edx 
	push	ecx
	push	ebx
	push	eax
	push	ebp
	mov		ebp, esp
	call	Crlf
	mov		esi, [ebp+40] ; address of randomArray
	mov		ecx, [ebp+44] ; address of array size, used to loop through array 
	cld

; displays unsorted string  
	displayString		[ebp+36]
	call	Crlf
	jmp		display_nums

;displays sum string, makes loop stop  variable equal to 11. This is maakes it so sum to only be displayed once. 
sum_string:
	displayString	 [ebp+56] ; address of sum strung 
	mov		edx, 11
	mov		[ebp+68], edx 
	push	ecx
	mov		ecx, 0
	mov		ebx, 10
	jmp		get_char

; displays mean string, makes loop stop variable equal to 44. This makes it so mean is displayed once before advancing to end of program. 
mean_string:
	displayString	[ebp+60] ; address of mean string
	mov		edx, 44
	mov		[ebp+68], edx
	push	ecx
	mov		ecx, 0
	mov		ebx, 10
	jmp		get_char

; loads values in edi register to be converted to string 
; checks if number is negative, is so adds '-' as first character in string output 
; adds value to sum if number is positive, subtracts from sum if negative  
display_nums:
	lodsd
sum_mean:
	push	ecx
	mov		edi, [ebp+64] ; address of num string 
	test	eax, eax 
	jnl		positive_num ; checks if user number is negative
	neg		eax 
	sub		[ebp+48], eax ; tracks sum of numbers entered 
	push	eax 
	mov		eax, 45 ; moves negative sign into first byte of string 
	stosb
	pop eax 
	mov		ecx, 0
	mov		ebx, 10
	jmp		get_char
positive_num:
	add		[ebp+48], eax ; tracks sum of numbers entered 
	mov		ecx, 0
	mov		ebx, 10

; gets ASCII character for each number in users number 
get_char:
	xor     edx, edx 
	idiv	ebx
	add		edx, 48	
	push	edx
	inc		ecx
	cmp		eax, 0
	jne		get_char
	
; converts each ASCII character in users number to string 
; displays string along with space 
convert:
	pop		eax 
	stosb
	loop	convert 
	displayString	 [ebp+64] 
	displayString	[ebp+32] ; places space 
	mov		ecx, 11
	mov		al, 0
	rep		stosb
	mov		[ebp+64], edi
	pop		ecx 
	Loop	display_nums
	mov		edx, [ebp+68]
	cmp		edx, 44
	je		endDisplay
	cmp		edx, 11
	je		mean

; calcualtes sum of user numbers  
; test if sum is negative number, if so adds "-" to first bit of string and converts absolute value 
sum:
	call	Crlf
	call	Crlf
	mov		edx, [ebp+68]
	mov		eax, [ebp+48] ; address of sum
	mov		edi, [ebp+64] ; address of num string 
	test	eax, eax 
	jnl		positive_sum ; checks if user number is negative
	neg		eax 
	push	eax 
	mov		eax, 45 ; moves negative sign into first byte of string 
	stosb
	pop eax 
positive_sum:
	mov		ecx, 1
	cmp		edx, 11
	jne		sum_string

; calcualtes mean of user numbers  
; test if mean is negative number, if so adds "-" to first bit of string and converts absolute value 
mean:
	call	Crlf
	call	Crlf
	mov		eax, [ebp+48] ; address of sum
	mov		eax, [ebp+48] ; address of sum
	mov		edi, [ebp+64] ; address of num string 
	test	eax, eax 
	jnl		positive_mean ; checks if user number is negative
	neg		eax 
	push	eax 
	mov		eax, 45 ; moves negative sign into first byte of string 
	stosb
	pop eax 
positive_mean:
	xor     edx, edx 
	mov		ebx, 10
	idiv	ebx 
	mov		edx, [ebp+68]
	mov		ecx, 1
	cmp		edx, 44
	jne		mean_string

endDisplay:
	call	Crlf
	pop		ebp
	pop		eax 
	pop		ebx
	pop		ecx
	pop		edx
	pop		esi	
	pop		edi
	ret		40
writeVal ENDP


;------------------------------------------------------------------------------
;farewell 
;Procedure that displays farewell message for user 
;recieves: Address of goodbye string on stack 
;returns: goodbye message 
;preconditions: none
;postcontditions: none
;registers changed: ebp 
;------------------------------------------------------------------------------
 farewell PROC
	push	ebp
	mov		ebp, esp
	call	Crlf
	displayString		[ebp+8]
	pop		ebp
	ret		4
 farewell ENDP 


END main
	