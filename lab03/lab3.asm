.586
.model flat, stdcall
option casemap :none

include D:\Programs\masm32\include\windows.inc
include D:\Programs\masm32\include\kernel32.inc
include D:\Programs\masm32\include\user32.inc

includelib D:\Programs\masm32\lib\kernel32.lib
includelib D:\Programs\masm32\lib\user32.lib

include module.inc

.data
 Caption db "My LabProgram 3", 0
 
 Int_8_1 db 27
 Int_8_2 db -27

 Int_16_1 dw 27
 Int_16_2 dw -27
 
 Int_32_1 dd 27
 Int_32_2 dd -27
 
 Int_64_1 dq 27
 Int_64_2 dq -27
 
 Float_32_1 dd 27.0
 Float_32_2 dd -54.0
 Float_32_3 dd 27.27 
 
 Float_64_1 dq 27.0
 Float_64_2 dq -54.0
 Float_64_3 dq 27.27 
 
 Float_80_1 dt 27.0
 Float_80_2 dt -54.0
 Float_80_3 dt 27.27

 Header11 db "Integer  8 bit", 0
 Header12 db "Integer 16 bit", 0
 Header13 db "Integer 32 bit", 0
 Header14 db "Integer 64 bit", 0
 Header21 db "Float 32 bit", 0
 Header22 db "Float 64 bit", 0
 Header23 db "Float 80 bit", 0
 HeaderLength1 equ 15
 HeaderLength2 equ 13

    HexBufferLength equ (20+4)
    BinBufferLength equ (80+9)    

 Content1 db "+27 (hex): ", HexBufferLength dup(' '), 13, 10,
             "+27 (bin): ", BinBufferLength dup(' '), 13, 10,
             "-27 (hex): ", HexBufferLength dup(' '), 13, 10,             
             "-27 (bin): ", BinBufferLength dup(' '), 0

  Type1StartLength equ 11
  Type1HexLineLength equ (Type1StartLength + HexBufferLength + 2)
  Type1BinLineLength equ (Type1StartLength + BinBufferLength + 2)

  Content21 db "+27.00 (hex): ", HexBufferLength dup(' '), 13, 10,
                "+27.00 (bin): ", BinBufferLength dup(' '), 0

  Content22 db "-54.00 (hex): ", HexBufferLength dup(' '), 13, 10,
                "-54.00 (bin): ", BinBufferLength dup(' '), 0                

  Content23 db "+27.27 (hex): ", HexBufferLength dup(' '), 13, 10,
                "+27.27 (bin): ", BinBufferLength dup(' '), 0                

  Type2NumberStartLength equ 14
  Type2HexLineLength equ (Type2NumberStartLength + HexBufferLength + 2)
  ;Type2BinLineLength equ (Type2NumberStartLength + BinBufferLength + 2)
  
.code
main:

  ; PREPARE integer loop
  mov ecx, 4 ; 4 windows with different length of integers
  mov eax, 1 ; current amount of bytes
  mov ebx, offset Int_8_1 ; current number offset
  mov edx, offset Header11 ; current Header offset

  cmp ecx, 0
  je integer_loop_end
integer_loop_begin:  
  push ecx  
  
  push edx
  push eax
  push ebx
  
  ; get 1st hex
  shl eax, 3 ; get bits from bytes  
  push [offset Content1 + 0 * (Type1HexLineLength + Type1BinLineLength) + Type1StartLength]
  push ebx
  push eax
  call StrHex_MY

  mov ebx, [esp]
  mov eax, [esp + 4]
  shl eax, 3
  push [offset Content1 + Type1HexLineLength + Type1StartLength] ; #1 Result buffer address
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
  push [offset Content1 + 1 * (Type1HexLineLength + Type1BinLineLength) + Type1StartLength]
  push ebx
  push eax
  call StrHex_MY  

  mov ebx, [esp]
  mov eax, [esp + 4]
  shl eax, 3
  push [offset Content1 + 1 * (Type1HexLineLength + Type1BinLineLength) + Type1HexLineLength + Type1StartLength] ; #1 Result buffer address
  push ebx
  push eax
  call StrBin

  mov edx, [esp + 8]; + eax + ebx => edx
  invoke MessageBoxA, 0, addr Content1, edx, MB_ICONINFORMATION

  ; prepare for next cycle  
  pop ebx
  pop eax
  pop edx

  add ebx, eax ; last advancing for this variable type  
  shl eax, 1   ; new variable type(amount of digits)  
  add edx, HeaderLength1 ; advance to the next Header

  pop ecx
  loop integer_loop_begin
integer_loop_end:

