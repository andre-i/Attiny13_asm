;		прошивка через USBASP : avrdude -p t13 -c usbasp -P usb -U flash:w:FILE_NAME.hex
;   прошивка через arduinoUNO(nano)  : avrdude -p t13  -c avrisp -b 19200 -P /dev/ttyUSB0  -U flash:w:FILE_NAME.hex

; пример с работой ватчдога(WD).
; моргание светодиодов происходит по прерыванию WD
; на пины 3 и 4 через резисторы ~300-600 Ом подключаем светодиоды
; при прерывании от WD менямем состояние светодиодов


;   includes
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
;  -----  векторы прерываний  -----------
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
rjmp WATCHDOG ; Watchdog Interrupt Handler
rjmp RESET ; ADC ; ADC Conversion Handler


RESET:
; -- инициализация стека --
; старший байт ATtiny13 не нужен(адреса SRAM вмещаются в 1 байт)
ldi r16, Low(RAMEND)  ; младший байт конечного адреса ОЗУ в R16
out SPL, r16          ; установка младшего байта указателя стека

; ---  настройка
cli

;  периферия
; DDRB
; 3 и 4 пин как вывод
ldi r16, (1<<DDB3) | (1<<DDB4)
out DDRB,r16
; PORTB пин 3 -высокий (светодиод горит), на пине 4 светодиод не светит
ldi r16,(1<<PORTB3)
out PORTB,r16

; ватчдог
; MCUSR регистр состояния контроллера

; WDTCR - таймер ватчдога
; WDTIE - прерывания по таймеру WD разрешены, WDE=0 - запрет на сброс по WD, WDP[0-3] - настройка таймера WD
ldi r16, (1<<WDTIE) | (0<<WDE) | (WDP2<<1) | (1<<WDP1) ; таймер WD ~  1сек
out WDTCR,r16

; стартовые значения
; для инверсии мигалки
.def invert=r0
ldi r16,0b00011000
mov r0,r16

sei
; настройка окончена


MAIN:
	;here must be some useful action
	nop
	nop
rjmp MAIN	


;обработчик прерываний по WD
; при каждом обращении инвертирует состояние светодиодов
WATCHDOG:
	push r16
	in r16,PORTB; прочитали состояние
	eor r16,invert ; инвертировали его
	out PORTB,r16 ; записали обратно в порт
	pop r16
reti


;  EEPROM segment
; ----------------------------------
.eseg     ; 
