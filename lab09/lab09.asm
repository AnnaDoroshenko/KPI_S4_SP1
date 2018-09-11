.586
.model flat, stdcall
option casemap :none
.stack 4096

include D:\Programs\masm32\include\windows.inc
include D:\Programs\masm32\include\user32.inc
include D:\Programs\masm32\include\kernel32.inc
include D:\Programs\masm32\include\gdi32.inc
include D:\Programs\masm32\include\comdlg32.inc

include module.inc
include longop.inc

includelib D:\Programs\masm32\lib\user32.lib
includelib D:\Programs\masm32\lib\kernel32.lib
includelib D:\Programs\masm32\lib\gdi32.lib
includelib D:\Programs\masm32\lib\comdlg32.lib


.data
  FileNameBuffer dd ?
  FileNameBufferSize equ 256
  FileName db ?
  HandleOfFile dd 0
  CorrectOp dd 0

  ; n! == 62! == ^85 <= 288 bits (9*32)
  ValueN dd 62
  FactorialNGroupsOf32 equ 9 ; amount of groups of 32 bits
  ResultFactorial dd FactorialNGroupsOf32 dup(0)  
  CurrentFactorial dd FactorialNGroupsOf32 dup(0)

  FactorialHex db FactorialNGroupsOf32 * 11 dup(' '), 13, 10, 0
  FactorialHexSize equ $ - FactorialHex - 1

  BoxHeader db "Result of determinant calculations", 0
  BoxContentResult db 12 dup(' '), 0

.code

  ; Indicate name of the file
  IndicateSaveFileName proc
    LOCAL ofn : OPENFILENAME

    invoke RtlZeroMemory, ADDR ofn, SIZEOF ofn
    mov ofn.lStructSize, SIZEOF ofn
    mov eax, FileNameBuffer
    mov ofn.lpstrFile, eax
    mov ofn.nMaxFile, FileNameBufferSize

    invoke GetSaveFileName, ADDR ofn
    ret
  IndicateSaveFileName endp

; Main
start:

  invoke GlobalAlloc, GPTR, FileNameBufferSize ; creates dynamic array (256 bytes)
  mov FileNameBuffer, eax                      ; gets pointer from EAX (result of GlobalAlloc) 
  ; Indicate the file name
  call IndicateSaveFileName
  cmp eax, 0
  je @exit


  ; Write into file (steps of factorial calculations)
  invoke CreateFile, FileNameBuffer, GENERIC_WRITE, FILE_SHARE_WRITE,
                   0, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0
                   
  cmp eax, INVALID_HANDLE_VALUE
  je @exit
  mov HandleOfFile, eax


  ; Calculate the factorial
  mov eax, offset CurrentFactorial
  mov dword ptr[eax], 2; fact = 1
  mov ecx, 1 ; n = 1
@fact:
    push ecx
  ;jg @endfact



  push FactorialNGroupsOf32
  push offset CurrentFactorial
  push ecx
  push offset ResultFactorial
  call MulLong32

  push offset FactorialHex 
  push offset ResultFactorial
  push FactorialNGroupsOf32 * 32
  call StrDec

  ;invoke MessageBoxA, 0, addr FactorialHex, addr BoxHeader, MB_ICONINFORMATION
  invoke WriteFile, HandleOfFile, ADDR FactorialHex, FactorialHexSize, ADDR CorrectOp, 0


  mov ecx, FactorialNGroupsOf32
  mov esi, offset ResultFactorial
  mov edi, offset CurrentFactorial
 @copy:
  mov eax, dword ptr[esi + ecx * 4 - 4]
  mov dword ptr[edi + ecx * 4 - 4], eax
  dec ecx
  jnz @copy

  pop ecx  
  inc ecx
  cmp ecx, ValueN
  jl @fact

@endfact:
  invoke CloseHandle, HandleOfFile

  invoke GlobalFree, FileNameBuffer ; free the memory (clean dynamic array)


@exit:
   invoke ExitProcess, 0

   end start