#Requires AutoHotkey v2.0
; Ctrl+Alt+D inserts the current date and time at the cursor
^!d::SendText FormatTime(, "yyyy-MM-dd HH:mm:ss")
