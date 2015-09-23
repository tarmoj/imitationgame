;Imitation-game interactive for series "Participation concerts"
; users play on html5 based UI-s imitating flutes
; see https://github.com/tarmoj/imitationgame for full source
; based on Hans Mikelson's example of waveguid flute http://www.eumus.edu.uy/eme/ensenanza/electivas/csound/materiales/book_chapters/19mathmodels/19math_models.htm
; (c) Tarmo Johannes tarmo@otsakool.edu.ee

<CsoundSynthesizer>
<CsOptions>
-odac:system:playback_ -+rtaudio=jack -d
-+rtmidi=alsaraw -Ma
</CsOptions>
<CsInstruments>


; internetis vaata: http://www.eumus.edu.uy/eme/ensenanza/electivas/csound/materiales/book_chapters/19mathmodels/19math_models.htm

sr        =         44100
ksmps     =         16 ; changes pitch; keep it 16
nchnls    =         2
0dbfs = 1

;;GLOBALS
gaflute init 0
gaemb init 0
gaL init 0
gaR init 0
;giLowFrequencies[] fillarray 50,60,70,80

gkSteps[] fillarray 1,9/8,5/4,11/8,3/2,13/8,7/4,2,17/8,18/8,19/8, 21/8

;;CHANNELS
chn_k "step0", 1
chn_k "volume",3
chn_k "noise0",1
chn_k "pan0",1
chn_k "vibrato0",1
chn_k "feedback",3

chnset 0.5, "pan0" 
chnset 0,"step1000"
chnset 0.01, "noise1000" ; 0.0001
chnset 0.5, "volume1000" ; bind with slider or some other controller
chnset 0.5, "pan1000"
chnset 0, "vibrato1000"
chnset 0,"feedback"
chnset 0.6, "volume"



