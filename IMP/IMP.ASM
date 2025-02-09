    .model tiny
; Not my best piece of code but I had fun putting it together
; Didn't have time to optimize the code, but that wasn't the point.
; This source code could use some comments but I was focused on
; making it run and once it was done I just shipped it as it was.
; anyway, enjoy :)

; omen/Dimension, e-mail omen@arrakis.cs.put.poznan.pl
    .486P
    .code
    locals
;go=$
org 100h                                  ; entry point
start:
       dec di
       dec bp
       inc bp
       dec si
       mov ax,4300h
       int 2fh
       cmp al,80h
       jz oki0
       mov dx,offset Blad00
       jmp KoniecX
oki0:  mov eax,cr0
       test al,1
       jz oki
       mov dx,offset Blad01
       jmp KoniecX
oki:
       mov ax,4f01h
       mov cx,010Dh
       mov di,offset bufor
       int 10h
       mov ax,4f02h
       mov bx,010Dh+4000h
       int 10h
       test ah,1
       jz oki2
       mov dx,offset Blad02
       jmp KoniecX
oki2:
       mov ax,3508h
       int 21h
       mov word ptr ds:[OldVect],bx
       mov word ptr ds:[OldVect+2],es
       mov dx,offset NewInt08
       mov ah,25h
       int 21h
       mov al,36h
       out 43h,al
       mov ax,17039
       out 40h,al
       mov al,ah
       out 40h,al
       xor ax,ax
       mov es,ax                         ; es jest od flata
; plasma
; generowanie palety
        xor bp,bp
palloop:
        mov cx,bp
        and cl,11110000b
        shl cx,1+5
        mov ax,bp
        shr ax,6
        add ax,cx
        mov ax,bp
        and al,11100000b
        add cx,ax
    ;    not cx
    ;    and ch,7fh
        mov word ptr [bp+paleta2],cx
        inc bp
        inc bp
        cmp bp,512
        jnz palloop
; gen. plasmy
        mov edi,3*1024*1024+512*1024+128*1024
        mov esi,edi
        mov ebx,[plasmaw]
        mov word ptr es:[2*ebx],0
        mov bl,127
        mov word ptr es:[2*ebx],96
        mov bh,127
        mov word ptr es:[2*ebx],255
        xor bl,bl
        mov word ptr es:[2*ebx],190
        xor ax,ax
        mov cx,7f7fh
        mov [fpu1],255
RekBegin:
        mov dx,ax
        add dx,cx
        shr dx,1
        and dl,7fh
        or ah,ah
        jnz Y1N0
        call random
        call PG01
Y1N0:   xchg ax,cx
        call random
        call PG01
        or cl,cl
        jnz X1N0
        call random
        call PG02
X1N0:   xchg ax,cx
        call random
        call PG02
        call random
        sal bp,1
        mov bh,ah
        mov bl,dl
        add bp,word ptr es:[2*ebx]
        mov bh,ch
        add bp,word ptr es:[2*ebx]
        mov bx,cx
        mov bh,dh
        add bp,word ptr es:[2*ebx]
        mov bl,al
        add bp,word ptr es:[2*ebx]
        sar bp,2
        and bp,255
        mov bl,dl
        mov word ptr es:[2*ebx],bp
        cmp [fpu1],2              ;!!!!!!!!!!
        jl NoRek
        shr [fpu1],1
        call GenRek
        xchg al,bl
        xchg bl,cl
        call GenRek
        xchg al,cl
        xchg ah,bh
        xchg bl,cl
        xchg bh,ch
        call GenRek
        mov al,bl
        mov bl,cl
        call GenRek
NoRek:  cmp esi,edi
        jne NextRek
; powielenie plasmy na 4 polowki
        mov ah,127
cploopy:
        mov al,127
cploopx:
        mov bx,ax
        mov bp,word ptr es:[2*ebx]
        not bh
        mov word ptr es:[2*ebx],bp
        not bl
        mov word ptr es:[2*ebx],bp
        not bh
        mov word ptr es:[2*ebx],bp
        dec al
        jns cploopx
        dec ah
        jns cploopy
; tworzenie tablic do landscape'u
        ; w ebx jest plasmaw
        mov esi,[plasmac]
; - utworzenie kolorowej tablicy z plasma
        mov edi,[plasmatabl]
        xor bx,bx
cp2loopx:
        mov di,bx
        mov bp,word ptr es:[2*ebx]
        shl bp,1
        mov bp,word ptr ds:[bp+paleta2]
        mov word ptr es:[2*edi],bp
        inc bx
        jnz cp2loopx

        mov ax,4
        call BlurPlasma
; cieniowanie landscape'u
        xor ax,ax
sdfgh:  mov si,ax
        mov bx,ax
        inc bl
        mov cx,word ptr es:[2*ebx]
        sub bl,2
        sub cx,word ptr es:[2*ebx]
        sal cx,1
        add cx,128
        inc bl
        inc bh
        add cx, word ptr es:[2*ebx]
        add cx,word ptr es:[2*ebx]
        sub bh,2
        sub cx,word ptr es:[2*ebx]
        sub cx,word ptr es:[2*ebx]
        inc bh
        and cx,255
        mov word ptr es:[2*esi],cx
        inc ax
        jnz sdfgh
        mov ax,3
        mov ebx,esi
        call BlurPlasma
