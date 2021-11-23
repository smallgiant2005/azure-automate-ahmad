[CmdletBinding()]
param (
    [Parameter()]
    [string]
    $UrlKortstokk = "http://nav-deckofcards.herokuapp.com/shuffle"
)

$ErrorActionPreference = 'Stop'

$webRequest = Invoke-WebRequest -Uri $UrlKortstokk


$kortstokkJson = $webRequest.Content | ConvertFrom-Json

$sum = 0
foreach ($kort in $kortstokkJson)
{
    $sum +=  switch ($kort.value) {
        "J" { 10 }
        "Q" { 10 }
        "K" { 10 }
        "A" { 11 }
        Default {$kort.value}
    }
     
}

$kortstokk = @()
foreach ($kort in $kortstokkJson)
{
    $kortstokk +=  ($kort.suit[0] + $kort.value + ",")
}

Write-Host "Kortstokk:  $kortstokk"
Write-Host "Poengsum:   $sum"
