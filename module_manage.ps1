<#
.SYNOPSIS
Manage PowerShell modules.
.PARAMETER Module
Module name.
.PARAMETER Scope
User-installed modules scope. Valid values are: CurrentUser, AllUsers.
.PARAMETER Option
Whether to create new module manifest or delete installed module. Valid values are: create, delete.

.EXAMPLE
$Module = 'do-test'
./module_manage.ps1 -m $Module -o 'create'
./module_manage.ps1 -m $Module -o 'delete'
#>
[CmdletBinding()]
param (
    [Alias('m')]
    [Parameter(Mandatory)]
    [string]$Module,

    [Alias('s')]
    [ValidateSet('CurrentUser', 'AllUsers')]
    [string]$Scope = 'CurrentUser',

    [Alias('o')]
    [Parameter(Mandatory)]
    [ValidateSet('create', 'delete')]
    [string]$Option
)

$modulePath = [IO.Path]::Join(
    $psModPath,
    $Module
)

switch ($Option) {
    {$_ -eq 'create'} {
        if (-not (Test-Path -Path "./modules/$Module")) {
            New-Item -Path "./modules/$Module" -Force -ItemType Directory | Out-Null
        }

        New-ModuleManifest -Path "modules/$Module/$Module.psd1"
    }

    {$_ -eq 'delete'} {
        $psModPath = switch ($Scope) {
            { $_ -eq 'CurrentUser' } {
                if ($IsWindows) {
                    $env:PSModulePath.Split("$($IsWindows ? ';' : ':')").Where({ $_ -match "$($HOME.Replace('\', '\\'))|$($env:OneDrive.Replace('\', '\\'))" })
                } else {
                    "$HOME/.local/share/powershell/Modules"
                }
                break
            }
            { $_ -eq 'AllUsers' } {
                $IsWindows ? "$env:ProgramFiles\PowerShell\Modules" : '/usr/local/share/powershell/Modules'
                break
            }
        }
        $modulePath = [IO.Path]::Join($psModPath, $Module)
        Remove-Item -Path $modulePath -Force -Recurse -ErrorAction SilentlyContinue
    }
}
