$files = Get-ChildItem -Path "e:\Turtle Wow\Interface\AddOns\WCS_Brain\*.lua"
foreach ($f in $files) {
    $c = Get-Content $f.FullName -Raw
    $nc = $c -replace 'VERSION\s*=\s*"[67]\.\d+\.\d+"', 'VERSION = "8.0.0"' `
             -replace 'Version[:\s]*[67]\.\d+\.\d+', 'Version 8.0.0' `
             -replace 'v[67]\.\d+\.\d+', 'v8.0.0' `
             -replace 'v[67]\.\d+', 'v8.0'
    if ($c -cne $nc) {
        Set-Content -Path $f.FullName -Value $nc -NoNewline
        Write-Host "Updated $($f.Name)"
    }
}
