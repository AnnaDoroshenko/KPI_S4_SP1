.586
.model flat, stdcall
option casemap :none
.stack 4096

include D:\Programs\masm32\include\windows.inc
include D:\Programs\masm32\include\user32.inc
include D:\Programs\masm32\include\kernel32.inc
include D:\Programs\masm32\include\gdi32.inc

include module.inc

includelib D:\Programs\masm32\lib\user32.lib
includelib D:\Programs\masm32\lib\kernel32.lib
includelib D:\Programs\masm32\lib\gdi32.lib

.data


  X equ 7 + 10 ; 17
  Y equ 2 * X  ; 34  

  HexBufferLength equ (20 + 4) ; + 4 spaces (groups of 4)
  BinBufferLength equ (80 + 9) ; + 9 spaces (groups of 8)

  ExponentLength equ 15
  MantissaLength equ 64 + 2 ; + ('1.' || '.')

  ; DATA
  Int_8_1 db X
  Int_8_2 db -X

  Int_16_1 dw X
  Int_16_2 dw -X

  Int_32_1 dd X
  Int_32_2 dd -X

  Int_64_1 dq X
  Int_64_2 dq -X  

  Float_32_1 dd 17.0
  Float_32_2 dd -34.0
  Float_32_3 dd 17.17

  Float_64_1 dq 17.0
  Float_64_2 dq -34.0
  Float_64_3 dq 17.17

  Float_80_1 dt 17.0
  Float_80_2 dt -34.0
  Float_80_3 dt 17.17  


  MainBoxHeader db "Lab03 by Igor Boyarshin", 0  

  BoxHeader11 db "Integer,  8-bit", 0
  BoxHeader12 db "Integer, 16-bit", 0
  BoxHeader13 db "Integer, 32-bit", 0
  BoxHeader14 db "Integer, 64-bit", 0
  BoxHeaderLength1 equ 16

  BoxHeader21 db "Floating, 32-bit", 0
  BoxHeader22 db "Floating, 64-bit", 0
  BoxHeader23 db "Floating, 80-bit", 0  
  BoxHeaderLength2 equ 17

  BoxContentType1 db "+17 (hex): ", HexBufferLength dup(' '), 13, 10, ; 11 + HexBufferLength + 2
                     "+17 (bin): ", BinBufferLength dup(' '), 13, 10, ; 11 + BinBufferLength + 2
                     "-17 (hex): ", HexBufferLength dup(' '), 13, 10, ; 11 + HexBufferLength + 2
                     "-17 (bin): ", BinBufferLength dup(' '), 0

  Type1StartLength equ 11
  Type1HexLineLength equ (Type1StartLength + HexBufferLength + 2)
  Type1BinLineLength equ (Type1StartLength + BinBufferLength + 2)  

  BoxContentType21 db "+17.00 (hex): ", HexBufferLength dup(' '), 13, 10, ; 14 + HexBufferLength + 2
                      "+17.00 (bin): ", BinBufferLength dup(' '), 13, 10, ; 14 + BinBufferLength + 2
                      "Sign: ", "*", 13, 10,                             ; 6 + 1 + 2
                      "Exp: ", ExponentLength dup(' '), 13, 10,          ; 5 + ExponentLength + 2
                      "Mantissa: ", MantissaLength dup (' '), 0    ; 10 + MantissaLength + 2
  BoxContentType22 db "-34.00 (hex): ", HexBufferLength dup(' '), 13, 10, ; 14 + HexBufferLength + 2
                      "-34.00 (bin): ", BinBufferLength dup(' '), 13, 10, ; 14 + BinBufferLength + 2
                      "Sign: ", "*", 13, 10,                             ; 6 + 1 + 2
                      "Exp: ", ExponentLength dup(' '), 13, 10,          ; 5 + ExponentLength + 2 
                      "Mantissa: ", MantissaLength dup (' '), 0    ; 10 + MantissaLength + 2
  BoxContentType23 db "+17.17 (hex): ", HexBufferLength dup(' '), 13, 10, ; 14 + HexBufferLength + 2
                      "+17.17 (bin): ", BinBufferLength dup(' '), 13, 10, ; 14 + BinBufferLength + 2
                      "Sign: ", "*", 13, 10,                              ; 6 + 1 + 2
                      "Exp: ", ExponentLength dup(' '), 13, 10,           ; 5 + ExponentLength + 2 
                      "Mantissa: ", MantissaLength dup (' '), 0
  
  Type2NumberStartLength equ 14
  Type2SignStartLength equ 6
  Type2ExpStartLength equ 5
  Type2MantissaStartLength equ 10
  Type2HexLineLength equ (Type2NumberStartLength + HexBufferLength + 2)
  Type2BinLineLength equ (Type2NumberStartLength + BinBufferLength + 2)
  Type2SignLineLength equ (Type2SignStartLength + 1 + 2)
  Type2SExpLineLength equ (Type2ExpStartLength + ExponentLength + 2)
  Type2MantissaLineLength equ (Type2MantissaStartLength + MantissaLength + 1)  
  ;BoxContentType2Length equ Type2HexLineLength + Type2BinLineLength + Type2SignLineLength + Type2SExpLineLength + Type2MantissaLineLength

