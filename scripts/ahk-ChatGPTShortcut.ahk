; Copyright (c) 2025 Michael Hill
; Licensed under the MIT License (see LICENSE file)

;;;
; ChatGPT Window Manager
;
; Description:
;   ChatGPT Window Manager is an AHK 2.x script for easy access to Edge-based
;   websites. This script allows binding keys to opening flexible ChatGPT window ...
;
;   Advantages compared to some other solutions (Logi Options+ ChatGPT window,
;   the ChatGPT app, etc.):
;   - Browser extensions can be used.
;   - Uses shared browser resources.
;   - Browser credentials are saved (only applies to Logi Options+; the ChatGPT app authz flow uses your browser).
;   - Windows can be resized (cannot be resized in Logi Options+).
;   - Pages can be refreshed, caches purged, etc.
;   - Elements can be inspected with Edge DevTools.
;
;   Disadvantages:
;   - Restricted to features available on the web version of ChatGPT.
;   - Maintenance is your own responsibility if issues occur.
;   - Requires AHK 2.x.
;
;   While this has been originally created for ChatGPT specifically, this simply
;   uses a Microsoft Edge "app" window and can be adapted for any website.
;   desired. Additionally, while tested only on Edge, this is expected to
;   function similarly on all Chromium-based browsers.
;
; Usage:
;   ...
;
; Common use cases:
;   - Bind to a mouse or keyboard key (or both) for quick navigation to ChatGPT.
;   - Change the "app" from ChatGPT to another site of your preference.
;   - Open multiple windows for the target app side-by-side for parallel conversations.
;;;

#SingleInstance Force
#Include %A_ScriptDir%\ahk-Debugger.ahk
#Include %A_ScriptDir%\ahk-Util.ahk
; #MaxThreads 1 ; Disallow concurrent hotkey presses -- disabled to allow aggregate scripts to include this one

global g_KeysEnabled := True ; Global flag to enable/disable key bindings

global windows := []
global currentWinIdx := -1
global DefaultWidth := 1000
global DefaultHeight := 700
global WinOpenDelayMs := 500
global ScreenPadding := 20 ; The distance from the screen bottom and right to preserve when positioning windows
global ExePath := "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
global ExeName := "msedge.exe"
global ExeParams := '--app="https://chatgpt.com"'
global DebugEnabled := False

global WS_VISIBLE :=        0x10000000 ; E.g., after WinShow
global WS_EX_TOPMOST :=     0x00000008 ; Always-on-top
global WS_EX_TRANSPARENT := 0x00000020 ; Click-through
global WS_EX_TOOLWINDOW :=  0x00000080 ; Hide from toolbar
global WS_EX_APPWINDOW :=   0x00040000 ; App window (unable to be hidden from toolbar)

; Clear log file on start-up
if (FileExist("debug_log.txt")) {
    FileDelete("debug_log.txt")
}

; Recover any windows from prior instances
DisplayHiddenWindows("RECOVERY")

; Key bindings
#HotIf g_KeysEnabled
F14::ActivateCurrentWindow()                ; F14                   : Pop-up/hide the current window
<^F14::CreateNewWindow()                    ; LCtrl + F14           : Create an additional window
<+F14::CycleNextWindow()                    ; LShift + F14          : Cycle between existing windows
<!F14::DisplayHiddenWindows("SHOW_ONLY")    ; LAlt + F14            : Display all trackedwindows
<^<!F14::DisplayHiddenWindows("RESET")      ; LCtrl + LAlt + F14    : Detach all tracked windows
#HotIf
>^F14::ToggleKeyBindings()                  ; RCtrl + F14           : Toggle key bindings

; Functions
ActivateCurrentWindow() {
    CleanUpWindows()
    if (currentWinIdx = -1) {
        Log("ActivateCurrentWindow: No window present. Creating new window.")
        CreateNewWindow()
    } else {
        hwnd := windows[currentWinIdx]
        if (WinIsActive(hwnd)) {
            Log("ActivateCurrentWindow: Window is active. Deactivating.")
            DeactivateWindow(hwnd)
        } else {
            Log("ActivateCurrentWindow: Window is not active. Activating.")
            ActivateWindow(currentWinIdx)
        }
    }
}

