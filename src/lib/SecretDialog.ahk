/*
Script            : AutoHotkey-Typer - SecretDialog
FileName          : SecretDialog.ahk
Author            : Philippe Addelia
Created           : 2026-10-24 23:30 EDT
Modified          : 2026-10-25 12:55 EDT
Preferred Location: src\lib\
Version           : 1.6
Purpose           : One-page dialog to add, edit or delete a snippet -
                    plain text or encrypted secret (1.2):
                      - name (pick an existing snippet to edit it)
                      - type: Plain text or Secret
                      - hotkey builder (Ctrl / Alt / Shift / Win + key) with
                        live AHK notation and conflict verdict
                      - hotstring
                      - list of allowed windows, with Pick... to capture one
                      - plain text: multi-line text box
                      - secret value typed twice, optional Show
                      - Generate... opens the password generator (1.1)
                      - Delete removes the snippet being edited (1.2)
                      - login: username, Tab / Enter, secret, Enter (1.3)
*/

global SecretDlg := ""

; 1.2: one dialog for plain snippets and secrets
ShowSnippetDialog(*) => ShowSecretDialog()

ShowSecretDialog(*) {
    global SecretDlg
    if IsObject(SecretDlg) {
        SecretDlg.Show()
        return
    }
    SecretDlg := BuildSecretDialog()
}

