<#
.SYNOPSIS
    Wrapper for tools/bin/verify-api.mjs.

.DESCRIPTION
    The tools are Node now, so they run on macOS and Linux and inside CI, not
    only on Windows. This wrapper exists so existing muscle memory and older
    docs keep working. It forwards every argument and preserves the exit code,
    which matters: exit 1 from verify-api means "that API does not exist".
#>
[CmdletBinding()]
param([Parameter(ValueFromRemainingArguments = $true)] [string[]] $Args)

$script = Join-Path (Split-Path $PSScriptRoot -Parent) 'bin/verify-api.mjs'
if (-not (Test-Path $script)) {
    Write-Error "Not found: $script"
    exit 2
}
& node $script @Args
exit $LASTEXITCODE
