/*
Script            : AutoHotkey-Typer - Tray
FileName          : Tray.ahk
Author            : Philippe Addelia
Created           : 2026-10-24 13:45 EDT
Modified          : 2026-10-25 12:55 EDT
Preferred Location: src\lib\
Version           : 1.6
Purpose           : Tray menu, About box, first-run welcome and the startup
                    problem / warning report.
                    1.0.3 : Add secret moved to SecretDialog.ahk (one page).
                    1.1.1 : own tray icon (red), grey while suspended.
                    1.2   : Add / edit snippet (plain + secret) is the
                            default action; Notepad editing renamed.
                    1.4   : Snippet file submenu - My snippets / Example
                            snippets, copy examples into my snippets.
                    1.5   : one snippet file again - examples are created in
                            it on first run; Remove example snippets.
                    1.5.1 : copyright line in the About box.
                    1.6   : Secret lock... and Lock secrets now; tooltip
                            shows when secrets are locked.
*/

global TriggerCount := 0

; Tooltip: version, triggers, and whether secrets are locked or suspended
UpdateTrayTip() {
    tip := APP_NAME " " APP_VERSION " - " TriggerCount " trigger"
        . (TriggerCount = 1 ? "" : "s")
    if A_IsSuspended
        tip .= " - SUSPENDED"
    else if (SecretLock.Enabled && SecretLock.Locked)
        tip .= " - secrets locked"
    A_IconTip := tip
}

BuildTrayMenu(count) {
    global TriggerCount := count
    UpdateTrayTip()

    files := Menu()
    files.Add("Edit snippet file",   (*) => Run('notepad.exe "' ConfigFile '"'))
    files.Add("Open snippet folder", (*) => Run('explorer.exe /select,"' ConfigFile '"'))
    files.Add()
    files.Add("Remove example snippets...", RemoveExamplesMenu)

    tray := A_TrayMenu
    tray.Delete()                                   ; remove the standard items
    tray.Add("Add / edit snippet...", ShowSnippetDialog)
    tray.Add("Snippet file", files)
    tray.Add("Secret lock...", ShowLockDialog)
    if SecretLock.Enabled
        tray.Add("Lock secrets now", (*) => SetSecretLock(true))
    tray.Add()
    tray.Add("Reload",  (*) => Reload())
    tray.Add("Suspend", ToggleSuspend)
    tray.Add()
    tray.Add("About",   (*) => ShowAbout(count))
    tray.Add("Exit",    (*) => ExitApp())
    tray.Default := "Add / edit snippet..."         ; double-click the tray icon
}

ToggleSuspend(itemName, itemPos, menu) {
    Suspend(-1)
    if A_IsSuspended
        menu.Check(itemName)
    else
        menu.Uncheck(itemName)
    SetAppIcon(A_IsSuspended)
    UpdateTrayTip()
}

; ---------------------------------------------------------------------
;  App icon: red when active, grey when suspended. Also used by the
;  app's dialogs. "Freeze" stops AutoHotkey from swapping in its stock
;  suspended icon.
;    Script  : icons from src\res\
;    Compiled: icons embedded by Ahk2Exe (see AutoHotkey-Typer.ahk)
; ---------------------------------------------------------------------
SetAppIcon(suspended := false) {
    try {
        if A_IsCompiled {
            TraySetIcon(A_ScriptFullPath, suspended ? -206 : -159, true)
            return
        }
        file := A_ScriptDir "\res\AutoHotkey-Typer" (suspended ? "-suspended" : "") ".ico"
        if FileExist(file)
            TraySetIcon(file, , true)
    }
}

ShowAbout(count) {
    MsgBox(APP_NAME " " APP_VERSION "`n"
        . APP_AUTHOR "`n"
        . "Apache License 2.0`n`n"
        . "Triggers active: " count "`n"
        . "Snippet file:`n" ConfigFile "`n`n"
        . APP_REPO,
        "About " APP_NAME, "Iconi")
}

ShowWelcome(count) {
    MsgBox("Welcome to " APP_NAME "!`n`n"
        . "Your snippet file was created with EXAMPLE snippets, so you can "
        . "try the app right away:`n`n"
        . "  - type  `;addr  anywhere for a postal address`n"
        . "  - type  `;hi  in Notepad`n"
        . "  - press  Ctrl + Alt + Shift + S  for a signature`n`n"
        . "The examples are named 'Ex - ...'. When you are ready for your own "
        . "snippets and secrets, remove them:`n"
        . "  tray icon > Snippet file > Remove example snippets`n`n"
        . "To add your own, double-click the tray icon.",
        APP_NAME, "Iconi")
}

; Deletes every snippet whose name starts with "Ex - " (the examples
; created on first run). The user's own snippets are not touched.
RemoveExamplesMenu(*) {
    names := ExampleSnippetNames()
    if (names.Length = 0) {
        MsgBox("There are no example snippets left (names starting with "
            . "'Ex - ').", APP_NAME, "Iconi")
        return
    }
    if (MsgBox("Remove " names.Length " example snippet(s)?`n`n"
            . "Only snippets whose name starts with 'Ex - ' are removed. "
            . "Your own snippets and secrets are not touched.", APP_NAME
            , "OKCancel Icon? Default2") != "OK")
        return
    for name in names
        try IniDelete(ConfigFile, name)
    Reload()
}

ReportProblems(problems, warnings := []) {
    if (problems.Length = 0 && warnings.Length = 0)
        return
    msg := ""
    if problems.Length
        msg .= "Some snippets could not be loaded:`n" BulletList(problems) "`n`n"
    if warnings.Length
        msg .= "Warnings (these snippets still work):`n" BulletList(warnings) "`n`n"
           . "Add AllowRisky=1 to a snippet to silence its hotkey warning.`n`n"
    msg .= "Fix them with Add / edit snippet (or in the snippet file), then "
         . "choose Reload from the tray menu."
    MsgBox(msg, APP_NAME, problems.Length ? "Icon!" : "Iconi")
}

BulletList(items, maxShown := 12) {
    out := ""
    for i, p in items {
        if (i > maxShown) {
            out .= "`n  ...and " (items.Length - maxShown) " more"
            break
        }
        out .= "`n  - " p
    }
    return out
}
