# A partir de l'exemple https://www.it-connect.fr/powershell-et-foreach-object-parallel-traitement-des-objets-en-parralele/
# Ne marche qu'a partir de powershell 7
# Les Keys/value du header pas dans le même index entre powershell 5 et powershell 7 

#$result = 1..10 | ForEach-Object -Parallel {Invoke-WebRequest -URI http://votingappsan-sanlab02.francecentral.cloudapp.azure.com/ -Method Post -Body @{vote="Cats"} -UseBasicParsing; Start-Sleep -Seconds 1;} -ThrottleLimit 2

# première boucle de 1 a 100, une seconde entre envoie de chaque bloc de 2 requetes.
$result = 1..10 | ForEach-Object -Parallel {
    Invoke-WebRequest -URI http://votingappsan-sanlab02.francecentral.cloudapp.azure.com/ `
                      -Method Post `                      -Body @{vote="Cats"} `
                      -UseBasicParsing;
    Start-Sleep -Seconds 1;
} -ThrottleLimit 2

# $_ en powershell permet de "selectionner" dans chaque requete le X-HANDLED-BY. Sinon il répète celui du premier tableau pour chaque $result.headers et cela fausse le résultat
$result.headers | ForEach-Object {
    Write-Output $_.'X-HANDLED-BY'
    Write-Output $_.Date
}

# Faire une deuxième boucle car le test de charge n'est pas assez long (décalage entre résultat et se qui se spawn en temps réel

$resulttwo = 1..10 | ForEach-Object -Parallel {
    Invoke-WebRequest -URI http://votingappsan-sanlab02.francecentral.cloudapp.azure.com/ `
                      -Method Post `                      -Body @{vote="Dogs"} `
                      -UseBasicParsing;
    Start-Sleep -Seconds 15;
} -ThrottleLimit 3

$resulttwo.headers | ForEach-Object {
    Write-Output $_.'X-HANDLED-BY'
    Write-Output $_.Date
}