.code
start:

  ; PREPARE integer loop
  mov ecx, 4 ; 4 windows with different length of integers
  mov eax, 1 ; current amount of bytes
  mov ebx, offset Int_8_1 ; current number offset
  mov edx, offset BoxHeader11 ; current BoxHeader offset

  cmp ecx, 0
  je integer_loop_end
integer_loop_begin:  
  push ecx  
  
  push edx
  push eax
  push ebx
  
  ; get 1st hex
  shl eax, 3 ; get bits from bytes  
  push [offset BoxContentType1 + 0 * (Type1HexLineLength + Type1BinLineLength) + Type1StartLength]
  push ebx
  push eax
  call StrHex_MY

  mov ebx, [esp]
  mov eax, [esp + 4]
  shl eax, 3
  push [offset BoxContentType1 + Type1HexLineLength + Type1StartLength] ; #1 Result buffer address
  push ebx
  push eax
  call StrBin

  ; advance to the next variable
  pop ebx
  pop eax
  add ebx, eax
  push eax
  push ebx  
  
  ; get 2nd hex
  shl eax, 3 ; get bits from bytes  
  push [offset BoxContentType1 + 1 * (Type1HexLineLength + Type1BinLineLength) + Type1StartLength]
  push ebx
  push eax
  call StrHex_MY  

  mov ebx, [esp]
  mov eax, [esp + 4]
  shl eax, 3
  push [offset BoxContentType1 + 1 * (Type1HexLineLength + Type1BinLineLength) + Type1HexLineLength + Type1StartLength] ; #1 Result buffer address
  push ebx
  push eax
  call StrBin

  mov edx, [esp + 8]; + eax + ebx => edx
  invoke MessageBoxA, 0, addr BoxContentType1, edx, MB_ICONINFORMATION

  ; prepare for next cycle  
  pop ebx
  pop eax
  pop edx

  add ebx, eax ; last advancing for this variable type  
  shl eax, 1   ; new variable type(amount of digits)  
  add edx, BoxHeaderLength1 ; advance to the next BoxHeader

  pop ecx
  loop integer_loop_begin
integer_loop_end:

float_32_mark:
  ; +17.0
  push [offset BoxContentType21 + Type2NumberStartLength] ; #1 Result buffer address
  push [offset Float_32_1] ; #2 Variable address 
  push 32 ; #3 Amount of bits  
  call StrHex_MY  

  push [offset BoxContentType21 + Type2NumberStartLength + Type2HexLineLength] ; #1 Result buffer address
  push [offset Float_32_1] ; #2 Variable address 
  push 32 ; #3 Amount of bits  
  call StrBin

  push [offset BoxContentType21 + Type2NumberStartLength + Type2HexLineLength] ; #1 Sourse offset
  push 32 ; #2 Amount of bits  
  call ExtractFloatInfo

  invoke MessageBoxA, 0, addr BoxContentType21, addr BoxHeader21, MB_ICONINFORMATION

  ; -34.0
  push [offset BoxContentType22 + Type2NumberStartLength] ; #1 Result buffer address
  push [offset Float_32_2] ; #2 Variable address 
  push 32 ; #3 Amount of bits  
  call StrHex_MY  

  push [offset BoxContentType22 + Type2NumberStartLength + Type2HexLineLength] ; #1 Result buffer address
  push [offset Float_32_2] ; #2 Variable address 
  push 32 ; #3 Amount of bits  
  call StrBin

  push [offset BoxContentType22 + Type2NumberStartLength + Type2HexLineLength] ; #1 Sourse offset
  push 32 ; #2 Amount of bits  
  call ExtractFloatInfo

  invoke MessageBoxA, 0, addr BoxContentType22, addr BoxHeader21, MB_ICONINFORMATION

  ; +17.17
  push [offset BoxContentType23 + Type2NumberStartLength] ; #1 Result buffer address
  push [offset Float_32_3] ; #2 Variable address 
  push 32 ; #3 Amount of bits  
  call StrHex_MY  

  push [offset BoxContentType23 + Type2NumberStartLength + Type2HexLineLength] ; #1 Result buffer address
  push [offset Float_32_3] ; #2 Variable address 
  push 32 ; #3 Amount of bits  
  call StrBin

  push [offset BoxContentType23 + Type2NumberStartLength + Type2HexLineLength] ; #1 Sourse offset
  push 32 ; #2 Amount of bits  
  call ExtractFloatInfo

  invoke MessageBoxA, 0, addr BoxContentType23, addr BoxHeader21, MB_ICONINFORMATION


