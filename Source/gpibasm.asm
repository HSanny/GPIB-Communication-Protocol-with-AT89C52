$MOD52  


gpdata   equ   p0  ;---------------------------------------
outdata  equ   p1  ;

renpin   equ   p2.0;
ifc      equ   p2.1;
ndac     equ   p2.2;
nrfd     equ   p2.3;
dav      equ   p2.4;
eoi      equ   p2.5;
atn      equ   p2.6;            Portlar tan�mlan�r
srq      equ   p2.7;

te161    equ    p3.7;
dc161    equ    p3.6;
dr160    equ    p3.5;
e160     equ    p3.4;
FA       equ    p3.3; ac dc off butonlar� i�in
FB       equ    p3.2; ac dc off butonlar� i�in
otoman   equ    p3.1; otomatik manuel anahtar�
gcdata   equ    p3.0; ilk �al�l��ta 74578 i se�mek i�in kullan�l�r
		    ;--------------------------------------



commbuf  equ   60h ; ro dizisini 60h adresinden itibaren sakla


ismyadd   equ  8     ; e�er adres do�ruysa bu bit 1 olur
acmidcmi  equ  9     ; bu bit TOAC! komutu do�rulan�rsa 1 olur TODC! komutu do�rulan�rsa 0 olur
		     ;------------------------------------
acbit     equ  14    	
dcbit     equ  15
offbit    equ  16    ; ac dc off d�ng�lerine bir sefer girmek i�in kullan�l�r 
otokont   equ  17    
otokont1  equ  18

		     ;----------------------------------
unl      equ   3fh ;
myadress equ   42  ; 10 OR 32





org 0000h     ;---------------------------------

jmp startx    ; 0h ve 200h aras�ndaki adresleri bo� b�rak program� 200h adresinden sonra kaydet bu araya r0 dizisi kaydedilicek

org 0200h     ;--------------------------------
startx:
lcall setlistener     ;
mov r0, #commbuf      ; r0'� 60h adresine konumland�r


clr otokont
clr offbit ;-------------------
clr dcbit  ; bu bitler g�venlik i�in s�f�rlan�r program�n hi� bi alt programa girmedi�in g�sterir
clr acbit  ;-------------------
lcall bekle1
setb outdata
lcall manoff   
clr gcdata       ; adresi okumak i�in birinci 74578 i �al��t�r
lcall bekle1
mov a, gpdata    ; datay� al
mov myadress,a  ;
setb gcdata      ; datalar� okumak i�in ikinci 74578 i �al��t�r




roletak1:
clr offbit ;
clr dcbit  ;
clr acbit  ;
setb otokont

roletak:    
jnb p1.3,main
lcall bekle
lcall bekle
clr p1.5
clr p1.6        ; role tak prosed�r�n� �al��t�r e�er role tak�l�rsa roletak1 e git roleleri off yap ana programa d�n
clr p1.7
lcall bekle
lcall bekle
setb p1.5
setb p1.6
setb p1.7
lcall bekle
lcall bekle
jmp roletak




main:
jb p1.3,roletak1
jb otoman, notmanuel     ; e�er manuelde de�ilse bu manuel prosed�r� ge�


setb otokont
jb FB,devam1
jb FA,devam     
lcall mandc
jmp notmanuel1
devam1:
lcall manoff
jmp notmanuel1 
devam:
lcall manac
jmp notmanuel1


notmanuel:
jnb otokont,atlanotmanuel
clr otokont               ; manuelden remote ge�erken bir kele�ine roleleri off yap bilgisayardan komut beklemeye ba�la
lcall manoff
atlanotmanuel:


jnb otoman, notmanuel1 ;----------------------------------
clr dcbit
clr acbit              ; bu b�lgeye sadece otomatik modda girmeli
clr offbit
notmanuel1:            ;----------------------------------


jb dav, main          ; e�er data yoldaysa oku
clr nrfd              ; not ready for data �uan me�gul�m sinyali
jb atn, main1         ; e�er atn 0 ise gelen data adres bilgisidir 1 ise ger�ek data geliyor demektir
lcall itiscommand     ; adresi oku ve do�rula
jmp main;
main1:
lcall itisdata        ;  datay� oku
jmp main;




itisdata:
jnb otoman,dataalindi        ; e�er manueldeyse next1x'e atlay�p adres uymam�� gibi g�ster
jnb ismyadd,dataalindi       ; adres do�ruysa datay� almaya ba�la
mov a, gpdata               ; datay� al
cpl a                       ; gpib ters logic oldu�u i�in gelen datay� ters �evir
mov @r0, a                  ; datay� r0 inci adreste sakla
inc r0                      ; r0'� bir artt�r yani bi sonraki adrese ge�

cjne a, #'!', dataalindi     ; ! geldi�inde ald��� datalar� kar��la�t�rmaya git
lcall komutlar              ;
mov r0,#commbuf             ; tekrar dizinin ba�lang�cana 60h adresinde git
lcall datataken             ; konu�mac�ya data al�nd� bilgisi g�nder
ret;

dataalindi:                  ;
lcall datataken             ; e�er hi� bir adres tutmazsa yinede data al�nd� bilgisi g�ndermeliyiz paralel bi haberle�me oldu�u i�in
ret;                        ;





itiscommand:
mov a, gpdata               ; datay� al
cpl a   		    ; tersle
cjne a,myadress , next1x   ; program�n ba�lang�c�nda okunan adresle ayn�ysa devam et
setb ismyadd                ; adres uyuyosa bu bit'i 1 yap
lcall datataken             ; konu�mac�ya data al�nd� bilgisi g�nder
ret;

next1x:
cjne a, #unl, next2x        ;
clr ismyadd                 ;
lcall datataken             ;
ret;                        ;