; generacja tablicy do nieba
        mov ax,100
skytloop:
        mov [fpu1],ax
        finit
        fild [wys]
        fidiv [fpu1]
        fld st(0)
        fimul [fpuw20]
        fld st(0)
        fidiv [fpuw160]
        fild [dist]
        fmul st(3),st(0)
        fsubp st(3),st(0)
        fimul [fpuw256]
;        fmul st(1),st(0)
;        fmulp st(2),st(0)
        fistp [fpu1]
        mov cx,[fpu1]
        mov bx,100
        sub bx,ax
        shl bx,2
        mov word ptr [bx+skytabl],cx
        fistp [fpu1]
        mov cl,byte ptr [fpu1]
        fistp [fpu1]
        mov ch,byte ptr [fpu1]
        mov word ptr [bx+skytabl+2],cx
        dec ax
        jnz skytloop

; generacja tablicy do tunelu
Gentunel:
        mov cx,-100
        mov ebp,[tuneltabl]
GTLY:
        mov bx,-160
GTLX:
        mov [fpu1],cx
        fild [fpu1]
        fmul st(0),st(0)
        mov [fpu1],bx
        fild [fpu1]
        fmul st(0),st(0)
        faddp st(1)
        fsqrt
        fistp [fpu1]

        mov ax,10000
        cwd
        mov di,[fpu1]
        or di,di
        jnz diok
        inc di
diok:
        div di
        mov dh,al
        mov di,cx
        or di,di
        jnz diok2
        inc di
diok2:  mov [fpu1],di
        fild [fpu1]
        mov di,bx
        or di,di
        jnz diok3
        inc di
diok3:  mov [fpu1],di
        fild [fpu1]
        fpatan
        fldpi
        faddp st(1)
        fld1
        fidiv [fpuw10]
        faddp st(1)
        fimul [fpuw128]
        fldpi
        fdivp st(1),st(0)
        fistp [fpu1]
        mov dl,byte ptr [fpu1]
        mov word ptr es:[2*ebp],dx
        inc bp
        inc bx
        cmp bx,160
        jnz GTLX
        inc cx
        cmp cl,100
        jnz GTLY
; no i palety phonga
CreatePhongPal:
        xor di,di
CPPLoop:
        xor cx,cx
        mov ds:[fpu1],di
        fild ds:[fpu1]          ; 2x do koprocesora
        fidiv ds:[fpu4]         ; x/512         \
        fldpi                   ;                >To zeby kat byl w I cwiartce
        fmulp st(1)             ; i jeszcze *PI /
        fsin
        mov bx,rozproszenie-1
        fld st(0)
PotLoop:
        fmul st(0),st(1)
        dec bx
        jnz PotLoop
        fimul [natezenie]        ; jeszcze mnoze przez natezenie
        mov bp,offset red
ColorLoop:
        mov bx,word ptr ds:[bp]              ; bierzemy skladowa koloru
        fild word ptr ds:[bp]
        add bp,2
        fmul st(0),st(2)        ; sklad2=skladowa*sin(kat(x))
        fadd st(0),st(1)        ; sklad2=sklad2+natezenie*(sin(kat))^rozproszenie
        mov ax,rozjasnienie
        mul bx                  ; sklad=skladowa*rozjasnienie
        shr ax,7                ; sklad=sklad/64
        fistp word ptr ds:[fpu1]
        add ax,ds:[fpu1]             ; sklad=sklad+sklad2
        cmp ax,15
        jl RedOK
        mov ax,15               ; jesli sklad>63 to sklad=63
RedOK:
        shl cx,5
        or cl,al
        cmp bp,offset red+6      ; czy juz byl red, green i blue ???
        jnz ColorLoop
        mov word ptr ds:[di+offset paleta1],cx
        fninit
        inc di
        inc di
        cmp di,256*2
        jnz CPPLoop
; +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
       call CreateBumpMap
       call Go01
; Nieruchomy bump
       mov [counter],280
BumpLoop01:
       xor ebp,ebp
       mov bp,100
       mov ax,160
       mov esi,ebp
       mov cx,ax
       call MakeBump
       jnz BumpLoop01
;-----------------------------------
       push es
       mov ax,1130h
       mov bh,3
       int 10h
       push es
       pop fs
       pop es
       mov [fonty],bp
       mov edi,[slidescreen]
       push edi
       call ClrScr2
       call ClrScr
       mov bx,offset tekst1
       pop edi
       mov di,640*(100-16)+320-256
       mov cx,0011110111101111b
       call Writetext
; Wjezdza napis "OMEN"
       mov [counter],500
       mov [fpu2],4
