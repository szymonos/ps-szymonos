. $PSScriptRoot/Functions/common.ps1
. $PSScriptRoot/Functions/az.ps1

$exportModuleMemberParams = @{
    Function = @(
        # common
        'Invoke-CommandRetry',
        'Get-ArrayIndexMenu',
        # az
        'Connect-AzContext',
        'Set-SubscriptionMenu',
        'Invoke-AzApiRequest'
    )
    Variable = @()
    Alias  = @(
        'ssm'
    )
}

Export-ModuleMember @exportModuleMemberParams
