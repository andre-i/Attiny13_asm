; flash : avrdude -p t13 -c usbasp -P usb -U flash:w:first.hex
; see fuses : avrdude -p t13 -c usbasp -P usb 
;   includes
; uncomment for avra
;.INCLUDEPATH "/some/proj/avr/avra/" ; /path/to/inclusdes/file
;.INCLUDE "tn13def.inc"            ; definions for ATiny13
.LIST                           ; включить генерацию листинга
;


;  definions
.def counter=r18
.equ min_val = 30


; data segment  
; --------------------------------------------------
.dseg 


;code segment
; --------------------------------------------------
.cseg  
; interrupt vectors
rjmp RESET  ; Reset Handler
rjmp RESET  ; IRQ0 Handler
rjmp RESET  ; PCINT0 Handler
rjmp RESET  ; Timer0 Overflow Handler
rjmp RESET  ; EEPROM Ready Handler
rjmp RESET  ; Analog Comparator Handler
rjmp RESET  ; Timer0 CompareA Handler
rjmp RESET  ; Timer0 CompareB Handler
rjmp RESET  ; Watchdog Interrupt Handle

;  on reset action
RESET:
; --  stack address require only low byte  --
ldi r16, Low(RAMEND)  ; 
out SPL, r16          ; 

; --------------------  INIT ----------------------

;  -------------   PWM   ---------------------
;TCCR0A
; clear on compare and phase correct pwm
ldi r17, (1<<COM0A1)|(0 <<COM0A0) | (1<<WGM00)|(0<<WGM01) 
out TCCR0A,r17

;TCCR0B
; phase correct pwm and no prescaler
ldi R17, (0<<WGM02) | (1<<CS00) | (0<<CS01) | (0<<CS02)  
out TCCR0B,r17

;  -----------------  PIN config  -------------------------
; PORTB0 - out(PWM on TCCR0A)
ldi r17, (1<<PORTB0) 
out DDRB, r17

;  ----------------------  ADC  ---------------------------
; it reflekt voltage change on resistors divider
; ADMUX - 
;   REFS0 - reference( 1 - internal)
;   ADLAR  - ADJUST( 1 - left for 8bit conversion)
;   MUX[1 0] - source
ldi r17,(0<<REFS0) | (1 <<ADLAR) | (1<<MUX0) | (1<<MUX1) ;  pinb3 - ADC
out ADMUX,r17
; ADCSRA
;   ADEN (1 - ADC enabled)
;   ADSC (SET 1 to start, mcu set it to 0 when conversion complete 
;   ADPS[0-2]  prescaler( here 1/16)
ldi r17,(1<<ADEN) | (1<<ADPS2) | (0<<ADPS1) | (0<<ADPS0) ; 
out ADCSRA,r17
 
; DIDR0 whether disable digital input (1 - DISABLE)
ldi r17, (1<<ADC3D) 
out DIDR0, r17

;
;----------------------------  MAIN  ---------------------------------
;
MAIN:
    ; here may be some
    ; usefull actions
    dec counter             ; mock useful action
    sbic ADCSRA,ADSC        ; ADSC=0 -> conversion complete
    brne MAIN
    rcall setValue
    sbi ADCSRA,ADSC         ; may be start new conversion
    rjmp MAIN
	
	
; out ADC value to PWM 	
setValue:	
    ; for 8bit conversion read only ADCH register
    in r1,ADCH
    out OCR0A,r1
ret

rjmp RESET ; on some left

;  EEPROM segment
; ----------------------------------
.eseg     ; 
