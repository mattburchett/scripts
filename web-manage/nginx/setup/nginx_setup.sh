#!/bin/sh


## Title: nginx_setup.sh
## Description: Deploy base nginx configurations
## Authors: Matt Burchett (2015-03-28)
## Version: 0.6
##

# I've placed all the installation in a function called "redhat" just in case this gets developed for compatiblity with another distribution.
function redhatlinux {

    #checking if epel repo is installed and enabled

if [ -z "`yum repolist | grep epel`" ]; then
    echo "EPEL repo not installed, would you like to install it now? (y/N)"
    read epelinstall
    if [ "$epelinstall" = "y" ]; then
        cd /tmp
        echo "Downloading epel package."
        wget http://mirror.pnl.gov/epel/6/i386/epel-release-6-8.noarch.rpm 
        echo "Installing Package."
        yum localinstall epel-release-6-8.noarch.rpm
        cd
    else
        echo "EPEL has to be enabled to install and setup nginx. Exiting."
        exit
    fi
else
    echo "EPEL repo enabled. All good!"
fi

echo
sleep 1

#checking if nginx is installed

if [ -z "`rpm -qi nginx | grep URL`" ]; then
    echo "nginx is not installed. Would you like to install it now? (y/N)"
    read nginxinstall
    if [ "$nginxinstall" = "y" ]; then
        echo "Okay, installing nginx."
        yum install nginx php-fpm
        echo "Nginx installed. Enabling services by default."
        chkconfig nginx on
        chkconfig php-fpm on
        echo "Services enabled."
    else
        echo "Wrong answer given. Exiting."
        exit
    fi
else 
    echo "nginx is already installed, moving on."
fi

    #start PHP-FPM configuration

echo "Starting php-fpm configuration..."

echo

# change how it listens
echo "Changing php-fpm to listen on socket (unix:/var/run/php5-fpm.sock)..."

sed -i 's,listen = 127.0.0.1:9000, listen = /var/run/php5-fpm.sock,g' /etc/php-fpm.d/www.conf

if [ "`cat /etc/php-fpm.d/www.conf | grep 'var/run/php5-fpm.sock'`" ]; then
   echo "Change successfully made."
   cat /etc/php-fpm.d/www.conf | grep 'var/run/php5-fpm.sock'
   
else
   echo "Change not made. Please edit the file manually and change listen = 127.0.0.1:9000 to listen = /var/run/php5-fpm.sock."
fi

echo 
sleep 1

# change who it listens as
echo "Changing listen.owner to = apache..."

sed -i 's:;listen.owner = nobody:listen.owner = apache:g' /etc/php-fpm.d/www.conf

if [ "`cat /etc/php-fpm.d/www.conf | grep 'listen.owner = apache'`" ]; then
   echo "Change successfully made."
   cat /etc/php-fpm.d/www.conf | grep 'listen.owner = apache'

else
   echo "Change not made. Please edit the file manually and uncomment listen.owner and set it's ownership to apache."
fi

echo 
sleep 1

# group too
echo "Changing listen.group to = apache..."

sed -i 's:;listen.group = nobody:listen.group = apache:g' /etc/php-fpm.d/www.conf

if [ "`cat /etc/php-fpm.d/www.conf | grep 'listen.group = apache'`" ]; then
   echo "Change successfully made."
   cat /etc/php-fpm.d/www.conf | grep 'listen.group = apache'

else
   echo "Change not made. Please edit the file manually and uncomment listen.group and set it's ownership to apache."
fi

echo
sleep 1

echo "Configuration of php-fpm complete."
#end php-fpm configuration
}

function tuning {

echo "Creating $FILE ..."

cat << EOF > $FILE
server_names_hash_bucket_size 64;
EOF

if [ -f $FILE ]; then
    echo "$FILE created."
else
    echo "Creation of $FILE failed, please create manually."
fi

}

function vhosts {

echo "Creating $FILE ..." 

cat << EOF > $FILE
include /etc/nginx/vhosts.d/*.conf;
EOF

if [ -f $FILE ]; then
    echo "$FILE created."
else
    echo "Creation of $FILE failed, please create manually."
fi

}

function restrictions {

echo "Creating $FILE..." 

cat << EOF > $FILE
location = /favicon.ico {
    log_not_found off;
    access_log off;
}
location = /robots.txt {
    allow all;
    log_not_found off;
    access_log off;
}
location ~ /\. {
    deny all;
}
location ~* /(?:uploads|files)/.*\.php$ {
 
    deny all;
}
EOF

if [ -f $FILE ];then
    echo "$FILE created."
else
    echo "Creation of $FILE failed, please create manually."
fi

}

function wordpress {

echo "Creating $FILE..."

cat << EOF > $FILE
# Add trailing slash to */wp-admin requests.
 
rewrite /wp-admin\$ \$scheme://\$host\$uri/ permanent;
 
location ~* ^.+\.(ogg|ogv|svg|svgz|eot|otf|woff|mp4|ttf|rss|atom|jpg|jpeg|gif|png|ico|zip|tgz|gz|rar|bz2|doc|xls|exe|ppt|tar|mid|midi|wav|bmp|rtf)\$ {
 
       access_log off; log_not_found off; expires max;
 
}
EOF

if [ -f $FILE ];then
    echo "$FILE created."
else
    echo "Creation of $FILE failed, please create manually."
fi

}

