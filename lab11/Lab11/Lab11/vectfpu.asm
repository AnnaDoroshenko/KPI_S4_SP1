.586
.model flat, c
.stack 4096

.data

Result dd 0

.code

DotProductFPU proc resultAddress : DWORD, aVector : DWORD, bVector : DWORD, N : DWORD

	mov ecx, N
	mov eax, aVector
	mov edx, bVector
	fldz                   ; LoaD the value of Zero

@next_group:
	fld dword ptr[eax + ecx * 4 - 4]
	fmul dword ptr[edx + ecx * 4 - 4]
	faddp st(1), st(0)

	dec ecx
	jnz @next_group

	fstp Result

	mov edi, resultAddress
	mov eax, Result
	mov dword ptr[edi], eax

	ret
DotProductFPU endp

end