BuildSecretDialog() {
    W       := 470                      ; content width
    LBL     := 92                       ; label column width
    FLD     := W - LBL - 8              ; field width after a label
    ; Shared state lives in an object so nested handlers change its
    ; properties instead of assigning to outer variables
    ; st.editing = name of the snippet being edited, st.editingSecret = it
    ; is a secret in the file
    st := {editing: "", editingSecret: false, syncing: false}

    d := Gui("+AlwaysOnTop -MinimizeBox", APP_NAME " - Add / edit snippet")
    d.SetFont("s10", "Segoe UI")
    d.MarginX := 14, d.MarginY := 12

    ; ================= Name =================
    d.Add("Text", "xm w" LBL, "Name")
    cbName := d.Add("ComboBox", "x+8 yp-3 w" FLD, ListSnippetNames())
    d.Add("Text", "xm+" (LBL + 8) " y+3 w" FLD " cGray"
        , "Pick an existing snippet to edit it, or type a new name.")
    d.Add("Text", "xm y+10 w" LBL, "Type")
    rbPlain  := d.Add("Radio", "x+8 yp Checked", "Plain text")
    rbSecret := d.Add("Radio", "x+24 yp", "Secret (encrypted)")

    ; ================= Trigger =================
    d.Add("Text", "xm y+12 w" W " h1 0x10")
    d.SetFont("s10 Bold")
    d.Add("Text", "xm y+8", "Trigger")
    d.SetFont("s10 Norm")

    ckUseHk := d.Add("Checkbox", "xm y+8 w" LBL " Checked", "Hotkey")
    ckCtrl  := d.Add("Checkbox", "x+8 yp", "Ctrl")
    ckAlt   := d.Add("Checkbox", "x+10 yp", "Alt")
    ckShift := d.Add("Checkbox", "x+10 yp", "Shift")
    ckWin   := d.Add("Checkbox", "x+10 yp", "Win")
    d.Add("Text", "x+14 yp", "+ Key")
    cbKey   := d.Add("ComboBox", "x+8 yp-3 w100", KeyChoices())

    d.Add("Text", "xm+" (LBL + 8) " y+8 w62 cGray", "Notation")
    edNotation := d.Add("Edit", "x+4 yp-3 w110")
    txPretty   := d.Add("Text", "x+10 yp+3 w" (FLD - 186), "")

    txVerdict := d.Add("Text", "xm+" (LBL + 8) " y+8 w" FLD " h38", "")

    ckUseHs := d.Add("Checkbox", "xm y+4 w" LBL, "Hotstring")
    edHs    := d.Add("Edit", "x+8 yp-3 w120 Disabled", ";")
    d.Add("Text", "x+10 yp+3 w" (FLD - 130) " cGray", "Abbreviation you type")

    ; ================= Windows =================
    d.Add("Text", "xm y+14 w" W " h1 0x10")
    d.SetFont("s10 Bold")
    d.Add("Text", "xm y+8", "Only type in these windows")
    d.SetFont("s10 Norm")
    d.Add("Text", "x+8 yp cGray", "(recommended for secrets)")

    edWin    := d.Add("Edit", "xm y+8 w" (W - 166))
    btAddWin := d.Add("Button", "x+6 yp-1 w76", "Add")
    btPick   := d.Add("Button", "x+6 yp w78", "Pick...")
    lbWin    := d.Add("ListBox", "xm y+6 w" (W - 84) " r3")
    btRemove := d.Add("Button", "x+6 yp w78", "Remove")
    ; place the hint under the LIST, not under the shorter Remove button
    ; ("y+" is relative to the last control added)
    lbWin.GetPos(, &lbY, , &lbH)
    d.Add("Text", "xm y" (lbY + lbH + 4) " w" W " cGray"
        , "Part of a window title and/or ahk_exe program.exe. The snippet works "
        . "in any window listed. Pick... captures the window you click next.")

    ; ============ Value: Secret or Plain text, in the same place ============
    sepV := d.Add("Text", "xm y+12 w" W " h1 0x10")
    sepV.GetPos(, &vY)

    secretCtrls := []
    secretCtrls.Push(d.Add("Text", "xm y" (vY + 10) " w" LBL, "Secret"))
    edPw1 := d.Add("Edit", "x+8 yp-3 w" (FLD - 112) " Password")
    btGen := d.Add("Button", "x+6 yp-1 w106", "Generate...")
    secretCtrls.Push(edPw1, btGen)
    secretCtrls.Push(d.Add("Text", "xm y+8 w" LBL, "Confirm"))
    edPw2 := d.Add("Edit", "x+8 yp-3 w" (FLD - 112) " Password")
    ckShow := d.Add("Checkbox", "xm+" (LBL + 8) " y+8", "Show")
    txPw   := d.Add("Text", "x+16 yp w" (FLD - 70), "")
    secretCtrls.Push(edPw2, ckShow, txPw)

    ; --- optional login sequence (1.3) ---
    secretCtrls.Push(d.Add("Text", "xm y+14 w" LBL, "Username"))
    edUser := d.Add("Edit", "x+8 yp-3 w" (FLD - 112))
    secretCtrls.Push(edUser, d.Add("Text", "x+8 yp+3 cGray", "optional"))
    lbThen := d.Add("Text", "xm y+12 w" LBL, "Then press")
    ddSep  := d.Add("DropDownList", "x+8 yp-3 w80 Choose1", ["Tab", "Enter"])
    txThen := d.Add("Text", "x+8 yp+3 w" (FLD - 96) " cGray", "between username and secret")
    secretCtrls.Push(lbThen, ddSep, txThen)
    ckSubmit := d.Add("Checkbox", "xm+" (LBL + 8) " y+12", "Press Enter after the secret")
    lbDelay  := d.Add("Text", "x+14 yp", "Delay")
    edDelay  := d.Add("Edit", "x+6 yp-3 w52 Number Limit4", "150")
    txMs     := d.Add("Text", "x+4 yp+3 cGray", "ms")
    secretCtrls.Push(ckSubmit, lbDelay, edDelay, txMs)
    txLogin  := d.Add("Text", "xm+" (LBL + 8) " y+10 w" FLD " cGray"
        , "Click in the first field (username, or the secret if no username), "
        . "then press the hotkey.")
    secretCtrls.Push(txLogin)
    txLogin.GetPos(, &sY, , &sH)

    plainCtrls := []
    plainCtrls.Push(d.Add("Text", "xm y" (vY + 10) " w" LBL, "Text"))
    edText := d.Add("Edit", "x+8 yp-3 w" FLD " r9 Multi WantReturn")
    txText := d.Add("Text", "xm+" (LBL + 8) " y+4 w" FLD " cGray"
        , "Typed exactly as written. Enter starts a new line.")
    plainCtrls.Push(edText, txText)
    txText.GetPos(, &pY, , &pH)

    ; ================= Buttons =================
    d.Add("Text", "xm y" (Max(sY + sH, pY + pH) + 12) " w" W " h1 0x10")
    btSave   := d.Add("Button", "xm y+12 w110 h30 Default", "Save")
    btCancel := d.Add("Button", "x+10 yp w110 h30", "Cancel")
    btDelete := d.Add("Button", "x+" (W - 340) " yp w110 h30 Disabled", "Delete")

    ; ================= Events =================
    cbName.OnEvent("Change", NameChanged)
    for c in [rbPlain, rbSecret]
        c.OnEvent("Click", (*) => TypeChanged())
    for c in [ckUseHk, ckUseHs]
        c.OnEvent("Click", (*) => UpdateMode())
    for c in [ckCtrl, ckAlt, ckShift, ckWin]
        c.OnEvent("Click", (*) => BuildNotation())
    cbKey.OnEvent("Change", (*) => BuildNotation())
    edNotation.OnEvent("Change", (*) => ParseNotation())
    edHs.OnEvent("Change", (*) => UpdateVerdict())
    btAddWin.OnEvent("Click", (*) => AddWindowRule())
    btPick.OnEvent("Click", (*) => PickWindow())
    btRemove.OnEvent("Click", (*) => RemoveWindowRule())
    edPw1.OnEvent("Change", (*) => UpdatePwState())
    edPw2.OnEvent("Change", (*) => UpdatePwState())
    edUser.OnEvent("Change", (*) => UpdateLoginState())
    ckShow.OnEvent("Click", (*) => ToggleShow())
    btGen.OnEvent("Click", (*) => ShowPasswordGenerator(d, UseGenerated))
    btSave.OnEvent("Click", (*) => SaveSnippet())
    btDelete.OnEvent("Click", (*) => DeleteSnippet())
    btCancel.OnEvent("Click", (*) => CloseDialog())
    d.OnEvent("Close", (*) => CloseDialog())
    d.OnEvent("Escape", (*) => CloseDialog())

    UpdateMode()
    ShowTypePanel()
    UpdateLoginState()
    d.Show("AutoSize")
    return d

    ; =================================================================
    ;  Nested handlers (closures over the controls above)
    ; =================================================================

    NameChanged(*) {
        name := Trim(cbName.Text)
        if (name != "" && SectionExists(name)) {
            LoadExisting(name)
        } else if (st.editing != "") {
            st.editing := ""            ; typed away from an existing name:
            st.editingSecret := false   ; keep the fields, treat as new
            btDelete.Enabled := false
            UpdatePwState()
        }
    }

    LoadExisting(name) {
        st.editing := name
        hk  := Trim(IniRead(ConfigFile, name, "Hotkey", ""))
        hs  := Trim(IniRead(ConfigFile, name, "Hotstring", ""))
        win := Trim(IniRead(ConfigFile, name, "Window", ""))

        st.syncing := true
        ckUseHk.Value := (hk != "" || hs = "")
        ckUseHs.Value := (hs != "")
        edHs.Value    := (hs != "") ? hs : ";"
        edNotation.Value := hk
        st.syncing := false
        ParseNotation()

        lbWin.Delete()
        for rule in SplitWindowRules(win)
            lbWin.Add([rule])

        edPw1.Value := "", edPw2.Value := ""
        isSecret := IsSecretSection(name)
        st.editingSecret := isSecret
        rbSecret.Value := isSecret
        rbPlain.Value  := !isSecret
        edText.Value   := isSecret ? "" : TextForEdit(IniRead(ConfigFile, name, "Text", ""))
        ; login sequence
        edUser.Value := isSecret ? Trim(IniRead(ConfigFile, name, "Username", "")) : ""
        ddSep.Choose((Trim(IniRead(ConfigFile, name, "Separator", "Tab")) = "Enter") ? 2 : 1)
        ckSubmit.Value := isSecret && (Trim(IniRead(ConfigFile, name, "Submit", "0")) = "1")
        edDelay.Value  := ParseDelay(IniRead(ConfigFile, name, "Delay", ""))
        UpdateLoginState()
        btDelete.Enabled := true
        UpdateMode()
        ShowTypePanel()
    }

    ; Plain text <-> Secret
    TypeChanged() {
        ; Plain -> Secret: carry a one-line text over into the secret fields
        if (rbSecret.Value && edPw1.Value = "" && edPw2.Value = ""
                && edText.Value != "" && !InStr(edText.Value, "`n"))
            edPw1.Value := edText.Value, edPw2.Value := edText.Value
        ShowTypePanel()
    }

    ; "Then press" only matters when a username is set
    UpdateLoginState() {
        hasUser := (Trim(edUser.Value) != "")
        for c in [lbThen, ddSep, txThen]
            c.Enabled := hasUser
    }

    ShowTypePanel() {
        sec := rbSecret.Value
        for c in secretCtrls
            c.Visible := sec
        for c in plainCtrls
            c.Visible := !sec
        UpdatePwState()
    }

    UpdateMode() {
        hkOn := ckUseHk.Value
        for c in [ckCtrl, ckAlt, ckShift, ckWin, cbKey, edNotation]
            c.Enabled := hkOn
        edHs.Enabled := ckUseHs.Value
        UpdateVerdict()
    }

    ; Checkboxes + key  ->  notation
    BuildNotation() {
        if st.syncing
            return
        key := Trim(cbKey.Text)
        if (StrLen(key) = 1)
            key := StrLower(key)
        mods := (ckCtrl.Value ? "^" : "") (ckAlt.Value ? "!" : "")
              . (ckShift.Value ? "+" : "") (ckWin.Value ? "#" : "")
        st.syncing := true
        edNotation.Value := mods key
        st.syncing := false
        UpdateVerdict()
    }

    ; Notation typed by hand  ->  checkboxes + key
    ParseNotation() {
        if st.syncing
            return
        p := SplitHotkey(Trim(edNotation.Value))
        st.syncing := true
        ckCtrl.Value  := InStr(p.Mods, "^") > 0
        ckAlt.Value   := InStr(p.Mods, "!") > 0
        ckShift.Value := InStr(p.Mods, "+") > 0
        ckWin.Value   := InStr(p.Mods, "#") > 0
        ; only touch the key box when it really differs, so the caret does
        ; not jump while the user is typing a key name such as F12
        if (Trim(cbKey.Text) != p.Key)
            cbKey.Text := (StrLen(p.Key) = 1) ? StrUpper(p.Key) : p.Key
        st.syncing := false
        UpdateVerdict()
    }

    UpdateVerdict() {
        if !ckUseHk.Value {
            txPretty.Text := ""
            if !ckUseHs.Value
                return SetVerdict("Red", "Choose a hotkey, a hotstring, or both.")
            hs := Trim(edHs.Value)
            if (hs = "" || hs = ";")
                return SetVerdict("Gray", "Type an abbreviation, for example  `;pw1")
            return SetVerdict("Green", "Hotstrings never clash with application shortcuts.")
        }

        hk := Trim(edNotation.Value)
        p  := SplitHotkey(hk)
        txPretty.Text := PrettyHotkey(p)

        if (p.Key = "")
            return SetVerdict("Gray", "Choose a key.")
        if !IsKnownKey(p.Key)
            return SetVerdict("Red", "'" p.Key "' is not a key name AutoHotkey knows.")

        issues := CheckHotkey(hk)
        if HasBlock(issues)
            return SetVerdict("Red", "Blocked: " IssueText(issues, "Block"))

        dup := FindTriggerUser("Hotkey", hk, JoinWindowRules(), st.editing)
        if (dup != "")
            return SetVerdict("Red", "Already used by [" dup "] for the same windows.")

        if issues.Length
            return SetVerdict("Orange", "Warning: " IssueText(issues, "Warn"))
        return SetVerdict("Green", "No known conflict.")
    }

    SetVerdict(level, msg) {
        static colors := Map("Green", "c008000", "Orange", "cB06000"
                           , "Red", "cC00000", "Gray", "c808080")
        txVerdict.Opt(colors[level])
        txVerdict.Text := msg
    }

    AddWindowRule() {
        rule := Trim(edWin.Value)
        if (rule = "")
            return
        if InStr(rule, "|") {
            MsgBox("A window rule cannot contain  |", APP_NAME, "Icon! Owner" d.Hwnd)
            return
        }
        for existing in ControlGetItems(lbWin)
            if (existing = rule)
                return (edWin.Value := "")
        lbWin.Add([rule])
        edWin.Value := ""
        UpdateVerdict()
    }

    RemoveWindowRule() {
        if (lbWin.Value) {
            lbWin.Delete(lbWin.Value)
            UpdateVerdict()
        }
    }

    ; Hides the dialog, waits for the next left-click, and captures the
    ; title and program of the window that was clicked.
    PickWindow() {
        d.Hide()
        ToolTip("Click the window this snippet should type into.`n"
              . "Esc to cancel.")
        picked := 0
        start  := A_TickCount
        Loop {
            if GetKeyState("Escape", "P") || (A_TickCount - start > 20000)
                break
            if GetKeyState("LButton", "P") {
                KeyWait("LButton")
                Sleep(150)
                picked := WinExist("A")
                break
            }
            Sleep(30)
        }
        ToolTip()

        if picked {
            cls := WinGetClass(picked)
            if (cls ~= "^(Shell_TrayWnd|Shell_SecondaryTrayWnd|Progman|WorkerW)$") {
                picked := 0
                d.Show()
                MsgBox("That was the taskbar or desktop. Click Pick... again and "
                    . "click inside the target window.", APP_NAME, "Icon! Owner" d.Hwnd)
                return
            }
            title := WinGetTitle(picked)
            exe   := WinGetProcessName(picked)
            ; Titles can contain | which is the rule separator - drop it
            title := Trim(StrReplace(title, "|", " "))
            edWin.Value := (title != "" ? title " " : "") "ahk_exe " exe
        }
        d.Show()
        if picked {
            edWin.Focus()
            ToolTip("Shorten the title if it changes (file names, document "
                  . "names), then click Add.", , , 2)
            SetTimer(() => ToolTip(, , , 2), -4000)
        }
    }

    UpdatePwState() {
        a := edPw1.Value, b := edPw2.Value
        if (st.editing != "" && st.editingSecret && a = "" && b = "") {
            SendMessage(0x1501, 1, StrPtr("Leave empty to keep the current secret"), edPw1)
            txPw.Opt("c808080"), txPw.Text := "Editing [" st.editing "] - current secret kept"
        } else {
            SendMessage(0x1501, 1, StrPtr(""), edPw1)
            if (a = "" && b = "")
                txPw.Opt("c808080"), txPw.Text := ""
            else if (a == b)
                txPw.Opt("c008000"), txPw.Text := "Match"
            else
                txPw.Opt("cC00000"), txPw.Text := "Does not match"
        }
        a := b := ""
    }

    ; Called by the generator window with the value the user accepted
    UseGenerated(value) {
        edPw1.Value := value
        edPw2.Value := value
        value := ""
        UpdatePwState()
    }

    ToggleShow() {
        ch := ckShow.Value ? 0 : 0x25CF         ; 0 = visible, 0x25CF = dot
        for e in [edPw1, edPw2] {
            SendMessage(0xCC, ch, 0, e)         ; EM_SETPASSWORDCHAR
            e.Redraw()
        }
    }

    JoinWindowRules() {
        rules := ControlGetItems(lbWin)
        pending := Trim(edWin.Value)            ; typed but not yet added
        if (pending != "" && !InStr(pending, "|")) {
            found := false
            for r in rules
                if (r = pending)
                    found := true
            if !found
                rules.Push(pending)
        }
        out := ""
        for r in rules
            out .= (out = "" ? "" : " | ") r
        return out
    }

    SaveSnippet() {
        own := "Owner" d.Hwnd

        ; --- Name ---
        name := Trim(cbName.Text)
        if (name = "")
            return Fail("Please enter a name.")
        if (name ~= "[\[\]=]" || SubStr(name, 1, 1) = ";" || SubStr(name, 1, 1) = "~")
            return Fail("The name cannot contain  [  ]  =  or start with  `;  or  ~")
        if (name != st.editing && SectionExists(name))
            return Fail("A snippet named [" name "] already exists. "
                . "Pick it from the list to edit it, or choose another name.")

        ; --- Trigger ---
        hk := ckUseHk.Value ? Trim(edNotation.Value) : ""
        hs := ckUseHs.Value ? Trim(edHs.Value) : ""
        if (ckUseHs.Value && (hs = "" || hs = ";"))
            return Fail("Please type a hotstring, or untick Hotstring.")
        if (hk = "" && hs = "")
            return Fail("Choose a hotkey, a hotstring, or both.")
        winStr := JoinWindowRules()

        if (hk != "") {
            p := SplitHotkey(hk)
            if (p.Key = "" || !IsKnownKey(p.Key))
                return Fail("The hotkey has no valid key.")
            issues := CheckHotkey(hk)
            if HasBlock(issues)
                return Fail("Blocked: " IssueText(issues, "Block"))
            dup := FindTriggerUser("Hotkey", hk, winStr, st.editing)
            if (dup != "")
                return Fail("Hotkey " hk " is already used by [" dup "] for the same windows.")
            if (issues.Length && MsgBox("Warning: " IssueText(issues, "Warn")
                    . "`n`nUse this hotkey anyway?", APP_NAME, "YesNo Icon! " own) != "Yes")
                return
        }
        if (hs != "") {
            dup := FindTriggerUser("Hotstring", hs, winStr, st.editing)
            if (dup != "")
                return Fail("Hotstring " hs " is already used by [" dup "] for the same windows.")
        }

        ; --- Plain text ---
        if rbPlain.Value {
            text := edText.Value
            if (Trim(text, " `t`r`n") = "")
                return Fail("Please type the text.")
            if (st.editing != "" && st.editingSecret
                    && MsgBox("[" st.editing "] is a secret. Saving it as plain text "
                    . "stores the value UNENCRYPTED in the snippet file."
                    . "`n`nContinue?", APP_NAME, "YesNo Icon! Default2 " own) != "Yes")
                return
            try {
                SavePlainSnippet(ConfigFile, name, hk, hs, winStr, EscapeText(text))
                if (st.editing != "" && st.editing != name)
                    IniDelete(ConfigFile, st.editing)      ; renamed
            } catch as err {
                return Fail("Could not save: " err.Message)
            }
            CloseDialog()
            Reload()
            return
        }

        ; --- Secret ---
        if (winStr = "" && MsgBox("No window is listed, so this secret can be typed "
                . "into ANY window, including chat and email.`n`nSave anyway?"
                , APP_NAME, "YesNo Icon! " own) != "Yes")
            return

        keepOld := (st.editing != "" && st.editingSecret
            && edPw1.Value = "" && edPw2.Value = "")
        if keepOld {
            encrypted := Trim(IniRead(ConfigFile, st.editing, "Secret", ""))
        } else {
            if (edPw1.Value = "")
                return Fail("Please type the secret.")
            if !(edPw1.Value == edPw2.Value)
                return Fail("The two values do not match.")
            try
                encrypted := DpapiProtect(edPw1.Value)
            catch as err
                return Fail("Encryption failed: " err.Message)
        }

        login := {
            User:   Trim(edUser.Value),
            Sep:    ddSep.Text,
            Submit: ckSubmit.Value,
            Delay:  ParseDelay(edDelay.Value)
        }

        ; --- Write ---
        try {
            SaveSecretSnippet(ConfigFile, name, hk, hs, winStr, encrypted, login)
            if (st.editing != "" && st.editing != name)
                IniDelete(ConfigFile, st.editing)          ; renamed
        } catch as err {
            return Fail("Could not save: " err.Message)
        }

        CloseDialog()
        Reload()
    }

    DeleteSnippet() {
        if (st.editing = "")
            return
        if (MsgBox("Delete [" st.editing "]?`n`nThis cannot be undone."
                , APP_NAME, "YesNo Icon! Default2 Owner" d.Hwnd) != "Yes")
            return
        try IniDelete(ConfigFile, st.editing)
        catch as err
            return Fail("Could not delete: " err.Message)
        CloseDialog()
        Reload()
    }

    Fail(msg) {
        MsgBox(msg, APP_NAME, "Icon! Owner" d.Hwnd)
    }

    CloseDialog() {
        global SecretDlg
        edPw1.Value := "", edPw2.Value := "", edText.Value := ""
        d.Destroy()
        SecretDlg := ""
    }
}

