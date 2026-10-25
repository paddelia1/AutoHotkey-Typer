/*
Script            : AutoHotkey-Typer - Config
FileName          : Config.ahk
Author            : Philippe Addelia
Created           : 2026-10-24 13:45 EDT
Modified          : 2026-10-25 10:55 EDT
Preferred Location: src\lib\
Version           : 1.5
Purpose           : Locates, creates, reads and writes the snippet file
                    (snippets.ini). Secrets are stored DPAPI-encrypted.
*/

; ---------------------------------------------------------------------
;  Where the snippet file lives
;    Portable mode : snippets.ini next to the script / exe (if it exists)
;    Default       : %AppData%\AutoHotkey-Typer\snippets.ini
;  The default keeps personal data out of OneDrive and git folders.
; ---------------------------------------------------------------------
ResolveConfigFile() {
    portable := A_ScriptDir "\snippets.ini"
    if FileExist(portable)
        return portable
    return A_AppData "\" APP_NAME "\snippets.ini"
}

; Creates the snippet file on first run (1.5): a copy of the shipped
; template (examples\snippets.sample.ini - note on top + example snippets).
; templateFile is a temporary copy made by FileInstall in the main script;
; if it is missing, a file with only the format help is created instead.
; Returns true when a new file was created.
EnsureConfigExists(file, templateFile := "") {
    if FileExist(file)
        return false
    SplitPath(file, , &dir)
    DirCreate(dir)
    text := (templateFile != "" && FileExist(templateFile))
        ? FileRead(templateFile)
        : DefaultConfigText()
    ; UTF-16 so the Windows INI functions read accented characters correctly
    FileAppend(text, file, "UTF-16")
    return true
}

; Names of the example snippets (created on first run, prefix "Ex - ")
ExampleSnippetNames() {
    names := []
    try sections := IniRead(ConfigFile)
    catch
        return names
    for name in StrSplit(sections, "`n", "`r")
        if (SubStr(name, 1, 5) = "Ex - ")
            names.Push(name)
    return names
}

; ---------------------------------------------------------------------
;  Read every [section] as one snippet
;  Returns { Snippets: [ {Name, Hotkey, Hotstring, Text, IsSecret, Secret,
;                         Window, AllowRisky} ],
;            Errors: [], Warnings: [] }
;  A plain snippet has Text=. A secret has Secret=dpapi1:... instead and
;  is only decrypted at the moment it is typed.
; ---------------------------------------------------------------------
LoadSnippets(file) {
    snippets := []
    errors   := []
    warnings := []

    if IsSyncedFolder(file)
        warnings.Push("The snippet file is in a cloud-synced folder:`n    " file
            . "`n    Move it, or delete the portable snippets.ini to use AppData.")

    try
        sections := IniRead(file)
    catch as err {
        if FileExist(file) {
            sections := ""          ; a file with no snippets yet is fine
        } else {
            errors.Push("Could not read " file " - " err.Message)
            return {Snippets: snippets, Errors: errors, Warnings: warnings}
        }
    }

    for name in StrSplit(sections, "`n", "`r") {
        if (name = "")
            continue

        enabled := Trim(IniRead(file, name, "Enabled", "1"))
        if (enabled = "0")
            continue

        hk   := Trim(IniRead(file, name, "Hotkey", ""))
        hs   := Trim(IniRead(file, name, "Hotstring", ""))
        text := IniRead(file, name, "Text", "")
        win  := Trim(IniRead(file, name, "Window", ""))
        secret := Trim(IniRead(file, name, "Secret", ""))
        risky  := (Trim(IniRead(file, name, "AllowRisky", "0")) = "1")
        ; login sequence (1.3): Username, Separator, secret, Submit
        login := {
            User:   Trim(IniRead(file, name, "Username", "")),
            Sep:    (Trim(IniRead(file, name, "Separator", "Tab")) = "Enter") ? "Enter" : "Tab",
            Submit: (Trim(IniRead(file, name, "Submit", "0")) = "1"),
            Delay:  ParseDelay(IniRead(file, name, "Delay", ""))
        }

        if (hk = "" && hs = "") {
            errors.Push("[" name "] has no Hotkey or Hotstring - skipped")
            continue
        }
        if (text != "" && secret != "") {
            errors.Push("[" name "] has both Text and Secret - use only one - skipped")
            continue
        }
        if (text = "" && secret = "") {
            errors.Push("[" name "] has no Text or Secret - skipped")
            continue
        }

        if (secret != "") {
            ; Refuse plain text in Secret= so nobody believes it is protected
            if !IsDpapiValue(secret) {
                errors.Push("[" name "] Secret is not encrypted. Remove it and use "
                    . "Add / edit snippet from the tray menu - skipped")
                continue
            }
            ; Prove it decrypts now, rather than failing when the key is pressed
            try {
                test := DpapiUnprotect(secret)
                test := ""
            } catch {
                errors.Push("[" name "] Secret cannot be decrypted. It was encrypted "
                    . "under another Windows account or PC. Add it again - skipped")
                continue
            }
            if (win = "")
                warnings.Push("[" name "] is a secret with no Window= restriction. "
                    . "It can be typed into any window.")
        } else if (login.User != "" || login.Submit) {
            warnings.Push("[" name "] Username= and Submit= only work with "
                . "secrets - ignored for this plain snippet.")
        }

        snippets.Push({
            Name:       name,
            Hotkey:     hk,
            Hotstring:  hs,
            Text:       (secret = "") ? Unescape(text) : "",
            IsSecret:   (secret != ""),
            Secret:     secret,
            Window:     win,
            AllowRisky: risky,
            Login:      login
        })
    }
    return {Snippets: snippets, Errors: errors, Warnings: warnings}
}

