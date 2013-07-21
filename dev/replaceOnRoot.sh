#!/bin/sh
# $1 file to replace, be somewhere under it, but not in later than "classes"

PATH_FROM_HERE=`find . -name $1.class`
CLASS_PATH=`echo $PATH_FROM_HERE | sed s/.*classes//`

DIR_ON_TOMCAT=`echo /var/lib/tomcat7/webapps/ROOT/WEB-INF/classes/$CLASS_PATH | sed s/$1.class//`

sudo mkdir -p $DIR_ON_TOMCAT
sudo cp $PATH_FROM_HERE $DIR_ON_TOMCAT

sudo chown -R tomcat7:tomcat7 /var/lib/tomcat7/webapps/ROOT/WEB-INF/classes

