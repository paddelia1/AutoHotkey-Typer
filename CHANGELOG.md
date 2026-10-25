# Changelog

## 1.5 - 2026-10-25

- **One snippet file again** - simpler than the 1.4 switch:
  - on the first start the snippet file is created from
    `examples/snippets.sample.ini`: a welcome note at the top plus the
    example snippets, so the app works immediately
  - tray > **Snippet file > Remove example snippets** deletes every snippet
    named `Ex - ...`; your own snippets and secrets are not touched
  - removed: My snippets / Example snippets switch, Copy examples,
    `settings.ini` and the separate example file (both deleted at startup
    if left over from 1.4); existing snippet files are not changed
- Fix: the example template is now really embedded in AHK-Typer.exe
  (Ahk2Exe only embeds files when `FileInstall` starts its own line)
- Docs updated for the single file

## 1.4 - 2026-10-25

- **AHK-Typer.exe**: distributed as a single executable on the GitHub
  Releases page - no AutoHotkey installation needed
  - `build/Build-AhkTyper.ps1` compiles it (no UPX packing, to limit
    antivirus false positives) and writes `AHK-Typer.exe.sha256` and
    `release-notes.md` with the SHA-256 and verification steps
- **Example snippets** (`examples/snippets.sample.ini`): 15 ready-made
  examples with no real data, embedded in the .exe
  - first start uses the examples; your own file is created empty
  - tray > **Snippet file**: My snippets / Example snippets, Copy examples
    into my snippets, Edit my snippet file, Open snippet folder
  - the active set is stored in `settings.ini`; existing installations
    stay on My snippets
  - Add / edit snippet is not available on the read-only examples and
    offers to switch
- Docs: new `docs/examples.md` (try the examples, first snippet, recipes,
  choosing triggers, troubleshooting); README download / verify section;
  setup guide: install options, file locations, "Where snippets cannot type"
- Hotkey guide: Windows 11 Win + Alt shortcuts noted

## 1.3 - 2026-10-25

- **Login sequences**: a secret can type a username first -
  username, Tab (or Enter), secret, optional Enter - in one hotkey
  - new optional keys `Username=`, `Separator=`, `Submit=`, `Delay=`
  - fields in Add / edit snippet (type Secret): Username, Then press,
    Press Enter after the secret, Delay
  - waits for the hotkey's Ctrl / Alt / Shift / Win to be released first,
    so Tab and Enter are not sent as Ctrl+Tab or Alt+Enter
  - switching a secret to plain text removes the login keys
- Plain text box in the dialog is taller (9 lines)
- README roadmap rewritten to show the real status

## 1.2 - 2026-10-25

- **Add / edit snippet**: the secret dialog now handles plain snippets too
  - Type: Plain text or Secret (encrypted)
  - plain text in a multi-line box; line breaks, tabs and backslashes are
    converted to `\n`, `\t`, `\\` automatically
  - hotkey builder, conflict checker and window list with **Pick...** now
    work for plain snippets
  - Name list shows all snippets
  - **Delete** button for the snippet being edited
  - switching Plain -> Secret encrypts and removes the `Text=` line;
    Secret -> Plain asks for confirmation and removes the `Secret=` line
- Tray: **Add / edit snippet** is the first item and the double-click
  action; Notepad editing renamed **Edit snippet file**

## 1.1.1 - 2026-10-25

- Own tray icon: red square with a white "T" (`src/res/AutoHotkey-Typer.ico`),
  replacing the stock AutoHotkey icon. Also shown in the app's dialogs
- Grey icon and "SUSPENDED" tooltip while suspended
- Ahk2Exe directives embed both icons when compiled

## 1.1.0.1 - 2026-10-25

- Fix: in Add / edit secret, the hint under the window list overlapped the
  list frame (it was placed below the shorter Remove button)

## 1.1 - 2026-10-25

- **Password generator**: **Generate...** button in the Add / edit secret
  window (`src/lib/GeneratorDialog.ahk`, `src/lib/PwGen.ahk`)
  - passwords 8 - 64 characters, choice of character sets, option to avoid
    look-alike characters
  - passphrases of 4 - 12 words from the EFF Large Wordlist (7,772 words,
    `src/lib/Wordlist.ahk`), separator, capitalization, optional number
  - Windows `BCryptGenRandom` with rejection sampling (no modulo bias)
  - strength meter from the settings; defaults are Strong (passphrase,
    about 84 bits) and Very strong (password, about 122 bits)
  - "Use this" fills Secret and Confirm; nothing is copied to the clipboard
  - settings are remembered until the app is restarted
- Secret dialog state handling made more robust (state object)
- README: Credits section for the EFF word list (CC BY 3.0 US)

## 1.0.3.2 - 2026-10-25

- Docs: "Work and personal computers" - keep one snippet file per computer,
  work secrets on the work PC only, personal secrets on the personal PC only

## 1.0.3.1 - 2026-10-25

- Docs: "How hard is it to decrypt a dpapi1: value?" and "Securing your
  dpapi1: secrets" added to `docs/setup-and-security.md`
- Docs and `Dpapi.ahk` comment: corrected the description of the DPAPI
  "entropy" value - it is public, not a protection against programs
  running as you

## 1.0.3 - 2026-10-24

- **Add / edit secret** is now one window (`src/lib/SecretDialog.ahk`)
  instead of a chain of input boxes:
  - pick an existing secret to edit it; leave the value empty to keep it
  - hotkey builder: Ctrl / Alt / Shift / Win checkboxes and a key list, live
    AHK notation, readable form and a colored conflict verdict
  - several allowed windows per secret, with **Pick...** to capture one
  - Show checkbox and a live "Match" indicator for the two value fields
- `Window=` accepts several rules separated by `|`
- Saving a secret keeps `Enabled` and `AllowRisky` settings
- Docs: Remote Desktop sessions and multi-window rules

## 1.0.2.1 - 2026-10-24

- Fix: script did not start - a `;` after a space inside quoted strings in
  `Tray.ahk` was read as a comment. Escaped as `` `; ``

## 1.0.2 - 2026-10-24

Encryption and safety.

- `Secret=` entries encrypted with Windows DPAPI (`src/lib/Dpapi.ahk`),
  decrypted only at the moment they are typed
- Tray menu **Add secret...**: hidden input typed twice, only the encrypted
  form is written to the file
- Unencrypted or undecryptable `Secret=` values are refused at startup
- Warning when a secret has no `Window=` restriction
- Shortcut checker (`src/lib/Checker.ahk`): blocks hotkeys reserved by
  Windows or that would stop normal typing; warns about common application
  shortcuts and the AltGr (Ctrl + Alt) trap. `AllowRisky=1` silences a warning
- Warning when the snippet file is inside a cloud-synced folder
- `.gitignore` reduced to AutoHotkey-Typer entries only
- Documentation: `docs/setup-and-security.md`

## 1.0.1 - 2026-10-24

Phase 1 - core engine.

- Snippets triggered by hotkeys and hotstrings, read from `snippets.ini`
- Optional per-snippet window restriction (`Window=`)
- `\n`, `\t`, `\\` escapes in snippet text
- Duplicate and invalid triggers reported at startup
- Sample snippet file created on first run in `%AppData%\AutoHotkey-Typer`
- Portable mode: `snippets.ini` next to the script takes priority
- Tray menu: Edit snippets, Open snippet folder, Reload, Suspend, About, Exit
- Documentation: `docs/hotkey-notation.md`
