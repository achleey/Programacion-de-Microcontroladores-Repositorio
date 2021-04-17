/*
 * File:   Laboratorio7.c
 * Author: ashley
 *
 * Created on April 13, 2021, 4:01 PM
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
#define Reinicio_Timer0 254     //DEFINIENDO VALOR PARA UNA INTERRUPCIÓN DE 5 MS

//VARIABLES
char Contador1;                 //VARIABLE PARA GUARDAR DATOS DE CONTADOR
int Multiplexado;               //VARIABLE PARA TOGGLE
char Centenas; char Decenas; char Unidades;     //VARIABLES PARA DIVISION
char A;                         //VARIABLE PARA CONVERTIDOR

//PROTOTIPOS DE FUNCIONES
void setup(void);               //FUNCION DE CONGIFURACION DE COMPONENTES
char Convertidor(char A);       //FUNCION PARA CONVERTIR DATOS PARA MOSTRAR EN DISPLAY
char Division(void);            //FUNCION PARA CONVERTIR VALORES DE CONTADOR A DECIMALES

//INTERRUPCIONES

void __interrupt() isr(void) {
    
    if (RBIF) {                 //INTERRUPCION PARA INCREMENTAR O DECREMENTAR CONTADOR
        if (RB0 == 0) {         //SI SE PRESIONA BOTON DE INCREMENTO
            PORTA++;            //INCREMENTAR
        }
        if (RB1 == 0) {         //SI SE PRESIONA BOTON DE DECREMENTO
            PORTA--;            //DECREMENTAR
        }
        INTCONbits.RBIF = 0;    //BAJANDO BANDERA INTERRUPT ON CHANGE
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
        Contador1 = PORTA;      //ENCENDER LEDS CON VALOR DEL CONTADOR
        Division();             //LLAMAR A LA FUNCION PARA CONVERTIR VALORES A DECIMAL
    }

}

//FUNCIONES

void setup(void) {

    //CONTADORES
    ANSEL = 0;      //CONFIGURANDO PUERTO A Y C COMO OUTPUT
    TRISA = 0;
    TRISC = 0;
    PORTA = 0;
    PORTC = 0;

    //BOTON INCREMENTO Y BOTON DECREMENTO
    ANSELH = 0;
    PORTB = 0;

    //ACTIVANDO PULL UP INDIVIDUALES PARA PUERTO B
    OPTION_REGbits.nRBPU = 0;

    //BOTON DE INCREMENTO Y DECREMENTO
    TRISB = 0b00000011;
    
    //TRANSISTORES DE DISPLAY
    PORTE = 0;
    TRISE = 0b0000;
    
    //ACTIVANDO PULL UP INTERNO PARA BOTON INCREMENTO Y DECREMENTO
    WPUB = 0b00000011;

    INTCONbits.GIE = 1;
    INTCONbits.PEIE = 1;
    
    //INTERRUPT-ON-CHANGE
    PORTB = PORTB;
    INTCONbits.RBIF = 0; //BAJANDO BANDERA INTERRUPT ON CHANGE
    INTCONbits.RBIE = 1; //ACTIVANDO INTERRUPT ON CHANGE EN PUERTO B
    IOCB = 0b00000011; //INTERRUPT ON CHANGE ACTIVADO PARA LOS BOTONES

    //CONFIGURACION DE OSCILADOR
    OSCCONbits.SCS = 1; //ACTIVANDO OSCILADOR INTERNO
    OSCCONbits.IRCF2 = 0; //ELIGIENDO OSCILADOR DE 250 KHZ
    OSCCONbits.IRCF1 = 1;
    OSCCONbits.IRCF0 = 0;

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
    Centenas = (Contador1/100);         //GUARDAR EN CENTENAS EL RESULTADO ENTERO DE LA DIVISION
    Decenas = (Contador1 % 100)/10;     //GUARDAR EN DECENAS EL RESULTADO ENTERO DE LA DIVISON DEL RESIDUO DE CENTENAS ENTRE 10
    Unidades = (Contador1 % 100) % 10;  //GUARDAR EN UNIDADES EL RESIDUO DE AMBAS DIVISIONES
}


