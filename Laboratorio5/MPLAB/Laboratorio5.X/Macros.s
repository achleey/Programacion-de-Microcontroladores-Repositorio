;PSECT udata_shr ;common memory
;  W_T:       DS 1 ; variable que de interrupcio para w
;  STATUS_T:  DS 1 ; variable que de interrupcio que guarda STATUS
;  SENAL:     DS 1
;  NIBBLE:    DS 2
;  DIS:    DS 2 
;  
;;Instrucciones de reset
;PSECT resVect, class=code, abs, delta=2
;;--------------vector reset----------------
;ORG 00h        ;posicion 0000h para el reset
;resetVec:
;    PAGESEL main
;    GOTO main
;   
;    
;PSECT intVect, class=CODE, ABS, DELTA=2
;;------------------------VECTOR DE INTERRUPCION---------------------------------
;ORG 04h
;    PUSH:
;       MOVWF W_T
;       SWAPF STATUS, W
;       MOVWF STATUS_T
;       
;    ISR:
;      BTFSC RBIF ; confirma si hubo una interrucion en el puerto B
;      CALL INC_DEC ; llama a la subrrutina de la interrupcion del contador binario
;      BTFSC T0IF; verifica si se desbordo el timer0
;      CALL INT_T0; llama a la subrrutina de interrupcion del tiemer 0
;      
;    POP: 
;      SWAPF STATUS_T, W
;      MOVWF STATUS
;      SWAPF W_T, F
;      SWAPF W_T, W
;      RETFIE
;    
;
;PSECT code, delta=2, abs
;ORG 100h    ; Posicion para el codigo
;; se establece la tabla para traducir los numeros y que el numero correspondiente
;; se marque en el display
;TABLA:
;    CLRF    PCLATH
;    BSF     PCLATH, 0 
;    ANDLW   0x0f
;    ADDWF   PCL
;    retlw   00111111B	; 0
;    retlw   00000110B	; 1
;    retlw   01011011B	; 2
;    retlw   01001111B	; 3
;    retlw   01100110B	; 4
;    retlw   01101101B	; 5
;    retlw   01111101B	; 6
;    retlw   00000111B	; 7
;    retlw   01111111B	; 8
;    retlw   01101111B	; 9
;    retlw   01110111B	; A
;    retlw   01111100B	; b
;    retlw   00111001B	; C
;    retlw   01011110B	; d
;    retlw   01111001B	; E
;    retlw   01110001B	; F
;main:
;    BANKSEL ANSEL ; Entramos al banco donde esta el registro ANSEL
;    CLRF ANSEL
;    CLRF ANSELH  ; se establecen los pines como entras y salidas digitales
;    
;   
;    BANKSEL TRISA ; Entramos al banco donde esta el TRISA
;    BCF TRISA, 0 
;    BCF TRISA, 1 
;    BCF TRISA, 2
;    BCF TRISA, 3
;    BCF TRISA, 4
;    BCF TRISA, 5
;    BCF TRISA, 6
;    BCF TRISA, 7  ; Se ponen los pines del puerto A como entradas
;    
;    BCF TRISC, 0  ; 
;    BCF TRISC, 1
;    BCF TRISC, 2
;    BCF TRISC, 3
;    BCF TRISC, 4
;    BCF TRISC, 5
;    BCF TRISC, 6
;    BCF TRISC, 7  ; Se ponen los pines del puerto C como salida
;        
;    BCF TRISD, 0
;    BCF TRISD, 1
;    BCF TRISD, 2
;    BCF TRISD, 3
;    BCF TRISD, 4
;    BCF TRISD, 5
;    BCF TRISD, 6
;    BCF TRISD, 7 ; Se ponen todos pines del puerto D como salida
;    
;    BSF TRISB,0
;    BSF TRISB,1 ; Se ponen los dos primeros pines como salida
;    BCF TRISB,4
;    BCF TRISB,5 ; Se ponen dos pines como salida (TRANSISTORES)
;    
;; subrutinas de cofiguracion
;    CALL PULL_UP
;    CALL OSCILLATOR
;    CALL CONF_IOC
;    CALL CONF_INTCON ; Se llama a las diferentes subrrutinas de configuracion
;
;    
;    BANKSEL PORTA
;    CLRF PORTA
;    CLRF PORTB
;    CLRF PORTC
;    CLRF PORTD ; Se limpian todos los puertos del pic
;    BANKSEL PORTA 
;
;loop:
;    CALL SEP_NIBBLE
;    CALL MOSTRAR_DIS
;    GOTO loop
;    
;PULL_UP:
;    BANKSEL OPTION_REG
;    BCF OPTION_REG, 7 ; Se abilitan los pull-up internos del puerto B
;    BCF T0CS ; Se establece que se usara oscilador interno 
;    BCF PSA  ; el prescaler se asigna al timer 0
;    BSF PS2
;    BSF PS1
;    BSF PS0  ; el prescaler es de 256   
;    CALL R_TIMER0
;    BANKSEL WPUB
;    BSF WPUB,0
;    BSF WPUB,1
;    BCF WPUB,2
;    BCF WPUB,3
;    BCF WPUB,4
;    BCF WPUB,5
;    BCF WPUB,6
;    BCF WPUB,7 ;Se estblece que pines del puerto B tendran activado el pull-up
;    RETURN 
;    
;;configuracion de oscilador interno
;OSCILLATOR:
;    BANKSEL OSCCON ; Se ingresa al banco donde esta el registro OSCCON
;    bcf	    IRCF2   
;    bsf	    IRCF1   
;    bcf	    IRCF0  ; Se configura el oscilador a una frecuencia de 250kHz 
;    bsf	    SCS	  
;    RETURN
;    
;;configuracion de pines para abilitacion de interrupt on change
;CONF_IOC:   
;    BANKSEL IOCB
;    BSF IOCB, 0
;    BSF IOCB, 1  ;Se activa el interrupt on change de los dos primeros pines del puerto B 
;    RETURN
;    
;;abilitacion de interrupciones      
;CONF_INTCON:
;    BANKSEL INTCON
;    BSF  GIE ; Se activan las interrupciones globales 
;    BCF  RBIF ; Se colaca la bandera en 0 por precaucion
;    BSF  RBIE ; Permite interrupciones en el puerto B
;    BSF  T0IE ; Permite interrupion del timer 0
;    BCF  T0IF ; limpia bandera de desbordamiento de timer 0
;    RETURN
;
;SEP_NIBBLE:
;    MOVF PORTA, W
;    ANDLW 00001111B
;    MOVWF NIBBLE
;    SWAPF PORTA, W
;    ANDLW 00001111B
;    MOVWF NIBBLE+1
;    RETURN
;    
;MOSTRAR_DIS:
;    MOVF NIBBLE, W
;    CALL TABLA 
;    MOVWF DIS
;    MOVF NIBBLE+1, W
;    CALL TABLA 
;    MOVWF DIS+1
;    RETURN
;;----------------subrutinas de interrupcion y en loop---------------------------    
;CONT_DIS:
;    MOVF    PORTA, W ; Se mueve a W lo que hay en el puerto A
;    CALL    TABLA  ; Se llama a la subrrutina TABLA
;    MOVWF   PORTC ; Se mueve al puerto C lo que hay en W
;    RETURN
;    
;INC_DEC:
;     BTFSS PORTB,0 ; verifica si el PB del primer pin del puerto b esta activado
;     INCF  PORTA ;incrementa el puerto A
;     BTFSS PORTB,1 ; verifica si el PB del segundo pin del puerto b esta activado
;     DECF  PORTA; decrementa el puerto A
;     BCF   RBIF ; Se pone en cero la bandera por cambio de estado
;     RETURN
;     
;R_TIMER0:
;    BANKSEL PORTA
;    MOVLW  254
;    MOVWF  TMR0; Se ingresa al registro TMR0 el numero desde donde empieza a contar
;    BCF  T0IF ; Se pone en 0 el bit T0IF  
;    RETURN
;    
;INT_T0:
;    CALL   R_TIMER0; llama a subrrutina para reiniciar el timer0
;    BCF  PORTB, 4
;    BCF  PORTB, 5
;    BTFSC SENAL, 0
;    GOTO  DIS1
;DIS0:
;    MOVF DIS, W
;    MOVWF PORTC
;    BSF PORTB, 4
;    GOTO NEXT_D
;DIS1:
;    MOVF DIS+1, W
;    MOVWF PORTC
;    BSF PORTB, 5
;NEXT_D:
;    MOVLW 1
;    XORWF SENAL, F
;    RETURN; vuelve al isr
;
;END


