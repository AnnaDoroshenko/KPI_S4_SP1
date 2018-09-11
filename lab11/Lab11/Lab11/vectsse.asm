.686
.xmm
.model flat, c
.stack 4096

.data

ZeroFloat dq 0.0
Result dd 0

.code

DotProductSSE proc resultAddress : DWORD, aVector : DWORD, bVector : DWORD, N : DWORD

	mov ecx, N
	shr ecx, 2 ; /4
	mov eax, aVector
	mov edx, bVector
	movsd xmm0, ZeroFloat ; Move Scalar Double-Precision Floating-Point Value

@next_four_pairs:
	movaps xmm1, [eax]
	movaps xmm2, [edx]
	mulps xmm1, xmm2
	addps xmm0, xmm1

	add eax, 16
	add edx, 16
	dec ecx
	jnz @next_four_pairs

	haddps xmm0, xmm0
	haddps xmm0, xmm0
	movss Result, xmm0 ; Move Scalar Single-Precision Floating-Point Values

	mov edi, resultAddress
	mov eax, Result
	mov dword ptr[edi], eax

	ret
DotProductSSE endp

end