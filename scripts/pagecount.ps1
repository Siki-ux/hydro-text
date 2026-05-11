# Count standard pages (1 page = 1,800 characters) with LaTeX commands stripped.
# Own figures count as 0.5 page each. Appendix (08-*) is excluded from the total.
param([string]$Dir = "dp-text/chapters")

$total = 0
$mainTotal = 0
$figCount = 0
foreach ($f in Get-ChildItem "$Dir/*.tex" | Sort-Object Name) {
    $raw = Get-Content $f.FullName -Raw
    # Count figures (own pictures) in this file
    $figs = ([regex]::Matches($raw, '\\begin\{figure\}')).Count
    # Strip comments, LaTeX commands, braces, tildes, collapse whitespace
    $c = $raw -replace '(?m)%.*$', ''
    $c = $c -replace '\\begin\{[^}]*\}', ''
    $c = $c -replace '\\end\{[^}]*\}', ''
    $c = $c -replace '\\[a-zA-Z]+\*?\{', ''
    $c = $c -replace '\\[a-zA-Z]+\*?', ''
    $c = $c -replace '[{}\\~]', ''
    $c = $c -replace '\s+', ' '
    $c = $c.Trim()
    $n = $c.Length
    $p = [math]::Round($n / 1800, 1)
    $total += $n
    $isAppendix = $f.Name -match '^08-'
    if (-not $isAppendix) {
        $mainTotal += $n
        $figCount += $figs
    }
    $suffix = if ($isAppendix) { " (appendix, excluded)" } elseif ($figs -gt 0) { " + $figs fig(s)" } else { "" }
    Write-Host ("  {0,-25} {1,6} chars = {2,5} pages{3}" -f $f.Name, $n, $p, $suffix)
}
$textPages = [math]::Round($mainTotal / 1800, 1)
$figPages = $figCount * 0.5
$totalPages = [math]::Round($textPages + $figPages, 1)
Write-Host ""
Write-Host ("  Text pages (ch01-07):  {0}" -f $textPages)
Write-Host ("  Figure pages ({0} figs x 0.5): {1}" -f $figCount, $figPages)
Write-Host ("  TOTAL standard pages: {0} (target: 50-70)" -f $totalPages)

# Background share check
$bg = 0
foreach ($f in Get-ChildItem "$Dir/02-background.tex", "$Dir/03-requirements.tex" -ErrorAction SilentlyContinue) {
    $c = Get-Content $f.FullName -Raw
    $c = $c -replace '(?m)%.*$', '' -replace '\\begin\{[^}]*\}', '' -replace '\\end\{[^}]*\}', ''
    $c = $c -replace '\\[a-zA-Z]+\*?\{', '' -replace '\\[a-zA-Z]+\*?', ''
    $c = $c -replace '[{}\\~]', '' -replace '\s+', ' '
    $bg += $c.Trim().Length
}
$bgPct = [math]::Round($bg / $mainTotal * 100, 1)
Write-Host ("  Background share (Ch2+Ch3): {0}% (max 30%)" -f $bgPct)
