@echo off
:: ═══════════════════════════════════════════════════════════════════════
:: kitly.cmd — Windows batch launcher for Kitly
:: ═══════════════════════════════════════════════════════════════════════
::
:: FIX: Store the script path in a variable BEFORE using it.
:: %~dp0 can break when used inline if the path contains spaces
:: (e.g. "C:\Users\admin\My Tools\kitly\core.ps1").
:: Assigning to a variable first and double-quoting it on use is the
:: correct, robust pattern for all Windows environments.
::
:: FIX 2: Use -NonInteractive so PowerShell never pauses waiting for
:: input when running from a cmd context.
:: ═══════════════════════════════════════════════════════════════════════

setlocal

set "KITLY_SCRIPT=%~dp0core.ps1"

powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%KITLY_SCRIPT%" %*

endlocal
