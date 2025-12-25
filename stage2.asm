[BITS 16]
[ORG 0x8000]

start:
    ; Inicializa modo de vídeo 13h (320x200, 256 cores)
    mov ax, 0x0013
    int 0x10
    
    ; Configura segmento de vídeo
    mov ax, 0xA000
    mov es, ax
    
    ; Desenha desktop
    call draw_desktop
    
    ; Renderiza janelas e apps
    call render_os
    
    ; Loop principal
main_loop:
    ; Aguarda tecla
    mov ah, 0x00
    int 0x16
    
    ; ESC para sair
    cmp al, 27
    je exit_program
    
    ; '1' abre calculadora
    cmp al, '1'
    je open_calculator
    
    ; '2' abre notepad
    cmp al, '2'
    je open_notepad
    
    ; '3' abre paint
    cmp al, '3'
    je open_paint
    
    jmp main_loop

open_calculator:
    call draw_desktop
    mov si, app_calculator
    call parse_document
    jmp main_loop

open_notepad:
    call draw_desktop
    mov si, app_notepad
    call parse_document
    jmp main_loop

open_paint:
    call draw_desktop
    mov si, app_paint
    call parse_document
    jmp main_loop

exit_program:
    ; Retorna ao modo texto
    mov ax, 0x0003
    int 0x10
    ret

; Desenha desktop
draw_desktop:
    ; Preenche fundo (azul)
    mov ax, 0
    mov bx, 0
    mov cx, 320
    mov dx, 200
    mov byte [color], 1
    call draw_filled_rect
    
    ; Barra de tarefas
    mov ax, 0
    mov bx, 180
    mov cx, 320
    mov dx, 20
    mov byte [color], 8
    call draw_filled_rect
    
    ; Botão Start
    mov ax, 2
    mov bx, 182
    mov cx, 50
    mov dx, 16
    mov byte [color], 7
    call draw_filled_rect
    
    mov ax, 2
    mov bx, 182
    mov cx, 50
    mov dx, 16
    mov byte [color], 15
    call draw_rect
    
    ; Texto "START"
    mov ax, 8
    mov bx, 186
    mov byte [text_color], 0
    mov si, txt_start
    call draw_text
    
    ; Relógio
    mov ax, 270
    mov bx, 186
    mov byte [text_color], 15
    mov si, txt_clock
    call draw_text
    
    ; Ícones no desktop
    call draw_desktop_icons
    
    ret

; Desenha ícones do desktop
draw_desktop_icons:
    ; Ícone 1 - Calculadora
    mov ax, 10
    mov bx, 10
    mov cx, 32
    mov dx, 32
    mov byte [color], 14
    call draw_filled_rect
    
    mov ax, 10
    mov bx, 10
    mov cx, 32
    mov dx, 32
    mov byte [color], 15
    call draw_rect
    
    mov ax, 12
    mov bx, 44
    mov byte [text_color], 15
    mov si, txt_calc
    call draw_text
    
    ; Ícone 2 - Notepad
    mov ax, 50
    mov bx, 10
    mov cx, 32
    mov dx, 32
    mov byte [color], 15
    call draw_filled_rect
    
    mov ax, 50
    mov bx, 10
    mov cx, 32
    mov dx, 32
    mov byte [color], 0
    call draw_rect
    
    mov ax, 52
    mov bx, 44
    mov byte [text_color], 15
    mov si, txt_note
    call draw_text
    
    ; Ícone 3 - Paint
    mov ax, 90
    mov bx, 10
    mov cx, 32
    mov dx, 32
    mov byte [color], 11
    call draw_filled_rect
    
    mov ax, 90
    mov bx, 10
    mov cx, 32
    mov dx, 32
    mov byte [color], 15
    call draw_rect
    
    mov ax, 92
    mov bx, 44
    mov byte [text_color], 15
    mov si, txt_paint
    call draw_text
    
    ret

; Renderiza o SO
render_os:
    mov si, os_startup
    call parse_document
    ret

; Parser de documentos
parse_document:
.parse_loop:
    lodsb
    cmp al, 0
    je .done
    
    cmp al, '<'
    je .parse_tag
    
    jmp .parse_loop

