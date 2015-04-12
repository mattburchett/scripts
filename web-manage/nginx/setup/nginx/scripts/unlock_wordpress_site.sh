#!/bin/sh

## unlock_wordpress_site.sh
##
## Usage: cd /var/www/domains/test.com/www/htdocs && ~/unlock_wordpress_site.sh
##
## This unlocks a wordpress site by chowning everything to apache:apache
## Notes:
##  - make sure you are cd'd into the correct directory prior to running this script
##  - this script will check for certain files that should be in place in the working directory
##     else it will exit and not change anything


WORKINGDIR=$(pwd)
FILECHECK="wp-login.php"
BASEDIR=$(basename "$WORKINGDIR")
GROUPNAME="wp"
VHOSTNAME="/etc/httpd/vhosts.d/includes/HOST_NAME.DOMAIN_NAME.conf"

if [ -f wp-login.php ];
then
    if [[ "$WORKINGDIR" =~ "/var/www/domains" && ( "$BASEDIR" == "htdocs"  ||  "$BASEDIR" == "current"  ||  "$BASEDIR" =~ "wordpress*" ) ]];
        then
                echo "$FILECHECK file exists, proceeding to grant full permissions to apache"
                chown -R apache."$GROUPNAME" .
                find . -type f -exec chmod 0664 {} \;
                find . -type d -exec chmod 0775 {} \;
                
                sed -i 's/Include/#Include/g' $VHOSTNAME
                echo -e "Changes made, Reloading Apache to read in the updated configuration\n"
                service httpd reload
                if [ $? == 0 ]; then
                    echo "Apache Reload Successful.  The Instance is now insecure and ready for modification."
                    logger -p user.info -t WORDPRESS "Permissions for Wordpress Site at $WORKINGDIR Unlocked and Opened Up by $USER"
                    exit 0
                else
                    echo "Apache Reload FAILED.  You may have to apply changes manually."
                    logger -p user.info -t WORDPRESS "Permissions for Wordpress Site at $WORKINGDIR FAILED to Unlock and Open Due to Apache Reload Fail, by $USER"
                    exit 1 
                fi
        else
                echo "###############################################################"
                echo "#                   Directory check failed!                   #"
                echo "###############################################################"
                echo "Your base directory is not htdocs, current, or wordpress*"
                echo "Or you're not in /var/www/domains/*"
                echo -e "\nWorking Directory: $WORKINGDIR \n"
                echo -e "\nBase Directory: $BASEDIR \n"
                echo "Are you sure you're in the correct directory?"
                logger -p user.err -t WORDPRESS "Permissions for Wordpress Site at $WORKINGDIR FAILED to be Removed by $USER - Bad Current Directory"
                exit 1
        fi
else
    echo "###############################################################"
    echo "#                   Directory check failed!                   #"
    echo "###############################################################"
    echo "The $FILECHECK file does not exist in the current working directory:"
    echo -e "\n $WORKINGDIR \n"
    echo "Are you sure you're in the correct directory?"
    logger -p user.err -t WORDPRESS "Permissions for Wordpress Site at $WORKINGDIR FAILED to be Removed by $USER - Bad Current Directory, no $FILECHECK"
    exit 1
fi
