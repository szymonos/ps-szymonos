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
Send request to Azure REST API.
.PARAMETER Scope
Request scope.
.PARAMETER ApiVersion
API version.
.PARAMETER Method
Request method. Allowed values: Get, Patch, Put, Delete. Default: Get.
.PARAMETER Body
Request payload provided as string.
.PARAMETER InFile
Request payload provided as path to file.
.PARAMETER Output
Output format. Allowed values: json, jsonc, object. Default: object.
#>
function Invoke-AzApiRequest {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Alias('s')]
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'Default')]
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'Payload:Body')]
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'Payload:File')]
        [string]$Scope,

        [Alias('a')]
        [Parameter(Mandatory, ParameterSetName = 'Default')]
        [Parameter(Mandatory, ParameterSetName = 'Payload:Body')]
        [Parameter(Mandatory, ParameterSetName = 'Payload:File')]
        [string]$ApiVersion,

        [Alias('m')]
        [Parameter(ParameterSetName = 'Default')]
        [Parameter(ParameterSetName = 'Payload:Body')]
        [Parameter(ParameterSetName = 'Payload:File')]
        [ValidateSet('Get', 'Patch', 'Put', 'Delete')]
        [string]$Method = 'Get',

        [Alias('b')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Payload:Body')]
        [ValidateScript({ '' -ne $_ }, ErrorMessage = 'Payload cannot be empty.')]
        [string]$Body,

        [Alias('f')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Payload:File')]
        [ValidateScript({ Test-Path $_ -PathType 'Leaf' }, ErrorMessage = "'{0}' is not a valid path.")]
        [string]$InFile,

        [Alias('o')]
        [Parameter(ParameterSetName = 'Default')]
        [Parameter(ParameterSetName = 'Payload:Body')]
        [Parameter(ParameterSetName = 'Payload:File')]
        [ValidateSet('json', 'jsonc', 'object')]
        [string]$Output = 'object'
    )

    begin {
        $responseList = [Collections.Generic.List[PSCustomObject]]::new()
        $params = @{
            Method         = $Method
            Authentication = 'Bearer'
            Token          = (Get-AzAccessToken -ResourceTypeName 'Arm').Token | ConvertTo-SecureString -AsPlainText -Force
            Headers        = @{ 'Content-Type' = 'application/json' }
        }

        # add payload
        if ($Body) {
            $params.Body = $Body
        } elseif ($InFile) {
            $params.InFile = $InFile
        }
    }

    process {
        $response = Invoke-CommandRetry {
            Invoke-RestMethod @params -Uri "https://management.azure.com$($Scope)?api-version=$ApiVersion"
        }
        $responseList.Add($response)
    }

    end {
        switch ($Output) {
            { $_ -eq 'object' } {
                $responseList
                break
            }
            { $_ -eq 'json' } {
                $responseList | ConvertTo-Json -Depth 10
                break
            }
            { $_ -eq 'jsonc' } {
                $responseList | ConvertTo-Json -Depth 10 | jq
                break
            }
        }
    }
}