BumpLoop02:
       fild [fpu2]
       fmul st(0),st(0)
       fsin
       fimul [fpuw320]
       fidiv [fpu2]
       fistp [fpu1]
       mov ax,[fpu1]
       inc [fpu2]
       call SlideScr
       call KScan
       jnz BumpLoop02
; Napis "OMEN" nieruchomy
       mov [counter],210
BumpLoop022:
       mov ax,0
       call SlideScr
       call KScan
       jnz BumpLoop022
; Fade down napisu
       mov [counter],32*8
       mov cx,0111111111111111b
BumpLoop0222:
       mov edi,dword ptr [bufor+28h]
       mov bx,offset tekst1
       mov di,640*(100-16)+320-256
       push cx
       call Writetext
       call Kscan
       pop cx
       test [counter],7
       jnz bl0222skip
       shr cx,1
       and cx,0011110111101111b
bl0222skip:
       or cx,cx
       jnz BumpLoop0222
; Zwykly bump
       mov [counter],400
BumpLoop03:
       call Wsp1
       call MakeBump
       jnz BumpLoop03

       mov edi,[slidescreen]
       push edi
       call ClrScr2
       call ClrScr
; Fade up napisu "presents"
       mov [counter],32*8+140 ; 250
       xor cx,cx
BumpLoop04:
       mov bx,offset tekst2
       mov edi,dword ptr [bufor+28h]
       mov di,640*(100-16)+320-256
       push cx
       call Writetext
       call KScan
       pop cx
       test [counter],7
       jnz BumpLoop04
       cmp cx,0111111111111111b
       jz BumpLoop042
       add cx,0000010000100001b
       jmp BumpLoop04
BumpLoop042:
       cmp [counter],0
       jnz BumpLoop04

       pop edi
       mov bx,offset tekst2
       mov di,640*(100-16)+320-256
       mov cx,0100001000010000b
       call Writetext
       call ClrScr
; Napis "presents" wyjezdza
       mov [fpu1],0
BumpLoop044:
       mov ax,[fpu1]
       inc [fpu1]
       inc [fpu1]
       call SlideScr
       call Kscan
       cmp [fpu1],320
       jnz BumpLoop044

; maly przerywnik, tunel non-standard
       mov ax,128
       call GenSinus
       mov [counter],400
       mov byte ptr [mt1],0
m:
       call MakeTunel1
mm:
       mov bx,word ptr es:[2*ebp]
       add bh,byte ptr [mt1]
       add bl,byte ptr [mt2]
       add byte ptr [mt2],4
       call MakeTunel2
       cmp bp,64000
       jnz mm
       add byte ptr [mt1],4
       call MakeTunel1
       call KScan
       jnz mm
; IMP-Create
       mov al,9         ; ilosc elementow
       mov si,offset ImpBump
       call AddTitle
       call Go01
       call ClrScr
       mov [counter],900
; Imp
BumpLoop05:
       call Wsp1
       call MakeBump
       jnz BumpLoop05
; plasma strange #2
       mov [counter],500
       mov ax,64 ;48
       call GenSinus
pls2:
       call ShowPlasma
       call Kscan
       jnz pls2
; tunel przod i tyl
       mov ax,128
       call GenSinus

       mov [counter],700
       mov byte ptr [mt1],0
l:
       call MakeTunel1
ll:
;       add bh,byte ptr [counter]
       mov bx,word ptr es:[2*ebp]
       add bh,byte ptr [mt1]
    ;   add bh,byte ptr [mt2]
    ;   add bl,byte ptr [mt2]
    ;   add byte ptr [mt2],4
       call MakeTunel2
       cmp bp,64000
       jnz ll
       add byte ptr [mt1],4
       call MakeTunel1
       call KScan
       jnz ll
       mov [counter],128*8
;       mov byte ptr [mt1],0
la:
       call MakeTunel1
lla:
;       add bh,byte ptr [counter]
       mov bx,word ptr es:[2*ebp]
       add bh,byte ptr [mt1]
    ;   add bh,byte ptr [mt2]
    ;   add bl,byte ptr [mt2]
    ;   add byte ptr [mt2],-4
       call MakeTunel2
       cmp bp,64000
       jnz lla
       add byte ptr [mt1],-4
       call MakeTunel1
       call KScan
       jnz lla

; plasma standard
       mov [counter],800
; sinus 128
k:
       call ShowPlasma
       call Kscan
       jnz k
; tunel non-standard
       mov [counter],800
       mov byte ptr [mt1],0
n:
       call MakeTunel1
nn:
;       add bh,byte ptr [counter]
       mov bx,word ptr es:[2*ebp]
       add bh,byte ptr [mt1]
       add bh,byte ptr [mt2]
       add bl,byte ptr [mt2]
       sub byte ptr [mt2],4
       call MakeTunel2
       cmp bp,64000
       jnz nn
       add byte ptr [mt1],4
       call MakeTunel1
       call KScan
       jnz nn
; landscape ----------------------
;-----------------------------------
lands:
       mov [counter],460
       mov ebx,[plasmaw]