float_64_mark:
  ; +17.0
  push [offset BoxContentType21 + Type2NumberStartLength] ; #1 Result buffer address
  push [offset Float_64_1] ; #2 Variable address 
  push 64 ; #3 Amount of bits  
  call StrHex_MY  

  push [offset BoxContentType21 + Type2NumberStartLength + Type2HexLineLength] ; #1 Result buffer address
  push [offset Float_64_1] ; #2 Variable address 
  push 64 ; #3 Amount of bits  
  call StrBin

  push [offset BoxContentType21 + Type2NumberStartLength + Type2HexLineLength] ; #1 Sourse offset
  push 64 ; #2 Amount of bits  
  call ExtractFloatInfo

  invoke MessageBoxA, 0, addr BoxContentType21, addr BoxHeader22, MB_ICONINFORMATION

  ; -34.0
  push [offset BoxContentType22 + Type2NumberStartLength] ; #1 Result buffer address
  push [offset Float_64_2] ; #2 Variable address 
  push 64 ; #3 Amount of bits  
  call StrHex_MY  

  push [offset BoxContentType22 + Type2NumberStartLength + Type2HexLineLength] ; #1 Result buffer address
  push [offset Float_64_2] ; #2 Variable address 
  push 64 ; #3 Amount of bits  
  call StrBin

  push [offset BoxContentType22 + Type2NumberStartLength + Type2HexLineLength] ; #1 Sourse offset
  push 64 ; #2 Amount of bits  
  call ExtractFloatInfo

  invoke MessageBoxA, 0, addr BoxContentType22, addr BoxHeader22, MB_ICONINFORMATION

  ; +17.17
  push [offset BoxContentType23 + Type2NumberStartLength] ; #1 Result buffer address
  push [offset Float_64_3] ; #2 Variable address 
  push 64 ; #3 Amount of bits  
  call StrHex_MY  

  push [offset BoxContentType23 + Type2NumberStartLength + Type2HexLineLength] ; #1 Result buffer address
  push [offset Float_64_3] ; #2 Variable address 
  push 64 ; #3 Amount of bits  
  call StrBin

  push [offset BoxContentType23 + Type2NumberStartLength + Type2HexLineLength] ; #1 Sourse offset
  push 64 ; #2 Amount of bits  
  call ExtractFloatInfo

  invoke MessageBoxA, 0, addr BoxContentType23, addr BoxHeader22, MB_ICONINFORMATION


