; Copyright (c) 2025 Michael Hill
; Licensed under the MIT License (see LICENSE file)

#Requires AutoHotkey v2.0
#SingleInstance Force

global DebugEnabled := false

; Logs the given message
Log(message) {
    if (DebugEnabled) {
        try {
            timestamp := FormatTime(, "yyyy-MM-dd HH:mm:ss")
            FileAppend(timestamp ": " message "`n", A_ScriptName . ".log")
        } catch as e {
            ; Swallow
        }
    }
}

; Returns a string with details about the specified hwnd.
DebugWinGetDetails(hwnd) {
    return "Hwnd: [" . hwnd . "]."
            . " Title: [" . WinGetTitle(hwnd) . "]."
            . " Class: [" . WinGetClass(hwnd) . "]."
            . " Exe: [" . WinGetProcessName(hwnd) . "]."
}
