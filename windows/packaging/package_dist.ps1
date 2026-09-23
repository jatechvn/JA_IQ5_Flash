<# Build in a fresh staging directory; retain previous dist and never alter Release. #>
[CmdletBinding()]
param([string]$ProjectRoot = '')
$ErrorActionPreference = 'Stop'
if (-not $ProjectRoot) { $ProjectRoot = Join-Path $PSScriptRoot '..\..' }
$root = (Resolve-Path -LiteralPath $ProjectRoot).Path
$pubspec = Get-Content -LiteralPath (Join-Path $root 'pubspec.yaml') -Raw
if ($pubspec -notmatch '(?m)^version:\s*([0-9]+\.[0-9]+\.[0-9]+)(?:\+([0-9]+))?\s*$') { throw 'Invalid package version' }
$version = $Matches[1]
$build = $Matches[2]
$release = Join-Path $root 'build\windows\x64\runner\Release'
$dist = Join-Path $root 'dist'
foreach ($required in @('ja_iq5_flash.exe','flutter_windows.dll','data\app.so','data\icudtl.dat')) {
    if (-not (Test-Path -LiteralPath (Join-Path $release $required) -PathType Leaf)) { throw "Missing runtime: $required" }
}
$binaryVersion = (Get-Item -LiteralPath (Join-Path $release 'ja_iq5_flash.exe')).VersionInfo.ProductVersion
$expected = if ($build) { "$version+$build" } else { $version }
if ($binaryVersion -ne $expected) { throw "Stale Release binary: $binaryVersion; expected $expected" }
foreach ($path in @($release, $dist)) {
    if (Test-Path -LiteralPath $path) {
        $item = Get-Item -LiteralPath $path -Force
        for ($parent = $item; $parent; $parent = $parent.Parent) {
            if ($parent.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw "Linked packaging path refused: $path" }
        }
    }
}
$id = [guid]::NewGuid().ToString('N')
$stage = Join-Path $root ('.package-stage-' + $id)
$packageName = "JA_IQ5_Flash_v${version}_Windows_x64"
$payload = Join-Path $stage $packageName
$output = Join-Path $stage 'output'
New-Item -ItemType Directory -Path $payload,$output | Out-Null

# Only distribute runtime binaries/assets and explicitly named project documents.
$runtime = @(Get-ChildItem -LiteralPath $release -File | Where-Object { $_.Name -eq 'ja_iq5_flash.exe' -or $_.Extension -eq '.dll' -or $_.Name -eq 'native_assets.json' })
if (Get-ChildItem -LiteralPath (Join-Path $release 'data') -Recurse -Force | Where-Object { $_.Attributes -band [IO.FileAttributes]::ReparsePoint }) { throw 'Linked assets refused' }
$runtime += @(Get-ChildItem -LiteralPath (Join-Path $release 'data') -Recurse -File -Force)

# Include bin, assets, i18n if present in release
foreach ($folder in @('bin', 'assets', 'i18n')) {
    $dir = Join-Path $release $folder
    if (Test-Path -LiteralPath $dir) {
        $runtime += @(Get-ChildItem -LiteralPath $dir -Recurse -File -Force)
    }
}

