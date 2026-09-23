<# Backward-compatible wrapper delegating to windows\packaging\package_dist.ps1 #>
[CmdletBinding()]
param([string]$ProjectRoot = '')
$ErrorActionPreference = 'Stop'
$targetScript = Join-Path $PSScriptRoot '..\windows\packaging\package_dist.ps1'
if (-not (Test-Path -LiteralPath $targetScript)) {
    throw "Packaging script not found at $targetScript"
}
& $targetScript @PSBoundParameters
exit $LASTEXITCODE
