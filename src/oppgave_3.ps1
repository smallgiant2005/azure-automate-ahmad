$ErrorActionPreference = 'Stop'

$Url = "http://nav-deckofcards.herokuapp.com/shuffle"
$webRequest = Invoke-WebRequest -Uri $Url


$kortstokkJson = $webRequest.Content | ConvertFrom-Json

$kortstokk = @()
foreach ($kort in $kortstokkJson)
{
    $kortstokk +=  ($kort.suit[0] + $kort.value[0] + ",")
}

Write-Host "Kortstokk:  $kortstokk"