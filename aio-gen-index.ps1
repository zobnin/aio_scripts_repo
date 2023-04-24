#Requires -Version 5.0

$lastFile = Get-ChildItem | Sort-Object -Descending | Select-Object -First 1

Write-Output "["

Get-ChildItem -Filter "*.lua" | ForEach-Object {
    Write-Output "{"
    Write-Output "`"file`": `"$($_.Name)`","
    Get-Content $_.FullName -Encoding UTF8 | ForEach-Object {
        if ($_ -match '^--\s*[a-zA-Z]*\s*=') {
            $matches = [regex]::Matches($_, '^--\s*([a-zA-Z]*)\s*=')
            $key = $matches[0].Groups[1].Value
            $value = $_ -replace '^--\s*[a-zA-Z]*\s*=\s*', ''
            Write-Output "`"$key`": $value,"
        }
    }
    Write-Output "`"md5sum`": `"$(Get-FileHash $_.FullName -Algorithm MD5 | Select-Object -ExpandProperty Hash)`""
    if ($_.Name -eq $lastFile.Name) {
        Write-Output "}"
    }
    else {
        Write-Output "},"
    }
}

Write-Output "]"