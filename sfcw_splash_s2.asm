; ===============================================================================================
; SFCW Splash Screen v2.5B (S2 version)
; by Zy BG9K (Zumi, ZoomTen)
;
; Last modified 2014-03-01
; Uploaded to GitHub 2016-08-20
; ===============================================================================================

; -----------------------------------------------------------------------------------------------
; The real deal. :)
; -----------------------------------------------------------------------------------------------
SFCW_SplashStart:
		move.b	#$7D+$80,d0
		jsr	PlayMusic 		; Stop music
		jsr	ClearPLC		; Clear the PLC
		jsr	Pal_FadeFrom		; Fade out previous screen
; Set up VDP..
		move	#$2700,sr		; Disable interrupts
		lea	($C00004).l,a6
		move.w	#$8004,(a6)
		move.w	#$8230,(a6)
		move.w	#$8405,(a6)
		move.w	#$8700,(a6)
		move.w	#$8B03,(a6)
		clr.b	($FFFFF64E).w		; Clear water state
		clr.w	($FFFFFFD8).w		; Clear 2P mode
		jsr    ClearScreen

		dmaFillVRAM 0,$C000,$2000 ; fill VRAM $C000 - $DFFF with zeroes
; Clear objects..
		lea	($FFFFB000).w,a1	; Prepare for object clearing
		moveq	#0,d0			; Set to clear object RAM
		move.w	#$800,d1		; Clear FFFFB000-FFFFD000
-		move.l	d0,(a1)+
		dbf d1,	-			; No sleep until clear
; Load art..
		move.l	#$40000000,($C00004).l
		lea	(Art_SFCW).l,a0
		jsr	NemDec
; Load mappings..
		lea	($FFFF0000).l,a1
		lea	(Map_SFCW).l,a0
		move.w	#0,d0
		jsr	EniDec
; Copy mappings to VRAM so we can see it..
		lea	($FFFF0000).l,a1
		move.l	#$40000003,d0
		moveq	#$27,d1
		moveq	#$1B,d2
		jsr	ShowVDPGraphics2
; Clear palette..
		moveq	#0,d0			; Set fill byte to 0 for clearing
		lea	($FFFFFB80).w,a1	; To palette buffer
		moveq	#$10,d1			; Clear 16 entries
-		move.w	d0,(a1)+
		dbf d1,	-			; Loop until all palette entries clear

                move.w	#$0EEE,($FFFFFB98).w	; Show SFCW URL (Set palette entry #9 to white)

; -----------------------------------------------------------------------------------------------
; SFCW text fade animation
; -----------------------------------------------------------------------------------------------
SFCW_Animation:
		jsr	Pal_FadeTo
		move.b	#$1A+$80,d0		; Set music ID to level clear music
		jsr	PlayMusic		; Play the music
; Fade title text in..
		moveq	#6,d1			; # of frames for fading

SFCW_FadeAnim:
		move.w	#$8,($FFFFF614).w	; Set to delay 8 frames
		add.w	#$0201,($FFFFFB16).w	; Fade palette entry #8
-		jsr	SFCW_RunDelay
		tst.w	($FFFFF614).w		; Has delay time run out?
		bne.w	-			; If not, keep waiting
		dbf d1,	SFCW_FadeAnim		; Loop 6 more times
; Wait until flash..
                move.w	#$1C,($FFFFF614).w	; Set to delay 28 frames
-		jsr	SFCW_RunDelay
		tst.w	($FFFFF614).w
		bne.w	-
; -----------------------------------------------------------------------------------------------
; SFCW ending loop
; -----------------------------------------------------------------------------------------------
		jsr	Pal_MakeFlash		; Flash the screen
SFCW_LoadPalette:
		lea	(Pal_SFCW).l,a1		; Load palette
		lea	($FFFFFB80).w,a2	; To palette buffer
		moveq	#$10,d0			; Copy 16 entries
-		move.w	(a1)+,(a2)+
		dbf d0,	-			; Loop until all palette entries copied
		jsr	Pal_ToWhite

		move.w	#$43+$80,d0		; Set SFX ID to Sonic 1 SS ring entry sound
		jsr	PlaySound		; Play the sound

		move.w	#5,($FFFFF65E).l	; Enable real palette cycling
		move.w	#0,($FFFFF65C).l	; Set cycle index to 0
SFCW_Loop:
		jsr	Pal_MakeWhite		; Flash out
		move.w	#60*4,($FFFFF614).w	; Set to wait 4 seconds
-		jsr	SFCW_PalCycle		; Run palette cycling
		jsr	SFCW_RunDelay
		andi.b	#$F0,($FFFFF605).w	; Is any button pressed?
		bne.w	SFCW_Next		; If so, go to next screen
		tst.w   ($FFFFF614).w		; Is time run out?
		bne.s	-			; If not, loop
SFCW_Next:
		move.b	#$04,($FFFFF600).w 	; go to title screen
		rts
; -----------------------------------------------------------------------------------------------
; SUBROUTINES
; -----------------------------------------------------------------------------------------------
SFCW_PalCycle:					;modified GHZ palette cycling routine.. -_-
		lea	(Pal_SFCWCyc).l,a0	;load cycling palette
		subq.w	#1,($FFFFF65E).l	;subtract 1 from time left
		bne.s	+			;if delay is > 0 then loop
		move.w	#4,($FFFFF65E).l	;set delay time to 4
		move.w	($FFFFF65C).l,d0	;move index to d0
		addq.w	#2,($FFFFF65C).l	;add index
		andi.w	#6,d0			;limit the number of cycles
		lea	($FFFFFB16).w,a1 	;modify palette entry #8 (text)
		move.w	(a0,d0.w),(a1)
+		rts

SFCW_RunDelay:
		move.b	#2,($FFFFF62A).w
  		jsr	DelayProgram
  		rts

; -----------------------------------------------------------------------------------------------
; FILES
; -----------------------------------------------------------------------------------------------

Pal_SFCW:	BINCLUDE	"#SFCW_Intro/sfcw_pal.bin"
Art_SFCW:	BINCLUDE	"#SFCW_Intro/sfcw_set.nem"
Map_SFCW:	BINCLUDE	"#SFCW_Intro/sfcw_map.eni"
Pal_SFCWCyc:	dc.w	$0A68,	$0ECE,	$0A68,	$0402
