.586
.model flat, c
option casemap :none

include longop.inc

.data

; used in StrDec proc
DivRemainder dd 0

.code

; Converts the given 32-bit float number into dec string.
; 1st arg = variable(32-bit) address [EBP + 12]
; 2nd arg = result string address [EBP + 8]
FloatToDec32 proc resultAddress : DWORD, variableAddress : DWORD

  ; 32-bit value has the following structure: [s{1}] [e{8}] [F{23}]
  ; M = 1.F
  ; E = e - 127

  ; RETRIEVE THE SIGN BIT
  ; the first character of the result string will contain the sign
  mov esi, variableAddress; dword ptr[EBP + 12] variable address
  mov edi, resultAddress; dword ptr[EBP + 8] result string address
  mov eax, dword ptr[esi] ; the variable itself
  and eax, 80000000h ; retrieve the sign bit
  cmp eax, 0
  je @floattodec32_sign_plus
  ; Sign (-)
  mov byte ptr[edi], '-'
  jmp @floattodec32_sign_done
@floattodec32_sign_plus: 
  mov byte ptr[edi], '+'
@floattodec32_sign_done:
  inc edi ; for the character that we've just put


  ; RETRIEVE THE EXPONENT
  mov eax, dword ptr[esi]
  and eax, 7F800000h ; 01111111100..0
  shr eax, 23 ; 32 - 8 - 1 = 23
  ; Now EAX holds the e

  cmp eax, 0
  je @floattodec32_e_not_normalized
  cmp eax, 0FFFFFFFFh
  je @floattodec32_e_inf_or_nan
  
  ; The value is good, proceed
  sub eax, 127 ; to get the E
  cmp eax, 0
  jg @floattodec32_retrieve_whole    
  je @floattodec32_whole_1
  ; Otherwise the whole part is 0
  mov word ptr[edi], "0"
  mov word ptr[edi + 1], "."
  add edi, 2 ; we just wrote two characters
  jmp @floattodec32_retrieve_fraction  
@floattodec32_whole_1:
  mov word ptr[edi], "1"
  mov word ptr[edi + 1], "."
  add edi, 2 ; we just wrote two characters
  jmp @floattodec32_retrieve_fraction


  ; RETRIEVE THE WHOLE PART  
