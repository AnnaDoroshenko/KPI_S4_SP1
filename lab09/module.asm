.586
.model flat, c

include longop.inc

.data
; used in StrDec proc
DivRemainder dd 0

.code

; Converts the given 32-bit float number into dec string.
; 1st arg = variable(32-bit) address [EBP + 12]
; 2nd arg = result string address [EBP + 8]
FloatToDec32 proc
  push ebp
  mov ebp, esp

  ; 32-bit value has the following structure: [s{1}] [e{8}] [F{23}]
  ; M = 1.F
  ; E = e - 127

  ; RETRIEVE THE SIGN BIT
  ; the first character of the result string will contain the sign
  mov esi, dword ptr[EBP + 12] ; variable address
  mov edi, dword ptr[EBP + 8] ; result string address
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

  mov esp, ebp
  pop ebp
  ret 8
FloatToDec32 endp






; Converts the given 64-bit float number into dec string.
; 1st arg = variable(64-bit) address [EBP + 12]
; 2nd arg = result string address [EBP + 8]
FloatToDec64 proc
  push ebp
  mov ebp, esp

  ; 64-bit value has the following structure: [s{1}] [e{11}] [F{52}]
  ; M = 1.F
  ; E = e - 1023
  ; The bytes are stored in memory in reverse order, so the sign bit is in the last(highest) byte

  ; RETRIEVE THE SIGN BIT
  ; the first character of the result string will contain the sign
  mov esi, dword ptr[EBP + 12] ; variable address
  mov edi, dword ptr[EBP + 8] ; result string address
  mov eax, dword ptr[esi + 4] ; the first half of the variable
  and eax, 80000000h ; retrieve the sign bit
  cmp eax, 0
  je @floattodec64_sign_plus
  ; Sign (-)
  mov byte ptr[edi], '-'
  jmp @floattodec64_sign_done
@floattodec64_sign_plus: 
  mov byte ptr[edi], '+'
@floattodec64_sign_done:
  inc edi ; for the character that we've just put


  ; RETRIEVE THE EXPONENT
  mov eax, dword ptr[esi + 4] ; the first half of the variable
  and eax, 7FF00000h ; 01{11}00..0
  shr eax, 20 ; 32 - 11 - 1 = 20
  ; Now EAX holds the e

  cmp eax, 0
  je @floattodec64_e_not_normalized
  cmp eax, 0FFFFFFFFh
  je @floattodec64_e_inf_or_nan
  
  ; The value is good, proceed
  sub eax, 1023 ; to get the E
  cmp eax, 0
  jg @floattodec64_retrieve_whole    
  je @floattodec64_whole_1
  ; Otherwise the whole part is 0
  mov word ptr[edi], "0"
  mov word ptr[edi + 1], "."
  add edi, 2 ; we just wrote two characters
  jmp @floattodec64_retrieve_fraction  
@floattodec64_whole_1:
  mov word ptr[edi], "1"
  mov word ptr[edi + 1], "."
  add edi, 2 ; we just wrote two characters
  jmp @floattodec64_retrieve_fraction


  ; RETRIEVE THE WHOLE PART  
