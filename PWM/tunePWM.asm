;
; управляемый шим по кнопке
; жмём кнопку - яркость меняется
;


;   includes must be uncomment for "avra" compilation
.INCLUDEPATH "/some/proj/avr/avra" ; путь для подгрузки INC файлов
.INCLUDE "tn13def.inc"            ; загрузка предопределений для ATiny13
.LIST                           ; включить генерацию листинга
;

; ----------------------------------------------------------------
; --------------------   ОПРЕДЕЛЕНИЯ  ----------------------------
; ----------------------------------------------------------------

; variables
.def t_out_count=r1			; 
.def timer_tick=r0
.def press_counter=r24		; for handle contact chatter
.def light_value=r23

;  constants
.equ max_check_val= 16		;
.equ button_pin = PINB4		;
.equ max_tick_count = 16	; for handle contact chatter
.equ max_light_value = 126	;
.equ min_light_value = 1	;

;  FLAGS
.def flags=r20
.equ time_out_flag = 0		; for handle contact chatter
.equ time_out_flag_bit = 1
.equ grow_flag = 1
.equ grow_flag_bit = 2





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
rjmp TIM0_OVF  ; Timer0 Overflow Handler
rjmp RESET  ; EEPROM Ready Handler
rjmp RESET  ; Analog Comparator Handler
rjmp RESET  ; Timer0 CompareA Handler
rjmp RESET  ; Timer0 CompareB Handler
rjmp RESET  ; Watchdog Interrupt Handle

;---------------------  INTERRUPT HANDLERS -----------------------------
;   TIMER INTERRUPT HANDLER
; check button state and  handle contact chatter
TIM0_OVF:
	sbrs flags,time_out_flag 
	reti					; check off if button not pressed on first time
	in r16,SREG
	push r16
	dec timer_tick
	breq CHECK
	rjmp END_TIMER
CHECK:
	ldi r17,max_tick_count
	mov timer_tick,r17
	cbr flags,time_out_flag_bit
END_TIMER:
	pop r16
	out SREG,r16
	reti
	


;  on reset action
RESET:
; -- инициализация стека --
ldi r16, Low(RAMEND)  ; младший байт конечного адреса ОЗУ в R16
out SPL, r16          ; 

;  =======================   INIT   ================================
cli
; ---------- pin config --------------
;PB4 - in  button pin( кнопка)
;PB0 - out led pin(светодиод)
ldi r16,(1<<PORTB4) | (1<<PORTB0) 
out PORTB,r16
ldi r16,(0<<DDB4) | (1<<DDB0)
out DDRB,r16

;  -------------- timer ---------------
; TCCR0A  fast pwm + clear on compare match
ldi r17, (0<<COM0A0) | (1<<COM0A1) | (1<<WGM00) | (1<<WGM01)
out TCCR0A,r17

; TCCR0B fast PWM + no prescaler
ldi r17, (0<<WGM02) | (1<<CS00) | (0<<CS01) | (0<<CS02)
out TCCR0B,r17

; TIMSK0 timer overflow interrupt enabled
ldi r17,(1<<TOIE0)
out TIMSK0,r17
;----------------------------------
;----------------------------------

; set start values
ldi flags,0
sbr flags , grow_flag_bit	; set grow flag
ldi light_value, 16
out OCR0A,light_value		; start light value = 16


sei
; ===================   END INIT   ============================

; -----------------  MAIN  -----------------------
MAIN:
	; CHECK time out
	sbrc flags,time_out_flag
	rjmp END_MAIN
	; check button state
	sbic PINB,button_pin			
	; button not pressed -> DROP COUNTER
	rjmp DROP					
	; button pressed -> INCREASE COUNTER
	inc press_counter ; 
	cpi press_counter,max_check_val
	; pressed times > max_check_val -> set new value
	brcc HANDLE_BUTTON_PRESS	
	sbr flags,time_out_flag_bit		
END_MAIN:	
	rjmp main		;
;  ----------------- END MAIN ------------------

; button not pressed - drop counter 
DROP:
	ldi press_counter,0
	rjmp main

;  change value for PWM 
HANDLE_BUTTON_PRESS:
	ldi press_counter,0
;  change light value
	sbrc flags,grow_flag
	; grow flag set -> grow light
	rjmp GROW
	; grow flag clear -> decrease light
	subi light_value,1  
	rjmp END_BUTTON_PRESS
GROW:	
	subi light_value,(-1) ; grow light: x-(-1)=x+1
END_BUTTON_PRESS: 
; CHECK	LIGHT value and set appropriate grow_flag(if needed)
	cpi light_value, max_light_value
	brcs CHECK_ON_MIN
	; value=max -> grow flag clear
	ldi light_value,max_light_value
	cbr flags,grow_flag_bit
	rjmp END_CHECK
CHECK_ON_MIN:
	; value=min -> grow flag set
	cpi light_value,min_light_value
	brcc END_CHECK
	ldi light_value,0
	sbr flags,grow_flag_bit
END_CHECK:
;  set light value
	out OCR0A,light_value
	sbr flags,time_out_flag_bit
	rjmp MAIN


;  EEPROM segment
; ----------------------------------
.eseg     ; 





