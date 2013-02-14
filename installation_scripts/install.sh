#!/bin/bash

service apache2 stop
service mysql stop

pushd /var/www
      NEWNAME=projects.spartanshops.com.$(date +%Y%b%d.%s)

      git clone https://github.com/mikeyin/teambox.git $NEWNAME
      mv projects.spartanshops.com projects.spartanshops.com.oldlink
      rm -rf projects.spartanshops.com
      ln -s $NEWNAME projects.spartanshops.com
      
      pushd $NEWNAME
      	    git checkout master
	    echo "Linking configurations"
	    ln -s /etc/teambox/teambox.yml config/teambox.yml
	    ln -s /etc/teambox/database.yml config/database.yml
	    bundle install --path .bundle
      popd
      chown -R www-data.root $NEWNAME
popd

service mysql start
service apache2 start

echo "Warming up passenger"
wget localhost --no-check-certificate -O /tmp/index
