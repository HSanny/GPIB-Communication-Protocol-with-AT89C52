$MOD52  


gpdata   equ   p0  ;---------------------------------------
outdata  equ   p1  ;

renpin   equ   p2.0;
ifc      equ   p2.1;
ndac     equ   p2.2;
nrfd     equ   p2.3;
dav      equ   p2.4;
eoi      equ   p2.5;
atn      equ   p2.6;            Portlar tanýmlanýr
srq      equ   p2.7;

te161    equ    p3.7;
dc161    equ    p3.6;
dr160    equ    p3.5;
e160     equ    p3.4;
FA       equ    p3.3; ac dc off butonlarý için
FB       equ    p3.2; ac dc off butonlarý için
otoman   equ    p3.1; otomatik manuel anahtarý
gcdata   equ    p3.0; ilk çalýlýþta 74578 i seçmek için kullanýlýr
		    ;--------------------------------------



commbuf  equ   60h ; ro dizisini 60h adresinden itibaren sakla


ismyadd   equ  8     ; eðer adres doðruysa bu bit 1 olur
acmidcmi  equ  9     ; bu bit TOAC! komutu doðrulanýrsa 1 olur TODC! komutu doðrulanýrsa 0 olur
		     ;------------------------------------
acbit     equ  14    	
dcbit     equ  15
offbit    equ  16    ; ac dc off döngülerine bir sefer girmek için kullanýlýr 
otokont   equ  17    
otokont1  equ  18

		     ;----------------------------------
unl      equ   3fh ;
myadress equ   42  ; 10 OR 32





org 0000h     ;---------------------------------

jmp startx    ; 0h ve 200h arasýndaki adresleri boþ býrak programý 200h adresinden sonra kaydet bu araya r0 dizisi kaydedilicek

org 0200h     ;--------------------------------
startx:
lcall setlistener     ;
mov r0, #commbuf      ; r0'ý 60h adresine konumlandýr


clr otokont
clr offbit ;-------------------
clr dcbit  ; bu bitler güvenlik için sýfýrlanýr programýn hiç bi alt programa girmediðin gösterir
clr acbit  ;-------------------
lcall bekle1
setb outdata
lcall manoff   
clr gcdata       ; adresi okumak için birinci 74578 i çalýþtýr
lcall bekle1
mov a, gpdata    ; datayý al
mov myadress,a  ;
setb gcdata      ; datalarý okumak için ikinci 74578 i çalýþtýr




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
clr p1.6        ; role tak prosedürünü çalýþtýr eðer role takýlýrsa roletak1 e git roleleri off yap ana programa dön
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
jb otoman, notmanuel     ; eðer manuelde deðilse bu manuel prosedürü geç


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
clr otokont               ; manuelden remote geçerken bir keleðine roleleri off yap bilgisayardan komut beklemeye baþla
lcall manoff
atlanotmanuel:


jnb otoman, notmanuel1 ;----------------------------------
clr dcbit
clr acbit              ; bu bölgeye sadece otomatik modda girmeli
clr offbit
notmanuel1:            ;----------------------------------


jb dav, main          ; eðer data yoldaysa oku
clr nrfd              ; not ready for data þuan meþgulüm sinyali
jb atn, main1         ; eðer atn 0 ise gelen data adres bilgisidir 1 ise gerçek data geliyor demektir
lcall itiscommand     ; adresi oku ve doðrula
jmp main;
main1:
lcall itisdata        ;  datayý oku
jmp main;




itisdata:
jnb otoman,dataalindi        ; eðer manueldeyse next1x'e atlayýp adres uymamýþ gibi göster
jnb ismyadd,dataalindi       ; adres doðruysa datayý almaya baþla
mov a, gpdata               ; datayý al
cpl a                       ; gpib ters logic olduðu için gelen datayý ters çevir
mov @r0, a                  ; datayý r0 inci adreste sakla
inc r0                      ; r0'ý bir arttýr yani bi sonraki adrese geç

