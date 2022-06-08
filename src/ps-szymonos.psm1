. $PSScriptRoot/Functions/common.ps1
. $PSScriptRoot/Functions/az.ps1
. $PSScriptRoot/Functions/winget.ps1

$exportModuleMemberParams = @{
    Function = @(
        # common
        'Get-ArrayIndexMenu',
        'Invoke-CommandRetry',
        # az
        'Connect-AzContext',
        'Set-SubscriptionMenu',
        'Get-AzApiRequest',
        # winget
        'Get-WingetResult',
        'Invoke-WingetUpgrade'
    )
    Variable = @()
    Alias  = @(
        'ssm'
    )
}

Export-ModuleMember @exportModuleMemberParams
