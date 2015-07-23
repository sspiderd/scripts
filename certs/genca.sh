#!/bin/bash
./genkey.sh $1
openssl req -new -x509 -batch -subj '/CN='$2 -days 73000 -key $1.key -out $1.crt
