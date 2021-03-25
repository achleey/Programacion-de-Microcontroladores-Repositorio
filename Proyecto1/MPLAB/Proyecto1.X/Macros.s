Botones macro
 
 ;BOTON INCREMENTO, BOTON DECREMENTO Y BOTON MODO (USANDO PORTB PULL UPS)
    banksel PORTB
    clrf PORTB
    banksel ANSELH 
    clrf ANSELH 

	banksel TRISB
	bcf OPTION_REG, 7	;Activando los pull up individuales para el PORTB (RBPU)
	
	;BOTON MODO
	bsf TRISB, 4		;Pin RB4 como input
	bsf WPUB, 4		;Pin RB4 configurado como input usando pull up interno 
	
	;BOTON INCREMENTO
	bsf TRISB, 5		;Pin RB5 como input
	bsf WPUB, 5		;Pin RB5 configurado como input usando pull up interno
	
	;BOTON DECREMENTO
	bsf TRISB, 6		;Pin RB6 como input
	bsf WPUB, 6		;Pin RB6 configurado como input usando pull up interno 
endm
	
Via_en_configuracion macro
 
 ;VÍA EN CONFIGURACIÓN
    banksel PORTB
    clrf PORTB
    banksel ANSELH 
    clrf ANSELH
	
	banksel TRISB
	;LEDS
	bcf TRISB, 1		;Pin RB1 como output
	bcf TRISB, 2		;Pin RB2 como output
	bcf TRISB, 3		;Pin RB3 como output
endm 

Vias_y_configuracion_tiempo macro
	
;DISPLAY DE VÍAS Y CONFIGURACIÓN DE TIEMPO
    banksel PORTD
    clrf PORTD
    banksel PORTB
    clrf PORTB
    banksel PORTC
    clrf PORTC
    
	banksel TRISD
	movlw 00000000B		;PORTD configurado como output
	movwf TRISD
	
	;VÍA 1
	bcf TRISB, 7		;Pin RB2 configurado como output
	bcf TRISC, 0		;Pin RC0 configurado como output
	
	;VÍA 2
	bcf TRISC, 1		;Pin RC1 configurado como output
	bcf TRISC, 2		;Pin RC2 configurado como output

	;VÍA 3
	bcf TRISC, 3		;Pin RC3 configurado como output
	bcf TRISC, 4		;Pin RC4 configurado como output
	
	;CONFIGURACIÓN DE TIEMPO
	bcf TRISC, 5		;Pin RC5 configurado como output
	bcf TRISC, 6		;Pin RC6 configurado como output
endm 

Semaforos macro

    banksel PORTA
    clrf PORTA
    banksel ANSEL
    clrf ANSEL
	
	banksel TRISA
	;SEMÁFOROS
	movlw 00000000B		;PORTA configurado como output
	movwf TRISA
	bcf TRISB, 0		;Completar usando RB0
 
endm
	
Oscilador macro 
 
 ;OSCILADOR
    banksel OSCCON
    bsf SCS	;Eligiendo oscilador interno
    bcf IRCF2	;Eligiendo oscilador interno de 250kHz
    bsf IRCF1	
    bcf IRCF0

endm
    
Interrupcion_Timer0 macro
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
	    
endm