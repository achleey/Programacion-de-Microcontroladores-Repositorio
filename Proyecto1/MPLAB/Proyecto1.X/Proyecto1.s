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
    PSECT udata_shr	;Memoria común
    W_TEMP: DS 1	;Registro temporal para W
    STATUS_TEMP: DS 1	;Registro temporal para STATUS 
    Unidades: DS 3	;Variable para almacenar las unidades de los tiempos  
    Decenas: DS 3	;Variable para almacenar las decenas de los tiempos
    Tiempo: DS 3
    Multiplexado: DS 1	;Variable para controlar el multiplexado
	
;VECTOR RESET 
    PSECT resVect, class=code, abs, delta=2
    ORG 00h		;Posición para reset
    resetVec: 
    PAGESEL main
    goto main

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
    call Toggle
    goto loop

;SUBRUTINAS
    Modo1:
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
	
	
    movlw 0
    movwf Unidades
    movlw 1
    movwf Decenas
    movlw 0
    movwf Unidades+1 ;Via 2
    movlw 0
    movwf Unidades+2 ;Via 3
    movlw 2
    movwf Decenas+1 ;Via 2
    movlw 3
    movwf Decenas+2 ;Via 3
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
	
END
