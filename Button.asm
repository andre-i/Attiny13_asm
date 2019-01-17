; -------------  работа портов ввода и вывода ---------------------------
;  	к 3 пину подключен светодиод( настроен на вывод) 
; 	к 4 пину подключена кнопка(настроен на ввод)
; Состояние светодиода зависит от кнопки. При нажатой кнопке диод гаснет
; при отпущенной горит.

;		прошиваем : avrdude -p t13 -c usbasp -P usb -U flash:w:FILE_NAME.hex
;   прошивка через ардуину  : avrdude -p t13  -c avrisp -b 19200 -P /dev/ttyUSB0  -U flash:w:FILE_NAME.hex
;   includes
;
:


.includepath "/home/user/proj/avr/avra/" ; путь для подгрузки INC файлов
.include "tn13def.inc"            ; загрузка предопределений для ATiny13
.list                           ; включить генерацию листинга
;

; data segment  
; --------------------------------------------------
.dseg 


;code segment
; --------------------------------------------------
.cseg
;  -----  interrupts vectors  -----------
;
; by default - RESET
rjmp RESET ; Reset Handler
rjmp RESET ; EXT_INT0 ; IRQ0 Handler
rjmp RESET ; PCINT0 ; PCINT0 Handler
rjmp RESET ; TIM0_OVF ; Timer0 Overflow Handler
rjmp RESET ; EE_RDY ; EEPROM Ready Handler
rjmp RESET ; ANA_COMP ; Analog Comparator Handler
rjmp RESET ; TIM0_COMPA ; Timer0 CompareA Handler
rjmp RESET ; TIM0_COMPB ; Timer0 CompareB Handler
rjmp RESET ; WATCHDOG ; Watchdog Interrupt Handler
rjmp RESET ; ADC ; ADC Conversion Handler

RESET:
; -- инициализация стека --
; старший байт ATtiny13 не нужен(адреса вмещаются в 1 байт)
ldi r16, Low(RAMEND)  ; младший байт конечного адреса ОЗУ в R16
out SPL, r16          ; установка младшего байта указателя стека

; ---  настройка
cli

; PORTS
; portb4 - button, portb3 - led
ldi r16, (1<<PORTB3) | (1<<PORTB4) ; 3 пин - высокое состояние, 4 подтянут к "+"
out PORTB, r16
ldi r16, (1<<DDB3) | (0<<DDB4) ; 3 пин - вывод. 4 - ввод
out DDRB, r16

;------------  INIT --------------------
; счётчики для формирования задержки
.def counter=r0
.def counter1=r1
ldi r16,5
mov r1, r16
; флаговый регистр нужен для установки состояния пина светодиода
.def flags=r25
.equ LOW_FLAG=1
.equ LOW_FLAG_BIT=0
sbr flags,LOW_FLAG

sei
; настройка окончена

MAIN:
	rcall DELAY
	nop
	sbic PINB, PORTB4
	;если состояние низкое - подать 1 на 3 пин
	rjmp TO_HIGHT
	rjmp TO_LOV
rjmp MAIN

; зажгли диод
TO_HIGHT: 
	sbi PORTB, PORTB3
	rjmp MAIN

; погасили диод
TO_LOV:
	cbi PORTB, PORTB3
	rjmp MAIN

; задержка нужна для обхода дребезга кнопки при нажатии
DELAY:
	dec counter
	brne DELAY
	dec counter1
	brne DELAY
	ldi r16,150
	mov r1, r16
ret


;  EEPROM segment
; ----------------------------------
.eseg     ; 


