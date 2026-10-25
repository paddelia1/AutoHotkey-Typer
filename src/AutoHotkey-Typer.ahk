#Requires AutoHotkey v2.0
#SingleInstance Force
/*
Script            : AutoHotkey-Typer
FileName          : AutoHotkey-Typer.ahk
Author            : Philippe Addelia
Created           : 2026-10-24 13:45 EDT
Modified          : 2026-10-25 12:55 EDT
Preferred Location: src\ (repo AutoHotkey-Typer)
Version           : 1.6
Purpose           : Types saved text snippets when you press a hotkey or type a
                    short abbreviation (hotstring).
                    Phase 1: core engine, snippet file, tray menu.
                    1.0.2 : DPAPI-encrypted secrets, shortcut checker.
                    1.0.3 : one-page Add / edit secret dialog.
                    1.1   : password / passphrase generator.
                    1.1.1 : own red tray icon (grey when suspended).
                    1.2   : one dialog for plain snippets and secrets.
                    1.3   : login sequence (username, Tab, secret, Enter).
                    1.4   : example snippets + switch, AHK-Typer.exe build.
                    1.5   : examples created in the snippet file on first run.
                    1.5.0.1 : docs - start automatically with Windows.
                    1.5.1 : copyright in About box, .exe properties, docs.
                    1.6   : optional secret lock (PIN after being away).
Copyright         : Copyright 2026 Philippe Addelia
License           : Apache 2.0 - see LICENSE
*/

;@Ahk2Exe-SetName AHK-Typer
;@Ahk2Exe-SetDescription AHK-Typer - types snippets and encrypted secrets
;@Ahk2Exe-SetVersion 1.6
;@Ahk2Exe-ExeName ..\dist\AHK-Typer.exe
;@Ahk2Exe-SetMainIcon res\AutoHotkey-Typer.ico
;@Ahk2Exe-AddResource res\AutoHotkey-Typer-suspended.ico, 206
;@Ahk2Exe-SetCopyright Copyright 2026 Philippe Addelia
;@Ahk2Exe-SetCompanyName Philippe Addelia

global APP_NAME    := "AutoHotkey-Typer"
global APP_VERSION := "1.6"
global APP_REPO    := "https://github.com/paddelia1/AutoHotkey-Typer"
global APP_AUTHOR  := "Copyright 2026 Philippe Addelia"

SetWorkingDir(A_ScriptDir)
SetTitleMatchMode(2)        ; Window= filters match any part of the title
Persistent()                ; stay running even if no snippet could be bound

#Include lib\Dpapi.ahk
#Include lib\Checker.ahk
#Include lib\Config.ahk
#Include lib\Engine.ahk
#Include lib\Tray.ahk
#Include lib\SecretDialog.ahk
#Include lib\Wordlist.ahk
#Include lib\PwGen.ahk
#Include lib\GeneratorDialog.ahk
#Include lib\PinLock.ahk

; ---------------------------------------------------------------------
;  Startup
; ---------------------------------------------------------------------
global ConfigFile := ResolveConfigFile()
SplitPath(ConfigFile, , &DataDir)

; First run: the snippet file is created from the shipped template
; (examples\snippets.sample.ini, embedded in the .exe) - a note on top plus
; example snippets, so the app works right away.
; Ahk2Exe only embeds the file when FileInstall starts its own line.
template := A_Temp "\AHK-Typer-template.ini"
if !FileExist(ConfigFile) {
    try {
        FileInstall("..\examples\snippets.sample.ini", template, 1)
    }
}
isFirstRun := EnsureConfigExists(ConfigFile, template)
try FileDelete(template)

; Clean up files used by 1.4 only (separate example file and its switch)
for old in ["snippets.sample.ini", "settings.ini"]
    try FileDelete(DataDir "\" old)

loaded  := LoadSnippets(ConfigFile)
result  := RegisterSnippets(loaded.Snippets)

InitSecretLock()                 ; optional PIN after being away (1.6)
SetAppIcon()
BuildTrayMenu(result.Count)

if (isFirstRun)
    ShowWelcome(result.Count)

problems := []
for e in loaded.Errors
    problems.Push(e)
for e in result.Errors
    problems.Push(e)
warnings := []
for w in loaded.Warnings
    warnings.Push(w)
for w in result.Warnings
    warnings.Push(w)
ReportProblems(problems, warnings)