next2x:
lcall datataken             ; Adres do�rulanmad�
ret;                        ;




setlistener:		    ;---------------------------------------------
clr dr160                   ;
clr e160                   ;
clr te161                   ;
setb dc161                  ;    
lcall bekle1                ;                                
clr  ndac                   ; data not accepted                  Dinleme �zelli�i i�in gerekli ayarlamalar� yap
setb nrfd                   ; ready for data
setb srq                    ; not service request
setb eoi                    ; EOI
setb atn                    ; ATN
setb dav                    ; DAV
clr ismyadd                 ;
ret                         ;---------------------------------------------

datataken:
setb ndac                   ; data al�nd�
jnb dav, datataken          ; data al�nd� onay� i�in bekle
clr ndac                    ; data al�namad�
setb nrfd                   ; yeni data almaya haz�r
ret;







komutlar:

mov r0, #commbuf         ; dizinin ba��na d�n        
mov a, @r0               ; ilk karakteri al
cjne a, #'T', NotT       ; �lk karakter T mi         

inc r0                   ; r0 � bir artt�rarak 2. karaktere ge�
mov a, @r0               ; ikinci karakteri al
cjne a, #'O', bitir1  ; ikinci karakter O mu

inc r0                   ;
mov a, @r0               ;
cjne a, #'F', notFA      ; ���nc� karakter F mi
jmp off

notFA:
cjne a, #'A', notAD      ; F de�ilse A m�
setb acmidcmi            ;
jmp atlaal               ;

notAD:
cjne a, #'D', bitir1  ; A da de�ilse D mi
clr acmidcmi             ;
atlaal:                  

inc r0                   ;
mov a, @r0               ;
cjne a, #'C', bitir1  ; son karakter C yse whicbite git ve acmidcmi e bakarak acmi dcmi kararver
jmp karar;


NotT:
cjne a, #'D', NotD ; �lk karakter D mi  

inc r0;
mov a, @r0;
cjne a, #'A', bitir1 ; ikinci karakter A mu

inc r0;
mov a, @r0;
cjne a, #'T', bitir1 ; ���nc� karakter T mu

inc r0;
mov a, @r0;
cjne a, #'A', bitir1 ; d�rd�nc� karakter A mu

inc r0;
mov a, @r0;
mov outdata,a
clr p1.5
setb p1.6
clr p1.7
bitir1:
ret


NotD:
cjne a, #'R', bitir1 ; �lk karakter R mi  

inc r0;
mov a, @r0;
cjne a, #'K', bitir1 ; ikinci karakter K mu

inc r0;
mov a, @r0;
cjne a, #'N', bitir1 ; ikinci karakter N mu

inc r0;
mov a, @r0;
cjne a, #'T', bitir1 ; ikinci karakter T mu
                   ;----------------------------------
clr p1.5
clr p1.6
clr p1.7


clr p1.0
lcall bekle
lcall bekle
setb p1.0

clr p1.1
lcall bekle
lcall bekle
setb p1.1

clr p1.0
clr p1.1
lcall bekle
lcall bekle
setb p1.0
setb p1.1

clr p1.2
lcall bekle
lcall bekle
setb p1.2

clr p1.0
clr p1.2
lcall bekle
lcall bekle
setb p1.0
setb p1.2

clr p1.1
clr p1.2
lcall bekle
lcall bekle
setb p1.2
setb p1.1

clr p1.0
clr p1.1
clr p1.2
lcall bekle
lcall bekle
setb p1.2
setb p1.1
setb p1.0




clr offbit ;-------------------
clr dcbit  ; bu bitler g�venlik i�in s�f�rlan�r program�n hi� bi alt programa girmedi�in g�sterir
clr acbit  ;-------------------
ret                ;----------------------------------



off:
inc r0;
mov a, @r0;
cjne a, #'F', bitir ; e�er ���nc� karakter F ise d�rd�nc� karakterde F'mi kontrol et


manoff:                    ;----------------------------------
jb offbit,bitir       ;off prosed�r�n�n i�ine arka arkaya girmeyi �nler offbit bir ise ba�ka bir prosed�r �a�r�lana kadar buraa girmez
setb p1.5
setb p1.6
clr p1.7

clr p1.0
clr p1.1
lcall bekle
setb p1.0
setb p1.1

clr p1.0
lcall bekle
setb p1.0

clr acbit
setb offbit
clr dcbit

ret                        ;----------------------------------



karar:
jb acmidcmi,manac



mandc:                    ;----------------------------------
jb dcbit,bitir
setb p1.5
clr p1.6
setb p1.7

clr p1.2   	;
lcall bekle 	;
setb p1.2	;
clr p1.1	;
clr p1.2	;
lcall bekle	;		dc ayarlar�
setb p1.1	;
setb p1.2	;
clr p1.0	;
lcall bekle	;
setb p1.0	;

clr acbit
clr offbit
setb dcbit
ret                       ;----------------------------------



manac:                    ;----------------------------------
jb acbit,bitir
clr p1.5
setb p1.6
setb p1.7

clr p1.1
lcall bekle
setb p1.1
clr p1.0
clr p1.2
lcall bekle
setb p1.0
setb p1.2
clr p1.0
clr p1.1
lcall bekle
setb p1.0
setb p1.1

setb acbit
clr offbit
clr dcbit
bitir:
ret                      ;----------------------------------




bekle1:                         ;
mov b,r7;
mov r7,#0ffh                    ;
bekle2:                         ;
djnz r7,bekle2                  ;
mov r7,b;
ret                             ;

bekle:
mov r6,#0ffh;
mov r5,#0ffh;
midd1:
djnz r5,midd1;
djnz r6,midd1;
ret;



end                                             