@floattodec32_retrieve_whole:
  ; In EBX we will store the 100..0 value == the 1 from mantisa, but shifted according to E.
  ; In EDX we will generate(by shifting) the whole part without 1 that we will add to EBX to get the actual whole part.  
  ; As a result, EBX will contain the whole part

  ; Generate EBX
  mov ebx, 1  
  mov ecx, eax
  shl ebx, cl

  ; Generate EDX
  mov edx, dword ptr[esi] ; the variable
  and edx, 7fffffh ; 00000000011..1
  mov ecx, 23
  sub ecx, eax
  shr edx, cl

  ; Now combine them to get the actual whole part
  add ebx, edx

  push eax ; not to lose the E
  ; Now perform the division by 10 to retrieve dec digits from EBX
  mov eax, ebx ; the lower bits  
  mov ebx, 10
  xor ecx, ecx ; we will count the number of digits that we wrote(we'll need to reverse the string)
@floattodec32_retrieve_whole_loop:
  ; EAX is set either before the loop or as the result of the division
  xor edx, edx ; the higher bits are always 0    
  div ebx
  ; the remainder is in EDX
  add edx, 48 ; to get the code
  push edx ; temporary store the digit code in the stack  
  inc ecx

  cmp eax, 0 ; if the whole part of the division is 0 => finish
  jne @floattodec32_retrieve_whole_loop

  ; Now pop the digits from the stack and write them into memory
  ; ECX contains the amount of digits that we pushed
@floattodec32_retrieve_whole_pop_loop:
  pop edx
  mov byte ptr[edi], dl ; write to the result string
  inc edi

  dec ecx
  jnz @floattodec32_retrieve_whole_pop_loop


  ; finish => prepare for the fraction part
  mov byte ptr[edi], '.'
  inc edi
  pop eax ; get back the E


  ; RETRIEVE THE FRACTION PART
@floattodec32_retrieve_fraction:
  mov ebx, dword ptr[esi] ; the variable
  and ebx, 7fffffh ; 00000000011..1
  mov edx, 1
  shl edx, 23 ; the hidden 1 for mantisa
  add edx, ebx ; the actual mantisa

  ; Now shift it according to the value stored in EAX
  mov ecx, eax
  cmp eax, 0
  jg @floattodec32_retrieve_fraction_shl
  ; otherwise shr (or don't shift at all if eax == 0)  
  ; We also need to transform the negative value into its absolute value
  not ecx
  inc ecx
  shr edx, cl
  jmp @floattodec32_retrieve_fraction_shift_done
@floattodec32_retrieve_fraction_shl:
  shl edx, cl  
@floattodec32_retrieve_fraction_shift_done:
  ; Need to leave only the 23 bits of the mantisa, remove the part that became the whole part
  and edx, 07fffffh

  ; Now process it by multiplying by 10 to get dec digits
  ; We know the length of mantisa to be 1+23=24 bits
  ; Which means that we will be interested in the 4 bits(higher ones) after those 24  
  ; EDX contains the mantisa
  mov ecx, 6 ; how many digits to retrieve from the mantisa
@floattodec32_retrieve_fraction_loop:
  mov ebx, edx
  shl ebx, 1 ; *2
  mov eax, edx
  shl eax, 3 ; *8 
  add eax, ebx 
  ; Generate the new mantisa by keeping only the 24 bits
  mov edx, eax 
  and edx, 07fffffh ; 00000000011..1
  ; Now get the desired 4 bits from EAX
  shr eax, 23 
  add eax, 48 ; to get the code of the dec digit
  mov byte ptr[edi], al
  inc edi
  dec ecx
  jnz @floattodec32_retrieve_fraction_loop
  jmp @floattodec32_end


  ; SPECIAL CASES
@floattodec32_e_not_normalized:
  mov dword ptr[edi], "not "
  mov dword ptr[edi + 4], "norm"
  mov dword ptr[edi + 8], "aliz"
  mov dword ptr[edi + 12], "ed. "
  jmp @floattodec32_end

@floattodec32_e_inf_or_nan:
  mov dword ptr[edi], "inf "
  mov dword ptr[edi + 4], "or N"
  mov dword ptr[edi + 8], "aN. "  
  jmp @floattodec32_end

@floattodec32_end:
  ret 
FloatToDec32 endp



; 1st arg = result buffer address(string)[EPB+16]
; 2nd arg = variable address[EPB+12]
; 3rd arg = amount of bits(% 8 == 0)[EPB+8]
StrDec proc amountOfBits : DWORD, variableAddress : DWORD, resultAddress : DWORD
  
    mov ecx, amountOfBits; [ebp + 8] amount of bits of variable
    mov esi, variableAddress; [ebp + 12] variable address
    mov edi, resultAddress; [ebp + 16] result address
    xor eax, eax ; = 0 

    @next_integer_part:
    push eax ; for counting of symbols in stack(use also in GroupDiv proc, so need to save its value)
    mov ecx, amountOfBits; [ebp + 8] rewrite value of amount of bits(ECX is used in GroupDiv proc)

    push ecx ; amount of bits
    push esi ; operand address
    push edi ; result address
    push offset DivRemainder ; remainder address
    call GroupDiv10 
	add esp, 16

    pop eax ; restore value of EAX
    mov esi, resultAddress ; [ebp + 16] writes addreess of result, that divides in the next iteration
    mov edi, resultAddress; [ebp + 16] address of next result is the same(divides operand and writes integer part in the same place)
    mov ebx, DivRemainder ; writes remainder
    add ebx, 48 ; gets remainder in ASCII code 
    push ebx ; pushes remainder into stack
    inc eax ; counter of symbols in stack

    mov edx, amountOfBits; [ebp + 8] amount of bits
    shr edx, 5 ; amount of 32-bits groups
    @cmp_zero:
    cmp dword ptr [edi + edx * 4 - 4], 0 ; compares each 32-bits group with 0 to know, if integer part is not 0
    jne @next_integer_part ; = 0 => end of division
    dec edx ; next 32-bits group
    jnz @cmp_zero

    mov edx, eax ; counter of symbols in stack(use EAX in the next cycle, need to save its value)

    mov edi, resultAddress;
    @next_dec_symbol:
    pop ebx ; gets symbols from stack
    mov byte ptr [edi], bl ; writes symbol in result
    inc edi ; for writing of next symbol
    dec eax
    jnz @next_dec_symbol

    mov eax, edx ; restores amount of symbols in stack(value of EAX) 
    mov ebx, amountOfBits; [ebp + 8] amount of bits of operand
    shr ebx, 3 ; /8, now have amount of bytes 
    cmp eax, ebx ; comparison of amount of symbols of result and operand
    jge @endp_StrDec ; if less we need to fill rest of bytes with spaces
    sub ebx, eax ; amount of bytes need to be filled
    @next_emptiness:
    mov byte ptr [edi], ' ' ; filling with spaces
    inc edi ; next byte
    dec ebx
    jnz @next_emptiness

@endp_StrDec:
    ret 
StrDec endp

end