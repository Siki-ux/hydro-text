# Count standard pages (1 page = 1,800 characters) with LaTeX commands stripped.
param([string]$Dir = "dp-text/chapters")

$total = 0
foreach ($f in Get-ChildItem "$Dir/*.tex" | Sort-Object Name) {
    $c = Get-Content $f.FullName -Raw
    # Strip comments, LaTeX commands, braces, tildes, collapse whitespace
    $c = $c -replace '(?m)%.*$', ''
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
    Write-Host ("  {0,-25} {1,6} chars = {2,5} pages" -f $f.Name, $n, $p)
}
$tp = [math]::Round($total / 1800, 1)
Write-Host ""
Write-Host ("  TOTAL: {0} chars = {1} standard pages (target: 50-70)" -f $total, $tp)

# Background share check
$bg = 0
foreach ($f in Get-ChildItem "$Dir/02-background.tex", "$Dir/03-requirements.tex" -ErrorAction SilentlyContinue) {
    $c = Get-Content $f.FullName -Raw
    $c = $c -replace '(?m)%.*$', '' -replace '\\begin\{[^}]*\}', '' -replace '\\end\{[^}]*\}', ''
    $c = $c -replace '\\[a-zA-Z]+\*?\{', '' -replace '\\[a-zA-Z]+\*?', ''
    $c = $c -replace '[{}\\~]', '' -replace '\s+', ' '
    $bg += $c.Trim().Length
}
$bgPct = [math]::Round($bg / $total * 100, 1)
Write-Host ("  Background share (Ch2+Ch3): {0}% (max 30%)" -f $bgPct)
