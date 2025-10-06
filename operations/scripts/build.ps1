Param(
    [ValidateSet("windows", "server")]
    [string]$Target = "windows",
    [string]$GodotPath = "godot"
)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$exportRoot = Join-Path $projectRoot ".."
$exportRoot = Resolve-Path $exportRoot

$exportDir = Join-Path $exportRoot "build"
if (!(Test-Path $exportDir)) {
    New-Item -Path $exportDir -ItemType Directory | Out-Null
}

switch ($Target) {
    "windows" {
        $preset = "Windows Desktop"
        $output = Join-Path $exportDir "windows/mmo_voxel.exe"
    }
    "server" {
        $preset = "Dedicated Server"
        $output = Join-Path $exportDir "server/mmo_voxel_server.x86_64"
    }
}

$outputDir = Split-Path -Parent $output
if (!(Test-Path $outputDir)) {
    New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
}

$godotArgs = @(
    "--headless",
    "--path", $exportRoot,
    "--export-release", $preset,
    $output
)

Write-Host "Building target '$Target' with Godot at '$GodotPath'" -ForegroundColor Cyan

$env:TMP_GODOT_BUILD_DIR = $exportRoot

& $GodotPath @godotArgs
$exitCode = if ($null -eq $LASTEXITCODE) { 0 } else { $LASTEXITCODE }

if ($exitCode -ne 0) {
    throw "Godot export failed with exit code $exitCode"
}

Write-Host "Export succeeded (exit code $exitCode): $output" -ForegroundColor Green
