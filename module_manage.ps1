#!/usr/bin/pwsh -nop
#Requires -Version 7.0
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
# *module
$Module = 'do-az'
$Module = 'do-common'
$Module = 'do-win'
# *install
./module_manage.ps1 -CleanUp -Module $Module
./module_manage.ps1 -CleanUp -Module $Module -RemoveRequirements
# *delete module
./module_manage.ps1 -m $Module -o 'delete'
# *scaffold module manifest
./module_manage.ps1 -m 'do-test' -o 'new'
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
    [ValidateSet('install', 'delete', 'new')]
    [string]$Option = 'install',

    [Alias('c')]
    [switch]$CleanUp,

    [Alias('r')]
    [switch]$RemoveRequirements
)

begin {
    # source paths
    $srcModulePath = Join-Path 'modules' -ChildPath $Module
    $srcModuleManifest = Join-Path $srcModulePath -ChildPath "$Module.psd1"

    # calculate destination path
    if ($Option -ne 'new') {
        $manifest = Test-ModuleManifest $srcModuleManifest

        # get module path in user context
        $psModPathSplit = $env:PSModulePath.Split("$($IsWindows ? ';' : ':')")
        $psModPath = $Scope -eq 'CurrentUser' ? $psModPathSplit[0] : $psModPathSplit[1]
        $dstModulePath = Join-Path $psModPath -ChildPath $Module
    }
}

process {
    switch ($Option) {
        # *install modules
        'install' {
            $installPath = Join-Path $dstModulePath -ChildPath $manifest.Version.ToString()

            # create/cleanup destination directory
            if (Test-Path $dstModulePath -PathType Container) {
                # clean-up old module versions
                if ($CleanUp) {
                    Remove-Item $dstModulePath -Recurse -Force
                } else {
                    Remove-Item $installPath -Recurse -Force
                }
            }
            New-Item -ItemType Directory -Force -Path $installPath | Out-Null

            # copy module files
            Copy-Item -Path (Join-Path $manifest.ModuleBase -ChildPath '*') -Destination $installPath -Recurse

            # remove requirements from module manifest to speed up module loading time
            if ($RemoveRequirements) {
                $dstModuleManifest = Join-Path $installPath -ChildPath "$Module.psd1"
            (Get-Content $dstModuleManifest -Raw) -replace '(?s)RequiredModules.*?\)\n' | Set-Content $dstModuleManifest
            }
            break
        }
        # *delete modules
        'delete' {
            Remove-Item -Path $dstModulePath -Force -Recurse -ErrorAction SilentlyContinue
            break
        }
        # *scaffold new module manifest
        'new' {
            if (-not (Test-Path -Path $srcModulePath -PathType Container)) {
                New-Item -Path $srcModulePath -ItemType Directory | Out-Null
            }
            New-ModuleManifest -Path $srcModuleManifest
            break
        }
    }
}
