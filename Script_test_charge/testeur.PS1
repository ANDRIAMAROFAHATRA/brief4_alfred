#New-Item -Path C:\Users\utilisateur\Desktop\ -Name "data1.txt" -ItemType "file" 
#New-Item -Path C:\Users\utilisateur\Desktop\ -Name "data2.txt" -ItemType "file" 

$result = 1..3| ForEach-Object -Parallel {
    Invoke-WebRequest -URI http://votingappsan-sanlab02.francecentral.cloudapp.azure.com/ `
                      -Method Post `
                      -Body @{vote="Cats"} `
                      -UseBasicParsing;
    Start-Sleep -Seconds 2;
} -ThrottleLimit 1


$result.headers| export-csv C:\Users\utilisateur\Desktop\dataconvert2.csv -NoTypeInformation

#$result.headers| ForEach-Object { 
#add-content $_.'X-HANDLED-BY' -Path C:\Users\utilisateur\Desktop\data1.txt
#add-content $_.Date -Path C:\Users\utilisateur\Desktop\data2.txt
#}
#import-csv  C:\Users\utilisateur\Desktop\data2.txt -delimiter ";" | export-csv C:\Users\utilisateur\Desktop\dataconvert.csv -NoTypeInformation
#import-csv  C:\Users\utilisateur\Desktop\data1.txt -delimiter ";" | export-csv C:\Users\utilisateur\Desktop\dataconvert.csv -NoTypeInformation