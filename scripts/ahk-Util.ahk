; Copyright (c) 2025 Michael Hill
; Licensed under the MIT License (see LICENSE file)

#Requires AutoHotkey v2.0+
#SingleInstance Force

; Opens the given application, acquiring or minimizing the window if it is already open.
OpenApp(appName, appPath, winPattern) {
    origTitleMatchMode := A_TitleMatchMode
    SetTitleMatchMode("RegEx")
    hwnd := WinExist(winPattern)
    SetTitleMatchMode(origTitleMatchMode)
    if (hwnd) {
        if (WinActive(hwnd) = hwnd) {
            WinMinimize(hwnd)
        } else {
            WinActivate(hwnd)
            WinMoveTop(hwnd)
        }
    } else {
        LaunchApp(appName, appPath)
    }
}

; Opens the given application, displaying a tooltip on success or failure.
LaunchApp(appName, appPath) {
    try {
        Run(appPath)
        ShowTooltip("Launching " appName, 1000)
    } catch as e {
        ShowTooltip("Failed to launch " appName ": " e.Message, 3000)
    }
}

; Shows a tooltip with the given message for the specified duration (default is 1000 ms).
ShowTooltip(message, duration := 1000) {
    ToolTip(message)
    SetTimer(() => ToolTip(), -duration)
}