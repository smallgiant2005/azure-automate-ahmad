[CmdletBinding()]
param (
    [Parameter()]
    [string]
    $UrlKortstokk = "http://nav-deckofcards.herokuapp.com/shuffle"
)

$ErrorActionPreference = 'Stop'

$webRequest = Invoke-WebRequest -Uri $UrlKortstokk


$kortstokkJson = $webRequest.Content | ConvertFrom-Json

$kortstokk = @()
foreach ($kort in $kortstokkJson)
{
    $kortstokk +=  ($kort.suit[0] + $kort.value[0] + ",")
}

Write-Host "Kortstokk:  $kortstokk"

