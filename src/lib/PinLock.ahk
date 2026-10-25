/*
Script            : AutoHotkey-Typer - PinLock
FileName          : PinLock.ahk
Author            : Philippe Addelia
Created           : 2026-10-25 12:50 EDT
Modified          : 2026-10-25 12:50 EDT
Preferred Location: src\lib\
Version           : 1.6
Purpose           : Optional secret lock (1.6).
                    After the user has been away (no keyboard or mouse use
                    for N minutes), the next secret asks for a PIN once.
                    Unlocking Windows (after Win + L) also counts as proof
                    of identity, so no PIN is asked then.
                    Plain snippets are never locked.

                    The PIN is never stored: only a salted PBKDF2-SHA256
                    hash (Windows BCrypt, 600,000 iterations) is kept, in
                    the [~AHK-Typer] section of the snippet file.

                    This is a gate against a casual person at an unlocked
                    PC, not encryption - see docs\setup-and-security.md.
*/

global LOCK_SECTION    := "~AHK-Typer"     ; settings section in snippets.ini
global LOCK_ITERATIONS := 600000
global SecretLock := {Enabled: false, Locked: false, Minutes: 15, Hash: ""
    , Fails: 0, BlockedUntil: 0}

; ---------------------------------------------------------------------
;  Start-up: read the settings, start the away timer, listen for
;  Windows lock / unlock
; ---------------------------------------------------------------------
InitSecretLock() {
    SecretLock.Hash    := Trim(IniRead(ConfigFile, LOCK_SECTION, "PinHash", ""))
    SecretLock.Minutes := ClampMinutes(IniRead(ConfigFile, LOCK_SECTION, "LockMinutes", "15"))
    SecretLock.Enabled := (SecretLock.Hash != "")
    SecretLock.Locked  := false              ; you just signed in to Windows
    if !SecretLock.Enabled
        return
    SetTimer(CheckAway, 5000)
    ; WM_WTSSESSION_CHANGE for this session only (NOTIFY_FOR_THIS_SESSION = 0)
    try DllCall("Wtsapi32\WTSRegisterSessionNotification", "Ptr", A_ScriptHwnd, "UInt", 0)
    OnMessage(0x02B1, OnSessionChange)
}

ClampMinutes(v) {
    v := Trim(v)
    return IsInteger(v) ? Min(Max(Integer(v), 1), 240) : 15
}

; Away = no keyboard or mouse input for N minutes (A_TimeIdle)
CheckAway() {
    if (SecretLock.Enabled && !SecretLock.Locked
            && A_TimeIdle >= SecretLock.Minutes * 60000)
        SetSecretLock(true)
}

; WTS_SESSION_UNLOCK (8): Windows has just verified the user - unlock too
OnSessionChange(wParam, lParam, msg, hwnd) {
    if (wParam = 8 && SecretLock.Enabled)
        SetSecretLock(false)
}

SetSecretLock(locked) {
    SecretLock.Locked := locked
    UpdateTrayTip()
}

; ---------------------------------------------------------------------
;  Called by TypeSecret before typing. Returns true when the secret may
;  be typed. While locked, asks for the PIN, then puts the focus back on
;  the window the user was typing in.
; ---------------------------------------------------------------------
EnsureSecretUnlocked(name) {
    if (!SecretLock.Enabled || !SecretLock.Locked)
        return true
    target := WinExist("A")
    if !PromptPin(name)
        return false
    if target {
        try {
            WinActivate("ahk_id " target)
            WinWaitActive("ahk_id " target, , 2)
        }
    }
    return true
}