lstart:
       call MakeLand
      inc byte ptr [zo+1]
      call Kscan
      jnz lstart
       mov [counter],400
       mov ebx,[plasmaw]
lstart2:
       call MakeLand
      inc byte ptr [zo+1]
      dec byte ptr [zx]
      call Kscan
      jnz lstart2
       mov [counter],400
       mov ebx,[plasmaw]
lstart3:
       call MakeLand
      dec byte ptr [zo+1]
      call Kscan
      jnz lstart3

;-------- koniec landscape'u
; plasma #1
       mov [counter],700
       mov ax,48 ;100 ;64 ;48
       call GenSinus
kk:
       call ShowPlasma
       call Kscan
       jnz kk

;-------- BYE BUMP
bbumpj:
       call ClrScr
       mov [counter],800
       call CreateBumpMap
       mov al,16
       mov si,offset ByeBump
       call AddTitle
       call Go01
       mov [counter],600
BumpBLoop:
       call Wsp1
       push esi
       push cx
       add [counter],40
       call Wsp1
       sub [counter],40
       pop cx
       pop esi
       call MakeBump
       jnz BumpBLoop

; tu wy


EscEnd:
       mov ax,3
       int 10h
       mov dx,word ptr ds:[OldVect]
       mov ax,word ptr ds:[OldVect+2]
       push ds
       mov ds,ax
       mov ax,2508h
       int 21h
       mov al,36h
       out 40h,al
       mov al,255
       out 40h,al
       out 40h,al
       pop ds
       mov dx,offset Blad03
KoniecX:
       mov ah,9
       int 21h
Koniec:
       mov ah,4ch
       int 21h          ; end
;----------------------------------------------------------------------------
Go01:
       mov ebx,dS:[OrygBumpMap]
       mov edi,ds:[FixedBumpMap]
;       call FixBumpMap
;       call CreatePhongLookUp
FixBumpMap:
                                  ; in : ES:EBX - original bumpmap addy
                                  ;      ES:EDI - destination
        ;push edi
        mov cx,320*200
FBMloop:
        xor eax,eax
        xor edx,edx
        mov ax,word ptr es:[ebx+640]
        sub ax,word ptr es:[ebx-640]
 ;       sal ax,1
        add ah,1
        shl eax,11         ; linia to 2*1024
        mov dx,word ptr es:[ebx+2]
        sub dx,word ptr es:[ebx-2]
;         sal dx,1
        add dh,1
        shl edx,1         ; ale wordow
        add eax,edx
        mov dword ptr es:[edi],eax
        add edi,4
        add ebx,2
        dec cx
        jnz FBMloop
; - - -
CreatePhongLookup:
        mov edi,[phonglookup]
        push edi
; wyczyscic tablice !!!!
        mov ecx,1024*1024
        mov ax,word ptr [paleta1]
        call ClrScrloop
        pop edi
        xor eax,eax               ; Y = 0
        fild ds:[fpuw255]
        fild ds:[fpuw128]
         fld1
PLLoopY: xor edx,edx              ; X=0
PLLoopX: mov ds:[fpu1],ax
        fild ds:[fpu1]
        fdiv st(0),st(2)       ; x/128
        fsub st(0),st(1)       ;x/128-1
        fmul st(0),st(0)        ;(x/128-1)^2
        mov ds:[fpu1],dx
        fild ds:[fpu1]
        fdiv st(0),st(3)       ; y/128
        fsub st(0),st(2)       ;y/128-1
        fmul st(0),st(0)        ;(y/128-1)^2
        faddp st(1),st(0)       ;(x/128-1)^2+(y/128-1)^2
        fsub st(0),st(1)        ;1-(x/128-1)^2-(y/128-1)^2 i to jest r
        fmul st(0),st(3)        ; r*255
        fist ds:[fpu1]
        test ds:[fpu1],65536/2       ; bit znaku=1 to r<0
        jnz PLOK
        fucomp
        xor bx,bx                ; (x,y) poza okregiem, kolor=0
        jz PLPoza
PLOK:   fmul st(0),st(0)        ; r^2 aby byly plynniejsze przejscia
        fdiv st(0),st(3)
        fistp ds:[fpu1]
        mov bx,ds:[fpu1]             ; i to jest numer koloru
PLPoza: add bx,bx
        mov bp,word ptr ds:[bx+offset paleta1] ; a to jest kolor
        mov ebx,256+128 ;+64
        add bx,ax
        shl ebx,10                   ; 1 linia to 2048 bajtow
        add ebx,edx
        add ebx,256+128 ;+64
        shl ebx,1
        mov word ptr es:[edi+ebx],bp
        xor ebx,1024*1024*2-2
        mov word ptr es:[edi+ebx],bp
        xor ebx,2048-2
        mov word ptr es:[edi+ebx],bp
        xor ebx,1024*1024*2-2
        mov word ptr es:[edi+ebx],bp
