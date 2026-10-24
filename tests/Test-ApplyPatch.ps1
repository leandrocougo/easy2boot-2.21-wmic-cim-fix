param([Parameter(Mandatory=$true)][string]$OriginalEasy2BootPath, [Parameter(Mandatory=$true)][string]$TestDirectory)
$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
$manifest = Get-Content -Raw (Join-Path $repo 'manifest.json') | ConvertFrom-Json
$apply = Join-Path $repo 'Apply-Patch.ps1'
$testRoot = [IO.Path]::GetFullPath($TestDirectory)
if (Test-Path -LiteralPath $testRoot) { throw 'Test directory must not already exist.' }
$null = New-Item -ItemType Directory -Path $testRoot
function Fixture([string]$Name,[bool]$R1 = $false) {
    $dir = Join-Path $testRoot $Name
    $null = New-Item -ItemType Directory -Path $dir
    Set-Content -LiteralPath (Join-Path $dir 'menu.lst') -Value 'fixture'
    foreach ($e in $manifest.files) {
        if ($e.added) { continue }
        $p = Join-Path $dir $e.path
        $null = New-Item -ItemType Directory -Force -Path (Split-Path -Parent $p)
        if ($R1) {
            $b = [IO.File]::ReadAllBytes((Join-Path (Join-Path $repo 'scripts') $e.path))
            $enc = [Text.Encoding]::GetEncoding(28591)
            $b = $enc.GetBytes($enc.GetString($b).Replace(' -NonInteractive -Command',' -NonInteractive -WindowStyle Hidden -Command'))
            [IO.File]::WriteAllBytes($p,$b)
        } else { Copy-Item -LiteralPath (Join-Path $OriginalEasy2BootPath $e.path) -Destination $p }
    }
    return $dir
}
function Assert-Patched([string]$Dir) {
    foreach ($e in $manifest.files) {
        if ((Get-FileHash -LiteralPath (Join-Path $Dir $e.path)).Hash.ToLowerInvariant() -ne $e.patched_sha256) { throw "Wrong output: $($e.path)" }
    }
}
$original = Fixture 'original'
& $apply -Easy2BootPath $original -WhatIf
if (@(Get-ChildItem $original -Filter '.e2b-cim-backup-*' -Directory).Count) { throw 'WhatIf created a backup.' }
foreach ($e in $manifest.files) {
    $p=Join-Path $original $e.path
    if ($e.added) { if (Test-Path $p) { throw 'WhatIf added a file.' } }
    elseif ((Get-FileHash -LiteralPath $p).Hash.ToLowerInvariant() -ne $e.original_sha256) { throw 'WhatIf changed a file.' }
}
& $apply -Easy2BootPath $original
Assert-Patched $original
$backups = @(Get-ChildItem $original -Filter '.e2b-cim-backup-*' -Directory)
if ($backups.Count -ne 1) { throw 'Missing backup.' }
foreach ($e in $manifest.files) {
    if (!$e.added -and (Get-FileHash -LiteralPath (Join-Path $backups[0].FullName $e.path)).Hash.ToLowerInvariant() -ne $e.original_sha256) { throw 'Incorrect backup.' }
}
& $apply -Easy2BootPath $original
if (@(Get-ChildItem $original -Filter '.e2b-cim-backup-*' -Directory).Count -ne 1) { throw 'Repeat application created a backup.' }
$r1=Fixture 'r1' $true
& $apply -Easy2BootPath $r1
Assert-Patched $r1
$unknown=Fixture 'unknown'
$last=@($manifest.files | Where-Object { !$_.added })[-1]
Add-Content -LiteralPath (Join-Path $unknown $last.path) -Value 'REM local change'
$rejected=$false
try { & $apply -Easy2BootPath $unknown } catch { $rejected=$true }
if (!$rejected) { throw 'Unknown file accepted.' }
if (@(Get-ChildItem $unknown -Filter '.e2b-cim-backup-*' -Directory).Count) { throw 'Rejected preflight created backup.' }
$first=$manifest.files[0]
if ((Get-FileHash -LiteralPath (Join-Path $unknown $first.path)).Hash.ToLowerInvariant() -ne $first.original_sha256) { throw 'Rejected preflight partially patched files.' }
$report = @('PASS: WhatIf makes no changes.','PASS: Original -> R2, all hashes verified.','PASS: Backup matches original scripts.','PASS: Reapplication is idempotent.','PASS: R1 -> R2, all hashes verified.','PASS: Unknown file rejected before replacing files.','No Easy2Boot creation/formatting script was executed.')
$report | Set-Content -Encoding UTF8 (Join-Path $testRoot 'test-results.txt')
$report
Write-Output "Test fixtures: $testRoot"