@floattodec64_retrieve_whole:
  ; We know for sure that if we are in this section => the E is positive => shl.
  ; In EBX we will store the 100..0 value == the 1 from mantisa, but shifted according to E.
  ; In EDX we will generate(by shifting) the whole part without 1 that we will add to EBX to get the actual whole part.    
  ; As a result, EBX will contain the whole part.
  ; We assume(simplify our task) that the required shifting is within one chunk.

  ; Generate EBX
  mov ebx, 1  
  mov ecx, eax
  shl ebx, cl

  ; Generate EDX
  mov edx, dword ptr[esi + 4] ; the first half of the variable
  and edx, 0fffffh ; 0{12}11..1
  mov ecx, 20 ; 32 - 11 - 1 = 20
  sub ecx, eax
  shr edx, cl

  ; Now combine them to get the actual whole part
  add ebx, edx

  push eax ; not to lose the E
  ; Now perform the division by 10 to retrieve dec digits from EBX
  mov eax, ebx ; the lower bits  
  mov ebx, 10
  xor ecx, ecx ; we will count the number of digits that we wrote(we'll need to reverse the string)
@floattodec64_retrieve_whole_loop:
  ; EAX is set either before the loop or as the result of the division
  xor edx, edx ; the higher bits are always 0    
  div ebx
  ; the remainder is in EDX
  add edx, 48 ; to get the code
  push edx ; temporary store the digit code in the stack  
  inc ecx

  cmp eax, 0 ; if the whole part of the division is 0 => finish
  jne @floattodec64_retrieve_whole_loop

  ; Now pop the digits from the stack and write them into memory
  ; ECX contains the amount of digits that we pushed
@floattodec64_retrieve_whole_pop_loop:
  pop edx
  mov byte ptr[edi], dl ; write to the result string
  inc edi

  dec ecx
  jnz @floattodec64_retrieve_whole_pop_loop


  ; finish => prepare for the fraction part
  mov byte ptr[edi], '.'
  inc edi
  pop eax ; get back the E



  ; RETRIEVE THE FRACTION PART
  ; EAX contains the E
@floattodec64_retrieve_fraction:
  ; 52 bits of mantisa = 32 + 20 
  mov ebx, dword ptr[esi + 4] ; the first half of the variable
  and ebx, 0fffffh ; 0{12}1{20}
  or ebx, 0100000h ; the hidden 1 for mantisa
  mov edx, dword ptr[esi] ; the second half of the variable

  ; Now shift it according to the value stored in EAX  
  mov ecx, eax
  cmp ecx, 0
  jg @floattodec64_retrieve_fraction_shl
  je @floattodec64_retrieve_fraction_shift_done
  ; shift right

  ; We also need to transform the negative value into absolute value
  not ecx
  inc ecx

  @floattodec64_retrieve_fraction_shift_loop1:
    shr edx, 1
    shr ebx, 1
    jnc @floattodec64_retrieve_fraction_shift_loop1_0
    or edx, 80000000h ; 100..0
  @floattodec64_retrieve_fraction_shift_loop1_0: ; don't need to do anything, 0 is already there
    dec ecx
    jnz @floattodec64_retrieve_fraction_shift_loop1
    
  jmp @floattodec64_retrieve_fraction_shift_done
@floattodec64_retrieve_fraction_shl:

  ; shift left
  @floattodec64_retrieve_fraction_shift_loop2:
    shl ebx, 1
    shl edx, 1
    jnc @floattodec64_retrieve_fraction_shift_loop2_0
    inc ebx ; put 1 there
  @floattodec64_retrieve_fraction_shift_loop2_0: ; don't need to do anything, 0 is already there
    dec ecx
    jnz @floattodec64_retrieve_fraction_shift_loop2


@floattodec64_retrieve_fraction_shift_done:  
  ; Need to leave only the 20 bits(first half of the variable) of the mantisa, remove the part that became the whole part
  and ebx, 0FFFFFh

  ; Now process it by multiplying by 10 to get dec digits
  ; We know the length of mantisa to be 20 + 32 bits. We only care about the 20, the other chunk will just get shifted from.  
  ; There will appear additional 4 bits in front of those 20, we will be processing them.
  ; EBX contains the first half of the mantisa
  ; EDX contains the second half of the mantisa
  mov ecx, 6; how many chars to retrieve from the mantisa
@floattodec64_retrieve_fraction_loop:
  push ecx

  mov eax, edx
  shl eax, 3
  shl edx, 1
  
  
  ; retrieve the 3 bits that fall out
  mov ecx, edx
  and ecx, 0E0000000h ; 11100..0
  shr ecx, 29 ; 32 - 3 = 29
  shl ebx, 3
  add ebx, ecx ; put there the 3 bits
  mov ecx, ebx
  shr ecx, 2 ; so get the same result as ebx shifted once
  
  ; now perform the addition of the *2 and *8 partial results
  ; EDX = 2nd half *2
  ; EAX = 2nd half *8
  ; EBX = 1st half *8
  ; ECX = 1st half *2
  add edx, eax
  adc ebx, ecx

  ; Generate the new mantisa by keeping only the 20 bits
  mov eax, ebx
  and ebx, 0FFFFFh

  ; Now get the desired 4 bits from EAX
  shr eax, 20 
  add eax, 48 ; to get the code of the dec digit
  mov byte ptr[edi], al
  inc edi

  pop ecx
  dec ecx
  jnz @floattodec64_retrieve_fraction_loop

  jmp @floattodec64_end


  ; SPECIAL CASES
@floattodec64_e_not_normalized:
  mov dword ptr[edi], "not "
  mov dword ptr[edi + 4], "norm"
  mov dword ptr[edi + 8], "aliz"
  mov dword ptr[edi + 12], "ed. "
  jmp @floattodec64_end

@floattodec64_e_inf_or_nan:
  mov dword ptr[edi], "inf "
  mov dword ptr[edi + 4], "or N"
  mov dword ptr[edi + 8], "aN. "  
  jmp @floattodec64_end

@floattodec64_end:

  mov esp, ebp
  pop ebp
  ret 8
FloatToDec64 endp




; 1st arg = result buffer address(string)[EPB+16]
; 2nd arg = variable address[EPB+12]
; 3rd arg = amount of bits(% 8 == 0)[EPB+8]
StrDec proc
    push ebp
    mov ebp, esp
 
    mov ecx, [ebp + 8] ; amount of bits of variable
    mov esi, [ebp + 12] ; variable address
    mov edi, [ebp + 16] ; result address
    xor eax, eax ; = 0 

    @next_integer_part:
    push eax ; for counting of symbols in stack(use also in GroupDiv proc, so need to save its value)
    mov ecx, [ebp + 8] ; rewrite value of amount of bits(ECX is used in GroupDiv proc)

    push ecx ; amount of bits
    push esi ; operand address
    push edi ; result address
    push offset DivRemainder ; remainder address
    call GroupDiv10 
    ;call LongDiv10

    pop eax ; restore value of EAX
    mov esi, [ebp + 16] ; writes addreess of result, that divides in the next iteration
    mov edi, [ebp + 16] ; address of next result is the same(divides operand and writes integer part in the same place)
    mov ebx, DivRemainder ; writes remainder
    add ebx, 48 ; gets remainder in ASCII code 
    push ebx ; pushes remainder into stack
    inc eax ; counter of symbols in stack

    mov edx, [ebp + 8] ; amount of bits
    shr edx, 5 ; amount of 32-bits groups
    @cmp_zero:
    cmp dword ptr [edi + edx * 4 - 4], 0 ; compares each 32-bits group with 0 to know, if integer part is not 0
    jne @next_integer_part ; = 0 => end of division
    dec edx ; next 32-bits group
    jnz @cmp_zero

    mov edx, eax ; counter of symbols in stack(use EAX in the next cycle, need to save its value)

    @next_dec_symbol:
    pop ebx ; gets symbols from stack
    mov byte ptr [edi], bl ; writes symbol in result
    inc edi ; for writing of next symbol
    dec eax
    jnz @next_dec_symbol

    mov eax, edx ; restores amount of symbols in stack(value of EAX) 
    mov ebx, [ebp + 8] ; amount of bits of operand
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
    mov esp, ebp
    pop ebp
    ret 12
StrDec endp


; 1st arg = result buffer address(string)
; 2nd arg = variable address
; 3rd arg = amount of bits(% 8 == 0)
StrBin proc
    push ebp
    mov ebp, esp

    mov ecx, [ebp + 8] ; amount of bits
    cmp ecx, 0
    jle exitp
    shr ecx, 3 ; now contains amount of bytes
    mov esi, [ebp + 12] ; number address
    mov ebx, [ebp + 16] ; result buffer address
cycle:    
    mov dl, byte ptr[esi + ecx - 1] ; 1 byte == 2 4-bit groups
    ; we go from the end to the beginning (+3 -> +0)
    
    ; Higher group
    mov al, dl
    shr al, 4 ; to get higher digit at the beginning
    push ebx
    call Get4Bits
    add ebx, 4
    ;mov byte ptr[ebx], al

    ; Lower group
    mov al, dl
    push ebx
    call Get4Bits
    add ebx, 4
    ;mov byte ptr[ebx+1], al

    dec ecx
    ;mov eax, ecx
    cmp ecx, 0
    je exitp ; don't put a ' ' (becase it's the end)
    ; otherwise put a ' '
    mov byte ptr[ebx], 32 ; code of ' '
    inc ebx
    jmp cycle


    ;mov eax, ecx
    ;cmp eax, 1
    ;jle @next ; no jump => more than 2 bytes(4 4-bit groups) left
    ;dec eax
    ;and eax, 1 ; 0...01, so the last digit, so 0 or 1
    ;cmp al, 0 ; if there is a 0 => the number of bytes % 2 == 0 => put a separator (groups of 4 digits)
    ;jne @next ; no need for a separator
    ;mov byte ptr[ebx+2], 32 ; code of ' '
    ;inc ebx ; for the ' '

