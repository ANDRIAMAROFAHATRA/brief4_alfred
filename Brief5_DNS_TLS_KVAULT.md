# BRIEF_5 MICROSOFT AZURE  DNS, TLS, AZURE GATEWAY ET KEY VAULT

Ce document est composé de 3 parties : 

1. les différentes étapes pour la génération d'un certificat dans un environnement local Windows subsystem Linux version 2 (WSL2).
2. Dans le cadre du brief, les étapes d'importation de la clé dans le service AZURE GATEWAY 
3. La création d'un AZURE KEYVAULT et l'importation d'un certificat via les commandes AZURE CLI.


## 1. Création et exploitation d'un certificat TLS dans un environnement local WINDOWS via WSL2 : 
*Pré-requis* : 
L'installation de WSL /WSL2 dans votre environnement windows : 
https://docs.microsoft.com/fr-fr/windows/wsl/install-win10#manual-installation-steps

La génération du certificat PFX se déroule en en plusieurs étapes : 


 ###  A : Mise à jour de la distribution : 
``sudo apt update``
``sudo apt upgrade``

### B : Installation de l'utilitaire cerbot : 
``sudo apt install certbot``

- Installation de OpenSSL
``cd /usr/local/src/``
``sudo wget https://www.openssl.org/source/openssl-1.0.2o.tar.gz ``
``sudo tar -xf openssl-1.0.2o.tar.gz``
``cd openssl-1.0.2o``
``openssl version -a (commande de vérification)``
``sudo ./config --prefix=/usr/local/ssl --openssldir=/usr/local/ssl shared zlib``
``make``
``sudo make install``
``cd /etc/ld.so.conf.d/``
``sudo cat /usr/local/ssl/lib | sudo tee openssl-1.0.2o.conf``
``sudo vim openssl-1.0.2o.conf
puis coller le chemin absolue  /usr/local/ssl/lib ]``
``sudo ldconfig -v``
``sudo mv /usr/bin/c_rehash /usr/bin/c_rehash.BEKUP ``
``sudo mv /usr/bin/openssl /usr/bin/openssl.BEKUP ``
``sudo cat PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/usr/local/ssl/bin" | sudo tee /etc/environment``
``source /etc/environment (commande de rafraichissment)``
``echo $PATH (commande de vérification)``
``which openssl(commande de vérification)``
``openssl version -a (commande de vérification)``


### C : génération d'un certificat : 
Installation du module pip ;
Installer le plugin Certbot du registrar :
``pip3 install certbot-plugin-gandi``
Utiliser Certbot pour créer un certificat en utilisant le challenge DNS :
https://github.com/obynio/certbot-plugin-gandi

``sudo certbot certonly --manual <sousdomaine.domaine.tld> --preferred-challenges dns``
 

Notons que le certificat est composé de plusieurs fichiers, à savoir :

* cert.pem
* chain.pem
* fullchain.pem
* privkey.pem



Dans les étapes suivantes, seuls les fichiers suivants seront utilisés :

* fullchain.pem –> Le certificat et les CA.
* privkey.pem –> La clef privée du certificat.




### D : Conversion au format "PFX"
Afin de rendre le certificat utilisable sur les environnements Windows, il est nécessaire de le convertir au format “pfx”.

1- Concaténation des deux fichier fullchain.pem & privkey.pem 
La commande nécessite une élévation de droit pour avoir accès au répertoire.

``sudo su``
``cd /etc/letsencrypt/live/<sousdomaine.domaine.tld>/
touch clefinale.pem``
``sudo cat fullchain.pem privkey.pem | sudo tee clefinal.pem``
2 - Converstion de la clé du format .pem vers le format PFX (ou PKCS12)
``openssl pkcs12 -export -out <clefinale.p12> -in <clefinale.pem>``


### Déplacement dans le temporaire windows :
 
Le nouveau certificat est créé dans le répertoire ``“/etc/letsencrypt/live/<sousdomaine.domaine.tld>/”``
Pour récupérer le certificat  (ainsi que l'ensemble du répertoire dans le répertoire “C:\temp\” utiliser la commande ci-dessous :

``cp -rf /etc/letsencrypt/live/<sousdomaine.domaine.tld>/ /mnt/c/Temp/``


***A partir d'ici, le certificat en format PFX est récupérable WINDOWS.*** 

## 2.Importer le certificats dans azure via le Portail AZURE. 

Nous partons du principe que l'infrastructure déployé possède un SERVICE AZURE GATEWAY 
Se rendre sur le service AZURE GATEWAY de son groupe de ressource. 
- Aller dans la section Listenner
1.Aller dans l'onget Listenner afin d'ouvrir le port d'écoute entrant du service AZURE GATEWAY  côté front-end **443**
2.Importer le certificat qui a été créer en locale
- Ensuite aller dans la section rules :
1.Créer une règles qui va cibler les échanges avec son Backend.
2.Option facultative = Possilité depuis cette section d'activer des redirections de toute les requête vers le site en HTTP vers le site HTTPS.




## 3. Création d'un Key vault via les commandes AZ CLI et importation du certificat

*Pré-requis : Avoir AZ CLI d'installer dans son environnemente de travail.* 


# Création d'un coffre de clés 

Création d'un coffre AZURE KEY VAULT 

``az keyvault create --name "<your-unique-keyvault-name>" --resource-group "myResourceGroup" --location "EastUS"``

importer un certificat 

``az keyvault certificate import --vault-name "<your-key-vault-name>" -n "ExampleCertificate" -f "/path/to/ExampleCertificate.pem"``

Afficher le certificat 

``az keyvault certificate show --vault-name "<your-key-vault-name>" --name "ExampleCertificate"``



Liens et sources. 

https://github.com/obynio/certbot-plugin-gandi
Création certificat via WSL2
https://teddycorp.net/wsl2-certbot-creer-des-certificats-ssl/
Documentation officiel MICROSOFT AZURE KEY VAULT
https://learn.microsoft.com/en-us/azure/key-vault/
