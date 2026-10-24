# Changelog

## Validation report — 2026-10-24

- Record the repository owner's successful creation of a bootable SSD on Windows 11 25H2 using the correction. Actual startup from the SSD has not yet been reported. No script behavior changed in this documentation update.

## 2.21-cim-r2

- Remove `-WindowStyle Hidden` from all 22 embedded queries. It can hide the shared batch console and make the interactive flow appear to have exited. The reporting user confirmed R2 worked.
- Add a diagnostic CMD launcher that retains the parent console and records stderr and exit code.
- Package complete corrected scripts, unified diff, hash manifest and a standalone PowerShell applicator with preflight checks, backup and rollback attempt.

## Initial CIM migration

- Remove the main WMIC missing-component gate and related obsolete WBEM/PATH gates.
- Replace disk, logical disk and disk-to-partition association queries with `Get-CimInstance`.
- Migrate Windows version/build queries and the main creation script's SecurityCenter2 queries.
- Preserve existing batch text consumers, file encoding and CRLF line endings.

R1 is superseded by R2; do not reintroduce the hidden-window argument into embedded queries.
