;    -------------------------    создано для ATTINY13   -------------------------------------------------------------------------------
;	прошивка через USBASP : avrdude -p t13 -c usbasp -P usb -U flash:w:FILE_NAME.hex
;   прошивка через ARDUINO( UNO, NANO )  : avrdude -p t13  -c avrisp -b 19200 -P /dev/ttyUSB0  -U flash:w:FILE_NAME.hex

;  ==================================================================
;  ======================  работа с EEPROM: Запись и чтение  ====================
;  ==================================================================
;     яркость светодиода на 0 пине управляется ШИМ 

;   Программа изменения яркости светодиода нажатием кнопки. 
; Одна кнопка используется и для изменения, и для сохранения значения яркости 
; светодиода, храним данные в EEPROM
; Короткие нажатия на кнопку меняют яркость, а длинные приводят к
; записи текущего значения.



.INCLUDEPATH "/home/user/proj/avr/avra/" ; путь для подгрузки INC файлов
.INCLUDE "tn13def.inc"            ; загрузка предопределений для ATiny13
.LIST                           ; включить генерацию листинга
;

; data segment  
; --------------------------------------------------
.dseg 


;code segment
; --------------------------------------------------
.cseg
;  -----  векторы прерываний  -----------
;
; при запуске - RESET
rjmp RESET ; Reset Handler
; нет прерываний - все обработчики ставим на сброс
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



cli
; ---  настройка  пинов контроллера ------------------
; пин 0 - светодиод меняет яркость
; пин 3 - сигнальный светодиод
; пин 4 - кнопка
;DDRB - 3 и 0 пин на вывод
ldi R16,(1<<DDB3) | (1<<DDB0)
out DDRB,R16
; PORTB  3 пин высокий, пин 4 подтянут к "+"
ldi R16, (1<<PORTB3) | (1<<PORTB4)
out PORTB,R16 

; ----------настройка таймера для ШИМ  ----------
;  TCCR0A - PHASE CORRECT on compare math A
 ldi r16,(1<<COM0A1) | (0<< COM0A0) | (0<<WGM01) | (1<<WGM00)
 out TCCR0A, r16

;   TCCR0B 
ldi r16,(0<<CS02) | (0<<CS01)  |  (1<<CS00) | (0<<WGM02) 
out TCCR0B,R16			; PRESCALER - 1


; ---------------------------------------- init param -----------------------------------------

; --------- EEPROM  ----------------
; при вызове на чтение и запись необходимо установить
; значения адреса (address) и данных для записи( байт в data)
.def address=R25  	; имя регистра с адресом записи в EEPROM
.def data=r24 			; имя регистра с записываемым байтом 
ldi address,0x0000
rcall EEPROM_read		; берём значение яркости при старте
cpi data, shift + 1
in r16,SREG
sbrc r16,SREG_C
ldi data,2
out  OCR0A,data

; ------- задержки  ------------
.def counter0=r0
.def counter1=r1
; кнопка
.equ button_pin=PORTB4
.equ short_press=2 			; короткое нажатие - меняем яркость
.equ long_press=30			; длинное нажатие - запись значения яркости в EEPROM
.def press_counter=r23    ; фиксирует длительность нажатия на кнопку


; -----------  PWM values  ---------------
; максимальное и минимальное значение яркости
.equ min_PWM=16
.equ max_PWM=229
; шаг изменения яркости
.equ shift=16

; -----------  flags  -------------
.def flags=r22
.equ add_flag=1  ; если установлен яркость прибавляется 
.equ add_flag_bit=0


sei
; настройка окончена

MAIN:
	sbi PORTB, PORTB3
	rcall DELAY
	sbic PINB, PORTB4
	;проверка на изменение или запись при отпущенной кнопке
	rjmp CHECK_ON_RELEASE
	cpi press_counter, long_press
	; если кнопка нажата дольше наибольшей длительности значение счётчика не меняем
	brcc MAIN
	inc press_counter
	NOP
rjmp MAIN

; ---------------------  проверка -----------------------------
;       происходит при отжатой кнопке
CHECK_ON_RELEASE:
	cpi press_counter, short_press-1
	 ; нет нажатия или дребезг кнопки - выход
	brcs DROP_PRESS_COUNTER
	cpi press_counter, long_press -1
	; короткое  нажатие - менять яркость
	brcs CHANGE_VALUE
	; длиное нажатие - начинаем запись в EEPROM
	rcall BLINK
	in data, OCR0A
	ldi address, 0x0000
	cli
	rcall EEPROM_write
	sei
	rcall BLINK
	rcall BLINK
DROP_PRESS_COUNTER:
	ldi press_counter,0
	rjmp MAIN

; изменяем значение ШИМ	
CHANGE_VALUE:
	rcall SMALL_BLINK
	in r16,OCR0A
	; при значениях меньше минимального ставим флаг сложения
	cpi r16, min_PWM
	in r17,SREG
	sbrc r17,SREG_C 
	sbr flags, add_flag
	; при значениях больше максимального удаляем флаг сложения
	cpi r16, max_PWM
	in r17,SREG
	sbrs r17,SREG_C
	cbr flags, add_flag
	; set value
	sbrc flags, add_flag_bit
	; если флаг сложения установлен идём к сложению
	rjmp ADD_SHIFT
	; нет флага - вычитаем
	subi r16,shift
	out OCR0A,r16
	rjmp DROP_PRESS_COUNTER
ADD_SHIFT:
	subi r16, -shift
	out OCR0A,r16
	rjmp DROP_PRESS_COUNTER
	
	

;задержка для уточнения состояния кнопки
DELAY:
	dec counter0
	brne DELAY	
	dec counter1
	brne delay
	ldi r16,30
	mov counter1,r16
ret	
	
; мигание светодиода на 3 пине
BLINK:	; серия миганий при записи в EEPROM
	sbi PORTB,PORTB3
	rcall DELAY
	rcall DELAY
	cbi PORTB,PORTB3
	rcall DELAY
	rcall DELAY
	sbi PORTB,PORTB3
	rcall DELAY
	rcall DELAY
	cbi PORTB,PORTB3
	rcall DELAY
	rcall DELAY
SMALL_BLINK:  ; мигнуть при изменении яркости
	cbi PORTB,PORTB3
	rcall DELAY
	sbi PORTB,PORTB3
	rcall DELAY
	rcall DELAY
ret


; -------------------------------------------------------------------------------------------------------
; --------------------   операции с  EEPROM   -------------------------------------------------
; -------------------------------------------------------------------------------------------------------

; чтение из EEPROM
EEPROM_read: 
	sbic EECR,EEPE 
	rjmp EEPROM_read ; ждём окончание записи если есть  
	out EEARL, address ; указали адрес
	sbi EECR,EERE ; начать чтение
	in data,EEDR ; вносим данные в регистр данных
	; далее три мигания, чтобы отметить окончание чтения
	rcall BLINK
	rcall BLINK
	rcall BLINK
ret

; записьв EEPROM
EEPROM_write:
	 sbic EECR,EEPE ;  ждём окончание записи если есть
	 rjmp EEPROM_write
	 ldi r16, (0<<EEPM1)|(0<<EEPM0) ; атомарный доступ на стирание и запись
	 out EECR, r16 
	 out EEARL, address  ; указали адрес
	 out EEDR,data          ; установка данных для записи
	 sbi EECR,EEMPE 	   ; установили бит записи
	 sbi EECR,EEPE   	   ;  старт записи
ret

;  EEPROM segment
; ----------------------------------
.eseg     ; 
