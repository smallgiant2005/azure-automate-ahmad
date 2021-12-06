[CmdletBinding()]
param (
    [Parameter()]
    [string]
    $resourceGroupName,
    [string]$subscription = "9f1b36f0-ab4c-444f-bd67-0b742263c2d6"    
)

$ErrorActionPreference = 'Stop'

#set context
$context = try {
    Set-AzContext $subscription
}
catch {
    Write-Warning "Unable to set subscription context, aborting"
    $Error[0].Exception.Message
    exit 1
}
Write-Host "Working in context $($context.Subscription.Name) [$($context.Subscription.id)]"

#Filter out app service plan which can't be deleted when assigned to a function app
$resources = Get-AzResource -ResourceGroupName $resourceGroupName |  Where-Object -FilterScript {$_.ResourceType -ne 'Microsoft.Web/serverFarms'}
$resources | Remove-AzResource -Force
Get-AzResource -ResourceGroupName $resourceGroupName | Remove-AzResource -Force