.parse_tag:
    ; Lê o nome da tag
    lodsb
    
    cmp al, 'w'
    je .check_window
    
    cmp al, 'b'
    je .check_button
    
    cmp al, 'p'
    je .check_panel_or_print
    
    cmp al, 'm'
    je .check_menu
    
    jmp .parse_loop

.check_panel_or_print:
    lodsb
    cmp al, 'a'
    je .is_panel
    cmp al, 'r'
    je .is_print
    dec si
    dec si
    jmp .parse_loop

.is_panel:
    lodsb
    lodsb
    lodsb
    call parse_panel
    jmp .parse_loop

.is_print:
    lodsb
    lodsb
    lodsb
    call parse_print
    jmp .parse_loop

.check_window:
    ; <window>
    call parse_window
    jmp .parse_loop

.check_button:
    ; <button>
    call parse_button
    jmp .parse_loop

.check_menu:
    ; <menu>
    call parse_menu
    jmp .parse_loop

.done:
    ret

; Tag <print x y color>texto</print>
parse_print:
    push si
    
    call extract_attributes
    
    ; Extrai cor se presente
    mov byte [text_color], 15
    
.find_color:
    lodsb
    cmp al, 'c'
    je .get_color
    cmp al, '>'
    je .get_text
    cmp al, 0
    je .done
    jmp .find_color

.get_color:
    call skip_to_value
    call parse_number
    mov [text_color], al
    jmp .find_color

.get_text:
    ; Extrai texto
    mov di, text_buffer
    
.text_loop:
    lodsb
    cmp al, '<'
    je .draw
    cmp al, 0
    je .draw
    stosb
    jmp .text_loop

.draw:
    mov byte [di], 0
    
    mov ax, [attr_x]
    mov bx, [attr_y]
    mov si, text_buffer
    call draw_text

.done:
    pop si
    ret

; Desenha janela
parse_window:
    push si
    
    call extract_attributes
    
    mov ax, [attr_x]
    mov bx, [attr_y]
    mov cx, [attr_w]
    mov dx, [attr_h]
    
    call draw_window
    
    pop si
    ret

; Desenha botão
parse_button:
    push si
    
    call extract_attributes
    
    mov ax, [attr_x]
    mov bx, [attr_y]
    mov cx, [attr_w]
    mov dx, [attr_h]
    
    call draw_button
    
    ; Extrai e desenha texto do botão
    mov di, text_buffer
    
.find_text:
    lodsb
    cmp al, '>'
    je .get_text
    cmp al, 0
    je .done
    jmp .find_text

.get_text:
    lodsb
    cmp al, '<'
    je .draw_text
    cmp al, 0
    je .draw_text
    stosb
    jmp .get_text

.draw_text:
    mov byte [di], 0
    
    ; Centraliza texto no botão
    mov ax, [attr_x]
    add ax, 5
    mov bx, [attr_y]
    add bx, 5
    mov byte [text_color], 15
    mov si, text_buffer
    call draw_text

.done:
    pop si
    ret

; Desenha painel
parse_panel:
    push si
    
    call extract_attributes
    
    mov ax, [attr_x]
    mov bx, [attr_y]
    mov cx, [attr_w]
    mov dx, [attr_h]
    
    call draw_panel
    
    pop si
    ret

; Desenha menu
parse_menu:
    push si
    
    call extract_attributes
    
    mov ax, [attr_x]
    mov bx, [attr_y]
    mov cx, [attr_w]
    mov dx, 18
    
    mov byte [color], 7
    call draw_filled_rect
    
    pop si
    ret

; Extrai atributos x="n" y="n" w="n" h="n" color="n"
extract_attributes:
    push si
    
    mov word [attr_x], 0
    mov word [attr_y], 0
    mov word [attr_w], 100
    mov word [attr_h], 50

.find_attr:
    lodsb
    cmp al, '>'
    je .done
    cmp al, 0
    je .done
    
    cmp al, 'x'
    je .get_x
    
    cmp al, 'y'
    je .get_y
    
    cmp al, 'w'
    je .get_w
    
    cmp al, 'h'
    je .get_h
    
    jmp .find_attr

.get_x:
    call skip_to_value
    call parse_number
    mov [attr_x], ax
    jmp .find_attr

.get_y:
    call skip_to_value
    call parse_number
    mov [attr_y], ax
    jmp .find_attr

