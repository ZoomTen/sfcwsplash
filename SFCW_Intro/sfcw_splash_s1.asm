; ===============================================================================================
; SFCW Splash Screen v2.5B (S1 version)
; by Zy BG9K (Zumi, ZoomTen)
;
; Last modified 2014-03-01
; Uploaded to GitHub 2016-08-20
; ===============================================================================================

; -----------------------------------------------------------------------------------------------
; MACROS
; -----------------------------------------------------------------------------------------------
SetVDP	macro	reg,data
	move.w	#((128+reg)*256+data),($C00004)
	endm

show	macro source,loc,width,height
	lea	($FF0000+\source).l,a1
	move.l	#$40000000+((loc&$3FFF)<<16)+((loc&$C000)>>14),d0
	moveq	#width,d1
	moveq	#height,d2
	jsr	ShowVDPGraphics
	endm
	
loadnem	macro	vram,	art
	move.l	#($40000000+((vram&$3FFF)<<16)+((vram&$C000)>>14)),($C00004).l
	lea	(art).l,a0
	jsr	NemDec
	endm
	
loadeni	macro	destination,	offset,	map
	lea	($FF0000+\destination).l,a1
	lea	(map).l,a0
	move.w	#offset,d0
	jsr	EniDec
	endm

; -----------------------------------------------------------------------------------------------
; The real deal. :)
; -----------------------------------------------------------------------------------------------
SFCW_SplashStart:
		move.b	#$E4,($FFFFF00B).w	; Stop all sound
		jsr	ClearPLC		; Clear the PLC
		jsr	Pal_FadeFrom		; Fade out previous screen
; Set up VDP..
		move	#$2700,sr		; Disable interrupts
		SetVDP	0, %00000100		; Select palette setting 1
		SetVDP	2, %00110000		; Set Plane A nametable address
		SetVDP	4, %00000111		; Set Plane B nametable address
		SetVDP	11,%00000011		; Set to line scrolling
		SetVDP	7, %00000000		; Background color = 1st color
		clr.b	($FFFFF64E).w		; Clear water flag
		jsr    ClearScreen
; Clear objects..
		lea	($FFFFD000).w,a1	; Prepare for object clearing
		moveq	#0,d0			; Set to clear object RAM
		move.w	#$7FF,d1		; Clear FFFFD000-FFFFD800
@clearloop:	move.l	d0,(a1)+
		dbf	d1,@clearloop		; No sleep until clear
; Load everything..
		loadnem	$0000, Art_SFCW
		loadeni	$FF0000, 0, Map_SFCW
		show	$FF0000, $C000, $27, $1B
; Clear palette..
		moveq	#0,d0			; Set fill byte to 0 for clearing
		lea	($FFFFFB80).w,a1	; To palette buffer
		moveq	#$10,d1			; Clear 16 entries
@palclear:	move.w	d0,(a1)+
		dbf d1,	@palclear		; Loop until all palette entries clear

                move.w	#$0EEE,($FFFFFB98).w	; Show SFCW URL (Set palette entry #9 to white)

; -----------------------------------------------------------------------------------------------
; SFCW text fade animation
; -----------------------------------------------------------------------------------------------
SFCW_Animation:
		jsr	Pal_FadeTo
		move.b	#$8E,($FFFFF00A).w	; Should be S3K End-of-Act music.
; Fade title text in..
		moveq	#6,d1			; # of frames for fading
@fadeanim:	move.w	#$8,($FFFFF614).w	; Set to delay 8 frames
		add.w	#$0201,($FFFFFB16).w	; Fade palette entry #8
@delayloop:	jsr	SFCW_RunDelay
		tst.w	($FFFFF614).w		; Has delay time run out?
		bne.w	@delayloop		; If not, keep waiting
		dbf d1,	@fadeanim		; Loop 6 more times
; Wait until flash..
                move.w	#$1C,($FFFFF614).w	; Set to delay 28 frames
@fadeend:	jsr	SFCW_RunDelay
		tst.w	($FFFFF614).w
		bne.w	@fadeend
; -----------------------------------------------------------------------------------------------
; SFCW ending loop
; -----------------------------------------------------------------------------------------------
		jsr	Pal_MakeFlash		; Flash the screen
SFCW_LoadPalette:
		lea	(Pal_SFCW).l,a1		; Load palette
		lea	($FFFFFB80).w,a2	; To palette buffer
		moveq	#$10,d0			; Copy 16 entries
@palloop:	move.w	(a1)+,(a2)+
		dbf d0,	@palloop		; Loop until all palette entries copied
		jsr	Pal_ToWhite
		move.b	#$C3,($FFFFF00B).w	; SS ring entry sound
		move.w	#5,($FFFFF634).w	; Enable real palette cycling
		move.w	#0,($FFFFF632).w	; Set cycle index to 0
SFCW_Loop:
		jsr	Pal_MakeWhite		; Flash out
		move.w	#60*4,($FFFFF614).w	; Set to wait 4 seconds
@loop:		jsr	SFCW_PalCycle		; Run palette cycling
		jsr	SFCW_RunDelay
		andi.b	#$F0,($FFFFF605).w	; Is any button pressed?
		bne.w	@next			; If so, go to next screen
		tst.w   ($FFFFF614).w		; Is time run out?
		bne.s	@loop			; If not, loop
@next:		move.b	#$04,($FFFFF600).w 	; go to title screen
		rts
; -----------------------------------------------------------------------------------------------
; SUBROUTINES
; -----------------------------------------------------------------------------------------------
SFCW_PalCycle:					;modified GHZ palette cycling routine.. -_-
		lea	(Pal_SFCWCyc).l,a0	;load cycling palette
		subq.w	#1,($FFFFF634).w	;subtract 1 from time left
		bne.s	@return			;if delay is > 0 then loop
		move.w	#4,($FFFFF634).w	;set delay time to 5
		move.w	($FFFFF632).w,d0	;move index to d0
		addq.w	#2,($FFFFF632).w	;add index
		andi.w	#6,d0			;limit the number of cycles
		lea	($FFFFFB16).w,a1 	;modify palette entry #8 (text)
		move.w	(a0,d0.w),(a1)
@return:	rts

SFCW_RunDelay:
		move.b	#2,($FFFFF62A).w
  		jsr	DelayProgram
  		rts

; -----------------------------------------------------------------------------------------------
; FILES
; -----------------------------------------------------------------------------------------------

Pal_SFCW:	incbin	"#SFCW_Intro/sfcw_pal.bin"
		even
Art_SFCW:	incbin	"#SFCW_Intro/sfcw_set.nem"
		even
Map_SFCW:	incbin	"#SFCW_Intro/sfcw_map.eni"
		even
Pal_SFCWCyc:	dc.w	$0A68,	$0ECE,	$0A68,	$0402
		even
