. $PSScriptRoot/Functions/common.ps1
. $PSScriptRoot/Functions/az.ps1
. $PSScriptRoot/Functions/azgraph.ps1

$exportModuleMemberParams = @{
    Function = @(
        # common
        'Invoke-CommandRetry',
        'Get-ArrayIndexMenu',
        # az
        'Connect-AzContext',
        'Set-SubscriptionMenu',
        'Invoke-AzApiRequest'
        # azgraph
        'Invoke-AzGraph',
        'Get-AzGraphSubscriptions',
        'Get-AzGraphResourceGroups',
        'Get-AzGraphResources'
    )
    Variable = @()
    Alias    = @(
        'ssm'
    )
}

Export-ModuleMember @exportModuleMemberParams