.get_w:
    call skip_to_value
    call parse_number
    mov [attr_w], ax
    jmp .find_attr

.get_h:
    call skip_to_value
    call parse_number
    mov [attr_h], ax
    jmp .find_attr

.done:
    pop si
    ret

skip_to_value:
    lodsb
    cmp al, '"'
    jne skip_to_value
    ret

parse_number:
    xor ax, ax
    xor cx, cx
    
.loop:
    mov dx, ax
    lodsb
    
    cmp al, '"'
    je .done
    cmp al, ' '
    je .done
    cmp al, '>'
    je .done_back
    
    sub al, '0'
    cmp al, 9
    ja .done
    
    mov cl, al
    mov ax, dx
    mov dx, 10
    mul dx
    add ax, cx
    
    jmp .loop

.done_back:
    dec si
.done:
    ret

; Desenha uma janela
draw_window:
    push ax
    push bx
    push cx
    push dx
    
    ; Sombra
    push ax
    push bx
    push cx
    push dx
    
    add ax, 3
    add bx, 3
    mov byte [color], 0
    call draw_filled_rect
    
    pop dx
    pop cx
    pop bx
    pop ax
    
    ; Borda externa
    push ax
    push bx
    push cx
    push dx
    
    mov byte [color], 8
    call draw_filled_rect
    
    pop dx
    pop cx
    pop bx
    pop ax
    
    ; Interior
    add ax, 2
    add bx, 2
    sub cx, 4
    sub dx, 4
    
    push ax
    push bx
    push cx
    push dx
    
    mov byte [color], 7
    call draw_filled_rect
    
    ; Barra de título
    pop dx
    pop cx
    pop bx
    pop ax
    
    push ax
    push bx
    push cx
    
    mov dx, 16
    mov byte [color], 1
    call draw_filled_rect
    
    ; Botões de controle (X, -, □)
    pop cx
    pop bx
    pop ax
    
    push ax
    add ax, cx
    sub ax, 16
    add bx, 2
    
    mov cx, 12
    mov dx, 12
    mov byte [color], 12
    call draw_filled_rect
    
    pop ax
    ret

; Desenha botão
draw_button:
    push ax
    push bx
    push cx
    push dx
    
    ; Borda
    mov byte [color], 15
    call draw_rect
    
    pop dx
    pop cx
    pop bx
    pop ax
    
    add ax, 1
    add bx, 1
    sub cx, 2
    sub dx, 2
    
    mov byte [color], 8
    call draw_filled_rect
    
    ret

; Desenha painel
draw_panel:
    push ax
    push bx
    push cx
    push dx
    
    mov byte [color], 8
    call draw_rect
    
    pop dx
    pop cx
    pop bx
    pop ax
    
    add ax, 1
    add bx, 1
    sub cx, 2
    sub dx, 2
    
    mov byte [color], 0
    call draw_filled_rect
    
    ret

; Desenha retângulo preenchido
draw_filled_rect:
    push ax
    push bx
    push cx
    push dx
    
    mov [rect_y], bx
    mov [rect_h], dx
    
.row_loop:
    cmp dx, 0
    jle .done
    
    push ax
    push bx
    push cx
    push dx
    call draw_hline
    pop dx
    pop cx
    pop bx
    pop ax
    
    inc bx
    dec dx
    jmp .row_loop
    
.done:
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; Desenha borda
draw_rect:
    push ax
    push bx
    push cx
    push dx
    
    push dx
    call draw_hline
    pop dx
    
    add bx, dx
    dec bx
    call draw_hline
    
    pop dx
    pop cx
    pop bx
    pop ax
    
    push ax
    push bx
    
    mov cx, dx
    call draw_vline
    
    pop bx
    pop ax
    
    push cx
    add ax, cx
    dec ax
    
    mov cx, dx
    call draw_vline
    
    pop cx
    ret

; Linha horizontal
draw_hline:
    push cx
    
.loop:
    cmp cx, 0
    jle .done
    
    push ax
    push bx
    push cx
    call plot_pixel
    pop cx
    pop bx
    pop ax
    
    inc ax
    dec cx
    jmp .loop
    
.done:
    pop cx
    ret

; Linha vertical
draw_vline:
    push cx
    
