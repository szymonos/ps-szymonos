$ErrorActionPreference = 'Stop'

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
        # get results
        if ($Option -eq 'list') {
            [string[]]$result = @(winget list --source 'winget').Where({ $_ -match '^\w' })
        } elseif ($Option -eq 'upgrade') {
            [string[]]$result = @(winget upgrade --source 'winget').Where({ $_ -match '^\w' -and $_ -notmatch '^\d+ +(upgrades|package)' })
            # return if winget hasn't returned upgradeable packages
            try {
                if (-not $result[0].StartsWith('Name')) {
                    Write-Host $result -ForegroundColor Yellow
                    return
                }
            } catch {
                return
            }
        }
    }

    process {
        # index columns
        $idIndex = $result[0].IndexOf('Id')
        $versionIndex = $result[0].IndexOf('Version')
        if ($Option -eq 'upgrade') {
            $availableIndex = $result[0].IndexOf('Available')
        }
        # Now cycle in real package and split accordingly
        $packages = [Collections.Generic.List[PSObject]]::new()
        for ($i = 1; $i -lt $result.Length; $i++) {
            $package = @{
                Name = $result[$i].Substring(0, $idIndex).TrimEnd()
                Id   = $result[$i].Substring($idIndex, $versionIndex - $idIndex).TrimEnd()
            }
            if ($Option -eq 'list') {
                $package.Version = $result[$i].Substring($versionIndex, $result[$i].Length - $versionIndex).TrimEnd()
            } elseif ($Option -eq 'upgrade') {
                $package.Version = $result[$i].Substring($versionIndex, $availableIndex - $versionIndex).TrimEnd()
                $package.Available = $result[$i].Substring($availableIndex, $result[$i].Length - $availableIndex).TrimEnd()
            }
            $packages.Add([PSCustomObject]$package)
        }
    }

    end {
        if ($Option -eq 'list') {
            return $packages | Sort-Object -Property Name | Select-Object Name, Id, Version
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
        if ([System.Environment]::OSVersion.Platform -ne 'Win32NT') {
            Write-Warning 'Function can be executed on Windows only!'
            break
        }
    }

    process {
        $packages = (Get-WingetResult -o 'upgrade') | Where-Object {
            $_.Id -notin $ExcludedItems
        }
        foreach ($item in $packages) {
            Write-Host $item.Name -ForegroundColor Magenta
            winget.exe upgrade --id $item.Id
        }
    }
}
