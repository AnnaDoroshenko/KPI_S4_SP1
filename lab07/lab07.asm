.586
.model flat, stdcall
option casemap :none
.stack 4096

include D:\Programs\masm32\include\windows.inc
include D:\Programs\masm32\include\user32.inc
include D:\Programs\masm32\include\kernel32.inc
include D:\Programs\masm32\include\gdi32.inc

include module.inc
include longop.inc

includelib D:\Programs\masm32\lib\user32.lib
includelib D:\Programs\masm32\lib\kernel32.lib
includelib D:\Programs\masm32\lib\gdi32.lib


.data

; n! == 62! == ^85 <= 288 bits (9*32)

; EQUs FOR SIZE
FactorialNGroupsOf32 equ 9 ; amount of groups of 32 bits
FormulaSize equ 32 ; amount of bits for interger and remainder parts

; INPUT VALUES  
ValueN dd 62
Value_X dd 100000
Value_Y dd 0
Value_m dd 01h
Value_Remainder dd 0

;TEST VALUES
Operand dd 110101110101b

; RESULTS
ResultNFactorial dd FactorialNGroupsOf32 dup(0)
ResultNFactorialSize equ $ - ResultNFactorial

ResultDiv10 dd FactorialNGroupsOf32 dup(0)
ResultDiv10Size equ $ - ResultDiv10

ResultDiv10Remainder dd 0

; HEADERS
BoxHeaderDiv10 db "Factorial in the decimal system", 0 
BoxHeaderFormula db "Result of calculating the formula", 0

; CONTENT
BoxContentTest db 10 dup(' '), 0 
BoxContentDiv10 db FactorialNGroupsOf32 * (10) dup(' '), 0
BoxContentFormula db "Integer part: ", FormulaSize dup(' '), 13, 10,
                     "Remainder part: ", FormulaSize dup(' '), 13, 10, 0

FormulaIntegerShift equ 14
FormulaIntegerLength equ (FormulaIntegerShift + FormulaSize + 2)
FormulaRemainderShift equ 16


.code
start:

  ; MUL n!
@mul_n_factorial:
  push ValueN
  push FactorialNGroupsOf32
  push offset ResultNFactorial
  call FactorialLong

  push offset BoxContentDiv10
  push offset ResultNFactorial
  push ResultNFactorialSize * 8
  call StrDec

  invoke MessageBoxA, 0, addr BoxContentDiv10, addr BoxHeaderDiv10, MB_ICONINFORMATION

 ;jmp @end

  ;push 12
  ;push offset Operand
  ;push offset BoxContentTest
  ;push offset ResultDiv10Remainder
  ;call LongDiv10

  ;invoke MessageBoxA, 0, addr BoxContentTest, addr BoxHeaderDiv10, MB_ICONINFORMATION

 ;jmp @end

  ; Calculating the formula
  xor edx, edx ; = 0 (higher bits of divided)
  mov eax, dword ptr [Value_X] ; lower bits of divided
  cdq ; converts doubleword to quadword (extends the sign bit of EAX into the EDX)
  mov ecx, dword ptr [Value_m] 
  add ecx, 3 ; m+3(power of 2)
  @next_power:
  shl edx, 1
  shl eax, 1
  jnc @clear_SignFlag ; jump if not carry
  inc edx ; carries 1 from EAX
  @clear_SignFlag:
  dec ecx
  jnz @next_power
  mov ebx, dword ptr [Value_X] 
  add ebx, 4 ; forms divider
  idiv ebx ; division
  mov dword ptr [Value_Y], eax ; integer part
  mov dword ptr [Value_Remainder], edx ; remainder part
  

  mov eax, offset BoxContentFormula
  add eax, FormulaIntegerShift
  push eax
  push offset Value_Y
  push FormulaSize
  call StrDec

  mov eax, offset BoxContentFormula
  add eax, FormulaIntegerLength
  add eax, FormulaRemainderShift
  push eax
  push offset Value_Remainder
  push FormulaSize
  call StrDec

  invoke MessageBoxA, 0, addr BoxContentFormula, addr BoxHeaderFormula, MB_ICONINFORMATION

@end:

  invoke ExitProcess, 0  

end start




