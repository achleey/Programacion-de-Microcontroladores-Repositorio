;Archivo: Laboratorio4.S
;Dispositivo: PIC16F887
;Autor: Ashley Morales
;Compilador: pic-as (v2.30), MPLABX V5.45
;
;Programa: Interrup-On-Change del PORTB Overflow Interrupt del Timer0
;Hardware: Push buttons en puerto B, leds en puerto A, display en puerto C y D
;
;Creado: 23 feb, 2021
;Última modiciación: 
    
PROCESSOR 16F887
#include <xc.inc>

;CONFIG1
CONFIG FOSC=INTRC_NOCLKOUT ;Oscilador interno
CONFIG WDTE=OFF	    ;WDT desactivado
CONFIG PWRTE=ON	    ;PWRT activado
CONFIG MCLRE=OFF    ;PIN MCLR usado como I/O
CONFIG CP=OFF	    ;Protección de código desactivada
CONFIG CPD=OFF	    ;Proteción de datos desactivada
CONFIG BOREN=OFF    ;No reset si Vdd < 4V
CONFIG IESO=OFF	    ;Reset sin cambiar reloj interno a reloj externo
CONFIG FCMEN=OFF    ;Cambiar reloj externo a reloj interno en caso de fallas 
CONFIG LVP=ON	    ;LVP activado  

;CONFIG2
CONFIG WRT=OFF	    ;Protección de autoescritura para programa desactivado
CONFIG BOR4V=BOR40V ;Reset si Vdd < 4V (BOR21v=2.1V)

;VARIABLES
    PSECT udata_shr	;Memoria común
    W_TEMP: DS 1	;Registro temporal para W
    STATUS_TEMP: DS 1	;Registro temporal para STATUS
    contador20ms: DS 1	;Contador para interrupciones cada 20 ms
    contador_display:	 DS 1	;Registro para guardar incremento display 2
    
;VECTOR RESET 
    PSECT resVect, class=CODE, abs, delta=2
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
    btfsc INTCON, 0	   ;Revisar si uno de los pines cambio de estado, usando RBIF
    call inc_dec	   ;Llamar a subrutina para incrementar y decrementar
    btfsc INTCON, 2	   ;Revisar si la bandera de Overflow para Timer0 se levanto
    call contador	   ;Llamar subrutina para incrementar el registro contador20ms
    
    pop:
    swapf STATUS_TEMP, W    ;Mover datos en STATUS_TEMP a W
    movwf STATUS	    ;Mover datos en W a STATUS
    swapf W_TEMP, F	    ;Mover W_TEMP al registro
    swapf W_TEMP, W	    ;Mover W_TEMP a W
    retfie
    
;MICROCONTROLADOR
    PSECT code, delta=2, abs
    ORG 100h	    ;Posición para código

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
    retlw 01110111B	;A
    retlw 01111111B	;B
    retlw 00111001B	;C
    retlw 00111111B	;D
    retlw 01111001B	;E
    retlw 01110001B	;F

