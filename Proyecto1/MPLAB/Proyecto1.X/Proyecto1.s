;Archivo: Laboratorio5.S
;Dispositivo: PIC16F887
;Autor: Ashley Morales
;Compilador: pic-as (v2.30), MPLABX V5.45
;
;Programa: Displays Simultaneos
;Hardware: Displays en PORTC y PORTD, contador 8 bits PORTA, push buttons en RB4 y RB5
;
;Creado: 2 marzo, 2021
;Última modiciación: 
    
PROCESSOR 16F887		;Incluyendo microcontrolador y librerias utiles
#include <xc.inc>   
#include "Macros.s"

;CONFIG1
CONFIG FOSC=INTRC_NOCLKOUT  ;Eligiendo oscilador interno
CONFIG WDTE=OFF		    ;WDT desactivado
CONFIG PWRTE=OFF	    ;PWRT activado
CONFIG MCLRE=OFF	    ;PIN MCLR usado como I/O
CONFIG CP=OFF		    ;Protección de código desactivada
CONFIG CPD=OFF		    ;Proteción de datos desactivada
CONFIG BOREN=OFF	    ;No reset si Vdd < 4V
CONFIG IESO=OFF		    ;Reset sin cambiar reloj interno a reloj externo
CONFIG FCMEN=OFF	    ;Cambiar reloj externo a reloj interno en caso de fallas 
CONFIG LVP=ON		    ;LVP activado  

;CONFIG2
CONFIG WRT=OFF	            ;Protección de autoescritura para programa desactivado
CONFIG BOR4V=BOR40V         ;Reset si Vdd < 4V (BOR21v=2.1V)

;VARIABLES
    GLOBAL Unidades
    GLOBAL Decenas
    GLOBAL Tiempo1M1
    GLOBAL Tiempo2M1
    GLOBAL Tiempo3M1
    GLOBAL Resta
    GLOBAL modo_numero_
    
    PSECT udata_bank0
    modo_numero_: DS 1	;Variable que controla el modo seleccionado
    Tiempo1M2: DS 1
    Multiplexado: DS 1	;Variable para controlar el multiplexado
    Resta: DS 1
    W_TEMP: DS 1	;Registro temporal para W
    STATUS_TEMP: DS 1	;Registro temporal para STATUS
    
    PSECT udata_shr	;Memoria común
    Unidades: DS 4	;Variable para almacenar las unidades de los tiempos  
    Decenas: DS 4	;Variable para almacenar las decenas de los tiempos
    Tiempo1M1: DS 1	;Variable para controlar el tiempo de semaforos en modo 1
    Tiempo2M1: DS 1	;Variable para controlar el tiempo de semaforos en modo 1
    Tiempo3M1: DS 1	;Variable para controlar el tiempo de semaforos en modo 1
    
    
;VECTOR RESET 
    PSECT resVect, class=code, abs, delta=2
    ORG 00h		;Posición para reset
    resetVec: 
    PAGESEL main
    goto main

;VECTOR DE INTERRUPCIÓN  
    PSECT intVect, class=CODE, abs, delta=2
    ORG 04h
   
    push: 
    movwf W_TEMP	   ;Mover datos en W a W_TEMP
    swapf STATUS, W	   ;Mover datos en STATUS a W
    movwf STATUS_TEMP	   ;Mover W a STATUS_TEMP
    
    isr: 
    btfsc PIR1, 0	   ;Revisar si la bandera de Overflow para Timer0 se levanto
    call reinicio_timer1   ;Llamar subrutina para incrementar los contadores para modo1
    btfsc INTCON, 0	   ;Revisar si uno de los pines cambio de estado, usando RBIF
    call control_modos	   ;Llamar subrutina para incrementar la variable que controla el modo seleccionado
    
    pop:
    swapf STATUS_TEMP, W    ;Mover datos en STATUS_TEMP a W
    movwf STATUS	    ;Mover datos en W a STATUS
    swapf W_TEMP, F	    ;Mover W_TEMP al registro
    swapf W_TEMP, W	    ;Mover W_TEMP a W
    retfie    

