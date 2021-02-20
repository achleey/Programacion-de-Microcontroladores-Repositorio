;Archivo: Laboratorio3.S
;Dispositivo: PIC16F887
;Autor: Ashley Morales
;Compilador: pic-as (v2.30), MPLABX V5.45
;
;Programa: Botones y Timer0
;Hardware: Push buttons en puerto A, leds en puerto C y A, display en puerto B
;
;Creado: 16 feb, 2021
;Última modiciación: Viernes 18 de febrero de 2021

    
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
    PSECT udata_shr ;common memory
    contador: DS 2
    
;VECTOR RESET 
    PSECT resVect, class=CODE, abs, delta=2
    ORG 00h	    ;Posición para reset
    resetVec: 
    PAGESEL main
    goto main
    
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
    
    ;BOTON INCREMENTO Y DECREMENTO
    banksel PORTA	;Direccionando a banco correcto
    clrf PORTA		;Inicializando PORTA
    banksel ANSEL	;Direccionando a banco correcto
    clrf ANSEL		;Inicializando ANSEL para tener pines digitales
   
	banksel TRISA
	;BOTON INCREMENTO
	bsf TRISA, 4	    ;Pin RA4 configurado como input
    
	;BOTON DECREMENTO 
	bsf TRISA, 5	    ;Pin RA5 configurado como input
	
    ;TIMER0
    banksel PORTC	;Direccionando a banco correcto
    clrf PORTC		;Inicializando PORTC
    
	banksel TRISC
	;CONFIGURACIÓN DE PINES
	bcf TRISC, 0	;Pin RC0 configurado como output
	bcf TRISC, 1	;Pin RC1 configurado como output 
	bcf TRISC, 2	;Pin RC2 configurado como output
	bcf TRISC, 3	;Pin RC3 configurado como output

	;PREESCALER Y TIMER MODE
	bcf OPTION_REG, 5   ;Seleccionando timer mode
	bcf PSA		;Haciendo que PSA este en cero para asignar prescaler en Timer0
	bsf PS0		;Seleccionando PSA=256
	bsf PS1
	bsf PS2

    ;DISPLAY
    banksel PORTB	;Direccionando a banco correcto
    clrf PORTB		;Inicializando PORTB
    banksel ANSELH	;Direccionando a banco correcto
    clrf ANSELH		;Inicializando ANSELH para tener pines digitales
    
	banksel TRISB
	;CONFIGURACIÓN DE DISPLAY
	bcf TRISB, 0	;Pin RB0 configurado como output
	bcf TRISB, 1	;Pin RB1 configurado como output
	bcf TRISB, 2	;Pin RB2 configurado como output
	bcf TRISB, 3	;Pin RB3 configurado como output
	bcf TRISB, 4	;Pin RB4 configurado como output
	bcf TRISB, 5	;Pin RB5 configurado como output
	bcf TRISB, 6	;Pin RB6 configurado como output
	bcf TRISB, 7	;Pin RB7 configurado como output

	;ENTRADA DE DATOS A DISPLAY
	banksel PORTD	    ;Direccionando a banco correcto
	clrf PORTD	    ;Inicializando PORTD
	banksel TRISD	    ;Direccionando a banco correcto
	movlw 00000000B	    ;Haciendo que PORTD sea salida
	movwf TRISD	    ;Moviendo configuración de pines a PORTD
    
    ;ALARMA
    banksel TRISA	    ;Llamando a banco correcto
    bcf TRISA, 0	    ;Configurando RA0 como output
    
    ;OSCILADOR
    banksel OSCCON
    bsf SCS	;Eligiendo oscilador interno
    bcf IRCF2	;Eligiendo oscilador interno de 500kHz
    bsf IRCF1	
    bsf IRCF0

;MAIN
   
    loop:
    
    ;CONTADOR USANDO TMR0
    btfss INTCON, 2	    ;Saltar goto $-1 si la bandera esta levantada para poder bajarla usando software
    goto $-1		    ;Permanecer en el chequeo hasta que la bandera este levantada para bajarla usando software
    call reinicio_timer0    ;Llamar subrutina para reiniciar Timer0 (bajar bandera)
    incf PORTC		    ;Incrementar puerto c	
    
    ;CONTADOR HEXADECIMAL
    banksel PORTA
	
	;INCREMENTAR
	btfss  PORTA, 4	    ;Si el boton no esta presionado, saltar la instrucción siguiente
	call incremento	    ;Llamar subrutina para incrementar display
	movf PORTD, 0	    ;Mover datos en PORTD a W
	call Convertidor    ;Llamar subrutina para que traduzca los datos anteriores
	movwf PORTB	    ;Mover resultados a PORTB (ubicación de display)
  
	;DECREMENTAR
	btfss PORTA, 5	    ;Si el boton no esta presionado, saltar la instrucción siguiente
	call decremento	    ;Llamar subrutina para decrementar display
	movf PORTD, 0	    ;Mover datos en PORTD a W
	call Convertidor    ;Llamar subrutina para que traduzca los datos anteriores
	movwf PORTB	    ;Mover resultados a PORTB (ubicación de display)
	
    bcf TRISA, 0	    ;Limpiar LED antes de volver a ejecutar
    
    ;ALARMA	
    call alarma		    ;Llamar subrutina para activar LED y reiniciar contador
    ;bcf TRISA, 0	    ;Limpiar LED antes de volver a ejecutar
    goto loop		    
    
    
;SUBRUTINAS
    
reinicio_timer0:
    banksel PORTA	;Direccionando a banco correcto
    movlw 11		;Valor necesario para que el contador incremente cada 500 ms
    movwf TMR0		;Guardar valor en registro TMR0
    bcf INTCON, 2	;Bajar la bandera
    return

incremento:
    banksel PORTA	;Direccionando a banco correcto
    btfss PORTA, 4	;Si el boton no está presionado, saltar la instrucción siguiente
    goto $-1		;Anti rebote
    banksel PORTD	
    incf PORTD		;Incrementar PORTD
    return		;Regresara main loop

decremento:
    banksel PORTA
    btfss PORTA, 5	;Si el botón no está presionado, saltar la instrucción siguiente
    goto $-1		;Anti rebote
    banksel PORTD	
    decf PORTD		;Decrementar PORTD
    return		;Regresar a main loop

alarma:
    movf PORTC, 0	;Mover datos de PORTC a W
    subwf PORTD, 0	;Restar W - PORTD, guardar en W
    btfsc STATUS, 2	;Revisar si el resultado de la resta es cero, saltar instruccion siguiente si no lo es
    call subrutina	;Si es así, llamar a subrutina para encender alarma
    return

    
subrutina:
    bsf TRISA, 0	;Encender alarma (LED ubicada en TRIS)
    clrf PORTC		;Limpiar contador
    return

END
    
    