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
    PSECT udata_bank0
    W_TEMP: DS 1	;Registro temporal para W
    STATUS_TEMP: DS 1	;Registro temporal para STATUS 
    
    PSECT udata_shr	;Memoria común
    multiplexado: DS 1	;Variable para hacer multiplexado
    separador: DS 1	;Variable para separar datos de contador
    nibble: DS 2	;Variable que almacenará los nibbles
    display: DS 5	;Variable que se usará para mostrar el valor en display
    residuo1: DS 1
    decenas: DS 1
    unidades: DS 1
    centenas: DS 1
    
;VECTOR RESET 
    PSECT resVect, class=code, abs, delta=2
    ORG 00h		;Posición para reset
    resetVec: 
    PAGESEL main
    goto main

;VECTOR DE INTERRUPCIÓN  
    PSECT intVect, class=code, abs, delta=2
    ORG 04h
   
    push: 
    movwf W_TEMP	   ;Mover datos en W a W_TEMP
    swapf STATUS, W	   ;Mover datos en STATUS a W
    movwf STATUS_TEMP	   ;Mover W a STATUS_TEMP
    
    isr: 
    btfsc INTCON, 0	   ;Revisar si uno de los pines cambio de estado, usando RBIF
    call inc_dec	   ;Llamar a subrutina para incrementar y decrementar
    btfsc INTCON, 2	   ;Revisar si la bandera de Overflow para Timer0 se levanto
    call int_timer0	   ;Llamar subrutina para de interrupción para timer0
    
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
	movlw 00000000B		;PORTA configurado como output
	movwf TRISA

    ;DISPLAY A1 Y A2
    banksel PORTC
    clrf PORTC
    clrf PORTD
    
	banksel TRISC
	;DISPLAY A1
	movlw 00000000B		;PORTC configurado como output
	movwf TRISC
	bcf TRISB, 2		;Pin RB2 configurado como output
	bcf TRISB, 3		;Pin RB3 configurado como output
	
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
    bcf IRCF2	;Eligiendo oscilador interno de 250kHz
    bsf IRCF1	
    bcf IRCF0
    
    banksel PORTA
	    
;MAIN LOOP	
    loop:
    call separacion
    call traductor 
    call division
    goto loop
    
;SUBRUTINAS
    
    inc_dec:
    btfss TRISB, 4	;Revisar si el boton de incremento está presionado
    incf PORTA		;Aumentar PORTA (ubicación de contador con LED's)
    btfss TRISB, 5	;Revisar si el boton de decremento esta presionado
    decf PORTA		;Decrementar PORTA (ubicación de contador con LED's)
    bcf INTCON, 0	;Se baja bandera Change Interrupt
    return
    
    separacion:
    movf PORTA, 0
    andlw 0x0f
    movwf nibble
    swapf PORTA, 0
    andlw 0x0f
    movwf nibble+1
    return
    
    traductor:
    movf nibble, 0
    call Convertidor
    movwf display
    movf nibble+1, 0
    call Convertidor
    movwf display+1
    movf centenas, 0
    call Convertidor
    movwf display+2
    movf decenas
    call Convertidor
    movwf display+3
    movf unidades
    call Convertidor
    movwf display+4
    return
    
    int_timer0:
    call reinicio_timer0    ;Reiniciar el Timer0
    bcf TRISB, 0
    bcf TRISB, 1
    bcf TRISB, 2
    bcf TRISB, 3
    bcf TRISB, 6
    btfsc multiplexado, 0
    goto display2A
    btfsc multiplexado, 1    
    goto display3B
    btfsc multiplexado, 2
    goto display2B
    btfsc multiplexado, 3
    goto display1B
    
    display1A: 
    movf display, 0
    movwf PORTC
    bsf PORTB, 3
    goto toggle
    
    display2A:
    movf display+1, 0		
    movwf PORTC
    bsf PORTB, 2
    
    display1B:
    movf display+2
    movwf PORTD
    bsf TRISB, 1
    goto toggle1
    
    display2B:
    movf display+3,0
    movwf PORTD
    bsf TRISB, 6
    goto toggle2
    
    display3B:
    movf display+4,0
    movwf PORTD
    bsf TRISB, 0
    goto toggle3
    
    toggle:
    movlw 1
    xorwf multiplexado, 1	

    
    toggle1:
    movlw 00000110B
    xorwf multiplexado, 1
    return
    
    toggle2:
    movlw 00001100B
    xorwf multiplexado, 1
    return
    
    toggle3:
    clrf multiplexado
    return

    reinicio_timer0:
    banksel PORTA
    movlw 254		;Valor de temporizador para interrupción cada 10ms
    movwf TMR0		;Cargando valor a Timer0
    bcf INTCON, 2	;Bajar la bandera de Overflow Interrupt para Timer0
    return

    division:
    movlw 100				    
    subwf PORTA, 0
    btfss STATUS, 0
    incf centenas,1			    	    
    btfss STATUS, 0
    goto $-5
    movwf residuo1, 1
    movlw 100
    addwf residuo1			    
   
    movlw 10				  
    subwf residuo1, 0
    btfss STATUS, 0
    incf decenas, 1			    
    btfss STATUS, 0
    goto $-5
    movwf unidades
    movlw 10
    addwf unidades
    return
    
    
    
END
