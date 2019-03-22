# Attiny13_asm
Small example work with Attiny13 on assembly
## Небольшие примеры работы с контроллером Attiny13 на ассемблере
Примеры содержат настройку работы с таймером, перифeрией.

1. Button.asm - работа порта ввода-вывода. Кнопка соединена с пином 4, светодиод с 3. 
	При нажатии на кнопку состояние светодиода меняется.
	
	| схема | макет |
	| --------- | --------- |
	| ![Схема](https://github.com/andre-i/Attiny13_asm/blob/master/pict/Button_circuit.png) | ![макет](https://github.com/andre-i/Attiny13_asm/blob/master/pict/Button.png) |
	
2. SimplePWM.asm - программый шим. Присоединённый к пину светодиод светит с некоторым промежуточным значением.
	![SimplePWM](https://github.com/andre-i/Attiny13_asm/blob/master/pict/simplePWM.png)
3. TunePWM.asm -  управляем ШИМ кнопкой. При нажатии на кнопку яркость светодиода плавно изменяется. 
	![SimplePWM](https://github.com/andre-i/Attiny13_asm/blob/master/pict/tunePWM.png)	
3. WD_interrupt - прерывания от ватчдога(WD) . В обработчике прерываний меняется состояние присоединённых к пинам 3 и 4 светодиодов.  
	![WD_intr](https://github.com/andre-i/Attiny13_asm/blob/master/pict/WD_interrupt.png)
4. WDwakeUP.asm - Работа ватчдога. Запускаем таймер ватчдога и отправляем контроллер в состяние сна. По истечении работы таймера контроллер выходит из этого состояния.
	![WDwakeUP](https://github.com/andre-i/Attiny13_asm/blob/master/pict/WD_interrupt.png)
4. Eeprom.asm - запись и чтени значения в EEPROM. При старте контроллера читается и устанавливается значение яркости присоединённого к 0 пину светодиода. При коротком нажатии на кнопку на пине 4 меняется значение яркости. А при длительном - записывается в EEPROM текущее значение яркости.
	![EEPROM](https://github.com/andre-i/Attiny13_asm/blob/master/pict/EEPROM.png) 
5. DS18B20_thermometer - измерение температуры датчиком DS18B20. Количество ножек контроллера не по зволяет подключить 
дисплей. Для индикации используются два диода: красный(tens_led_pin) для десятков и зелёный(ones_led_pin) для единиц. Количество блинков соответствует количеству десятков и единиц. Файл 1-wireProto.asm содержит подпрограммы работы с шиной one wire  на уровне протокола( сигнал сброса, чтение и запись байта , проверка crc отсутствует)
	![DS18B20_thermometer](https://github.com/andre-i/Attiny13_asm/blob/master/pict/DS18B20_thermometer.png)
	 
##### Прошиваем в avrdude
+ программатор USBASP:
	- avrdude -p t13 -c usbasp -P usb -U flash:w:ИМЯ_ФАЙЛА.hex
+ Arduino :
	- шьём в ардуино скетч  ArduinoISP
	- avrdude -p t13  -c avrisp -b 19200 -P /dev/ttyUSB0