; Small modal box. Returns true on a correct PIN.
PromptPin(name) {
    result := {ok: false}
    g := Gui("+AlwaysOnTop -MinimizeBox +ToolWindow", APP_NAME " - secrets locked")
    g.SetFont("s10", "Segoe UI")
    g.MarginX := 14, g.MarginY := 12
    g.Add("Text", "xm w300", "You have been away. Enter your PIN to type [" name "].")
    ed := g.Add("Edit", "xm y+10 w300 Password")
    msg := g.Add("Text", "xm y+6 w300 cC00000", "")
    bt := g.Add("Button", "xm y+8 w90 Default", "OK")
    g.Add("Button", "x+10 yp w90", "Cancel").OnEvent("Click", (*) => g.Destroy())
    g.OnEvent("Escape", (*) => g.Destroy())
    g.OnEvent("Close", (*) => g.Destroy())
    bt.OnEvent("Click", TryPin)
    g.Show("AutoSize")
    ed.Focus()
    WinWaitClose("ahk_id " g.Hwnd)
    return result.ok

    TryPin(*) {
        if (A_TickCount < SecretLock.BlockedUntil) {
            msg.Text := "Too many attempts - wait "
                . Ceil((SecretLock.BlockedUntil - A_TickCount) / 1000) " s."
            return
        }
        pin := ed.Value
        ed.Value := ""
        msg.Text := "Checking..."
        if VerifyPin(pin, SecretLock.Hash) {
            pin := ""
            SecretLock.Fails := 0
            SetSecretLock(false)
            result.ok := true
            g.Destroy()
            return
        }
        pin := ""
        SecretLock.Fails++
        Sleep(1000)                          ; slows down guessing
        if (SecretLock.Fails >= 5) {
            SecretLock.Fails := 0
            SecretLock.BlockedUntil := A_TickCount + 60000
            msg.Text := "Wrong PIN. Too many attempts - wait 60 s."
        } else {
            msg.Text := "Wrong PIN."
        }
        ed.Focus()
    }
}

; ---------------------------------------------------------------------
;  Settings dialog: tray > Secret lock...
; ---------------------------------------------------------------------
ShowLockDialog(*) {
    static dlg := {open: 0}            ; property, so nested Close() can reset it
    if (dlg.open && WinExist("ahk_id " dlg.open)) {
        WinActivate("ahk_id " dlg.open)
        return
    }
    hasPin := (SecretLock.Hash != "")
    W := 380
    g := Gui("+AlwaysOnTop -MinimizeBox", APP_NAME " - Secret lock")
    dlg.open := g.Hwnd
    g.SetFont("s10", "Segoe UI")
    g.MarginX := 14, g.MarginY := 12

    g.Add("Text", "xm w" W
        , "Optional: when you come back after being away, the next secret asks "
        . "for your PIN once. Plain snippets are never locked.")
    ckOn := g.Add("Checkbox", "xm y+12 w" W (hasPin ? " Checked" : "")
        , "Ask for my PIN after I have been away")
    g.Add("Text", "xm+20 y+10", "Away after")
    edMin := g.Add("Edit", "x+6 yp-3 w50 Number Limit3", SecretLock.Minutes)
    g.Add("Text", "x+6 yp+3", "minutes without keyboard or mouse (1 - 240)")

    if hasPin {
        g.Add("Text", "xm+20 y+16 w110", "Current PIN")
        edCur := g.Add("Edit", "x+6 yp-3 w170 Password")
    }
    g.Add("Text", "xm+20 y+12 w110", hasPin ? "New PIN" : "PIN")
    ed1 := g.Add("Edit", "x+6 yp-3 w170 Password")
    g.Add("Text", "xm+20 y+10 w110", "Confirm")
    ed2 := g.Add("Edit", "x+6 yp-3 w170 Password")
    g.Add("Text", "xm+136 y+4 w" (W - 136) " cGray"
        , hasPin ? "Leave both empty to keep the current PIN."
                 : "At least 4 characters.")
    g.Add("Text", "xm y+12 w" W " cGray"
        , "Locking Windows (Win + L) is even better: after you unlock Windows, "
        . "AHK-Typer does not ask for the PIN.")

    btSave := g.Add("Button", "xm y+14 w100 h30 Default", "Save")
    g.Add("Button", "x+10 yp w100 h30", "Cancel").OnEvent("Click", (*) => Close())
    btSave.OnEvent("Click", (*) => Save())
    g.OnEvent("Escape", (*) => Close())
    g.OnEvent("Close", (*) => Close())
    g.Show("AutoSize")
    return

    Close() {
        dlg.open := 0
        g.Destroy()
    }

    Fail(text) {
        MsgBox(text, APP_NAME, "Icon! Owner" g.Hwnd)
    }

    Save() {
        ; changing or switching off the lock needs the current PIN
        if hasPin {
            cur := edCur.Value
            edCur.Value := ""
            if !VerifyPin(cur, SecretLock.Hash)
                return Fail("The current PIN is wrong.")
        }
        minutes := ClampMinutes(edMin.Value)

        if !ckOn.Value {
            try IniDelete(ConfigFile, LOCK_SECTION, "PinHash")
            IniWrite(minutes, ConfigFile, LOCK_SECTION, "LockMinutes")
            Close()
            Reload()
            return
        }

        a := ed1.Value, b := ed2.Value
        ed1.Value := "", ed2.Value := ""
        if (hasPin && a = "" && b = "") {
            newHash := SecretLock.Hash
        } else {
            if (StrLen(a) < 4)
                return Fail("The PIN needs at least 4 characters.")
            if !(a == b)
                return Fail("The two PINs do not match.")
            newHash := HashPin(a)
        }
        a := b := ""
        IniWrite(newHash, ConfigFile, LOCK_SECTION, "PinHash")
        IniWrite(minutes, ConfigFile, LOCK_SECTION, "LockMinutes")
        Close()
        Reload()
    }
}

