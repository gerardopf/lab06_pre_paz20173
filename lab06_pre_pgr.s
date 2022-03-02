/*	
    Archivo:		lab06_pre_pgr.s
    Dispositivo:	PIC16F887
    Autor:		Gerardo Paz 20173
    Compilador:		pic-as (v2.30), MPLABX V6.00

    Programa:		Temporizadores 
    Hardware:		Leds en puerto A

    Creado:			02/03/22
    Última modificación:	02/03/22	
*/

PROCESSOR 16F887
#include <xc.inc>

; CONFIG1
CONFIG  FOSC = INTRC_NOCLKOUT ; Oscillator Selection bits (INTOSCIO oscillator: I/O function on RA6/OSC2/CLKOUT pin, I/O function on RA7/OSC1/CLKIN)
CONFIG  WDTE = OFF            ; Watchdog Timer Enable bit (WDT disabled and can be enabled by SWDTEN bit of the WDTCON register)
CONFIG  PWRTE = OFF            ; Power-up Timer Enable bit (PWRT enabled)
CONFIG  MCLRE = OFF           ; RE3/MCLR pin function select bit (RE3/MCLR pin function is digital input, MCLR internally tied to VDD)
CONFIG  CP = OFF              ; Code Protection bit (Program memory code protection is disabled)
CONFIG  CPD = OFF             ; Data Code Protection bit (Data memory code protection is disabled)
CONFIG  BOREN = OFF           ; Brown Out Reset Selection bits (BOR disabled)
CONFIG  IESO = OFF            ; Internal External Switchover bit (Internal/External Switchover mode is disabled)
CONFIG  FCMEN = OFF           ; Fail-Safe Clock Monitor Enabled bit (Fail-Safe Clock Monitor is disabled)
CONFIG  LVP = OFF              ; Low Voltage Programming Enable bit (RB3/PGM pin has PGM function, low voltage programming enabled)

; CONFIG2
CONFIG  BOR4V = BOR40V        ; Brown-out Reset Selection bit (Brown-out Reset set to 4.0V)
CONFIG  WRT = OFF             ; Flash Program Memory Self Write Enable bits (Write protection off)
    
 /*---------------- Macros ---------------*/
 reset_timer1 macro		    //siempre hay que volver a asignarle el valor al TMR0
    BANKSEL T1CON
    MOVLW   0x0B
    MOVWF   TMR1H	// B en parte alta
    MOVLW   0xDC	
    MOVWF   TMR1L	// DC en parte baja
    BCF	    TMR1IF	// Limpiar bandera
    ENDM   
    
 /*---------------- RESET ----------------*/
 PSECT resVect, class=CODE, abs, delta=2	
 ORG 00h					
 resVect:
       PAGESEL main
       GOTO    main

 /*--------------- Variables --------------*/ 
 PSECT udata_shr
 CONT:		    DS  1	    //Contador
 W_TEMP:	    DS  1	    
 STATUS_TEMP:	    DS  1
   
 /*-------------- Interrupciones ---------------*/   
 PSECT intVect, class=CODE, abs, delta=2    
 ORG 04h
 
 push:
    MOVWF   W_TEMP	    //Movemos W en la temporal
    SWAPF   STATUS, W	    //Pasar el SWAP de STATUS a W
    MOVWF   STATUS_TEMP	    //Guardar STATUS SWAP en W	
    
 isr:    
    BTFSC   TMR1IF	    //Revisar bandera Timer1
    CALL    int_timer1
    
 pop:
    SWAPF   STATUS_TEMP, W  //Regresamos STATUS a su orden original y lo guaramos en W
    MOVWF   STATUS	    //Mover W a STATUS
    SWAPF   W_TEMP, F	    //Invertimos W_TEMP y se guarda en F
    SWAPF   W_TEMP, W	    //Volvemos a invertir W_TEMP para llevarlo a W
    RETFIE
      
 /*------------ Subrutinas de interrupción ------------*/
 int_timer1:
    reset_timer1
    BANKSEL PORTA
    INCF    CONT	// incrementar contador
    MOVF    CONT, W
    MOVWF   PORTA	// mostrar contador
    RETURN
    
 /*----------------- COONFIGURACIÓN uC --------------------*/
 PSECT code, delta=2, abs	
 ORG 100h			//Dirección 100% seguro de que ya pasó el reseteo
 
 main:
    CALL    setup_io
    CALL    setup_int
    CALL    setup_clk
    CALL    setup_timer1
    BANKSEL PORTA
    
 loop:
    GOTO    loop
    
 setup_io:
    BANKSEL ANSEL
    CLRF    ANSEL
    CLRF    ANSELH  // i/o digitales
    
    BANKSEL TRISA
    CLRF    TRISA   // A out
    
    BANKSEL PORTA
    CLRF    PORTA   // Limpiar puertos
    
    CLRF    CONT    // limpiar contador
    RETURN
    
 setup_int:
    BANKSEL PIE1
    BSF	    TMR1IE  //	interrupción Timer1 ON
    BANKSEL PORTA
    BSF	    GIE	    // interrupciones globales ON
    BSF	    PEIE    // interrupciones de periféricos ON
    
    BCF	    TMR1IF  // limpiar bandera Timer1
    RETURN
    
 setup_clk:
    BANKSEL OSCCON
    BSF	SCS		//Activar oscilador interno
    
    // 1 MHz(100)
    BSF IRCF2		
    BCF IRCF1		
    BCF IRCF0		
    RETURN

 setup_timer1:
    //Desbordamiento 1000 ms
    /*
	N = 65536 - (td / (Prescaler * ti))
	td = 1000 ms
	ti = 1 MHz
	N = 3036 = 0xBDC
    */
    BANKSEL T1CON
    BCF	    TMR1GE	// Siempre va a estar contando
    
    //Prescaler 1:4
    BSF	    T1CKPS1
    BCF	    T1CKPS0
    
    BCF	    T1OSCEN	// Low power oscillator apagado
    BCF	    TMR1CS	// reloj interno
    
    BSF	    TMR1ON	// Timer 1 encendido
    reset_timer1	// Asignar valores iniciales 
    RETURN