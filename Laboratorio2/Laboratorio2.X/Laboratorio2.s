; Archivo: main.S
; Dispositivo: PIC16F887
; Autor: Ashley Morales
; Compilador: pic-as (v2.30), MPLABX V5.45
;
; Programa: Sumador de 4 bits
; Hardware: Push en puerto A, B y C, LEDS en puertos A, B, C y D, Oscilador en Puerto A
;
; Creado: 9 feb, 2021
; Última modiciación: 12 feb, 2021
    
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

;VECTOR RESET 
    PSECT resVect, class=CODE, abs, delta=2
    ORG 00h	    ;Position for the reset
    resetVec: 
    PAGESEL main
    goto main
    
;MICROCONTROLLER
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
bcf TRISA, 0	;Pin RA0 configured as output
bcf TRISA, 1	;Pin RA1 configured as output
bcf TRISA, 2	;Pin RA2 configured as output
bcf TRISA, 3	;Pin RA3 configured as output
bsf TRISA, 4	;Pin RA4 configured as input
bsf TRISA, 5	;Pin RA5 configured as input
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
banksel PORTB
clrf PORTB	;Initializing PORTB
banksel ANSELH
clrf ANSELH	;Initializing ANSELH, digital input
banksel TRISB
bsf TRISB, 0	;Pin RB0 configured as input
banksel PORTD
clrf PORTD	;Initializing PORTD
banksel TRISD
bcf TRISD, 0	;Pin RD0 configured as output
bcf TRISD, 1	;Pin RD1 configured as output
bcf TRISD, 2	;Pin RD2 configured as output
bcf TRISD, 3	;Pin RD3 configured as output

;CARRY/OVERFLOW	 
bcf TRISD, 4	;Pin RB1 configured as output

;MAIN LOOP 
loop: 
    
;INCREMENT COUNTER 1
banksel PORTA	    ;Make sure we select the bank where the register is located
btfss  PORTA, 4	    ;If the pushbutton is not pressed, the following instruction is not executed.
call subroutine1    ;Call the Subroutine 1
    
;DECREMENT COUNTER 1    
banksel PORTA
btfss PORTA, 5	    ;If the pushbutton is not pressed, the following instruction is not executed	    
call subroutine2    ;Call the Subroutine 2
    
;INCREMENT COUNTER 2
banksel PORTC
btfss PORTC, 4	    ;If the pushbutton is not pressed, the following instruction is not executed	    
call subroutine3    ;Call the Subroutine 3
	   
;DECREMENT COUNTER 2
banksel PORTC
btfss PORTC, 5	    ;If the pushbutton is not pressed, the following instruction is not executed
call subroutine4    ;Call the Subroutine 4
    
;ADDITION
banksel PORTB
btfss PORTB, 0	    ;If the pushbutton is not pressed, the following instruction is not executed
call addition	    ;Call addition subroutine	
btfss PORTB, 0	    ;If a carry didn't ocurre, then skip the next instruction 
call carry	    ;Call the carry subroutine
    
goto loop
    
;SUBRUTINES
subroutine1: 
    banksel PORTA	
    btfss PORTA, 4	;If the pushbutton is not pressed, the following instruction is not executed
    goto $-1		;Debounce
    incf PORTA, 1	;Proceed to increment port and show it through the LED's
    return		;return to mainloop
    
subroutine2:
    banksel PORTA	
    btfss PORTA, 5	;If the pushbutton is not pressed, the following instruction is not executed
    goto $-1		;Debounce
    decf PORTA, 1	;Proceed to decrement port and show it through the LED's
    return		;return to mainloop
 
subroutine3:
    banksel PORTC	
    btfss PORTC, 4	;If the pushbutton is not pressed, the following instruction is not executed
    goto $-1		;Go back to decfsz until its value is cero
    incf PORTC		;Proceed to increment the ports and show it through the LED's
    return		;return to mainloop

subroutine4:
    banksel PORTC	
    btfss PORTC, 5	;If the pushbutton is not pressed, the following instruction is not executed
    goto $-1		;Go back to decfsz until its value is cero
    decf PORTC		;Proceed to decrement the ports and show it through the LED's
    return		;return to mainloop
    
addition: 
    banksel PORTB	
    btfss PORTB, 0	;If the pushbutton is not pressed, the following instruction is not executed
    goto $-1
    movf PORTC, 0	;Move data stored in PORTC to W
    banksel PORTD	
    addwf PORTA, 0	;Add data stored in w to f (PORTA), then save in W
    movwf PORTD, 1	;Move data stored in w to f (PORTD)
    return		;return to mainloop 

carry: 
    banksel PORTD	
    btfss STATUS, 0	;Test if bit 0 in STATUS REG = 1. If yes, then a carry-out from the MSB occurred 
    goto $-1		;Debounce
    movf PORTD, 1	;Move data stored in STATUS to PORTD
    return		;return to mainloop
    
END
    
