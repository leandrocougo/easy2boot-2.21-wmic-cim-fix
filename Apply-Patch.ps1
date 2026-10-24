[CmdletBinding(SupportsShouldProcess = $true)]
param([Parameter(Mandatory = $true)][string]$Easy2BootPath)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Join-Checked([string]$Base, [string]$Relative) {
    if ([IO.Path]::IsPathRooted($Relative) -or $Relative -match '(^|[\\/])\.\.([\\/]|$)') {
        throw "Invalid relative path: $Relative"
    }
    $basePath = [IO.Path]::GetFullPath($Base).TrimEnd([char[]]'\/') + [IO.Path]::DirectorySeparatorChar
    $result = [IO.Path]::GetFullPath((Join-Path $basePath $Relative))
    if (!$result.StartsWith($basePath, [StringComparison]::OrdinalIgnoreCase)) { throw 'Path outside destination.' }
    return $result
}
function Hash([string]$Path) { return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant() }

$rootItem = Get-Item -LiteralPath $Easy2BootPath
if (!$rootItem.PSIsContainer -or $rootItem.PSProvider.Name -ne 'FileSystem') { throw 'Select an extracted Easy2Boot directory.' }
$root = $rootItem.FullName
if (!(Test-Path -LiteralPath (Join-Path $root 'menu.lst') -PathType Leaf)) { throw 'Easy2Boot root menu.lst not found.' }
$manifest = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $PSScriptRoot 'manifest.json') | ConvertFrom-Json
$payload = Join-Path $PSScriptRoot 'scripts'
$pending = @()

# Preflight every file before creating backups or replacing anything.
foreach ($entry in $manifest.files) {
    $source = Join-Checked $payload $entry.path
    $target = Join-Checked $root $entry.path
    if ((Hash $source) -ne $entry.patched_sha256) { throw "Corrupt patch payload: $($entry.path)" }
    $exists = Test-Path -LiteralPath $target -PathType Leaf
    if ($exists) {
        $actual = Hash $target
        if ($actual -eq $entry.patched_sha256) { continue }
        if ($entry.added -or $actual -notin @($entry.original_sha256, $entry.r1_sha256)) {
            throw "Unrecognized or locally modified file: $($entry.path). No files were changed."
        }
    } elseif (!$entry.added) { throw "Missing original file: $($entry.path). No files were changed." }
    $pending += [pscustomobject]@{ Entry = $entry; Source = $source; Target = $target; Existed = $exists }
}
if ($pending.Count -eq 0) { Write-Output 'CIM R2 is already installed. No changes needed.'; return }
if (!$PSCmdlet.ShouldProcess($root, "Apply Easy2Boot 2.21 CIM R2 to $($pending.Count) files and create backup")) { return }

$backup = Join-Path $root ('.e2b-cim-backup-' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '-' + [guid]::NewGuid().ToString('N').Substring(0,8))
$null = New-Item -ItemType Directory -Path $backup
foreach ($item in $pending) {
    if ($item.Existed) {
        $saved = Join-Checked $backup $item.Entry.path
        $null = New-Item -ItemType Directory -Force -Path (Split-Path -Parent $saved)
        Copy-Item -LiteralPath $item.Target -Destination $saved
    }
}
$pending | ForEach-Object { [pscustomobject]@{ path = $_.Entry.path; existed = $_.Existed; patched_sha256 = $_.Entry.patched_sha256 } } |
    ConvertTo-Json -Depth 4 | Set-Content -Encoding UTF8 -LiteralPath (Join-Path $backup 'backup-manifest.json')
$written = @()
try {
    foreach ($item in $pending) {
        $null = New-Item -ItemType Directory -Force -Path (Split-Path -Parent $item.Target)
        $written += $item
        Copy-Item -LiteralPath $item.Source -Destination $item.Target -Force
        if ((Hash $item.Target) -ne $item.Entry.patched_sha256) { throw "Verification failed: $($item.Entry.path)" }
    }
} catch {
    $failure = $_
    foreach ($item in $written) {
        try {
            if ($item.Existed) { Copy-Item -LiteralPath (Join-Checked $backup $item.Entry.path) -Destination $item.Target -Force }
            elseif (Test-Path -LiteralPath $item.Target -PathType Leaf) { Remove-Item -LiteralPath $item.Target }
        } catch { Write-Warning "Automatic rollback failed for $($item.Entry.path). Backup: $backup" }
    }
    throw $failure
}
Write-Output "CIM R2 applied. Files updated: $($pending.Count)"
Write-Output "Backup: $backup"
Write-Output 'No disk creation or formatting commands were executed.'
Write-Output 'To use Easy2Boot, run INICIAR_COM_DIAGNOSTICO.cmd as administrator in the patched directory.'
