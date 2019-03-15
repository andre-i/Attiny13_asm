; base op on protocol
;	1 Reset-presence
;	2 read byte
;	3 write byte


;must be defined 
;	wire_pin - port on bus(PORT...)
;	ow_byte - register contain data(r16-r31)

; on RESET-PRESENCE device found -> set T flag(SREG)
; clear otherwice

;________________________________________________
;
; ----------	WARNING !!!	---------
; all operation broken XH and XL registers
;	
;________________________________________________


; ------------------  delays in cycles  -------------------------
;     all result follow from freq ~ 9 600 000Hz 
;     DELAY function(subroutine) take (num*4 + 15) cycles on call, 
;     this implies  num = (cycles - 15)/4 - 1

; for numbers small  than 256 hight byte is 0
.equ without_delay_H=0
;   reset - presence
.equ reset_delay_H=0x04				;reset cycles=4616 number=1151
.equ reset_delay_L=0x81				; really time may be slightly groowe 1152
.equ check_presence_delay=0xA5		;delay cycles=673 number=165
.equ tail_presence_delay_H=0x03		;tail cycles=3942 number~980
.equ tail_presence_delay_L=0xD4	; 
;  write bit 1
.equ init_send_1_delay=0x0A			; cycles=58  number=10 (10,25)
.equ tail_send_1_delay=0x96			; cycles=616 number=150(150,25)
; 	write bit 0
.equ init_send_0_delay=0x8C			; cycles=577 number=140
.equ tail_send_0_delay=0x14			; cycles=96  number=20(20,75)
;  read bit 
.equ init_read_delay=0x09		; cycles=58 number=10(10,75)
.equ wait_read_delay=0x14		; cycles=86 number=18(17,75)
.equ tail_read_delay=0x7f		; cycles=528 number=128(128,25)
; ----------------------------------------------


;  ================  RESET  ====================
;	before any request must send reset sign
RESET_WIRE:
	cli
	sbi DDRB, wire_pin 			; set 0 wire pin
	rcall DELAY					; delay for RESET
	cbi DDRB, wire_pin 			; release pin
	ldi XL, reset_delay_L
	ldi XH , reset_delay_H
	rcall DELAY
	sei
ret



;  =============  RESET____Presence  =============
; set reset signal and check be present of devices
RESET_PRESENCE:
	cli
	; rjmp set_be_present		;  debug  !!!!
	; prepare for delay
	push r16
	sbi DDRB, wire_pin 			; set 0 wire pin
	ldi XL, reset_delay_L
	ldi XH , reset_delay_H
	rcall DELAY					; delay for RESET
	cbi DDRB, wire_pin 			; release pin
	ldi XL , (check_presence_delay - 0x02) 
	ldi XH , without_delay_H
	rcall DELAY					; delay for read PRESENCE
	sbis PINB, wire_pin			; read wire_pin
	rjmp set_be_present			; null on wire - devices be present
	clt							; device not found -> clear T flag(SREG)
;	cbr flags, present_flag		; device not found -> clear flag
	rjmp tail_delay
set_be_present:
	set							; device be present -> set T flag(SREG)
;	sbr flags, present_flag		; device be present -> set flag
tail_delay:
	; 8 cycles take actions -> substract 3 from numbers
	; (there delay is slightly small than see in datatsheet)
	ldi XL, (tail_presence_delay_L - 0x03)
	ldi XH, tail_presence_delay_H
	rcall DELAY
	pop r16
	sei
ret	

; ===========  WRITE_TO_LINE ==============================

WRITE_BIT_0:
	ldi XL,init_send_0_delay
	ldi XH,without_delay_H
	sbi DDRB, wire_pin 			; set 0 wire pin
	rcall DELAY
	cbi DDRB, wire_pin 			; release wire pin
	ldi XL,(tail_send_0_delay - 0x07)
	ldi XH,without_delay_H
	rcall DELAY
rjmp after_write				; return to WRITE_BYTE subroutine

WRITE_BIT_1:
	ldi XL,init_send_1_delay
	ldi XH,without_delay_H
	sbi DDRB, wire_pin 			; set 0 wire pin
	rcall DELAY
	cbi DDRB, wire_pin 			; release wire pin
	ldi XL,(tail_send_1_delay - 0x07)
	ldi XH,without_delay_H
	rcall DELAY
rjmp after_write				; return to WRITE_BYTE subroutine


WRITE_BYTE:
	cli
	push r16
	ldi r16,0
ow_write_loop: 
	ror ow_byte			; on 1bit=1 -> carry set, cleared otherwise
	brcc WRITE_BIT_0
	brcs WRITE_BIT_1 
after_write:
	inc r16
	cpi r16,8
	brne ow_write_loop
	pop r16 
	sei
ret

	
; ===============  READ FROM LINE  =====================
; 
; by exit from read C flag of SREG have same value as 
; gotten bit	
READ_BIT:	
	;cbr flags,is_read_1_flag  ; old with use flags
	clc
	ldi XL,init_read_delay
	ldi XH,without_delay_H
	sbi DDRB, wire_pin 				; set 0 wire pin
	rcall DELAY
	cbi DDRB, wire_pin 				; release wire pin
	; subtracted value must set correspond time for
	; read byte( 15ms after to down wire ) compute on cycles
	ldi XL,wait_read_delay - 0x02	; 2 - shift on operation
	ldi XH,without_delay_H
	rcall DELAY
	sbic PINB, wire_pin				; read wire_pin	
	;sbr flags, is_read_1_flag		; old with use flags
	sec								; set carry if 1 on wire pin
	ldi XL,tail_read_delay-0x06
	ldi XH,without_delay_H
	rcall DELAY
ret



READ_BYTE:
	cli
	push r16			; save tmp reg
	in r16, SREG
	push r16			; save sreg
	ldi ow_byte,0		; set 0 by byte
	ldi r16,0
ow_read_loop:
	rcall READ_BIT
	ror ow_byte
	inc r16
	cpi r16,8
	brne ow_read_loop
	pop r16
	out SREG,r16
	pop r16
	sei
ret


; --------------  delay  -----------------
;  use XH and XL registers for create delay	
					; cycles on call 
DELAY:				; 3  
	push r16		; 1
	in r16, SREG	; 1
	push r16		; 2       save SREG
loop_4cycle:
	subi XL,0x01	; 1
	sbci XH, 0x00	; 1
	brne loop_4cycle; 2 (false - 1cyc)
	; end of loop
	pop r16			; 2
	out SREG, r16	; 1
	pop r16			; 1
ret					; 4
	
	 
