# Setup and security guide

Version: 1.5.0.1

This guide covers what you need to run AutoHotkey-Typer, where your snippet
file lives, how secrets are encrypted, and how to keep the real file safe.

## 1. Prerequisites

| Requirement | Needed? | Notes |
|---|---|---|
| Windows 10 or 11 | Yes | Encryption uses Windows DPAPI, built into every supported Windows version |
| [AutoHotkey v2.0](https://www.autohotkey.com/v2/) or later | Only to run the `.ahk` source | **Not needed for AHK-Typer.exe** from the Releases page. The script refuses to start on v1 |
| Administrator rights | No | Installs and runs as a normal user |
| Ahk2Exe (AutoHotkey compiler) | Optional | Only to build your own `.exe`. Offered by the AutoHotkey v2 installer / Dash |
| VS Code + *AutoHotkey v2 Language Support* (thqby) | Optional | For editing the source with syntax checking |
| Git | Optional | Only to clone or contribute |

Nothing else is installed: no libraries, no runtime, no network access.

### Elevated (admin) windows

Windows blocks a normal program from typing into a program that runs **as
administrator**. If you start SQL Server Management Studio, a PowerShell
console or similar with *Run as administrator*, snippets will not type there.

Options:

- Run those programs normally when you can.
- Or start AutoHotkey-Typer as administrator too (right-click, *Run as
  administrator*). Only do this if you understand that the script then has
  admin rights.

## 2. Installing and running

**Option A - the .exe (recommended)**

1. Download **AHK-Typer.exe** from the
   [latest release](https://github.com/paddelia1/AutoHotkey-Typer/releases/latest).
2. Verify it: compare `(Get-FileHash .\AHK-Typer.exe -Algorithm SHA256).Hash`
   with the SHA-256 in the release notes.
3. Put it in a folder of your choice (for example
   `%LOCALAPPDATA%\Programs\AHK-Typer`) and run it. On *"Windows protected
   your PC"* choose **More info > Run anyway** (the file is not code-signed).

**Option B - the script**

1. Install AutoHotkey v2 from [https://www.autohotkey.com/v2/](https://www.autohotkey.com/v2/)
   (the Ahk2Exe compiler is offered by its Dash, if you want to build the .exe).
2. Clone or download the repository.
3. Double-click `src\AutoHotkey-Typer.ahk`.

**First start**

Your snippet file is created with **example snippets** and a welcome note
at the top, so the app works right away (anywhere: `;addr`, Notepad: `;hi`,
Ctrl + Alt + Shift + S). The examples are named `Ex - ...`. When you are
ready, remove them all with tray icon > **Snippet file > Remove example
snippets**, or one by one with **Delete** in Add / edit snippet. See
[examples.md](examples.md).

### Start automatically when you sign in to Windows

Windows starts everything in your personal **Startup folder** each time you
sign in. Put a shortcut to AHK-Typer there.

**Before you start**

- Keep AHK-Typer.exe in its **final folder** (for example
  `%LOCALAPPDATA%\Programs\AHK-Typer`), not in Downloads. The shortcut
  stops working if the file is moved later.
- Clear the "downloaded from the internet" mark once, so Windows does not
  ask *"Do you want to run this file?"* at every sign-in. After checking the
  SHA-256 (see above), right-click AHK-Typer.exe > **Properties** > tick
  **Unblock** > **OK**, or in PowerShell:

  ```powershell
  Unblock-File -Path "$($env:LOCALAPPDATA)\Programs\AHK-Typer\AHK-Typer.exe"
  ```

**Option 1 - with the mouse**

1. Press **Win + R**, type `shell:startup`, press **Enter**. Your Startup
   folder opens.
2. In a second Explorer window, go to the folder with **AHK-Typer.exe**.
3. Drag AHK-Typer.exe into the Startup folder **with the right mouse
   button**, release, and choose **Create shortcuts here**.
   (A plain left drag would *move* the program - do not do that.)
4. Sign out and back in (or restart): the red **T** appears in the tray.

Running the script instead of the .exe? Create the shortcut to
`src\AutoHotkey-Typer.ahk` the same way - AutoHotkey v2 must be installed.

**Option 2 - with PowerShell** (no administrator rights needed)

```powershell
# Adjust this path to where you keep AHK-Typer.exe
$exe     = "$($env:LOCALAPPDATA)\Programs\AHK-Typer\AHK-Typer.exe"
$startup = [Environment]::GetFolderPath('Startup')
$shell   = New-Object -ComObject WScript.Shell
$link    = $shell.CreateShortcut("$($startup)\AHK-Typer.lnk")
$link.TargetPath       = $exe
$link.WorkingDirectory = Split-Path -Path $exe -Parent
$link.Description      = 'AHK-Typer - start with Windows'
$link.Save()
Write-Host "Shortcut created: $($startup)\AHK-Typer.lnk"
```

**Check it, or turn it off**

| To... | Do this |
|---|---|
| See that it is set up | **Task Manager** (Ctrl + Shift + Esc) > **Startup apps**: *AHK-Typer* is listed as **Enabled**. Also in **Settings > Apps > Startup** |
| Pause it without deleting | Task Manager > Startup apps > AHK-Typer > **Disable** (or the switch in Settings > Apps > Startup) |
| Remove it | Delete the shortcut: Win + R > `shell:startup` > delete **AHK-Typer**. In PowerShell: `Remove-Item "$([Environment]::GetFolderPath('Startup'))\AHK-Typer.lnk"` |

Notes:

- The Startup folder is per user: AHK-Typer starts only for your own Windows
  account, which is also the only account that can decrypt your secrets.
- It starts as a normal (not elevated) program. That is the right choice -
  see *Elevated (admin) windows* in section 1. Avoid Task Scheduler's "Run
  with highest privileges" unless you really need to type into admin
  windows.
- After updating to a new version, replace AHK-Typer.exe **in the same
  folder** with the same name, and the shortcut keeps working. Unblock the
  new file again.

## 3. Where the snippet file lives

| Mode | Location | When used |
|---|---|---|
| Default | `%AppData%\AutoHotkey-Typer\snippets.ini` | Always, unless portable mode applies |
| Portable | `snippets.ini` next to the script or `.exe` | Only when that file exists |

There is only this one file. Tray icon > **Snippet file**:

| Item | What it does |
|---|---|
| Edit snippet file | Opens it in Notepad, for bulk changes. Reload afterwards |
| Open snippet folder | Opens the folder in Explorer |
| Remove example snippets... | Deletes every snippet named `Ex - ...` (the first-run examples). Your own snippets and secrets are not touched |

The examples contain no real data and no secrets.

The default location is per user, protected by Windows file permissions,
and not inside OneDrive or a git folder. **Keep it there** unless you have a
specific reason for portable mode.

The file is saved as UTF-16 so accented characters such as é, à and ü work
with the Windows INI functions. Notepad handles this format.

## 4. Plain snippets and secrets

| Entry | Stored as | Use for |
|---|---|---|
| `Text=` | Plain text | Email addresses, signatures, SQL snippets, URLs |
| `Secret=` | DPAPI-encrypted (`dpapi1:...`) | Passwords, API keys, tokens, account numbers |

### Adding, editing or deleting a snippet

Double-click the tray icon (or right-click it and choose **Add / edit
snippet...**). Everything is on one page:

| Section | What to do |
|---|---|
| Name | Type a new name, or pick an existing snippet from the list to edit it |
| Type | **Plain text** for everyday text, **Secret (encrypted)** for passwords and keys |
| Trigger | Tick Ctrl / Alt / Shift / Win and choose a key. The AHK notation and a colored verdict (green / orange / red) update as you go. You can also type the notation directly. Optionally add a hotstring |
| Windows | Add one or more windows. **Pick...** hides the dialog; click the target window and its title and program are filled in. Shorten the title if part of it changes (document names, file names), then click **Add** |
| Text (plain) | Type the text as it should appear. Enter starts a new line |
| Secret | Type the value twice, or click **Generate...**. **Show** reveals it. When editing, leave both empty to keep the current secret |

**Save** writes the file (encrypting secrets) and reloads. **Delete** removes
the snippet you are editing.

Switching an existing snippet between the two types:

- **Plain text -> Secret**: a one-line text is carried into the secret
  fields; Save encrypts it and removes the plain `Text=` line.
- **Secret -> Plain text**: you are asked to confirm, because the value will
  then be stored unencrypted. Type the text again; the secret is removed.

**Snippet file > Edit snippet file** in the tray menu still opens the
file in Notepad, for bulk changes.

Only the encrypted form is written to the file. You never type `Secret=` by
hand; if you do, the entry is refused at startup because it is not encrypted.

### Login sequences (username + password)

A secret can also type a username first. With the cursor in the username
field, one hotkey types:

**username -> Tab -> secret -> Enter**

In **Add / edit snippet** (type Secret), fill in the optional fields under
the secret:

| Field | Meaning | Default |
|---|---|---|
| Username | Typed first. Leave empty to type only the secret | empty |
| Then press | **Tab** (same page) or **Enter** (two-page logins: username page, then password page) | Tab |
| Press Enter after the secret | Submits the form | off |
| Delay | Pause in milliseconds between steps, for slow windows (0 - 2000) | 150 |

In the file:

```ini
[VPN]
Hotkey=^!+v
Username=jdoe
Secret=dpapi1:AQAAANCMnd8B...
Window=ahk_exe vpnui.exe
Submit=1
```

Tips:

- **Click in the first field** (username, or the secret field when there is
  no username) before pressing the hotkey.
- If the app already **remembers the username**, leave Username empty, or
  the name is typed twice.
- If characters go missing or land in the wrong field, raise the **Delay**
  (try 300).
- **MFA** (push approval, one-time code) happens after the sequence; approve
  or type the code yourself. Never store one-time codes or smart card PINs.
- Windows' own credential prompts (Remote Desktop, the built-in VPN client,
  UAC) ignore typed input since the January 2026 Windows update. Login
  sequences work in apps with their own login window.

### Generating a secret

In the **Add / edit snippet** window (type Secret), click **Generate...** next to the
Secret field. Choose a password or a passphrase, then **Use this**: the value
fills both Secret and Confirm, and is encrypted when you click Save.

| Type | Default | Strength |
|---|---|---|
| Password | 20 characters, upper, lower, digits, symbols, no look-alike characters | about 122 bits - Very strong |
| Passphrase | 6 words from the EFF list (7,772 words), hyphens, capitalized, plus a number | about 84 bits - Strong |

- Randomness comes from Windows `BCryptGenRandom`, the system cryptographic
  generator, not AutoHotkey's `Random()`.
- Strength is calculated from the **settings** (pool size and length), not
  from the characters that happen to appear in one result.
- Thresholds: under 45 bits Weak, under 70 Fair, under 100 Strong, 100 and
  above Very strong. Fewer than 5 passphrase words drops below Strong.
- The generated value is shown on screen so you can save it in your
  password manager. It is never copied to the clipboard.
- After saving, use the secret's hotkey to type the new password into the
  site's "new password" and "confirm password" fields.

### Several windows for one secret

A secret can work in several windows. In the file they are separated by `|`:

```ini
Window=Connect ahk_exe Ssms.exe | desktop - Remote Desktop Connection ahk_exe mstsc.exe
```

### Remote Desktop sessions

AutoHotkey-Typer only sees windows on the PC where it runs. A whole Remote
Desktop session is one window on your PC (`ahk_exe mstsc.exe`); the programs
inside it are invisible. Two choices:

- Add the RDP window as a rule (Pick... works). The secret then types into
  any program inside that session, so click the right field first.
- Or run AutoHotkey-Typer on the remote PC too, with its own secrets
  (encrypted secrets do not move between PCs).

In full-screen RDP, key combinations go to the remote PC, so local hotkeys
may not fire. Use a windowed session or a hotstring.

### Where snippets cannot type

| Place | Why | What to do |
|---|---|---|
| **Windows credential prompts** - Remote Desktop sign-in, the built-in Windows VPN, *Windows Security* dialogs | Since the **January 2026** Windows update (KB5080542) these dialogs ignore simulated typing from normal programs | Let Windows remember the credential where allowed, or type it. Apps with their own login window (Cisco, GlobalProtect, FortiClient, web pages) are not affected |
| **Programs running as administrator** | Windows blocks a normal program from typing into an elevated one | Run the program normally, or see *Elevated (admin) windows* in section 1 |
| **UAC prompt, lock screen, sign-in screen** | They run on the secure desktop | Type these yourself |
| **Inside a Remote Desktop session** | The app only sees the RDP window, not the programs in it | See *Remote Desktop sessions* above |
| **A window not matching `Window=`** | The snippet is switched off there by design | Check the window rule; **Pick...** captures the exact title and program |

A snippet that does not fire is usually the last case. Also check that
the app is not suspended (grey icon), and choose **Reload** in the tray menu
after editing the file by hand.

### What stays readable

Encryption covers the secret **value only**. These remain plain text in the
file: the section name, hotkey, hotstring and window filter. So avoid names
that reveal too much, for example `[prod sa password AW-SQL-01]`. Prefer a
neutral name such as `[db1]`.

## 5. Keeping the real file safe - checklist

- [ ] Leave the file in `%AppData%` (the default).
- [ ] Never put passwords in plain text. Use the **Secret** type.
- [ ] Set a `Window=` filter on every secret, so a hotkey pressed in the
      wrong window (chat, email, browser) types nothing. The app warns at
      startup when a secret has no filter.
- [ ] Never commit the file. `.gitignore` already excludes `snippets*.ini`,
      but the AppData location keeps it out of repositories anyway.
- [ ] Do not use portable mode inside OneDrive, Dropbox or Google Drive. The
      app warns when the file is in a synced folder.
- [ ] Keep the **original** values in your password manager. The snippet file
      is a convenience, not your only copy (see section 7).
- [ ] Lock your PC (**Win + L**) when you step away. Anyone at your unlocked
      session can press the hotkeys.
- [ ] Use **Suspend** from the tray menu while screen sharing or presenting.

### Optional: tighten file permissions

The AppData folder is already private to your account. To restrict the file
further so only your account can open it, run this in PowerShell:

```powershell
$file = "$($env:APPDATA)\AutoHotkey-Typer\snippets.ini"
icacls $file /inheritance:r /grant:r "$($env:USERNAME):(F)"
```

## 6. What the encryption protects against

| Protected | Not protected |
|---|---|
| Someone copying the file to another PC | Malware running under your own Windows account |
| Another Windows user on the same PC | Someone using your unlocked session |
| The file leaking through a backup, email or accidental commit | Keyloggers or screen recorders - the value is typed, so it is visible to them |
| Casual viewing in Notepad or over your shoulder | A person who knows your Windows password and has the file and your profile |

In short: it stops the file from being useful **on its own**. It cannot
protect a value from your own account, because your account is the key.

### How hard is it to decrypt a `dpapi1:` value?

It depends entirely on what the attacker already has:

| Attacker has... | Can they recover the secret? | Why |
|---|---|---|
| Only the `dpapi1:` string or the file (leaked backup, email, accidental commit, copied file) | **No, not realistically** | The value is AES-256 encrypted with a key derived from your account's DPAPI master key, which is itself protected by your Windows password. Without them it is a brute-force attack on AES |
| A program running **as you**, while you are signed in (malware, a malicious script or extension) | **Yes, trivially** | Windows decrypts DPAPI data for any program running under your account - one function call. The application "entropy" does not help: it is in this public source code |
| **Administrator** access to your PC while you are signed in | **Yes** | An administrator can read your DPAPI master keys from memory with well-known tools |
| Your **disk** (lost or stolen PC) **without** BitLocker | **Only if they also crack your Windows password** | The master key files are on the disk, protected by your password. A weak password can be cracked offline; a strong one, practically not |
| Your **disk with BitLocker** | **No** | The master key files cannot be read at all |
| A **domain administrator** (work PCs joined to a domain) | **Yes, for domain accounts** | Active Directory keeps a DPAPI backup key that can decrypt any domain user's data. Treat secrets on a work PC as readable by your IT department |

This is the same model Windows, Edge and Chrome have long used for saved
passwords: strong against a leaked file, no protection against malware that
already runs as you. A master password would not change that - malware
running as you can also record the master password as it is typed, or read
the decrypted value from memory. Once malware runs under your account, the
fix is removing it and changing your passwords, not stronger encryption.

### Securing your `dpapi1:` secrets

| Do this | Protects against |
|---|---|
| Turn on **BitLocker / Device encryption** (Settings > Privacy & security > Device encryption) | A lost or stolen PC |
| Use a **strong Windows password**, not only a PIN | Offline cracking of the DPAPI master key |
| Work as a **standard user**; keep the administrator account for installs | Theft of master keys from memory |
| Put a **window filter** on every secret | The secret being typed into the wrong window - the most likely everyday leak |
| Keep the snippet file **out of OneDrive, Dropbox and git** | The encrypted file spreading to places you do not control |
| **Lock the PC** (Win + L) when you step away | Someone using your session to press the hotkeys |
| Keep **originals in a password manager** | Losing access when the PC or profile is replaced |
| Keep **work and personal secrets apart** - see below | The domain backup key, and mixing employer and private data |
| If you suspect malware, **change every password** stored in the file after cleaning the PC | Secrets already decrypted by the malware |

### Work and personal computers

On a computer joined to a company domain, your employer's administrators can
decrypt any `dpapi1:` value through the domain's DPAPI backup key. Use one
snippet file per computer, and keep the two worlds apart:

| Computer | Store | Do not store |
|---|---|---|
| **Work PC** (domain-joined) | Work passwords only: work applications, servers, databases, work web sites | Personal passwords - banking, personal email, shopping, family accounts |
| **Personal PC** | Personal passwords | Work passwords - keep them on employer-managed devices |

- **Check your employer's policy first.** Many organizations, especially in
  government, defense and finance, do not allow passwords to be stored in
  tools that IT has not approved. If unsure, ask before using
  AutoHotkey-Typer for work secrets.
- **Never copy the snippet file between work and personal PCs.** Secrets
  do not decrypt on another PC anyway, and plain `Text=` snippets could carry
  work information onto a personal device.
- **Shared or privileged accounts** (service accounts, `sa`, domain admin)
  usually belong in the organization's vault (CyberArk, Secret Server, Azure
  Key Vault, AWS Secrets Manager), not in a personal tool.
- **When you leave a job**, the work PC and its snippet file stay with the
  employer. Nothing on your personal PC needs cleaning up if the two were
  never mixed.

## 7. Moving to a new PC, or a password reset

Encrypted values only decrypt under **your Windows account on the PC where
they were created**.

- **New PC:** copy `%AppData%\AutoHotkey-Typer\snippets.ini`, then re-add each secret with
  **Add / edit snippet** (pick the name, type the value again). Plain `Text=` snippets
  carry over as they are. Undecryptable secrets are reported at startup.
- **Your own password change:** no effect. Windows re-protects its keys.
- **An administrator resets your password:** on a local account, previously
  encrypted secrets may become unreadable. Re-add them.

This is why section 5 says to keep the originals in a password manager.

## 8. Encryption investigation - why DPAPI

Options considered for a dependency-free AutoHotkey v2 tool:

| Option | How | Pros | Cons | Verdict |
|---|---|---|---|---|
| **DPAPI, current user** | `CryptProtectData` in crypt32.dll via `DllCall` | Built into Windows, no master password, key managed by Windows, small code | Tied to one user on one PC | **Chosen** |
| DPAPI, local machine | Same, with `CRYPTPROTECT_LOCAL_MACHINE` | Any account on the PC can decrypt | Any account on the PC can decrypt | Rejected |
| Windows Credential Manager | `CredWrite` / `CredRead` | Visible in Control Panel, also DPAPI-backed | Second storage place to keep in sync, 2,560-byte limit per entry | Possible later option |
| AES with a master password | `BCrypt*` functions plus a key derivation function | Portable across PCs | Master password prompt at every start, much more code to get right | Possible later "portable vault" |
| Password manager CLI | KeePassXC or Bitwarden command line | Strong, already audited | External dependency, slower | Rejected |
| Plain text | INI file | Simple | No protection | Rejected (only for `Text=`) |

### How it is implemented (`src\lib\Dpapi.ahk`)

1. The value is converted to UTF-8 bytes.
2. `CryptProtectData` encrypts it with your account's DPAPI key, plus a
   fixed application "entropy" value. The entropy is not a secret - it is
   in this public source code. It only stops generic tools that decrypt
   DPAPI data *without* an entropy value from reading these entries blindly.
3. The result is Base64-encoded and stored as `dpapi1:<base64>`. The
   `dpapi1` prefix leaves room for other formats later.
4. At startup each secret is test-decrypted once, so a broken entry is
   reported right away instead of when you press the key.
5. When the hotkey fires, the value is decrypted, typed with `SendText`, and
   the variable is cleared. The clipboard is never used.
6. Temporary byte buffers holding the plain text are overwritten with zeros.

Limitation: AutoHotkey strings are managed by the interpreter, so a copy of
a decrypted value may stay in process memory briefly after typing. This
matters only against an attacker who can already read your process memory,
which is the "malware under your account" case in section 6.

### Verifying it yourself

1. Add a secret with **Add / edit snippet** (type Secret).
2. Open the snippet file: the `Secret=` line starts with `dpapi1:` and is
   unreadable.
3. Press the hotkey in the allowed window: the real value is typed.
4. Copy the file to another Windows account and run the app there: the
   secret is reported as "cannot be decrypted".
