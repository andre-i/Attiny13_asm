 ;		load to chip : avrdude -p t13 -c usbasp -P usb -U flash:w:wire_debug.hex
 ;    check fuses : avrdude -p t13 -c usbasp -P usb 
 ; for work must set FUSES E:FF, H:FF, L:7A ( prescaler off frequence ~ 9.6 MHz)
;   includes must have for avra assembly (avrstudio not require)
;.INCLUDEPATH "/usr/share/avra/" ; path/to/avr/inc/file
;.INCLUDE "tn13def.inc"          ; file name for ATiny13
.LIST                            ; 
;

.def tmp=r16		; temporary register

;  PORTB pins
.equ tens_led_pin=PORTB3	; blink tens count( RED may be use as err signal)
.equ ones_led_pin=PORTB4	; blink ones count( GREEN )
; 1-wire
.equ wire_pin=PORTB2
.def ow_byte=r22

;  flags 
.def flags=r23
.equ sign_flag=0b00000001					; 2^0
.equ sign_flag_bit=0			; if set number sign is minus

.equ hundred_flag=0b00000010				; 2^1
.equ hundred_flag_bit=1			; set if themperature > 100 celcius

.equ tens_light_flag=0b00000100				; 2^2
.equ tens_light_flag_bit=2		; if set must be set 1 to tens_led_pin

.equ ones_light_flag=0b000001000			; 2^3 
.equ ones_light_flag_bit=3		; if set must be set 1 to ones_led_pin

.equ get_themperature_flag=0b000010000		; 2^4
.equ get_themperature_flag_bit=4; if set must be start get themperature
								; from DS18B20 sensor process


; ones holder on start it contains ls_byte from 1-wire(value be send DS18B20)
.def ones_byte=r24	
; tens holder on start it contains ms_byte from 1-wire( DS18B20 )
.def tens_byte=r25		


; DS18B20 commands
.equ skip_rom=0xcc
.equ convert=0x44
.equ read=0xbe		; NOTE after read first 2 bytes must call reset 

;-----------------------------------------------------
;--------------------  MACRO  ------------------------
;-----------------------------------------------------

; accept thwo first bytes gotten from 1-wire line(send DS18B20)
; and compute one`s and ten`s count in data
; restrictions - not reflect hundred counts
; ----- On end work macro ------
;	@0 contain one`s count  
;	@1 contain ten`s count
;	for negative themperatures flag T of SREG be set
; 
.macro COMPUTE_DIGITS
	clt
	push tmp
	ldi tmp, 4 
shift_loop:			; shift bytes 
	;  init 
	;push tmp
	; shift bytes right and left for hold only themperature bits
	lsl @1
	lsr @0
	dec r16
	brne shift_loop
	add @0, @1 ; add for megre 2 in 1
	;  compute tens and ones count
	ldi @1 , 0
	sbrs @0, 7
	rjmp compute
	cbr @0, 0b10000000
	set					; negative value in register -> set flag T 
compute:
	cpi @0, 10			
	brcs result			; residue substraction < 10  ends of macro
	inc @1				; residue substraction > 10 -> ten count ++
	subi @0, 10
	rjmp compute
	; after all substraction  register @0 contain ones count(final residue)
result:
	pop tmp
.endm


;-----------------------------------------------------
;------------------  end MACRO  ----------------------

; data segment  
; --------------------------------------------------
.dseg 


;code segment
; --------------------------------------------------
.cseg  
; interrupt vectors
rjmp RESET ; Reset Handler
rjmp RESET  ; IRQ0 Handler
rjmp RESET  ; PCINT0 Handler
rjmp RESET	; Timer0 Overflow Handler
rjmp RESET  ; EEPROM Ready Handler
rjmp RESET  ; Analog Comparator Handler
rjmp RESET  ; Timer0 CompareA Handler
rjmp RESET  ; Timer0 CompareB Handler
rjmp RESET  ; Watchdog Interrupt Handle

; load includes
.include "1-wireProto.asm"


RESET:
; -- ATtiny13 require only low byte for stack address --
ldi r16, Low(RAMEND)  ; 
out SPL, r16          ; 

; __________________  INIT ON START  ____________________
; _______________________________________________________
; 

; init PORTB
ldi tmp, (1<<tens_led_pin)| (1<<ones_led_pin)
out DDRB,tmp

; init flags register
clr flags
sbr flags, get_themperature_flag  ; set it -> must get themperature

clr ow_byte
clr tmp
clr ones_byte
clr tens_byte



; main loop
MAIN:
	sbrs flags, get_themperature_flag_bit
	rcall SHOW_THEMPERATURE					; themperature flag clear ->
											; must show themperature
find_device:
	rcall CHECK_PRESENCE					; try start connect with DS18B20
	brtc find_device						; not connect -> retry it
	rcall GET_THEMPERATURE					;
rjmp MAIN