;@next:
    ;add ebx, 2 ; wrote 2 new symbols
    ;dec ecx ; move to the next byte(earlier in memory)
    ;jnz @cycle
    ;mov byte ptr[ebx], 0 ; finish string with 0
exitp:
    mov esp, ebp
    pop ebp
    ret 12
StrBin endp

; converts 4-bit number [in AL]
; arg = destination offset [IN STACK]
Get4Bits proc    
    push ebx
    push ecx

    mov ebx, [esp + 12] ; destination offset    
    add ebx, 3 ; start from the end
    mov ecx, 4
    and al, 00001111b

next_bit:
    shr al, 1
    jc bit_1
bit_0:
    mov byte ptr[ebx], 48 ; '0'
    jmp done
bit_1:   
    mov byte ptr[ebx], 49 ; '1'
done:
    dec ebx
    loop next_bit

    pop ecx
    pop ebx
    ret 4
Get4Bits endp


; 1st arg = result buffer address(string)
; 2nd arg = variable address
; 3rd arg = amount of bits(% 8 == 0)
StrHex_MY proc
    push ebp
    mov ebp, esp
    mov ecx, [ebp+8] ; amount of bits
    cmp ecx, 0
    jle @exitp
    shr ecx, 3 ; now contains amount of bytes
    mov esi, [ebp+12] ; number address
    mov ebx, [ebp+16] ; result buffer address
