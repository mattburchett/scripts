#!/bin/bash

if [ -z "$1" ]
then
        echo "Usage: ./wp-nginx-lock.sh [site name]"
        echo "Parameters: ./wp-nginx-lock -h for help"
        exit
fi

if [ $1 == "-h" ]
then
        echo "wp-nginx-lock.sh help:"
        echo ""
        echo "Usage: ./wp-nginx-lock.sh [site name] [parameter] [parameter-setting]" 
        echo ""
        echo "[site name] is the htdocs folder name ie [/srv/http/www.example.com]"
        echo ""
        echo "Parameters must be specified in parameter section with the destination in parameter-setting."
        echo ""
        echo "-d, destination pre-htdocs folder [default is /srv/http]"
fi 

if [ -z "$2" ] 
then
        SRV=/srv/http
else
        if [ -z "$3" ]
        then
                echo "You can't pass -d without a parameter parameter."
                echo "Usage: ./wp-nginx-lock.sh www.example.com -d /srv/html"
                exit
        else
                SRV=$3
        fi
fi

echo "Checking for a valid wordpress instance..."

if [ -f "$SRV/$1/wp-login.php" ]
then
        echo "Valid Wordpress Instance Found, locking..."      
        chown -R root:root $SRV/$1/* 
else 
        echo "No valid wordpress instance found. Exiting ..."
        exit
fi 
