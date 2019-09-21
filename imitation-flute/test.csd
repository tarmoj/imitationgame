<CsoundSynthesizer>
<CsOptions>
-d  -odac ;-+rtaudio=jack
</CsOptions>
<CsInstruments>

sr = 44100
ksmps = 32
nchnls = 2
0dbfs = 1

;;channels
chn_k "vibrato",3
chn_k "step",3
chn_k "noise",3
chn_k "volume", 3

chnset 0.6, "volume"

gkSteps[] fillarray 1, 72/70, 80/70, 84/71, 93/70,  96/70 ;1,9/8,5/4,11/8,3/2,13/8,7/4,2,17/8,18/8,19/8, 21/8
; frequencies: 71 Hz (põhitoon), 76 Hz, 92 Hz => 1, 76/71, 92/71

schedule 1,  0,     1,   0, 0,0.5

; based on Hans Mikelson's example of waveguid flute http://www.eumus.edu.uy/eme/ensenanza/electivas/csound/materiales/book_chapters/19mathmodels/19math_models.htm

instr     flute,1 ; FLUTE INSTRUMENT BASED ON PERRY COOK'S SLIDE FLUTE

	; INIT----------------------
	ifqc      =  (p5==0) ?       2 * 72 : p5; ; good was 7.05 flutes's lowest notes by default OR p5, if given
	print ifqc
	; constants
	ipress    =         0.9
	;ibreath   =         0.01;0.036 ; TODO: from channel
	ifeedbk1  =         0.43
	ifeedbk2  =         0.43
	iplayer = p4 ; to know from which step and noise channel to read
	iamp = 0.2
	;ipan = (p6==0) ? 0.5 : p6


	; changing values from channels	----------------
	; get pitch by step - it can be changed via channel value
	kstep chnget "step"
	knoise port chnget:k("noise"), 0.1,chnget:i("noise")
	;TODO define MAXNOISELEVEL; MINNOISELEVEL
	knoiseLevel = 0.001 + knoise*0.2

	kvibratoLevel port chnget:k("vibrato"),0.05,chnget:i("vibrato")

	kpan init 0.5;port chnget:k(SpanChannel),0.05,chnget:i(SpanChannel)


	kfreq init ifqc
	if (p5==0) then ; if freq was given, use that
		kfreq = ifqc*gkSteps[kstep]
		kfreq port kfreq, 0.03,ifqc
	endif

	; FLOW SETUP ----------------------------
	aflute1 init 0 ; the bore sound
	aenv1     linsegr    0, .06, 1.1*ipress, .2, ipress, .5, 0 ; blow envelope ;?? maybe more than 0.2	; rise was 0.06
	aenv2     linenr   1, .01, 0.8, 0.001 ; declick, basically
	kenvibr   linsegr    0, .5, 0, .5, 1, 0.1, 1 ; VIBRATO ENVELOPE - start after 0.5 seconds

	; THE VALUES MUST BE APPROXIMATELY -1 TO 1 OR THE CUBIC WILL BLOW UP
	aflow1    rand      aenv1 ; noise
	avibr init 0
	avibr   poscil     .06*kenvibr*sqrt(kvibratoLevel), 1+kvibratoLevel*7

	; knoiseLevelCAN BE USED TO ADJUST THE NOISE LEVEL
	; try with bandpass for noise?
	;aflow1 butterbp aflow1, kfreq,kfreq*0.75
	asum1     =         knoiseLevel *aflow1 + aenv1 + avibr
	asum2     =         asum1 + aflute1*ifeedbk1 ; noise + feedback sound from bore

	afqc      =      1/kfreq  - asum1/5000 -9/sr + kfreq/12000000  ; 1/kfreq  - asum1/20000 -9/sr + kfreq/12000000 ; 	the correction found empirically

	; EMBOUCHURE DELAY SHOULD BE 1/2 THE BORE DELAY ---------
	atemp1    delayr    1/ifqc/2
	ax        deltapi   afqc/2  ; - asum1/ifqc/10 + 1/1000 ;
			  delayw    asum2

	apoly     =         ax - ax*ax*ax
	asum3     =         apoly + aflute1*ifeedbk2

	avalue    tone      asum3, 2000 ; filter from bore opening. Sound that goes into the air

	; BORE, THE BORE LENGTH DETERMINES PITCH.  SHORTER IS HIGHER PITCH ----------------------------
	atemp2    delayr    1/ifqc
	aflute1     deltapi afqc ; afqc depends on kfreq
			 delayw    avalue
	kvolume port chnget:k("volume"), 0.02, chnget:i("volume")

	aout = avalue*iamp*aenv2*kvolume
	aout clip aout, 0, 0dbfs*0.95  ; for any case

	;aL,aR pan2 aout, kpan
  outs aout, aout

endin

;maxalloc 2, 3
instr bell
	iamp= p4
	ifreq=p5
	aenv adsr 0.1,0.1,0.5,p3*0.75
	asig poscil iamp*aenv,  ifreq ; very simple side sound
	outs asig, asig
endin


</CsInstruments>
<CsScore>
;i1 0 3
</CsScore>
</CsoundSynthesizer>

