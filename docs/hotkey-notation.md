# Reading and writing hotkeys

Version: 1.4

AutoHotkey writes key combinations with short symbols. This page explains
them, shows which combinations are safe, and which ones to avoid.

## The four modifier symbols

| Symbol | Key   | Memory aid                      |
|--------|-------|---------------------------------|
| `^`    | Ctrl  | the "control" caret             |
| `!`    | Alt   | "alt-ernative" - an exclamation |
| `+`    | Shift | add (shift) a capital           |
| `#`    | Win   | the Windows key                 |

Combine them in front of the key. Order does not matter: `^!k` and `!^k`
are the same.

| You write | You press                    |
|-----------|------------------------------|
| `^k`      | Ctrl + K                     |
| `^+k`     | Ctrl + Shift + K             |
| `^!+k`    | Ctrl + Alt + Shift + K       |
| `#!k`     | Win + Alt + K                |
| `^!F5`    | Ctrl + Alt + F5              |

Letters are case-insensitive: `^!K` is the same as `^!k`. To require Shift,
add `+`.

## Key names

Letters and digits are written as themselves. Other keys use names:

| Key                | Name in a hotkey            |
|--------------------|-----------------------------|
| Function keys      | `F1` ... `F24`              |
| Enter, Tab, Space  | `Enter`, `Tab`, `Space`     |
| Arrows             | `Up`, `Down`, `Left`, `Right` |
| Home, End, PgUp    | `Home`, `End`, `PgUp`, `PgDn` |
| Insert, Delete     | `Insert`, `Delete`          |
| Numeric keypad     | `Numpad0` ... `Numpad9`, `NumpadAdd` |
| Pause, ScrollLock  | `Pause`, `ScrollLock`       |

Example: `^!Numpad1` = Ctrl + Alt + keypad 1.

## Left or right modifier only

Put `<` (left) or `>` (right) directly before a modifier:

| You write | Meaning                          |
|-----------|----------------------------------|
| `<^k`     | Left Ctrl + K only               |
| `>!k`     | Right Alt + K only               |

Note: on many European keyboards the right Alt key is **AltGr** (see below).

## Prefix flags (advanced)

| Flag | Effect                                                         |
|------|----------------------------------------------------------------|
| `~`  | The key still does its normal job as well as the snippet       |
| `*`  | Fires even if extra modifiers are held down                    |
| `$`  | Prevents a hotkey from triggering itself (rarely needed here)  |

You will rarely need these for snippets. Leave them out unless you know why.

## Hotstrings - the conflict-free alternative

A hotstring is a short abbreviation you type, such as `;em`. AutoHotkey-Typer
erases it and types the snippet instead.

- It never collides with an application's keyboard shortcut.
- Start abbreviations with a character you rarely type, such as `;` or `,,`.
- Do not make one abbreviation the start of another. With `;em` and
  `;email`, the first one fires before you can finish the second.

## Combinations to avoid

These are used by Windows or by almost every application.

| Avoid                                   | Why                                  |
|-----------------------------------------|--------------------------------------|
| Ctrl + C / V / X / Z / Y / A / S        | Copy, paste, cut, undo, redo, select all, save |
| Ctrl + F / G / H / N / O / P / W        | Find, find next, replace, new, open, print, close |
| Ctrl + T / Tab / 1-9                    | Browser tabs                         |
| Ctrl + U / B / I                        | Underline, bold, italic              |
| Alt + Tab, Alt + F4, Alt + Esc          | Windows task switching and closing   |
| Win + L / D / E / R / Tab / arrows      | Lock, desktop, Explorer, Run, Task View, snapping |
| Ctrl + Alt + Delete, Ctrl + Shift + Esc | Reserved by Windows                  |
| F1 - F12 alone                          | Help, rename, refresh and many app commands |

## The AltGr trap (European keyboards)

On Swiss, German, French and many other layouts, **AltGr is the same signal
as Ctrl + Alt**. Characters you type every day depend on it:

| Swiss French layout | Types |
|---------------------|-------|
| AltGr + 2           | `@`   |
| AltGr + 3           | `#`   |
| AltGr + E           | euro sign |

So a hotkey such as `^!2` (Ctrl + Alt + 2) would stop you from typing `@`
on those keyboards. Adding Shift usually avoids the clash: `^!+2`.

## Safe patterns

| Pattern                  | Example   | Notes                                  |
|--------------------------|-----------|----------------------------------------|
| Ctrl + Alt + Shift + key | `^!+e`    | Almost never used by applications      |
| Win + Alt + key          | `#!e`     | Windows 11 uses a few: Win + Alt + B, D, K, R and Print Screen |
| Hotstring                | `;em`     | No conflicts at all                    |
| Window-restricted        | `^+e` with `Window=ahk_exe ssms.exe` | Only active in one program |

## The built-in checker

AutoHotkey-Typer applies these rules at startup, and live in the
**Add / edit snippet** window while you build a hotkey:

| Result | Meaning                                                          |
|--------|------------------------------------------------------------------|
| Block  | Reserved by Windows, or would stop you typing a character. The hotkey is not bound |
| Warn   | Clashes with a common shortcut or AltGr. The hotkey works, and the warning is shown at startup |

If you really want a flagged hotkey (for example Ctrl + Shift + T inside one
program only), add `AllowRisky=1` to that snippet to silence its warning.
Blocked hotkeys cannot be overridden.
