<#
.SYNOPSIS
Install the module.
.PARAMETER Module
Specify module to install.
.PARAMETER Scope
User-installed modules scope. Valid values are: CurrentUser, AllUsers.
.PARAMETER CleanUp
Remove all existing module versions in installed module directory.
.PARAMETER RemoveRequirements
Remove RequiredModules from module manifest to speed up loading time.

.EXAMPLE
./module_install.ps1 -CleanUp -Module 'do-common'
./module_install.ps1 -CleanUp -Module 'do-win'
./module_install.ps1 -CleanUp -Module 'do-az' -RemoveRequirements
#>
[CmdletBinding()]
param (
    [Alias('m')]
    [Parameter(Mandatory)]
    [string]$Module,

    [Alias('s')]
    [ValidateSet('CurrentUser', 'AllUsers')]
    [string]$Scope = 'CurrentUser',

    [Alias('c')]
    [switch]$CleanUp,

    [Alias('r')]
    [switch]$RemoveRequirements
)

$ErrorActionPreference = 'Stop'

# get module path in user context
$manifest = Test-ModuleManifest "modules/$Module/$Module.psd1"
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
$installPath = [IO.Path]::Join($modulePath, $manifest.Version.ToString())

# create/cleanup destination directory
if (Test-Path $modulePath) {
    # clean-up old module versions
    if ($CleanUp) {
        Remove-Item "$modulePath/*" -Recurse -Force
    } else {
        Remove-Item $installPath -Recurse -Force
    }
}
New-Item -ItemType Directory -Force -Path $installPath | Out-Null

# copy module files
Copy-Item -Path "$PSScriptRoot/modules/$Module/*" -Destination $installPath -Recurse

# remove requirements from module manifest to speed up module loading time
if ($RemoveRequirements) {
    $manifest = "$installPath/$Module.psd1"
    (Get-Content $manifest -Raw) -replace '(?s)RequiredModules.*?\)\n' | Set-Content $manifest
}
