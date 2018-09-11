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

  ; SHIFT
  ShiftArgumentAmountOfChunks equ 23
  ;ShiftArgumentAmountOfHex equ ShiftArgumentAmountOfChunks * 8
  ;ShiftArgumentAmountOfHexSpaces equ ShiftArgumentAmountOfChunks ; because one chunk == 8 hex symbols
  ShiftArgumentAmountOfBin equ ShiftArgumentAmountOfChunks * 32
  ShiftArgumentAmountOfBinSpaces equ ShiftArgumentAmountOfChunks * 4 ; because one bin group == 8 bits

  ShiftArgument dd (ShiftArgumentAmountOfChunks-2) dup (0F8F8F8F8h), 12345678h, 09ABCDEFh ;(0AAAAAAAAh)
  ;ShiftArgument dd ShiftArgumentAmountOfChunks dup (0AAAAAAAAh)
  ShiftArgumentSize equ $ - ShiftArgument
  ShiftResult dd ShiftArgumentAmountOfChunks dup (0)
  ShiftResultSize equ $ - ShiftResult
  ShiftN dd 16 ; bits
  ShiftNSize equ $ - ShiftN
  ShiftFill dd 099993333h;, 0EEEEFFFFh ;  low -> high
  ;ShiftFill dd 0FFFFFFFFh, 0FFFFFFFFh ;  low -> high
  ShiftFillSize equ $ - ShiftFill



  ; HEADERS
  BoxHeaderShift db "Shift left N bits", 0  

  ; CONTENT
  BoxContentShift db "Input value(bin): ", (ShiftArgumentAmountOfBin + ShiftArgumentAmountOfBinSpaces) dup('.'), 13, 10,                 
                "Amount of bits to shift(N): ", 8 dup('.'), 13, 10, ; 8 hex symbols for 32 bits
                "Bits to fill with: ", ShiftFillSize * 9 dup('.'), 13, 10, ; *9 because 8 bits(symbols) per byte + ' '
                "Output value(bin):", (ShiftArgumentAmountOfBin + ShiftArgumentAmountOfBinSpaces) dup('.'), 13, 10, 0
                ;"Input value(hex): ", (ShiftArgumentAmountOfHex + ShiftArgumentAmountOfHexSpaces) dup('.'), 13, 10,   
                ;"Output value(hex): ", (ShiftArgumentAmountOfHex + ShiftArgumentAmountOfHexSpaces) dup('.'), 13, 10,
                
                
  ;ShiftHexShift equ 18
  ;ShiftsHexLength equ (ShiftHexShift + ShiftArgumentAmountOfHex + ShiftArgumentAmountOfHexSpaces + 2)
  ShiftBinShift equ 18
  ShiftBinLength equ (ShiftBinShift + ShiftArgumentAmountOfBin + ShiftArgumentAmountOfBinSpaces + 2)
  ShiftAmountShift equ 28
  ShiftAmountLength equ (ShiftAmountShift + 8 + 2)
  ShiftFillShift equ 19
  ShiftFillLength equ (ShiftFillShift + ShiftFillSize * 9 + 2)  


.code
start:

;jmp @end

@shift_n:

  ; Call the procedure  
  push ShiftArgumentAmountOfChunks
  push offset ShiftArgument
  push offset ShiftResult
  push ShiftN
  push offset ShiftFill
  call ShlLongN

  ; Fill bin input
  mov eax, offset BoxContentShift
  add eax, ShiftBinShift
  push eax
  push offset ShiftArgument
  push ShiftArgumentSize * 8
  call StrBin

  ; Fill amount of bits to shift(in hex)
  mov eax, offset BoxContentShift 
  add eax, ShiftBinLength
  add eax, ShiftAmountShift
  push eax
  push offset ShiftN
  push ShiftNSize * 8
  call StrHex_MY

  ; Fill bits to fill with(in bin)
  mov eax, offset BoxContentShift
  add eax, ShiftBinLength
  add eax, ShiftAmountLength
  add eax, ShiftFillShift
  push eax
  push offset ShiftFill
  push ShiftFillSize * 8
  call StrBin

  ; Fill bin output
  mov eax, offset BoxContentShift
  add eax, ShiftBinLength
  add eax, ShiftAmountLength
  add eax, ShiftFillLength
  add eax, ShiftBinShift
  push eax
  push offset ShiftResult
  push ShiftResultSize * 8
  call StrBin

  invoke MessageBoxA, 0, addr BoxContentShift, addr BoxHeaderShift, MB_ICONINFORMATION

@end:
  invoke ExitProcess, 0  

end start


