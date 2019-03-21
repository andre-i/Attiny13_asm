;		прошиваем USBASP : avrdude -p t13 -c usbasp -P usb -U flash:w:PWMexample.hex
;		прошивка через ардуину  : avrdude -p t13  -c avrisp -b 19200 -P /dev/ttyUSB0

;	=========================================================
;   ===================== простой ШИМ  ==========================
;   =========================================================
;   Аппаратный шим реализован на 0 пине. присоединяем к нему светодиод. Он будет 
;  гореть , но не ярко. Никаких изменений не предусмотрено с целью упрощения.
;  Устанавливается значение яркости и ничего более.
;

;   includes
; здесь надо подставить своё значение пути к файлам определений
.includepath "/путь/для/подгрузки/INC/файлов/" ; 
.INCLUDE "tn13def.inc"            ; загрузка предопределений для ATiny13
.LIST                           ; включить генерацию листинга
; data segment  
; --------------------------------------------------
.dseg 


;code segment
; --------------------------------------------------
.cseg
;;;  -----  interrupts vectors  ----------
; by default - reset  

.ORG 0x0000 
	rjmp RESET ; Reset Handler 
.ORG 0x0001
	rjmp RESET ; EXT_INT0 ; IRQ0 Handler
.ORG 0x0002
	rjmp RESET ; PCINT0 ; PCINT0 Handler
.ORG 0x0003 
	rjmp  RESET ;TIM0_OVF ; Timer0 Overflow Handler
.ORG 0x0004 
	rjmp RESET ; EE_RDY ; EEPROM Ready Handler
.ORG 0x0005 
	rjmp RESET ; ANA_COMP ; Analog Comparator Handler
.ORG 0x0006 
	rjmp RESET ; TIM0_COMPA ; Timer0 CompareA Handler
.ORG 0x0007 
	rjmp RESET ; TIM0_COMPB ; Timer0 CompareB Handler
.ORG 0x0008 
	rjmp RESET ; WATCHDOG ; Watchdog Interrupt Handler
.ORG 0x0009
	rjmp RESET ; ADC ; ADC Conversion Handler

RESET:
; -- инициализация стека --
LDI R16, Low(RAMEND)  ; младший байт конечного адреса ОЗУ в R16
OUT SPL, R16          ; установка младшего байта указателя стека

; настройка
;--------------------  INIT  --------------------------------------
cli
; ---- порт 0 для шима ----
ldi r16,(1<<DDB3) ;  устанавливаем бит для 3 пина 
out DDRB, r16 ;  настройка порта на вывод
clr r16

; --------------  timer ----------------
; все настройки аппаратного ШИМ  устанавливаются в таймере
;  для ШИМ берётся регистр OCR0A (пин 0)
;  TCCR0A - PHASE CORRECT on compare math A
 ldi r16,(1<<COM0A1) | (0<< COM0A0) | (0<<WGM01) | (1<<WGM00)
 out TCCR0A, r16

;   TCCR0B предделитель - 1,таймер тикает с частотой контроллера
ldi r16,(0<<CS02) | (0<<CS01)  |  (1<<CS00) | (0<<WGM02) 
out TCCR0B,R16			; 



; -------- устанавливаем значение яркости --------------
ldi r16,16
out OCR0A,r16
sei

;--------------------------  MAIN  --------------------------------
;---------------------------------------------------------
;  --------------- ГЛАВНЫЙ ЦИКЛ ----------------------
;---------------------------------------------------------
MAIN:
	; there may be some useful action
	nop
	rjmp MAIN

;----------------------------------------------------------------
;                       END_MAIN
;;---------------------------------------------------------------


;;  ==================   END OF PROGRAMM   ======================
rjmp RESET

;  EEPROM segment
; ----------------------------------
.eseg    
