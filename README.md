# Attiny13_asm
Small example work with Attiny13 on assembly
## Небольшие примеры работы с контроллером Attiny13 на ассемблере
Примеры содержат настройку работы с таймером, перифeрией.
#### Компиляция
 Компилировать можно в avr(atmel)studio или компилятором *avra*. Если компилируем 
через *avra* надо в asm файлах  раскомментировать вторую и третью строку.
	 
#### Прошиваем в avrdude
+ программатор USBASP:
	- прошивка: *avrdude -p t13 -c usbasp -P usb -U flash:w:ИМЯ_ФАЙЛА.hex*
	- посмотреть фьюзы: *avrdude -p t13 -c usbasp -P usb*  
+ Arduino :
	- шьём в ардуино скетч  ArduinoISP
	- прошивка: *avrdude -p t13  -c avrisp -b 19200 -P /dev/ttyUSB0 -U flash:w:ИМЯ_ФАЙЛА.hex*
	- посмотреть фьюзы: *avrdude -p t13  -c avrisp -b 19200 -P /dev/ttyUSB0*
	
1. Button.asm - работа порта ввода-вывода. Кнопка соединена с пином 4, светодиод с 3. 
	При нажатии на кнопку состояние светодиода меняется.
	
	| схема | макет |
	| --------- | --------- |
	| ![Схема](https://github.com/andre-i/Attiny13_asm/blob/master/pict/button.png) | ![макет](https://github.com/andre-i/Attiny13_asm/blob/master/pict/buttonmack.png) |
	
2. SimplePWM.asm - программый шим. Присоединённый к пину светодиод светит с некоторым промежуточным значением.
	
	| схема | макет |
	| --------- | --------- |
	|![simplePWM](https://github.com/andre-i/Attiny13_asm/blob/master/pict/simplePWM.png)|![simplePWM](https://github.com/andre-i/Attiny13_asm/blob/master/pict/simplePWMmack.png)|
	
3. TunePWM.asm -  управляем ШИМ кнопкой. При нажатии на кнопку яркость светодиода плавно изменяется. 
	
	| схема | макет |
	| --------- | --------- |
	|![tunePWM](https://github.com/andre-i/Attiny13_asm/blob/master/pict/tunePWM.png)|![tunePWM](https://github.com/andre-i/Attiny13_asm/blob/master/pict/tunePWMmack.png)|
		
4. WD_interrupt - прерывания от ватчдога(WD) . В обработчике прерываний меняется состояние присоединённых к пинам 3 и 4 светодиодов.  
	
	| схема | макет |
	| --------- | --------- |
	|![WD_intr](https://github.com/andre-i/Attiny13_asm/blob/master/pict/WD_interrupt.png)|![WD_intr](https://github.com/andre-i/Attiny13_asm/blob/master/pict/WD_mack.png)|
	
5. WDwakeUP.asm - Работа ватчдога. Запускаем таймер ватчдога и отправляем контроллер в состяние сна. По истечении работы таймера контроллер выходит из этого состояния.
	
	| схема | макет |
	| --------- | --------- |
	|![WDwakeUP](https://github.com/andre-i/Attiny13_asm/blob/master/pict/WD_interrupt.png)|![WD_intr](https://github.com/andre-i/Attiny13_asm/blob/master/pict/WD_mack.png)|
	
6. Eeprom.asm - запись и чтениe значения в EEPROM. При старте контроллера из EEPROM читается значение и устанавливается как яркость свечения светодиода. При коротком нажатии на кнопку меняется значение яркости. А при длительном - записывается в EEPROM текущее значение яркости свечения. 
	
	| схема | макет |
	| --------- | --------- |
	|![EEPROM](https://github.com/andre-i/Attiny13_asm/blob/master/pict/EEPROM.png)| ![EEPROM](https://github.com/andre-i/Attiny13_asm/blob/master/pict/EEPROMmack.png)| 
7. DS18B20_thermometer - измерение температуры датчиком DS18B20. Количество ножек контроллера не позволяет подключить 
дисплей. Для индикации используются два диода: красный(tens_led_pin) для десятков и зелёный(ones_led_pin) для единиц. Количество блинков соответствует количеству десятков и единиц. Температура измеряется в градусах по Цельсию. Файл 1-wireProto.asm содержит подпрограммы работы с шиной "one wire"  на уровне протокола( сигнал сброса, чтение и запись байта , проверка crc отсутствует).
	
	| схема | макет |
	| --------- | --------- |
	|![DS18B20_thermometer](https://github.com/andre-i/Attiny13_asm/blob/master/pict/DS18B20_thermometer.png)| ![DS18B20_thermometer](https://github.com/andre-i/Attiny13_asm/blob/master/pict/DS18B20_thermometer_mack.png)|
	

