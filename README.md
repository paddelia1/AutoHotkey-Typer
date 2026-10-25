# AutoHotkey-Typer
Build a secure AutoHotkey 2.0 typer for strings, passwords and more 

**Version 1.6** - download **AHK-Typer.exe** from the
[latest release](https://github.com/paddelia1/AutoHotkey-Typer/releases/latest)

AutoHotkey-Typer types text you use often - email addresses, signatures,
SQL snippets, URLs, passwords - when you press a key combination or type a
short abbreviation. It is written in AutoHotkey v2 and ships as a single
`.exe`: no installer, no AutoHotkey needed, no libraries, no network access.

## Download and verify

1. Open the [latest release](https://github.com/paddelia1/AutoHotkey-Typer/releases/latest) and download **AHK-Typer.exe**.
2. Check the file: the release notes list its **SHA-256** (also attached as
   `AHK-Typer.exe.sha256`). In PowerShell, in the download folder:

   ```powershell
   (Get-FileHash .\AHK-Typer.exe -Algorithm SHA256).Hash
   ```

   The result must match the release notes (upper or lower case does not
   matter). All versions and their hashes: [Releases](https://github.com/paddelia1/AutoHotkey-Typer/releases).
3. Run it. Windows may show *"Windows protected your PC"* because the file
   is not code-signed: choose **More info > Run anyway**.

The red **T** icon appears in the system tray.

## Features

- Snippets triggered by a **hotkey** (for example Ctrl + Alt + Shift + S)
  or a **hotstring** (type `;em` and it becomes your email address)
- **Encrypted secrets** with Windows DPAPI - only your Windows account on
  your PC can decrypt them. Added from the tray menu, never typed into the
  file by hand
- Secrets are decrypted only at the moment they are typed
- **Optional secret lock**: after you have been away, the next secret asks
  for your PIN once - never while you are working, never after unlocking
  Windows, never for plain snippets
- **Login sequences**: one hotkey types username, Tab, password and Enter -
  for VPN clients, web logins, database tools
- One-page **Add / edit snippet** window for plain text and secrets: hotkey
  builder with Ctrl / Alt / Shift / Win checkboxes, live notation and
  conflict verdict, window picker, Delete. No need to edit the file by hand
- **Password generator** built into the secret window: passwords (8 - 64
  characters) or passphrases from the 7,772-word EFF list, using the
  Windows cryptographic random generator. Defaults are rated **Strong** or
  better, and the result goes straight into the encrypted secret
- Snippets can be limited to one or more programs or windows
- **Shortcut checker**: hotkeys that would break Windows are refused;
  hotkeys that clash with common shortcuts (Ctrl+T, Ctrl+C, AltGr...) are
  reported
- **Works on the first start**: your snippet file is created with example
  snippets to try right away; remove them in one click when you are ready
- Text is typed exactly as written (no AutoHotkey escaping), and the
  clipboard is never used
- Duplicate and invalid triggers are reported at startup, not silently ignored
- Tray menu: Add / edit snippet (also on double-click), Snippet file
  (edit, open folder, remove example snippets), Reload, Suspend, About,
  Exit. Red tray icon, grey while suspended
- Snippet file stored in `%AppData%\AutoHotkey-Typer`, outside OneDrive and
  git folders, with a warning if it ends up in a synced folder

## Quick start

1. Start **AHK-Typer.exe** (or `src\AutoHotkey-Typer.ahk` with
   [AutoHotkey v2](https://www.autohotkey.com/v2/) installed).
2. It works right away: your snippet file is created with **example
   snippets**. Type `;addr` anywhere, or `;hi` in Notepad, or press
   **Ctrl + Alt + Shift + S**. All examples: [docs/examples.md](docs/examples.md).
3. Add your own: double-click the tray icon to open **Add / edit snippet**,
   choose **Plain text** or **Secret (encrypted)**, set a trigger, **Save**.
4. When you no longer need the examples (named `Ex - ...`): right-click the
   tray icon > **Snippet file > Remove example snippets**. Your own
   snippets are not touched.
5. To start it automatically when you sign in to Windows, see
   [Start automatically](docs/setup-and-security.md#start-automatically-when-you-sign-in-to-windows)
   in the setup guide.

## Snippet file

You normally never edit it - **Add / edit snippet** writes it for you. It
looks like this:

```ini
[Email]
Hotstring=;em
Text=you@example.com

[Signature]
Hotkey=^!+s
Text=Best regards,\nYour Name

[SQL template]
Hotkey=^!+q
Text=SELECT TOP (100)\n     t.Column1\n    ,t.Column2\nFROM dbo.TableName AS t;
Window=ahk_exe Ssms.exe | ahk_exe Code.exe

[VPN login]
Hotkey=^!+l
Username=jdoe
Secret=dpapi1:AQAAANCMnd8B...
Window=ahk_exe vpnui.exe
Submit=1
```

| Key         | Meaning                                                        |
|-------------|----------------------------------------------------------------|
| `Hotkey`    | Key combination in AutoHotkey notation - see [docs/hotkey-notation.md](docs/hotkey-notation.md) |
| `Hotstring` | Abbreviation replaced as you type                              |
| `Text`      | What gets typed. `\n` = Enter, `\t` = Tab, `\\` = backslash    |
| `Secret`    | Encrypted value (`dpapi1:...`), created with **Add / edit snippet** in the tray menu |
| `Window`    | Optional. Part of a window title, or `ahk_exe program.exe`. Several windows: separate with `\|`. Recommended for secrets |
| `Username`  | Secrets only: typed first, then Tab, then the secret (login sequence) |
| `Separator` | `Tab` (default) or `Enter` between username and secret         |
| `Submit`    | `1` presses Enter after the secret                             |
| `Delay`     | Milliseconds between login steps (default `150`)               |
| `AllowRisky`| `1` silences the checker's warning for this hotkey             |
| `Enabled`   | `1` or `0` (default `1`)                                       |

Each snippet needs a `Hotkey`, a `Hotstring`, or both, and a `Text` or a
`Secret`.

**Where it lives:** `%AppData%\AutoHotkey-Typer\snippets.ini` - one file,
yours. **Portable mode:** put a `snippets.ini` next to the `.exe` (or
script) and it is used instead.

> **Security:** `Text=` values are plain text - use the **Secret** type in **Add / edit snippet** for
> passwords and keys. Prerequisites, safe storage and how the encryption works
> are in [docs/setup-and-security.md](docs/setup-and-security.md).

## Hotkey symbols at a glance

| Symbol | Key   |
|--------|-------|
| `^`    | Ctrl  |
| `!`    | Alt   |
| `+`    | Shift |
| `#`    | Win   |

`^!+e` = Ctrl + Alt + Shift + E. The full guide, including which combinations
to avoid and the AltGr trap on European keyboards, is in
[docs/hotkey-notation.md](docs/hotkey-notation.md).

## Roadmap

| Area | Content | Status |
|------|---------|--------|
| Engine | Hotkeys, hotstrings, window filters (several per snippet), tray menu, own icon | Done |
| Secrets | DPAPI encryption, masked entry, decrypt only when typed | Done |
| Generator | Passwords and EFF-list passphrases, cryptographic randomness | Done |
| Snippet dialog | Add / edit / delete plain snippets and secrets, hotkey builder, window picker | Done |
| Conflict checker | Reserved Windows shortcuts, common app shortcuts, AltGr warning, live verdict | Done |
| Login sequence | Username, Tab, password, optional Enter, in one hotkey | Done |
| Secret lock | Optional PIN after being away; Windows unlock counts as proof | Done |
| Examples | Example snippets created in your file on the first start, removable in one click | Done |
| Release | AHK-Typer.exe with SHA-256 in the release notes, build script | Done |
| Docs | Where snippets cannot type (Windows credential dialogs, elevated windows), examples guide | Done |
| Feedback | Tray message when a filtered snippet does not fire, naming the active window | Next |
| Snippet list | Table of all snippets with Enable / Disable | Planned |
| Conflict checker | Hotkeys already taken by other running apps; layout-aware AltGr check | Planned |
| Screenshots | Dialog and tray screenshots in the README | Planned |

## Project layout

```
src/AutoHotkey-Typer.ahk     main script (compiles to AHK-Typer.exe)
src/lib/                     Config, Engine, Tray, Dpapi, Checker, SecretDialog,
                             PwGen, GeneratorDialog, Wordlist
src/res/                     tray icons (active, suspended)
examples/snippets.sample.ini first-run template: welcome note + example snippets, embedded in the .exe
build/Build-AhkTyper.ps1     builds dist/AHK-Typer.exe, its SHA-256 and release notes
docs/                        user documentation
dist/                        build output (not committed - published as Releases)
```

### Building the .exe yourself

Requires AutoHotkey v2 with its Ahk2Exe compiler. From the repo folder:

```powershell
.\build\Build-AhkTyper.ps1
```

It writes `dist\AHK-Typer.exe`, `dist\AHK-Typer.exe.sha256` and
`dist\release-notes.md`, and prints the command to publish the release.

## Documentation

- [Examples](docs/examples.md) - ready-made recipes to learn the tool fast
- [Setup and security](docs/setup-and-security.md) - prerequisites, where the
  file lives, where snippets cannot type, encryption, safe-storage checklist
- [Reading and writing hotkeys](docs/hotkey-notation.md) - `^ ! + #`, keys to
  avoid, the AltGr trap

## License

Apache 2.0 - see [LICENSE](LICENSE).

## Credits

Passphrases use the **EFF Large Wordlist** by the Electronic Frontier
Foundation ([eff.org/dice](https://www.eff.org/dice)), licensed under
[CC BY 3.0 US](https://creativecommons.org/licenses/by/3.0/us/). The four
hyphenated words were removed; see `src/lib/Wordlist.ahk`.

---

Copyright 2026 Philippe Addelia
