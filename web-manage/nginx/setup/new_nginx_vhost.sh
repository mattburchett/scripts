#!/bin/sh


## Title: new_nginx_vhost.sh
## Description: Deploy a new nginx vhost in the "Contegix" way, covers SSL vhosts as well
## Authors: Bradley McCrorey (initial script, in 2012)  
##          Kevin Dreyer ( update of script, altered deployment method and provided more structure to the deployment, created custom templates for use by script ) 
##          Matt Burchett ( nginx modifications )
## Version: 0.1
##
## Usage:
# export FQDN=www.domain.com USESSL=Y/N INTERFACE=eth0/eth1; svn cat --username=your.username --no-auth-cache https://jira.com/svn/NSAK/trunk/toolbox/common/bin/new_nginx_vhost.sh | bash

echo -e "FQDN: $FQDN"
echo -e "USESSL: $USESSL"
echo -e "NET: $INTERFACE\n"


# Check to see if they set FQDN, if not ask for user input
if [ -z "$FQDN" ]; then
    echo -e "No FQDN variable set.  Please enter the FQDN (e.g. www.example.com), followed by [ENTER]:"
    read FQDN
fi

# Check to see if they set SSL, if not ask for user input
if [ -z "$USESSL" ]; then
    echo -e "No SSL variable set.  Do you want an SSL enabled vhost? Please enter Y or N, followed by [ENTER]:"
    read USESSL
fi

# Check to see if they set an interface, if not ask for user input
if [ -z "$INTERFACE" ]; then
    echo -e "No interface set.  Please enter the interface name (e.g. eth0, eth1, eth1:3), followed by [ENTER]:"
    read INTERFACE
fi

# Strip the FQDN down to its basic parts
set -- $(echo $FQDN |awk -F\. '{print $1,$2,$3}')
HOST_NAME=$1
DOMAIN_NAME="$2.$3"


# Extract the IP address out of ifconfig.
IPADDR=$(ifconfig $INTERFACE  | grep 'inet addr:'| grep -v '127.0.0.1' | cut -d: -f2 | awk '{ print $1}'  |tr -d '\n')

# Just in case, create directory structure
mkdir -p /etc/nginx/vhosts.d/includes/

# Do the thang.
cd /etc/nginx/vhosts.d

# Configure port 80 loader
cat /etc/nginx/templates.d/vhosts.d/vhost-template.conf | \
sed "s/IP_ADDRESS/${IPADDR}/g;s/DOMAIN_NAME/${DOMAIN_NAME}/g;s/HOST_NAME/${HOST_NAME}/g" \
> /etc/nginx/vhosts.d/${HOST_NAME}.${DOMAIN_NAME}.conf

# Configure port 443 loader
cat /etc/nginx/templates.d/vhosts.d/vhost-template-ssl.conf | \
sed "s/IP_ADDRESS/${IPADDR}/g;s/DOMAIN_NAME/${DOMAIN_NAME}/g;s/HOST_NAME/${HOST_NAME}/g" \
> /etc/nginx/vhosts.d/${HOST_NAME}.${DOMAIN_NAME}-ssl.conf

# Configure Main vhost
cat /etc/nginx/templates.d/vhosts.d/includes/vhost-template.conf | \
sed "s/IP_ADDRESS/${IPADDR}/g;s/DOMAIN_NAME/${DOMAIN_NAME}/g;s/HOST_NAME/${HOST_NAME}/g" \
> /etc/nginx/vhosts.d/includes/${HOST_NAME}.${DOMAIN_NAME}.conf


# create the dir structure under /var/www
mkdir -p /var/www/domains/${DOMAIN_NAME}/${HOST_NAME}/{htdocs,logs,cgi-bin,ssl}

if [ "$USESSL" = "Y" ] || [ "$USESSL" = "y" ] || [ "$USESSL" = "yes" ] || [ "$USESSL" = "Yes" ] || [ "$USESSL" = "YES" ]; then
    export USESSL="Y"
    echo -e "**************WITHSSL****************** \n"
    echo -e "The basic vhost is configured, you will still need to create/upload a SSL cert, then fix the appropriate lines in \n"
    echo -e "/etc/nginx/vhosts.d/${HOST_NAME}.${DOMAIN_NAME}-ssl.conf \n "
    echo -e "The nginx -t that will run in a moment will likely fail until this is completed.\n \n"
else
    echo -e "--------------NOSSL------------------- \n"
    echo -e "SSL will not be in use.  Disabling the SSL config file.\n"
    echo -e "The port 443 loader has been renamed to *.OFF, simply rename to *.conf and kick nginx to re-enable\n"
    mv /etc/nginx/vhosts.d/${HOST_NAME}.${DOMAIN_NAME}-ssl.conf{,.OFF}
fi


# Notify user what is expected now

if [ "$USESSL" = "Y" ]; then
    echo -e "**************WITHSSL****************** \n"
    echo -e "Now we will test the nginx configuration as-is.   If you are using SSL but don't have the SSL certs in place yet, \n"
    echo -e "This test will likely fail citing that as the reason.  You can solve that by creating/uploading the SSL certs to the proper spot\n"
    echo -e "Then ensuring the ssl vhost config points to those certs, then finally you can run the command again to test the config. \n"
    echo -e "/usr/sbin/nginx -t \n"
else
    echo -e "--------------NOSSL-------------------- \n"
    echo "Now we will test the nginx configuration as-is.  Since you are not utilizing SSL, it should result with no errors.\n"
fi

# check the nginx config
/usr/sbin/nginx -t 2>&1 && echo -e "\n nginx config looks good. restart nginx when ready.\n"


## EOF
