[CmdletBinding()]
param(
    [string]$GodotEditorSource,
    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:Root = Resolve-Path (Join-Path $PSScriptRoot '..' '..')
Write-Host "[INFO] Repository root: $Root"

function Initialize-Directory {
    param(
        [Parameter(Mandatory)][string]$RelativePath
    )

    $fullPath = Join-Path $script:Root $RelativePath
    if (-not (Test-Path $fullPath)) {
        New-Item -ItemType Directory -Path $fullPath -Force | Out-Null
        Write-Host "[CREATE] $RelativePath"
    }
    else {
        Write-Host "[SKIP] $RelativePath already exists"
    }

    return $fullPath
}

function Set-GitIgnoreEntries {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string[]]$Entries
    )

    if (-not (Test-Path $Path)) {
        Write-Host "[WARN] .gitignore not found at $Path"
        return
    }

    $lines = Get-Content -Path $Path -Encoding UTF8
    $missing = @()
    foreach ($entry in $Entries) {
        if ($lines -notcontains $entry) {
            $missing += $entry
        }
    }

    if ($missing.Count -gt 0) {
        Add-Content -Path $Path -Value '' -Encoding UTF8
        foreach ($entry in $missing) {
            Add-Content -Path $Path -Value $entry -Encoding UTF8
        }
        Write-Host "[UPDATE] Added to .gitignore: $($missing -join ', ')"
    }
    else {
        Write-Host '[SKIP] .gitignore already contains required entries'
    }
}

function Set-AutoloadEntry {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string]$Value,
        [switch]$Force
    )

    if (-not (Test-Path $Path)) {
        throw "project.godot not found at $Path"
    }

    $raw = Get-Content -Path $Path -Raw -Encoding UTF8
    $lines = $raw -split "`r?`n", -1
    $list = [System.Collections.Generic.List[string]]::new()
    foreach ($line in $lines) {
        $null = $list.Add($line)
    }

    $autoloadStart = -1
    for ($i = 0; $i -lt $list.Count; $i++) {
        if ($list[$i] -match '^\s*\[autoload\]\s*$') {
            $autoloadStart = $i
            break
        }
    }

    if ($autoloadStart -eq -1) {
        if ($list.Count -gt 0 -and $list[$list.Count - 1] -ne '') {
            $null = $list.Add('')
        }
        $autoloadStart = $list.Count
        $null = $list.Add('[autoload]')
        $null = $list.Add('')
    }

    $sectionEnd = $list.Count
    for ($i = $autoloadStart + 1; $i -lt $list.Count; $i++) {
        if ($list[$i] -match '^\s*\[.+\]\s*$') {
            $sectionEnd = $i
            break
        }
    }

    $existingIndex = -1
    for ($i = $autoloadStart + 1; $i -lt $sectionEnd; $i++) {
        if ($list[$i] -match "^\s*$Name\s*=") {
            $existingIndex = $i
            break
        }
    }

    $entryLine = "$Name=`"$Value`""
    $updated = $false

    if ($existingIndex -eq -1) {
        $insertIndex = $sectionEnd
        if ($insertIndex -gt $autoloadStart + 1 -and $insertIndex -le $list.Count -and $list[$insertIndex - 1].Trim() -eq '') {
            $insertIndex -= 1
        }

        if ($insertIndex -ge $list.Count) {
            $null = $list.Add($entryLine)
        }
        else {
            $list.Insert($insertIndex, $entryLine)
        }

        $updated = $true
    }
    elseif ($Force -or $list[$existingIndex] -ne $entryLine) {
        $list[$existingIndex] = $entryLine
        $updated = $true
    }

    if ($updated) {
        $newContent = ($list -join "`n")
        Set-Content -Path $Path -Value $newContent -Encoding UTF8
        Write-Host "[UPDATE] project.godot autoload '$Name'"
    }
    else {
        Write-Host "[SKIP] Autoload '$Name' already configured"
    }
}

$gitignorePath = Join-Path $Root '.gitignore'
Set-GitIgnoreEntries -Path $gitignorePath -Entries @('bin/', 'build/', '*.import/', '*.scons_cache', 'user://')

$autoloadDir = Initialize-Directory -RelativePath 'autoload'
Initialize-Directory -RelativePath 'tools'
Initialize-Directory -RelativePath 'tools\godot'
$editorBinDir = Initialize-Directory -RelativePath 'tools\godot\bin'

$gameStatePath = Join-Path $autoloadDir 'GameState.gd'
$gameStateContent = @'
extends Node

var player_count: int = 0

func _ready() -> void:
    # TODO: 状態初期化を実装
    pass
'@

if (-not (Test-Path $gameStatePath) -or $Force) {
    Set-Content -Path $gameStatePath -Value $gameStateContent -Encoding UTF8
    Write-Host '[WRITE] autoload/GameState.gd'
}
else {
    Write-Host '[SKIP] autoload/GameState.gd already exists'
}

$projectFile = Join-Path $Root 'project.godot'
Set-AutoloadEntry -Path $projectFile -Name 'GameState' -Value '*res://autoload/GameState.gd' -Force:$Force

if ($GodotEditorSource) {
    $resolvedEditor = Resolve-Path $GodotEditorSource -ErrorAction Stop
    $targetEditorPath = Join-Path $editorBinDir 'godot.windows.editor.x86_64.exe'

    if ((Test-Path $targetEditorPath) -and -not $Force) {
        throw "Editor already exists at $targetEditorPath. Use -Force to overwrite."
    }

    Copy-Item -Path $resolvedEditor -Destination $targetEditorPath -Force
    Write-Host '[COPY] godot.windows.editor.x86_64.exe -> tools/godot/bin'
}
else {
    Write-Host '[INFO] Godot editor copy skipped (no source path provided)'
}

Write-Host '[DONE] Project initial setup completed.'