; ---------------------------------------------------------------------
;  PIN hashing - PBKDF2-HMAC-SHA256 via Windows BCrypt
;  Stored format: pbkdf2-sha256$<iterations>$<base64 salt>$<base64 hash>
; ---------------------------------------------------------------------
HashPin(pin) {
    salt := Buffer(16, 0)
    st := DllCall("bcrypt\BCryptGenRandom", "Ptr", 0, "Ptr", salt, "UInt", 16
        , "UInt", 0x2, "UInt")                ; system preferred RNG
    if (st != 0)
        throw OSError(st, -1, "BCryptGenRandom failed")
    key := Pbkdf2Sha256(pin, salt, 16, LOCK_ITERATIONS, 32)
    return "pbkdf2-sha256$" LOCK_ITERATIONS "$" Base64Encode(salt.Ptr, 16)
        . "$" Base64Encode(key.Ptr, 32)
}

VerifyPin(pin, stored) {
    parts := StrSplit(stored, "$")
    if (parts.Length != 4 || parts[1] != "pbkdf2-sha256" || !IsInteger(parts[2]) || pin = "")
        return false
    try {
        salt := Base64Decode(parts[3], &saltSize)
        want := Base64Decode(parts[4], &wantSize)
        got  := Pbkdf2Sha256(pin, salt, saltSize, Integer(parts[2]), wantSize)
    } catch {
        return false
    }
    diff := 0                                 ; compare every byte
    Loop wantSize
        diff |= NumGet(got, A_Index - 1, "UChar") ^ NumGet(want, A_Index - 1, "UChar")
    return (diff = 0)
}

Pbkdf2Sha256(pin, saltBuf, saltSize, iterations, outSize) {
    hAlg := 0
    st := DllCall("bcrypt\BCryptOpenAlgorithmProvider", "Ptr*", &hAlg
        , "WStr", "SHA256", "Ptr", 0, "UInt", 0x8, "UInt")   ; HMAC flag
    if (st != 0)
        throw OSError(st, -1, "BCryptOpenAlgorithmProvider failed")
    pw  := Utf8Buffer(pin, &pwSize)
    out := Buffer(outSize, 0)
    try {
        st := DllCall("bcrypt\BCryptDeriveKeyPBKDF2", "Ptr", hAlg
            , "Ptr", pw, "UInt", pwSize
            , "Ptr", saltBuf, "UInt", saltSize
            , "Int64", iterations
            , "Ptr", out, "UInt", outSize
            , "UInt", 0, "UInt")
    } finally {
        WipeBuffer(pw)
        DllCall("bcrypt\BCryptCloseAlgorithmProvider", "Ptr", hAlg, "UInt", 0)
    }
    if (st != 0)
        throw OSError(st, -1, "BCryptDeriveKeyPBKDF2 failed")
    return out
}
