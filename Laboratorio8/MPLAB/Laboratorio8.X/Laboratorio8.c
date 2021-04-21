/*
 * File:   Laboratorio8.c
 * Author: ashley
 *
 * Created on April 20, 2021, 12:15 PM
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
#define _XTAL_FREQ 4000000
#define Reinicio_Timer0 237

//VARIABLES
char Valor_potenciometro;        //VARIABLE QUE ALMACENA VALOR POTENCIOMETRO 2
int Multiplexado;               //VARIABLE PARA TOGGLE
char Centenas; char Decenas; char Unidades;     //VARIABLES PARA DIVISION
char A;                         //VARIABLE PARA CONVERTIDOR

//PROTOTIPOS DE FUNCIONES
void setup(void);               //FUNCION DE CONGIFURACION
char Convertidor(char A);       //FUNCION PARA CONVERTIR DATOS PARA MOSTRAR EN DISPLAY
char Division(void);            //FUNCION PARA CONVERTIR VALORES DE CONTADOR A DECIMALES


//INTERRUPCIONES
void __interrupt() isr(void) {
   if (ADIF) {      
       if (ADCON0bits.CHS == 12){//INTERRUPCION PARA INCREMENTAR O DECREMENTAR CONTADOR 
       PORTA = ADRESH;
       __delay_us(50);
       ADCON0bits.CHS = 10;    //PIN RB1 CONFIGURADO PARA ADC
       }
       else if (ADCON0bits.CHS == 10){
           Valor_potenciometro = ADRESH;
           ADCON0bits.CHS = 12;
       }
       PIR1bits.ADIF = 0;    //BAJANDO BANDERA A/D INTERRUPT
    }
   
   if (T0IF) {  
      
        PORTEbits.RE2 = 0;      //LIMPIAR TRANSISTORES Y PUERTO PARA CORRECTO FUNCIONAMIENTO DE DISPLAYS
        PORTEbits.RE1 = 0;
        PORTEbits.RE0 = 0;
        PORTC = 0;
        
        if (Multiplexado == 0){     //SI MULTIPLEXADO = 0
            PORTEbits.RE2 = 0;      //ENCENDER DISPLAY 1
            PORTEbits.RE0 = 1;      
            A = Centenas;
            Convertidor(A);         //MOSTRAR CENTENAS DE CONTADOR
            Multiplexado = 1;       //MULTIPLEXADO = 1 PARA IR A DISPLAY 2
        }
        else if (Multiplexado == 1) {   //SI MULTIPLEXADO = 1
            PORTEbits.RE0 = 0;          //ENCENDER DISPLAY 2
            PORTEbits.RE1 = 1;
            A = Decenas;                //MOSTRAR DECENAS DE CONTADOR 
            Convertidor(A); 
            Multiplexado = 2;           //MULTIPLEXADO = 2 PARA IR A DISPLAY 3     
        } 
        else if (Multiplexado == 2) {   //SI MULTIPLEXADO = 2
            PORTEbits.RE1 = 0;          //ENCENDER DISPLAY 3
            PORTEbits.RE2 = 1;
            A = Unidades;               //MOSTRAR UNIDADES DE CONTADOR
            Convertidor(A);
            Multiplexado = 0;           //MULTIPLEXADO = 0 PARA IR A DISPLAY 1
        }
        
        TMR0 = Reinicio_Timer0;         //REINICIAR TIMER0
        INTCONbits.T0IF = 0;            //BAJANDO BANDERA DE TIMER0 OVERLOW INTERRUPT              
    }
   
}

//MAIN
void main(void) {
    setup();
    while (1)
    {
        __delay_us(50);
        ADCON0bits.GO_nDONE = 1;    //COMENZAR CONVERSION
        Division();
    }
}

//FUNCIONES
void setup(void) {

    //LEDS 
    ANSEL = 0;      //CONFIGURANDO PUERTO A COMO OUTPUT
    TRISA = 0;
    PORTA = 0;
    
    //DISPLAY
    TRISC = 0;     //CONFIGURANDO PUERTO C COMO OUTPUT
    PORTC = 0;
    
        //TRANSISTORES
        PORTE = 0;
        TRISE = 0;
    
    //POTENCIOMETROS
    ANSELH = 0b11111111;             //CONFIGURANDO ENTRADAS ANALOGICAS EN EL PUERTO B
    TRISB = 0b11111111;
    PORTB = 0;
    ADCON0bits.CHS = 12;    //PIN RB0 CONFIGURADO PARA ADC

    
    //CONFIGURACION ADC
    ADCON0bits.ADON = 1;        //ENCENDER MODULO
    __delay_us(50);
    ADCON0bits.GO_nDONE = 1;    //COMENZAR CONVERSION
    
        //VOLTAJES DE REFERENCIA 
        ADCON1bits.VCFG0 = 0;   //+
        ADCON1bits.VCFG1 = 0;   //-
        
        //FUENTE DE RELOJ
        ADCON0bits.ADCS0 = 1;   //Fosc/8, TAD = 2us.
        ADCON0bits.ADCS1 = 0;
        
    //INTERRUPCIONES
        INTCONbits.GIE = 1;    //HABILITANDO INTERRUPCIONES GLOBALES Y PERIFERICAS
        INTCONbits.PEIE = 1;
            
        //A/D INTERRUPT
        PIR1bits.ADIF = 0;      //BAJANDO BANDERA DE A/D INTERRUPT
        PIE1bits.ADIE = 1;      //HABILITANDO A/D INTERRUPT
        
        //FORMATO DE RESULTADO
        ADCON1bits.ADFM = 0;    //JUSTIFICADO A LA IZQUIERDA
        
    //CONFIGURACION DE OSCILADOR
    OSCCONbits.SCS = 1;     //ACTIVANDO OSCILADOR INTERNO
    OSCCONbits.IRCF0 = 0;   //ELIGIENDO OSCILADOR DE 4 MHz
    OSCCONbits.IRCF1 = 1;
    OSCCONbits.IRCF2 = 1;
    
    //CONFIGURACION DE TIMER0
    
        //PSA Y TIMER MODE
        OPTION_REGbits.T0CS = 0; //SELECCIONANDO OSCILADOR INTERNO
        OPTION_REGbits.PSA = 0; //PSA PROGRAMABLE PARA TIMER0
        OPTION_REGbits.PS0 = 1; //PSA DE 256
        OPTION_REGbits.PS1 = 1;
        OPTION_REGbits.PS2 = 1;

        //TIMER0 INTERRUPT
        INTCONbits.T0IE = 1; //HABILITANDO TIMER0 OVERFLOW INTERRUPT
        INTCONbits.T0IF = 0; //BAJANDO BANDERA DE OVERLOW INTERRUPT
        TMR0 = 0; //LIMPIANDO TMR0
}

char Convertidor(char A) {      //DEPENDIENDO DEL VALOR EN A, ELEGIRA LA TRADUCCION NECESARIA PARA MOSTRAR EN DISPLAY
    
    if (A == 0) {
        PORTC = 0b00111111;
    }
    if (A == 1) {
        PORTC = 0b00000110;
    }
    if (A == 2) {
        PORTC = 0b01011011;
    }
    if (A == 3) {
        PORTC = 0b01001111;
    }
    if (A == 4) {
        PORTC = 0b01100110;
    }
    if (A == 5) {
        PORTC = 0b01101101;
    }
    if (A == 6) {
        PORTC = 0b01111101;
    }
    if (A == 7) {
        PORTC = 0b00000111;
    }
    if (A == 8) {
        PORTC = 0b01111111;
    }
    if (A == 9) {
        PORTC = 0b01101111;
    }
}

char Division(void){
    Centenas = (Valor_potenciometro/100);         //GUARDAR EN CENTENAS EL RESULTADO ENTERO DE LA DIVISION
    Decenas = (Valor_potenciometro % 100)/10;     //GUARDAR EN DECENAS EL RESULTADO ENTERO DE LA DIVISON DEL RESIDUO DE CENTENAS ENTRE 10
    Unidades = (Valor_potenciometro % 100) % 10;  //GUARDAR EN UNIDADES EL RESIDUO DE AMBAS DIVISIONES
}