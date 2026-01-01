# Replace hardcoded Flutter colors with AppTheme equivalents
$files = Get-ChildItem -Path "lib\screens\*.dart" -File

$replacements = @(
    @{ Pattern = 'Colors\.blue(?!\.shade)'; Replacement = 'AppTheme.accentBlue' },
    @{ Pattern = 'Colors\.red(?!\.shade)'; Replacement = 'AppTheme.accentRed' },
    @{ Pattern = 'Colors\.orange(?!\.shade)'; Replacement = 'AppTheme.accentOrange' },
    @{ Pattern = 'Colors\.yellow(?!\.shade)'; Replacement = 'AppTheme.accentYellow' },
    @{ Pattern = 'Colors\.purple(?!\.shade)'; Replacement = 'AppTheme.accentPurple' }
)

foreach ($file in $files) {
    Write-Host "Processing: $($file.Name)"
    $content = Get-Content $file.FullName -Raw
    
    foreach ($r in $replacements) {
        $content = $content -replace $r.Pattern, $r.Replacement
    }
    
    Set-Content -Path $file.FullName -Value $content -NoNewline
}

Write-Host "Done! Replaced all hardcoded Colors.* with AppTheme.*"
