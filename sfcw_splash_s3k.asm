; ===============================================================================================
; SFCW Splash Screen v2.5B (S3K version, might be buggy)
; by Zy BG9K (Zumi, ZoomTen)
;
; Last modified 2014-03-01
; Uploaded to GitHub 2016-08-20
; ===============================================================================================

; -----------------------------------------------------------------------------------------------
; The real deal. :)
; -----------------------------------------------------------------------------------------------
SFCW_SplashStart:
		moveq	#-$1F,d0
		jsr	Play_Sound_2		; Stop music
		jsr	Clear_Nem_Queue		; Clear the PLC
		clr.w	($FFFFFE10).w		; Clear zone/act index
		jsr	Pal_FadeToBlack		; Fade out previous screen
; Set up VDP..
		move	#$2700,sr		; Disable interrupts
		lea	($C00004).l,a6
		move.w	#$8004,(a6)
		move.w	#$8230,(a6)
		move.w	#$8405,(a6)
		move.w	#$8700,(a6)
		move.w	#$8B03,(a6)
		clr.b	($FFFFF64E).w
		clr.b	($FFFFF730).w		; Both water flags cleared
		jsr	Clear_DisplayData
; Clear objects..
		lea	($FFFFD000).w,a1	; Prepare for object clearing
		moveq	#0,d0			; Set to clear object RAM
		move.w	#$1FF,d1		; Clear FFFFB000-FFFFD000
-		move.l	d0,(a1)+
		dbf d1,	-			; No sleep until clear
; Load art..
		move.l	#$40000000,($C00004).l
		lea	(Art_SFCW).l,a0
		jsr	Nem_Decomp
; Load mappings..
		lea	($FFFF0000).l,a1
		lea	(Map_SFCW).l,a0
		move.w	#0,d0
		jsr	Eni_Decomp
; Copy mappings to VRAM so we can see it..
		lea	($FFFF0000).l,a1
		move.l	#$40000003,d0
		moveq	#$27,d1
		moveq	#$1B,d2
		jsr	(Plane_Map_To_VRAM).l
; Clear palette..
		moveq	#0,d0			; Set fill byte to 0 for clearing
		lea	($FFFFFC80).w,a1	; To palette buffer
		moveq	#$10,d1			; Clear 16 entries
-		move.w	d0,(a1)+
		dbf d1,	-			; Loop until all palette entries clear

                move.w	#$0EEE,($FFFFFC98).w	; Show SFCW URL (Set palette entry #9 to white)
                
                move.w	($FFFFF60E).w,d0
		ori.b	#$40,d0
		move.w	d0,($C00004).l		; Turn the display on

; -----------------------------------------------------------------------------------------------
; SFCW text fade animation
; -----------------------------------------------------------------------------------------------
SFCW_Animation:
		jsr	Pal_FadeFromBlack
		moveq	#$29,d0
		jsr	Play_Sound
; Fade title text in..
		moveq	#6,d1			; # of frames for fading

SFCW_FadeAnim:
		move.w	#$8,($FFFFF614).w	; Set to delay 8 frames
		add.w	#$0201,($FFFFFC16).w	; Fade palette entry #8
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
		jsr	Pal_FadeToWhite		; Flash the screen
SFCW_LoadPalette:
		lea	(Pal_SFCW).l,a1		; Load palette
		lea	($FFFFFC80).w,a2	; To palette buffer
		moveq	#$10,d0			; Copy 16 entries
-		move.w	(a1)+,(a2)+
		dbf d0,	-			; Loop until all palette entries copied
		jsr	Pal_ToWhite

		moveq	#-$4D,d0		; Sound ID to big ring entry
		jsr	(Play_Sound_2).l	; Play SFX

		move.w	#5,($FFFF7800).l	; Enable real palette cycling
		move.w	#0,($FFFF7802).l	; Set cycle index to 0
SFCW_Loop:
		jsr	Pal_FromBlackWhite	; Flash out
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
		subq.w	#1,($FFFF7800).l	;subtract 1 from time left
		bne.s	+			;if delay is > 0 then loop
		move.w	#4,($FFFF7800).l	;set delay time to 4
		move.w	($FFFF7802).l,d0	;move index to d0
		addq.w	#2,($FFFF7802).l	;add index
		andi.w	#6,d0			;limit the number of cycles
		lea	($FFFFFC16).w,a1 	;modify palette entry #8 (text)
		move.w	(a0,d0.w),(a1)
+		rts

SFCW_RunDelay:
		move.b	#2,($FFFFF62A).w
  		jsr	Wait_VSync
  		rts

; -----------------------------------------------------------------------------------------------
; FILES
; -----------------------------------------------------------------------------------------------

Pal_SFCW:	binclude	"#SFCW_Intro/sfcw_pal.bin"
		even
Art_SFCW:	binclude	"#SFCW_Intro/sfcw_set.nem"
		even
Map_SFCW:	binclude	"#SFCW_Intro/sfcw_map.eni"
		even
Pal_SFCWCyc:	dc.w	$0A68,	$0ECE,	$0A68,	$0402
		even