float_80_mark:
  ; +17.0
  push [offset BoxContentType21 + Type2NumberStartLength] ; #1 Result buffer address
  push [offset Float_80_1] ; #2 Variable address 
  push 80 ; #3 Amount of bits  
  call StrHex_MY  

  push [offset BoxContentType21 + Type2NumberStartLength + Type2HexLineLength] ; #1 Result buffer address
  push [offset Float_80_1] ; #2 Variable address 
  push 80 ; #3 Amount of bits  
  call StrBin

  push [offset BoxContentType21 + Type2NumberStartLength + Type2HexLineLength] ; #1 Sourse offset
  push 80 ; #2 Amount of bits  
  call ExtractFloatInfo

  invoke MessageBoxA, 0, addr BoxContentType21, addr BoxHeader23, MB_ICONINFORMATION

  ; -34.0
  push [offset BoxContentType22 + Type2NumberStartLength] ; #1 Result buffer address
  push [offset Float_80_2] ; #2 Variable address 
  push 80 ; #3 Amount of bits  
  call StrHex_MY  

  push [offset BoxContentType22 + Type2NumberStartLength + Type2HexLineLength] ; #1 Result buffer address
  push [offset Float_80_2] ; #2 Variable address 
  push 80 ; #3 Amount of bits  
  call StrBin

  push [offset BoxContentType22 + Type2NumberStartLength + Type2HexLineLength] ; #1 Sourse offset
  push 80 ; #2 Amount of bits  
  call ExtractFloatInfo

  invoke MessageBoxA, 0, addr BoxContentType22, addr BoxHeader23, MB_ICONINFORMATION

  ; +17.17
  push [offset BoxContentType23 + Type2NumberStartLength] ; #1 Result buffer address
  push [offset Float_80_3] ; #2 Variable address 
  push 80 ; #3 Amount of bits  
  call StrHex_MY  

  push [offset BoxContentType23 + Type2NumberStartLength + Type2HexLineLength] ; #1 Result buffer address
  push [offset Float_80_3] ; #2 Variable address 
  push 80 ; #3 Amount of bits  
  call StrBin

  push [offset BoxContentType23 + Type2NumberStartLength + Type2HexLineLength] ; #1 Sourse offset
  push 80 ; #2 Amount of bits  
  call ExtractFloatInfo

  invoke MessageBoxA, 0, addr BoxContentType23, addr BoxHeader23, MB_ICONINFORMATION


  ; 1st arg = sourse offset
  ; 2nd arg = Amount of bits  
  ExtractFloatInfo proc
    push ebp
    mov ebp, esp

    mov edx, [esp + 12] ; sourse
    mov ecx, [esp + 8] ; Amount of bits  
    mov ebx, edx ; where to write
    add ebx, BinBufferLength + 2 ; now at the Sign start

    ; Sign    
    mov al, byte ptr[edx]
    mov byte ptr[ebx + Type2SignStartLength], al
    add ebx, Type2SignLineLength
    inc edx 
    dec ecx

    ; Exponent    
    push ebx
    push ecx

    cmp ecx, 32 - 1
    je exp_32

    cmp ecx, 64 - 1
    je exp_64

    jmp exp_80
  exp_32:
    mov ecx, 8 ; bits for exponent
    jmp exp_loop
  exp_64:
    mov ecx, 11 ; bits for exponent
    jmp exp_loop
  exp_80:
    mov ecx, 15 ; bits for exponent
  exp_loop: 
    mov al, byte ptr[edx]
    mov byte ptr[ebx + Type2ExpStartLength], al
    inc edx
    inc ebx

    pop eax ; there is ecx
    dec eax
    push eax ; so the ecx got decremented    
    and al, 00000111b ; if == 0 => %8 == 0
    cmp al, 0
    jne dont_skip_space
    inc edx
  dont_skip_space:    
    loop exp_loop
    pop ecx
    pop ebx
    add ebx, Type2SExpLineLength


    ; Mantissa
    cmp ecx, 60 ; roughly the margin
    jl hidden_bit
    ; no hidden bit
    mov al, byte ptr[edx]
    mov byte ptr[ebx + Type2MantissaStartLength], al
    mov byte ptr[ebx + Type2MantissaStartLength + 1], 46 ; '.'
    inc edx
    dec ecx
    jmp done_with_the_bit
  hidden_bit:
    mov byte ptr[ebx + Type2MantissaStartLength], 49 ; '1'
    mov byte ptr[ebx + Type2MantissaStartLength + 1], 46 ; '.'  
  done_with_the_bit:
    add ebx, 2
    
  mantissa_loop:
    mov al, byte ptr[edx]
    mov byte ptr[ebx + Type2MantissaStartLength], al
    inc edx
    inc ebx

    mov eax, ecx
    dec eax    
    and al, 00000111b ; if == 0 => %8 == 0
    cmp al, 0
    jne dont_skip_space2
    inc edx
  dont_skip_space2:
    loop mantissa_loop


    pop ebp
    ret 8
  ExtractFloatInfo endp

  

  invoke ExitProcess, 0  

end start


