# Makefile di "LightOs"

# File oggetto
OGGETTI = boot.o	\
	start.o		\
	uplevel.o
	

# Compilatori e linker
AS  = as
C = gcc
LS  = ld.bfd

# I rispettivi argomenti
ASFLAG = 
CFLAGS  = -c -O -fstrength-reduce -fomit-frame-pointer -fno-stack-protector -finline-functions -nostdlib -nostdinc -fno-builtin  -nodefaultlibs #-I include -I arch/include -c 
LSFLAG = -melf_i386 -static  -Ttext 0x100000 --oformat elf32-i386 --script=link.ld 


.PHONY: all clean compila scrivi test debug

all: compila iso debug

compila: $(OGGETTI)
	@$(LS) $(LSFLAG) $(OGGETTI) -o kernel.bin #-Map kernel.map
	@echo "Link dei file oggetto"

scrivi:
	mkdir tmp
	@sudo mount -o loop myos.img tmp
	sudo cp kernel.bin tmp/
	sudo cp tmpfs/initrd tmp/
	sleep 1
	#DEBUG
	@sudo umount /media/os/os_devel/src/tmp
	sudo dd if=myos.img of=/dev/fd0 status=noxfer
	rm -r tmp

clean:
	rm $(OGGETTI) kernel.bin

test: compila iso
	@/usr/bin/bochs -qf ./.bochsrc
	
debug: 
	@/usr/local/bin/bochs -qf ./.debug

test_qemu:
	qemu-system-i386 -cdrom myos.iso -soundhw sb16 -usb -net nic -m 128

.s.o: 
	@nasm -s -f elf  $< -o  $@

.c.o: 
	@$(C) $(CFLAGS) $< -o  $@
	
img:
	@mount -o loop myos.img tmp
	cp kernel.bin tmp/
	@sleep 1
	@umount /media/os/myos/tmp
	dd if=myos.img of=/dev/fd0 status=noxfer
iso:
	mkdir iso
	mkdir iso/boot/
	mkdir iso/boot/grub/
	cp grub/stage2_eltorito iso/boot/grub
	cp kernel.bin iso/
	cp grub/menu.lst iso/boot/grub
	cp tmpfs/initrd iso/
	mkisofs -R -b boot/grub/stage2_eltorito -no-emul-boot -boot-load-size 4 -boot-info-table -o myos.iso iso

	rm -r iso
