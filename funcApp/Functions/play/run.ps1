using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."

# Interact with query parameters or the body of the request.
$urlKortstokk = switch ($Request.Query.urlKortstokk) {
  {-not $_} {$Request.Body.urlKortstokk}
  Default {$_}
}

function playBlackjack {
    [OutputType([hashtable])]
    param (
        [string]
        $encodedUrlKortstokk = 'http%3A%2F%2Fnav-deckofcards.herokuapp.com%2Fshuffle'
    )

    # Feilhåndtering - stopp programmet hvis det dukker opp noen feil
    # Se https://docs.microsoft.com/en-us/dotnet/api/system.management.automation.actionpreference?view=powershellsdk-7.0.0
    $ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop

    $webRequest = Invoke-WebRequest -Uri ([System.Web.HttpUtility]::UrlDecode($encodedUrlKortstokk))

    $kortstokkJson = $webRequest.Content

    $kortstokk = ConvertFrom-Json -InputObject $kortstokkJson

    function kortstokkTilStreng {
        [OutputType([string])]
        param (
            [object[]]
            $kortstokk
        )
        $streng = ''
        foreach ($kort in $kortstokk) {
            $streng = $streng + "$($kort.suit[0])" + $kort.value + ","
        }
        return $streng
    }

    function sumPoengKortstokk {
        [OutputType([int])]
        param (
            [object[]]
            $kortstokk
        )

        $poengKortstokk = 0

        foreach ($kort in $kortstokk) {
            $poengKortstokk += switch ($kort.value) {
                { $_ -cin @('J', 'Q', 'K') } { 10 }
                'A' { 11 }
                default { $kort.value }
            }
        }
        return $poengKortstokk
    }

    function resultatTilHashtable {
        param (
            [string]
            $vinner,
            [object[]]
            $kortStokkMagnus,
            [object[]]
            $kortStokkMeg
        )
        [ordered]@{
            vinner = $vinner
            magnus = [ordered]@{
                poeng = $(sumPoengKortstokk -kortstokk $kortStokkMagnus)
                kort  = $(kortStokkTilStreng -kortstokk $kortStokkMagnus)
            }
            meg    = [ordered]@{
                poeng = $(sumPoengKortstokk -kortstokk $kortStokkMeg)
                kort  = $(kortStokkTilStreng -kortstokk $kortStokkMeg)
            }
        }
    }

    # Write-Output "Kortstokk: $(kortStokkTilStreng -kortstokk $kortstokk)"
    # Write-Output "Poengsum: $(sumPoengKortstokk -kortstokk $kortstokk)"
    # Write-Output ""

    ### Regler (1)
    ### Du tar de to første kortene, Magnus tar de to neste

    $meg = $kortstokk[0..1]
    $kortstokk = $kortstokk[2..$kortstokk.Count]

    $magnus = $kortstokk[0..1]
    $kortstokk = $kortstokk[2..$kortstokk.Count]

    ### Regn ut den samlede poengsummen til hver spiller
    ### Regn ut om en av spillerene har 21 poeng - Blackjack - med deres initielle kort, og dermed vinner runden

    # bruker 'blackjack' som et begrep - er 21
    $blackjack = 21

    if (((sumPoengKortstokk -kortstokk $meg) -eq $blackjack) -and ((sumPoengKortstokk -kortstokk $magnus) -eq $blackjack)) {
        return resultatTilHashtable -vinner "Draw" -kortStokkMagnus $magnus -kortStokkMeg $meg
        #exit
    }
    elseif ((sumPoengKortstokk -kortstokk $meg) -eq $blackjack) {
        resultatTilHashtable -vinner "meg" -kortStokkMagnus $magnus -kortStokkMeg $meg
        exit
    }
    elseif ((sumPoengKortstokk -kortstokk $magnus) -eq $blackjack) {
        return resultatTilHashtable -vinner "magnus" -kortStokkMagnus $magnus -kortStokkMeg $meg
        #exit
    }

    ### Regler(2)

    ### Hvis ingen har 21 poeng, skal spillerne trekke kort fra toppen av kortstokken
    ### Du skal stoppe å trekke kort når poengsummen blir 17 eller høyere

    while ((sumPoengKortstokk -kortstokk $meg) -lt 17) {
        $meg += $kortstokk[0]
        $kortstokk = $kortstokk[1..$kortstokk.Count]
    }

    ### Du taper spillet hvis poengsummen er høyere enn 21

    if ((sumPoengKortstokk -kortstokk $meg) -gt $blackjack) {
        return resultatTilHashtable -vinner "magnus" -kortStokkMagnus $magnus -kortStokkMeg $meg
        #exit
    }

    ### Når du har stoppet å trekke kort, begynner Magnus å trekke kort
    ### Magnus slutter å trekke kort når poengsummen hans er høyere enn din poengsum

    while ((sumPoengKortstokk -kortstokk $magnus) -le (sumPoengKortstokk -kortstokk $meg)) {
        $magnus += $kortstokk[0]
        $kortstokk = $kortstokk[1..$kortstokk.Count]
    }

    ### Magnus taper spillet dersom poengsummen er høyere enn 21
    if ((sumPoengKortstokk -kortstokk $magnus) -gt $blackjack) {
        return resultatTilHashtable -vinner "meg" -kortStokkMagnus $magnus -kortStokkMeg $meg
        #exit
    }

    return resultatTilHashtable -vinner "magnus" -kortStokkMagnus $magnus -kortStokkMeg $meg
}

$r = try {
    switch ($urlKortstokk) {
        { -not $_ } { playBlackJack }
        Default { playBlackJack -encodedUrlKortstokk $urlKortstokk }
    }
}
catch { 
    $null
}


$httpResp = if (-not $r) {
    [HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::OK
        Body = @{error = 'something went wrong, invalid param?'}
    }    
}
else {
    [HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::OK
        Body = ConvertTo-Json -InputObject $r
    }        
}

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value $httpResp