; Creates a new window
CreateNewWindow() {
    global currentWinIdx

    ; Disable always-on-top so that "new" window is top-most to allow order-based detection
    alwaysOnTopHwnds := DisableAlwaysOnTopWindows()
    existingHwnds := WinGetList("ahk_exe" ExeName) ; Identify pre-existing windows to be ignored for order-based detecgtion

    ; Open window
    Log("CreateNewWindow: Running executable with specified parameters.")
    Run(ExePath " " ExeParams, , , &pid) ; Empty working directory and additional options, store PID in pid
    Sleep(WinOpenDelayMs)

    ; Get new window
    hwnds := WinGetList("ahk_exe" ExeName) ; Order: Top-most to bottom-most
    hwnd := 0
    for (foundHwnd in hwnds) {
        isNewHwnd := True
        for (existingHwnd in existingHwnds) {
            if (foundHwnd = existingHwnd) {
                isNewHwnd := False
                break
            }
        }
        if (isNewHwnd) {
            hwnd := foundHwnd
            break
        }
    }
    if (!hwnd) {
        Log("CreateNewWindow: Unable to find handle for new window."
            " Discovered window handles: " ArrayToString(hwnds) "."
            " Known window handles: " ArrayToString(windows) ".")
        MsgBox("An error occurred while detecting the new window.")
        return
    }
    Log("CreateNewWindow: Window created successfully with handle " hwnd ".")
    for (winHwnd in alwaysOnTopHwnds) {
        ; Re-enable always-on-top for prior windows if present
        WinSetAlwaysOnTop(1, winHwnd)
    }

    ; Store the window handle and update the current window index
    windows.Push(hwnd)
    CleanUpWindows()
    currentWinIdx := windows.length
    Log("CreateNewWindow: Stored new window handle: " hwnd ". Total windows: " windows.length ". Current window index: " currentWinIdx ".")

    ; Set window properties
    WinSetExStyle("-" WS_EX_APPWINDOW, hwnd) ; Ensure windows are *allowed* to be hidden from the task bar
    WinSetExStyle("+" WS_EX_TOOLWINDOW, hwnd) ; Hide from task bar
    UpdateWindowPosition(hwnd, "MOUSE", "MOUSE", DefaultWidth, DefaultHeight, True) ; Update size and position
    WinSetAlwaysOnTop(True, hwnd)
    ActivateWindow(currentWinIdx)
    Log("CreateNewWindow: Window activated.")
}

; Cycles between all recognized active windows
CycleNextWindow() {
    global currentWinIdx

    CleanUpWindows()
    numWindows := windows.length
    if (numWindows = 0) {
        Log("CycleNextWindow: No windows exist. Doing nothing.")
        return
    }

    hwnd := windows[currentWinIdx]
    if (!WinIsActive(hwnd)) {
        Log("CycleNextWindow: Window not yet active. Activating.")
        ActivateWindow(currentWinIdx)
    } else if (numWindows = 1) {
        Log("CycleNextWindow: Only one window exists and is already active. Doing nothing.")
    } else {
        ; DeactivateWindow(hwnd) ; Disabled; just make new window visible, do not hide existing
        nextWinIdx := currentWinIdx + 1
        if (nextWinIdx > windows.length) {
            nextWinIdx := 1
        }
        Log("CycleNextWindow: Cycling to next window at index " nextWinIdx ".")
        ActivateWindow(nextWinIdx)
    }
}