@cycle:    
    mov dl, byte ptr[esi+ecx-1] ; 1 byte == 2 hex-symbols
    ; we go from the end to the beginning (+3 -> +0)
    
    ; First digit
    mov al, dl
    shr al, 4 ; to get higher digit at the beginning
    call HexSymbol_MY
    mov byte ptr[ebx], al

    ; Second digit
    mov al, dl ; lower digit
    call HexSymbol_MY
    mov byte ptr[ebx+1], al

    mov eax, ecx
    cmp eax, 4
    jle @next ; no jump => more than 4 bytes(8 symbols) left
    dec eax
    and eax, 3 ; 0...11, so the last digit, so 0 or 1
    cmp al, 0 ; if there is a 0 => the number of bytes % 4 == 0 => put a separator (groups of 8 digits)
    jne @next ; no need for a separator
    mov byte ptr[ebx+2], 32 ; code of ' '
    inc ebx ; for the ' '

@next:
    add ebx, 2 ; wrote 2 new symbols
    dec ecx ; move to the next byte(earlier in memory)
    jnz @cycle
    ;mov byte ptr[ebx], 0 ; finish string with 0
@exitp:
    pop ebp
    ret 12
StrHex_MY endp

; calculate code of hex-digit
; arg = value of AL
; result -> AL
HexSymbol_MY proc
    and al, 0Fh
    add al, 48 ; 0-9
    cmp al, 58
    jl @exitp
    add al, 7 ; A-F
@exitp:
    ret
HexSymbol_MY endp

end