# Examples - learn AHK-Typer in 10 minutes

Version: 1.4

## 1. Try the examples

On the first start AHK-Typer uses its **example snippets**. You can come
back to them any time: tray icon > **Snippet file > Example snippets**.

| Type this / press this | Where | You get |
|---|---|---|
| `;em` | anywhere | `jane.doe@example.com` |
| `;wem` | anywhere | `j.doe@company.example` |
| `;ph` | anywhere | `+1 555 0100` |
| `;ty` | anywhere | a short "thank you" reply |
| `;meet` | anywhere | a meeting link |
| `;addr` | anywhere | a 3-line postal address |
| **Ctrl + Alt + Shift + S** | anywhere | a 5-line email signature |
| **Ctrl + Alt + Shift + O** | anywhere | an out-of-office sentence |
| `;hi` | **Notepad or Notepad++ only** | `Hello from AHK-Typer!` |
| **Ctrl + Alt + Shift + Q** | **SSMS, VS Code, Azure Data Studio only** | a SELECT template |
| `;sqlh` | SSMS, VS Code only | an SQL script header |
| `;psh` | VS Code, PowerShell ISE only | a PowerShell script header |
| `;row` | anywhere | `Name`, `Email`, `Phone` separated by Tabs (try it in Excel) |
| `;tmpd` | anywhere | `C:\Temp\` |
| `;off` | - | nothing: this example is switched off (`Enabled=0`) |

Things to notice:

- A **hotstring** (`;em`) is replaced the moment you finish typing it.
- `;hi` does nothing in a browser: its **window filter** limits it to two
  programs.
- The examples file is read-only. Double-clicking the tray icon offers to
  switch to **My snippets**.

The file itself, with comments, is in
[examples/snippets.sample.ini](../examples/snippets.sample.ini).

## 2. Your first snippet (2 minutes)

1. Tray icon > **Snippet file > My snippets**.
2. Double-click the tray icon. **Add / edit snippet** opens.
3. **Name**: `My email`. **Type**: Plain text.
4. **Trigger**: untick *Hotkey*, tick *Hotstring*, type `;me`.
5. **Text**: your email address.
6. **Save**. The app reloads; type `;me` anywhere.

## 3. Recipes

Each recipe shows the dialog settings and the resulting lines in the file.

### A signature on several lines

| Field | Value |
|---|---|
| Type | Plain text |
| Hotkey | Ctrl + Alt + Shift + S |
| Text | press Enter between lines, exactly as it should look |

```ini
[Signature]
Hotkey=^!+s
Text=Best regards,\n\nJane Doe\nSenior Data Engineer
```

### A template for one program only

| Field | Value |
|---|---|
| Type | Plain text |
| Hotkey | Ctrl + Alt + Shift + Q |
| Windows | click **Pick...**, click your SSMS window, delete the title part so only `ahk_exe Ssms.exe` remains, **Add** |

```ini
[SQL template]
Hotkey=^!+q
Text=SELECT TOP (100)\n     t.Column1\n    ,t.Column2\nFROM dbo.TableName AS t;
Window=ahk_exe Ssms.exe
```

### The same snippet in several programs

Add one window rule per program; the snippet works in any of them.

```ini
Window=ahk_exe notepad.exe | ahk_exe notepad++.exe
```

### A password, typed safely

| Field | Value |
|---|---|
| Type | **Secret (encrypted)** |
| Hotkey | Ctrl + Alt + Shift + P |
| Windows | the program that asks for it (Pick...) |
| Secret | type it twice, or **Generate...** a new one |

```ini
[Shop password]
Hotkey=^!+p
Secret=dpapi1:AQAAANCMnd8B...
Window=ahk_exe msedge.exe
```

Only the encrypted form is stored. Click in the password field, press the
hotkey.

### A full login: username, Tab, password, Enter

| Field | Value |
|---|---|
| Type | Secret (encrypted) |
| Hotkey | Ctrl + Alt + Shift + L |
| Windows | your VPN client or login window (Pick...) |
| Username | `jdoe` |
| Then press | Tab |
| Press Enter after the secret | ticked |

```ini
[VPN login]
Hotkey=^!+l
Username=jdoe
Secret=dpapi1:AQAAANCMnd8B...
Window=ahk_exe vpnui.exe
Submit=1
```

Click in the **username** field, press the hotkey. If a character goes
missing, raise **Delay** to 300.

Two-page logins (username, Next, then password): set **Then press** to
**Enter**.

### Switch a snippet off for a while

Tray icon > **Snippet file > Edit my snippet file**, add `Enabled=0` to the
snippet, save, then **Reload**. Remove the line (or set `Enabled=1`) to
switch it back on.

### Keep some examples

Tray icon > **Snippet file > Copy examples into my snippets...**, switch to
My snippets, then open each example in **Add / edit snippet** to change it
or **Delete** it. The copies keep their `Ex - ` name prefix so they are easy
to find.

## 4. Choosing good triggers

| Choice | Example | Why |
|---|---|---|
| Hotstring starting with `;` | `;em` | Never clashes with application shortcuts; easy to remember |
| Ctrl + Alt + Shift + letter | `^!+s` | Almost no program uses these |
| A plain Ctrl + letter | `^t` | **Avoid** - the checker warns: Ctrl+T is "new tab" in every browser |
| Ctrl + Alt + letter | `^!e` | **Avoid** on European keyboards - it is AltGr (`AltGr + E` types the euro sign) |

Do not make one hotstring the start of another: with `;em` and `;email`,
`;em` fires before you can finish `;email`.

The full notation guide: [hotkey-notation.md](hotkey-notation.md).

## 5. When something does not work

| Symptom | Likely cause | Fix |
|---|---|---|
| Nothing happens in one program | The snippet's window filter does not match it | Open the snippet, **Pick...** that program's window, **Add**, **Save** |
| Nothing happens anywhere | The app is suspended (grey icon), or you are on the other snippet set | Tray > Suspend to resume; check **Snippet file** |
| Works on your PC, not in a Remote Desktop window | The app sees only the RDP window | Add `ahk_exe mstsc.exe` as a window rule, or run AHK-Typer on the remote PC |
| Does not type into the Windows sign-in / RDP / UAC prompt | Blocked by Windows since January 2026 | Type it yourself - see [setup-and-security.md](setup-and-security.md#where-snippets-cannot-type) |
| A login types into the wrong field | The app was slower than the program | Raise **Delay** to 300 |
| Startup message "already used by" | Two snippets share a trigger for the same windows | Change one trigger |