; ---------------------------------------------------------------------
;  Helpers (no GUI state)
; ---------------------------------------------------------------------

; All snippet names (plain and secret), for the Name list
ListSnippetNames() {
    names := []
    try sections := IniRead(ConfigFile)
    catch
        return names
    for name in StrSplit(sections, "`n", "`r")
        if (name != "" && SubStr(name, 1, 1) != "~")    ; "~..." = app settings
            names.Push(name)
    return names
}

; File value -> text box: \n etc. decoded, line breaks as CR LF
TextForEdit(raw) => StrReplace(Unescape(raw), "`n", "`r`n")

; Text box -> file value. Exact inverse of Unescape() in Config.ahk:
; backslash first, then line breaks and tabs.
EscapeText(s) {
    s := StrReplace(s, "\", "\\")
    s := StrReplace(s, "`r`n", "\n")
    s := StrReplace(s, "`r", "\n")
    s := StrReplace(s, "`n", "\n")
    return StrReplace(s, "`t", "\t")
}

SectionExists(name) {
    try sections := IniRead(ConfigFile)
    catch
        return false
    for s in StrSplit(sections, "`n", "`r")
        if (s = name)
            return true
    return false
}

IsSecretSection(name) => (Trim(IniRead(ConfigFile, name, "Secret", "")) != "")

; Returns the name of another snippet using the same trigger for the same
; window rules, or "" if none. kind = "Hotkey" or "Hotstring".
FindTriggerUser(kind, trigger, winStr, selfName) {
    try sections := IniRead(ConfigFile)
    catch
        return ""
    want := (kind = "Hotkey") ? NormalizeHotkey(trigger) : trigger
    for name in StrSplit(sections, "`n", "`r") {
        if (name = "" || name = selfName)
            continue
        other := Trim(IniRead(ConfigFile, name, kind, ""))
        if (other = "")
            continue
        if (kind = "Hotkey")
            other := NormalizeHotkey(other)
        if (other != want)
            continue
        if (NormalizeWindowRules(IniRead(ConfigFile, name, "Window", ""))
                = NormalizeWindowRules(winStr))
            return name
    }
    return ""
}

NormalizeWindowRules(win) {
    out := ""
    for r in SplitWindowRules(win)
        out .= StrLower(r) "|"
    return out
}

IsKnownKey(key) {
    if (StrLen(key) = 1)
        return true
    return (GetKeyVK(key) || GetKeySC(key))
}

PrettyHotkey(p) {
    parts := []
    if InStr(p.Mods, "^")
        parts.Push("Ctrl")
    if InStr(p.Mods, "!")
        parts.Push(p.AltGr ? "AltGr" : "Alt")
    if InStr(p.Mods, "+")
        parts.Push("Shift")
    if InStr(p.Mods, "#")
        parts.Push("Win")
    if (p.Key != "")
        parts.Push(StrLen(p.Key) = 1 ? StrUpper(p.Key)
            : StrUpper(SubStr(p.Key, 1, 1)) SubStr(p.Key, 2))
    out := ""
    for x in parts
        out .= (out = "" ? "" : " + ") x
    return out
}

IssueText(issues, level) {
    out := ""
    for it in issues
        if (it.Level = level)
            out .= (out = "" ? "" : " ") it.Reason "."
    return out
}

KeyChoices() {
    keys := []
    Loop 26
        keys.Push(Chr(64 + A_Index))
    Loop 10
        keys.Push(String(A_Index - 1))
    Loop 12
        keys.Push("F" A_Index)
    Loop 10
        keys.Push("Numpad" (A_Index - 1))
    for k in ["Space", "Enter", "Tab", "Insert", "Delete", "Home", "End"
            , "PgUp", "PgDn", "Up", "Down", "Left", "Right", "Pause", "ScrollLock"]
        keys.Push(k)
    return keys
}
