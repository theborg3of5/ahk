#If Config.isWindowActive("WinMerge")
	; Rough approximation of Ctrl+Tab (order still gets screwy)
	^Tab::Send, ^{F6}
	^+Tab::Send, ^+{F6}

	; Jump between differences
	^Up::Send, !{Up}
	^Down::Send, !{Down}

	; Options
	!o::Send, !eo

	; Remove all synchronization points
	!+s::Send, !mh
#If