;        shr cl,1                ; !!!!!!!!!
        inc dx                  ; zwieksz X
        cmp dx,128 ;64
        jnz PLLoopX             ; jesli x<128 to powtorz
        inc ax                  ; zwieksz Y
        cmp ax,128 ;64
        jnz PLLoopY             ; jesli y<128 to powtorz
        fninit
        ret
;------------------------------
Wsp1:
       fild [counter]
       fidiv [fpuw10]
       fsin
       fild [counter]
       fidiv [fpuw24]
       fcos
       fimul [fpuw100]
       fiadd [fpuw160]
       fistp [fpu1]
       mov ax,[fpu1]
       xor ebp,ebp
       fimul fpuw70
       fiadd [fpuw100]
       fistp [fpu1]
       mov bp,[fpu1]
       mov esi,ebp
       mov cx,ax
       ret
;----------------------------------------------------------------------------
; ebp - y1, ax - x1, esi - y2, cx - x2
MakeBump:
       mov edi,dword ptr ds:[bufor+28h]
       mov di,640
       mov ebx,[fixedbumpmap]
       mov bx,1280
       add bp,256
       shl ebp,10
       add bp,ax
       add bp,256
       shl ebp,1
       add ebp,[phonglookup]
       add si,256
       shl esi,10
       add si,cx
       add si,256
       shl esi,1
       add esi,[phonglookup]
       mov ax,198
bumpLoopy:
       push ax
       mov ax,320
bumpLoopx:
       mov edx,dword ptr es:[ebx]           ; wez delty z bumpmapy
       mov cx,word ptr es:[ebp+edx]         ; pobierz kolor
       add cx,word ptr es:[esi+edx]
       mov word ptr es:[edi],cx             ; wstaw kolor na ekran
       add ebx,4
       sub ebp,2
       sub esi,2
       add edi,2
       dec ax
       jnz bumpLoopx
       sub ebp,2048-640
       sub esi,2048-640
       pop ax
       dec ax
       jnz bumpLoopy
;       ret
;-------------------------
Kscan: pusha
       in al,60h
       cmp al,1
       jz Kscan2
VSync: mov dx,3dah
V1:    in al,dx
       test al,8
       jnz V1
V2:    in al,dx
       test al,8
       jz V2
       popa
       test [counter],65535
       ret
Kscan2:
       mov ah,8 ;
       int 21h  ;
;       popa     ;
       jmp EscEnd

;----------------------------------------------------------------------------
;-------------------------
CreateBumpMap:            ; od 1Mb+128kB przez 128 kB oryginalna bumpmapa
        mov ebx,[orygbumpmap]
        xor dx,dx         ; y
CBMloopX:
        xor ax,ax         ; x
CBMloopY:
        mov [fpu1],ax
;        add fpu1,ax               ; !
        fld1
        fild [fpuw2]
        call CBMproc
        fsin
        fimul [fpuw3]
        fadd st(0),st(1)
        fidiv fpuw2
        fsin
        fmulp st(3)
        mov fpu1,dx
;        add fpu1,dx               ; !
        call CBMproc
        fcos
        fadd st(0),st(2)
        fimul fpuw2
        fadd st(0),st(1)
        fidiv fpuw5
        fcos             ;
;        fimul fpuw2     ;
        faddp st(4)
        fidiv fpuw7
        fsin             ;
        fmulp st(2)
        fidiv fpuw3
        fcos
        fmulp st(1)
        faddp st(1)
;        fimul fpuw10
        fimul fpuw24
        fiadd fpuw100
        fistp word ptr es:[ebx]
        inc ebx
        inc ebx
        inc ax
        inc ax
        cmp ax,640
        jnz CBMloopY
        inc dx
        inc dx
        cmp dx,400
        jnz CBMloopX
        ret
;-------------------------------
AddTitle:  ; al - ilosc elementow, si - tablica z elementami
        mov cx,128
        xor edi,edi
        mov dx,word ptr ds:[si+2]
        mov di,word ptr ds:[si]
        add edi,[orygbumpmap]
ghj3:
        xor ebx,ebx
        mov bl,dh
        shl bx,1
        push edi
        push dx
        mov ebp,edi
ghj1:
        cmp word ptr es:[edi],cx
        jae skip1
        mov word ptr es:[edi],cx
skip1:  cmp word ptr es:[ebx+edi],cx
        jae skip2
        mov word ptr es:[ebx+edi],cx
skip2:  add edi,640
        dec dl
        cmp dl,0
        jge ghj1
ghj2:   cmp word ptr es:[edi],cx
        jae skip3
        mov word ptr es:[edi],cx
skip3:  cmp word ptr es:[ebp],cx
        jae skip4
        mov word ptr es:[ebp],cx
skip4:  add edi,2
        add ebp,2
        dec dh
        cmp dh,0
        jge ghj2
        cmp cx,256
        jae skip5
        add cx,32
skip5:
        pop dx
        pop edi
        or dl,dl
        jz skip6
        or dh,dh
        jz skip6
        sub dx,0202h
        add edi,642
        jmp ghj3
skip6:  add si,4
        dec al
        jnz AddTitle
        ret