;SUBRUTINAS DE INTERRUPCION
    reinicio_timer1:
    banksel PORTA
    movlw 0xE1		    ;Cargar valor en TMR1H para una interrupcion cada segundo
    movwf TMR1H
    movlw 0x7C		    ;Cargar valor en TMR1L para una interrupcion cada segundo
    movwf TMR1L
    decf Tiempo1M1	    ;Decrementar valor asignado a Tiempo1M1
    decf Tiempo2M1	    ;Decrementar valor asignado a Tiempo2M1
    decf Tiempo3M1	    ;Decrementar valor asignado a Tiempo3M1
    bcf PIR1, 0		    ;Bajar bandera de Timer1 Overflow 
    return
    
    control_modos:  
    incf modo_numero_	    ;Incrementar variable modo_numero
    bsf Multiplexado, 5
    bcf INTCON, 0
    return
    
;MICROCONTROLADOR
    PSECT code, delta=2, abs
    ORG 100h		    ;Posición para código
    
Convertidor:
    clrf PCLATH
    bsf PCLATH, 0	;Eligiendo posición 0100h
    andlw 00001111B
    addwf PCL		;PC = PCLATH + PCL
    retlw 00111111B	;0
    retlw 00000110B	;1
    retlw 01011011B	;2
    retlw 01001111B	;3
    retlw 01100110B	;4
    retlw 01101101B	;5
    retlw 01111101B	;6
    retlw 00000111B	;7
    retlw 01111111B	;8
    retlw 01101111B	;9
    
;SETUP
    main:
    bsf INTCON, 7	;Habilitando las interrupciones globales
    bsf INTCON, 6	;Habilitando interrupciones perifericas
    
    Botones			    ;Llamando configuraciones mediante macros
    Via_en_configuracion
    Vias_y_configuracion_tiempo
    Semaforos
    Oscilador
    Interrupcion_Timer1
    Tiempo_Semaforos_Modo1
    Interrupt_On_Change
    
    banksel PORTA
    
;MAIN LOOP	
    loop:
    call Modo1		;Llamar subrutina para modo 1
    movlw 1
    subwf modo_numero_, 0
    btfsc STATUS, 2
    call Modo2
    call Toggle		;Llamar subrutina para multiplexar los displays
    goto loop

