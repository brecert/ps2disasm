
; 0 address offsets in the form 0(a0) are optimized automatically by the assembler
; the value 0 will turn this feature off. This is good for producing a byte-perfect copy of
; the original ROM. When hacking, you don't need this so you can set it to 1 if you want
zeroOffsetOptimization = 0

bugfixes = 0			; if 1, include bug fixes
dezo_steal_fix = 0		; if 1, Shir will no longer steal on Dezo
walk_speed = 0			; 0 = normal; 1 = double; 2 = quadruple
exp_gain = 0			; 0 = normal; 1 = double; 2 = quadruple
meseta_gain = 0			; 0 = normal; 1 = double; 2 = quadruple
checksum_remove = 0		; if 1, remove the checksum calculation routine resulting in a faster boot time
revision = 2			; 0 = Japanese; 1 = first US release; 2 = second US release; 3 = Portuguese
cross_patch = 0			; Set this to 1 to replace the green cross sign with an H and remove the red cross sign, just like
						; the Virtual Console version