; Archivo: main.S
; Dispositivo: PIC16F887
; Autor: Ashley Morales
; Compilador: pic-as (v2.30), MPLABX V5.45
;
; Programa: Sumador de 4 bits
;Hardware: Push en puerto A y C, LEDS en puertos A, B, C y D
;
; Creado: 9 feb, 2021
; Última modiciación: 
    
PROCESSOR 16F887
#include <xc.inc>   
    
;CONFIG1
CONFIG FOSC=XT	    ;External Oscillator
CONFIG WDTE=OFF	    ;WDT disabled
CONFIG PWRTE=ON	    ;PWRT enabled 
CONFIG MCLRE=OFF    ;PIN MCLR used as I/O
CONFIG CP=OFF	    ;No code protection
CONFIG CPD=OFF	    ;No data protection
CONFIG BOREN=OFF    ;No reset if Vdd < 4V
CONFIG IESO=OFF	    ;Reset without cahnging internal clock to external clock
CONFIG FCMEN=OFF    ;Change external clock to internal clock in case of failures
CONFIG LVP=ON	    ;Low voltage programming allowed 

;CONFIG2
CONFIG WRT=OFF	    ;Autowritting protection for program disabled
CONFIG BOR4V=BOR40V ;Reset if Vdd < 4V (BOR21v=2.1V)

;VARIABLES
    PSECT udata_shr ;Common memory
    counter1: DS 1
    counter2: DS 1
    counter3: DS 1
    counter4: DS 1

;VECTOR RESET 
    PSECT resVect, class=CODE, abs, delta=2
    ORG 00h	    ;Position for the reset
    resetVec: 
    PAGESEL main
    goto main
    
;Microcontroller
    PSECT code, delta=2, abs
 ORG 100h	    ;Position for code 
 
;SETUP
main:
;PORTA (Counter 1 and oscillator)
banksel PORTA
clrf PORTA	;Initializing PORTA
banksel ANSEL
clrf ANSEL	;Initializing ANSEL, digital Input
banksel TRISA
bsf TRISA, 0	;Pin RA0 configured as input
bsf TRISA, 1	;Pin RA1 configured as input
bcf TRISA, 2	;Pin RA2 configured as output
bcf TRISA, 3	;Pin RA3 configured as output
bcf TRISA, 4	;Pin RA4 configured as output
bcf TRISA, 5	;Pin RA5 configured as output
bsf TRISA, 6	;Pin RA6 configured as input (Osicllator)
bsf TRISA, 7	;Pin RA7 configured as input
    
;PORTC (Counter 2)
banksel PORTC
clrf PORTC	;Initializing PORTC
banksel TRISC
bcf TRISC, 0	;Pin RC0 configured as output
bcf TRISC, 1	;Pin RC1 configured as output
bcf TRISC, 2	;Pin RC2 configured as output
bcf TRISC, 3	;Pin RC3 configured as output
bsf TRISC, 4	;Pin RC4 configured as input
bsf TRISC, 5	;Pin RC5 configured as input
    
;RESULTS
;banksel PORTB
banksel PORTB
clrf PORTB	;Initializing PORTB
banksel ANSELH
clrf ANSELH	;Initializing ANSELH, digital input
banksel TRISB
bsf TRISB, 0	;Pin RB0 configured as input
bcf TRISC, 6	;Pin RC6 configured as output
bcf TRISC, 7	;Pin RC7 configured as output
banksel PORTD
clrf PORTD	;Initializing PORTD
banksel TRISD
bcf TRISD, 0	;Pin RD0 configured as output
bcf TRISD, 1	;Pin RD1 configured as output

;CARRY/OVERFLOW	  
bcf TRISB, 1	;Pin RB1 configured as output

;MAIN LOOP 
loop: 
    
;INCREMENT COUNTER 1
banksel PORTA	    ;Make sure we select the bank where the register is located
btfss  PORTA, 0	    ;If the pushbutton is not pressed, the following instruction is not executed.
call subrutine1	    ;Call the debounce 1 which also works as the counter
    
;DECREMENT COUNTER 1    
banksel PORTA
btfss PORTA, 1	    ;If the pushbutton is not pressed, the following instruction is not executed	    
call subrutine2	    ;Call the debounce 2 which also contains the counter
    
;INCREMENT COUNTER 2
banksel PORTC
btfss PORTC, 4
call subrutine3
	   
;DECREMENT COUNTER 2
banksel PORTC
btfss PORTC, 5
call subrutine4
goto loop
    
;SUBRUTINES
subrutine1: 
    banksel PORTA	;Make sure we select the bank where the register is located
    btfss PORTA, 0	;Check if the pushbutton is pressed
    goto $-1		;Go back to decfsz until its value is cero
    incf PORTA		;Proceed to increment the ports and show it through the LED's
    return		;return to mainloop
    
subrutine2:
    banksel PORTA
    btfss PORTA, 1
    goto $-1
    decf PORTA
    return
 
subrutine3:
    banksel PORTC	;Make sure we select the bank where the register is located
    btfss PORTC, 4	;Check if the pushbutton is pressed
    goto $-1		;Go back to decfsz until its value is cero
    incf PORTC		;Proceed to increment the ports and show it through the LED's
    return		;return to mainloop

subrutine4:
    banksel PORTC
    btfss PORTC, 5
    goto $-1
    decf PORTC
    return
    
;delay:
    ;movlw 100
    ;movwf counter1
    ;decfsz counter1
    ;goto $-1
    ;return

END
    
