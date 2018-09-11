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

;ValuesA1 dd 1.1, 1.2, 1.3
;ValuesA2 dd 2.1, 2.2, 2.3
;ValuesA3 dd 3.0, 3.0, 1.0
;ValueResult dd 0

ValuesA1 dq 1.1, 1.2, 1.3
ValuesA2 dq 2.1, 2.2, 2.3
ValuesA3 dq 3.0, 3.0, 1.0
ValueResult dq 0

; HEADERS
BoxHeader db "Result of determinant calculations", 0
  

; CONTENT
BoxContentResult db 12 dup(' '), 0

.code
start:

    ;mov edx, 0
    mov eax, 3
@loop_ValueA1:
    mov ebx, 3
@loop_ValueA2:
    cmp ebx, eax
    je @m2
    mov ecx, 3
@loop_ValueA3:
    cmp ecx, ebx
    je @m3 
    cmp ecx, eax
    je @m3

    ;inc edx

    ;fld dword ptr[ValuesA1 + eax * 4 - 4]
    ;fmul dword ptr[ValuesA2 + ebx * 4 - 4]
    ;fmul dword ptr[ValuesA3 + ecx * 4 - 4]

    fld qword ptr[ValuesA1 + eax * 8 - 8]
    fmul qword ptr[ValuesA2 + ebx * 8 - 8]
    fmul qword ptr[ValuesA3 + ecx * 8 - 8]

@m3:
    dec ecx
    jnz @loop_ValueA3

@m2:
    dec ebx
    jnz @loop_ValueA2
    dec eax
    jnz @loop_ValueA1

fadd st(0), st(3)
fadd st(0), st(4)
fsub st(0), st(1)
fsub st(0), st(2)
fsub st(0), st(5) 

fstp ValueResult
fstp st(0)
fstp st(0)
fstp st(0)
fstp st(0)
fstp st(0)

push offset ValueResult
push offset BoxContentResult
call FloatToDec64
;call FloatToDec32

invoke MessageBoxA, 0, addr BoxContentResult, addr BoxHeader, MB_ICONINFORMATION

invoke ExitProcess, 0

end start