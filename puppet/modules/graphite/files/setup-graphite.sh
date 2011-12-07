#!/bin/bash

# download everything for graphite
installLog=$PWD/install.log
sudo rm -rf graphite
mkdir -p graphite
installLog=$PWD/install.log
cd graphite/
downloaddir=$PWD

graphiteTar="graphite-web-0.9.9"
carbonTar="carbon-0.9.9"
whisperTar="whisper-0.9.9"

echo "Downloading ${carbonTar}.tar.gz, ${graphiteTar}.tar.gz, ${whisperTar}.tar.gz" | tee $installLog
wget -N "http://launchpad.net/graphite/0.9/0.9.9/+download/${carbonTar}.tar.gz" >> $installLog 2>&1
wget -N "http://launchpad.net/graphite/0.9/0.9.9/+download/${graphiteTar}.tar.gz" >> $installLog 2>&1
wget -N "http://launchpad.net/graphite/0.9/0.9.9/+download/${whisperTar}.tar.gz" >> $installLog 2>&1


echo "easy_install not installed. Using alternative method to install packages" | tee -a $installLog
echo "Extracting download files" | tee -a $installLog
tar xfz ${carbonTar}.tar.gz >> $installLog 2>&1
tar xfz ${graphiteTar}.tar.gz >> $installLog 2>&1
tar xfz ${whisperTar}.tar.gz >> $installLog 2>&1

# install whisper - Graphite's DB system
echo "Install wisper" | tee -a $installLog
cd $downloaddir/${whisperTar}
sudo python setup.py install >> $installLog 2>&1
# install carbon - the Graphite back-end
echo "Install carbon" | tee -a $installLog
cd $downloaddir/${carbonTar}
sudo python setup.py install >> $installLog 2>&1

echo "Create carbon and storage config" | tee -a $installLog
sudo cp /opt/graphite/conf/carbon.conf.example /opt/graphite/conf/carbon.conf
# copy the example schema configuration file, and then configure the schema
# see: http://graphite.wikidot.com/getting-your-data-into-graphite
sudo cp /opt/graphite/conf/storage-schemas.conf.example /opt/graphite/conf/storage-schemas.conf

# install other graphite dependencies
echo -e "Installing Debian packages if not already installed:
\t- apache2
\t- libapache2-mod-python
\t- memcached
\t- python-cairo
\t- python-django
\t- python-ldap
\t- python-twisted 
\t- python-memcache" | tee -a $installLog

sudo apt-get --yes --force-yes install python-cairo python-django memcached python-memcache \
python-ldap python-twisted apache2 libapache2-mod-python >> $installLog 2>&1

# install graphite - Graphite web interface
echo "Install graphite-web" | tee -a $installLog
cd $downloaddir/${graphiteTar}
sudo python setup.py install >> $installLog 2>&1

# copy the graphite vhost example to available sites, edit it to you satisfaction, then link it from sites-enabled
echo "Extracting vhost example configuration" | tee -a $installLog
tar xfz $downloaddir/${graphiteTar}.tar.gz ${graphiteTar}/examples/example-graphite-vhost.conf >> $installLog 2>&1

echo "Copy vhost to Apache2 sites-available (graphite.conf) and create symlink to site-enabled" | tee -a $installLog
sudo cp $downloaddir/${graphiteTar}/examples/example-graphite-vhost.conf /etc/apache2/sites-available/graphite.conf >> $installLog 2>&1
sudo ln -s /etc/apache2/sites-available/graphite.conf /etc/apache2/sites-enabled/graphite.conf >> $installLog 2>&1

echo "Restarting Apache to enable graphite-web" | tee -a $installLog
sudo apache2ctl restart >> $installLog 2>&1

echo "Initial django database tables import" | tee -a $installLog
cd /opt/graphite/webapp/graphite
sudo python manage.py syncdb >> $installLog 2>&1
echo "Change owner/group of /opt/graphite/storage/ to www-data" | tee -a $installLog
sudo chown -R www-data:www-data /opt/graphite/storage/ >> $installLog 2>&1

# copy the local_settings example file to creating the app's settings
# this is where both carbon federation and authentication is configured
echo "Copy the local_settings example file to creating the app's settings" | tee -a $installLog
sudo cp local_settings.py.example local_settings.py >> $installLog 2>&1

#todo: Add note about config files and start of carbon
# - sudo /opt/graphite/bin/carbon-cache.py start
# - confs: local_settings (web application), carbon and storage configs
