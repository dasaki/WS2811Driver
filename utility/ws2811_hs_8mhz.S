;--------------------------------------------------------------------------------------------------------------
; ws2811_hs.S - ws2811 high speed write routine for rgb controller
;--------------------------------------------------------------------------------------------------------------
;
;    Copyright (C) 2012  Kevin Timmerman
;
;   This program is free software: you can redistribute it and/or modify
;   it under the terms of the GNU General Public License as published by
;   the Free Software Foundation, either version 3 of the License, or
;   (at your option) any later version.
;
;   This program is distributed in the hope that it will be useful,
;   but WITHOUT ANY WARRANTY; without even the implied warranty of
;   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;   GNU General Public License for more details.
;
;   You should have received a copy of the GNU General Public License
;   along with this program.  If not, see <http://www.gnu.org/licenses/>.
;--------------------------------------------------------------------------------------------------------------
; 11-15-2012 - rick@kimballsoftware.com modified for msp430-gcc
; 10-27-2015 - www.therandomlab.com - David Sanz Kirbis, modified for 8MHz clock
;--------------------------------------------------------------------------------------------------------------

#include <msp430.h>
#include "ws2811.h"

        .file "ws2811_hs.S"
        .global write_ws2811_hs_8

;--------------------------------------------------------------------------------------------------------------
; void write_ws2811_hs_8(uint8_t *data, uint16_t length, uint8_t pinmask, uint8_t portmask);
;                         data - R15,    length - R14,    pinmask - R13    portmask - @R12
;
; NOTE: assumes interrupts are disabled as cycle counts are used for timing
;
; --- High Speed Mode 800KHz
;        High / Low us   High / Low cycles @ 8 MHz
; Zero:  0.25 / 1.00        2 / 8
; One:   0.60 / 0.65        5 / 6
; Reset:    0 / 50+         0 / 400+
;
;
;--------------------------------------------------------------------------------------------------------------
        .section .text.write_ws2811_hs_8
        .p2align 1,0                    ; align on a word boundary
        .type write_ws2811_hs_8,@function
write_ws2811_hs_8:
        push    R9                      ; Save R9
        push    R10                     ; Save R10
        push    R11                     ; Save R11
        bic.b   R13, @R12               ; Output low
        mov.b   @R12, R10               ; copy port status in R10 
        mov.b   @R12, R11               ; copy port status in R11
        bis.b   R13, R11                ; set data pin bit high in R11 
byte_loop_hs:                           ;
        mov     #7, R13                 ; Do 7 bits in a loop
        mov.b   @R15+, R9               ; Get next byte from buffer
bit_loop_hs:                            ; - Bit loop - 20 cycles per bit
        rla.b   R9                      ; Get next bit
        jc      one_hs                  ; Jump if one...
        mov.b   R11, @R12               ; Output high
        mov.b   R10, @R12               ; Output low - 2 cycles elapsed
        jmp     $ + 2                   ; 2 cycle nop
        jmp     next_bit_hs             ; Next bit...
one_hs:                                 ;
        mov.b   R11, @R12
        jmp     $ + 2                   ; 2 cycle nop
        nop                   		      ; 1 cycle nop
        mov.b   R10, @R12               ; Output low - 5 cycles elapsed
	
next_bit_hs:                            ;
        dec     R13                     ; Decrement bit count
        jne     bit_loop_hs             ; Do next bit of not zero...

        rla.b   R9                      ; Get final bit of byte
        jc      last_one_hs             ; Jump if one...
        mov.b   R11, @R12               ; Output high
        mov.b   R10, @R12               ; Output low - 2 cycles elapsed
        dec     R14                     ; Decrement byte count
        jne     byte_loop_hs            ; Next byte if count not zero...
        jmp     reset_hs                ; All bytes done, reset...
last_one_hs:                            ;
        mov.b   R11, @R12               ; Output high
        mov     #7, R13                 ; Reset bit counter
        mov.b   @R15+, R9               ; Get next byte from buffer
        mov.b   R10, @R12               ; Output low - 5 cycles elapsed
        dec     R14                     ; Decrement byte count
        jne     bit_loop_hs             ; Do next byte if count is not zero...
                                        ;
reset_hs:                               ;
        mov     #400 / 3, R9            ; 800 cycle delay for reset
        dec     R9                      ;
        jne     $ - 2                   ;
        pop     R11                     ; Restore R11
        pop     R10                     ; Restore R10
        pop     R9                      ; Restore R9
        ret                             ; Return
