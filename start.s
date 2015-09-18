[GLOBAL init]  
[EXTERN main]
[EXTERN k_end]   
	
init_gdt:
	;mov dword [0xD00], 0x00000000 Prima entry nulla
	mov dword [0xD08], 0x0000FFFF	; Seconda entry (codice) 0x00CF9A000000FFFF
	mov dword [0xD0C], 0x00CF9A00	
	mov dword [0xD10], 0x0000FFFF	; Terza entry (dati)
	mov dword [0xD14], 0x00CF9200
	; Lascio lo spazio per le due entry user-level
	mov word [0xD28], 0x17 		; GDT size
	mov dword [0xD2A], 0xD00	; GDT start address
	lgdt [0xD28]
	ret

init_idt:
	mov ebx, 0x500
	mov ecx, 32 ; Setto gli isr
	mov eax, isr_handler
	mov edx, 0x80000	; EDX contiene 00 08 00 E2
	mov dx, ax
set_isr_loop:
	mov dword [ebx], edx
	add ebx, 4
	mov dword [ebx], 0x00108E00
	add ebx, 4	; Esempio di isr: 0x00 10 8E 00 00 00 08 00 E0
	loop set_isr_loop
	mov ecx, 16	; Setto gli irq
	mov eax, irq_handler
	mov dx, ax
set_irq_loop:
	mov dword [ebx], edx
	add ebx, 4
	mov dword [ebx], 0x00108E00
	add ebx, 4
	loop set_irq_loop
	; IRQ specifici a timer e tastiera!
	mov eax, tastiera
	mov dx, ax
	mov dword [0x608], edx	; IRQ 33
	mov dword [0x60c], 0x00108E00
	mov eax, timer
	mov dx, ax
	mov dword [0x600], edx	;IRQ 32
	mov dword [0x604], 0x00108E00
	mov word [0xD2E], 0x7FF		; IDT size
	mov dword [0xD30], 0x500	; IDT start address
	lidt [0xD2E]
	ret
		
init_pic:
	mov eax, 0x11
	out 0X20, al
	out 0XA0, al
	mov al, 0x20
	out 0X21, al
	mov al, 0x28
	out 0XA1, al
	mov al, 0x04
	out 0X21, al
	mov al, 0x02
	out 0XA1, al
	mov al, 0x01
	out 0X21, al
	out 0XA1, al
	mov al, 0x00
	out 0X21, al
	out 0XA1, al
	ret
	
clean_RAMVideo:
	mov ecx, 1000
	mov eax, 0xB8000
pulisci_screen_loop:
	mov [eax], dword 0x1F201F20
	add eax, 4
	loop pulisci_screen_loop
	ret

init_mem:
; VAR (int) TOT_PAGINE_DISPONIBILI(da4kb): addr 0xD34
	pop edx	; E' invocato da una call
	pop ebx 
	push edx ; Quindi devo salvare l'eip
	add ebx, 4
	mov ecx, [ebx]
	add ebx, 4
	add ecx, [ebx]
	sar ecx, 0x2
	mov dword [0xD34], ecx
	
	sar ecx, 0x05	; Divido per 32: n Pagine in una dword da 4 byte
	mov ebx, k_end
clean_bitmap_loop:
	mov dword [ebx], 0x0
	add ebx, 4
	loop clean_bitmap_loop
; VAR (int) TOT_PAGINE_LIBERE: addr 0xD38
	sar ebx, 0x11	; Divido per 1024*4*32 (ottengo resto, quindi approssimo per eccesso)
	add ebx, 1
	mov ecx, ebx	
	shl ebx, 0x5 ; Quindi ricalcolo il n di pagine libere
	mov dword [0xD38], ebx
	mov ebx, k_end
full_bitmap_loop:
	mov dword [ebx], 0xFFFFFFFF
	add ebx, 4
	loop full_bitmap_loop
	ret

get_free_page:
	mov eax, dword [0xD38]
	
	
	mov ebx, k_end
	mov edx, 0x20
	div dl
	mov edx, 0
	mov dl, al
	sal edx, 0x2
	mov cl, ah ; Salvo il resto
	add ebx, edx
	mov edx, 0x1
	shl edx, cl
	mov eax, dword [ebx]
	or eax, edx
	mov dword [ebx], eax
	
	
	mov ecx, dword [0xD38]
	add dword [0xD38], 1
	shl ecx, 0xC
	pop edx ; Preservo l'eip
	push ecx ; Carico l'addr generato dalla richiesta
	push edx
	ret
tastiera:	
	pusha ; Salva i registri allo stato precedente!
	in al, 0x60
	out 0xE9, al	
	mov eax, 0x20 ; Mandiamo l'EOI al pic
	out 0x20, al
	popa
	iret

timer:
	pusha ; Salva i registri allo stato precedente!
	mov eax, 0x54
	out 0xE9, al	
	mov eax, 0x20 ; Mandiamo l'EOI al pic
	out 0x20, al	
	popa
	iret

init:
	xchg bx, bx
	call init_gdt
	call init_idt
	call init_pic
	call clean_RAMVideo
	; Stampiamo il nostro logo!
	mov eax, 0xB8000
	mov [eax], byte 'L'
	add eax, 2
	mov [eax], byte 'i'
	add eax, 2
	mov [eax], byte 'g'
	add eax, 2
	mov [eax], byte 'h'
	add eax, 2
	mov [eax], byte 't'
	add eax, 2
	mov [eax], byte 'O'
	add eax, 2
	mov [eax], byte 'S'
	add eax, 2
	xchg bx, bx
	call init_mem
	
	jmp 0x1030A1 ; A questo indirizzo si trova l'eseguibile main.bin contenuto nell'initfs! (ps è solo una prova..)
	call main
; Loop infinito
	mov ecx, 2	
while1_loop:
	add ecx, 0
	loop while1_loop
	

irq_handler:
	xchg bx, bx
isr_handler:
	xchg bx, bx	
	
