$ErrorActionPreference = 'Stop'

<#
.SYNOPSIS
Set Az Context and eventually connect to Azure.
.PARAMETER Subscription
Subscription Name or ID.
.PARAMETER Tenant
Tenant Name or ID.
#>
function Connect-AzContext {
    param (
        [Alias('s')]
        [string]$Subscription,

        [Alias('t')]
        [string]$Tenant
    )

    $ctx = Get-AzContext
    if ($ctx) {
        if ($Subscription -and $Subscription -notin @($ctx.Subscription.Id, $ctx.Subscription.Name)) {
            $ctx = Invoke-CommandRetry {
                Set-AzContext -Subscription $Subscription -Tenant $ctx.Subscription.TenantId
            }
        }
    } else {
        $cmd = "Connect-AzAccount$($Subscription ? " -Subscription $Subscription" : '')$($Tenant ? " -Tenant $Tenant" : '')"
        $ctx = Invoke-CommandRetry {
            try {
                (Invoke-Expression -Command "$cmd -WarningAction Stop" 3>$null).Context
            } catch [System.Management.Automation.ActionPreferenceStopException] {
                (Invoke-Expression -Command "$cmd -UseDeviceAuthentication" -Verbose).Context
            }
        }
    }

    return $ctx
}

<#
.SYNOPSIS
Set subscription context from selection menu.
#>
function Set-SubscriptionMenu {
    # query graph api for subscriptions
    $tenantId = (Connect-AzContext).Tenant.Id
    $query = "ResourceContainers | where type =~ 'microsoft.resources/subscriptions' | project name, subscriptionId"
    $subscriptions = Search-AzGraph -Query $query -ManagementGroup $tenantId | Sort-Object name

    # select subscription from menu
    $i = Get-ArrayIndexMenu -Array $subscriptions.name -Message 'Select subscription'
    $sub = (Connect-AzContext $subscriptions[$i].subscriptionId).Subscription

    return $sub
}

Set-Alias -Name ssm -Value Set-SubscriptionMenu

<#
.SYNOPSIS
Send Azure API request.
.PARAMETER Scope
Request scope.
.PARAMETER ApiVersion
API version of the resource to query.
.PARAMETER Output
Output format.
#>
function Get-AzApiRequest {
    [CmdletBinding()]
    param (
        [Alias('s')]
        [Parameter(Mandatory, ValueFromPipeline)]
        [string]$Scope,

        [Alias('a')]
        [Parameter(Mandatory)]
        [string]$ApiVersion,

        [Alias('o')]
        [ValidateSet('json', 'jsonc', 'object')]
        [string]$Output = 'object'
    )

    begin {
        $responseList = [Collections.Generic.List[PSCustomObject]]::new()
        $params = @{
            Method         = 'Get'
            Authentication = 'Bearer'
            Token          = (Get-AzAccessToken -ResourceTypeName 'Arm').Token | ConvertTo-SecureString -AsPlainText -Force
            Headers        = @{ 'Content-Type' = 'application/json' }
            Body           = @{ 'api-version' = $ApiVersion }
        }
    }

    process {
        $response = Invoke-CommandRetry {
            Invoke-RestMethod @params -Uri "https://management.azure.com$Scope"
        }
        $responseList.Add($response)
    }

    end {
        switch ($Output) {
            { $_ -eq 'object' } {
                $responseList
            }
            { $_ -in 'json' } {
                $responseList | ConvertTo-Json -Depth 10
            }
            { $_ -eq 'jsonc' } {
                $responseList | ConvertTo-Json -Depth 10 | jq
            }
        }
    }
}
