function Format-Duration ([timespan]$TimeSpan) {
    <#
    .SYNOPSIS
    Print timespan in human readable format.#>
    switch ($TimeSpan) {
        { $_.TotalMilliseconds -gt 0 -and $_.TotalMilliseconds -lt 10 } { '{0:N2}ms' -f $_.TotalMilliseconds }
        { $_.TotalMilliseconds -ge 10 -and $_.TotalMilliseconds -lt 100 } { '{0:N1}ms' -f $_.TotalMilliseconds }
        { $_.TotalMilliseconds -ge 100 -and $_.TotalMilliseconds -lt 1000 } { '{0:N0}ms' -f $_.TotalMilliseconds }
        { $_.TotalSeconds -ge 1 -and $_.TotalSeconds -lt 10 } { '{0:N3}s' -f $_.TotalSeconds }
        { $_.TotalSeconds -ge 10 -and $_.TotalSeconds -lt 100 } { '{0:N2}s' -f $_.TotalSeconds }
        { $_.TotalSeconds -ge 100 -and $_.TotalHours -le 1 } { $_.ToString('mm\:ss\.ff') }
        { $_.TotalHours -ge 1 -and $_.TotalDays -le 1 } { $_.ToString('hh\:mm\:ss') }
        { $_.TotalDays -ge 1 } { "$($_.Days * 24 + $_.Hours):$($_.ToString('mm\:ss'))" }
        Default { '0ms' }
    }
}

function New-Password {
    # https://powersnippets.com/create-password/
    [CmdletBinding()]
    param (                            # Version 01.01.00, by iRon
        [Int]$Size = 8,
        [Char[]]$Complexity = 'ULNS',
        [Char[]]$Exclude
    )
    $AllTokens = @();
    $Chars = @();
    $TokenSets = @{
        UpperCase = [Char[]]'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
        LowerCase = [Char[]]'abcdefghijklmnopqrstuvwxyz'
        Numbers   = [Char[]]'0123456789'
        Symbols   = [Char[]]'!#%&*+-<>@^_|~'
    }
    $TokenSets.Keys | Where-Object { $Complexity -Contains $_[0] } | ForEach-Object {
        $TokenSet = $TokenSets.$_ | Where-Object { $Exclude -cNotContains $_ } | ForEach-Object { $_ }
        if ($_[0] -cle 'Z') {
            $Chars += $TokenSet | Get-Random
        }
        $AllTokens += $TokenSet
    }
    while ($Chars.Count -lt $Size) {
        $Chars += $AllTokens | Get-Random
    } -join ($Chars | Sort-Object { Get-Random })
}
