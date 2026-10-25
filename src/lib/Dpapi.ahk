/*
Script            : AutoHotkey-Typer - Dpapi
FileName          : Dpapi.ahk
Author            : Philippe Addelia
Created           : 2026-10-24 14:10 EDT
Modified          : 2026-10-25 02:25 EDT
Preferred Location: src\lib\
Version           : 1.0.3.1
Purpose           : Encrypts and decrypts secrets with Windows DPAPI
                    (CryptProtectData / CryptUnprotectData in crypt32.dll).
                    Only the same Windows user account can decrypt.
                    No passwords to manage, nothing extra to install.

Stored format     : dpapi1:<base64 of the DPAPI blob>
                    The text is UTF-8 encoded before encryption.
*/

global DPAPI_PREFIX  := "dpapi1:"
; Extra "entropy" mixed into every blob. It is NOT a secret - it is in
; this public source code. It only stops generic tools that decrypt DPAPI
; data without an entropy value from reading these blobs blindly.
; See docs\setup-and-security.md - "How hard is it to decrypt".
global DPAPI_ENTROPY := "AutoHotkey-Typer/secret/v1"

; ---------------------------------------------------------------------
;  Public functions
; ---------------------------------------------------------------------

; Plain text -> "dpapi1:..." string. Throws on failure.
DpapiProtect(plain) {
    if (plain = "")
        throw ValueError("Nothing to encrypt")

    inBuf  := Utf8Buffer(plain, &inSize)
    inBlob := MakeBlob(inBuf, inSize)
    entBuf := Utf8Buffer(DPAPI_ENTROPY, &entSize)
    entBlob := MakeBlob(entBuf, entSize)
    outBlob := Buffer(A_PtrSize * 2, 0)

    ok := DllCall("Crypt32\CryptProtectData"
        , "Ptr",  inBlob        ; data in
        , "Ptr",  0             ; description (not used)
        , "Ptr",  entBlob       ; optional entropy
        , "Ptr",  0             ; reserved
        , "Ptr",  0             ; prompt struct (none)
        , "UInt", 0x1           ; CRYPTPROTECT_UI_FORBIDDEN
        , "Ptr",  outBlob       ; data out
        , "Int")
    WipeBuffer(inBuf)           ; do not leave the plain text lying around
    if !ok
        throw OSError(A_LastError, -1, "CryptProtectData failed")

    outSize := NumGet(outBlob, 0, "UInt")
    outPtr  := NumGet(outBlob, A_PtrSize, "Ptr")
    try
        b64 := Base64Encode(outPtr, outSize)
    finally
        DllCall("Kernel32\LocalFree", "Ptr", outPtr)

    return DPAPI_PREFIX b64
}

; "dpapi1:..." string -> plain text. Throws on failure, for example when
; the value was encrypted under another Windows account or on another PC.
DpapiUnprotect(stored) {
    if !IsDpapiValue(stored)
        throw ValueError("Not an encrypted value (missing " DPAPI_PREFIX " prefix)")

    raw    := Base64Decode(SubStr(stored, StrLen(DPAPI_PREFIX) + 1), &rawSize)
    inBlob := MakeBlob(raw, rawSize)
    entBuf := Utf8Buffer(DPAPI_ENTROPY, &entSize)
    entBlob := MakeBlob(entBuf, entSize)
    outBlob := Buffer(A_PtrSize * 2, 0)

    ok := DllCall("Crypt32\CryptUnprotectData"
        , "Ptr",  inBlob
        , "Ptr",  0             ; description out (not wanted)
        , "Ptr",  entBlob
        , "Ptr",  0
        , "Ptr",  0
        , "UInt", 0x1           ; CRYPTPROTECT_UI_FORBIDDEN
        , "Ptr",  outBlob
        , "Int")
    if !ok
        throw OSError(A_LastError, -1, "CryptUnprotectData failed")

    outSize := NumGet(outBlob, 0, "UInt")
    outPtr  := NumGet(outBlob, A_PtrSize, "Ptr")
    plain   := StrGet(outPtr, outSize, "UTF-8")
    WipeMemory(outPtr, outSize)
    DllCall("Kernel32\LocalFree", "Ptr", outPtr)
    return plain
}

IsDpapiValue(s) => (SubStr(s, 1, StrLen(DPAPI_PREFIX)) = DPAPI_PREFIX)

; ---------------------------------------------------------------------
;  Helpers
; ---------------------------------------------------------------------

; String -> UTF-8 bytes (no terminating null). Size returned in &size.
Utf8Buffer(s, &size) {
    size := StrPut(s, "UTF-8") - 1
    buf  := Buffer(size + 1, 0)
    StrPut(s, buf, "UTF-8")
    return buf
}

; DATA_BLOB { DWORD cbData; BYTE *pbData; } - pointer is aligned on x64
MakeBlob(buf, size) {
    blob := Buffer(A_PtrSize * 2, 0)
    NumPut("UInt", size, blob, 0)
    NumPut("Ptr", buf.Ptr, blob, A_PtrSize)
    return blob
}

Base64Encode(ptr, size) {
    flags := 0x40000001         ; CRYPT_STRING_BASE64 | CRYPT_STRING_NOCRLF
    chars := 0
    if !DllCall("Crypt32\CryptBinaryToStringW", "Ptr", ptr, "UInt", size
            , "UInt", flags, "Ptr", 0, "UInt*", &chars)
        throw OSError(A_LastError, -1, "Base64 encode failed")
    out := Buffer(chars * 2, 0)
    if !DllCall("Crypt32\CryptBinaryToStringW", "Ptr", ptr, "UInt", size
            , "UInt", flags, "Ptr", out, "UInt*", &chars)
        throw OSError(A_LastError, -1, "Base64 encode failed")
    return StrGet(out, "UTF-16")
}

Base64Decode(b64, &size) {
    size := 0
    if !DllCall("Crypt32\CryptStringToBinaryW", "Str", b64, "UInt", 0
            , "UInt", 0x1, "Ptr", 0, "UInt*", &size, "Ptr", 0, "Ptr", 0)
        throw ValueError("The encrypted value is damaged (not valid base64)")
    buf := Buffer(size, 0)
    if !DllCall("Crypt32\CryptStringToBinaryW", "Str", b64, "UInt", 0
            , "UInt", 0x1, "Ptr", buf, "UInt*", &size, "Ptr", 0, "Ptr", 0)
        throw ValueError("The encrypted value is damaged (not valid base64)")
    return buf
}

WipeBuffer(buf) => WipeMemory(buf.Ptr, buf.Size)

WipeMemory(ptr, size) {
    Loop size
        NumPut("UChar", 0, ptr, A_Index - 1)
}
