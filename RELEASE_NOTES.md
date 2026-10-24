# Easy2Boot 2.21 CIM R2

Community patch for Easy2Boot 2.21 on Windows installations without WMIC. Replaces 22 script queries with PowerShell `Get-CimInstance` and removes obsolete WMIC presence/PATH checks while preserving batch text consumers.

R2 also removes `-WindowStyle Hidden`, which can make the shared CMD console disappear. Includes complete corrected scripts, a diagnostic launcher, unified diff, hash manifest and an applicator with preflight checks and backups.

The reporting user confirmed R2 worked. Query parsing, representative read-only CMD/CIM queries and file-only applicator tests passed. USB creation/formatting was not independently tested. Executables are not included or modified; some unrelated WMIC examples remain outside scope.

See README.md / README.pt-BR.md for installation and the supported source hashes.