ImpBump dw 46*640+46*2
        db 108,28
        dw 46*640+81*2
        db 28,108
        dw 66*640+81*2
        db 88,28
        dw 66*640+121*2
        db 28,28
        dw 66*640+161*2
        db 88,28
        dw 46*640+201*2
        db 108,28
        dw 46*640+221*2
        db 28,28
        dw 86*640+221*2
        db 28,28
        dw 46*640+241*2
        db 68,28
ByeBump dw 20*640+30*2
        db 100,20
        dw 20*640+50*2
        db 20,30
        dw 40*640+60*2
        db 20,20
        dw 60*640+50*2
        db 20,40
        dw  80*640+70*2
        db 20,20
        dw 100*640+50*2
        db 20,40
        ;-
        dw 20*640+110*2
        db 40,20
        dw 20*640+150*2
        db 40,20
        dw 60*640+110*2
        db 20,60
        dw  80*640+130*2
        db 40,20
        ;-
        dw 20*640+190*2
        db 100,20
        dw 20*640+210*2
        db 20,40
        dw 60*640+210*2
        db 20,20
        dw 100*640+210*2
        db 20,40
        ;-
        dw 20*640+270*2
        db 60,20
        dw 100*640+270*2
        db 20,20
CBMproc:
        fldpi
        fimul fpu1
        fidiv fpuw5
        fild fpuw10
        fdivr st(0),st(1)
        ret
;-----------------------------------------
;---------------------------------------
GenSinus:
; tablica sinusa     ax- 1/2 okresu
        mov [fpu2],ax
        xor bx,bx
GenSinLoop:
        mov [fpu1],bx
        fild [fpu1]
        fldpi
        fmulp st(1)
        ;fidiv [fpuw128]
        fidiv [fpu2]
        fsin
        fimul [fpuw24]
        fistp [fpu1]
        mov al,byte ptr ds:[offset fpu1]
        mov byte ptr ds:[bx+sinustabl],al
        inc bl
        jnz GenSinLoop
        ret
;------------------------
rozjasnienie    equ 15
rozproszenie    equ 100
natezenie       dw 10
red             dw 40 ;dw 80
green           dw 20 ;dw 60
blue            dw 30 ;dw 40

random: mov bp,word ptr ds:[sd]
        add bp,8365h
        rol bp,5
        xor bp,6324h
        mov word ptr ds:[sd],bp
        and bp,[fpu1]
        shl bp,1
        sub bp,[fpu1]
        sal bp,1
        ret
GenRek: mov word ptr es:[edi],ax
        inc edi
        inc edi
        mov word ptr es:[edi],bx
        inc edi
        inc edi
        mov dx,[fpu1]
        mov word ptr es:[edi],dx
        inc edi
        inc edi
        ret
sd dw 62b3h
PG01:
        ;shl bp,1
        mov bx,ax
        add bp,word ptr es:[2*ebx]
        mov bl,cl
        add bp,word ptr es:[2*ebx]
        sar bp,1
    and bp,255
        mov bl,dl
        mov word ptr es:[2*ebx],bp
        ret
PG02:
        mov bx,cx
        add bp,word ptr es:[2*ebx]
        mov bh,ah
        add bp,word ptr es:[2*ebx]
        sar bp,1
  ; and bp,255
        mov bh,dh
        mov word ptr es:[2*ebx],bp
        ret

NextRek:
        mov ax,word ptr es:[esi]
        inc esi
        inc esi
        mov cx,word ptr es:[esi]
        inc esi
        inc esi
        mov dx,word ptr es:[esi]
        mov [fpu1],dx
        inc esi
        inc esi
        jmp RekBegin

; - - -

;---------------------------------
MakePlasma:
        xor ch,ch                  ;y
        mov edi,[plasmatabl]
        mov ebp,[plasmatabl2]
MPLY:
        xor bx,bx
        mov dh,ch
        mov bl,ah
        add bl,ch
        add dh,byte ptr ds:[bx+sinustabl]
        mov bl,ah
        add bl,dh
 ;      add bl,al ;
        add bl,64
        add dh,byte ptr ds:[bx+sinustabl]
        xor cl,cl
MPLX:   ;xor bx,bx
        mov bl,ah
        add bl,cl
        add bl,ch
        mov bl,byte ptr ds:[bx+sinustabl]
        mov al,cl
        add al,byte ptr ds:[bx+sinustabl]
        mov dl,al
        mov bl,ah
        add bl,dl
        add bl,128
        add dl,byte ptr ds:[bx+sinustabl]
        mov di,dx
        mov di,word ptr es:[2*edi]
        mov bp,cx
        mov word ptr es:[2*ebp],di
        inc cl
        jnz MPLX
        inc ch
        jnz MPLY
        ret
;----------------------------
;------------------------
ShowPlasma:
       mov ah,byte ptr ds:[counter]
;       shl ah,1
;       mov ah,al
       call MakePlasma
       mov edi,dword ptr ds:[bufor+28h]
       mov ebx,ds:[plasmatabl2]