WinIsActive(hwnd) {
    Log("WinIsActive: "
        "WinActive: " (WinActive(hwnd) = hwnd)
        "WinGetMinMax: " WinGetMinMax(hwnd)
        "; WinGetTransparent: " (WinGetTransparent(hwnd) = "")
        "; WS_EX_TRANSPARENT: " ((WinGetExStyle(hwnd) & WS_EX_TRANSPARENT) = 0))
    return WinActive(hwnd) = hwnd
        && WinGetMinMax(hwnd) != -1
        && WinGetTransparent(hwnd) = ""
        && (WinGetExStyle(hwnd) & WS_EX_TRANSPARENT) = 0
}

DeactivateWindow(hwnd) {
    WinSetExStyle("+" WS_EX_TRANSPARENT, hwnd)
    WinSetTransparent(0, hwnd)
}

ActivateWindow(idx) {
    global currentWinIdx
    hwnd := windows[idx]
    Log("ActivateWindow: Activating window at index " idx " with handle " hwnd ".")
    ; if (!WinIsActive(hwnd)) {
        ; UpdateWindowPosition(hwnd, "MOUSE", "MOUSE", , , True)
    ; }
    WinSetExStyle("-" WS_EX_TRANSPARENT, hwnd)
    WinSetTransparent("Off", hwnd)
    WinActivate(hwnd)
    currentWinIdx := idx
}

UpdateWindowPosition(hwnd, posX?, posY?, width?, height?, centerOffset := False) {
    ; Restore window to ensure appropriate dimensions exist and allow adjustments
    if (WinGetMinMax(hwnd) = -1) {
        WinRestore(hwnd)
    }

    ; Get target position and dimensions
    WinGetPos(&curX, &curY, &curWidth, &curHeight)
    prevCoordMode := A_CoordModeMouse
    CoordMode("Mouse", "Screen")
    MouseGetPos(&mouseX, &mouseY)
    CoordMode("Mouse", prevCoordMode)
    newWidth := width ?? curWidth
    newHeight := height ?? curHeight
    newX := !IsSet(posX) ? curX
        : posX = "MOUSE" ? mouseX
        : posX
    newY := !IsSet(posY) ? curY
        : posY = "MOUSE" ? mouseY
        : posY

    ; Use center of window instead of upper-left corner
    if (centerOffset) {
        newX := newX - (newWidth / 2)
        newY := newY - (newHeight / 2)
    }

    ; Ensure window within screen bounds (note: no longer required in many cases)
    isInBounds := False
    for screen in GetScreenBoundaries() {
        if (newX >= screen.Left && newX < screen.Right && newY >= screen.Top && newY < screen.Bottom) {
            ; Screen boundaries satisfied; end check
            isInBounds := True
            Log("UpdateWindowPosition: Is in bounds for screen " screen.Index)
            break
        }
    }
    if (!isInBounds) {
        ; Move to nearest bounds
        targetScreenHeuristic := 1.0e308
        targetScreenIndex := -1
        origNewX := newX
        origNewY := newY
        for screen in GetScreenBoundaries() {
            ; Heuristic for target screen: closest screen to point
            h := 1.0e308
            if (origNewX >= screen.Left && origNewX < screen.Right) {
                if (origNewY < screen.Top) {
                    Log("UpdateWindowPosition: Screen: " screen.Index ". x: In range. y: Above screen.")
                    h := screen.Top - origNewY
                    proposedX := origNewX
                    proposedY := screen.Top
                } else if (origNewY >= screen.Bottom) {
                    Log("UpdateWindowPosition: Screen: " screen.Index ". x: In range. y: Below screen.")
                    h := origNewY - screen.Bottom
                    proposedX := origNewX
                    proposedY := screen.Bottom - ScreenPadding
                } else {
                    throw Error("UpdateWindowPosition: Unexpected state during bounds calculation."
                        " {origNewX: " origNewX ", origNewY: " origNewY
                        ", left: " screen.Left ", top: " screen.Top
                        ", right: " screen.Right ", bottom: " screen.Bottom "}")
                }
            } else if (origNewY >= screen.Top && origNewY < screen.Bottom) {
                if (origNewX < screen.Left) {
                    Log("UpdateWindowPosition: Screen: " screen.Index ". x: Left of screen. y: In range.")
                    h := screen.Left - origNewX
                    proposedX := screen.Left
                    proposedY := origNewY
                } else if (origNewX >= screen.Right) {
                    Log("UpdateWindowPosition: Screen: " screen.Index ". x: Right of screen. y: In range.")
                    h := origNewX - screen.Right
                    proposedX := screen.Right - ScreenPadding
                    proposedY := origNewY
                } else {
                    throw Error("UpdateWindowPosition: Unexpected state during bounds calculation."
                        " {origNewX: " origNewX ", origNewY: " origNewY
                        ", left: " screen.Left ", top: " screen.Top
                        ", right: " screen.Right ", bottom: " screen.Bottom "}")
                }
            } else {
                ; Find nearest corner
                Log("UpdateWindowPosition: Screen: " screen.Index ". Finding nearest corner.")
                nearestXSide := (screen.Left - origNewX) < (screen.Right - origNewX) ? -1 : 1 ; Left/right
                nearestYSide := (screen.Top - origNewY) < (screen.Bottom - origNewY) ? -1 : 1 ; Top/bottom
                Log("UpdateWindowPosition: Screen: " screen.Index "."
                    " nearestXSide: " nearestXSide " (" origNewX ", " screen.Left ", " screen.Right ")."
                    " nearestYSide: " nearestYSide " (" origNewY ", " screen.Top ", " screen.Bottom ").")
                proposedX := nearestXSide = -1 ? screen.Left : (screen.Right - ScreenPadding)
                proposedY := nearestYSide = -1 ? screen.Top : (screen.Bottom - ScreenPadding)
                h := Sqrt(
                    ((nearestXSide = -1 ? screen.Left : screen.Right) - origNewX)**2
                    + ((nearestYSide = -1 ? screen.Top : screen.Bottom) - origNewY)**2
                )
            }
            if (h < targetScreenHeuristic) {
                targetScreenHeuristic := h
                targetScreenIndex := screen.Index
                newX := proposedX
                newY := proposedY
                Log("UpdateWindowPosition: Screen: " screen.Index ". Heuristic is new minimum. h: " h ". newX: " newX ". newY: " newY ".")
            } else {
                Log("UpdateWindowPosition: Screen: " screen.Index ". Heuristic worse than prior. h: " h ".")
            }
        }
        Log("UpdateWindowPosition: Moving from (" origNewX ", " origNewY ") to screen " targetScreenIndex " at (" newX ", " newY ").")
    }

    ; Move window
    WinMove(newX, newY, newWidth, newHeight, hwnd)
    Log("UpdateWindowPosition: (" hwnd ")"
        " Position: (" newX ", " newY ")."
        " Size: (" newWidth ", " newHeight ").")
}

