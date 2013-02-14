#!/bin/bash

echo "Ensure that you are running this script as root."
echo "This script will rename the link /var/www/projects.spartanshops.com.oldlink"
echo "to /var/www/projects.spartanshops.com."
echo "-----"
ls -l /var/www/projects.spartanshops.com.oldlink
echo "-----"
echo "Ensure that the .oldlink above is pointing to the revision that you wish to rollback to."
read -p "Hit [ENTER] to continue running this script, or ^C to abort it."

service apache2 stop
service mysql stop

pushd /var/www
      rm -rf projects.spartanshops.com
      mv projects.spartanshops.com.oldlink projects.spartanshops.com
      chown -R www-data.root projects.spartanshops.com
popd

service mysql start
service apache2 start

echo "Warm up passenger"
wget localhost --no-check-certificate -O /tmp/index