; on device present turn on ones_led_pin(green)
CHECK_PRESENCE:
	ldi tmp, (1<<tens_led_pin) | (1<<ones_led_pin)
	out PORTB, tmp 					; turn on leds
	rcall RESET_PRESENCE
	ldi tmp, 40
	rcall PAUSE
	brtc not_device
	cbi PORTB, tens_led_pin			; turn off red led(green on)
	rjmp end_check
not_device:
	cbi PORTB, ones_led_pin			; turn off green led(red on)
end_check:
	ldi tmp,50
	rcall PAUSE
	ldi tmp, 0
	out PORTB, tmp					; turn off all leds
	ldi tmp, 60
	rcall PAUSE
ret		

;
; get themperature from DS18B20
GET_THEMPERATURE:
	ldi ow_byte, skip_rom
	rcall WRITE_BYTE			; skip rom
	ldi ow_byte, convert
	rcall WRITE_BYTE			; convert
	; call convert themperature may be spent ~ 750ms
	ldi tmp, 11					; 10 cycles for wait(~1050 ms)
wait_themp_loop:
	dec tmp
	breq JUMP_TO_ERROR
	push tmp
	ldi tmp, 15					; ~ 105 ms
	rcall PAUSE
	pop tmp
	sbis PINB, wire_pin	
	rjmp wait_themp_loop		; wait for ready themperature convert
	rcall RESET_WIRE			; start new connections
	ldi ow_byte, skip_rom
	rcall WRITE_BYTE			; skip rom
	ldi ow_byte, read
	rcall WRITE_BYTE			; get bytes command
	clr ow_byte
	rcall READ_BYTE				; read 1 byte 
	mov ones_byte, ow_byte
	clr ow_byte
	rcall READ_BYTE				; read 2 byte
	rcall RESET_WIRE			; reset connect for second session
	cpi ow_byte, 0xff			; 2 byte can`t contain only 1(ones)
	breq JUMP_TO_ERROR					; blink on error 
	mov tens_byte, ow_byte
	; after get bytes compute tens and ones count in themperature
	COMPUTE_DIGITS ones_byte, tens_byte	
	cbr flags, get_themperature_flag
	ret							; return on success
; RETURN FROM ANY CALL(set state for convert themperature)	
end_on_error:					
	clr flags
	sbr flags, get_themperature_flag
	clt
ret								; return on error
; use for:
;	1) overhead request time
;	2) get wrong themperature value
JUMP_TO_ERROR:					
	rjmp ERROR

; 
;	implies what tens_byte contain themperature tens count
;	ones count hold ones_byte
;  here not handle negative themperatures, it show same as positive
SHOW_THEMPERATURE:
	; check ones and tens count
	cpi tens_byte, 13 		; tens may be small than 13(1-12)
	brcc JUMP_TO_ERROR
	cpi ones_byte, 10		; ones may be small than 10
	brcc JUMP_TO_ERROR
	ldi tmp, 60
	rcall PAUSE
	cpi tens_byte, 1
	brcc show_tens			; tens > 0 -> show tens
	cpi ones_byte, 1
	brcs end_show			; ones_byte=0 -> end show
	rjmp show_ones			; ones_byte > 0 -> show ones
show_tens:
	rcall BLINK_TENS
	dec tens_byte
	brne show_tens
show_ones:
	rcall BLINK_ONES
	dec ones_byte
	brne show_ones
end_show:
	ldi tmp, 60
	rcall PAUSE
	sbr flags, get_themperature_flag
	clt
	clr r1
ret



;  delay ~ 6,7ms on one cycle
; cycle count must be set in 'tmp' register
; greather value tmp 250 ~ 1700 ms
; uncomment `rcall DELAY` on production
PAUSE:
	ldi XL,0xff
	ldi XH, 0xff
	rcall DELAY
	cpi tmp, 0xfc				; on first value tmp==0 be execute						
	breq return_from_pause		; 1 times
	dec tmp
	brne PAUSE
return_from_pause:	
ret

;  blink pin for tens( must be RED )
BLINK_TENS:
	sbi PORTB, tens_led_pin
	ldi tmp,30
	rcall PAUSE
	cbi PORTB, tens_led_pin
	ldi tmp, 20
	rcall PAUSE
ret

;  blink pin for ones( must be GREEN )
BLINK_ONES:
	sbi PORTB, ones_led_pin
	ldi tmp,30
	rcall PAUSE
	cbi PORTB, ones_led_pin
	ldi tmp,20
	rcall PAUSE
ret

; blink on error
ERROR:
	ldi flags, 15
err_loop:
	sbi PORTB,tens_led_pin
	cbi PORTB, ones_led_pin
	ldi tmp,5
	rcall PAUSE
	cbi PORTB, tens_led_pin
	sbi PORTB, ones_led_pin
	ldi tmp, 5
	rcall PAUSE
	dec flags
	brne err_loop
	cbi PORTB, ones_led_pin
	ldi tmp, 60
	rcall PAUSE
rjmp end_on_error

;  EEPROM segment
; ----------------------------------
.eseg     ; 

