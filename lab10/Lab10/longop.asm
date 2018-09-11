.586
.model flat, c
.stack 4096

.data

  BufferChunksAmount equ 19
  Buffer dd BufferChunksAmount dup(0)
  BufferSize equ $ - Buffer

  Buffer2ChunksAmount equ 19
  Buffer2 dd Buffer2ChunksAmount dup(0)
  Buffer2Size equ $ - Buffer2


.code

 

; Group division N:16 (by 10)
; 1st arg = operand length(in bits) [EBP + 20]
; 2nd arg = operand address [EBP + 16]
; 3rd arg = result address [EBP + 12]
; 4th arg = remainder address [EBP + 8]
GroupDiv10 proc remainderAddress : DWORD, resultAddress : DWORD, operandAddress : DWORD, operandLength : DWORD

  mov ecx, operandLength; [ebp + 20] operand length in bits
  cmp ecx, 0
  jle @exit_proc2
  shr ecx, 4 ; amount of 16-bits groups 
  mov esi, operandAddress; [ebp + 16] operand address
  mov edi, resultAddress; [ebp + 12] result address

  xor dx, dx ; = 0
  mov bx, 10 ; second operand (1010b)
  @next_loop_of_div:
  mov ax, word ptr [esi + 2 * ecx - 2]; first 16-bits group of first operand [esi + (ecx-1) * 2]
  div bx ; division to 10
  mov word ptr [edi + 2 * ecx - 2], ax ; writes integer part after division
  dec ecx ; goes to the next 16-bits group till = 0
  jnz @next_loop_of_div
  mov ebx, remainderAddress; [ebp + 8] address of remainder
  mov word ptr [ebx], dx ; writes remainder in right address 

@exit_proc2:
  ret 
GroupDiv10 endp





; Multiplies two long integers, where the second one is 32 bit
; 1st arg = first operand length (in 4-byte chunks) [EBP + 20]
; 2nd arg = first operand address [EBP + 16]
; 3rd arg = second operand(32 bit) [EBP + 12]
; 4th arg = result operand address [EBP + 8]
MulLong32 proc resultAddress : DWORD, secondOperand : DWORD, firstAddress : DWORD, operandLength : DWORD

  ; Retrieve args
  mov ebx, operandLength; [ebp + 20] first operand length  
  mov esi, firstAddress; [ebp + 16] first operand address  

  ; Current shift(in chunks) from the beginning(higher chunks)
  xor ecx, ecx ; = 0
  inc ebx ; result length = first op length + 1 (in chunks)

@mul_long_32_loop:
  ; Multiply
  mov eax, secondOperand; [ebp + 12] second operand(32 bit)
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
  push resultAddress; [ebp + 8] result address
  push resultAddress; [ebp + 8] result address
  call AddLong
  add esp, 16

  pop ecx
  pop ebx
  pop esi

  ; Prepare for next interation
  inc ecx
  cmp ecx, operandLength; dword ptr[ebp + 20]
  jl @mul_long_32_loop  

  ret 
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
AddLong proc resultAddress : DWORD, secondAddress : DWORD, firstAddress: DWORD, operandLength : DWORD

    ; Retrieve args
    mov ecx, operandLength; [ebp + 20] amount of iterations
    mov esi, firstAddress; [ebp + 16] first operand address
    mov ebx, secondAddress; [ebp + 12] second operand address
    mov edi, resultAddress; [ebp + 8] result address

	cmp ecx, 0
	jle @endAdd

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

@endAdd:
    ret 
AddLong endp





; Subtracts two long integers. The low chunk is first in memory
; 1st arg = operands length (in 4-byte chunks) [EBP + 20]
; 2nd arg = first operand address [EBP + 16]
; 3rd arg = second operand address [EBP + 12]
; 4th arg = result operand address [EBP + 8]
SubLong proc resultAddress : DWORD, secondAddress : DWORD, firstAddress: DWORD, operandLength : DWORD

    ; Retrieve args
    mov ecx, operandLength; [ebp + 20] amount of iterations
    mov esi, firstAddress; [ebp + 16] first operand address
    mov ebx, secondAddress; [ebp + 12] second operand address
    mov edi, resultAddress; [ebp + 8] result address

	cmp ecx, 0
	jle @endSub

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

@endSub:
    ret 
SubLong endp

end