.loop:
    cmp cx, 0
    jle .done
    
    push ax
    push bx
    push cx
    call plot_pixel
    pop cx
    pop bx
    pop ax
    
    inc bx
    dec cx
    jmp .loop
    
.done:
    pop cx
    ret

; Plot pixel (AX=x, BX=y)
plot_pixel:
    push ax
    push bx
    push dx
    
    ; Limites da tela
    cmp ax, 320
    jae .out
    cmp bx, 200
    jae .out
    
    ; Calcula offset
    push ax
    mov ax, bx
    mov dx, 320
    mul dx
    pop bx
    add ax, bx
    
    mov di, ax
    mov al, [color]
    stosb
    
.out:
    pop dx
    pop bx
    pop ax
    ret

; Desenha texto usando fonte 8x8
draw_text:
    push ax
    push bx
    push si
    
.loop:
    lodsb
    cmp al, 0
    je .done
    
    push ax
    push bx
    push si
    
    call draw_char
    
    pop si
    pop bx
    pop ax
    
    add ax, 6
    jmp .loop
    
.done:
    pop si
    pop bx
    pop ax
    ret

; Desenha um caractere (AL=char, AX=x, BX=y)
draw_char:
    push ax
    push bx
    push cx
    push dx
    
    ; Calcula offset na fonte
    sub al, 32
    mov cl, 8
    mul cl
    mov si, ax
    add si, font_data
    
    pop dx
    pop cx
    
    ; Desenha 8 linhas
    mov dh, 8
    
.line_loop:
    push cx
    push dx
    
    lodsb
    mov dl, al
    mov cl, 8
    
.pixel_loop:
    test dl, 0x80
    jz .skip_pixel
    
    push cx
    push dx
    
    mov ax, cx
    mov bx, dx
    push si
    push di
    
    mov al, [text_color]
    push ax
    mov al, [color]
    mov [color_backup], al
    pop ax
    mov [color], al
    
    call plot_pixel
    
    mov al, [color_backup]
    mov [color], al
    
    pop di
    pop si
    pop dx
    pop cx
    
.skip_pixel:
    shl dl, 1
    inc cx
    dec cl
    jnz .pixel_loop
    
    pop dx
    pop cx
    inc dx
    dec dh
    jnz .line_loop
    
    pop bx
    pop ax
    ret

; Dados
txt_start db 'START', 0
txt_clock db '12:00', 0
txt_calc db 'Calc', 0
txt_note db 'Note', 0
txt_paint db 'Paint', 0

os_startup:
    db '<window x="80" y="50" w="160" h="100">'
    db '<print x="90" y="70" color="0">Bem-vindo!</print>'
    db '<print x="85" y="82" color="0">Sistema Operacional</print>'
    db '<print x="95" y="94" color="0">MyOS v1.0</print>'
    db '<button x="100" y="120" w="60" h="20">OK</button>'
    db 0

app_calculator:
    db '<window x="100" y="40" w="120" h="140">'
    db '<print x="110" y="58" color="0">Calculadora</print>'
    db '<panel x="108" y="72" w="104" h="20">'
    db '<print x="115" y="77" color="10">0</print>'
    db '<button x="108" y="96" w="22" h="18">7</button>'
    db '<button x="132" y="96" w="22" h="18">8</button>'
    db '<button x="156" y="96" w="22" h="18">9</button>'
    db '<button x="180" y="96" w="22" h="18">/</button>'
    db '<button x="108" y="116" w="22" h="18">4</button>'
    db '<button x="132" y="116" w="22" h="18">5</button>'
    db '<button x="156" y="116" w="22" h="18">6</button>'
    db '<button x="180" y="116" w="22" h="18">*</button>'
    db '<button x="108" y="136" w="22" h="18">1</button>'
    db '<button x="132" y="136" w="22" h="18">2</button>'
    db '<button x="156" y="136" w="22" h="18">3</button>'
    db '<button x="180" y="136" w="22" h="18">-</button>'
    db '<button x="108" y="156" w="46" h="18">0</button>'
    db '<button x="156" y="156" w="22" h="18">=</button>'
    db '<button x="180" y="156" w="22" h="18">+</button>'
    db 0

