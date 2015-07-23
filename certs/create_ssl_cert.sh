#from: http://onlamp.com/onlamp/2008/03/04/step-by-step-configuring-ssl-under-apache.html
openssl req -new -x509 -days 365 -sha1 -newkey rsa:1024 -nodes -keyout server.key -out server.crt -subj '/O=Company/OU=Department/CN=www.ilan.com'
