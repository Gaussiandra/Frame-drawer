LOCALS
.model tiny
.code

org 100h

VIDEOSEG    = 0b800h
MAX_STR_LEN = 256
CMD_ARGS    = 82h
CMD_WIDTH   = 80
X1          = 20
Y1          = 5
X2          = 60
Y2          = 15
STYLE_OFFSET = 6

BLUE        = 1
GREEN       = 2
CYAN        = 3
RED         = 4
MAGENTA     = 5
BROWN       = 6

start:      
            ; cmd arguments handling
            cld
            mov si, CMD_ARGS
            lodsb

            cmp ax, '0'
            je @@uStyle
            cmp ax, '1'
            je @@sStile
            cmp ax, '2'
            je @@dStyle
            cmp ax, '3'
            je @@cStile
            ; jmp @@printError

@@printError:
            mov ah, 9
            mov dx, offset argErrorMsg
            int 21h
            jmp exit
@@uStyle:  
            mov si, CMD_ARGS + 2
            jmp @@next
@@sStile:
            mov si, offset singleStyle
            jmp @@next
@@dStyle:
            mov si, offset doubleStyle
            jmp @@next
@@cStile:
            mov si, offset cringeStyle
            ; jmp @@next
@@next:

            mov ax, VIDEOSEG
            mov es, ax

            xor di, di
            mov di, (CMD_WIDTH * Y1 + X1) * 2

            mov dx, Y2 - Y1
            mov cx, X2 - X1
            call drawFrame

exit:
            mov ax, 4ch
            int 21h

;-----------------------------
; Draws entire frame
; Entry: DX - number of lines
;        CX - middle line length
;        DI - drawing addr
;        SI - drawing style
; Destr: AX, CX, DX, DI, SI
; Note:  ES - videosegment
;        DF = 0
;-----------------------------
drawFrame   proc
            call drawLine
            add si, 3                   ; points to middle top style
            
            push si
            mov bl, [si]
            mov si, offset frameName
            add cx, 2
            call printString
            sub cx, 2
            pop si

            add di, 2 * CMD_WIDTH
            add si, 3                   ; 3 + 3 = STYLE_OFFSET

@@oneLine:
            call drawLine
            add di, 2 * CMD_WIDTH

            dec dx
            cmp dx, 0
            jne @@oneLine
            
            add si, STYLE_OFFSET
            call drawLine
            
            ret
endp

;-----------------------------
; Prints string near provided place
; Entry: DI - addr of start position of entire line
;        SI - addr of string to print
;        BL - string color attr
;        CX - length of entire place-line
; Destr: AX, SI, BX
;-----------------------------
printString proc

            push di
            push cx
            push bx

            push di
            mov di, si
            call strlen
            pop di

            ; calc di - mov position of string
            mov bx, ax                  ; ax - length of printing string
            shr bx, 1                  
            add di, cx
            sub di, ax                  ; name position on the frame
            sub di, 2

            or di, 1                    ; make videoseg filling correct

            ; mov string on the line
            pop bx
            xor cx, cx                  ; counter
@@printLetter:
            mov bh, [si]
            mov es:[di], bx
            
            add di, 2
            inc si
            inc cx
            cmp cx, ax
            jne @@printLetter

            pop cx
            pop di

            ret
endp

;-----------------------------
; Draws line in the frame
; Entry: CX - middle line length > 0
;        DI - drawing addr
;        SI - char+color addr to draw
; Destr: AX
; Note:  DF = 0
;        ES - videosegment
;-----------------------------
drawLine    proc

            push cx
            push di
            push si

            lodsw       ; AX = *SI, SI += 2
            stosw       ; ES:[DI] = AX, DI += 2
            lodsw
            rep stosw
            lodsw
            stosw

            pop si
            pop di
            pop cx

            ret
endp

;-----------------------------
; Find length of string
; Entry: DI - addr of string
; Ret:   AX - strlen
; Destr: DI, AX
; Note:  DF = 0
;-----------------------------
strlen      proc

            push cx
            push es

            mov ax, ds
            mov es, ax
            mov cx, MAX_STR_LEN

            xor ax, ax
            mov al, '$'

            repne scasb
            mov ax, MAX_STR_LEN
            sub ax, cx
            dec ax

            pop es
            pop cx

            ret
endp

.data
argErrorMsg:  db 'Unknown arguments$'
frameName:    db 'Privet ded$'

doubleStyle:  db 201, BROWN, 205, GREEN, 187, BROWN
              db 186, GREEN, 0,   0,     186, GREEN
              db 200, BROWN, 205, GREEN, 188, BROWN, '$'

singleStyle:  db 218, BROWN, 196, GREEN, 191, BROWN
              db 179, GREEN, 0,   0,     179, GREEN
              db 192, BROWN, 196, GREEN, 217, BROWN, '$'

cringeStyle:  db '+', CYAN,  196, BROWN, '+', RED
              db 179, GREEN, 0,   0,     179, GREEN
              db '+', BLUE,  196, RED,   '+', MAGENTA, '$'

end start
; убрать магические константы, проверить описания, общую логичность и подпилить всё
; проверить передачу аргументов
; выводить надпись только, если влезает
; анимация