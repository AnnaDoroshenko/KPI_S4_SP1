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
  ; (n!)^2 = (62!)^2 == ^170 <= 576 bits (18*32)

  ; EQUs FOR SIZE
  FactorialNGroupsOf32 equ 9 ; amount of groups of 32 bits
  FactorialNSqrGroupsOf32 equ 18 ; amount of groups of 32 bits

  ; INPUT VALUES  
  ValueN dd 62  
  ValueTestN dd FactorialNGroupsOf32 dup(0FFFFFFFFh)
  ;ValueTestN dd 4 dup (0FFFFFFFFh), 2 dup(0)
  ;ValueTestNSize equ $ - ValueTestN

  ValueTestNx32 dd 0FFFFFFFFh  

  ; RESULTS
  ResultNFactorial dd FactorialNGroupsOf32 dup(0)
  ;ResultNFactorial dd FactorialNGroupsOf32 dup(0FFFFFFFFh)
  ResultNFactorialSize equ $ - ResultNFactorial

  ResultNFactorialSqr dd FactorialNSqrGroupsOf32 dup(0)
  ResultNFactorialSqrSize equ $ - ResultNFactorialSqr

  ResultTestNx32 dd (FactorialNGroupsOf32 + 1) dup(0)
  ;ResultTestNx32 dd 0FFFFFFFFh, 0EEEEEEEEh, 0DDDDDDDDh, 4 dup(0)
  ResultTestNx32Size equ $ - ResultTestNx32
  
  ResultTestNxN dd FactorialNSqrGroupsOf32 dup(0)
  ResultTestNxNSize equ $ - ResultTestNxN


  ; HEADERS
  BoxHeaderNFactorial db "Result of n!", 0
  BoxHeaderNFactorialSqr db "Result of n! * n!", 0 
  BoxHeaderTestNx32 db "Result of Test Nx32", 0
  BoxHeaderTestNxN db "Result of Test NxN", 0   

  ; CONTENT
  BoxContentNFactorial db FactorialNGroupsOf32 * (8+1) dup(' '), 0 ; +1 for spaces (8 chars(32 bits) make 1 space)
  BoxContentNFactorialSqr db FactorialNSqrGroupsOf32 * (8+1) dup(' '), 0
  BoxContentTestNx32 db FactorialNGroupsOf32 * (8+1) dup(' '), 0
  BoxContentTestNxN db FactorialNSqrGroupsOf32 * (8+1) dup(' '), 0

.code
start:

  ;jmp @test_NxN

  ; MUL n!
@mul_n_factorial:
  push ValueN
  push FactorialNGroupsOf32
  push offset ResultNFactorial
  call FactorialLong

  push offset BoxContentNFactorial
  push offset ResultNFactorial
  push ResultNFactorialSize * 8
  call StrHex_MY
  invoke MessageBoxA, 0, addr BoxContentNFactorial, addr BoxHeaderNFactorial, MB_ICONINFORMATION


  ; MUL n! x n!
@mul_n_factorial_sqr:  
  push FactorialNGroupsOf32
  push offset ResultNFactorial
  push FactorialNGroupsOf32
  push offset ResultNFactorial
  push offset ResultNFactorialSqr
  call MulLong

  push offset BoxContentNFactorialSqr
  push offset ResultNFactorialSqr
  push ResultNFactorialSqrSize * 8
  call StrHex_MY
  invoke MessageBoxA, 0, addr BoxContentNFactorialSqr, addr BoxHeaderNFactorialSqr, MB_ICONINFORMATION


  ; TEST Nx32
@test_Nx32:
  push FactorialNGroupsOf32
  push offset ValueTestN
  push ValueTestNx32
  push offset ResultTestNx32
  call MulLong32

  push offset BoxContentTestNx32
  push offset ResultTestNx32
  push ResultTestNx32Size * 8
  call StrHex_MY
  invoke MessageBoxA, 0, addr BoxContentTestNx32, addr BoxHeaderTestNx32, MB_ICONINFORMATION

;jmp @mul_n_factorial_sqr
  ; TEST NxN
@test_NxN:
  push FactorialNGroupsOf32
  push offset ValueTestN
  push FactorialNGroupsOf32
  push offset ValueTestN
  push offset ResultTestNxN
  call MulLong

  push offset BoxContentTestNxN
  push offset ResultTestNxN
  push ResultTestNxNSize * 8
  call StrHex_MY
  invoke MessageBoxA, 0, addr BoxContentTestNxN, addr BoxHeaderTestNxN, MB_OKCANCEL
  ;cmp eax, IDCANCEL
  ;je @test_NxN

  invoke ExitProcess, 0  

end start