#Requires AutoHotkey v2.0
#SingleInstance Force
/*
Script            : AutoHotkey-Typer
FileName          : AutoHotkey-Typer.ahk
Author            : Philippe Addelia
Created           : 2026-10-24 13:45 EDT
Modified          : 2026-10-25 04:30 EDT
Preferred Location: src\ (repo AutoHotkey-Typer)
Version           : 1.4
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
License           : Apache 2.0 - see LICENSE
*/

;@Ahk2Exe-SetName AHK-Typer
;@Ahk2Exe-SetDescription AHK-Typer - types snippets and encrypted secrets
;@Ahk2Exe-SetVersion 1.4
;@Ahk2Exe-ExeName ..\dist\AHK-Typer.exe
;@Ahk2Exe-SetMainIcon res\AutoHotkey-Typer.ico
;@Ahk2Exe-AddResource res\AutoHotkey-Typer-suspended.ico, 206
;@Ahk2Exe-SetCopyright Philippe Addelia - Apache 2.0

global APP_NAME    := "AutoHotkey-Typer"
global APP_VERSION := "1.4"
global APP_REPO    := "https://github.com/paddelia1/AutoHotkey-Typer"

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

; ---------------------------------------------------------------------
;  Startup
; ---------------------------------------------------------------------
; My snippets (personal, never shipped)
global MyConfigFile := ResolveConfigFile()
isFirstRun          := EnsureConfigExists(MyConfigFile)
SplitPath(MyConfigFile, , &dir)
global DataDir := dir

; Example snippets: shipped with the app (embedded in the .exe), copied
; next to the personal file at every start so it is always current
global SampleFile := DataDir "\snippets.sample.ini"
try FileInstall("..\examples\snippets.sample.ini", SampleFile, 1)

; Which set is active - ConfigFile is the file actually loaded
global UsingExamples := (ReadSnippetSet(isFirstRun) = "examples")
                        && (FileExist(SampleFile) != "")
global ConfigFile    := UsingExamples ? SampleFile : MyConfigFile

loaded  := LoadSnippets(ConfigFile)
result  := RegisterSnippets(loaded.Snippets)

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
