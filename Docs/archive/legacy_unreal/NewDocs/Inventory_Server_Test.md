# Inventory Server Test Guide (UE5.6)

This document explains how to run server-side inventory tests, including commands, startup methods, and log verification for the MyMMO project.

- Project: `G:\Unreal Projects\MyMMO\MyMMO.uproject`
- Map: `/Game/ThirdPerson/Lvl_ThirdPerson.Lvl_ThirdPerson`
- Logs:
  - Standard: `G:\Unreal Projects\MyMMO\Saved\Logs\MyMMO.log`
  - Structured (JSONL): `G:\Unreal Projects\MyMMO\Saved\Logs\server_YYYYMMDD.jsonl`

## 1) Quick Test Commands (Server Console)
Run these on the SERVER (authority) console.

```
inventory_List
inventory_AddItem 2002 5
inventory_List
inventory_Save
inventory_Clear
inventory_Load
inventory_List
```

Expected logs:
- MyMMO.log
  - `[inventory] Save command executed - <N> slots saved`
  - `[inventory] Load command executed - <M> items loaded`
- server_*.jsonl
  - `Inventory saved to database` (data: `{ "saved_slots": N }`)
  - `Inventory loaded from database` (data: `{ "loaded_items": M }`)

## 2) Startup Methods

### A. Dedicated Server (Standalone)
Start server and (optionally) a client.

- Server (example):
```
"<UE5>\Engine\Binaries\Win64\UnrealEditor-Cmd.exe" -Project="G:\Unreal Projects\MyMMO\MyMMO.uproject" \
  /Game/ThirdPerson/Lvl_ThirdPerson -server -log -port=7777 -UNATTENDED -NOSTEAM -AllowCheats
```

- Client (optional):
```
"<UE5>\Engine\Binaries\Win64\UnrealEditor.exe" -Project="G:\Unreal Projects\MyMMO\MyMMO.uproject" \
  /Game/ThirdPerson/Lvl_ThirdPerson -game -log -windowed -ResX=1280 -ResY=720 -ExecCmds="open 127.0.0.1:7777"
```

Open server console (tilde `~`) and run the test commands.

### B. Editor PIE with Dedicated Server
1. Play Settings:
   - Number of Players: 2 (example)
   - Run Dedicated Server: ON
   - Use Single Process: OFF (recommended)
2. Start PIE, then open Output Log.
3. If available, switch instance to Server in Output Log and run the commands.
4. Alternatively, use Additional Server Game Command Line to push initial ExecCmds (e.g., `-ExecCmds="inventory_AddItem 2002 5; inventory_List"`) and then run Save/Load after the first client connects.

### C. Listen Server
1. Host (server+client) opens console:
```
open ?listen
```
2. Another client (optional):
```
open 127.0.0.1
```
3. Run the test commands on the host console.

### D. Batch Script (already included)
- File: `Scripts/start_server.bat`
- Current launch (single line):
```
"%ENGINE_PATH%" -Project="%PROJECT_PATH%" /Game/ThirdPerson/Lvl_ThirdPerson %SERVER_PARAMS% %EXEC_CMDS%
```
- Notes:
  - `%PROJECT_PATH%` should be `G:\Unreal Projects\MyMMO\MyMMO.uproject`.
  - `%ENGINE_PATH%` should point to your `UnrealEditor-Cmd.exe` or `UnrealEditor.exe`.
  - `%EXEC_CMDS%` may run Add/List at startup, but Save/Load should be executed after a player connects so that PlayerId is valid.

### E. PowerShell (portable launcher)
Example one-liner to run server from any directory:

```powershell
$PROJECT_PATH = 'G:\Unreal Projects\MyMMO\MyMMO.uproject'
$ENGINE_CANDIDATES = @(
  'G:\GitHub\UnrealEngine5.6\Engine\Binaries\Win64\UnrealEditor-Cmd.exe',
  'C:\Program Files\Epic Games\UE_5.6\Engine\Binaries\Win64\UnrealEditor-Cmd.exe',
  'C:\Program Files\Epic Games\UE_5.6\Engine\Binaries\Win64\UnrealEditor.exe',
  'C:\Program Files\Epic Games\UE_5.6\Engine\Binaries\Win64\UE5Editor.exe'
)
$ENGINE_PATH = $ENGINE_CANDIDATES | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not (Test-Path $PROJECT_PATH)) { Write-Error "Project not found: $PROJECT_PATH"; return }
if (-not $ENGINE_PATH) { Write-Error "UnrealEditor executable not found."; return }
$exec = 'inventory_AddItem 2002 5; inventory_List'
$map  = '/Game/ThirdPerson/Lvl_ThirdPerson'
$argsList = @(
  "-Project=\"$PROJECT_PATH\"",
  $map,
  '-server','-log','-port=7777','-UNATTENDED','-NOSTEAM','-AllowCheats',
  "-ExecCmds=\"$exec\""
)
Start-Process -FilePath $ENGINE_PATH -ArgumentList $argsList -NoNewWindow:$false
```