#end functions

#this bit is bad, but valid for now to make sure we don't screw up another OS
if [ -f "/etc/redhat-release" ]; then
    echo "RedHat (or variant) detected. Installing..."
    redhatlinux
else
    echo "Unsupported operating system, exiting..."
    # exit
fi

echo
sleep 1

echo "Copying configuration files in place..."

#make the directories needed
mkdir -p /etc/nginx/{conf.d,vhosts.d/includes,templates.d/conf.d,templates.d/vhosts.d/includes}

echo

#create the tuning.conf and creating templates

if [ -f /etc/nginx/conf.d/tuning.conf ]; then
    echo "Previous tuning.conf detected, not overwriting. Updating template..."
    FILE=/etc/nginx/templates.d/conf.d/tuning.conf
    tuning
else
    echo "No previous tuning.conf detected, creating and making template..."

    #/etc/nginx/conf.d/tuning.conf
    FILE=/etc/nginx/conf.d/tuning.conf
    tuning

    #/etc/nginx/templates.d/conf.d/tuning.conf
    FILE=/etc/nginx/templates.d/conf.d/tuning.conf
    tuning
fi

echo
sleep 1

#create the vhost conf and creating templates

if [ -f /etc/nginx/conf.d/vhosts.conf ]; then
    echo "Previous vhosts.conf detected, not overwriting. Updating template..."
    FILE=/etc/nginx/templates.d/conf.d/vhosts.conf
    vhosts
else
    echo "No previous vhosts.conf detected, creating and making template..."

    #/etc/nginx/conf.d/vhosts.conf
    FILE=/etc/nginx/conf.d/vhosts.conf
    vhosts

    #/etc/nginx/templates.d/conf.d/vhosts.conf
    FILE=/etc/nginx/templates.d/conf.d/vhosts.conf
    vhosts
fi

echo
sleep 1

# create includes/restrictions.conf and creating templates

if [ -f /etc/nginx/vhosts.d/includes/restrictions.conf ]; then
    echo "Previous restrictions detected, not overwriting. Updating template..."
    FILE=/etc/nginx/templates.d/vhosts.d/includes/restrictions.conf
    restrictions
else
    echo "No previous restrictions.conf detected, creating and making template..."

    #/etc/nginx/vhosts.d/includes/restrictions.conf
    FILE=/etc/nginx/vhosts.d/includes/restrictions.conf
    restrictions

    #/etc/nginx/templates.d/vhosts.d/includes/restrictions.conf
    FILE=/etc/nginx/templates.d/vhosts.d/includes/restrictions.conf
    restrictions
fi

echo
sleep 1

# create includes/wordpress.conf and creating templates
if [ -f /etc/nginx/vhosts.d/includes/wordpress.conf ]; then
    echo "Previous wordpress.conf detected, not overwriting. Updating template..."
    FILE=/etc/nginx/templates.d/vhosts.d/includes/wordpress.conf
    wordpress
else
    echo "No previous wordpress.conf detected, creating and making template..."

    #/etc/nginx/vhosts.d/includes/wordpress.conf
    FILE=/etc/nginx/vhosts.d/includes/wordpress.conf
    wordpress

    #/etc/nginx/templates.d/vhosts.d/includes/wordpress.conf
    FILE=/etc/nginx/templates.d/vhosts.d/includes/wordpress.conf
    wordpress
fi

echo
sleep 1

#start creation of the vhost templates
echo "Configuration of nginx complete. Creating template files..."

echo
sleep 1

#main vhost template (not include)
echo "Creating vhost-template.conf..."

cat << EOF > /etc/nginx/templates.d/vhosts.d/vhost-template.conf
        server {
                listen 80;
                server_name     HOST_NAME.DOMAIN_NAME;

                #To enable HTTPS, uncomment this line.
                #rewrite                ^(.*) https://\$server_name\$1 permanent;

                include /etc/nginx/vhosts.d/includes/HOST_NAME.DOMAIN_NAME.conf;

        }
EOF

if [ -f /etc/nginx/templates.d/vhosts.d/vhost-template.conf ];then
    echo "vhost-template.conf created."
