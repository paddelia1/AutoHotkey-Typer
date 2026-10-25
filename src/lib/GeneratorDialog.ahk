/*
Script            : AutoHotkey-Typer - GeneratorDialog
FileName          : GeneratorDialog.ahk
Author            : Philippe Addelia
Created           : 2026-10-25 02:35 EDT
Modified          : 2026-10-25 02:35 EDT
Preferred Location: src\lib\
Version           : 1.1
Purpose           : Password / passphrase generator window, opened from the
                    Add / edit secret dialog. "Use this" hands the value
                    back to the caller; nothing is copied to the clipboard.
*/

; owner : the Gui that opened the generator (disabled while it is open)
; onUse : function called with the chosen value
ShowPasswordGenerator(owner, onUse) {
    static last := {Mode: "Password"
        , Length: 20, Upper: 1, Lower: 1, Digits: 1, Symbols: 1, NoAmbiguous: 1
        , Words: 6, SepIndex: 1, Capitalize: 1, AddNumber: 1}
    static SEPS := ["-", ".", "_", " ", ""]

    W  := 440
    PY := 56                                    ; top of the option panels
    g := Gui("+Owner" owner.Hwnd " +AlwaysOnTop -MinimizeBox"
        , APP_NAME " - Generate a secret")
    g.SetFont("s10", "Segoe UI")
    g.MarginX := 14, g.MarginY := 12

    rbPw := g.Add("Radio", "xm y14", "Password")
    rbPp := g.Add("Radio", "x+24 yp", "Passphrase (words)")
    g.Add("Text", "xm y+10 w" W " h1 0x10")

    ; ---------------- Password panel ----------------
    pw := []
    pw.Push(g.Add("Text", "xm y" PY " w110", "Length"))
    edLen := g.Add("Edit", "x+4 yp-3 w60 Number Limit2")
    udLen := g.Add("UpDown", "Range8-64", last.Length)
    pw.Push(edLen, udLen)
    pw.Push(g.Add("Text", "x+10 yp+3 cGray", "characters (8 - 64)"))
    ckUp  := g.Add("Checkbox", "xm y+14 w200", "Uppercase (A-Z)")
    ckLo  := g.Add("Checkbox", "x+10 yp w200", "Lowercase (a-z)")
    ckDi  := g.Add("Checkbox", "xm y+10 w200", "Digits (0-9)")
    ckSy  := g.Add("Checkbox", "x+10 yp w200", "Symbols (!@#$%...)")
    ckAmb := g.Add("Checkbox", "xm y+10 w" W, "Avoid look-alike characters (O 0 l 1 I |)")
    pw.Push(ckUp, ckLo, ckDi, ckSy, ckAmb)

    ; ---------------- Passphrase panel ----------------
    pp := []
    pp.Push(g.Add("Text", "xm y" PY " w110", "Words"))
    edWords := g.Add("Edit", "x+4 yp-3 w60 Number Limit2")
    udWords := g.Add("UpDown", "Range4-12", last.Words)
    pp.Push(edWords, udWords)
    pp.Push(g.Add("Text", "x+10 yp+3 cGray", "from a list of 7,772 words"))
    pp.Push(g.Add("Text", "xm y+14 w110", "Separator"))
    ddSep := g.Add("DropDownList", "x+4 yp-3 w170 Choose" last.SepIndex
        , ["- (hyphen)", ". (dot)", "_ (underscore)", "space", "(none)"])
    ckCap := g.Add("Checkbox", "xm y+14 w200", "Capitalize each word")
    ckNum := g.Add("Checkbox", "x+10 yp w200", "Add a number (10 - 99)")
    pp.Push(ddSep, ckCap, ckNum)

    ; ---------------- Result ----------------
    g.Add("Text", "xm y" (PY + 140) " w" W " h1 0x10")
    g.SetFont("s12", "Consolas")
    edOut := g.Add("Edit", "xm y+10 w" W " h30 ReadOnly -Wrap")
    g.SetFont("s10", "Segoe UI")
    txStrength := g.Add("Text", "xm y+8 w" W, "")
    g.Add("Text", "xm y+6 w" W " cGray"
        , "Keep a copy in your password manager as well. Encrypted secrets "
        . "cannot be recovered if this PC or your Windows profile is lost.")

    btAgain := g.Add("Button", "xm y+12 w130 h30", "Generate again")
    btUse   := g.Add("Button", "x+10 yp w130 h30 Default", "Use this")
    btCanc  := g.Add("Button", "x+10 yp w130 h30", "Cancel")

    ; ---------------- Initial values ----------------
    rbPw.Value  := (last.Mode = "Password")
    rbPp.Value  := (last.Mode != "Password")
    ckUp.Value  := last.Upper,  ckLo.Value := last.Lower
    ckDi.Value  := last.Digits, ckSy.Value := last.Symbols
    ckAmb.Value := last.NoAmbiguous
    ckCap.Value := last.Capitalize, ckNum.Value := last.AddNumber

    ; ---------------- Events ----------------
    for c in [rbPw, rbPp]
        c.OnEvent("Click", (*) => SwitchMode())
    for c in [ckUp, ckLo, ckDi, ckSy, ckAmb, ckCap, ckNum]
        c.OnEvent("Click", (*) => Regenerate())
    edLen.OnEvent("Change", (*) => (edLen.Value != "" ? Regenerate() : 0))
    edWords.OnEvent("Change", (*) => (edWords.Value != "" ? Regenerate() : 0))
    ddSep.OnEvent("Change", (*) => Regenerate())
    btAgain.OnEvent("Click", (*) => Regenerate())
    btUse.OnEvent("Click", (*) => Finish(true))
    btCanc.OnEvent("Click", (*) => Finish(false))
    g.OnEvent("Close", (*) => Finish(false))
    g.OnEvent("Escape", (*) => Finish(false))

    owner.Opt("+Disabled")
    SwitchMode()
    g.Show("AutoSize")
    return

    ; =================================================================

    SwitchMode() {
        isPw := rbPw.Value
        for c in pw
            c.Visible := isPw
        for c in pp
            c.Visible := !isPw
        Regenerate()
    }

    ReadOptions() {
        return {
            Length: Clamp(udLen.Value, 8, 64),
            Upper: ckUp.Value, Lower: ckLo.Value,
            Digits: ckDi.Value, Symbols: ckSy.Value, NoAmbiguous: ckAmb.Value,
            Words: Clamp(udWords.Value, 4, 12),
            Separator: SEPS[ddSep.Value],
            Capitalize: ckCap.Value, AddNumber: ckNum.Value
        }
    }

    Regenerate() {
        o := ReadOptions()
        try {
            if rbPw.Value {
                edOut.Value := GeneratePassword(o)
                bits := PasswordBits(o)
            } else {
                edOut.Value := GeneratePassphrase(o)
                bits := PassphraseBits(o)
            }
        } catch as err {
            edOut.Value := ""
            txStrength.Opt("cC00000")
            txStrength.Text := err.Message
            btUse.Enabled := false
            return
        }
        s := StrengthOf(bits)
        txStrength.Opt(s.Color)
        txStrength.Text := "Strength: " s.Label "   (about " s.Bits " bits of entropy)"
        btUse.Enabled := true
    }

    Finish(use) {
        value := edOut.Value
        ; remember the settings (not the value) for next time
        ; (properties are updated one by one - the static object itself is
        ;  never reassigned from inside this nested function)
        o := ReadOptions()
        last.Mode        := rbPw.Value ? "Password" : "Passphrase"
        last.Length      := o.Length
        last.Upper       := o.Upper
        last.Lower       := o.Lower
        last.Digits      := o.Digits
        last.Symbols     := o.Symbols
        last.NoAmbiguous := o.NoAmbiguous
        last.Words       := o.Words
        last.SepIndex    := ddSep.Value
        last.Capitalize  := o.Capitalize
        last.AddNumber   := o.AddNumber
        edOut.Value := ""
        owner.Opt("-Disabled")
        g.Destroy()
        owner.Show()
        if (use && value != "")
            onUse(value)
        value := ""
    }
}

Clamp(v, lo, hi) => (v = "" ? lo : Min(Max(v, lo), hi))
