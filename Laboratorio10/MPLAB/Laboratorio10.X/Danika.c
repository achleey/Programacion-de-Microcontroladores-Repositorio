/*
 * File:   ASCII.c
 * Author: Danika
 *
 * Created on 4 de mayo de 2021, 05:24 PM
 */
//**************************
/*Uso de potenciometros, leds y displays
 *Se usa leds y dsiplay 7 para medir el valor de 2 potenciometros con ADC
 */
//**************************

#pragma config  FOSC    = INTRC_NOCLKOUT
#pragma config  WDTE    = OFF
#pragma config  PWRTE   = OFF
#pragma config  MCLRE   = OFF
#pragma config  CP      = OFF
#pragma config  CPD     = OFF
#pragma config  BOREN   = OFF
#pragma config  IESO    = OFF
#pragma config  FCMEN   = OFF
#pragma config  LVP     = OFF

#pragma config  BOR4V   = BOR40V
#pragma config  WRT     = OFF

#include <xc.h>
#include <stdint.h>

#define _XTAL_FREQ  1000000

void setup(void);

const char d    = 'H';

void __interrupt() isr (void){
    if(PIR1bits.RCIF){
        PORTD   = RCREG;
    }
}

void main(void) {
    setup();
    
    while(1){
        __delay_ms(500);
        
        if(PIR1bits.TXIF){
            
            TXREG   = d;
        }
    }
}

void setup (void){
    
    ANSEL   = 0x00;
    ANSELH  = 0x00;
    
    TRISC   = 0x00;
    TRISA   = 0x00;
    TRISD   = 0x00;
    
    PORTA   = 0;
    PORTC   = 0;
    PORTD   = 0;
    
    //oscilador a 1M Hz
    OSCCONbits.IRCF2 =1;    
    OSCCONbits.IRCF1 =0;
    OSCCONbits.IRCF0 =0;
    OSCCONbits.SCS   =1;
    
    //configuracion TX y RX
    TXSTAbits.SYNC  = 0;
    BAUDCTLbits.BRG16 = 1;      //16 bit - asincronico
    TXSTAbits.BRGH  = 1;
    
    SPBRG   = 25;
    SPBRGH  = 0;
    
    RCSTAbits.SPEN  = 1;
    RCSTAbits.RX9   = 0;
    RCSTAbits.CREN  = 1;
    
    TXSTAbits.TXEN  = 1;
    
    //configuracion interrupciones
    PIR1bits.RCIF   = 0;
    PIE1bits.RCIE   = 1;
    INTCONbits.PEIE = 1;
    INTCONbits.GIE  = 1;
}
