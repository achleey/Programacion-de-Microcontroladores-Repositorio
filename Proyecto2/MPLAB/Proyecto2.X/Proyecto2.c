/*
 * File:   Proyecto2.c
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
#include <pic16f887.h>

//DIRECTIVAS DEL COMPILADOR
#define _XTAL_FREQ 8000000      //OSICLADOR DE 8MHz

//VARIABLES
uint8_t DireccionEE = 0;        //VARIABLE AUMENTADA PARA GUARDAR VALOR EN 5 POSICIONES
uint8_t ADC;                    //VARIABLE USADA PARA GUARDAR EL VALOR DE ADC
uint8_t LeerEE[5];              //ALMACENA LAS 5 POSICIONES QUE ACABAN DE SUCEDER

//PROTOTIPOS DE FUNCIONES
void setup(void);               //FUNCION DE CONGIFURACION
void Escribir(uint8_t Valor, uint8_t Direccion);    //ESCRIBIR VALOR DE ADRESH A EEPROM
uint8_t Leer(uint8_t Direccion);                    //LEER VALOR ALMACENADO EN EEPROM Y GUARDAR EN CCPRL1
void ADCaEEPROM(uint8_t Direccion_adc);             //PREPARAR 5 VALORES EN POSICIONES 

//INTERRUPCIONES
void __interrupt() isr(void) {
   if (ADIF) {   
       
       if (ADCON0bits.CHS == 0){    //POTENCIOMETRO 1
       CCPR1L = (ADRESH>>1)+200;
       ADCON0bits.CHS = 1;    //PIN RA1 CONFIGURADO PARA ADC
       
   }
       else if (ADCON0bits.CHS == 1){
       CCPR2L = (ADRESH>>1)+200;
       ADCON0bits.CHS = 0;
   }
       PIR1bits.ADIF = 0;
   }
   return;
}


//MAIN
void main(void) {
    setup();
    int i;
    while (1)
    {
        __delay_us(100);
        if(ADCON0bits.GO_nDONE == 0){
            __delay_us(50);
        ADCON0bits.GO_nDONE = 1;    //COMENZAR CONVERSION
        }     
        
        if (RB0 == 0){
            ADCON0bits.ADON = 0;       //APAGAR CONVERSION DE ADC
            ADC = ADRESH;               //GUARDAR VALOR DE ADRESH EN ADC
            ADCaEEPROM(ADC);           //GUARDAR 5 POSICIONES EN 5 DIRECCIONES
            PORTDbits.RD0 = 1;          //ENCENDER LED PARA CONFIRMACION
        }
        if (RB1 == 0){
            ADCON0bits.ADON = 0;        //APAGAR CONVERSION DE ADC
            PORTDbits.RD1 = 1;          //ENCENDER LED PARA CONFIRMACION
            
            for(DireccionEE=0;DireccionEE<5;DireccionEE++)  //GUARDAR 5 POSICIONES ANTERIORES EN CCPR1L
    {
        for(int i=0;i<5;i++)
        {
            LeerEE[i]=Leer(DireccionEE);
        }
    }
            CCPR1L = LeerEE[i];
            PORTDbits.RD1 = 0;
        }
        else{
        ADCON0bits.ADON = 1;       //ENCENDER CONVERSION DE ADC
        }
    }
}

//FUNCIONES
void setup(void){
    
    //LEDS DE PRUEBA
    TRISDbits.TRISD0 = 0;
    TRISDbits.TRISD1 = 0;
    PORTD = 0;
    
    //BOTON DE INCREMENTO Y DECREMENTO
    TRISBbits.TRISB1 = 1;
    TRISBbits.TRISB0 = 1;
    
    //BOTON INCREMENTO Y BOTON DECREMENTO
    ANSELH = 0;
    PORTB = 0;

    //ACTIVANDO PULL UP INDIVIDUALES PARA PUERTO B
    OPTION_REGbits.nRBPU = 0;
    
    //ACTIVANDO PULL UP INTERNO PARA BOTON INCREMENTO Y DECREMENTO
    WPUB = 0b00000011;
  
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
        PR2 = 255;
        
        //PWM
        CCP1CONbits.P1M = 0b00;         //PWM OUTPUT CONFIGURATION BITS
        CCP2CONbits.DC2B0 = 0;          //MODO PWM
        CCP2CONbits.DC2B1 = 0;
        CCP2CONbits.CCP2M = 0b1111;
        CCP1CONbits.CCP1M = 0b1100;     //ECCP SELECT BITS
        
        CCPR1L = 0x0f;                  //CARGANDO VALOR INCIAL
        CCP1CONbits.DC1B = 0;           //BITS MENOS SIGNIFICATIVOS DEL DUTY CYCLE  
        CCPR2L = 0x0f;                 //CARGANDO VALOR INICIAL
        PIR1bits.TMR2IF = 0;    //BAJANDO BANDERA DE OVERFLOW
    
        //PSA
        T2CONbits.T2CKPS1 = 1;    //PSA 16
        T2CONbits.TMR2ON = 1;    //HABILITANDO TIMER2
            
            
    while(PIR1bits.TMR2IF == 0);    //ESPERANDO UN CICLO
    PIR1bits.TMR2IF = 0;
    TRISC = 0;
            
    //INTERRUPCIONES
    INTCONbits.GIE = 1;      //HABILITANDO INTERRUPCIONES GLOBALES Y PERIFERICAS
    INTCONbits.PEIE = 1;
//    PIE1bits.RCIE = 1;      //HABILITANDO INTERRUPCIONES POR TRANSMICION Y RECEPCION
//    PIE1bits.TXIE = 1;
    
        //A/D INTERRUPT
        PIR1bits.ADIF = 0;      //BAJANDO BANDERA DE A/D INTERRUPT
        PIE1bits.ADIE = 1;      //HABILITANDO A/D INTERRUPT
    
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
        RCSTAbits.CREN = 1;      //HABILITANDO RECEPTOR EUSART ASÍNCRONO
        RCSTAbits.RX9 = 0;       //RECEPCION DE 8 BITS
    
        return;
}     

uint8_t Leer(uint8_t Direccion){
//LEE Y REGRESA EL VALOR QUE ESTA EN DIRECCION
     
EEADR = Direccion;              //CARGAR DIRECCION EN EEADR
EECON1bits.EEPGD = 0;           //ACCESANDO EEPROM
EECON1bits.RD = 1;              //PEDIR QUE LEA EL VALOR EN EEPROM
return EEDATA;
}

void Escribir(uint8_t Valor_adc, uint8_t Direccion){
//TOMA VALOR ADC Y LO ESCRIBE EN DIRECCION
    
EEIF = 0; 
EEADR = Direccion;              //GUARDAR VALOR_ADC EN DIRECCION PARA MOSTRAR EN SERVO
EEDATA = Valor_adc;             //GUARDAR VALOR_ADC EN EEDATA
EECON1bits.EEPGD = 0;           //ACCESANDO EEPROM
EECON1bits.WREN = 1;            //ACTIVAR ESCRITURA
INTCONbits.GIE = 0;             //DESACTIVAR INTERRUPCIONES
EECON2 = 0x55;                  //SECUENCIA PARA ESCRITURA
EECON2 = 0xAA;
EECON1bits.WR = 1;              //PEDIRLE QUE ESCRIBA EN EEPROM
while(PIR2bits.EEIF == 0);      //MANTENER ACA SI NO HA TERMINADO EL CICLO DE ESCRITURA
PIR2bits.EEIF = 0;              //BAJAR LA BANDERA CUANDO HAYA TERMINADO EL CICLO DE ESCRITURA
EECON1bits.WREN = 0;            //DESACTIVAR ESCRITURA POR SEGURIDAD
INTCONbits.GIE = 1;             //ACTIVAR INTERRUPCIONES
return;
}

void ADCaEEPROM(uint8_t Direccion_adc){
    Escribir(Direccion_adc, DireccionEE);
    DireccionEE++;              //SIGUIENTE DIRECCION
    if (DireccionEE == 5)       //SOLO GUARDAR 5 VALORES DE ADC
        DireccionEE = 0;
    return;
}


