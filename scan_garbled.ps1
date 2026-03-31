# Fix garbled translations - save with UTF-8 BOM
# This script reads the .au3 file and fixes the garbled Chinese text
param()
$ErrorActionPreference = 'Stop'

$file = Join-Path $PSScriptRoot "GenP\GenP-3.8.0.au3"
$bytes = [System.IO.File]::ReadAllBytes($file)
$text = [System.Text.Encoding]::UTF8.GetString($bytes)
$origLen = $text.Length
Write-Host "Loaded: $origLen chars"

$count = 0

function DoFix {
    param([string]$context, [string]$wrong, [string]$right)
    # Find context string, then replace wrong portion within it
    if ($script:text.Contains($wrong)) {
        $script:text = $script:text.Replace($wrong, $right)
        $script:count++
        Write-Host "  FIXED: $($right.Substring(0, [Math]::Min(40, $right.Length)))"
    } else {
        Write-Host "  SKIP: $($right.Substring(0, [Math]::Min(40, $right.Length)))"
    }
}

# The batch script replaced English text with garbled Chinese.
# We need to find the garbled text and replace with correct Chinese.
# Strategy: search for the English context that still exists around the garbled text.

# Let's find all lines with private-use Unicode chars (U+E000-U+F8FF) and fix them
$lines = $text -split "`n"
$garbledLines = @()
for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match '[\uE000-\uF8FF]') {
        $garbledLines += $i
    }
}
Write-Host "Found $($garbledLines.Count) garbled lines"

# Output context for debugging
foreach ($lineNum in $garbledLines) {
    $line = $lines[$lineNum]
    # Extract the garbled portion (chars between quotes that contain private-use chars)
    Write-Host "Line $($lineNum + 1): $($line.Trim().Substring(0, [Math]::Min(80, $line.Trim().Length)))"
}

Write-Host "`nDone scanning. Now saving line numbers to fix_lines.txt"
$garbledLines | ForEach-Object { $_ + 1 } | Out-File (Join-Path $PSScriptRoot "fix_lines.txt")
