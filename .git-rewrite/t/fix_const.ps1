# Fix const widgets that reference AppTheme
$files = Get-ChildItem -Path "lib\screens\*.dart" -File

foreach ($file in $files) {
    Write-Host "Processing: $($file.Name)"
    $content = Get-Content $file.FullName -Raw
    
    # Remove const from widgets with AppTheme references
    $content = $content -replace 'const Icon\(([^)]*AppTheme[^)]*)\)', 'Icon($1)'
    $content = $content -replace 'const Text\(([^)]*AppTheme[^)]*)\)', 'Text($1)'
    $content = $content -replace 'const SnackBar\(([^)]*AppTheme[^)]*)\)', 'SnackBar($1)'
    $content = $content -replace 'const CircularProgressIndicator\(([^)]*AppTheme[^)]*)\)', 'CircularProgressIndicator($1)'
    $content = $content -replace 'const Center\(([^)]*AppTheme[^)]*)\)', 'Center($1)'
    $content = $content -replace 'const Divider\(([^)]*AppTheme[^)]*)\)', 'Divider($1)'
    $content = $content -replace 'const BorderSide\(([^)]*AppTheme[^)]*)\)', 'BorderSide($1)'
    $content = $content -replace 'const TextStyle\(([^)]*AppTheme[^)]*)\)', 'TextStyle($1)'
    
    Set-Content -Path $file.FullName -Value $content -NoNewline
}

Write-Host "Done!"