; Refresh windows and currentWinIdx values
CleanUpWindows() {
    global currentWinIdx
    idx := 1
    while (idx <= windows.length) {
        hwnd := windows[idx]
        if (!WinExist(hwnd)) {
            ; Remove nonexistent windows
            windows.RemoveAt(idx)
            if (currentWinIdx >= idx) {
                currentWinIdx--
            }
        } else if (WinActive(hwnd) = hwnd) {
            ; Update active window if switched
            currentWinIdx := idx
            idx++
        } else {
            idx++
        }
    }
    if (windows.length = 0) {
        currentWinIdx := -1
    } else {
        ; Ensure currentWinIdx is within valid range
        if (currentWinIdx < 1) {
            currentWinIdx := 1
        }
        if (currentWinIdx > windows.length) {
            currentWinIdx := windows.length
        }
    }
}

; Disable always-on-top windows and return the list of HWNDs if re-enabling later is desired.
; This can be useful if, for example, the caller wishes to start a new process and identify it as the first (i.e., top-most) window in WinGetList.
DisableAlwaysOnTopWindows() {
    currentHwnds := WinGetList("ahk_exe" ExeName)
    alwaysOnTopHwnds := []
    idx := currentHwnds.length
    while (idx >= 1) {
        hwnd := currentHwnds[idx--]
        if (WinGetExStyle(hwnd) & WS_EX_TOPMOST) {
            alwaysOnTopHwnds.Push(hwnd)
            WinSetAlwaysOnTop(False, hwnd)
        }
    }
    return alwaysOnTopHwnds
}

