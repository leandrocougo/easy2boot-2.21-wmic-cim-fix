# Validation

## Query migration

- Scanned 109 CMD/BAT/VBS scripts in the supplied installer extraction.
- Parsed all 22 generated PowerShell query bodies successfully.
- Executed read-only CIM disk and logical-disk association queries on Windows 11.
- Executed representative `FOR /F` consumers in CMD: `Build`, `PTN2`, `PTN2FS`, `PTN2FREE` and `myphysdrive` were populated.
- Confirmed the nine changed scripts retain their byte encoding and CRLF endings. Unchanged extracted files were compared by SHA-256.
- Tested the diagnostic launcher against a simulated child returning exit code 7 and emitting stderr: the parent reported the exit code and captured stderr in the log.
- The reporting user subsequently confirmed that R2 worked. No independent assertion is made about which disks or every creation step they exercised.

## Distribution applicator

Tested using file-only fixtures derived from the original scripts:

| Case | Result |
| --- | --- |
| `-WhatIf` | No script changes or backup created |
| Original scripts to R2 | All ten destination hashes match the manifest |
| Backup integrity | All saved scripts match original hashes |
| Reapply R2 | No changes and no additional backup |
| R1 to R2 | All ten destination hashes match the manifest |
| A local modification in the last checked upstream file | Rejected before replacing any scripts or creating a backup |
| Unified diff applied using Git to original file fixtures | All ten output hashes match the same R2 manifest |

The rollback code exists, but forced mid-copy filesystem failures were not injected. No disk creation, formatting, partitioning or installer executable was run by these tests. No CI workflow claiming hardware validation is included.

To reproduce the applicator fixture tests, supply an unmodified extraction matching the recorded original hashes:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\Test-ApplyPatch.ps1 -OriginalEasy2BootPath "C:\Tools\Easy2Boot_v2.21-original" -TestDirectory "C:\Temp\e2b-patch-tests"
```

The tests retain their file-only fixtures and write a results text file under the test directory. They do not execute upstream creation scripts.

Git may warn about CRLF as trailing whitespace when consuming the standalone diff. The patch deliberately preserves CRLF. Do not use `--whitespace=fix` on it: that can change the payload hashes. The PowerShell applicator copies exact bytes and is the recommended path.
