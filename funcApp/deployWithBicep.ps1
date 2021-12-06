param (
  [string]$firstName,
  [string]$resourceGroupName,
  [string]$Location = "norwayeast",
  [string]$TemplateFile = "$PSScriptRoot/functionApp.bicep",
  [string]$subscription = "9f1b36f0-ab4c-444f-bd67-0b742263c2d6"
)

$ErrorActionPreference = 'Stop'

function Disconnect-AzureSubscription {
  Write-Host "Logger av"
  $null = Disconnect-AzAccount -Scope CurrentUser
}

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

# Deploy Bicep
$params = @{
  Name              = $firstName + '-' + (Get-Date -Format yyMMdd-HHmmss).ToString()
  ResourceGroupName = $resourceGroupName
  TemplateFile      = $TemplateFile
  Location          = $Location
  firstName         = $firstName
}

Write-Host "Deploying $firstName-FunctionApp"

$deploy = New-AzResourceGroupDeployment @params -ErrorAction SilentlyContinue -ErrorVariable deployErr

if ($deploy.ProvisioningState -eq 'Succeeded') {
  Write-Host 'Deploy finished'
}
elseif ($deploy) {
  Write-Warning "Deployment did not finish as expected"
  $deploy
  exit 1
}
else {
  Write-Warning "Deploy failed!"
  $deployErr
  exit 1
}

##############
# Kapitel 4 -
##############
<#
En function app (fa) kan ha flere funksjoner

I folder 'Functions'
- noen config-filer for fa
- En eller flere sub foldere som hver er en funksjon
- Hver sub folder/funksjon har 2 filer function.json og run.ps1

Lag en unik zip-fil av ./Functions/* i temporær katalog
Publiser zip-filen til fa
#>

$funcAppName = $deploy.Outputs.Values.value

$pArchive = @{
  Path            = "$PSScriptRoot/Functions/*"
  DestinationPath = "$([io.path]::GetTempPath())/deploy_$($funcAppName).zip"
  PassThru        = $true
  Update          = $true
}

$zip = try {
  Write-Host "Oppretter zip-fil for function app [$($funcAppName)]"
  Compress-Archive @pArchive
}
catch {
  Write-Error "$($_.Exception.Message)"
  $null
}

if ($null -eq $zip) {
  Disconnect-AzureSubscription
  exit 1
}

$pPublish = @{
  Name              = $funcAppName
  ResourceGroupName = $params.ResourceGroupName
  ArchivePath       = $zip
  Force             = $true
}

$psSite = try {
  Write-Host "Deployer function app zip-fil [$($zip.Name)]"
  Publish-AzWebApp @pPublish
}
catch {
  Write-Error "$($_.Exception.Message)"
  $null
}

if ($null -eq $psSite) {
  Disconnect-AzureSubscription
  exit 1
}


##############
# Kapitel 5 -
##############
<#
Logg av!
Avslutt
#>

Write-Host "Ferdig!"
Disconnect-AzureSubscription
exit 0