app_notepad:
    db '<window x="40" y="30" w="240" h="140">'
    db '<print x="50" y="48" color="0">Notepad - Sem titulo</print>'
    db '<menu x="48" y="62" w="224" h="18">'
    db '<print x="52" y="66" color="0">Arquivo  Editar  Ajuda</print>'
    db '<panel x="48" y="82" w="224" h="76">'
    db '<print x="52" y="86" color="10">Digite aqui...</print>'
    db 0

app_paint:
    db '<window x="20" y="20" w="280" h="150">'
    db '<print x="30" y="38" color="0">Paint - Desenho</print>'
    db '<menu x="28" y="52" w="264" h="16">'
    db '<print x="32" y="56" color="0">Pincel  Borracha  Cores</print>'
    db '<panel x="28" y="70" w="264" h="88">'
    db '<print x="120" y="110" color="11">Area de desenho</print>'
    db 0

; Variáveis
attr_x dw 0
attr_y dw 0
attr_w dw 0
attr_h dw 0
rect_x dw 0
rect_y dw 0
rect_w dw 0
rect_h dw 0
color db 0
text_color db 15
color_backup db 0
text_buffer times 128 db 0

; Fonte 8x8 simplificada (ASCII 32-127)
font_data:
    ; Espaço (32)
    db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
    ; ! (33)
    db 0x18, 0x18, 0x18, 0x18, 0x00, 0x18, 0x18, 0x00
    ; " (34)
    db 0x66, 0x66, 0x66, 0x00, 0x00, 0x00, 0x00, 0x00
    ; # (35)
    db 0x6C, 0xFE, 0x6C, 0x6C, 0xFE, 0x6C, 0x00, 0x00
    ; $ (36)
    db 0x18, 0x7E, 0x06, 0x3C, 0x60, 0x7E, 0x18, 0x00
    ; % (37)
    db 0x66, 0x36, 0x18, 0x0C, 0x66, 0x63, 0x00, 0x00
    ; & (38)
    db 0x1C, 0x36, 0x1C, 0x6E, 0x3B, 0x33, 0x6E, 0x00
    ; ' (39)
    db 0x18, 0x18, 0x18, 0x00, 0x00, 0x00, 0x00, 0x00
    ; ( (40)
    db 0x30, 0x18, 0x0C, 0x0C, 0x0C, 0x18, 0x30, 0x00
    ; ) (41)
    db 0x0C, 0x18, 0x30, 0x30, 0x30, 0x18, 0x0C, 0x00
    ; * (42)
    db 0x00, 0x66, 0x3C, 0xFF, 0x3C, 0x66, 0x00, 0x00
    ; + (43)
    db 0x00, 0x18, 0x18, 0x7E, 0x18, 0x18, 0x00, 0x00
    ; , (44)
    db 0x00, 0x00, 0x00, 0x00, 0x00, 0x18, 0x18, 0x0C
    ; - (45)
    db 0x00, 0x00, 0x00, 0x7E, 0x00, 0x00, 0x00, 0x00
    ; . (46)
    db 0x00, 0x00, 0x00, 0x00, 0x00, 0x18, 0x18, 0x00
    ; / (47)
    db 0x60, 0x30, 0x18, 0x0C, 0x06, 0x03, 0x01, 0x00
    ; 0 (48)
    db 0x3C, 0x66, 0x76, 0x6E, 0x66, 0x66, 0x3C, 0x00
    ; 1 (49)
    db 0x18, 0x1C, 0x18, 0x18, 0x18, 0x18, 0x7E, 0x00
    ; 2 (50)
    db 0x3C, 0x66, 0x60, 0x30, 0x18, 0x0C, 0x7E, 0x00
    ; 3 (51)
    db 0x3C, 0x66, 0x60, 0x38, 0x60, 0x66, 0x3C, 0x00
    ; 4 (52)
    db 0x30, 0x38, 0x3C, 0x36, 0x7E, 0x30, 0x30, 0x00
    ; 5 (53)
    db 0x7E, 0x06, 0x3E, 0x60, 0x60, 0x66, 0x3C, 0x00
    ; 6 (54)
    db 0x38, 0x0C, 0x06, 0x3E, 0x66, 0x66, 0x3C, 0x00
    ; 7 (55)
    db 0x7E, 0x60, 0x30, 0x18, 0x0C, 0x0C, 0x0C, 0x00
    ; 8 (56)
    db 0x3C, 0x66, 0x66, 0x3C, 0x66, 0x66, 0x3C, 0x00
    ; 9 (57)
    db 0x3C, 0x66, 0x66, 0x7C, 0x60, 0x30, 0x1C, 0x00
    ; : (58)
    db 0x00, 0x18, 0x18, 0x00, 0x00, 0x18, 0x18, 0x00
    ; ; (59)
    db 0x00, 0x18, 0x18, 0x00, 0x00, 0x18, 0x18, 0x0C
    ; < (60)
    db 0x60, 0x30, 0x18, 0x0C, 0x18, 0x30, 0x60, 0x00
    ; = (61)
    db 0x00, 0x00, 0x7E, 0x00, 0x7E, 0x00, 0x00, 0x00
    ; > (62)
    db 0x06, 0x0C, 0x18, 0x30, 0x18, 0x0C, 0x06, 0x00
    ; ? (63)
    db 0x3C, 0x66, 0x60, 0x30, 0x18, 0x00, 0x18, 0x00
    ; @ (64)
    db 0x3C, 0x66, 0x76, 0x56, 0x76, 0x06, 0x3C, 0x00
    ; A (65)
    db 0x18, 0x3C, 0x66, 0x66, 0x7E, 0x66, 0x66, 0x00
    ; B (66)
    db 0x3E, 0x66, 0x66, 0x3E, 0x66, 0x66, 0x3E, 0x00
    ; C (67)
    db 0x3C, 0x66, 0x06, 0x06, 0x06, 0x66, 0x3C, 0x00
    ; D (68)
    db 0x1E, 0x36, 0x66, 0x66, 0x66, 0x36, 0x1E, 0x00
    ; E (69)
    db 0x7E, 0x06, 0x06, 0x3E, 0x06, 0x06, 0x7E, 0x00
    ; F (70)
    db 0x7E, 0x06, 0x06, 0x3E, 0x06, 0x06, 0x06, 0x00
    ; G (71)
    db 0x3C, 0x66, 0x06, 0x76, 0x66, 0x66, 0x7C, 0x00
    ; H-Z e outros caracteres
    db 0x66, 0x66, 0x66, 0x7E, 0x66, 0x66, 0x66, 0x00 ; H
    db 0x7E, 0x18, 0x18, 0x18, 0x18, 0x18, 0x7E, 0x00 ; I
    db 0x60, 0x60, 0x60, 0x60, 0x66, 0x66, 0x3C, 0x00 ; J
    db 0x66, 0x36, 0x1E, 0x0E, 0x1E, 0x36, 0x66, 0x00 ; K
    db 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x7E, 0x00 ; L
    db 0x63, 0x77, 0x7F, 0x6B, 0x63, 0x63, 0x63, 0x00 ; M
    db 0x66, 0x6E, 0x7E, 0x76, 0x66, 0x66, 0x66, 0x00 ; N
    db 0x3C, 0x66, 0x66, 0x66, 0x66, 0x66, 0x3C, 0x00 ; O
    db 0x3E, 0x66, 0x66, 0x3E, 0x06, 0x06, 0x06, 0x00 ; P
    db 0x3C, 0x66, 0x66, 0x66, 0x76, 0x36, 0x6C, 0x00 ; Q
    db 0x3E, 0x66, 0x66, 0x3E, 0x36, 0x66, 0x66, 0x00 ; R
    db 0x3C, 0x66, 0x06, 0x3C, 0x60, 0x66, 0x3C, 0x00 ; S
    db 0x7E, 0x18, 0x18, 0x18, 0x18, 0x18, 0x18, 0x00 ; T
    db 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x3C, 0x00 ; U
    db 0x66, 0x66, 0x66, 0x66, 0x66, 0x3C, 0x18, 0x00 ; V
    db 0x63, 0x63, 0x63, 0x6B, 0x7F, 0x77, 0x63, 0x00 ; W
    db 0x66, 0x66, 0x3C, 0x18, 0x3C, 0x66, 0x66, 0x00 ; X
    db 0x66, 0x66, 0x66, 0x3C, 0x18, 0x18, 0x18, 0x00 ; Y
    db 0x7E, 0x60, 0x30, 0x18, 0x0C, 0x06, 0x7E, 0x00 ; Z
    ; Caracteres especiais adicionais para completar até 127
    times 288 db 0x00

times 1024-($-$) db 0