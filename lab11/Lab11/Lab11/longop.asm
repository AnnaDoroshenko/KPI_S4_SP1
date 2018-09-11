.586
.model flat, c
.stack 4096

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

end
