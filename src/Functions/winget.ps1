<#
.SYNOPSIS
Parse winget upgrade results and return object with list of upgradeable packages.
.PARAMETER Option
Specify if the result should return all installed packages or upgradeable only.
.EXAMPLE
Get-WingetResult
.EXAMPLE
Get-WingetResult -o 'upgrade'
#>
function Get-WingetResult {
    [CmdletBinding()]
    param (
        [Alias('o')]
        [ValidateSet('list', 'upgrade')]
        [string]$Option = 'list'
    )

    begin {
        if (-not $IsWindows) {
            Write-Warning 'Function can be executed on Windows only!'
            break
        }
    }

    process {
        # get results
        if ($Option -eq 'list') {
            [string[]]$result = @(winget list).Where({ $_ -match '^\w' })
        } else {
            [string[]]$result = @(winget upgrade).Where({ $_ -match '^\w' -and $_ -notmatch '^\d+ +upgrades' })
        }

        # return if winget hasn't returned upgradeable packages
        try {
            if (-not $result[0].StartsWith('Name')) {
                return $result[0]
            }
        } catch {
            return
        }

        # index columns
        $idIndex = $result[0].IndexOf('Id')
        $versionIndex = $result[0].IndexOf('Version')
        $availableIndex = $result[0].IndexOf('Available')
        $sourceIndex = $result[0].IndexOf('Source')
        # Now cycle in real package and split accordingly
        $packages = [Collections.Generic.List[PSObject]]::new()
        for ($i = 1; $i -lt $result.Length; $i++) {
            $package = [ordered]@{
                Name      = $result[$i].Substring(0, $idIndex).TrimEnd()
                Id        = $result[$i].Substring($idIndex, $versionIndex - $idIndex).TrimEnd()
                Version   = $result[$i].Substring($versionIndex, $availableIndex - $versionIndex).TrimEnd()
                Available = $result[$i].Substring($availableIndex, $sourceIndex - $availableIndex).TrimEnd()
                Source    = $result[$i].Substring($sourceIndex, $result[$i].Length - $sourceIndex)
            }
            $packages.Add([PSCustomObject]$package)
        }
    }

    end {
        if ($Option -eq 'list') {
            return $packages | Sort-Object -Property Name | Select-Object Name, Id, Version, Source
        } else {
            return $packages | Sort-Object -Property Name | Select-Object Name, Id, Version, Available
        }
    }
}

<#
.SYNOPSIS
Update all packages that were not excluded or unknown.
.PARAMETER ExcludedItems
List of excluded packages from upgrade.
.EXAMPLE
Invoke-WingetUpgrade
.EXAMPLE
Invoke-WingetUpgrade -e @('Microsoft.Edge', 'Mozilla.Firefox')
#>
function Invoke-WingetUpgrade {
    [CmdletBinding()]
    param (
        [Alias('e')]
        [string[]]$ExcludedItems = @()
    )

    begin {
        if (-not $IsWindows) {
            Write-Warning 'Function can be executed on Windows only!'
            break
        }
    }

    process {
        $packages = Get-WingetResult -o 'upgrade' | Where-Object {
            $_.Id -notin $ExcludedItems -and $_.Version -ne 'Unknown'
        }
        foreach ($item in $packages) {
            [Console]::WriteLine("`e[95m$($item.Name)`e[0m")
            winget.exe upgrade --id $item.Id
        }
        if (-not $packages.Count) {
            Write-Host 'No packages to upgrade.'
        }
    }
}
