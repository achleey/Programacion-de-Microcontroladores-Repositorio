/*
 * File:   Laboratorio10.c
 * Author: ashley
 *
 * Created on May 3, 2021, 8:26 PM
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
#define _XTAL_FREQ 4000000      //DECLARANDO OSCILADOR DE 4MHZ

//VARIABLES
char Pregunta[] = {"Que accion desea realizar?\r"};         //DEFINIENDO CADENAS A TRANSMITIR
char Opcion1[] = {"(1) Desplegar cadena de caracteres\r"};
char Opcion2[] = {"(2) Cambiar PORTA\r"};
char Opcion3[] = {"(3) Cambiar PORTB\r"};
char Cadena[] = {"HOLI :)\r"};
char Nuevo[] = {"Ingrese nuevo caracter\r"};
char Opcion;                                       //VARIABLE PARA CONTROL DE OPCIONES

//PROTOTIPOS DE FUNCIONES
void setup(void);               //FUNCION DE CONGIFURACION
void menu(void);                //MENU A DESPLEGAR

////MAIN
void main(void) {            
    setup();    
    
    while (1){
        menu();
         while(RCIF==0)         //MANTENER EN EL LOOP MIENTRAS NO SE HAYA RECIBIDO NINGUN DATO
            ;
        Opcion = RCREG;         //CONTROL DE OPCION SELECCIONADO 
        if (Opcion == '1'){     //SI SE SELECCIONA LA OPCION 1 
        for (int i = 0; i<8; i++){
        while (!TXIF);
        TXREG = Cadena[i];       //ENTONCES ENVIAR CADENA DE CARACTER
    }
        }
        else if (Opcion == '2'){    //SI SE SELECCIONA OPCION 2
        for (int i = 0; i<23; i++){
        while (!TXIF);
        TXREG = Nuevo[i];           //PREGUNTAR CARACTER PARA MOSTRAR
        while(!RCIF);               //ESPERAR CARACTER
        PORTA = RCREG;              //MOSTRARLO EN EL PUERTO A
    }
}
        else if (Opcion == '3'){    //SI SE SELECCIONA OPCION 3
        for (int i = 0; i<23; i++){ 
        while (!TXIF);
        TXREG = Nuevo[i];           //PREGUNTAR CARACTER PARA MOSTRAR
        while(!RCIF);               //ESPERAR CARACTER
        PORTD = RCREG;              //MOSTRARLO EN EL PUERTO D
    }
}
        else{
            TXSTAbits.TXEN = 0;     //SI SE PRESIONA UN CARACTER QUE NO SEA 1, 2 O 3, NO TRANSMITIR NADA
        }
        
        }
     
}

//FUNCIONES
void setup(void){

    //LEDS 
    ANSEL = 0;      //CONFIGURANDO PUERTO A Y D COMO OUTPUT
    TRISA = 0;
    TRISD = 0;
    PORTA = 0;
    PORTD = 0;
    
    //EUSART
    SPBRG = 23;                 //VALOR NECESARIO PARA UN BAUD RATE DE 10,417 bits/s
    SPBRGH = 0;                 //CON UN Fosc DE 4MHZ 
    
        //BAUD RATE GENERATOR
        BAUDCTLbits.BRG16 = 0;    //USANDO 8-BIT BAUD RATE GENERATOR
        TXSTAbits.BRGH = 1;       //SELECCIONANDO HIGH SPEED BAUD RATE 
        
        RCSTAbits.SPEN = 1;       //HABILITANDO EUSART Y TX/RX COMO PUERTOS SERIALES
        TXSTAbits.SYNC = 0;       //SELECCIONANDO FUNCIONAMIENTO ASÍNCRONO
    
        //TRANSMISOR
        TXSTAbits.TXEN = 1;       //HABILITANDO TRANSMISOR EUSART ASÍNCRONO
        TXSTAbits.TX9 = 0;        //TRANSMICIÓN DE 8 BITS.
        
        //RECEPTOR
        RCSTAbits.CREN = 1;      //HABILITANDO RECEPTOR EUSAR ASÍNCRONO
        RCSTAbits.RX9 = 0;       //RECEPCION DE 8 BITS
    
    //INTERRUPCIONES
    INTCONbits.GIE = 1;    //HABILITANDO INTERRUPCIONES GLOBALES Y PERIFERICAS
    INTCONbits.PEIE = 1;
    
    //CONFIGURACION DE OSCILADOR
    OSCCONbits.SCS = 1;     //ACTIVANDO OSCILADOR INTERNO
    OSCCONbits.IRCF0 = 0;   //ELIGIENDO OSCILADOR DE 4 MHz
    OSCCONbits.IRCF1 = 1;
    OSCCONbits.IRCF2 = 1;
    
}

void menu(void){
        __delay_ms(200);                        //HACER UN DELAY PARA QUE PUEDA ENVIARSE EL DATO
            for (int i = 0; i < 28; i++){
                while(!TXIF);
                TXREG = Pregunta[i];            //TRANSMITIR EL MENU
            }
        //OPCION1
        __delay_ms(200);
        for (int i = 0; i < 35; i++){
                while(!TXIF);
                TXREG = Opcion1[i];
        }
        //OPCION 2
        __delay_ms(200);
        for (int i = 0; i < 18; i++){
                while(!TXIF);
                TXREG = Opcion2[i];
        }
        //OPCION 3
        __delay_ms(200);
        for (int i = 0; i < 19; i++){
                while(!TXIF);
                TXREG = Opcion3[i];
        }
       
        }