;SUBRUTINAS
    Modo2:
    movlw 14
    movwf Tiempo1M2
    call Division
    return
    
    Modo1:
    call Division	;Llamar subrutina para convertir valores a decimal
    
    ;SEMAFORO 1
    movlw 10		    ;Si el tiempo en Tiempo1M1 es 10, entonces:
    subwf Tiempo1M1, 0
    btfsc STATUS, 2
    bsf PORTA, 2	    ;Encender led verde
    btfsc STATUS, 2
    bcf PORTA, 0	    ;Apagar led roja para el semaforo 1
    btfsc STATUS, 2
    bsf PORTA, 3	    ;Encender led roja para el semaforo 2
    btfsc STATUS, 2
    bsf PORTA, 6	    ;Encender led roja para el semaforo 3
    movlw 6		    ;Si el tiempo en Tiempo1M1 es 6, entonces:
    subwf Tiempo1M1, 0
    btfsc STATUS, 2
    bcf PORTA, 2	    ;Hacer titilar led verde
    btfsc STATUS, 2
    bsf PORTA, 2
    btfsc STATUS, 2
    bcf PORTA, 2
    movlw 5		    ;Hacer titilar led verde
    subwf Tiempo1M1, 0
    btfsc STATUS, 2
    bsf PORTA, 2
    btfsc STATUS, 2
    bcf PORTA, 2
    btfsc STATUS, 2
    bsf PORTA, 2
    movlw 4		    ;Hacer titilar led verde
    subwf Tiempo1M1, 0
    btfsc STATUS, 2
    bcf PORTA, 2
    btfsc STATUS, 2
    bsf PORTA, 2
    btfsc STATUS, 2
    bcf PORTA, 2
    movlw 3		    ;Si el tiempo en Tiempo1M1 es 3, entonces:
    subwf Tiempo1M1, 0
    btfsc STATUS, 2
    bsf PORTA, 1	    ;Encender led amarilla
    movlw 0		    ;Si el tiempo en Tiempo1M1 es 0, entonces:
    subwf Tiempo1M1, 0
    btfsc STATUS, 2
    bcf PORTA, 1	    ;Apagar led amarilla
    btfsc STATUS, 2
    call TopeS		    ;Llamar subrutina para regresar al tiempo inicial
    
    ;SEMAFORO 2
    movlw 10		    ;Si el tiempo en Tiempo2M1 es 10, entonces:
    subwf Tiempo2M1, 0
    btfsc STATUS, 2
    bsf PORTA, 5	    ;Encender led verde
    btfsc STATUS, 2
    bcf PORTA, 3	    ;Apagar led roja
    movlw 6		    ;Si el tiempo en Tiempo2M1 es 6, entonces:
    subwf Tiempo2M1, 0
    btfsc STATUS, 2
    bsf PORTA, 5	    ;Hacer titilar led verde
    btfsc STATUS, 2
    bcf PORTA, 5
    movlw 5
    subwf Tiempo2M1, 0
    btfsc STATUS, 2
    bsf PORTA, 5	    ;Hacer titilar led verde
    btfsc STATUS, 2
    bcf PORTA, 5
    movlw 4
    subwf Tiempo2M1, 0
    btfsc STATUS, 2
    bsf PORTA, 5	    ;Hacer titilar led verde
    btfsc STATUS, 2
    bcf PORTA, 5
    movlw 3		    ;Si el tiempo en Tiempo2M1 es 3, entonces:
    subwf Tiempo2M1, 0
    btfsc STATUS, 2
    bsf PORTA, 4	    ;Encender led amarilla
    movlw 0		    ;Si el tiempo en Tiempo2M1 es 0, entonces:
    subwf Tiempo2M1, 0
    btfsc STATUS, 2
    bcf PORTA, 4	    ;Apagar led amarilla
    btfsc STATUS, 2
    call TopeS		    ;Llamar subrutina para regresar al tiempo inicial
    
    ;SEMAFORO 3
    movlw 10		    ;Si el tiempo en Tiempo3M1 es 10, entonces:
    subwf Tiempo3M1, 0
    btfsc STATUS, 2
    bsf PORTB, 0	    ;Encender led verde
    btfsc STATUS, 2
    bcf PORTA, 6	    ;Apagar led roja
    movlw 6		    ;Si el tiempo en Tiempo3M1 es 6, entonces:
    subwf Tiempo3M1, 0
    btfsc STATUS, 2
    bsf PORTB, 0	    ;Hacer titilar led verde
    btfsc STATUS, 2
    bcf PORTB, 0
    movlw 5
    subwf Tiempo3M1, 0
    btfsc STATUS, 2
    bsf PORTB, 0	    ;Hacer titilar led verde
    btfsc STATUS, 2
    bcf PORTB, 0
    movlw 4
    subwf Tiempo3M1, 0
    btfsc STATUS, 2
    bsf PORTB, 0	    ;Hacer titilar led verde
    btfsc STATUS, 2
    bcf PORTB, 0
    movlw 3		    ;Si el tiempo en Tiempo3M1 es 3, entonces:
    subwf Tiempo3M1, 0
    btfsc STATUS, 2
    bsf PORTA, 7	    ;Endender led amarilla
    movlw 0		    ;Si el tiempo en Tiempo3M1 es 0, entonces:
    subwf Tiempo3M1, 0
    btfsc STATUS, 2
    bcf PORTA, 7	    ;Apagar led amarilla
    btfsc STATUS, 2
    call TopeS		    ;Llamar subrutina para regresar al tiempo inicial
    return
    
    TopeS:
    movlw 0		    ;Si el tiempo en Tiempo1M1 es 0, entonces:
    subwf Tiempo1M1, 0
    btfsc STATUS, 2
    movlw 30		    ;Asignar tiempo de espera a la vía 1
    btfsc STATUS, 2
    movwf Tiempo1M1
    btfsc STATUS, 2
    bsf PORTA, 0	    ;Encender led roja
    movlw 0		    ;Si el tiempo en Tiempo2M1 es 0, entonces:
    subwf Tiempo2M1, 0
    btfsc STATUS, 2
    movlw 30		    ;Asignar tiempo de espera a la vía 2
    btfsc STATUS, 2
    movwf Tiempo2M1
    btfsc STATUS, 2
    bsf PORTA, 3	    ;Encender led roja
    movlw 0		    ;Si el tiempo en Tiempo3M1 es 0, entonces:
    subwf Tiempo3M1, 0
    btfsc STATUS, 2
    movlw 30		    ;Asignar tiempo de espera a la vía 3
    btfsc STATUS, 2
    movwf Tiempo3M1
    btfsc STATUS, 2
    bsf PORTA, 6	    ;Encender led roja
    call Division	    ;Llamar subrutina para convertir a decimal
    return

    Division:
    clrf Decenas	;Limpiamos los registros a utilizar 
    clrf Unidades
    clrf Resta
    movf Tiempo1M1, 0    ;Trasladamos valor en IncrementoT1 a resta 
    movwf Resta
    movlw 10		;Mover valor 10 a W
    subwf Resta, f	;Restamos W y Resta, lo guardamos en el registro
    btfsc STATUS, 0	;Si la bandera no se levanto, no saltar
    incf Decenas	;Incrementar decenas
    btfsc STATUS, 0	;Si la bandera no se levanto, no saltar
    goto $-5		;Repetir hasta que ya no hayan decenas
    movlw 10		;Evitar que haya un overlap (00h - FFh)
    addwf Resta	
    movf Resta, 0	;Trasladar valor restante a unidades
    movwf Unidades
    
    clrf Decenas+1	;Limpiamos los registros a utilizar 
    clrf Unidades+1
    clrf Resta
    movf Tiempo2M1, 0    ;Trasladamos valor en IncrementoT1 a resta 
    movwf Resta
    movlw 10		;Mover valor 10 a W
    subwf Resta, f	;Restamos W y Resta, lo guardamos en el registro
    btfsc STATUS, 0	;Si la bandera no se levanto, no saltar
    incf Decenas+1	;Incrementar decenas
    btfsc STATUS, 0	;Si la bandera no se levanto, no saltar
    goto $-5		;Repetir hasta que ya no hayan decenas
    movlw 10		;Evitar que haya un overlap (00h - FFh)
    addwf Resta	
    movf Resta, 0	;Trasladar valor restante a unidades
    movwf Unidades+1

    clrf Decenas+2	;Limpiamos los registros a utilizar 
    clrf Unidades+2
    clrf Resta
    movf Tiempo3M1, 0    ;Trasladamos valor en IncrementoT1 a resta 
    movwf Resta
    movlw 10		;Mover valor 10 a W
    subwf Resta, f	;Restamos W y Resta, lo guardamos en el registro
    btfsc STATUS, 0	;Si la bandera no se levanto, no saltar
    incf Decenas+2	;Incrementar decenas
    btfsc STATUS, 0	;Si la bandera no se levanto, no saltar
    goto $-5		;Repetir hasta que ya no hayan decenas
    movlw 10		;Evitar que haya un overlap (00h - FFh)
    addwf Resta	
    movf Resta, 0	;Trasladar valor restante a unidades
    movwf Unidades+2
    
    clrf Decenas+3
    clrf Unidades+3
    clrf Resta
    movwf Tiempo1M2, 0
    movwf Resta
    movlw 10
    subwf Resta, f
    btfsc STATUS, 0
    incf Decenas+3
    btfsc STATUS, 0
    goto $-5
    movlw 10
    addwf Resta
    movf Resta, 0
    movwf Unidades+3
    return
    
    Toggle:
    bcf PORTC, 0		;Se limpian los pines que tienen transistores
    bcf PORTC, 1
    bcf PORTC, 2
    bcf PORTC, 3
    bcf PORTC, 4
    bcf PORTB, 7
    btfsc Multiplexado, 1	;Si x bit de multiplexado es 1, entonces ir al semaforo indicado
    goto Semaforo2
    btfsc Multiplexado, 3
    goto Semaforo3
    btfsc Multiplexado, 5
    goto Configuracion_de_TiempoM2
    
    Semaforo1:
    btfsc Multiplexado, 0	;Revisar bit 0 de multiplexado para elegir el display
    goto D3
    
	D4: 
	bsf Multiplexado, 0	;Poner en 1 el bit 0 para que se diriga al otro display
	movf Unidades, 0	;Elegir el valor que se mostrará en el display
	call Convertidor	;Traducirlo
	movwf PORTD		;Enviarlo al display
	bsf PORTC, 0		;Encender el transistor del display y apagar el otro
	bcf PORTB, 7
	return
	
	D3: 
	bsf Multiplexado, 1	;Poner el 1 el bit 1 para que se diriga a otro semaforo
	bcf Multiplexado, 0	;Poner en 0 el bit 0 para que se diriga a otro display
	movf Decenas, 0		;Elegir el valor que se mostrará en el display
	call Convertidor	;Traducirlo
	movwf PORTD		;Enviarlo al display
	bsf PORTB, 7		;Encender transistor del display y apagar el otro
	bcf PORTC, 0
	return
    
    Semaforo2:
    btfsc Multiplexado, 2	;Revisar bit 2 de multiplexado para elegir el display
    goto D5
    
	D6:
	bsf Multiplexado, 2	;Poner en 1 el bit 2 para que se dirija al otro display
	movf Unidades+1, 0	;Elegir el valor que se mostrará en el display
	call Convertidor	;Traducirlo
	movwf PORTD		;Enviarlo al display
	bsf PORTC, 2		;Encender el transistor del display y apagar el otro
	bcf PORTC, 1
	return
	
	D5: 
	bsf Multiplexado, 3	;Poner en 1 el bit 3 para que se dirija a otro semaforo
	bcf Multiplexado, 2	;Poner en 0 los bits de semaforo 2 para que se diriga a otro semaforo
	bcf Multiplexado, 1
	movf Decenas+1, 0	;Elegir el valor que se mostrará en el display
	call Convertidor	;Traducirlo
	movwf PORTD		;Enviarlo al display
	bsf PORTC, 1		;Encender el transistor del display y apagar el otro
	bcf PORTC, 2
	return

    Semaforo3:
    btfsc Multiplexado, 4	;Revisar bit 4 de multiplexado para elegir el display
    goto D7
    
	D8:
	bsf Multiplexado, 4	;Poner en 1 el bit 4 para que se dirija a otro display
	movf Unidades+2, 0	;Elegir el valor que se mostrará en el display
	call Convertidor	;Traducirlo
	movwf PORTD		;Enviarlo al display
	bsf PORTC, 4		;Encender el transistor del display y apagar el otro
	bcf PORTC, 3
	return
	
	D7:
	bcf Multiplexado, 4	;Poner en 0 bits de semaforo 2 y 3 para que se dirija al 1
	bcf Multiplexado, 3
	bcf Multiplexado, 1
	movf Decenas+2, 0	;Elegir el valor que se mostrará en el display
	call Convertidor	;Traducirlo
	movwf PORTD		;Enviarlo al display
	bsf PORTC, 3		;Encender el transistor del display y apagar el otro
	bcf PORTC, 4
	return

    Configuracion_de_TiempoM2:
    btfsc Multiplexado, 4
    goto D1
    
    D2:
    bsf Multiplexado, 4
    movwf Unidades+3, 0
    call Convertidor
    movwf PORTD
    bsf PORTC, 6
    bcf PORTC, 5
    return
    
    D1:
    bcf Multiplexado, 1
    bcf Multiplexado, 3
    bcf Multiplexado, 4
    bcf Multiplexado, 5
    movf Decenas+3, 0
    call Convertidor
    movwf PORTD
    bcf PORTC, 6
    bsf PORTC, 5
    return

	END