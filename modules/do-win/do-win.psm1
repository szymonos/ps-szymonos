. $PSScriptRoot/Functions/forms.ps1
. $PSScriptRoot/Functions/winget.ps1

$exportModuleMemberParams = @{
    Function = @(
        # forms
        'Get-FileName',
        'Get-FolderPath'
        # winget
        'Get-WingetResult',
        'Invoke-WingetUpgrade'
    )
    Variable = @()
    Alias  = @(
    )
}

Export-ModuleMember @exportModuleMemberParams
