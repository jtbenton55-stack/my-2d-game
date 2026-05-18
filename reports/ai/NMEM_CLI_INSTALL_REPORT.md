# NMEM_CLI_INSTALL_REPORT

## 1) Date/time

- Date: 2026-05-17
- Local time window: ~17:39-17:40 (UTC-4)

## 2) Branch

- `c2a-full-character-animation-20260509-172230`

## 3) Git status

```text
A  .gitattributes
M  .gitignore
 M AGENTS.md
?? docs/NOWLEDGE_MEM_SETUP.md
?? docs/OPENCODE_PLANNING_PROMPT.md
?? reports/ai/NOWLEDGE_MEM_OPENCODE_WINDOWS_SETUP_REPORT.md
?? scenes/testing/
?? scripts/ai/
?? src/autoload/GameState.gd.bisect.bak
?? src/autoload/GameState_McpBisectShim.gd
?? src/autoload/GameState_McpBisectShim.gd.uid
?? src/autoload/GameState_McpBisectStub.gd
?? src/autoload/GameState_McpBisectStub.gd.uid
?? tests/
```

## 4) Python/pip availability

Audit commands and results:

- `python --version` -> `Python 3.13.13`
- `py --version` -> `Python 3.13.13`
- `pip --version` -> `pip 26.0.1 ... (python 3.13)`
- `py -m pip --version` -> `pip 26.0.1 ... (python 3.13)`

Conclusion:

- Both Python launcher (`py`) and pip are available.

## 5) Install command used

Because `nmem` was missing, install was run with:

```powershell
py -m pip install nmem-cli
```

Result:

- Install succeeded.
- Package installed: `nmem-cli 0.8.4`

## 6) Whether nmem installed

- Yes, installed successfully.
- The executable was installed into the user Scripts folder, which is not currently on PATH.

## 7) where.exe nmem result

Before install:

- `where.exe nmem` -> not found

After install:

- `where.exe nmem` -> still not found (PATH not updated yet)

## 8) nmem status result

### On PATH command

- `nmem status` -> fails with `CommandNotFoundException` (still not recognized on PATH).

### Full-path command (temporary verification)

Executed:

```powershell
& "C:\Users\jtben\AppData\Local\Packages\PythonSoftwareFoundation.Python.3.13_qbz5n2kfra8p0\LocalCache\local-packages\Python313\Scripts\nmem.exe" status
```

Result:

- `status ok`
- `mode local`
- `api http://127.0.0.1:14242 (default)`
- `database connected`
- `search ready`
- `agent running`

Note:

- Version mismatch warning reported:
  - CLI `v0.8.4`
  - server `v0.8.6`

## 9) PATH folder to add manually

Add this folder to your Windows user PATH:

`C:\Users\jtben\AppData\Local\Packages\PythonSoftwareFoundation.Python.3.13_qbz5n2kfra8p0\LocalCache\local-packages\Python313\Scripts`

This is the location where `nmem.exe` was installed.

## 10) Whether Nowledge Mem desktop app connection works

- Yes, connection works when using full-path `nmem.exe`.
- Explicit API URL also works:

```powershell
& "C:\Users\jtben\AppData\Local\Packages\PythonSoftwareFoundation.Python.3.13_qbz5n2kfra8p0\LocalCache\local-packages\Python313\Scripts\nmem.exe" --api-url http://127.0.0.1:14242 status
```

Result:

- `status ok`
- same connected/ready output

Interpretation:

- Nowledge Mem desktop app is reachable.
- Remaining blocker is PATH exposure for `nmem`.

## 11) Next exact command to run after fixing PATH

After adding the Scripts folder to PATH and opening a new terminal, run:

```powershell
nmem status
```

Optional follow-up:

```powershell
nmem --api-url http://127.0.0.1:14242 status
```
