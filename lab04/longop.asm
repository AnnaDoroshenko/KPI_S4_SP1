.586
.model flat, c
.stack 4096


.code

; Adds two long integers. The low chunk is first in memory
; 1st arg = operands length (in 4-byte chunks) [EBP + 20]
; 2nd arg = first operand address [EBP + 16]
; 3rd arg = second operand address [EBP + 12]
; 4th arg = result operand address [EBP + 8]
AddLong proc
    push ebp
    mov ebp, esp

    ; Retrieve args
    mov ecx, [ebp + 20] ; amount of iterations
    mov esi, [ebp + 16] ; first operand address
    mov ebx, [ebp + 12] ; second operand address
    mov edi, [ebp + 8] ; result address

    ; Main loop
    clc    
    mov edx, 0
@cycle:
    mov eax, dword ptr[esi + 4 * edx]
    adc eax, dword ptr[ebx + 4 * edx]
    mov dword ptr[edi + 4 * edx], eax

    inc edx
    dec ecx
    jnz @cycle

    mov esp, ebp
    pop ebp
    ret 16
AddLong endp


; Adds two long integers. The low chunk is last in memory
; 1st arg = operands length (in 4-byte chunks) [EBP + 20]
; 2nd arg = first operand address [EBP + 16]
; 3rd arg = second operand address [EBP + 12]
; 4th arg = result operand address [EBP + 8]
AddLongProper proc
    push ebp
    mov ebp, esp

    ; Retrieve args
    mov ecx, [ebp + 20] ; amount of iterations
    mov esi, [ebp + 16] ; first operand address
    mov ebx, [ebp + 12] ; second operand address
    mov edi, [ebp + 8] ; result address

    ; Main loop
    clc    
    ;mov edx, 0
@cycle:
    mov eax, dword ptr[esi + 4 * ecx - 4]
    adc eax, dword ptr[ebx + 4 * ecx - 4]
    mov dword ptr[edi + 4 * ecx - 4], eax

    ;inc edx
    dec ecx
    jnz @cycle

    mov esp, ebp
    pop ebp
    ret 16
AddLongProper endp


; Subtracts two long integers. The low chunk is first in memory
; 1st arg = operands length (in 4-byte chunks) [EBP + 20]
; 2nd arg = first operand address [EBP + 16]
; 3rd arg = second operand address [EBP + 12]
; 4th arg = result operand address [EBP + 8]
SubLong proc
    push ebp
    mov ebp, esp

    ; Retrieve args
    mov ecx, [ebp + 20] ; amount of iterations
    mov esi, [ebp + 16] ; first operand address
    mov ebx, [ebp + 12] ; second operand address
    mov edi, [ebp + 8] ; result address

    ; Main loop
    clc    
    mov edx, 0
@cycle2:
    mov eax, dword ptr[esi + 4 * edx]
    sbb eax, dword ptr[ebx + 4 * edx]
    mov dword ptr[edi + 4 * edx], eax

    inc edx
    dec ecx
    jnz @cycle2

    mov esp, ebp
    pop ebp
    ret 16
SubLong endp

end