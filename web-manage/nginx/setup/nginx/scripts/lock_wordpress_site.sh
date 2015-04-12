#!/bin/sh

## lock_wordpress_site.sh
##
## Usage: cd /var/www/domains/test.com/www/htdocs && ~/lock_wordpress_site.sh
##
## This locks a wordpress site by chowning everything to root:root and chowns wp-content apache:apache
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
                echo "$FILECHECK file exists, proceeding to lock permissions from apache"
                chown -R root:"$GROUPNAME" .
                chown -R apache:"$GROUPNAME" wp-content
                chown -R root:"$GROUPNAME" wp-content/plugins
                find . -type f -exec chmod 0664 {} \;
                find . -type d -exec chmod 0775 {} \;
                find . -name wp-config.php -exec chmod 0644 {} \;
                find . -name readme.html -exec chmod 0400 {} \;

                # Wordpress Plugin-specific Mods.  Any specific permissions for plugins put in this portion
                if [[ -d "$WORKINGDIR/wp-content/plugins/gallery-bank" ]];
                then
                    chown -R apache:"$GROUPNAME" "$WORKINGDIR/wp-content/plugins/gallery-bank/lib/cache"
                fi
                if [[ -d "$WORKINGDIR/wp-content/plugins/wp-security-scan" ]];
                then
                    echo -e "WP Security Scan Plugin Installed, Fixing Backups Perms\n"
                    chown -R apache:"$GROUPNAME" "$WORKINGDIR/wp-content/plugins/wp-security-scan/res/backups"
                fi 

                # Fix Apache vhost
                echo -e "Lockdown of Permissions complete, moving on to fixing the apache vhost, re-applying protective rewrites\n"
                sed -i 's/#Include/Include/g' $VHOSTNAME

                echo -e "Changes made, Reloading Apache to read in the updated configuration\n"
                service httpd reload
                if [ $? == 0 ]; then 
                    echo -e "Apache reload successful, Permissions are now fixed and locked down.\n"
                    logger -p user.info -t WORDPRESS "Permissions for Wordpress Site at $WORKINGDIR Fixed and Locked Back Down by $USER"
                    exit 0
                else 
                    apachectl -t
                    echo -e "\n Apache Reload FAILED.  You may have to apply changes manually.\n"
                    logger -p user.info -t WORDPRESS "Permissions for Wordpress Site at $WORKINGDIR FAILED to Revert due ot Apache Reload Fail, by $USER"
                    exit 1
                fi
        else
                echo "###############################################################"
                echo "#                   Directory check failed!                   #"
                echo "###############################################################"
                echo "Your base directory is not htdocs, current, or wordpress*"
                echo "Or you're not in /var/www/domains/*"
                echo -e "\n $WORKINGDIR \n"
                echo "Are you sure you're in the correct directory?"
                logger -p user.err -t WORDPRESS "Permissions for Wordpress Site at $WORKINGDIR FAILED to be Fixed by $USER, Perms still OPEN - Bad Current Directory"
                exit 1
        fi
else
    echo "###############################################################"
    echo "#                   Directory check failed!                   #"
    echo "###############################################################"
    echo "The $FILECHECK file does not exist in the current working directory:"
    echo -e "\n $WORKINGDIR \n"
    echo "Are you sure you're in the correct directory?"
    logger -p user.err -t WORDPRESS "Permissions for Wordpress Site at $WORKINGDIR FAILED to be Fixed by $USER, Perms still OPEN - Bad Current Directory, no $FILECHECK"
    exit 1
fi
