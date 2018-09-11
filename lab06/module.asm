.586
.model flat, c

.code

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