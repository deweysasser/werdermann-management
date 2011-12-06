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

class tomcat($tcversion=7, $tcmysql=present) {
	tcuser = "tomcat"
	tcgroup = "tomcat"
	tcpath = "/opt/tomcat"

        group {
                "$tcgroup":
                        ensure => present
        }

        user {
                "$tcuser":
                        ensure => present,
                        gid => "$tcgroup",
                        managehome => true,
                        home => "$tcpath",
                        shell => "/bin/bash",
                        require => Group["$tcgroup"]
        }

	service {
		"tomcat":
			hasrestart => true,
			hasstatus => false,
			ensure => running,
			enable => true,
			require => File["/etc/init.d/tomcat"];
	}

	exec {
		"download tomcat ${tcversion}":
			command => $tcversion ? {
					6 => "curl http://apache.lauf-forum.at/tomcat/tomcat-6/v6.0.33/bin/apache-tomcat-6.0.33.tar.gz | tar xz",
					7 => "curl http://mirror.checkdomain.de/apache/tomcat/tomcat-7/v7.0.22/bin/apache-tomcat-7.0.22.tar.gz | tar xz"
				},
			cwd => "/opt",
			creates =>  $tcversion ? {
					6 => "/opt/apache-tomcat-6.0.33",
					7 => "/opt/apache-tomcat-7.0.22"
				};
		"chown tomcat dir":
			command => "chown -R ${tcuser}.${tcgroup} $tcpath",
			require => [File["$tcpath"],User["$tcuser"]];
	}
	file {
		"$tcpath":
			ensure => link,
			target =>  $tcversion ? {
					6 => "/opt/apache-tomcat-6.0.33",
					7 => "/opt/apache-tomcat-7.0.22"
				},
			require => Exec["download tomcat ${tcversion}"];
		"/opt/tomcat/lib/mysql-connector-java-5.1.18-bin.jar":
			ensure => $tcmysql ? {
					present => present,
					default => absent
				},
			source => "puppet://${puppetserver}/tomcat/mysql-connector-java-5.1.18-bin.jar",
			mode => 644,
			owner => tomcat,
			group => services,
			require => File["$tcpath"];
		"/etc/init.d/tomcat":
			ensure => present,
			content => template("/tomcat/etc/init.d/tomcat.erb"),
			owner => root,
			group => root,
			mode => 755,
			require => File["$tcpath"];
	}

	# so most tomcat apps seems to need many filehandles

	line {
		"set ulimits nofile 6144 for $tcuser":
			file => "/etc/security/limits.conf",
			line => "$tcuser		-	nofile		6144",
			ensure => present,
			require => User["$tcuser"];
	}

}