;       shr ebx,1
       xor ch,ch
loophhy:
       mov dx,320
       xor cl,cl
loophhx:
       mov bx,cx
;         mov ax,word ptr es:[edi]
;         shr ax,1
;         and ax,0011110111101111b
;         add ax,word ptr es:[2*ebx]
       mov ax,word ptr es:[2*ebx]
       mov word ptr es:[edi],ax
       add edi,2
       inc cl
       dec dx
       jnz loophhx
;       add edi,(320-256)*2
       inc ch
       cmp ch,200
       jnz loophhy
       ret
;-----------------------
MakeTunel1:
       mov ah,byte ptr [counter]
       call MakePlasma
       mov ebp,[tuneltabl]
       mov ebx,[plasmatabl2]
       mov edi,dword ptr [bufor+28h]
       mov al,byte ptr [mt1]
       mov byte ptr [mt2],al
       ret
;--------------------------
MakeTunel2:
       mov ax,word ptr es:[2*ebx]
       mov word ptr es:[edi],ax
       inc bp
       inc edi
       inc edi
       ret
;-----------------------------
ClrScr:
       mov edi,dword ptr [bufor+28h]
ClrScr2:
       mov ecx,64000
       xor ax,ax
clrscrloop:
       mov word ptr es:[edi],ax
       inc edi
       inc edi
       dec ecx
       jnz clrscrloop
       ret
;----------------------------
writetextloop:
       push edi
       push cx
       shl ecx,16
       pop cx
       mov si,[fonty]
       shl bp,3
       mov dh,8
wcloopy:
       mov al,byte ptr fs:[bp+si]
       mov dl,8
wcloopx:
       shl al,1
       jnc nocarry
       mov dword ptr es:[edi],ecx
       mov dword ptr es:[edi+4],ecx
       mov dword ptr es:[edi+640],ecx
       mov dword ptr es:[edi+644],ecx
nocarry:
       add di,8
       dec dl
       jnz wcloopx
       add edi,4*640-64
       inc bp
       dec dh
       jnz wcloopy
       pop edi
       inc bx
       add di,64
Writetext:
       movzx bp,byte ptr [bx]
       or bp,bp
       jnz writetextloop
       ret
;----------------------------
SlideScr:
       mov edi,dword ptr [bufor+28h]
       mov ebx,[slidescreen]
       cwde
       add bx,ax
       add bx,ax
       test ah,80h
       jz ssoki
       neg eax
       neg bx
       xchg di,bx
ssoki:
       add edi,640*80
       add ebx,640*80
       mov dh,40/4
ss03:
       mov dl,4
ss02:
       mov cx,ax
ss01:
       mov si,word ptr es:[ebx]
       or si,si
       jnz NZmniejsz
       mov si,word ptr es:[edi]
       or si,si
       jz NZmniejsz
       sub si,0000010000100001b
NZmniejsz:
       mov word ptr es:[edi],si
       inc cx
       add ebx,2
       add edi,2
       cmp cx,320
       jb ss01
       add ebx,eax
       add ebx,eax
       add edi,eax
       add edi,eax
       dec dl
       jnz ss02
       xchg bx,di
       dec dh
       jnz ss03
       ret
;---------------------
BlurPlasma:
        xor bx,bx
cqwe:   mov cx,word ptr es:[2*ebx]
        shl cx,2
        inc bl
        add cx,word ptr es:[2*ebx]
        sub bl,2
        add cx,word ptr eS:[2*ebx]
        inc bl
        inc bh
        add cx,word ptr es:[2*ebx]
        sub bh,2
        add cx,word ptr es:[2*ebx]
        inc bh
        shr cx,3
        mov word ptr es:[2*ebx],cx
        inc bx
        jnz cqwe
        dec ax
        jnz BlurPlasma
        ret
;-----------------
MakeLand:
       mov edi,[ekran2]
       mov esi,dword ptr [bufor+28h]
       ;shr si,1
       mov cx,32000
dupscreen:
       mov eax,dword ptr es:[2*edi]
       mov dword ptr es:[esi],eax
       add di,2
       add esi,4
       dec cx
       jnz dupscreen
       xor di,di
       push edi
       shl edi,1
       mov ax,0110001100011000b
       mov ecx,64000
;       call clrscr2
       call clrscrloop
       pop edi
       mov byte ptr [z3+1],9
lnloop:
       finit
       fild [fpuw100]
       fild [fpuw320]
       mov ax,word ptr [z3]
       mov dx,ax
       shl dx,1
       mov word ptr[xx],dx
       mov word ptr [xx+2],0
       fild [xx]
       fidiv [fpuw160]
       fistp [fpu1]
       fild [dist]
       fld st(0)
       mov byte ptr [fpu2],ah
       mov byte ptr [fpu2+1],0
       fiadd [fpu2]
       fdivp st(1),st(0)
       mov bh,byte ptr [zo+1]
       mov bl,byte ptr [zx]
       mov bx,word ptr es:[2*ebx]
       sub bx,130
       movzx cx,ah
       shr cx,1
       add cx,bx
       mov si,319
       mov bh,ah
       add bh,byte ptr [zo+1]
