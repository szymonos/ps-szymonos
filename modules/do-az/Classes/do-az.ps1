<#
.SYNOPSIS
Class for creating an object from ResourceId.
#>
class AzResource {
    [string]$Name
    [string]$ResourceGroupName
    [guid]$SubscriptionId
    [string]$SubscriptionName
    [string]$ResourceType
    [string]$ResourceId

    # constructors
    AzResource () { }

    AzResource ([string]$id) {
        if ($id) {
            $idSplit = $id.Split('/')
            if ($idSplit.Count -eq 9) {
                $this.Name = $idSplit[8]
                $this.ResourceGroupName = $idSplit[4]
                $this.SubscriptionId = $idSplit[2]
                $this.ResourceType = "$($idSplit[6])/$($idSplit[7])"
                $this.ResourceId = $id
            } else {
                throw("Wrong ResourceId provided!`n$id")
            }
        }
    }

    AzResource ([guid]$subscriptionId, [string]$resourceGroupName, [string]$resourceType, [string]$name) {
        $this.Name = $name
        $this.ResourceGroupName = $resourceGroupName
        $this.SubscriptionId = $subscriptionId
        $this.ResourceType = $resourceType
        $this.ResourceId = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/$resourceType/$name"
    }

    [string] GetSubscriptionName () {
        $this.SubscriptionName = (Get-AzGraphSubscriptions -SubscriptionId $this.SubscriptionId).name

        return $this.SubscriptionName
    }
}