cjne a, #'!', dataalindi     ; ! geldiðinde aldýðý datalarý karþýlaþtýrmaya git
lcall komutlar              ;
mov r0,#commbuf             ; tekrar dizinin baþlangýcana 60h adresinde git
lcall datataken             ; konuþmacýya data alýndý bilgisi gönder
ret;

dataalindi:                  ;
lcall datataken             ; eðer hiç bir adres tutmazsa yinede data alýndý bilgisi göndermeliyiz paralel bi haberleþme olduðu için
ret;                        ;





itiscommand:
mov a, gpdata               ; datayý al
cpl a   		    ; tersle
cjne a,myadress , next1x   ; programýn baþlangýcýnda okunan adresle aynýysa devam et
setb ismyadd                ; adres uyuyosa bu bit'i 1 yap
lcall datataken             ; konuþmacýya data alýndý bilgisi gönder
ret;

next1x:
cjne a, #unl, next2x        ;
clr ismyadd                 ;
lcall datataken             ;
ret;                        ;

next2x:
lcall datataken             ; Adres doðrulanmadý
ret;                        ;




setlistener:		    ;---------------------------------------------
clr dr160                   ;
clr e160                   ;
clr te161                   ;
setb dc161                  ;    
lcall bekle1                ;                                
clr  ndac                   ; data not accepted                  Dinleme özelliði için gerekli ayarlamalarý yap
setb nrfd                   ; ready for data
setb srq                    ; not service request
setb eoi                    ; EOI
setb atn                    ; ATN
setb dav                    ; DAV
clr ismyadd                 ;
ret                         ;---------------------------------------------

datataken:
setb ndac                   ; data alýndý
jnb dav, datataken          ; data alýndý onayý için bekle
clr ndac                    ; data alýnamadý
setb nrfd                   ; yeni data almaya hazýr
ret;







komutlar:

mov r0, #commbuf         ; dizinin baþýna dön        
mov a, @r0               ; ilk karakteri al
cjne a, #'T', NotT       ; Ýlk karakter T mi         

inc r0                   ; r0 ý bir arttýrarak 2. karaktere geç
mov a, @r0               ; ikinci karakteri al
cjne a, #'O', bitir1  ; ikinci karakter O mu

inc r0                   ;
mov a, @r0               ;
cjne a, #'F', notFA      ; üçüncü karakter F mi
jmp off

notFA:
cjne a, #'A', notAD      ; F deðilse A mý
setb acmidcmi            ;
jmp atlaal               ;

notAD:
cjne a, #'D', bitir1  ; A da deðilse D mi
clr acmidcmi             ;
atlaal:                  

inc r0                   ;
mov a, @r0               ;
cjne a, #'C', bitir1  ; son karakter C yse whicbite git ve acmidcmi e bakarak acmi dcmi kararver
jmp karar;


NotT:
cjne a, #'D', NotD ; Ýlk karakter D mi  

inc r0;
mov a, @r0;
cjne a, #'A', bitir1 ; ikinci karakter A mu

inc r0;
mov a, @r0;
cjne a, #'T', bitir1 ; üçüncü karakter T mu

inc r0;
mov a, @r0;
cjne a, #'A', bitir1 ; dördüncü karakter A mu

inc r0;
mov a, @r0;
mov outdata,a
clr p1.5
setb p1.6
clr p1.7
bitir1:
ret


NotD:
cjne a, #'R', bitir1 ; Ýlk karakter R mi  

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
clr dcbit  ; bu bitler güvenlik için sýfýrlanýr programýn hiç bi alt programa girmediðin gösterir
clr acbit  ;-------------------
ret                ;----------------------------------



off:
inc r0;
mov a, @r0;
cjne a, #'F', bitir ; eðer üçüncü karakter F ise dördüncü karakterde F'mi kontrol et


manoff:                    ;----------------------------------
jb offbit,bitir       ;off prosedürünün içine arka arkaya girmeyi önler offbit bir ise baþka bir prosedür çaðrýlana kadar buraa girmez
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
lcall bekle	;		dc ayarlarý
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
