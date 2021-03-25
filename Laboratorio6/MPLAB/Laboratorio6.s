;Archivo: Laboratorio6.S
;Dispositivo: PIC16F887
;Autor: Ashley Morales
;Compilador: pic-as (v2.30), MPLABX V5.45
;
;Programa: Temporizadores
;Hardware: Display en PORTC, LED en RA0 y Transistores en RE0 y RE1
;
;Creado: 23 marzo, 2021
;Última modiciación: 
   
PROCESSOR 16F887		;Incluyendo microcontrolador y librerias utiles
#include <xc.inc>    
    
;CONFIG1
CONFIG FOSC=INTRC_NOCLKOUT ;Oscilador interno
CONFIG WDTE=OFF	    ;WDT desactivado
CONFIG PWRTE=OFF	    ;PWRT activado
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
    GLOBAL IncrementoT1 
    GLOBAL Unidades
    GLOBAL Decenas
    GLOBAL Resta
    PSECT udata_shr	;Memoria común
    W_TEMP: DS 1	;Registro temporal para W
    STATUS_TEMP: DS 1	;Registro temporal para STATUS 
    IncrementoT1: DS 1	;Variable que aumenta con Timer1
    Multiplexado: DS 1	;Bandera para multiplexado
    Unidades: DS 1 
    Decenas: DS 1
    Resta: DS 1

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
    btfsc PIR1, 0	    ;Si la bandera de Timer1 no se ha levantado, saltar
    call reinicio_timer1
    btfsc PIR1, 1	    ;Si la bandera de Timer2 no se ha levantado, saltar
    call reinicio_timer2
    btfsc INTCON, 2	    ;Si la bandera de Timer0 no se ha levantado, saltar
    call reinicio_timer0
    
    pop:
    swapf STATUS_TEMP, W    ;Mover datos en STATUS_TEMP a W
    movwf STATUS	    ;Mover datos en W a STATUS
    swapf W_TEMP, F	    ;Mover W_TEMP al registro
    swapf W_TEMP, W	    ;Mover W_TEMP a W
    retfie
    
;SUBRUTINAS DE INTERRUPCIÓN
    reinicio_timer1:
    banksel PORTA
    movlw 0xE1
    movwf TMR1H
    movlw 0x7B
    movwf TMR1L
    incf IncrementoT1, 1
    bcf PIR1, 0
    return
    
    reinicio_timer2:
    banksel PORTA
    incf PORTA
    bcf PIR1, 1
    return
    
    reinicio_timer0:
    banksel PORTA
    movlw 248		;Valor de temporizador para interrupción cada 2ms
    movwf TMR0		;Cargando valor a Timer0
    bcf INTCON, 2	;Bajar la bandera de Overflow Interrupt para Timer0
    call Toggle
    return
    
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
    
;SETUP
main:
    
    ;LED INTERMITENTE
    banksel PORTA
    clrf PORTA
    banksel ANSEL
    clrf ANSEL
    banksel TRISA
    bcf TRISA, 0	    ;Pin RA0 configurado como output
    
    ;DISPLAY 1 Y 2
    banksel PORTC
    clrf PORTC
    clrf PORTE
    banksel TRISC
    movlw 00000000B		;PORTC configurado como output
    movwf TRISC
	
	;TRANSISTORES
	banksel TRISE
	bcf TRISE, 0
	bcf TRISE, 1

    ;OSCILADOR
    banksel OSCCON
    bsf SCS	;Eligiendo oscilador interno
    bcf IRCF2	;Eligiendo oscilador interno de 250kHz
    bsf IRCF1	
    bcf IRCF0	
    
    ;TIMER0
    bcf OPTION_REG, 5	;Seleccionando oscilador interno
    
	;PSA
	bcf OPTION_REG, 3	;Haciendo que el PSA sea programable para Timer0
	bsf OPTION_REG, 2	;Eligiendo PSA de 256
	bsf OPTION_REG, 1
	bsf OPTION_REG, 0
	
	    ;INTERRUPT
	    bsf INTCON, 5	;Habilitando Timer0 Overfow Interrupt
	    banksel TMR0
	    clrf TMR0		;Inicializando Timer0
	    bcf INTCON, 2	;Bajando bandera de Timer0 Overflow Interrupt 
    
    ;TIMER1
    banksel T1CON
    bcf T1CON, 1	;Eligiendo oscilador interno
    bsf T1CON, 0	;Habilitando Timer1
	
	;PSA
	bsf T1CON, 4	;Eligiendo un PSA de 1:8
	bsf T1CON, 5
	
	;TIMER1 INTERRUPT
	bcf PIR1, 0	;Bajando Timer1 Overflow IF
	clrf TMR1H	;Limpiando TMR1H
	movlw 0xE1
	movwf TMR1H
	clrf TMR1L	;Limpiando TMR1L
	movlw 0x7B
	movwf TMR1L
	bsf INTCON, 7	;Habilitando las interrupciones globales
	bsf INTCON, 6	;Habilitando interrupciones perifericas
	banksel PIE1
	bsf PIE1, 0	;Habilitando la interrupcion del Timer1

    ;TIMER2
    banksel T2CON
    bsf T2CON, 2	;Habilitando Timer2 
    
	;PSA
	bsf T2CON, 1	;Seleccionando PSA de 16
	
	;POSTCALER
	bsf T2CON, 3	;Seleccionando Postcaler de 16
	bsf T2CON, 4
	bsf T2CON, 5
	bsf T2CON, 6
	
	;TIMER2 INTERRUPT
	bcf PIR1, 1	;Bajando Timer2 Overflow IF
	clrf TMR2	;Limpiando TMR2
	movlw 61
	movwf PR2
	banksel PIE1
	bsf PIE1, 1	;Habilitando la interrupción del Timer2
	
banksel PORTA
	
;MAIN LOOP	
    loop:
    call Division
    goto loop

;SUBRUTINAS
    
    Division:
    clrf Decenas		    
    movf IncrementoT1, 0	    
    movwf Resta			    
    movlw 10			    
    subwf Resta, 0		    
    btfss STATUS, 0		    
    incf Decenas		    
    btfss STATUS, 0		    
    movwf Resta			    
    btfsc STATUS, 0		    
    goto $-7			    

    clrf Unidades		    
    movlw 1			     
    subwf Resta, 0
    btfss STATUS, 0
    incf Unidades
    btfsc STATUS, 0
    return
    goto $-6
    
     
    Toggle: 
    bcf PORTE, 0
    bcf PORTE, 1
    btfsc Multiplexado, 1
    goto D1
    
    D2: 
    bsf Multiplexado, 0
    movf Unidades, 0
    call Convertidor
    movwf PORTC
    bsf PORTE, 1
    bcf PORTE, 0
    return
    
    D1:
    bsf Multiplexado, 1
    bcf Multiplexado, 0
    movf Decenas, 0
    call Convertidor
    movwf PORTC
    bsf PORTE, 0
    bcf PORTE, 1
    return

END