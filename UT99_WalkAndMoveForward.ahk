; ============================================================
; UT99_WalkAndMoveForward.ahk  -  AutoHotkey v1
;
; Tap-to-autorun for Unreal Tournament 99.
;
;   * Tap Mouse4 (XButton1) once  -> start walking forward (hands-free)
;   * Tap Mouse4 again            -> stop
;   * Press any movement / action key -> cancels autorun immediately
;
; HOW IT WORKS
;   UT99's forward movement (Axis aBaseY) only applies while a key is
;   physically held, so a single tap cannot create lasting movement on
;   its own.  This script bridges that gap: on a Mouse4 tap it physically
;   holds down the BACKSPACE key for you.  In User.ini, Backspace is bound
;   to the "Walking" alias (Button bRun | Axis aBaseY Speed=+300.0), so the
;   game keeps walking forward until the script releases Backspace again.
;
;   You never press Backspace yourself - it is purely the channel between
;   this script and the game.
;
; WHY THE REPEAT TIMER (up+down re-press, via keybd_event)
;   The forward Axis (aBaseY) responds to the key's held STATE, so a
;   single injected key-down keeps you moving forward.  But the walk
;   modifier "Button bRun" is driven by the keyboard AUTO-REPEAT STREAM -
;   a continuous flow of key-down events.  A single injected key-down
;   gives only ~1 second of bRun, after which walk decays back to run.
;
;   The catch: Windows de-duplicates a redundant key-DOWN injected while
;   the key is already down (no new WM_KEYDOWN is posted), so simply
;   re-sending {down} on a timer does nothing - bRun still decays.  To
;   force a genuine fresh key-down, the timer briefly releases and
;   re-presses the key (UP then DOWN) every cycle.  The release lasts
;   only microseconds - far shorter than a game frame - so forward
;   movement stays smooth, while each cycle re-arms bRun.
;
; ELEVATION
;   UT is launched elevated by UT_Launcher.ahk.  A non-elevated process
;   cannot send input to an elevated window (Windows UIPI), so this script
;   must also run elevated.  When started from the (already elevated)
;   launcher it inherits the admin token silently.  When run standalone it
;   self-elevates, producing one UAC prompt.
;
; SCOPE
;   Hotkeys are active only while Unreal Tournament is the foreground
;   window, so Mouse4 and the cancel keys behave normally everywhere else.
; ============================================================

#NoEnv
#SingleInstance Force
#Persistent
SetBatchLines, -1
SendMode Event          ; reliable key up/down hold for games
SetKeyDelay, -1

; --- Self-elevate via UAC if not already admin (AHK v1 method) ----------
if not A_IsAdmin {
    Run *RunAs "%A_AhkPath%" "%A_ScriptFullPath%"
    ExitApp
}

; The in-game key that User.ini binds to the "Walking" alias.
; To use a different key, change this name only - the virtual-key/scan
; code and extended-key flag below are derived from it automatically.
; NOTE: use a NON-EXTENDED key.  Extended keys (Insert, Home, End, the
; arrows, etc. - those sending an E0 scancode prefix) appear to break
; UT's Button bRun handling, dropping walk after ~1s while forward keeps
; working.  Backspace is non-extended.
WALK_KEY := "Backspace"

WALK_VK  := GetKeyVK(WALK_KEY)              ; e.g. 0x08 for Backspace
WALK_SC  := GetKeySC(WALK_KEY) & 0xFF       ; low byte of the scan code
WALK_EXT := (GetKeySC(WALK_KEY) & 0x100) ? 1 : 0   ; 1 if extended key (Insert is)

autorun := false

; Make sure the walk key is never left stuck down when the script exits.
OnExit("ReleaseOnExit")

; ============================================================
; HOTKEYS - active only when Unreal Tournament is the active window
; ============================================================
#IfWinActive ahk_exe UnrealTournament.exe

; --- Toggle autorun on / off -------------------------------------------
XButton1::
    if (autorun)
        StopAutorun()
    else
        StartAutorun()
return

; --- Any of these keys cancels autorun ---------------------------------
; Covers every movement / combat / weapon key in the current User.ini.
; Add or remove keys here to taste.  The leading ~ lets the keypress
; still reach the game as normal.
~LButton::
~RButton::
~MButton::
~WheelUp::
~WheelDown::
~w::
~a::
~s::
~d::
~e::
~q::
~r::
~t::
~f::
~v::
~b::
~c::
~x::
~z::
~g::
~y::
~Space::
~LAlt::
~RAlt::
~LCtrl::
~RCtrl::
~LShift::
~RShift::
~Tab::
~1::
~2::
~3::
~4::
~5::
~6::
~7::
~8::
~9::
~0::
~Left::
~Right::
~Up::
~Down::
    if (autorun)
        StopAutorun()
return

#IfWinActive

; ============================================================
; FUNCTIONS
; ============================================================
StartAutorun() {
    global autorun
    autorun := true
    WalkKeyDown()
    SetTimer, RepeatWalkKey, 100   ; re-press periodically so Button bRun stays active
}

StopAutorun() {
    global autorun
    SetTimer, RepeatWalkKey, Off
    autorun := false
    WalkKeyUp()
}

; Re-presses the walk key 10x/sec while autorun is on (brief up+down forces
; a genuine fresh key-down past Windows' injected-key-down de-duplication).
; Auto-cancels if UT loses focus so the key isn't spammed into other windows.
RepeatWalkKey:
    if !WinActive("ahk_exe UnrealTournament.exe") {
        StopAutorun()
        return
    }
    WalkKeyUp()
    WalkKeyDown()
return

; --- Low-level key events via Win32 keybd_event -------------------------
; Forces a real key-down/up every call (AHK's Send would skip a redundant
; key-down while it thinks the key is already held).
WalkKeyDown() {
    global WALK_VK, WALK_SC, WALK_EXT
    DllCall("keybd_event", "UChar", WALK_VK, "UChar", WALK_SC, "UInt", WALK_EXT, "UPtr", 0)
}

WalkKeyUp() {
    global WALK_VK, WALK_SC, WALK_EXT
    DllCall("keybd_event", "UChar", WALK_VK, "UChar", WALK_SC, "UInt", WALK_EXT | 0x2, "UPtr", 0)  ; 0x2 = KEYEVENTF_KEYUP
}

ReleaseOnExit(ExitReason, ExitCode) {
    global autorun
    if (autorun) {
        SetTimer, RepeatWalkKey, Off
        WalkKeyUp()
    }
    return 0
}
