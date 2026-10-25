/*
Script            : AutoHotkey-Typer - PwGen
FileName          : PwGen.ahk
Author            : Philippe Addelia
Created           : 2026-10-25 02:35 EDT
Modified          : 2026-10-25 02:35 EDT
Preferred Location: src\lib\
Version           : 1.1
Purpose           : Password and passphrase generation (no GUI).
                    Randomness comes from Windows BCryptGenRandom (the
                    system cryptographic generator), with rejection sampling
                    so every character / word is equally likely.
                    Based on the logic of PasswordGenerator.ahk.
*/

global PWGEN_SETS := Map(
    "Upper",   "ABCDEFGHIJKLMNOPQRSTUVWXYZ",
    "Lower",   "abcdefghijklmnopqrstuvwxyz",
    "Digits",  "0123456789",
    "Symbols", "!@#$%^&*()-_=+[]{}:,.?"
)
; Characters that are easy to confuse when read or typed by hand
global PWGEN_AMBIGUOUS := "O0oIl1|`"'``{}[]()/\:.,"

; ---------------------------------------------------------------------
;  Secure random integer in [0, n - 1]
; ---------------------------------------------------------------------
SecureRandInt(n) {
    static buf := Buffer(4, 0)
    if (n < 1 || n > 0xFFFFFFFF)
        throw ValueError("SecureRandInt: range out of bounds")
    limit := 0x100000000 - Mod(0x100000000, n)    ; reject the biased tail
    Loop {
        status := DllCall("bcrypt\BCryptGenRandom", "Ptr", 0, "Ptr", buf
            , "UInt", 4, "UInt", 0x2, "UInt")      ; 0x2 = system preferred RNG
        if (status != 0)
            throw OSError(status, -1, "BCryptGenRandom failed")
        v := NumGet(buf, 0, "UInt")
        if (v < limit)
            return Mod(v, n)
    }
}

SecureRandChar(str) => SubStr(str, SecureRandInt(StrLen(str)) + 1, 1)

; ---------------------------------------------------------------------
;  Password
;    opts: {Length, Upper, Lower, Digits, Symbols, NoAmbiguous}
;  At least one character from each selected set is guaranteed.
; ---------------------------------------------------------------------
PasswordPool(opts) {
    sets := []
    for key in ["Upper", "Lower", "Digits", "Symbols"] {
        if !opts.%key%
            continue
        s := PWGEN_SETS[key]
        if opts.NoAmbiguous
            s := StripChars(s, PWGEN_AMBIGUOUS)
        if (s != "")
            sets.Push(s)
    }
    return sets
}

GeneratePassword(opts) {
    sets := PasswordPool(opts)
    if (sets.Length = 0)
        throw ValueError("Select at least one character type")
    pool := ""
    for s in sets
        pool .= s

    len   := Max(opts.Length, sets.Length)
    chars := []
    for s in sets                               ; one from each set
        chars.Push(SecureRandChar(s))
    Loop len - sets.Length
        chars.Push(SecureRandChar(pool))

    ; Fisher-Yates shuffle with the secure generator
    i := chars.Length
    while (i > 1) {
        j := SecureRandInt(i) + 1
        tmp := chars[i], chars[i] := chars[j], chars[j] := tmp
        i--
    }
    out := ""
    for c in chars
        out .= c
    return out
}

; Entropy from the SETTINGS (not from the result), in bits
PasswordBits(opts) {
    size := 0
    for s in PasswordPool(opts)
        size += StrLen(s)
    return (size < 2) ? 0 : Max(opts.Length, 1) * Log2(size)
}

; ---------------------------------------------------------------------
;  Passphrase
;    opts: {Words, Separator, Capitalize, AddNumber}
; ---------------------------------------------------------------------
GeneratePassphrase(opts) {
    list   := EffWordList()
    phrase := ""
    Loop opts.Words {
        w := list[SecureRandInt(list.Length) + 1]
        if opts.Capitalize
            w := StrUpper(SubStr(w, 1, 1)) SubStr(w, 2)
        phrase .= (A_Index > 1 ? opts.Separator : "") w
    }
    if opts.AddNumber
        phrase .= opts.Separator (SecureRandInt(90) + 10)     ; 10 - 99
    return phrase
}

PassphraseBits(opts) {
    bits := opts.Words * Log2(EffWordList().Length)
    if opts.AddNumber
        bits += Log2(90)
    return bits
}

; ---------------------------------------------------------------------
;  Strength label - same thresholds as PasswordGenerator.ahk
;  Returns {Label, Color, Bits}
; ---------------------------------------------------------------------
StrengthOf(bits) {
    bits := Round(bits)
    if (bits < 45)
        return {Label: "Weak",        Color: "cC00000", Bits: bits}
    if (bits < 70)
        return {Label: "Fair",        Color: "cB06000", Bits: bits}
    if (bits < 100)
        return {Label: "Strong",      Color: "c008000", Bits: bits}
    return {Label: "Very strong", Color: "c006000", Bits: bits}
}

; ---------------------------------------------------------------------
;  Helpers
; ---------------------------------------------------------------------
Log2(x) => Ln(x) / Ln(2)

StripChars(s, remove) {
    out := ""
    Loop Parse s
        if !InStr(remove, A_LoopField, true)
            out .= A_LoopField
    return out
}