instr lowFlute ; to play low frequencies for feedback, usually played from MIDI keyboard (or send index via p4

	if (p4==0) then 
		inotenum notnum
		index = inotenum % 12
		
		if (inotenum<60) then
			instrno = nstrnum("flute") + index/1000
			iplayer = 1000 ; to signal about low notes
			ibaseFreq = cpspch(4.00)
		else
			iplayer = 0
			instrno = nstrnum("flute") + inotenum/10000
			ibaseFreq = cpspch(8.00)
		endif
		
	else
		index = p4
		
	endif
	
	
	
	ifreq =  ibaseFreq* i(gkSteps[index])  ; think about the frequency!
	print index, ifreq

	
	
	schedule instrno, 0, p3, iplayer, ifreq ; fraction 0.001 tells that low one ; TEST with different feedbacks!
	
	if (release()==1) then
		turnoff2 instrno, 4, 1
	endif

endin

#define NOTEON #11#
#define NOTEOFF #10#

alwayson "osc"
instr osc ; Taasta! port 8008
	ihandle OSCinit 8008
	kcommand init 0
	kplayer init 0
	kinstrno init 0
	kmessage OSClisten ihandle, "/event", "iif", kcommand, kplayer, kinstrno
	
	if (kmessage==1) then 
		if (kcommand==$NOTEON) then
			event "i",kinstrno,0,-1, kplayer
		elseif (kcommand==$NOTEOFF) then
			turnoff2 abs(kinstrno), 4, 1
		endif
	endif
	

endin

schedule 10,  0,     1,   0, 0,0.5

instr     flute,10 ; FLUTE INSTRUMENT BASED ON PERRY COOK'S SLIDE FLUTE 

	; INIT----------------------
	ifqc      =  (p5==0) ?        cpspch(8.00) : p5; ; good was 7.05 flutes's lowest notes by default OR p5, if given
	print ifqc
	; constants
	ipress    =         0.9
	;ibreath   =         0.01;0.036 ; TODO: from channel
	ifeedbk1  =         0.43
	ifeedbk2  =         0.43
	iplayer = p4 ; to know from which step and noise channel to read	
	iamp = 0.1
	;ipan = (p6==0) ? 0.5 : p6
	
	; changing values from channels	----------------
	; get pitch by step - it can be changed via channel value
	StepChannel sprintf "step%d", iplayer
	SnoiseChannel sprintf "noise%d", iplayer
	SpanChannel sprintf "pan%d", iplayer
	SvibratoChannel sprintf "vibrato%d", iplayer
	prints SvibratoChannel
	kstep chnget StepChannel
	knoise port chnget:k(SnoiseChannel), 0.1,chnget:i(SnoiseChannel)
	;TODO define MAXNOISELEVEL; MINNOISELEVEL
	knoiseLevel = 0.001 + knoise*(0.2-0.001)
	
	kvibratoLevel port chnget:k(SvibratoChannel),0.05,chnget:i(SvibratoChannel)
	
	kpan port chnget:k(SpanChannel),0.05,chnget:i(SpanChannel)	

	
	kfreq init ifqc
	if (p5==0) then ; if freq was given, use that
		kfreq = ifqc*gkSteps[kstep]
		kfreq port kfreq, 0.03,ifqc
	endif
	
	; FLOW SETUP ---------------------------- 
	aflute1 init 0 ; the bore sound
	aenv1     linsegr    0, .06, 1.1*ipress, .2, ipress, .5, 0 ; blow envelope ;?? maybe more than 0.2	; rise was 0.06
	aenv2     linenr   1, .01, .2, 0.001 ; declick, basically	
	kenvibr   linsegr    0, .5, 0, .5, 1, 0.1, 1 ; VIBRATO ENVELOPE - start after 0.5 seconds
	
	; THE VALUES MUST BE APPROXIMATELY -1 TO 1 OR THE CUBIC WILL BLOW UP
	aflow1    rand      aenv1 ; noise
	avibr init 0
	avibr   poscil     .06*kenvibr*kvibratoLevel, 2+kvibratoLevel*4
	
	; ibreath CAN BE USED TO ADJUST THE NOISE LEVEL
	asum1     =         knoiseLevel *aflow1 + aenv1 + avibr 
	asum2     =         asum1 + aflute1*ifeedbk1 ; noise + feedback sound from bore 
	
	
	
	afqc      =      1/kfreq  - asum1/5000 -9/sr + kfreq/12000000  ; 1/kfreq  - asum1/20000 -9/sr + kfreq/12000000 ; 	the correction found empirically
	
	; EMBOUCHURE DELAY SHOULD BE 1/2 THE BORE DELAY ---------
	atemp1    delayr    1/ifqc/2	
	ax        deltapi   afqc/2  ; - asum1/ifqc/10 + 1/1000 ;
	          delayw    asum2
	                              
	apoly     =         ax - ax*ax*ax
	kglobalFeedback chnget ("feedback")
	asum3     =         apoly + aflute1*ifeedbk2+ gaflute*ifeedbk2*kglobalFeedback/sqrt((active:k("flute")+1) ) ; the more players the less feedback
	gaemb  += asum3*aenv2 ;/ (sqrt(active:k(10)+1)) ; add declick
	
	
	avalue    tone      asum3, 2000 ; filter from bore opening. Sound that goes into the air
	
	; BORE, THE BORE LENGTH DETERMINES PITCH.  SHORTER IS HIGHER PITCH ----------------------------
	atemp2    delayr    1/ifqc
	aflute1     deltapi afqc ; afqc depends on kfreq
	         delayw    avalue
	
	;output is from instr bore
	aout = avalue*iamp*aenv2
	aout clip aout, 0, 0dbfs*0.95  ; for any case
  	aL,aR pan2 aout, kpan
  	gaL += aL
  	gaR += aR
    ;outs       aout, aout
    
    ; pitch test - to find correct value for afc
;    apitch, aloc plltrack aout, 0.3
;    kpitch downsamp apitch
;    outvalue "pitch", kpitch
    

endin


alwayson "superBore"

instr superBore; collects and outputs sound from all "flute" insruments (Sum of gemb) and send global feedback (gaflute) + main output

	ifqc = cpspch(6.01) ; fixed length 100 on hea.
	gaemb limit gaemb, -2, 2 ; find some other way to tame gaemb 
	avalue    tone      gaemb, 2000 ; sum of all embouchure's
	
	; BORE, THE BORE LENGTH DETERMINES PITCH.  SHORTER IS HIGHER PITCH
	atemp2    delayr    1/ifqc
	gaflute     deltapi 1/ifqc-12/sr;+asum1/20000 ;afqc
          delayw    avalue
	
	; midi controllers
	ctrlinit 1,1,0
	kfeedback ctrl7 1,1,0,1
	chnset kfeedback, "feedback"
	; main out
	
	kvolume port (chnget:k("volume")),0.02
	kvolume *=0.5
	
	gaL clip gaL, 0, 0dbfs*0.95
	gaL limit gaL, -0.99, 0.99 ; for any case, if something wants to blow
	gaR clip gaR, 0, 0dbfs*0.95
	gaR limit gaR, -0.99, 0.99 ; for any case, if something wants to blow
	outs gaL*kvolume, gaR*kvolume
	
	gaemb = 0
	gaL = 0      
	gaR = 0        
    ;outs       aout, aout

endin



</CsInstruments>
<CsScore>

</CsScore>
</CsoundSynthesizer>

















<bsbPanel>
 <label>Widgets</label>
 <objectName/>
 <x>0</x>
 <y>0</y>
 <width>435</width>
 <height>466</height>
 <visible>true</visible>
 <uuid/>
 <bgcolor mode="nobackground">
  <r>255</r>
  <g>255</g>
  <b>255</b>
 </bgcolor>
 <bsbObject type="BSBScrollNumber" version="2">
  <objectName>step0</objectName>
  <x>119</x>
  <y>153</y>
  <width>80</width>
  <height>25</height>
  <uuid>{d9401bd2-d771-4459-96d8-0a345a02b79b}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>0</midicc>
  <alignment>left</alignment>
  <font>Arial</font>
  <fontsize>10</fontsize>
  <color>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </color>
  <bgcolor mode="background">
   <r>255</r>
   <g>255</g>
   <b>255</b>
  </bgcolor>
  <value>0.00000000</value>
  <resolution>1.00000000</resolution>
  <minimum>0.00000000</minimum>
  <maximum>11.00000000</maximum>
  <bordermode>border</bordermode>
  <borderradius>1</borderradius>
  <borderwidth>1</borderwidth>
  <randomizable group="0">false</randomizable>
  <mouseControl act=""/>
 </bsbObject>
 <bsbObject type="BSBScope" version="2">
  <objectName/>
  <x>85</x>
  <y>316</y>
  <width>350</width>
  <height>150</height>
  <uuid>{72f84eac-2953-4dd5-89d4-a1a3fc246366}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>0</midicc>
  <value>-255.00000000</value>
  <type>scope</type>
  <zoomx>2.00000000</zoomx>
  <zoomy>2.00000000</zoomy>
  <dispx>1.00000000</dispx>
  <dispy>1.00000000</dispy>
  <mode>0.00000000</mode>
 </bsbObject>
 <bsbObject type="BSBVSlider" version="2">
  <objectName>volume</objectName>
  <x>57</x>
  <y>6</y>
  <width>20</width>
  <height>100</height>
  <uuid>{a435f8e8-c36e-4b55-9055-96d52a36a151}</uuid>
  <visible>true</visible>
  <midichan>1</midichan>
  <midicc>1</midicc>
  <minimum>0.00000000</minimum>
  <maximum>1.00000000</maximum>
  <value>0.60000000</value>
  <mode>lin</mode>
  <mouseControl act="jump">continuous</mouseControl>
  <resolution>-1.00000000</resolution>
  <randomizable group="0">false</randomizable>
 </bsbObject>
 <bsbObject type="BSBLabel" version="2">
  <objectName/>
  <x>38</x>
  <y>108</y>
  <width>80</width>
  <height>25</height>
  <uuid>{23e9f98a-517d-4494-829b-bcb4a3bf7a92}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>0</midicc>
  <label>Volume</label>
  <alignment>left</alignment>
  <font>Arial</font>
  <fontsize>10</fontsize>
  <precision>3</precision>
  <color>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </color>
  <bgcolor mode="nobackground">
   <r>255</r>
   <g>255</g>
   <b>255</b>
  </bgcolor>
  <bordermode>noborder</bordermode>
  <borderradius>1</borderradius>
  <borderwidth>1</borderwidth>
 </bsbObject>
 <bsbObject type="BSBLabel" version="2">
  <objectName/>
  <x>34</x>
  <y>152</y>
  <width>80</width>
  <height>25</height>
  <uuid>{3b13c00e-7a09-4973-baf7-59d37c2c62df}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>0</midicc>
  <label>Step0</label>
  <alignment>left</alignment>
  <font>Arial</font>
  <fontsize>10</fontsize>
  <precision>3</precision>
  <color>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </color>
  <bgcolor mode="nobackground">
   <r>255</r>
   <g>255</g>
   <b>255</b>
  </bgcolor>
  <bordermode>noborder</bordermode>
  <borderradius>1</borderradius>
  <borderwidth>1</borderwidth>
 </bsbObject>
 <bsbObject type="BSBVSlider" version="2">
  <objectName>feedback</objectName>
  <x>221</x>
  <y>8</y>
  <width>20</width>
  <height>100</height>
  <uuid>{4467df67-d9f2-4636-8198-69662d48a704}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>0</midicc>
  <minimum>0.00000000</minimum>
  <maximum>1.00000000</maximum>
  <value>0.00000000</value>
  <mode>lin</mode>
  <mouseControl act="jump">continuous</mouseControl>
  <resolution>-1.00000000</resolution>
  <randomizable group="0">false</randomizable>
 </bsbObject>
 <bsbObject type="BSBLabel" version="2">
  <objectName/>
  <x>193</x>
  <y>111</y>
  <width>104</width>
  <height>25</height>
  <uuid>{308f0f7b-a0fc-402f-8870-3947d7bdcd50}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>0</midicc>
  <label>Global feedback</label>
  <alignment>left</alignment>
  <font>Arial</font>
  <fontsize>10</fontsize>
  <precision>3</precision>
  <color>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </color>
  <bgcolor mode="nobackground">
   <r>255</r>
   <g>255</g>
   <b>255</b>
  </bgcolor>
  <bordermode>noborder</bordermode>
  <borderradius>1</borderradius>
  <borderwidth>1</borderwidth>
 </bsbObject>
 <bsbObject type="BSBLabel" version="2">
  <objectName/>
  <x>25</x>
  <y>198</y>
  <width>80</width>
  <height>25</height>
  <uuid>{d54a424c-8141-44dd-a4d1-6862c9a567a8}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>0</midicc>
  <label>noise0</label>
  <alignment>left</alignment>
  <font>Arial</font>
  <fontsize>10</fontsize>
  <precision>3</precision>
  <color>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </color>
  <bgcolor mode="nobackground">
   <r>255</r>
   <g>255</g>
   <b>255</b>
  </bgcolor>
  <bordermode>noborder</bordermode>
  <borderradius>1</borderradius>
  <borderwidth>1</borderwidth>
 </bsbObject>
 <bsbObject type="BSBHSlider" version="2">
  <objectName>noise0</objectName>
  <x>122</x>
  <y>197</y>
  <width>129</width>
  <height>26</height>
  <uuid>{61947aee-d747-489b-849b-99330caa745b}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>0</midicc>
  <minimum>0.00000000</minimum>
  <maximum>1.00000000</maximum>
  <value>0.00000000</value>
  <mode>lin</mode>
  <mouseControl act="jump">continuous</mouseControl>
  <resolution>-1.00000000</resolution>
  <randomizable group="0">false</randomizable>
 </bsbObject>
 <bsbObject type="BSBHSlider" version="2">
  <objectName>pan0</objectName>
  <x>124</x>
  <y>230</y>
  <width>134</width>
  <height>32</height>
  <uuid>{07624fa9-14e5-43b6-a724-823a5bccd1ee}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>0</midicc>
  <minimum>0.00000000</minimum>
  <maximum>1.00000000</maximum>
  <value>0.52238806</value>
  <mode>lin</mode>
  <mouseControl act="jump">continuous</mouseControl>
  <resolution>-1.00000000</resolution>
  <randomizable group="0">false</randomizable>
 </bsbObject>
 <bsbObject type="BSBHSlider" version="2">
  <objectName>vibrato0</objectName>
  <x>124</x>
  <y>264</y>
  <width>134</width>
  <height>32</height>
  <uuid>{b8f8f68b-60a0-46a9-96fc-4cf09c5001f5}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>0</midicc>
  <minimum>0.00000000</minimum>
  <maximum>1.00000000</maximum>
  <value>1.00000000</value>
  <mode>lin</mode>
  <mouseControl act="jump">continuous</mouseControl>
  <resolution>-1.00000000</resolution>
  <randomizable group="0">false</randomizable>
 </bsbObject>
 <bsbObject type="BSBLabel" version="2">
  <objectName/>
  <x>27</x>
  <y>235</y>
  <width>80</width>
  <height>25</height>
  <uuid>{21eb17d1-916e-4014-a463-0ed1c3bd0f9d}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>0</midicc>
  <label>pan0</label>
  <alignment>left</alignment>
  <font>Arial</font>
  <fontsize>10</fontsize>
  <precision>3</precision>
  <color>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </color>
  <bgcolor mode="nobackground">
   <r>255</r>
   <g>255</g>
   <b>255</b>
  </bgcolor>
  <bordermode>noborder</bordermode>
  <borderradius>1</borderradius>
  <borderwidth>1</borderwidth>
 </bsbObject>
 <bsbObject type="BSBLabel" version="2">
  <objectName/>
  <x>29</x>
  <y>272</y>
  <width>80</width>
  <height>25</height>
  <uuid>{8a8d39c6-b0af-4208-b101-dbb34bc13ae7}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>0</midicc>
  <label>vibrato0</label>
  <alignment>left</alignment>
  <font>Arial</font>
  <fontsize>10</fontsize>
  <precision>3</precision>
  <color>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </color>
  <bgcolor mode="nobackground">
   <r>255</r>
   <g>255</g>
   <b>255</b>
  </bgcolor>
  <bordermode>noborder</bordermode>
  <borderradius>1</borderradius>
  <borderwidth>1</borderwidth>
 </bsbObject>
 <bsbObject type="BSBDisplay" version="2">
  <objectName>pitch</objectName>
  <x>96</x>
  <y>549</y>
  <width>80</width>
  <height>25</height>
  <uuid>{dca42d32-7896-4c0d-8083-0dba96ffc6f3}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>0</midicc>
  <label>0.000</label>
  <alignment>left</alignment>
  <font>Arial</font>
  <fontsize>10</fontsize>
  <precision>3</precision>
  <color>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </color>
  <bgcolor mode="nobackground">
   <r>255</r>
   <g>255</g>
   <b>255</b>
  </bgcolor>
  <bordermode>border</bordermode>
  <borderradius>1</borderradius>
  <borderwidth>1</borderwidth>
 </bsbObject>
</bsbPanel>
<bsbPresets>
</bsbPresets>
<EventPanel name="play 1902" tempo="60.00000000" loop="8.00000000" x="1261" y="159" width="655" height="346" visible="true" loopStart="0" loopEnd="0">i 10 0 20 0 10 0 
i 10 0 30 0 0 0 
i 10 0 1 0 300 0.9 
i 10 0 2 0 400 0.2 
i 10 0 2 0 600 .1 </EventPanel>
