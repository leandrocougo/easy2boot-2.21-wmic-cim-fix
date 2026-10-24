# Easy2Boot 2.21 — WMIC to PowerShell CIM fix

[Português do Brasil](README.pt-BR.md)

An unofficial script patch for the Easy2Boot 2.21 installer identified below. It removes the WMIC presence/PATH gate and replaces disk queries with `Get-CimInstance`, retaining the text formats consumed by the original batch scripts.

**Use revision R2.** The first revision used `-WindowStyle Hidden`, which can hide the shared CMD console during a PowerShell query. R2 removes that argument. The user who reported the disappearing window confirmed that R2 worked; this is one user report, not a hardware compatibility guarantee.

**User-reported result — October 24, 2026:** the repository owner successfully created a bootable SSD using this correction on **Windows 11 25H2**. The report confirms completion of the creation process in that environment. Actual startup from the SSD, firmware mode and SSD model have not been reported. See [validation details](VALIDATION.md).

## Apply

1. Close running Easy2Boot processes. Extract Easy2Boot 2.21 into its own folder.
2. Download/extract this repository separately. Open Windows PowerShell in this repository folder.
3. Preview the file changes:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Apply-Patch.ps1 -Easy2BootPath "C:\Tools\Easy2Boot_v2.21" -WhatIf
```

4. Apply the patch:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Apply-Patch.ps1 -Easy2BootPath "C:\Tools\Easy2Boot_v2.21"
```

`ExecutionPolicy Bypass` applies only to that PowerShell process. The applicator validates all payload and destination hashes before making changes, creates a timestamped backup inside the Easy2Boot folder, and verifies copied files. It accepts the recognized original scripts, R1 scripts, or files already patched to R2. Unknown/local modifications stop the operation before any files are replaced. A replacement failure triggers an attempted rollback from the backup.

Applying this patch copies script files only. It does not start Easy2Boot, select a disk, format a drive, install WMIC, or modify the system execution policy. Write permission to the extraction folder is required.

5. In the patched Easy2Boot folder, run **`INICIAR_COM_DIAGNOSTICO.cmd` as administrator**. This launches the original interactive creation script, keeps the parent console open when it exits, and appends stderr and the exit code to `Easy2Boot-erro.log`. The Easy2Boot creation flow can erase the selected disk; verify its number before confirming.

## Contents

| File/folder | Purpose |
| --- | --- |
| `Apply-Patch.ps1` | Hash-checked applicator with backup and rollback attempt |
| `scripts/` | Nine complete corrected upstream scripts and the new diagnostic launcher; original relative paths retained |
| `patches/easy2boot-2.21-cim-r2.patch` | Unified diff against the extracted original, including the diagnostic launcher |
| `manifest.json` | Original, R1 and R2 SHA-256 hashes, plus source installer hash |
| `CHANGELOG.md` | R2 fix and migration details |
| `VALIDATION.md` | Tests performed and practical limits |

For manual installation, back up the corresponding files and overlay the **contents** of `scripts/` on the Easy2Boot extraction root, merging `_ISO` rather than replacing the directory. Manual installation does not enforce hash checks. The applicator is preferred.

## Scope and compatibility

- 109 CMD/BAT/VBS scripts scanned; nine modified and 22 WMIC query invocations migrated.
- Disk queries: `Win32_DiskDrive`, `Win32_LogicalDisk`, `Win32_LogicalDiskToPartition`.
- Additional migrated queries: Windows version/build and the main script's SecurityCenter2 diagnostics.
- `property=value`, disk association tokens, disk IDs and drive-letter enumeration remain compatible with the existing `FOR /F` and `FIND` consumers. Output is explicit text, without `Format-Table` truncation.
- Requires Windows PowerShell with `Get-CimInstance` and access to the relevant CIM/WMI providers. This patch targets the tested Windows 11 scenario; older Windows/WinPE environments have not been validated.
- Existing disk selection, confirmation, sector-size and formatting logic is retained.
- EXE files are not modified or included. WMIC inventory/licensing/rename examples and the optional Add WMIC utility remain outside this patch's scope. This is not a claim that every component in Easy2Boot is WMIC-free.

The source executable supplied for this work was named `Easy2Boot_v2.21.exe` and had SHA-256:

```text
bdd5ed526e0e9ae8550b331398c3e9dcd7c41cdc42616c07160f19ac3dd0966a
```

Version labels alone are insufficient: repackaged installers may differ. The applicator checks individual script hashes and refuses unfamiliar files.

## Restore

Close Easy2Boot. Copy the saved script tree from `.e2b-cim-backup-<timestamp>-<id>/` back over the extraction root, preserving paths; `backup-manifest.json` is metadata, not an upstream file. Remove `INICIAR_COM_DIAGNOSTICO.cmd` only if it was newly added by this application. The backup manifest records which files previously existed. Backups can represent either original scripts or R1, depending on the state before patching.

## Attribution

This is an independent community patch, not an official Easy2Boot release. Existing Easy2Boot script notices remain intact. No new license is asserted over the upstream scripts in this repository. An upstream license file was not included in this patch package.