foreach ($file in $runtime) {
    if ($file.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw 'Linked payload refused' }
    $relative = $file.FullName.Substring($release.Length).TrimStart('\')
    $destination = Join-Path $payload $relative
    New-Item -ItemType Directory -Path (Split-Path $destination -Parent) -Force | Out-Null
    Copy-Item -LiteralPath $file.FullName -Destination $destination
    if ((Get-FileHash -LiteralPath $file.FullName).Hash -ne (Get-FileHash -LiteralPath $destination).Hash) { throw "Copy mismatch: $relative" }
}

foreach ($name in @('debug.bat','install.bat','uninstall.bat','uninstall.ps1','ABOUT.txt','README.md','CHANGELOG.md','USERGUIDE.md','RELEASE_NOTES.md','FLASH_TROUBLESHOOTING.md','LICENSE','license.key.example')) {
    $source = Join-Path $root $name
    if (Test-Path -LiteralPath $source) { Copy-Item -LiteralPath $source -Destination (Join-Path $payload $name) }
    elseif ($name -in @('install.bat','uninstall.bat','uninstall.ps1')) { throw "Missing installer helper: $name" }
}

$zip = Join-Path $output ($packageName + '.zip')
Add-Type -AssemblyName System.IO.Compression.FileSystem
[IO.Compression.ZipFile]::CreateFromDirectory($payload, $zip, [IO.Compression.CompressionLevel]::Optimal, $true)
$archive = [IO.Compression.ZipFile]::OpenRead($zip)
try {
    $files = @(Get-ChildItem -LiteralPath $payload -Recurse -File -Force)
    if (@($archive.Entries | Where-Object { $_.Name }).Count -ne $files.Count) { throw 'ZIP file count mismatch' }
    foreach ($file in $files) {
        $entryName = $packageName + '/' + $file.FullName.Substring($payload.Length + 1).Replace('\','/')
        $entry = @($archive.Entries | Where-Object { $_.FullName.Replace('\','/') -eq $entryName }) | Select-Object -First 1
        if (-not $entry) { throw "Missing ZIP entry: $entryName" }
        $stream = $entry.Open()
        $sha = [Security.Cryptography.SHA256]::Create()
        try { $hash = [BitConverter]::ToString($sha.ComputeHash($stream)).Replace('-','') }
        finally { $stream.Dispose(); $sha.Dispose() }
        if ($hash -ne (Get-FileHash -LiteralPath $file.FullName).Hash) { throw "ZIP mismatch: $entryName" }
    }
} finally { $archive.Dispose() }

foreach ($item in Get-ChildItem -LiteralPath $payload -Force) { Copy-Item -LiteralPath $item.FullName -Destination $output -Recurse }
$hash = (Get-FileHash -LiteralPath $zip).Hash
Set-Content -LiteralPath (Join-Path $output 'SHA256SUMS.txt') -Value "$hash *$packageName.zip" -Encoding ascii

# OTA update metadata
$notesPath = Join-Path $root 'RELEASE_NOTES.md'
$notes = if (Test-Path -LiteralPath $notesPath) { (Get-Content -LiteralPath $notesPath -Raw).Trim() } else { '' }
[ordered]@{
    version = $expected
    fileName = "$packageName.zip"
    releaseNotes = $notes
    releaseDate = [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ssZ')
} | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $output 'version.json') -Encoding UTF8

# Publish only a validated complete output. Keep old output untouched on failure.
$backupDir = Join-Path $root 'backup'
$previous = Join-Path $backupDir ('dist_previous_' + $id)
$distReplaced = $false
if (Test-Path -LiteralPath $dist) {
    try {
        New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
        Move-Item -LiteralPath $dist -Destination $previous -ErrorAction Stop
        $distReplaced = $true
    } catch {
        # Fallback if dist directory handle is locked by OneDrive/Explorer/watcher:
        Write-Host "[NOTICE] dist folder handle is held by another process or OneDrive sync. Syncing contents directly..."
    }
}

if ($distReplaced -or -not (Test-Path -LiteralPath $dist)) {
    try { Move-Item -LiteralPath $output -Destination $dist -ErrorAction Stop }
    catch {
        if ((Test-Path -LiteralPath $previous) -and -not (Test-Path -LiteralPath $dist)) {
            Move-Item -LiteralPath $previous -Destination $dist -Force
        }
        throw
    }
} else {
    # Backup existing dist contents to $previous
    New-Item -ItemType Directory -Path $previous -Force | Out-Null
    Copy-Item -LiteralPath (Join-Path $dist '*') -Destination $previous -Recurse -Force
    # Clean stale build files from dist, preserving runtime configs/logs if present
    foreach ($item in (Get-ChildItem -LiteralPath $dist -Force)) {
        if ($item.Name -notmatch '^(config\.(ini|json)|license\.key|logs)$') {
            Remove-Item -LiteralPath $item.FullName -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
    # Copy fresh verified output into dist
    foreach ($item in (Get-ChildItem -LiteralPath $output -Force)) {
        Copy-Item -LiteralPath $item.FullName -Destination $dist -Recurse -Force
    }
}

# Clean staging directory
if (Test-Path -LiteralPath $stage) {
    Remove-Item -LiteralPath $stage -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host "[SUCCESS] $dist ($expected). ZIP contents, version.json and SHA256 verified."
if (Test-Path -LiteralPath $previous) { Write-Host "Previous output retained: $previous" }
