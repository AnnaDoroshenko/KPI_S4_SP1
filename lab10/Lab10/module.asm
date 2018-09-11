.586
.model flat, c
option casemap :none

include longop.inc

.data
; used in StrDec proc
DivRemainder dd 0

.code


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





; 1st arg = result buffer address(string)
; 2nd arg = variable address
; 3rd arg = amount of bits(% 8 == 0)
StrHex_MY proc amountOfBits : DWORD, variableAddress : DWORD, resultAddress : DWORD

    mov ecx, amountOfBits; [ebp+8] amount of bits
    cmp ecx, 0
    jle @exitp
    shr ecx, 3 ; now contains amount of bytes
    mov esi, variableAddress; [ebp+12] number address
    mov ebx, resultAddress; [ebp+16] result buffer address
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
    ret 
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