float_32_mark:
  ; +27.0
  push [offset Content21 + Type2NumberStartLength] ; #1 Result buffer address
  push [offset Float_32_1] ; #2 Variable address 
  push 32 ; #3 Amount of bits  
  call StrHex_MY  

  push [offset Content21 + Type2NumberStartLength + Type2HexLineLength] ; #1 Result buffer address
  push [offset Float_32_1] ; #2 Variable address 
  push 32 ; #3 Amount of bits  
  call StrBin

  invoke MessageBoxA, 0, addr Content21, addr Header21, MB_ICONINFORMATION

  ; -54.0
  push [offset Content22 + Type2NumberStartLength] ; #1 Result buffer address
  push [offset Float_32_2] ; #2 Variable address 
  push 32 ; #3 Amount of bits  
  call StrHex_MY  

  push [offset Content22 + Type2NumberStartLength + Type2HexLineLength] ; #1 Result buffer address
  push [offset Float_32_2] ; #2 Variable address 
  push 32 ; #3 Amount of bits  
  call StrBin

  invoke MessageBoxA, 0, addr Content22, addr Header21, MB_ICONINFORMATION

  ; +27.27
  push [offset Content23 + Type2NumberStartLength] ; #1 Result buffer address
  push [offset Float_32_3] ; #2 Variable address 
  push 32 ; #3 Amount of bits  
  call StrHex_MY  

  push [offset Content23 + Type2NumberStartLength + Type2HexLineLength] ; #1 Result buffer address
  push [offset Float_32_3] ; #2 Variable address 
  push 32 ; #3 Amount of bits  
  call StrBin

  invoke MessageBoxA, 0, addr Content23, addr Header21, MB_ICONINFORMATION

float_64_mark:
  ; +27.0
  push [offset Content21 + Type2NumberStartLength] ; #1 Result buffer address
  push [offset Float_64_1] ; #2 Variable address 
  push 64 ; #3 Amount of bits  
  call StrHex_MY  

  push [offset Content21 + Type2NumberStartLength + Type2HexLineLength] ; #1 Result buffer address
  push [offset Float_64_1] ; #2 Variable address 
  push 64 ; #3 Amount of bits  
  call StrBin

  invoke MessageBoxA, 0, addr Content21, addr Header22, MB_ICONINFORMATION

  ; -54.0
  push [offset Content22 + Type2NumberStartLength] ; #1 Result buffer address
  push [offset Float_64_2] ; #2 Variable address 
  push 64 ; #3 Amount of bits  
  call StrHex_MY  

  push [offset Content22 + Type2NumberStartLength + Type2HexLineLength] ; #1 Result buffer address
  push [offset Float_64_2] ; #2 Variable address 
  push 64 ; #3 Amount of bits  
  call StrBin

  invoke MessageBoxA, 0, addr Content22, addr Header22, MB_ICONINFORMATION

  ; +27.27
  push [offset Content23 + Type2NumberStartLength] ; #1 Result buffer address
  push [offset Float_64_3] ; #2 Variable address 
  push 64 ; #3 Amount of bits  
  call StrHex_MY  

  push [offset Content23 + Type2NumberStartLength + Type2HexLineLength] ; #1 Result buffer address
  push [offset Float_64_3] ; #2 Variable address 
  push 64 ; #3 Amount of bits  
  call StrBin

  invoke MessageBoxA, 0, addr Content23, addr Header22, MB_ICONINFORMATION

float_80_mark:
  ; +27.0
  push [offset Content21 + Type2NumberStartLength] ; #1 Result buffer address
  push [offset Float_80_1] ; #2 Variable address 
  push 80 ; #3 Amount of bits  
  call StrHex_MY  

  push [offset Content21 + Type2NumberStartLength + Type2HexLineLength] ; #1 Result buffer address
  push [offset Float_80_1] ; #2 Variable address 
  push 80 ; #3 Amount of bits  
  call StrBin

  invoke MessageBoxA, 0, addr Content21, addr Header23, MB_ICONINFORMATION

  ; -54.0
  push [offset Content22 + Type2NumberStartLength] ; #1 Result buffer address
  push [offset Float_80_2] ; #2 Variable address 
  push 80 ; #3 Amount of bits  
  call StrHex_MY  

  push [offset Content22 + Type2NumberStartLength + Type2HexLineLength] ; #1 Result buffer address
  push [offset Float_80_2] ; #2 Variable address 
  push 80 ; #3 Amount of bits  
  call StrBin

  invoke MessageBoxA, 0, addr Content22, addr Header23, MB_ICONINFORMATION

  ; +27.27
  push [offset Content23 + Type2NumberStartLength] ; #1 Result buffer address
  push [offset Float_80_3] ; #2 Variable address 
  push 80 ; #3 Amount of bits  
  call StrHex_MY  

  push [offset Content23 + Type2NumberStartLength + Type2HexLineLength] ; #1 Result buffer address
  push [offset Float_80_3] ; #2 Variable address 
  push 80 ; #3 Amount of bits  
  call StrBin

  invoke MessageBoxA, 0, addr Content23, addr Header23, MB_ICONINFORMATION
  invoke ExitProcess, 0  
end main