lclloop:
      mov [podst],cx
      mov bl,byte ptr [zx]
      sub bl,dh
      mov bp,word ptr es:[2*ebx]
      sub [podst],bp
      fld st(0)
      fimul [podst]
      frndint
      fist [fpu2]
      cmp [fpu2],-100
      jg nblg
blg:
      fistp [fpu2]
      jmp pol
nblg:
      fsub st(0),st(3)
      fchs
      fmul st(0),st(2)
      fistp [xx]
      cmp ah,85
      jb noszary
      mov bp,0111001110011100b
      mov di,si
      add di,word ptr [xx]
      jmp llloop
noszary:
      mov bp,word ptr es:[2*ebx+128*1024]
      xchg ah,al
      mov di,ax
      shr di,2
      sub bp,di
      jnb rrr
      xor bp,bp
rrr:
      xchg ah,al
      mov di,si
      add di,word ptr [xx]
      shl bp,1
      mov bp,word ptr [paleta2+bp]
llloop:
      cmp word ptr es:[2*edi],0110001100011000b
      jnz pol
      mov word ptr es:[2*edi],bp
      add di,320
      cmp di,64000
      jb llloop
pol:
      sub dx,[fpu1]
      dec si
      jns lclloop
      inc byte ptr [z3+1]
      cmp byte ptr [z3+1],95
      jnz lnloop
      push ebx
      xor di,di                ;ekran;
      xor bp,bp                ;skytabl
      mov ebx,[plasmatabl]     ;plasmatabl
zzxxx:
      xor dl,dl
      mov ax,word ptr [bp+skytabl]
      mov dh,byte ptr [bp+skytabl+2]
      mov bh,byte ptr [bp+skytabl+3]
      add bh,byte ptr [zo+1]
      mov cx,320
bbnnn: mov bl,byte ptr [zx]
      cmp word ptr es:[2*edi],0110001100011000b
      jnz JestLand
      add bl,dh
      mov si,word ptr es:[2*ebx]
      xor si,7fffh
      mov word ptr es:[2*edi],si
JestLand:
      sub dx,ax
      add di,1
      dec cx
      jnz bbnnn
      add bp,4
      cmp bp,400
      jnz zzxxx
      pop ebx
      ret

;----------------------------------------------------------------------------

;--
Blad00  db 'No XMS driver !$'
Blad01  db 'V86 mode !$'
Blad02  db 'Graphic error !$'
Blad03  db 'Thanx for watching...',13,10,'omen/Dimension$'
tekst1  db 'OMEN/Dmn',0
tekst2  db 'presents',0
fpu4    dw 512*2 ; *3
fpuw2   dw 2
fpuw3   dw 3
fpuw5   dw 5
fpuw7   dw 7
fpuw10  dw 10
fpuw20  dw 20
fpuw24  dw 24
fpuw70  dw 70
fpuw100 dw 100
fpuw128 dw 128
fpuw160 dw 160
fpuw255 dw 255
fpuw256 dw 256
fpuw320  dw 320
z3    db 0,?
zo    db 0,0
dist  dw 50
wys   dw 200
zx db 100

orygbumpmap  dd 1024*1024+2*65536    ; - zajmuje 128kB
fixedbumpmap dd 1024*1024+4*65536    ; - zajmuje 128kB ( przesuniecia )
phonglookup  dd 1024*1024+512*1024   ; - phong look up - 2 Mb !!!! 1,5-3,5
plasmatabl   dd (3*1024*1024+512*1024)/2 ; 128kB (256*256*word(kolor))
;plasmaFIFO   dd 3*1024*1024+512*1024+128*1024 ; jakies 64kB starczy
plasmatabl2  dd (4*1024*1024)/2         ; 128 kB
tuneltabl    dd (4*1024*1024+128*1024)/2 ; 128 kB
slidescreen  dd 4*1024*1024+512*1024
plasmaw      dd (5*1024*1024)/2
plasmac      dd (5*1024*1024+128*1024)/2
ekran2       dd (5*1024*1024+512*1024)/2
;------------------------------
NewInt08: test word ptr cs:[counter],65535
          jz NewInt8_02
          dec word ptr cs:[counter]
NewInt8_02:
          dec cs:[Count08]
          test cs:[Count08],3
          jz OldInt
          push ax
          mov al,20h
          out 20h,al
          pop ax
          iret
OldInt:
         db 0eah
; com file ends here
;---------------------- Undefined data -----------------------------------
OldVect dd ?
counter dw ?
Count08 db ?
fpu1    dw ?
fpu2    dw ?
mt1     db ?
mt2     db ?
fonty   dw ?
podst dw ?
xx     dd ?
bufor   db 256 dup (?)
paleta1  dw 256 dup (?)
paleta2  dw 256 dup (?)
sinustabl db 256 dup (?)
skytabl   db 120*4 dup (?)
end start
