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



function kortVerdi {
    param (
        [Parameter()]
        [Object[]]
        $kort
    )
    $value = 0
    $value = switch ($kort.value) {
                    "J" { 10  }
                    "Q" { 10  }
                    "K" { 10  }
                    "A" { 11  }
                    Default {$kort.value}
    }
    return $value
}
#sum the cards value and announce the winner
function sumPoengKortstokk{
    param (
        [Parameter()]
        [Object[]]
        $kortstokkJs
    )

    $sum = 0
    foreach ($kort in $kortstokkJs)
    {
         $sum +=  kortVerdi($kort)
    }

    return $sum
}

function resultsPrint {
    param (
        [string]
        $vinner,        
        [object[]]
        $kortStokkMagnus,
        [object[]]
        $kortStokkAhmad        
        )
        Write-Output "Vinner: $vinner"
        Write-Output "magnus | $(sumPoengKortstokk -kortstokk $Magnus) | $(KortstokkPrint -kortstokkJs $Magnus)"    
        Write-Output "Ahmad    | $(sumPoengKortstokk -kortstokk $Ahmad) | $(KortstokkPrint -kortstokkJs $Ahmad)"
}

$blackjack = 21

# Draw a card if sum of existing cards are less than 17
while ((sumPoengKortstokk -kortstokk $Ahmad) -lt 17) {
    
    $Ahmad += $kortstokkJson[0]
    $kortstokkJson = $kortstokkJson[1..$kortstokkJson.length]
    #Write-Host "My hand is $(KortstokkPrint($Ahmad))"
    #Write-Host "kortstokkJs is $(KortstokkPrint($kortstokkJson))"
}

if ((sumPoengKortstokk -kortstokk $Ahmad) -gt $blackjack) {
    resultsPrint -vinner "Magnus" -kortStokkMagnus $Magnus -kortStokkMeg $Ahmad
    exit
}


if ((sumPoengKortstokk -kortstokk $Magnus) -eq $blackjack) {
    resultsPrint -vinner "Magnus" -kortStokkMagnus $Magnus -kortStokkMeg $Ahmad
    exit
}
elseif ((sumPoengKortstokk -kortstokk $Ahmad) -eq $blackjack) {
    resultsPrint -vinner "Ahmad" -kortStokkMagnus $Magnus -kortStokkMeg $Ahmad
    exit
}
elseif (((sumPoengKortstokk -kortstokk $Magnus) -eq $blackjack) -and
        ((sumPoengKortstokk -kortstokk $Ahmad) -eq $blackjack)) {
    resultsPrint -vinner "Draw" -kortStokkMagnus $Magnus -kortStokkMeg $Ahmad
    exit
}elseif (((sumPoengKortstokk -kortstokk $Magnus) -lt $blackjack) -and
         ((sumPoengKortstokk -kortstokk $Ahmad) -lt $blackjack)) {
    resultsPrint -vinner "undecided" -kortStokkMagnus $Magnus -kortStokkMeg $Ahmad
     exit
}

