;Archivo:	Timer1-2.s
;Dispositivo:	    PIC16F887
;Autor:	    Juan Diego Villafuerte
;Compilador: pic-as (v2.30), MPLABX V5.40
;
;Programa:	
;Hardware:	LED en puestos D, 7 segmentos en puerto C
;
;Creado;	23 marzo 2021
;Ultima modificación:	    23 marzo 2021

PROCESSOR 16F887
#include <xc.inc>
    ;configuration word 1

    CONFIG FOSC=INTRC_NOCLKOUT // Osilador interno sin salida
    CONFIG WDTE=OFF // WDT disabled (reinicio repetitivo del pic)
    CONFIG PWRTE=ON // PWRT eneable (espeera de 72ms al inicial)
    CONFIG MCLRE=OFF // El pin de MCLR se utiliza como I/O 
    CONFIG CP=OFF // Sin proteccion de código
    CONFIG CPD=OFF // Sin proteccion de datos
    
    CONFIG BOREN=OFF //Sin reinicio cuando el voltaje de alimentación baja de 4V
    CONFIG IESO=OFF // Reinicio sin cambio de reloj de interno a externo
    CONFIG FCMEN=OFF // Cambio de reloj externo a interno en caso de fallo
    CONFIG LVP=ON // Programación en bajo voltaje permitida
    
    ;configuration word 2
    
    CONFIG WRT=OFF // Proteccion de autoescritura por el programa desactivada
    CONFIG BOR4V=BOR40V // Reinicio abajo de 4V1 (BOR21V=2.1V)
     
    PSECT udata_shr ;common memory
	W_TEMP: DS 1 ;1 byte
	STATUS_TEMP: DS 1 ;var: DS 5
	var: DS 1
	banderas: DS 1
	contador: DS 1
	display: DS 2
	nibble: DS 2
    
;_Para el vector reset   
    PSECT resVect, class=CODE, abs, delta=2
    ORG 00h	;posicion 0000h para el reset
    
resetVec:
	PAGESEL main
	goto main
    

    PSECT intVect, class=CODE, abs, delta=2
    ORG 04h	;posicion 0004h para el reset

push:	    ;guardar W y STATUS
    movwf  W_TEMP
    swapf STATUS,w
    movwf STATUS_TEMP
       
isr:
    
    btfsc INTCON,2  ;Para revisar el overflow del timer0
    call taimer0
    
    btfsc PIR1,1    ;Para revisar la interrupcion de timer2
    call taimer2
    
    btfsc PIR1,0    ;Para revisar el overflow del timer1
    call taimer1
    
pop:	    ;desplegar los guardados de W y STATUS
    swapf STATUS_TEMP,w
    movwf STATUS
    swapf W_TEMP,f
    swapf W_TEMP,w
    retfie

    PSECT code, delta=2, abs
    ORG 100h
    
tabla7seg:
    clrf PCLATH
    bsf PCLATH,0
    ;andwf 0x0F
    
    addwf PCL

    retlw 00111111B	;0
    retlw 00000110B	;1
    retlw 01011011B	;2
    retlw 01001111B	;3
    retlw 01100110B	;4
    retlw 01101101B	;5
    retlw 01111101B	;6
    retlw 00000111B	;7
    retlw 01111111B	;8
    retlw 01100111B	;9
    retlw 01110111B	;A
    retlw 01111100B	;B
    retlw 00111001B	;C
    retlw 01011110B	;D
    retlw 01111001B	;E
    retlw 01110001B	;F   

main:
    call config_inter_eneable
    call config_io
    bsf banderas,0

loop:
    call separar
    call cargar    
    
    goto loop

taimer2:
    banksel PIR1    ;reset timer2
    bcf PIR1,1
    clrf TMR2
    
    incf PORTE
    
    return

    
taimer1:
    banksel PIR1    ;reset timer1
    movlw 11011100B
    movwf TMR1L
    movlw 1011B
    movwf TMR1H
    bcf TMR1IF
        
    incf var
    
    return
    
taimer0:
    banksel PORTA   ;reset timer0
    movlw 170
    movwf TMR0
    bcf INTCON,2
    
    clrf PORTD    
    btfss PORTE,0
    goto $+5
    
    btfsc banderas,0	;chequeo de banderas 
    goto display1
    btfsc banderas,1
    goto display0
    clrf PORTC

    return

display0:	;displays individuales
    movf display,w
    movwf PORTC
    bsf PORTD,1

    bcf banderas,1
    bsf banderas,0
    return
    
display1:
    movf display+1,w
    movwf PORTC
    bsf PORTD,0
    
    bcf banderas,0
    bsf banderas,1
    return
    
separar:    ;para separar el nibble en 2 partes
    movf var,w
    andlw 0x0f
    movwf nibble
    
    swapf var,w
    andlw 0x0f
    movwf nibble+1
    return   
    
cargar:	    ;traduccion del binario a hex
    movf nibble,w
    call tabla7seg
    movwf display
    
    movf nibble+1,w 
    call tabla7seg
    movwf display+1
    
    return
    
config_io:
    
    banksel ANSEL
    clrf ANSEL
    clrf ANSELH
    
    banksel TRISA
    clrf TRISC
    clrf TRISD
    bcf TRISE,0
    
    bsf PIE1,0	   ;Limpiar las banderas de ambos Timers 
    bsf PIE1,1
    
    movlw 244	   ;Cargar el valor para el PR2 de 244
    movwf PR2
    
    banksel PORTA
    clrf PORTC
    clrf PORTD
    clrf PORTE
    
    bcf PIR1,1
    bcf PIR1,0
    
    ;T1CON
    bsf T1CON,0	    ;Para encender el Timer1
    bcf T1CON,1	    ;Para que use el reloj interno
    
    bcf T1CON,3	    ;Para el LowPower
    bcf T1CON,4	    ;Para cargar el valor del prescalar de 1:4
    bsf T1CON,5	    
    
    bcf T1CON,6
    
    ;T2CON
    bsf T2CON,1	    ;Para cargar el prescalar de 1:16
    bsf T2CON,2	    ;Para encender el Timer2
    
    bsf T2CON,3	    ;Para cargar el postscaler de 1:16
    bsf T2CON,4
    bsf T2CON,5
    bsf T2CON,6
    
    
    ;OPTION_REG
 
    banksel OPTION_REG
    bcf OPTION_REG,5 ;Para configurar como timer interno
    bcf OPTION_REG,3 ;Activar el prescaler para timer0
    
    bcf OPTION_REG,0 ;Cargar el prescaler
    bcf OPTION_REG,1 
    bsf OPTION_REG,2 
    
    ;OSCCON
    
    banksel OSCCON
    bsf OSCCON,6     ;Config del osilador a 1MHz
    bcf OSCCON,5
    bcf OSCCON,4
    
    bsf OSCCON,0     ;osilador interno
    return    
    
config_inter_eneable:
    bsf GIE	    ;encender interrupciones
    bsf T0IE	    ;encender interrupcion timer0
    bsf PEIE	    ;encender interrupcion timer1
    
    return
    
end