; True when the path is inside a common cloud-sync folder
IsSyncedFolder(path) {
    for marker in ["\OneDrive", "\Dropbox\", "\Google Drive\", "\My Drive\", "\iCloudDrive\"]
        if InStr(path, marker)
            return true
    return false
}

; ---------------------------------------------------------------------
;  Write (or update) a plain snippet. escapedText uses \n \t \\ (see
;  EscapeText). Removes any Secret= line, so switching a secret to plain
;  leaves no encrypted value behind. Enabled / AllowRisky are kept.
; ---------------------------------------------------------------------
SavePlainSnippet(file, name, hk, hs, win, escapedText) {
    IniWrite(escapedText, file, name, "Text")
    for key, val in Map("Hotkey", hk, "Hotstring", hs, "Window", win) {
        if (val != "")
            IniWrite(val, file, name, key)
        else
            try IniDelete(file, name, key)
    }
    try IniDelete(file, name, "Secret")
    for key in ["Username", "Separator", "Submit", "Delay"]    ; secrets only
        try IniDelete(file, name, key)
}

; ---------------------------------------------------------------------
;  Write (or update) a secret snippet. The value must already be
;  encrypted with DpapiProtect - plain text never touches the file.
;  Keys the dialog does not manage (Enabled, AllowRisky) are kept.
; ---------------------------------------------------------------------
; login (optional, 1.3): {User, Sep, Submit, Delay}
SaveSecretSnippet(file, name, hk, hs, win, encrypted, login := 0) {
    if !IsDpapiValue(encrypted)
        throw ValueError("Refusing to save an unencrypted secret")
    IniWrite(encrypted, file, name, "Secret")
    for key, val in Map("Hotkey", hk, "Hotstring", hs, "Window", win) {
        if (val != "")
            IniWrite(val, file, name, key)
        else
            try IniDelete(file, name, key)
    }
    try IniDelete(file, name, "Text")   ; a secret never also has plain text

    ; --- login sequence: only keys that differ from the defaults ---
    user := IsObject(login) ? login.User : ""
    if (user != "") {
        IniWrite(user, file, name, "Username")
        IniWrite(login.Sep, file, name, "Separator")
    } else {
        try IniDelete(file, name, "Username")
        try IniDelete(file, name, "Separator")
    }
    if (IsObject(login) && login.Submit)
        IniWrite("1", file, name, "Submit")
    else
        try IniDelete(file, name, "Submit")
    if (IsObject(login) && login.Delay != 150)
        IniWrite(login.Delay, file, name, "Delay")
    else
        try IniDelete(file, name, "Delay")
}

; Delay= value -> milliseconds, 0 - 2000, default 150
ParseDelay(v) {
    v := Trim(v)
    return IsInteger(v) ? Min(Max(Integer(v), 0), 2000) : 150
}

; \n = Enter, \t = Tab, \\ = a literal backslash (plain Text= only;
; secrets are typed exactly as entered)
Unescape(s) {
    s := StrReplace(s, "\\", Chr(1))
    s := StrReplace(s, "\n", "`n")
    s := StrReplace(s, "\t", "`t")
    return StrReplace(s, Chr(1), "\")
}

; ---------------------------------------------------------------------
;  Sample file written on first run
; ---------------------------------------------------------------------
DefaultConfigText() {
    return "
    (
; =====================================================================
;  AHK-Typer - your snippet file
;  Easiest: double-click the tray icon (Add / edit snippet).
;  Or edit this file, save it, then choose Reload from the tray menu.
;
;  One [section] per snippet. The section name is the snippet's name.
;
;    Hotkey=     key combination in AutoHotkey notation
;                  ^ = Ctrl    ! = Alt    + = Shift    # = Win
;                  Example: ^!+e  means  Ctrl + Alt + Shift + E
;                  Full guide: docs\hotkey-notation.md in the repo
;    Hotstring=  abbreviation replaced as you type, for example ;em
;    Text=       what gets typed. \n = Enter, \t = Tab, \\ = backslash
;    Secret=     an encrypted value (dpapi1:...). Never type this by hand -
;                  use Add / edit snippet from the tray menu.
;    Window=     optional - only active while this window is in front.
;                  Part of the window title, or ahk_exe program.exe
;                  Several windows: separate them with  |
;                  Strongly recommended for secrets.
;    AllowRisky= 1 to silence warnings about this hotkey (default 0)
;    Username=   secrets only: typed first, then Separator, then the secret
;    Separator=  Tab (default) or Enter, between username and secret
;    Submit=     1 = press Enter after the secret (default 0)
;    Delay=      milliseconds between those steps (default 150)
;    Enabled=    1 or 0 (default 1)
;
;  A snippet needs a Hotkey, a Hotstring, or both, and Text or Secret.
;
;  IMPORTANT: Text= values are plain text. Passwords, API keys and
;  similar values belong in Secret= entries, created from the tray menu.
;  Secrets only decrypt under your Windows account on this PC.
; =====================================================================

    )"
}
