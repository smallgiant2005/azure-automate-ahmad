[CmdletBinding()]
param (
    [Parameter()]
    [string]
    $UrlKortstokk = "http://nav-deckofcards.herokuapp.com/shuffle"
)

$ErrorActionPreference = 'Stop'

$webRequest = Invoke-WebRequest -Uri $UrlKortstokk


$kortstokkJson = $webRequest.Content | ConvertFrom-Json

#Sum up the value of the cards
#J, Q and K are 10 and Ace is 11
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


# Print short format of a card and its value
# input is Json formatted data
# Output is array of short formatted key-value pair 
function KortstokkPrint {
    param (
        [Parameter()]
        [Object[]]
        $kortstokkJs
    )
    $kortstokk = @()
    foreach ($kort in $kortstokkJs)
    {
        $kortstokk +=  ($kort.suit[0] + $kort.value + ",")
    }

    return $kortstokk
}

Write-Host "Kortstokk:  $(kortstokkPrint($kortstokkJson))"
Write-Host "Poengsum:   $sum"

# 2 players and each take first cards on the deck/kortstokkJson
# Print players hand and the rest of deck
$Ahmad = $kortstokkJson[0..1]
$Magnus = $kortstokkJson[2..3]
$kortstokkJson = $kortstokkJson[4..$kortstokkJson.Length]

Write-Host "Ahmad:  $(KortstokkPrint($Ahmad))"
Write-Host "Magnus:  $(KortstokkPrint($Magnus))"
Write-Host "Kortstokk:  $(KortstokkPrint($KortstokkJson))"