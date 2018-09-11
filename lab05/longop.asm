.586
.model flat, c
.stack 4096

.data

  BufferChunksAmount equ 13
  Buffer dd BufferChunksAmount dup(0)
  BufferSize equ $ - Buffer

  Buffer2ChunksAmount equ 13
  Buffer2 dd Buffer2ChunksAmount dup(0)
  Buffer2Size equ $ - Buffer2

.code

; Calculates the factorial of the given integer(N)
; 1st arg = N [EBP + 16]
; 2nd arg = result length(in 4-byte chunks) [EBP + 12]
; 3rd arg = result address [EBP + 8]
FactorialLong proc
  push ebp
  mov ebp, esp
  
  mov ecx, dword ptr[ebp + 16] ; iterator

  mov eax, dword ptr[ebp + 8] ; result address
  mov dword ptr[eax], ecx
  dec ecx ; because we already wrote 1 iteration into the result

@factorial_long_loop:
  push ecx

  push offset Buffer2
  call ClearBuffer

  ; Do the factorial step (result * ecx)
  push dword ptr[ebp + 12] ; first operand(result) length
  push dword ptr[ebp + 8]  ; first operand(result) address
  push ecx                 ; second operand 
  push offset Buffer2      ; result address
  call MulLong32

  ; Move the Buffer2 into the result
  mov ecx, dword ptr[ebp + 12] ; chunks amount    
  mov esi, offset Buffer2
  mov edi, dword ptr[ebp + 8]
@factorial_move_loop:  
  dec ecx
  mov eax, dword ptr[esi + 4 * ecx]  
  mov dword ptr[edi + 4 * ecx], eax  
  jnz @factorial_move_loop

  pop ecx
  dec ecx
  jnz @factorial_long_loop

  pop ebp
  ret 12
FactorialLong endp




; Multiplies two long integers
; 1st arg = first operand length (in 4-byte chunks) [EBP + 24]
; 2nd arg = first operand address [EBP + 20]
; 3rd arg = second operand length (in 4-byte chunks) [EBP + 16]
; 4th arg = second operand address [EBP + 12]
; 5th arg = result operand address [EBP + 8]
MulLong proc
  push ebp
  mov ebp, esp

  xor ebx, ebx ; = 0. Chunk index of second operand

@mul_long_loop:   
  push offset Buffer2
  call ClearBuffer
  
  push ebx
  ; Mul one chunk of second agrument and write into Buffer2 with proper shift
  push dword ptr[ebp + 24]
  push dword ptr[ebp + 20]

  mov eax, dword ptr[ebp + 12] ; second operand address
  push dword ptr[eax + 4 * ebx] ; the chunk in second operand(32-bit integer itself)
  
  mov eax, ebx
  shl eax, 2 ; *4
  add eax, offset Buffer2
  push eax ; [Buffer2 + ebx * 4]. So we will have chunks of 0s at the start(low chunks)
  
  call MulLong32
  pop ebx


  push ebx  
  ; Add this result to the current sum(stored in the result)  
  mov eax, dword ptr[ebp + 24] ; first operand length
  shl eax, 1 ; max possible operand length(in buffer)
  push eax

  push offset Buffer2 ; first operand
  push dword ptr[ebp + 8] ; second operand address == result address
  push dword ptr[ebp + 8] ; result address
  call AddLong
  pop ebx
  
  inc ebx
  cmp ebx, dword ptr[EBP + 16]
  jl @mul_long_loop

  pop ebp
  ret 20
MulLong endp


; Multiplies two long integers, where the second one is 32 bit
; 1st arg = first operand length (in 4-byte chunks) [EBP + 20]
; 2nd arg = first operand address [EBP + 16]
; 3rd arg = second operand(32 bit) [EBP + 12]
; 4th arg = result operand address [EBP + 8]
MulLong32 proc
  push ebp
  mov ebp, esp

  ; Retrieve args
  mov ebx, [ebp + 20] ; first operand length  
  mov esi, [ebp + 16] ; first operand address  

  ; Current shift(in chunks) from the beginning(higher chunks)
  xor ecx, ecx ; = 0
  inc ebx ; result length = first op length + 1 (in chunks)

@mul_long_32_loop:
  ; Multiply
  mov eax, dword ptr[ebp + 12] ; second operand(32 bit)
  mul dword ptr[esi + ecx * 4] ; first operand

  ; Move the result to the buffer (using EAX:EDX)
  push ecx
  call FillBuffer

  push esi
  push ebx
  push ecx

  ; Add the buffer to the current sum
  push ebx
  push offset Buffer
  push dword ptr[ebp + 8] ; result address
  push dword ptr[ebp + 8] ; result address
  call AddLong

  pop ecx
  pop ebx
  pop esi

  ; Prepare for next interation
  inc ecx
  cmp ecx, dword ptr[ebp + 20]
  jl @mul_long_32_loop  

  pop ebp
  ret 16
MulLong32 endp


; Fills the Buffer with the given integer(64 bit EAX:EDX) surrounded by 0s
; 1st arg = chunks shift from the beginning [EBP + 8]
FillBuffer proc
  push ebp
  mov ebp, esp

  push ebx
  ; Retrieve args  
  mov ebx, [ebp + 8] ; chunks shift from the beginning  

  ; Fill the buffer
  push offset Buffer
  call ClearBuffer  
  mov dword ptr[Buffer + 4 * ebx], eax     ; lower
  mov dword ptr[Buffer + 4 * ebx + 4], edx ; higher

  pop ebx

  mov esp, ebp
  pop ebp
  ret 4
FillBuffer endp



; Clears the Buffer with 0s. Does not alter registers
; 1st arg = Buffer address [EBP + 8]
ClearBuffer proc
  push ebp
  mov ebp, esp

  push ecx
  push ebx

  mov ebx, dword ptr[ebp + 8]

  mov ecx, 0
@clear_loop:
  mov dword ptr[ebx + 4 * ecx], 0
  inc ecx
  cmp ecx, BufferChunksAmount
  jl @clear_loop

  pop ebx
  pop ecx

  mov esp, ebp
  pop ebp
  ret 4
ClearBuffer endp


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