param(
    [string]$TexDir = "dp-text",
    [string]$Main   = "fi-lualatex"
)

$ErrorActionPreference = "Stop"

$tmp = Join-Path $TexDir "_pandoc_tmp"

# Clean up previous run
if (Test-Path $tmp) { Remove-Item $tmp -Recurse -Force }

# Copy chapter files to temp dir
Copy-Item (Join-Path $TexDir "chapters") $tmp -Recurse

# Strip tikzpicture environments from each chapter
Get-ChildItem $tmp -Filter "*.tex" | ForEach-Object {
    $c = Get-Content $_.FullName -Raw
    $c = [regex]::Replace(
        $c,
        '\\begin\{tikzpicture\}.*?\\end\{tikzpicture\}',
        '\emph{[Figure: see PDF version]}',
        [System.Text.RegularExpressions.RegexOptions]::Singleline
    )
    Set-Content -Path $_.FullName -Value $c -NoNewline
}

# Build list of chapter files in order
$chapterNames = @(
    "01-introduction",
    "02-background",
    "03-requirements",
    "04-architecture",
    "05-implementation",
    "06-testing",
    "07-conclusion"
)

$bibFile = Resolve-Path (Join-Path $TexDir "thesis.bib")
$resPath = Resolve-Path $TexDir
$outDir  = Join-Path $TexDir "docx"

if (-not (Test-Path $outDir)) { New-Item $outDir -ItemType Directory | Out-Null }

foreach ($name in $chapterNames) {
    $src = Join-Path $tmp "$name.tex"
    if (-not (Test-Path $src)) { continue }
    $out = Join-Path $outDir "$name.docx"
    pandoc $src --from=latex --bibliography=$bibFile --citeproc --resource-path=$resPath -o $out
    if ($LASTEXITCODE -ne 0) { throw "Pandoc failed on $name (exit code $LASTEXITCODE)" }
    Write-Host "  $out"
}

# Clean up
Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "Done - chapter files in $outDir/"
