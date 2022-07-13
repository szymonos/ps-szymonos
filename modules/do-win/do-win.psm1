. $PSScriptRoot/Functions/common.ps1
. $PSScriptRoot/Functions/forms.ps1
. $PSScriptRoot/Functions/winget.ps1

$exportModuleMemberParams = @{
    Function = @(
        # common
        'Get-CommandSource',
        'Get-DiskUsage',
        # forms
        'Get-FileName',
        'Get-FolderPath'
        # winget
        'Get-WingetResult',
        'Invoke-WingetUpgrade'
    )
    Variable = @()
    Alias  = @(
        'which',
        'du'
    )
}

Export-ModuleMember @exportModuleMemberParams
