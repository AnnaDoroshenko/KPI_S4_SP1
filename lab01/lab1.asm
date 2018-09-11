.386
.model flat, stdcall

include D:\Programs\masm32\include\kernel32.inc
include D:\Programs\masm32\include\user32.inc 

includelib D:\Programs\masm32\lib\kernel32.lib
includelib D:\Programs\masm32\lib\user32.lib

.data
 Caption db "Lab #1", 0
 Text db "Hi!", 13, 10, "Created by Anna Doroshenko", 0

.code
start:
 invoke MessageBoxA, 0, ADDR Text, ADDR Caption, 0
 invoke ExitProcess, 0
end start 