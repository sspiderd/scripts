#!/bin/bash
# $1 = name of the keypair, $2 = common name, $3 = signing ca

#generate a the key for the requesting certificate
genkey.sh $1

#create a certificate request
openssl req -new -batch -subj '/CN='$2 -key $1.key -out $1.csr

#Create a random serial number
RAND=$(od -vAn -N4 -tu4 < /dev/urandom)

#Sign the certificate
openssl x509 -req -days 73000 -in $1.csr -CA $3.crt -CAkey $3.key -set_serial $RAND -out $1.crt

#Delete the certificate request, as we don't need it anymore
rm $1.csr

#Create a certificate chain for the certificate
cat $1.crt $3.crt > $1.crt.chain
