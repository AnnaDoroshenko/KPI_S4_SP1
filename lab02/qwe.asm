.586
.model flat, stdcall

include D:\Programs\masm32\include\kernel32.inc
include D:\Programs\masm32\include\user32.inc

includelib D:\Programs\masm32\lib\kernel32.lib
includelib D:\Programs\masm32\lib\user32.lib

.data
 Caption db "My LabProgram 2", 0
 Text1 db "Hello! How are you doing?!", 13, 10, "Author: Anna Doroshenko", 0

 res dd 256 dup(0)
 Text2 db "EAX=xxxxxxxx",13,10, 
          "EBX=xxxxxxxx",13,10, 
		  "ECX=xxxxxxxx",13,10, 
		  "EDX=xxxxxxxx", 0

 Caption0 db "Result CPUID 0", 0
 Caption1 db "Result CPUID 1", 0
 Caption2 db "Result CPUID 2", 0

 Caption00 db "Result CPUID 80000000h", 0
 Caption01 db "Result CPUID 80000001h", 0
 Caption02 db "Result CPUID 80000002h", 0
 Caption03 db "Result CPUID 80000003h", 0
 Caption04 db "Result CPUID 80000004h", 0
 Caption05 db "Result CPUID 80000005h", 0
 ;Caption06 db "Result CPUID 80000006h", 0
 ;Caption07 db "Result CPUID 80000007h", 0
 Caption08 db "Result CPUID 80000008h", 0


 Model db 32 dup(0)
 CaptionModel db "Result CPUID 0 Model", 0

 Model2 db 64 dup(0)
 CaptionModel2 db "Result CPUID 80000002-4h", 0

;ця процедура записує 8 символів HEX коду числа
;перший параметр - 32-бітове число
;другий параметр - адреса буфера тексту


.code

DwordToStrHex proc
   push ebp
   mov ebp,esp
   mov ebx,[ebp+8]
   mov edx,[ebp+12]
   xor eax,eax
   mov edi,7
@next:
   mov al,dl
   and al,0Fh ;0..0001111
   add ax,48
   cmp ax,58
   jl @store   ;jump if less
   add ax,7
@store:
   mov [ebx+edi],al
   shr edx,4
   dec edi
   cmp edi,0
   jge @next   ;jump greater or equal
   pop ebp
   ret 8
DwordToStrHex endp

MyProc proc
push ebp       ;base pointer
mov ebp, esp   ;stack pointer

 mov eax, [ebp+8]
 cpuid
 mov dword ptr[res], eax
 mov dword ptr[res+4], ebx
 mov dword ptr[res+8], ecx
 mov dword ptr[res+12], edx
 push [res]
 push offset [Text2+4]
 call DwordToStrHex
 push [res+4]
 push offset [Text2+18]
 call DwordToStrHex
 push [res+8]
 push offset [Text2+32]
 call DwordToStrHex
 push [res+12]
 push offset [Text2+46]
 call DwordToStrHex
 mov eax, [ebp+12]
 invoke MessageBox, 0, ADDR Text2, eax, 0
  
mov esp, ebp
pop ebp
ret 8
MyProc endp

main:
 invoke MessageBox, 0, ADDR Text1, ADDR Caption, 0
 
 mov eax, 0
 cpuid
 mov dword ptr[Model], ebx
 mov dword ptr[Model+4], edx
 mov dword ptr[Model+8], ecx
 invoke MessageBox, 0, ADDR Model, ADDR CaptionModel, 0

push offset Caption0
push 0
call MyProc

push offset Caption1
push 1
call MyProc

push offset Caption2
push 2
call MyProc

push offset Caption00
push 80000000h
call MyProc

push offset Caption01
push 80000001h
call MyProc

push offset Caption02
push 80000002h
call MyProc

push offset Caption03
push 80000003h
call MyProc

push offset Caption04
push 80000004h
call MyProc

push offset Caption05
push 80000005h
call MyProc

push offset Caption08
push 80000008h
call MyProc

 mov eax, 80000002h
 cpuid
 mov dword ptr[Model2], eax
 mov dword ptr[Model2+4], ebx
 mov dword ptr[Model2+8], ecx
 mov dword ptr[Model2+12], edx

 mov eax, 80000003h
 cpuid
 mov dword ptr[Model2+16], eax
 mov dword ptr[Model2+20], ebx
 mov dword ptr[Model2+24], ecx
 mov dword ptr[Model2+28], edx

 mov eax, 80000004h
 cpuid
 mov dword ptr[Model2+32], eax
 mov dword ptr[Model2+36], ebx
 mov dword ptr[Model2+40], ecx
 mov dword ptr[Model2+44], edx

 ;invoke MessageBox, 0, ADDR Model2, ADDR CaptionModel2, 0

 invoke ExitProcess, 0
end main