## 3) Automatic Load/Save (Production)
The server now automates inventory persistence:

- `UInventoryComponent::BeginPlay()`
  - Starts `StartAutoLoad()` on server authority.
- `StartAutoLoad()` / `TryAutoLoad()`
  - Polls until `GetPlayerIdFromOwner()` becomes valid, then calls `inventory_Load()` once.
- `StartAutoSave()`
  - Runs periodic saves via `OnAutoSaveTick()` every `AutoSaveIntervalSeconds` (default 60s). Tunable in component details.
- `EndPlay()`
  - Calls `StopAutoSave()` and `SaveInventory()` for a final save.

No manual Save/Load is required at runtime. The quick commands remain useful for debugging.

## 4) Log Verification
Use these to filter relevant lines quickly:

```powershell
# Standard log
Select-String -Path "G:\Unreal Projects\MyMMO\Saved\Logs\MyMMO.log" -Pattern "Save command executed|Load command executed" -Context 1,2

# Structured log
Select-String -Path "G:\Unreal Projects\MyMMO\Saved\Logs\server_*.jsonl" -Pattern "Inventory saved to database|Inventory loaded from database"
```

## 5) Troubleshooting
- **No Save/Load logs**: Ensure a player is connected. The automated loader waits for a valid PlayerId.
- **Different sessions**: PlayerId changes across sessions; old saves won’t load for a new PlayerId.
- **SQLite not available**: Check `USQLiteSubsystem` init in logs. The component will log an error and skip persistence.

---
Maintainer: Engineering
Last Updated: 2025-09-15

## 6) Automation (UE5.6 Editor Automation Tests)
An editor automation test is available to validate SQLite inventory persistence without manual steps.

- Test name (filter): `MyMMO.Inventory.Server.SaveLoad`
- Source: `Source/MyMMO/Private/InventoryAutomationTests.cpp`

### A. Run from Command Line (Headless Editor)

Option 1 (ExecCmds):
```
"<UE5>\Engine\Binaries\Win64\UnrealEditor-Cmd.exe" -Project="G:\Unreal Projects\MyMMO\MyMMO.uproject" -log -UNATTENDED -NOP4 -NoSound ^
  -ExecCmds="Automation RunTests MyMMO.Inventory.Server.SaveLoad; Quit"
```

Option 2 (Automation runner):
```
"<UE5>\Engine\Binaries\Win64\UnrealEditor-Cmd.exe" -Project="G:\Unreal Projects\MyMMO\MyMMO.uproject" -log -UNATTENDED -NOP4 -NoSound ^
  -run=Automation -Test=MyMMO.Inventory.Server.SaveLoad -ReportExportPath="G:\Unreal Projects\MyMMO\Saved\Automation\Reports" -nop4
```

Reports are exported under:
- `Saved/Automation/Reports/` (JSON, CSV, HTML)

### B. Run from Editor (Session Frontend)
1. Window → Developer Tools → Session Frontend → Automation タブ
2. フィルタで `MyMMO.Inventory.Server.SaveLoad` を検索
3. チェックして「Start Tests」を実行
4. 結果は Automation タブおよび `Saved/Automation/Reports/` に保存

### C. PowerShell helper
```powershell
$Project = 'G:\Unreal Projects\MyMMO\MyMMO.uproject'
$Candidates = @(
  'G:\GitHub\UnrealEngine5.6\Engine\Binaries\Win64\UnrealEditor-Cmd.exe',
  'C:\Program Files\Epic Games\UE_5.6\Engine\Binaries\Win64\UnrealEditor-Cmd.exe'
)
$Editor = $Candidates | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $Editor) { throw 'UnrealEditor-Cmd.exe not found' }
$Args = @('-Project="{0}"' -f $Project, '-log','-UNATTENDED','-NoSound','-NOP4',
          '-run=Automation','-Test=MyMMO.Inventory.Server.SaveLoad',
          '-ReportExportPath="G:\Unreal Projects\MyMMO\Saved\Automation\Reports"')
Start-Process -FilePath $Editor -ArgumentList $Args -NoNewWindow:$false
```
