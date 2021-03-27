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
    GLOBAL Unidades, Decenas, Tiempo1M1, Tiempo2M1, Tiempo3M1
    PSECT udata_shr	;Memoria común
    W_TEMP: DS 1	;Registro temporal para W
    STATUS_TEMP: DS 1	;Registro temporal para STATUS 
    Unidades: DS 3	;Variable para almacenar las unidades de los tiempos  
    Decenas: DS 3	;Variable para almacenar las decenas de los tiempos
    Multiplexado: DS 1	;Variable para controlar el multiplexado
    Tiempo1M1: DS 1	;Variable para controlar el tiempo de semaforos en modo 1
    Tiempo2M1: DS 1
    Tiempo3M1: DS 1
    ;Tiempo: DS 3
    
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
    btfsc INTCON, 2	   ;Revisar si la bandera de Overflow para Timer0 se levanto
    call reinicio_timer0   ;Llamar subrutina para incrementar los contadores para modo1
    
    pop:
    swapf STATUS_TEMP, W    ;Mover datos en STATUS_TEMP a W
    movwf STATUS	    ;Mover datos en W a STATUS
    swapf W_TEMP, F	    ;Mover W_TEMP al registro
    swapf W_TEMP, W	    ;Mover W_TEMP a W
    retfie    

;SUBRUTINAS DE INTERRUPCION
    reinicio_timer0:
    banksel PORTA
    incf Tiempo1M1	    ;Variable que controla el tiempo en el semaforo 1
    incf Tiempo2M1	    ;Variable que controla el tiempo en el semaforo 2
    incf Tiempo3M1	    ;Variable que controla el tiempo en el semaforo 3
    movlw 12		    ;Valor de temporizador para interrupción cada 1s
    movwf TMR0		    ;Cargando valor a Timer0
    bcf INTCON, 2	    ;Bajar la bandera de Overflow Interrupt para Timer0
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
    Botones			    ;Llamando configuraciones mediante macros
    Via_en_configuracion
    Vias_y_configuracion_tiempo
    Semaforos
    Oscilador
    Interrupcion_Timer0
    
    banksel PORTA
    
;MAIN LOOP	
    loop:
    banksel PORTD
    call Modo1		;Llamar subrutina para modo 1
    call Toggle		;Llamar toggle para mostrar resultados en display
    goto loop

;SUBRUTINAS
    Modo1:
    goto TiempoS1	;Ir a subrutina para el tiempo en el semaforo 1
    goto TiempoS2	;Ir a subrutina para el tiempo en el semaforo 2
    goto TiempoS3
    
    TiempoS1:
    movlw 10		;Valor necesario para que se llegue a 10s
    subwf Tiempo1M1	;Restar valor de TiempoM1 con W para saber si ya se incremento 10 veces
    btfss STATUS, 2	;Revisar si la bandera Z se levanto, si es asi, saltar
    return
    bsf PORTA, 0		;Incrementar PORTA para ver si funciona
    clrf Tiempo1M1	;Limpiar contenido en TiempoM1 para que pueda volver a funcionar
    return
    
    TiempoS2: 
    movlw 20		;Valor necesario para que se llegue a 20s
    subwf Tiempo2M1	;Restar valor de TiempoM1+1 con W para saber si ya se incremento 20 veces
    btfss STATUS, 2	;Revisar si la bandera Z se levanto, si es asi, saltar
    return
    bsf PORTA, 1	;Incrementar PORTB para ver si funciona
    btfsc STATUS, 2
    clrf Tiempo2M1	;Limpiar contenido en TiempoM1+1 para que pueda volver a funcionar
    return

    TiempoS3: 
    movlw 30		;Valor necesario para que se llegue a 30s
    subwf Tiempo3M1	;Restar valor de TiempoM1+2 con W para saber si ya se incremento 30 veces
    btfss STATUS, 2	;Revisar si la bandera Z se levanto, si es asi, saltar
    return
    bsf PORTA, 2
;    movlw 0
;    movwf Unidades
;    movlw 1
;    movwf Decenas
;    movlw 0
;    movwf Unidades+1 ;Via 2
;    movlw 0
;    movwf Unidades+2 ;Via 3
;    movlw 2
;    movwf Decenas+1 ;Via 2
;    movlw 3
;    movwf Decenas+2 ;Via 3
    btfsc STATUS, 2
    clrf Tiempo3M1	;Limpiar contenido en TiempoM1+2 para que pueda volver a funcionar
    return
    
    Toggle:
    bcf PORTC, 0
    bcf PORTC, 1
    bcf PORTC, 2
    bcf PORTC, 3
    bcf PORTC, 4
    bcf PORTB, 7
    btfsc Multiplexado, 1
    goto Semaforo2
    btfsc Multiplexado, 3
    goto Semaforo3
    
    Semaforo1:
    btfsc Multiplexado, 0
    goto D3
    
	D4: 
	bsf Multiplexado, 0
	movf Unidades, 0
	call Convertidor
	movwf PORTD
	bsf PORTC, 0
	bcf PORTB, 7
	return
	
	D3: 
	bsf Multiplexado, 1
	bcf Multiplexado, 0
	movf Decenas, 0
	call Convertidor
	movwf PORTD
	bsf PORTB, 7
	bcf PORTC, 0
	return
    
    Semaforo2:
    btfsc Multiplexado, 2
    goto D5
    
	D6:
	bsf Multiplexado, 2
	movf Unidades+1, 0
	call Convertidor
	movwf PORTD
	bsf PORTC, 2
	bcf PORTC, 1
	return
	
	D5: 
	bsf Multiplexado, 3
	bcf Multiplexado, 2
	bcf Multiplexado, 1
	movf Decenas+1, 0
	call Convertidor
	movwf PORTD
	bsf PORTC, 1
	bcf PORTC, 2
	return

    Semaforo3:
    btfsc Multiplexado, 4
    goto D7
    
	D8:
	bsf Multiplexado, 4
	movf Unidades+2, 0
	call Convertidor
	movwf PORTD
	bsf PORTC, 4
	bcf PORTC, 3
	return
	
	D7:
	bsf Multiplexado, 5
	bcf Multiplexado, 4
	bcf Multiplexado, 3
	bcf Multiplexado, 1
	movf Decenas+2, 0
	call Convertidor
	movwf PORTD
	bsf PORTC, 3
	bcf PORTC, 4
	return

	    ;DECENAS
	;VÍA 1
;	clrf Decenas		;DECENAS = 0
;	movlw 10		;W = 10
;	movwf Tiempo		;TIEMPO = 10
;	
;	movlw 10		;W = 10
;	subwf Tiempo, 0		;W - TIEMPO = 10 - 10 = 0
;	btfss STATUS, 0		;STATUS, 0 = 1
;	incf Decenas		;Decenas = 1
;	btfss STATUS, 0		;STATUS, 0 = 1
;	movwf Unidades		;Unidades = 0
;	btfsc STATUS, 0		;STATUS, 0 = 1
;	goto $-7		;No lo hace
	
	;VÍA 2
	;clrf Decenas+1
	;movlw 20
	;movwf Tiempo+1
	;movlw 20
	;subwf Tiempo+1, 0
	;btfsc STATUS, 0
	;incf Decenas+1
	;btfsc 
	
	END