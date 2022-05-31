<#
.SYNOPSIS
Install the module.
.PARAMETER CleanUp
Remove all existing module versions in installed module directory.
.PARAMETER RemoveRequirements
Remove RequiredModules from module manifest to speed up loading time.

.EXAMPLE
./install.ps1
./install.ps1 -CleanUp
./install.ps1 -CleanUp -RemoveRequirements
#>
[CmdletBinding()]
param (
    [Alias('c')]
    [switch]$CleanUp,

    [Alias('r')]
    [switch]$RemoveRequirements
)
# get module path in user context
$installPath = [IO.Path]::Join(
    $env:PSModulePath.Split("$($IsWindows ? ';' : ':')")[0],
    'ps-szymonos',
    (Test-ModuleManifest 'src/ps-szymonos.psd1').Version.ToString()
)

# create/cleanup destination directory
if (Test-Path $installPath) {
    # clean-up old module versions
    if ($CleanUp) {
        Remove-Item "$(Split-Path $installPath)/*" -Recurse -Force
    } else {
        Remove-Item $installPath -Recurse -Force
    }
}
New-Item -ItemType Directory -Force -Path $installPath | Out-Null

# copy module files
Copy-Item -Path "$PSScriptRoot/src/*" -Destination $installPath -Recurse

# remove requirements from module manifest to speed up module loading time
if ($RemoveRequirements) {
    $manifest = "$installPath/ps-szymonos.psd1"
    (Get-Content $manifest -Raw) -replace '(?s)RequiredModules.*?\)\n' | Set-Content $manifest
}
