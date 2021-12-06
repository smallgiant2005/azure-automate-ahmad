[CmdletBinding()]
param (
    [Parameter(HelpMessage = "The name of the parameter file", Mandatory = $false)]
    [ValidateScript( { Test-Path $_ })]
    [string]
    $paramsFile = "$PSScriptRoot/deploy.parameters.psd1",
    [Parameter(HelpMessage = "Subscription to deploy to", Mandatory = $false)]
    [string]
    $subscription = "9f1b36f0-ab4c-444f-bd67-0b742263c2d6"
)

##############
# Kapitel 0 -
##############
<#
All cmdlet's skal i utgangspunktet kaste feil
Les parameter fil
#>

$ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop
$p = Import-PowerShellDataFile -Path $paramsFile

function Disconnect-AzureSubscription {
    Write-Host "Logger av"
    $null = Disconnect-AzAccount -Scope CurrentUser
}

##############
# Kapitel 1 -
##############
<#
Lag en funksjon som logger seg på Azure med default subscription
Lag en funksjon som logger CurrentUser av
Logg på
Forlat programmet hvis ikke pålogging lykkes
#>

$context = try {
    Set-AzContext $subscription
}
catch {
    Write-Warning "Unable to set subscription context, aborting"
    $Error[0].Exception.Message
    exit 1
}
Write-Host "Working in context $($context.Subscription.Name) [$($context.Subscription.id)]"


##############
# Kapitel 2 -
##############
<#
Sjekk om ressurs gruppe (rg) finnes
Opprett rg om den ikke finnes
Forlat programmet hvis ikke rg lykkes
#>

$pRGLookup = @{
    Name        = $p.resourceGroupName
    Location    = $p.location
    ErrorAction = [System.Management.Automation.ActionPreference]::Ignore
}

$rGroup = Get-AzResourceGroup @pRGLookup

$rGroup = if ($null -eq $rGroup) {

    $pRG = @{
        Name     = $p.resourceGroupName
        Location = $p.location
    }
    try {
        Write-Host "Oppretter resource group [$($p.resourceGroupName)]"
        New-AzResourceGroup @pRG
    }
    catch {
        Write-Error "$($_.Exception.Message)"
        $null
    }
}
else {
    Write-Host "Resource group [$($p.resourceGroupName)] finnes fra før"
    $rGroup
}

if ($null -eq $rGroup) {
    Disconnect-AzureSubscription
    exit 1
}

##############
# Kapitel 3 -
##############
<#
En function app (fa) er avhengig av lagringsplass - Storage Account (sa)
Navn på Storage Account må være GLOBALT UNIKT, 22-karakterer max, kun små bokstaver og tall
Navn på fa må være GLOBALT UNIKT, skal være en del av URL

Sjekk om sa finnes
Opprett sa om den ikke finnes
Forlat programmet hvis ikke sa lykkes

Sjekk om fa finnes
Opprett fa om den ikke finnes, bruker sa
Forlat programmet hvis ikke fa lykkes
#>

$pSALookup = @{
    Name              = $p.storageAccountName
    ResourceGroupName = $rGroup.ResourceGroupName
    ErrorAction       = [System.Management.Automation.ActionPreference]::Ignore
}

$sAccount = Get-AzStorageAccount @pSALookup

$sAccount = if ($null -eq $sAccount) {

    $pSA = @{
        Name              = $p.storageAccountName
        ResourceGroupName = $rGroup.ResourceGroupName
        Location          = $rGroup.Location
        SkuName           = 'Standard_LRS'
    }
    try {
        Write-Host "Oppretter storage account [$($p.storageAccountName)]"
        New-AzStorageAccount @pSA
    }
    catch {
        Write-Error "$($_.Exception.Message)"
        $null
    }
}
else {
    Write-Host "Storage account [$($p.storageAccountName)] finnes fra før"
    $sAccount
}

if ($null -eq $sAccount) {
    Disconnect-AzureSubscription
    exit 1
}

$pFALookup = @{
    Name              = $p.functionAppName
    ResourceGroupName = $rGroup.ResourceGroupName
    ErrorAction       = [System.Management.Automation.ActionPreference]::Ignore
}

$fApp = Get-AzFunctionApp @pFALookup

$fApp = if ($null -eq $fApp) {

    $pFA = @{
        Name               = $p.functionAppName
        Runtime            = 'Powershell'
        RuntimeVersion     = '7.0'
        FunctionsVersion   = '3'
        OSType             = 'Windows'
        ResourceGroupName  = $rGroup.ResourceGroupName
        Location           = $rGroup.Location
        StorageAccountName = $sAccount.StorageAccountName
    }

    try {
        Write-Host "Oppretter function app [$($p.functionAppName)]"
        New-AzFunctionApp @pFA
    }
    catch {
        Write-Error "$($_.Exception.Message)"
        $null
    }
}
else {
    Write-Host "Function app [$($p.functionAppName)] finnes fra før"
    $fApp
}

if ($null -eq $fApp) {
    Disconnect-AzureSubscription
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

$pArchive = @{
    Path            = "$PSScriptRoot/Functions/*"
    DestinationPath = "$([io.path]::GetTempPath())/deploy_$($fApp.Name).zip"
    PassThru        = $true
    Update          = $true
}

$zip = try {
    Write-Host "Oppretter zip-fil for function app [$($p.functionAppName)]"
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
    Name              = $fApp.Name
    ResourceGroupName = $rGroup.ResourceGroupName
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