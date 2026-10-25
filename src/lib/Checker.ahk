/*
Script            : AutoHotkey-Typer - Checker
FileName          : Checker.ahk
Author            : Philippe Addelia
Created           : 2026-10-24 14:10 EDT
Modified          : 2026-10-24 14:10 EDT
Preferred Location: src\lib\
Version           : 1.0.2
Purpose           : Flags hotkeys that would break Windows or common
                    application shortcuts.
                      Block - never bound (would break Windows or typing)
                      Warn  - bound, but reported at startup unless the
                              snippet has AllowRisky=1
*/

; ---------------------------------------------------------------------
;  CheckHotkey("^t") -> [ {Level: "Warn", Reason: "..."} , ... ]
;  An empty array means no known conflict.
; ---------------------------------------------------------------------
CheckHotkey(hk) {
    issues := []
    parts  := SplitHotkey(hk)
    mods   := parts.Mods        ; sorted subset of ^ ! + #   e.g. "^!+"
    key    := parts.Key         ; lower case                 e.g. "e"
    combo  := mods key          ; modifiers are always in ^ ! + # order

    ; --- Reserved by Windows: never allowed ----------------------------
    static reserved := Map(
        "!tab",      "Alt + Tab switches windows",
        "!f4",       "Alt + F4 closes the active window",
        "!escape",   "Alt + Esc cycles windows",
        "^escape",   "Ctrl + Esc opens the Start menu",
        "^+escape",  "Ctrl + Shift + Esc opens Task Manager",
        "^!delete",  "Ctrl + Alt + Delete is reserved by Windows",
        "#l",        "Win + L locks the computer",
        "#d",        "Win + D shows the desktop",
        "#e",        "Win + E opens File Explorer",
        "#r",        "Win + R opens the Run box",
        "#tab",      "Win + Tab opens Task View",
        "#v",        "Win + V opens clipboard history",
        "+#s",       "Win + Shift + S takes a screenshot"
    )
    if reserved.Has(combo)
        issues.Push({Level: "Block", Reason: reserved[combo]})

    ; --- A plain character with no modifier (or Shift only) -----------
    if ((mods = "" || mods = "+") && StrLen(key) = 1)
        issues.Push({Level: "Block"
            , Reason: "You could no longer type this character. Add Ctrl, Alt or Win."})

    ; --- Common Ctrl shortcuts -------------------------------------------
    static ctrlKeys := Map(
        "a", "select all",  "b", "bold",          "c", "copy",
        "d", "bookmark / delete line", "e", "search bar",
        "f", "find",        "g", "find next",     "h", "replace / history",
        "i", "italic",      "j", "downloads",     "k", "insert link",
        "l", "address bar", "n", "new",           "o", "open",
        "p", "print",       "r", "refresh",       "s", "save",
        "t", "new tab",     "u", "underline",     "v", "paste",
        "w", "close tab",   "x", "cut",           "y", "redo",
        "z", "undo",        "tab", "next tab",    "enter", "send / new line",
        "space", "autocomplete"
    )
    if (mods = "^") {
        if ctrlKeys.Has(key)
            issues.Push({Level: "Warn", Reason: "Ctrl + " Format("{:U}", key)
                . " is " ctrlKeys[key] " in most applications"})
        else if RegExMatch(key, "^[0-9]$")
            issues.Push({Level: "Warn", Reason: "Ctrl + digit switches browser tabs"})
        else if (StrLen(key) = 1)
            issues.Push({Level: "Warn", Reason: "Ctrl + one key is used by many applications"})
    }

    ; --- Ctrl + Shift: a few very common ones ---------------------------
    static ctrlShiftKeys := Map(
        "t", "reopen closed tab", "n", "new private window",
        "v", "paste as plain text", "z", "redo", "s", "save as",
        "tab", "previous tab"
    )
    if (mods = "^+" && ctrlShiftKeys.Has(key))
        issues.Push({Level: "Warn", Reason: "Ctrl + Shift + " Format("{:U}", key)
            . " is " ctrlShiftKeys[key] " in many applications"})

    ; --- Alt + letter opens menus ----------------------------------------
    if (mods = "!" && StrLen(key) = 1)
        issues.Push({Level: "Warn", Reason: "Alt + letter opens menus in many applications"})

    ; --- Win + key: Windows claims most of these ------------------------
    if (mods = "#" && !reserved.Has(combo))
        issues.Push({Level: "Warn", Reason: "Windows uses most Win + key shortcuts"})

    ; --- Function keys alone ----------------------------------------------
    if (mods = "" && RegExMatch(key, "^f([1-9]|1[0-2])$"))
        issues.Push({Level: "Warn", Reason: "F-keys on their own are used by most applications"})

    ; --- AltGr trap: Ctrl + Alt is AltGr on European keyboards ----------
    if ((parts.AltGr || mods = "^!") && StrLen(key) = 1)
        issues.Push({Level: "Warn"
            , Reason: "Ctrl + Alt is AltGr on European keyboards and may block a "
            . "character such as @ or #. Add Shift to be safe."})

    return issues
}

; Splits "<^>!+K" into { Mods: "^!+", Key: "k", AltGr: true }
SplitHotkey(hk) {
    i := 1
    raw := ""
    while (i <= StrLen(hk) && InStr("~*$<>^!+#", SubStr(hk, i, 1)))
        raw .= SubStr(hk, i, 1), i++
    key := StrLower(SubStr(hk, i))

    mods := ""
    for m in ["^", "!", "+", "#"]
        if InStr(raw, m)
            mods .= m
    ; Right Alt (>!) is the AltGr key itself on European layouts
    return {Mods: mods, Key: key, AltGr: InStr(raw, ">!") > 0}
}

; Formats issues as one line each, for message boxes
FormatIssues(name, hk, issues) {
    out := ""
    for it in issues
        out .= "[" name "] " hk " - " it.Reason "`n"
    return RTrim(out, "`n")
}

HasBlock(issues) {
    for it in issues
        if (it.Level = "Block")
            return true
    return false
}
