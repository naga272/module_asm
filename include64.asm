
;
;	Libreria include64.asm fatta da Bastianello Federico 05 / 05 / 2024
;
;	Siete liberi di usare questo modulo assembly che contiene macro e funzioni
;	base per lo svolgimento di un comune programma assembly. Nel caso vogliate modificarlo
;	per migliorarlo vi chiedo gentilmente di contattarmi alla seguente email:
;		- nagato27272@gmail.com
;	mandandomi la vostra versione. Se vedo che ci sono delle migliorie all'interno del codice
;	aggiornero' questo modulo con la vostra implementazione, dandovi i crediti
;	Questo perche' ho faticato e studiato molto per creare questa libreria, quindi,
;	vi chiedo di usare il buonsenso. Grazie per la dispobilita'
;

; valori di uscita processi / funzioni
%define EXIT_SUCCESS 0
%define EXIT_FAILURE 1

; common file descriptor
%define stdin 0
%define stdout 1
%define stderr 2

; proprieta' file
%define O_WRONLY 0o010
%define O_RDONLY 0o100
%define O_TRUNC  0o001

; xor general register of cpu
%macro GXOR 0
	xor rax, rax
	xor rbx, rbx
	xor rcx, rcx
	xor rdx, rdx
%endmacro


; gestione FILE
%macro FOPEN 3
	mov rax, 2	; syscall
	mov rdi, %1 	; pathname
	mov rsi, %2	; modalita' apertura
	mov rdx, %3	; permessi file (0o666 -> rw-rw-rw-)
	syscall		; ritorna in rax il file descriptor
%endmacro



%macro FWRITE 2		; N.B.: prima di usare questa macro assicurarsi che rdi contenga il file descriptor
	mov rax, 1	; write-syscall
	mov rsi, %1	; char []
	mov rdx, %2	; strlen(char[])
	syscall
%endmacro


%macro FCLOSE 0		; N.B.: prima di usare questa macro assicurarsi che rdi contenga il file descriptor		
	mov rax, 3
	syscall
%endmacro


section .bss
	digitSpace 	resb 100
	digitSpacePos 	resb 8
	fd_in 		resd 1
	buff 		resb 1

section .rodata
	NEWLINE		db 10, 0
	msg_error_read 	db "errore durante la lettura del file", NEWLINE
	msg_error_write db "errore durante la scrittura del file", NEWLINE
section .text


print:	; funzione che stampa in stdout
        ;
        push rbp
	mov rbp, rsp
	
	mov rsi, [rbp + 16]
	
	.puts:	cmp byte[rsi], 0
		je .finish_print
	
		mov rax, 1		
		mov rdi, stdout
		mov rdx, 1
		syscall

		inc rsi
		jmp .puts

	.finish_print:	
		mov rax, EXIT_SUCCESS
		leave
		ret



print_int:	push rbp
		mov rbp, rsp

		mov rax, [rbp + 16]		
		
		mov rcx, digitSpace	; vettore di 100 elementi	
		mov rbx, 10		; base 10
		mov [rcx], rbx
		inc rcx
		mov [digitSpacePos], rcx

		.st_loop:	
			xor rdx, rdx		; azzero rdx
			div rbx			; divido il contenuto di rax per rbx
			push rax		; salvo il quoziente nello stack (il resto si trova in rdx)
			add rdx, 48

			mov rcx, [digitSpacePos]
			mov [rcx], dl
			inc rcx
			mov [digitSpacePos], rcx

			pop rax
			cmp rax, 0
			jne .st_loop

		.end_loop:
			;mov rcx, [digitSpacePos]

			mov rax, 1
			mov rdx, 1
			mov rdi, 1
			mov rsi, rcx
			syscall			

			mov rcx, [digitSpacePos]
			dec rcx

			mov [digitSpacePos], rcx

			cmp rcx, digitSpace
			jge .end_loop

			mov rax, EXIT_SUCCESS
			leave
			ret


input:  push rbp
	mov rbp, rsp

	mov rsi, [rbp + 16]	;vettore
	
	request_loop: 
		mov rax, 0
		mov rdi, stdin
		mov rdx, 1
		syscall

		cmp byte[rsi], 10
		je end_request

		inc rsi
		jmp request_loop

	end_request:
		mov rax, EXIT_SUCCESS
		leave
		ret



fread_all:	
	push rbp
	mov rbp, rsp

	FOPEN [rbp + 16], O_RDONLY, 0o000
	test rax, rax
	js .error

	mov [fd_in], rax
	
	.loop:  
		mov rsi, buff
		mov rdi, [fd_in]	; sposto il fd in rdi
		mov rax, 0
		mov rdx, 1
		syscall 
	
	cmp rax, 0
	je .eof
	
	mov rax, 1
	mov rdi, 1
	mov rsi, buff
	mov rdx, 1
	syscall

	jmp .loop
	
	.eof:	FCLOSE
		mov rax, EXIT_SUCCESS
		leave
		ret

	.error: leave
		push msg_error_read
		call print
		mov rax, 60
		mov rdi, EXIT_FAILURE
		syscall


writef:	push rbp
	mov rbp, rsp

	FOPEN [rbp + 16], O_WRONLY, 0o666
	test rax, rax
	js .error

	FCLOSE

	mov rax, EXIT_SUCCESS
	leave
	ret
	.error: leave
		push msg_error_write
		call print
		mov rax, 60
		mov rdi, EXIT_FAILURE
	xor rsi, rsi
	syscall

