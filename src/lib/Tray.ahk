/*
Script            : AutoHotkey-Typer - Tray
FileName          : Tray.ahk
Author            : Philippe Addelia
Created           : 2026-10-24 13:45 EDT
Modified          : 2026-10-25 04:30 EDT
Preferred Location: src\lib\
Version           : 1.4
Purpose           : Tray menu, About box, first-run welcome and the startup
                    problem / warning report.
                    1.0.3 : Add secret moved to SecretDialog.ahk (one page).
                    1.1.1 : own tray icon (red), grey while suspended.
                    1.2   : Add / edit snippet (plain + secret) is the
                            default action; Notepad editing renamed.
                    1.4   : Snippet file submenu - My snippets / Example
                            snippets, copy examples into my snippets.
*/

BuildTrayMenu(count) {
    A_IconTip := APP_NAME " " APP_VERSION " - " count " trigger" (count = 1 ? "" : "s")
        . (UsingExamples ? " (examples)" : "")

    files := Menu()
    files.Add("My snippets",      (*) => SwitchSnippetSet("mine"))
    files.Add("Example snippets", (*) => SwitchSnippetSet("examples"))
    files.Check(UsingExamples ? "Example snippets" : "My snippets")
    files.Add()
    files.Add("Copy examples into my snippets...", CopyExamplesMenu)
    files.Add()
    files.Add("Edit my snippet file", (*) => Run('notepad.exe "' MyConfigFile '"'))
    files.Add("Open snippet folder",  (*) => Run('explorer.exe /select,"' MyConfigFile '"'))

    tray := A_TrayMenu
    tray.Delete()                                   ; remove the standard items
    tray.Add("Add / edit snippet...", ShowSnippetDialog)
    tray.Add("Snippet file", files)
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
    A_IconTip := APP_NAME " " APP_VERSION (A_IsSuspended ? " - SUSPENDED" : "")
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
    MsgBox(APP_NAME " " APP_VERSION "`n`n"
        . "Using: " (UsingExamples ? "Example snippets" : "My snippets") "`n"
        . "Triggers active: " count "`n"
        . "Snippet file:`n" ConfigFile "`n`n"
        . APP_REPO,
        "About " APP_NAME, "Iconi")
}

ShowWelcome(count) {
    if !UsingExamples {
        MsgBox("Welcome to " APP_NAME "!`n`n"
            . "Your snippet file was created here:`n" MyConfigFile "`n`n"
            . "Double-click the tray icon to add your first snippet.",
            APP_NAME, "Iconi")
        return
    }
    MsgBox("Welcome to " APP_NAME "!`n`n"
        . "You are trying the EXAMPLE snippets. Open Notepad and type  `;hi"
        . "  or  `;addr`n`n"
        . "When you are ready for your own:`n"
        . "  tray icon > Snippet file > My snippets`n"
        . "  then double-click the tray icon to add a snippet.`n`n"
        . "To keep some examples: Snippet file > Copy examples into my snippets.",
        APP_NAME, "Iconi")
}

CopyExamplesMenu(*) {
    if (MsgBox("Copy all example snippets into My snippets?`n`n"
            . "Snippets whose name already exists in My snippets are skipped. "
            . "You can edit or delete the copies afterwards.", APP_NAME
            , "OKCancel Iconi") != "OK")
        return
    r := CopyExamplesToMine()
    if (MsgBox(r.Added " example(s) copied, " r.Skipped " skipped (name already used)."
            . "`n`nSwitch to My snippets now?", APP_NAME, "YesNo Iconi") = "Yes")
        SwitchSnippetSet("mine")
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
