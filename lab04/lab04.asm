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

  ; DATA ADDITION
  ValueAddA dd 80010001h, 80020001h, 80030001h, 80040001h, 15 dup (0)  
  ValueAddASize equ $ - ValueAddA
  ValueAddAShift equ 16 ; bytes
  
  ValueAddB dd 19 dup (80000001h)

  ResultAdd dd 19 dup(0)
  ResultAddSize equ $ - ResultAdd


  ; DATA SUBTRACTION
  ValueSubA dd 16 dup(0)

  ValueSubB dd 16 dup(0)
  ValueSubBSize equ $ - ValueSubB

  ResultSub dd 16 dup(0)
  ResultSubSize equ $ - ResultSub


  ; HEADERS
  BoxHeaderAdd db "Result of addition", 0
  BoxHeaderSub db "Result of subtraction", 0 

  ; CONTENT
  BoxContentAdd db  3*ResultAddSize dup(0), 0  
  BoxContentSub db  3*ResultSubSize dup(0), 0  


.code
start:

  ; Generate ValueAddA && ValueSubB  
  mov ecx, 0 
  mov eax, 17 ; starting value to put
@generate_loop:
@write_value_a:
  cmp ecx, 14
  jg @write_value_b

  mov dword ptr[ValueAddA + ValueAddAShift + ecx * 4], eax

@write_value_b:
  mov dword ptr[ValueSubB + ecx * 4], eax

  inc ecx
  inc eax

  cmp ecx, 16
  jl @generate_loop 
@generate_loop_done:


  ; ADDITION
  push 19
  push offset ValueAddA
  push offset ValueAddB
  push offset ResultAdd
  call AddLong

  push offset BoxContentAdd
  push offset ResultAdd
  push ResultAddSize * 8
  call StrHex_MY
  invoke MessageBoxA, 0, addr BoxContentAdd, addr BoxHeaderAdd, MB_ICONINFORMATION

  ; SUBTRACTION
  push 16
  push offset ValueSubA
  push offset ValueSubB
  push offset ResultSub
  call SubLong

  push offset BoxContentSub
  push offset ResultSub
  push ResultSubSize * 8
  call StrHex_MY
  invoke MessageBoxA, 0, addr BoxContentSub, addr BoxHeaderSub, MB_ICONINFORMATION


  invoke ExitProcess, 0  

end start


