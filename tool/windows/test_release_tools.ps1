$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$verifier = Join-Path $PSScriptRoot 'verify_assets.ps1'
$tempRoot = [System.IO.Path]::GetFullPath([System.IO.Path]::GetTempPath())
$sandbox = Join-Path $tempRoot ('particle-release-tools-' + [guid]::NewGuid().ToString('N'))
[System.IO.Directory]::CreateDirectory($sandbox) | Out-Null
try {
    foreach ($name in @('pdg_notes_2026.sqlite', 'review_index_2026.sqlite', 'review_search_rules_v1.json', 'review_sources_2026.json')) {
        Copy-Item -LiteralPath (Join-Path $repoRoot "assets/$name") -Destination $sandbox
    }
    & $verifier -AssetsDirectory $sandbox -SkipSnapshot
    $failed = $false
    try { & $verifier -AssetsDirectory $sandbox } catch { $failed = $_.Exception.Message -like 'Missing asset:*pdgall*' }
    if (-not $failed) { throw 'Missing main snapshot was accepted.' }
    $rules = Join-Path $sandbox 'review_search_rules_v1.json'
    [System.IO.File]::AppendAllText($rules, ' ')
    $failed = $false
    try { & $verifier -AssetsDirectory $sandbox -SkipSnapshot } catch { $failed = $_.Exception.Message -like 'Asset SHA-256 mismatch:*' }
    if (-not $failed) { throw 'Modified review rules were accepted.' }
    Copy-Item -LiteralPath (Join-Path $repoRoot 'assets/review_search_rules_v1.json') -Destination $rules -Force
    $index = Join-Path $sandbox 'review_index_2026.sqlite'
    [System.IO.File]::WriteAllBytes($index, [byte[]]@(1, 2, 3))
    $failed = $false
    try { & $verifier -AssetsDirectory $sandbox -SkipSnapshot } catch { $failed = $_.Exception.Message -like 'Asset size mismatch:*' }
    if (-not $failed) { throw 'Truncated review index was accepted.' }
    Copy-Item -LiteralPath (Join-Path $repoRoot 'assets/review_index_2026.sqlite') -Destination $index -Force
    [System.IO.File]::WriteAllText((Join-Path $sandbox 'pdg_notes_2026.sqlite'), 'invalid SQLite file')
    $failed = $false
    try { & $verifier -AssetsDirectory $sandbox -SkipSnapshot } catch { $failed = $_.Exception.Message -like '*not a SQLite database*' }
    if (-not $failed) { throw 'Invalid notes database was accepted.' }
    Write-Host 'Release tools correctly reject missing, modified and truncated assets.'
} finally {
    $resolved = [System.IO.Path]::GetFullPath($sandbox)
    if ([System.IO.Path]::GetDirectoryName($resolved).TrimEnd('\') -ne $tempRoot.TrimEnd('\') -or
        [System.IO.Path]::GetFileName($resolved) -notlike 'particle-release-tools-*') {
        throw 'Refusing to remove an unexpected test directory.'
    }
    Remove-Item -LiteralPath $resolved -Recurse -Force
}
