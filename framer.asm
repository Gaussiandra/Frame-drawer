.model tiny
.code

org 100h

VIDEOSEG    = 0b800h
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
            mov si, 82h
            lodsb

            cmp ax, '0'
            je uStyle
            cmp ax, '1'
            je sStile
            cmp ax, '2'
            je dStyle
            cmp ax, '3'
            je cStile

printError:
            mov ah, 9
            mov dx, offset argErrorMsg
            int 21h
            jmp exit
uStyle:  
            mov si, 84h
            jmp next
sStile:
            mov si, offset singleStyle
            jmp next
dStyle:
            mov si, offset doubleStyle
            jmp next
cStile:
            mov si, offset cringeStyle
            jmp next
next:

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
;-----------------------------
drawFrame   proc

            cld

            call drawLine
            add di, 2 * CMD_WIDTH
            add si, STYLE_OFFSET

oneLine:; сделать local
            call drawLine
            add di, 2 * CMD_WIDTH

            dec dx
            cmp dx, 0
            jne oneLine
            
            add si, STYLE_OFFSET
            call drawLine
            
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

.data
argErrorMsg:  db 'Unknown arguments$'

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