/*
Script            : AutoHotkey-Typer - Engine
FileName          : Engine.ahk
Author            : Philippe Addelia
Created           : 2026-10-24 13:45 EDT
Modified          : 2026-10-25 12:55 EDT
Preferred Location: src\lib\
Version           : 1.6
Purpose           : Binds snippets to hotkeys / hotstrings and types them.
                    Secrets stay encrypted in memory and are decrypted only
                    at the moment they are typed.
                    1.0.3 : Window= accepts several rules separated by |
                    1.6   : secrets ask for the PIN first when the optional
                            secret lock is on and the user was away
                    1.3   : login sequence - username, Tab/Enter, secret,
                            optional Enter
*/

; ---------------------------------------------------------------------
;  Register every snippet. Returns { Count, Errors, Warnings }.
;  Count = number of triggers (hotkeys + hotstrings) bound.
; ---------------------------------------------------------------------
RegisterSnippets(snippets) {
    errors   := []
    warnings := []
    count    := 0
    seen     := Map()           ; normalized trigger + window -> snippet name
    seen.CaseSense := false

    for s in snippets {
        action := (s.IsSecret
            ? TypeSecret.Bind(s.Secret, s.Name, s.Login)
            : TypeSnippet.Bind(s.Text))
        SetWindowContext(s.Window)

        if (s.Hotkey != "") {
            id := "HK|" NormalizeHotkey(s.Hotkey) "|" s.Window
            issues := CheckHotkey(s.Hotkey)
            if HasBlock(issues) {
                errors.Push(FormatIssues(s.Name, s.Hotkey, issues) " - skipped")
            } else if seen.Has(id) {
                errors.Push("[" s.Name "] hotkey " s.Hotkey " is already used by ["
                    seen[id] "] - skipped")
            } else {
                try {
                    Hotkey(s.Hotkey, action, "On")
                    seen[id] := s.Name
                    count++
                    if (issues.Length && !s.AllowRisky)
                        warnings.Push(FormatIssues(s.Name, s.Hotkey, issues))
                } catch as err {
                    errors.Push("[" s.Name "] hotkey " s.Hotkey " is not valid - "
                        err.Message)
                }
            }
        }

        if (s.Hotstring != "") {
            id := "HS|" s.Hotstring "|" s.Window
            if seen.Has(id) {
                errors.Push("[" s.Name "] hotstring " s.Hotstring " is already used by ["
                    seen[id] "] - skipped")
            } else {
                try {
                    ; * = fire right away, no space or Enter needed after it
                    Hotstring(":*:" s.Hotstring, action, "On")
                    seen[id] := s.Name
                    count++
                } catch as err {
                    errors.Push("[" s.Name "] hotstring " s.Hotstring " is not valid - "
                        err.Message)
                }
            }
        }
    }

    HotIf()                     ; back to global context
    return {Count: count, Errors: errors, Warnings: warnings}
}

; Types the text literally - no AutoHotkey escaping, never uses the clipboard
TypeSnippet(text, *) {
    SendText(text)
}

; Decrypts just in time, types, then drops the plain text right away.
; With a login (1.3): username, Tab or Enter, secret, optional Enter.
TypeSecret(encrypted, name, login, *) {
    if !EnsureSecretUnlocked(name)          ; optional secret lock (1.6)
        return
    try {
        plain := DpapiUnprotect(encrypted)
    } catch {
        TrayTip("Could not decrypt [" name "]. Add the secret again.", APP_NAME, "Iconx")
        return
    }
    WaitForModifiers()
    if (login.User != "") {
        SendText(login.User)
        Sleep(login.Delay)
        Send(login.Sep = "Enter" ? "{Enter}" : "{Tab}")
        Sleep(login.Delay)
    }
    SendText(plain)
    plain := ""
    if login.Submit {
        Sleep(login.Delay)
        Send("{Enter}")
    }
}

; Wait until Ctrl / Alt / Shift / Win from the hotkey are released, so Tab
; and Enter are not sent as Ctrl+Tab or Alt+Enter (at most 1 s per key)
WaitForModifiers() {
    for k in ["Ctrl", "Alt", "Shift", "LWin", "RWin"]
        KeyWait(k, "T1")
}

; ---------------------------------------------------------------------
;  Window restriction: one cached criterion per distinct Window= value
; ---------------------------------------------------------------------
SetWindowContext(win) {
    static cache := Map()
    if (win = "") {
        HotIf()
        return
    }
    if !cache.Has(win)
        cache[win] := MakeWindowCheck(win)
    HotIf(cache[win])
}

; Window= may list several rules:  Connect ahk_exe Ssms.exe | ahk_exe mstsc.exe
; The snippet is active when ANY of them matches the active window.
MakeWindowCheck(win) {
    rules := SplitWindowRules(win)
    return (*) => AnyWindowActive(rules)
}

AnyWindowActive(rules) {
    for r in rules
        if WinActive(r)
            return true
    return false
}

SplitWindowRules(win) {
    rules := []
    for r in StrSplit(win, "|")
        if (Trim(r) != "")
            rules.Push(Trim(r))
    return rules
}

; ---------------------------------------------------------------------
;  Normalize a hotkey so "!^E" and "^!e" are seen as the same trigger.
;  Prefix flags ~ * $ do not change which keys are pressed, so drop them.
;  Left/right markers (< >) depend on order, so those are kept as typed.
; ---------------------------------------------------------------------
NormalizeHotkey(hk) {
    mods := ""
    i := 1
    while (i <= StrLen(hk) && InStr("~*$<>^!+#", SubStr(hk, i, 1)))
        mods .= SubStr(hk, i, 1), i++
    key  := StrLower(SubStr(hk, i))
    mods := StrReplace(StrReplace(StrReplace(mods, "~"), "*"), "$")

    if !(InStr(mods, "<") || InStr(mods, ">")) {
        sorted := ""
        for m in ["^", "!", "+", "#"]
            if InStr(mods, m)
                sorted .= m
        mods := sorted
    }
    return mods key
}
