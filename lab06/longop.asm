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



; Shifts left N bits and fills the free space with the given string of bits. Expects the result to be clean(0s).
; 1st arg = integer length(in 4-byte chunks) [EBP + 24]
; 2nd arg = integer address [EBP + 20]
; 3rd arg = result address [EBP + 16]
; 4th arg = N (amount of bits to shift) [EBP + 12]
; 5th arg = string of bits address [EBP + 8]
ShlLongN proc
  push ebp
  mov ebp, esp
  
  ; SHIFT THE INTEGER ITSELF (whole chunks)
  mov esi, dword ptr[ebp + 20] ; source address == integer address
  mov edi, dword ptr[ebp + 16] ; destination address == result address  
  mov edx, dword ptr[ebp + 12] ; N
  shr edx, 5 ; /32 => integer shift (full chunks to shift)

  mov ecx, dword ptr[ebp + 24] ; chunks in the integer
  sub ecx, edx ; chunks that are left(not gone because of shifting)

  mov eax, edx
  shl eax, 2 ; *4
  add edi, eax ; manually shift the destination, so that we write starting from the highest chunks
@shl_long_move_integer_loop:
  mov ebx, dword ptr[esi + ecx * 4 - 4]  
  mov dword ptr[edi + ecx * 4 - 4], ebx

  dec ecx
  jnz @shl_long_move_integer_loop


  ; FILL THE INTEGER WITH THE CHUNKS(whole) FROM THE STRING
  ; if chunks == 0 then skip this part
  cmp edx, 0
  je @shl_long_move_string_loop_done

  mov esi, dword ptr[ebp + 8]  ; string address to fill with
  mov edi, dword ptr[ebp + 16] ; result address
  mov ecx, edx ; EDX contains amount of chunks that were shifted
@shl_long_move_string_loop:
  mov ebx, dword ptr[esi + ecx * 4] ; don't need -4 because the last[low] chunk is half-empty, we don't count it
  mov dword ptr[edi + ecx * 4 - 4], ebx

  dec ecx
  jnz @shl_long_move_string_loop
@shl_long_move_string_loop_done:


  ; SHIFT THE RIGHTMOST(HIGH) CHUNK OF THE INTEGER
  mov ebx, dword ptr[ebp + 24] ; integer length == result length
  mov esi, dword ptr[ebp + 16] ; result address  
  mov ecx, dword ptr[ebp + 12] ; N
  and ecx, 31 ; %32 => bits in one chunk to shift. (00011111b)
  shl dword ptr[esi + ebx * 4 - 4], cl ; shift the rightmost chunk  


  ; SHIFT ALL THE REMAINING CHUNKS IN A LOOP
  mov ebx, ecx ; in ecx we calculated the amount of bits to shift
  
  ; if ecx == 0 => skip this part
  cmp ecx, 0
  je @shl_long_shift_chunks_loop_done
  
  mov esi, dword ptr[ebp + 16] ; result address
  mov ecx, dword ptr[ebp + 24] ; integer length == result length
  dec ecx ; skip the last one(high) 
@shl_long_shift_chunks_loop:  
  mov edx, 32
  sub edx, ebx ; the chunk has to be shifted in the opposite direction in order to apply the mask for the previous chunk
  mov eax, dword ptr[esi + ecx * 4 - 4] ; the chunk we're working with (at first iteration it will be the one before the last(high))  
  push ecx  
  mov ecx, edx ; second operand for shift has to be CL
  shr eax, cl ; shift current chunk in the opposite direction
  pop ecx
  mov edx, dword ptr[esi + ecx * 4] ; previous(higher) chunk is +4 relative to the current chunk
  or edx, eax ; apply the mask stored in eax === put there the bits that will fall out because of shifting the current chunk
  mov dword ptr[esi + ecx * 4], edx ; put the previous(higher) chunk back into memory
  ; Now safely shift(because we've processed the bits that fall out) the current chunk(in memory)  
  push ecx
  mov eax, ecx ; used in the address for dword ptr two lines down
  mov ecx, ebx ; second operand for shift has to be CL
  shl dword ptr[esi + eax * 4 - 4], cl ; MAIN OPERATION. Amount of bits to shift is stored in EBX  
  pop ecx  

  dec ecx
  jnz @shl_long_shift_chunks_loop
@shl_long_shift_chunks_loop_done:


  ; FILL WITH BITS FROM THE STRING THE LAST(LOW) CHUNK IN THE INTEGER
  ; if ebx == 0 (so only whole chunks needed to be shifted) => skip this part
  cmp ebx, 0
  je @shl_long_fill_last_chunk_done

  ; We know for sure that the bits we need are in the last(lowest) chunk(both source and destination), so no shift in memory from the start
  mov esi, dword ptr[ebp + 8] ; string address  
  mov edi, dword ptr[ebp + 16] ; result address
  ; We also know that the last(lowest) chunk has already been shifted in the loop above
  ; The bits in the string that we need are in the higher part of the chunk
  mov eax, dword ptr[esi] ; the chunk from the string that wee need
  mov ecx, 32
  sub ecx, ebx ; same routine as before
  shr eax, cl ; We shift in the opposite direction
  mov edx, dword ptr[edi] ; the chunk in the integer that we are modifying
  or edx, eax ; apply the mask === put in the bits
  mov dword ptr[edi], edx ; put back into memory
@shl_long_fill_last_chunk_done:


  mov esp, ebp
  pop ebp
  ret 20 
ShlLongN endp


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