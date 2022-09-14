# A partir de l'exemple https://www.it-connect.fr/powershell-et-foreach-object-parallel-traitement-des-objets-en-parralele/
# Ne marche qu'a partir de powershell 7

 1..50 | ForEach-Object -Parallel {Invoke-WebRequest -URI http://votingappsan-sanlab02.francecentral.cloudapp.azure.com/ -Method Post -Body @{vote="Cats"}; Start-Sleep -Seconds 1 } -ThrottleLimit 10