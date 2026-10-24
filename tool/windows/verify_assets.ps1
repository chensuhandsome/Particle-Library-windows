[CmdletBinding()]
param(
    [string]$AssetsDirectory,
    [string]$ReferenceAssetsDirectory,
    [switch]$SkipSnapshot
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if (-not $AssetsDirectory) { $AssetsDirectory = Join-Path $repoRoot 'assets' }

function Read-ContractValue([string]$Contract, [string]$Name) {
    $pattern = '\b' + [regex]::Escape($Name) + "\s*=\s*(?:'([^']+)'|(\d+))\s*;"
    $match = [regex]::Match($Contract, $pattern)
    if (-not $match.Success) { throw "Missing contract value: $Name" }
    if ($match.Groups[1].Success) { return $match.Groups[1].Value }
    return $match.Groups[2].Value
}

function Assert-Asset([string]$Name, [string]$ExpectedHash = '', [long]$ExpectedSize = -1) {
    $path = Join-Path $AssetsDirectory $Name
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Missing asset: $path" }
    if ($ExpectedSize -ge 0 -and (Get-Item -LiteralPath $path).Length -ne $ExpectedSize) {
        throw "Asset size mismatch: $Name"
    }
    $actual = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($ExpectedHash -and $actual -ne $ExpectedHash) { throw "Asset SHA-256 mismatch: $Name" }
    if ($ReferenceAssetsDirectory) {
        $reference = Join-Path $ReferenceAssetsDirectory $Name
        if (-not (Test-Path -LiteralPath $reference -PathType Leaf)) { throw "Missing reference asset: $reference" }
        if ($actual -ne (Get-FileHash -LiteralPath $reference -Algorithm SHA256).Hash.ToLowerInvariant()) {
            throw "Packaged asset differs from source: $Name"
        }
    }
}

if (-not $SkipSnapshot) {
    $snapshot = Get-Content -LiteralPath (Join-Path $repoRoot 'lib/core/contract.dart') -Raw -Encoding UTF8
    Assert-Asset (Read-ContractValue $snapshot 'fileName') `
        (Read-ContractValue $snapshot 'expectedSha256') `
        ([long](Read-ContractValue $snapshot 'expectedSizeBytes'))
}
$index = Get-Content -LiteralPath (Join-Path $repoRoot 'lib/core/review_index_contract.dart') -Raw -Encoding UTF8
Assert-Asset 'review_index_2026.sqlite' (Read-ContractValue $index 'expectedSha256') `
    ([long](Read-ContractValue $index 'expectedSizeBytes'))
Assert-Asset 'review_search_rules_v1.json' (Read-ContractValue $index 'expectedRulesSha256')
Assert-Asset 'review_sources_2026.json' (Read-ContractValue $index 'expectedManifestSha256')
Assert-Asset 'pdg_notes_2026.sqlite'
$notes = [System.IO.File]::OpenRead((Join-Path $AssetsDirectory 'pdg_notes_2026.sqlite'))
try {
    $header = New-Object byte[] 16
    if ($notes.Read($header, 0, 16) -ne 16 -or
        [System.Text.Encoding]::ASCII.GetString($header) -ne "SQLite format 3`0") {
        throw 'PDG notes asset is not a SQLite database.'
    }
} finally { $notes.Dispose() }
Write-Host "Verified data assets: $AssetsDirectory"
