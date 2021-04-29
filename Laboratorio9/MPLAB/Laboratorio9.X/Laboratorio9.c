/*
 * File:   Laboratorio9.c
 * Author: ashley
 *
 * Created on April 25, 2021, 2:56 PM
 */

// PIC16F887 Configuration Bit Settings
// 'C' source line config statements
// CONFIG1
#pragma config FOSC = INTRC_NOCLKOUT// Oscillator Selection bits (INTOSCIO oscillator: I/O function on RA6/OSC2/CLKOUT pin, I/O function on RA7/OSC1/CLKIN)
#pragma config WDTE = OFF       // Watchdog Timer Enable bit (WDT disabled and can be enabled by SWDTEN bit of the WDTCON register)
#pragma config PWRTE = OFF      // Power-up Timer Enable bit (PWRT disabled)
#pragma config MCLRE = OFF      // RE3/MCLR pin function select bit (RE3/MCLR pin function is digital input, MCLR internally tied to VDD)
#pragma config CP = OFF         // Code Protection bit (Program memory code protection is disabled)
#pragma config CPD = OFF        // Data Code Protection bit (Data memory code protection is disabled)
#pragma config BOREN = OFF      // Brown Out Reset Selection bits (BOR disabled)
#pragma config IESO = OFF       // Internal External Switchover bit (Internal/External Switchover mode is disabled)
#pragma config FCMEN = OFF      // Fail-Safe Clock Monitor Enabled bit (Fail-Safe Clock Monitor is disabled)
#pragma config LVP = OFF        // Low Voltage Programming Enable bit (RB3 pin has digital I/O, HV on MCLR must be used for programming)

// CONFIG2
#pragma config BOR4V = BOR40V   // Brown-out Reset Selection bit (Brown-out Reset set to 4.0V)
#pragma config WRT = OFF        // Flash Program Memory Self Write Enable bits (Write protection off)

#include <xc.h>
#include <stdint.h>

//DIRECTIVAS DEL COMPILADOR
#define _XTAL_FREQ 8000000

//VARIABLES

//PROTOTIPOS DE FUNCIONES
void setup(void);               //FUNCION DE CONGIFURACION

//INTERRUPCIONES
void __interrupt() isr(void) {
   if (ADIF) {      
       if (ADCON0bits.CHS == 0){    //POTENCIOMETRO 1
       CCPR1L = (ADRESH>>1)+124;    //INDICANDO EL RANGO PARA EL SERVO MOTOR (-90 A 90 )
       }
       else if (ADCON0bits.CHS == 1){
       CCPR2L = (ADRESH>>1)+124;
       ADCON0bits.CHS = 0;
       }
       PIR1bits.ADIF = 0;    //BAJANDO BANDERA A/D INTERRUPT
    }
}

//MAIN
void main(void) {
    setup();
    while (1)
    {
        __delay_us(100);
        ADCON0bits.GO_nDONE = 1;    //COMENZAR CONVERSION
        if (ADCON0bits.CHS == 0){   //MULTIPLEXADO DE CANALES
        __delay_us(50);
       ADCON0bits.CHS = 1;    //PIN RA1 CONFIGURADO PARA ADC
        }
    }
}

//FUNCIONES
void setup(void){
    
    //POTENCIOMETROS
    ANSEL = 0b00000011;             //CONFIGURANDO ENTRADAS ANALOGICAS EN EL PUERTO A
    TRISA = 0b11111111;             
    PORTA = 0;
    ADCON0bits.CHS = 0;             //PIN RA0 CONFIGURADO PARA ADC
    
            //CONFIGURACION ADC
            ADCON0bits.ADON = 1;        //ENCENDER MODULO
            __delay_us(100);             //RECOMENDANDO DE ACUERDO AL OSCILADOR UTILIZADO
            ADCON0bits.GO_nDONE = 1;    //COMENZAR CONVERSION
    
        //VOLTAJES DE REFERENCIA 
        ADCON1bits.VCFG0 = 0;   //+
        ADCON1bits.VCFG1 = 0;   //-
        
        //FUENTE DE RELOJ
        ADCON0bits.ADCS0 = 0;   //Fosc/32, TAD = 2us.
        ADCON0bits.ADCS1 = 1;
        
        //FORMATO DE RESULTADO
        ADCON1bits.ADFM = 0;    //JUSTIFICADO A LA IZQUIERDA
    
    //CONFIGURACION DE OSCILADOR
    OSCCONbits.SCS = 1;     //ACTIVANDO OSCILADOR INTERNO
    OSCCONbits.IRCF0 = 1;   //ELIGIENDO OSCILADOR DE 8 MHz
    OSCCONbits.IRCF1 = 1;
    OSCCONbits.IRCF2 = 1;
    
        //SERVO
        PORTC = 0;              //DESACTIVANDO OUTPUT DRIVERS
        TRISC = 0b11111111;
        PR2 = 250;
        
        //PWM
        CCP1CONbits.P1M = 0b00;         //PWM OUTPUT CONFIGURATION BITS
        CCP2CONbits.DC2B0 = 0;          //MODO PWM
        CCP2CONbits.DC2B1 = 0;
        CCP2CONbits.CCP2M = 0b1111;
        CCP1CONbits.CCP1M = 0b1100;     //ECCP SELECT BITS
        
        CCPR1L = 0x0f;                  //CARGANDO VALOR DE PERIODO
        CCP1CONbits.DC1B = 0;           //BITS MENOS SIGNIFICATIVOS DEL DUTY CYCLE  
        CCPR2L = 0x0f;                 //CARGANDO VALOR DE PERIODO
        PIR1bits.TMR2IF = 0;    //BAJANDO BANDERA DE OVERFLOW
    
        //PSA
        T2CONbits.T2CKPS1 = 1;    //PSA
        T2CONbits.TMR2ON = 1;    //HABILITANDO TIMER2
            
            
    while(PIR1bits.TMR2IF == 0);    //ESPERANDO UN CICLO
    PIR1bits.TMR2IF = 0;
    TRISC = 0;
            
    //INTERRUPCIONES
    INTCONbits.GIE = 1;      //HABILITANDO INTERRUPCIONES GLOBALES Y PERIFERICAS
    INTCONbits.PEIE = 1;
    
        //A/D INTERRUPT
        PIR1bits.ADIF = 0;      //BAJANDO BANDERA DE A/D INTERRUPT
        PIE1bits.ADIE = 1;      //HABILITANDO A/D INTERRUPT
    
}              