; Display all hidden windows
DisplayHiddenWindows(mode := "RECOVERY") {
    winFilter := "ahk_exe" ExeName
    clearWindowList := False
    disableToolWindow := False
    Switch mode {
        case "FULL":
            ; DANGER: This will impact many windows which are *not* intended to be shown
            winFilter := ""
            disableToolWindow := True
        case "RECOVERY":
            disableToolWindow := True
        case "SHOW_ONLY":
            ; Use defaults
        case "RESET":
            clearWindowList := True
            disableToolWindow := True
        DEFAULT:
            throw Error("DisplayHiddenWindows: Mode unrecognized: " mode ". A valid mode must be specified.")
    }
    origDetectHiddenWindows := A_DetectHiddenWindows
    DetectHiddenWindows(True)
    for hwnd in WinGetList(winFilter) {
        try {
            title := WinGetTitle(hwnd)
            pid := WinGetPID(hwnd)
            proc := WinGetProcessName(hwnd)
            isVisible := (WinGetStyle(hwnd) & WS_VISIBLE) != 0
            isTransparent := WinGetTransparent(hwnd) = "" ? False : WinGetTransparent(hwnd) < 255
            isClickThrough := (WinGetExStyle(hwnd) & WS_EX_TRANSPARENT) != 0
            isToolWindow := (WinGetExStyle(hwnd) & WS_EX_TOOLWINDOW) != 0
            isMinimized := WinGetMinMax(hwnd) = -1
            Log("DisplayHiddenWindows:"
                " Hwnd: " hwnd
                "; PID: " pid
                "; proc: " proc
                "; title:" title
                "; isVisible: " isVisible
                "; isTransparent: " isTransparent " (" WinGetTransparent(hwnd) ")"
                "; isClickThrough: " isClickThrough
                "; isToolWindow: " isToolWindow
                "; isMinimized: " isMinimized)
            if (!isVisible || isTransparent || !isClickThrough) {
                if (isTransparent) {
                    WinSetTransparent("Off", hwnd)
                }
                if (isClickThrough) {
                    WinSetExStyle("-" WS_EX_TRANSPARENT, hwnd)
                }
                if (disableToolWindow) {
                    WinSetExStyle("-" WS_EX_TOOLWINDOW, hwnd)
                }
                if (isMinimized) {
                    WinRestore(hwnd)
                }
            }
        } catch as e {
            Log("DisplayHiddenWindows: Error occurred: " e.Message)
        }
    }
    if (clearWindowList) {
        while (windows.length) {
            windows.Pop()
        }
    }
    DetectHiddenWindows(origDetectHiddenWindows)
}

; Gets the boundary values for all screens
GetScreenBoundaries() {
    screens := []
    screenCount := MonitorGetCount()
    idx := 0
    while (++idx <= screenCount) {
        MonitorGetWorkArea(idx, &left, &top, &right, &bottom)
        screens.Push({
            Index: idx,
            Left: left,
            Top: top,
            Right: right,
            Bottom: bottom
        })
    }
    return screens
}

ToggleKeyBindings() {
    global g_KeysEnabled
    g_KeysEnabled := !g_KeysEnabled
    if (g_KeysEnabled) {
        ShowTooltip("Key bindings enabled.", 1000)
        Log("Key bindings enabled.")
    } else {
        ShowTooltip("Key bindings disabled.", 1000)
        Log("Key bindings disabled.")
    }
}

ArrayToString(arr, delimiter := ", ") {
    result := ""
    if (arr.length > 0) {
        for index, value in arr {
            result .= value . delimiter
        }
        ; Remove trailing delimiter
        result := SubStr(result, 1, StrLen(result) - StrLen(delimiter))
    }
    return result
}