else
    echo "Creation of vhost-template.conf failed, please create manually."
fi

echo
sleep 1

#ssl vhost template (not include)
echo "Creating vhost-template-ssl.conf..."

cat << EOF > /etc/nginx/templates.d/vhosts.d/vhost-template-ssl.conf
    server {
        listen 443 ssl;
        server_name     HOST_NAME.DOMAIN_NAME;
        
        ssl on;
        ssl_certificate /var/www/domains/DOMAIN_NAME/HOST_NAME/ssl/HOST_NAME.DOMAIN_NAME.crt;
        ssl_certificate_key /var/www/domains/DOMAIN_NAME/HOST_NAME/ssl/HOST_NAME.DOMAIN_NAME.key;
        ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
        ssl_prefer_server_ciphers on;
        ssl_ciphers "ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-SHA:ECDHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA256:DHE-RSA-AES128-SHA256:DHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA:ECDHE-RSA-DES-CBC3-SHA:EDH-RSA-DES-CBC3-SHA:AES256-GCM-SHA384:AES128-GCM-SHA256:AES256-SHA256:AES128-SHA256:AES256-SHA:AES128-SHA:DES-CBC3-SHA:HIGH:!aNULL:!eNULL:!EXPORT:!DES:!MD5:!PSK:!RC4";

        include /etc/nginx/vhosts.d/includes/HOST_NAME.DOMAIN_NAME.conf;
    }
EOF

if [ -f /etc/nginx/templates.d/vhosts.d/vhost-template-ssl.conf ];then
    echo "vhost-template-ssl.conf created."
else
    echo "Creation of vhost-template-ssl.conf failed, please create manually."
fi
echo
sleep 1

#main vhost template (include) (SSL too)
echo "Creating includes/vhost-template.conf..." 

cat << EOF > /etc/nginx/templates.d/vhosts.d/includes/vhost-template.conf
    root /var/www/domains/DOMAIN_NAME/HOST_NAME/htdocs;
    index index.html index.htm index.php;
    access_log      /var/www/domains/DOMAIN_NAME/HOST_NAME/logs/access_log;
    error_log       /var/www/domains/DOMAIN_NAME/HOST_NAME/logs/error_log;

    #custom maintenance message
    location @sorry502 {
       return 502 "This site is currently undergoing maintenance. We apologize for the inconvenience.";
    }

    location @sorry503 {
       return 503 "This site is currently undergoing maintenance. We apologize for the inconvenience.";
    }


    error_page  500 504 /50x.html;
    error_page 502 @sorry502;
    error_page 503 @sorry503;

    location = /50x.html {
    root /usr/share/nginx/html;
    }

    include /etc/nginx/vhosts.d/includes/restrictions.conf;
    #If this is a Wordpress vhost, uncomment this line
    #include /etc/nginx/vhosts.d/includes/wordpress.conf;

            
    location ~ \.php$ {
            try_files \$uri =404;
            fastcgi_pass unix:/var/run/php5-fpm.sock;
            fastcgi_index index.php;
            fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
            include fastcgi_params;
    }


    # These are placeholders until I figure out how to make them work specifically. 
    # ScriptAlias /cgi-bin "/var/www/domains/DOMAIN_NAME/HOST_NAME/cgi-bin"

    # <Directory "/var/www/domains/DOMAIN_NAME/HOST_NAME/cgi-bin">
    #      AllowOverride None
    #      Options None
    #      Order allow,deny
    #      Allow from all
    #  </Directory>


    ## If you will be installing any j2ee apps, e.g. Atlassian Jira, Confluence, Crowd, Fisheye, Bamboo, Stash, etc. you will need
    ## To uncomment the following Proxy* Lines and change appropriately.  
    ## If this is a plain vhost, say for wordpress, you can leave them commented out.
    ## Currently, nginx does not have support out-of-the-box for AJP connectors, nginx would have to be custom compiled for support. 
    ## HTTP connectors MUST be used.

    # location / {
    #     proxy_read_timeout 300;
    #     proxy_connect_timeout 300;
    #     proxy_redirect off;
          
    #     proxy_set_header    X-Forwarded-Proto \$scheme;
    #     proxy_set_header    Host          \$http_host;
    #     proxy_set_header    X-Real-IP     \$remote_addr;
            
    #     proxy_pass http://j2ee.HOST_NAME.DOMAIN_NAME:8009;
    # }


EOF

if [ -f /etc/nginx/templates.d/vhosts.d/includes/vhost-template.conf ];then
    echo "includes/vhost-template.conf created."
else
    echo "Creation of includes/vhost-template.conf failed, please create manually."
fi

echo

sleep 1

#Check for problems.
echo "Checking nginx for errors."
nginx -t

echo "nginx configuration complete."

echo

#exit
echo "Complete."
exit