; OneNote hotkeys.
#If Config.isWindowActive("OneNote")
	; Block certain hotkeys that I accidentally trigger, but don't want to use
	*^+1::return ; Add Outlook task
	
	; Make ctrl+tab (and XButtons) switch pages, not sections
	^Tab:: Send, ^{PgDn}
	^+Tab::Send, ^{PgUp}
	XButton1::Send, ^{PgDn}
	XButton2::Send, ^{PgUp}
	; Make ctrl+page down/up switch sections
	^PgDn::Send, ^{Tab}
	^PgUp::Send, ^+{Tab}
	
	; Expand and collapse outlines
	!Left:: !+-
	!Right::!+=
	; Alternate history back/forward
	!+Left:: Send, !{Left}
	!+Right::Send, !{Right}
	
	; Make line movement alt + up/down instead of alt + shift + up/down to match notepad++ and EpicStudio.
	!Up::  !+Up
	!Down::!+Down
	
	; Horizontal scrolling.
	+WheelUp::  OneNote.scrollLeft()
	+WheelDown::OneNote.scrollRight()
	
	^+0::Send, ^0 ; Since we're using ^0 to set zoom to 100% below, add a replacement hotkey for clearing all tags.
	^!n::Send, ^+n ; 'Normal' text formatting, as ^+n is already being used for new subpage.
	^7:: Send, ^6 ; Make ^7 do the same tag (Done green check) as ^6.
	^+8::SendRaw, % "*" Config.private["INITIALS"] " " FormatTime(, "MM/yy") ; Insert contact comment
	^!4::Send, ^!5 ; Use Header 5 instead of Header 4 - Header 4 is just an italicized Header 3, which isn't distinct enough for me.
	
	; Print preview
	^!p::
		Send, !fpr
	return
	
	; Delete the entire current line
	^d::
		OneNote.escapePastePopup()
		OneNote.selectLine()
		Send, {Delete}
	return
	
	; Notebook syncing
	^s::
		OneNote.escapePastePopup()
		Send, +{F9} ; Sync This Notebook Now
	return
	^+s::
		OneNote.escapePastePopup()
		Send, {F9} ; Sync All Notebooks Now
	return
	
	; Focus notebooks by index
	!1::OneNote.focusNotebookWithIndex(1)
	!2::OneNote.focusNotebookWithIndex(2)
	!3::OneNote.focusNotebookWithIndex(3)
	!4::OneNote.focusNotebookWithIndex(4)
	!5::OneNote.focusNotebookWithIndex(5)
	
	; Various specific commands based on the quick access toolbar.
	$^+n::OneNote.newSubpage()
	^+[:: OneNote.promoteSubpage()
	^+]:: OneNote.makeSubpage()
	$^+d::OneNote.deletePageWithConfirm()
	!m::  OneNote.meetingDetailsFromAnotherDay()
	^0::  OneNote.setZoomTo100Percent()
	
	; Onetastic custom styles and macros
	^+c::OneNote.customStylesCode()
	^+i::OneNote.addSubLinesToSelectedLines()
	!t:: OneNote.collapseToUnfinishedTags()
	^l:: OneNote.createAndLinkPage()
	^+w::OneNote.widenOutline()
	
	; Work-specific macros
	^+a::OneNote.applyDevStructureToCurrentPage()
	^+l::OneNote.createAndLinkDevPage()
	^+p::OneNote.createAndLinkWorkplanPage()
	
	; Link handling
	!c::      OneNote.copyLinkToCurrentPage()
	!#c::     OneNote.copyTitleLinkToCurrentParagraph()
	^RButton::OneNote.copyLinkUnderMouse()
	^MButton::OneNote.removeLinkUnderMouse()
	
	; Todo page handling
	^t::          OneNoteTodoPage.collapseToTodayItems() ; Today only, item-level
	^+t::         OneNoteTodoPage.collapseToAllItems()   ; All sections, item-level
	^!t::         OneNoteTodoPage.collapseToTodayAll()   ; Today only, fully expanded
	^+m::         OneNoteTodoPage.copyForToday()         ; New page for today
	^+#m::        OneNoteTodoPage.copyForTomorrow()      ; New page for tomorrow
	:*X:.todo::   OneNoteTodoPage.peekOtherTodos()       ; Peek at past/future todo items
	:*X:.itodo::  OneNoteTodoPage.insertOtherTodos()     ; Insert past/future todo items
	:*X:.devdo::  OneNoteTodoPage.insertDevTodos()       ; Typical dev list of todo sub-items
	:*X:.sudo::   OneNoteTodoPage.insertDevSUTodos()     ; Typical dev SU list of todo sub-items
	:*X:.pqado::  OneNoteTodoPage.insertPQATodos()       ; Typical PQA list of todo sub-items
	
	; Update links for a dev structure section header
	!+#n::OneNote.linkDevStructureSectionTitle()
#If
