<CsoundSynthesizer>
<CsOptions>
-d  -odac ;-+rtaudio=jack
</CsOptions>
<CsInstruments>

sr = 44100
nchnls = 2
0dbfs = 1
ksmps = 32


;alwayson "test"
chn_k "value",1
gkValue init 1

;schedule "tester", 0,1
instr tester
	schedule "test",0,p3
	chnset line(1,p3,0),"value"
endin

;schedule "test",0,1

instr test
	prints "INSTR TEST"
	;kval chnget "value"
	kval = gkValue
	printk2 kval
	kfreq = 200+400*kval 
	asig vco2 1, kfreq
	asig moogvcf asig, kfreq, 0.5+kval/2
	asig *= madsr(0.1,0.1,0.6, 0.3) * 0.5
	outs asig, asig
endin


</CsInstruments>
<CsScore>
;i1 0 3
</CsScore>
</CsoundSynthesizer>

