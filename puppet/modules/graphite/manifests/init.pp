# --------------------------------------------------------------------
# **** BEGIN LICENSE BLOCK *****
#
# Version: MPL 1.1
#
# The contents of this file are subject to the Mozilla Public License Version
# 1.1 (the "License"); you may not use this file except in compliance with
# the License. You may obtain a copy of the License at
# http://www.mozilla.org/MPL/
#
# Software distributed under the License is distributed on an "AS IS" basis,
# WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
# for the specific language governing rights and limitations under the
# License.
#
# The Original Code is echocat management.
#
# The Initial Developer of the Original Code is Daniel Werdermann.
# Portions created by the Initial Developer are Copyright (C) 2011
# the Initial Developer. All Rights Reserved.
#
# **** END LICENSE BLOCK *****
# --------------------------------------------------------------------

# INFO: This module is written for Debian/Ubuntu. At this point
# it is a standalone with own Apache. Sould be seperated in the future.


## TODO: Split graphite in carbon, whisper and webapp classes

class graphite { }

class graphite::all inherits graphite {

	# for full functionality we need this packages:
	# madatory: python-cairo, python-django, python-twisted, python-django-tagging, python-simplejson
	# optinal: python-ldap, python-memcache, memcached, python-sqlite

	$graphitpkgs = ["python-cairo","python-twisted","python-django","python-django-tagging","python-ldap","python-memcache","python-sqlite","python-simplejson"]

	package { $graphitpkgs: ensure => installed }

# Todo: outsource apache to seperate module
#	# we need an apache with python support
#	# the vhost fiel is stored in apache module
#
#	include apache::python
	package {
		"apache2": ensure => installed;
		"libapache2-mod-python": ensure => installed;
	}

	service {
		"apache2":
			hasrestart => true,
			hasstatus => true,
			ensure => running,
			enable => true,
			require => Exec["Chown graphit for apache"];
	}

	# variables

	# this will set the servername in vhost file
	$graphitehost = $fqdn

	$graphiteVersion = "graphite-web-0.9.9"
	$carbonVersion = "carbon-0.9.9"
	$whisperVersion = "whisper-0.9.9"

	# Download graphite sources

	exec {
		"Download and untar $graphiteVersion":
			command => "wget -O - http://launchpad.net/graphite/0.9/0.9.9/+download/${graphiteVersion}.tar.gz | tar xz",
			creates => "/usr/local/src/$graphiteVersion",
			cwd => "/usr/local/src";
		"Download and untar $carbonVersion":
			command => "wget -O - http://launchpad.net/graphite/0.9/0.9.9/+download/${carbonVersion}.tar.gz | tar xz",
			creates => "/usr/local/src/$carbonVersion",
			cwd => "/usr/local/src";
		"Download and untar $whisperVersion":
			command => "wget -O - http://launchpad.net/graphite/0.9/0.9.9/+download/${whisperVersion}.tar.gz | tar xz",
			creates => "/usr/local/src/$whisperVersion",
			cwd => "/usr/local/src";
	}

	# Install graphite from source

	exec {
		"Install $graphiteVersion":
			command => "python setup.py install",
			cwd => "/usr/local/src/$graphiteVersion",
			subscribe => Exec["Download and untar $graphiteVersion"],
			refreshonly => true,
			require => [Exec["Download and untar $graphiteVersion"],Package["python-cairo"]];
		"Install $carbonVersion":
			command => "python setup.py install",
			cwd => "/usr/local/src/$carbonVersion",
			subscribe => Exec["Download and untar $carbonVersion"],
			refreshonly => true,
			require => [Exec["Download and untar $carbonVersion"],Package["python-twisted"]];
		"Install $whisperVersion":
			command => "python setup.py install",
			cwd => "/usr/local/src/$whisperVersion",
			subscribe => Exec["Download and untar $whisperVersion"],
			refreshonly => true,
			require => [Exec["Download and untar $whisperVersion"],Package["python-twisted"]];
	}

	# initialize database

	# Because the django isntall of debian sucks we have to 
	# create our own symlinks to python lib dir.
	# you find your lib dir wiht: 
	#   python -c "from distutils.sysconfig import get_python_lib; print get_python_lib()";
	file {
		"/usr/lib/python2.6/dist-packages/django":
			ensure => link,
			target => "/usr/lib/pymodules/python2.6/django",
			require => Package["python-django"];
	}

	exec {
		"Initial django db creation":
			command => "python manage.py syncdb",
			cwd => "/opt/graphite/webapp/graphite",
			require => [Exec["Install $graphiteVersion","Install $carbonVersion","Install $whisperVersion"],File["/usr/lib/python2.6/dist-packages/django"]],
			refreshonly => true,
			subscribe => [Exec["Install $graphiteVersion"],Package["python-django-tagging"]];
	}

	# change access permitions for apache

	exec {
		"Chown graphit for apache":
			command => "chown -R www-data:www-data /opt/graphite/storage/",
			cwd => "/opt/graphite/";
	}

	# Deploy configfiles

	file {
		"/opt/graphite/webapp/graphite/local_settings.py":
			mode => 644,
			owner => "www-data",
			group => "www-data",
			content => template("graphite/opt/graphite/webapp/graphite/local_settings.py.erb");
		"/etc/apache2/sites-available/graphite.conf":
			mode => 644,
			owner => "www-data",
			group => "www-data",
			content => template("graphite/etc/apache2/sites-available/graphite.conf.erb"),
			require => [Package["apache2"],Exec["Initial django db creation"]],
			notify => Service["apache2"];
		"/etc/apache2/sites-enabled/graphite.conf":
			ensure => link,
			target => "/etc/apache2/sites-available/graphite.conf",
			require => File["/etc/apache2/sites-available/graphite.conf"];
	}

	# configure carbon engine

	file {
		"/opt/graphite/conf/storage-schemas.conf":
			mode => 644,
			content => template("graphite/opt/graphite/conf/storage-schemas.conf.erb"),
			require => Exec["Install $carbonVersion"],
			notify => Exec["restart carbon engine"];
		"/opt/graphite/conf/carbon.conf":
			mode => 644,
			content => template("graphite/opt/graphite/conf/carbon.conf.erb"),
			require => Exec["Install $carbonVersion"],
			notify => Exec["restart carbon engine"];
	}

	# startup carbon engine

	service {
		"carbon-cache.py":
			path => "/opt/graphite/bin/",
			hasstatus => true,
			hasrestart => false,
			ensure => running,
			require => File["/opt/graphite/conf/storage-shema.conf"];
	}

	exec {
		"restart carbon engine":
			command => "python /opt/graphite/bin/carbon-cache.py stop && python /opt/graphite/bin/carbon-cache.py start",
			refreshonly => true;
	}
	
}

