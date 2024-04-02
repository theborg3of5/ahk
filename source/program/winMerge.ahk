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

	; Fix tab order (it's always MRU, but we can turn MRU back into the order they're in).
	^+f::
		fixWinMergeTabOrder() {
			HotkeyLib.waitForRelease()
			numTabs := 9

			; Select each tab in reverse order.
			Loop, % numTabs {
				tabIndex := numTabs - A_Index + 1
				Send, !w ; Window menu
				Send, % tabIndex ; Tab index is just that number in the menu
			}
		}
	
	; Toggle word wrap
	^+7::
		Send, !v ; View menu
		Send, r  ; Wrap lines
	return
#If
