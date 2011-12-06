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

class java {}

class java::jdk16 inherits java {
	exec { 
		"get jdk source":
			command => "wget -c http://download.oracle.com/otn-pub/java/jdk/6u29-b11/jdk-6u29-linux-x64-rpm.bin -O jdk-6u29-linux-x64-rpm.bin",
			cwd => "/opt",
			creates => "/opt/jdk-6u29-linux-x64-rpm.bin";
		"install jdk":
			command => "/bin/bash /opt/jdk-6u29-linux-x64-rpm.bin",
			cwd => "/opt",
			creates => "/usr/java/default/bin/java",
			require => Exec["get jdk source"];
	}

	file {
		"/etc/profile.d/jdk.sh":
			owner => root,
			group => root,
			mode => 644,
			ensure => present,
			source => "puppet://${puppetserver}/java/etc/profile.d/jdk.sh",
			require => Exec["install jdk"];
		## Includes the special CA
		"cacerts_jdk":
			owner => root,
			group => root,
			mode => 644,
			path => "/usr/java/default/jre/lib/security/cacerts",
			source => [
				"puppet://${puppetserver}/java/security/cacerts_${fqdn}",
				"puppet://${puppetserver}/java/security/cacerts_${domain}",
				"puppet://${puppetserver}/java/security/cacerts",
			],
			require => Exec["install jdk"];
	}
}
