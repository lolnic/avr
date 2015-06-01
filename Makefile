CFLAGS = -mmcu=atmega2560 -DF_CPU=16000000 -I../lib/include -nostdlib
ASSEMBLER = avr-gcc $(CFLAGS) -DALL_ASSEMBLY
AVRDUDE = avrdude -c stk500v2 -pm2560 -P /dev/tty.usbmodem1411 -D -b 115200
AVRASM = wine avrasm2.exe -fI

%.hex: %.asm
	$(AVRASM) $< -o $@

upload-%.hex: %.hex
	$(AVRDUDE) -U flash:w:"$<":i