;SETUP
main:
    
    ;BOTON INCREMENTO Y BOTON DECREMENTO (USANDO PORTB PULL UPS)
    banksel PORTB
    clrf PORTB
    banksel ANSELH 
    clrf ANSELH 

	banksel TRISB
	bcf OPTION_REG, 7	;Activando los pull up individuales para el PORTB (RBPU)
	
	;BOTON INCREMENTO
	bsf TRISB, 4		;Pin RB4 como input
	bsf WPUB, 4		;Pin RB4 configurado como input usando pull up interno
	
	;BOTON DECREMENTO
	bsf TRISB, 5		;Pin RB5 como input
	bsf WPUB, 5		;Pin RB5 configurado como input usando pull up interno 

    ;CONTADOR
    banksel PORTA
    clrf PORTA
    banksel ANSEL 
    clrf ANSEL
	
	banksel TRISA
	;LEDS
	bcf TRISA, 0		;Pin RA0 como output
	bcf TRISA, 1		;Pin RA1 como output
	bcf TRISA, 2		;Pin RA2 como output
	bcf TRISA, 3		;Pin RA3 como output

    ;DISPLAY 1 Y 2
    banksel PORTC
    clrf PORTC
    clrf PORTD
    
	banksel TRISC
	;DISPLAY 1
	movlw 00000000B		;PORTC configurado como output
	movwf TRISC
	
	;DISPLAY 2
	movlw 00000000B		;PORTD configurado como output
	movwf TRISD 
	
    ;CONFIGURACIÓN DE INTERRUPCIONES
    bsf INTCON, 7		;Activando interrupciones no periféricas
    
	;INTERRUPT-ON-CHANGE
	bcf INTCON, 0		;Bandera Change Interrupt esta abajo
	bsf INTCON, 3		;Activando change interrupt en el PORTB
	bsf IOCB, 4		;Interrupt-on-change activado para RB4
	bsf IOCB, 5		;Interrupt-on-change activado para RB5
	
	;TMR0 INTERRUPT
	
	    ;PRESCALER Y TIMER MODE
	    bcf OPTION_REG, 5	;Seleccionando oscilador interno
	    bcf OPTION_REG, 3	;Haciendo que el PSA sea programable para Timer0
	    bsf OPTION_REG, 2	;Eligiendo PSA de 256
	    bsf OPTION_REG, 1
	    bsf OPTION_REG, 0
	
	    ;INTERRUPT
	    bsf INTCON, 5	;Habilitando Timer0 Overfow Interrupt
	    banksel TMR0
	    clrf TMR0		;Inicializando Timer0
	    bcf INTCON, 2	;Bajando bandera de Timer0 Overflow Interrupt 
    
    ;OSCILADOR
    banksel OSCCON
    bsf SCS	;Eligiendo oscilador interno
    bcf IRCF2	;Eligiendo oscilador interno de 500kHz
    bsf IRCF1	
    bsf IRCF0
    
    banksel PORTA
    
;MAIN LOOP	
	
    loop:
    
	;DISPLAY 1 - CONTADOR
	banksel PORTA
	movf PORTA, 0	    ;Mover datos en PORTA a W
	call Convertidor    ;Llamar subrutina para que traduzca los datos anteriores
	movwf PORTC	    ;Mover resultados a PORTC (ubicación de display)
	
	;DISPLAY 2 - TMR0
	call incremento1000ms	    ;Llamar a subrutina para incrementar cada 1000ms
	movf contador_display, 0    ;Moviendo datos en variable a W
	call Convertidor	    ;Llamando subrutina para traducir datos anteriores
	movwf PORTD		    ;Moviendo resultados a PORTD (ubicacion de display)
	
    goto loop
    
;SUBRUTINAS
    
    inc_dec:
    btfss TRISB, 4	;Revisar si el boton de incremento está presionado
    incf PORTA		;Aumentar PORTA (ubicación de contador con LED's)
    btfss TRISB, 5	;Revisar si el boton de decremento esta presionado
    decf PORTA		;Decrementar PORTA (ubicación de contador con LED's)
    bcf INTCON, 0	;Se baja bandera Change Interrupt
    return
    
    reinicio_timer0:
    banksel PORTA
    movlw 245		;Valor de temporizador para interrupción cada 20ms
    movwf TMR0		;Cargando valor a Timer0
    bcf INTCON, 2	;Bajar la bandera de Overflow Interrupt para Timer0
    return
    
    contador:
    incf contador20ms	;Hacer contador20ms+1
    call reinicio_timer0    ;Reiniciar el Timer0
    return
    
    incremento1000ms:
    movlw 50		    ;Valor necesario para incremento de 1000ms
    subwf contador20ms, 0   ;Restar valor en W con valor en contador20ms
    btfss STATUS, 2	    ;Revisar bandera Z
    return		    ;Si no es cero no incrementa variable para display 2
    incf contador_display   ;Si es cero incrementa variable para display 2
    clrf contador20ms	    ;Limpiamos contador20ms
    return  
END	
	
