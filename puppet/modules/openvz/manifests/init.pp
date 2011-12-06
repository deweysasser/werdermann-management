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

class openvz { }

class openvz::getTemplateCentOS64 { 
	exec {
		"get CentOS5 64 template":
			command => "wget -c http://download.openvz.org/template/precreated/centos-5-x86_64.tar.gz",
			cwd => "/vz/template/cache/",
			require => [Package["ovzkernel"],Package["vzctl"]],
			creates => "/vz/template/cache/centos-5-x86_64.tar.gz";
	}
}

class openvz::getTemplateDebian64 { 
	exec {
		"get Debian6 64 template":
			command => "wget -c http://download.openvz.org/template/precreated/debian-6.0-x86_64.tar.gz",
			cwd => "/vz/template/cache/",
			require => [Package["ovzkernel"],Package["vzctl"]],
			creates => "/vz/template/cache/debian-6.0-x86_64.tar.gz";
	}
}

class openvz::server inherits openvz {
	# OpenVZ installation according to http://wiki.openvz.org/Quick_installation
	file {
		"/etc/yum.repos.d/openvz.repo":
			mode => 0644,
			owner => root,
			group => root,
			source => "puppet://${puppetserver}/openvz/etc/yum.repos.d/openvz.repo",
			ensure => present,
	}
	exec {
		"import_openvz_repo_key":
			command => "rpm --import  http://download.openvz.org/RPM-GPG-Key-OpenVZ",
			subscribe => File["/etc/yum.repos.d/openvz.repo"],
			refreshonly => true
	}
	package {
		"ovzkernel":
			name => "ovzkernel.x86_64",
			ensure => installed,
			require => File["/etc/yum.repos.d/openvz.repo"];
		"vzctl":
			name => "vzctl.x86_64",
			ensure => installed,
			require => [ File["/etc/yum.repos.d/openvz.repo"], Package["ovzkernel"] ];
		"vzquota":
			name => "vzquota.x86_64",
			ensure => installed,
			require => [ File["/etc/yum.repos.d/openvz.repo"], Package["ovzkernel"] ];
	}
	file {
	# special tuning for ovz
		"/etc/vz/vz.conf":
			mode => 0644,
			owner => root,
			group => root,
			source => "puppet://${puppetserver}/openvz/etc/vz/vz.conf",
			ensure => present,
			require => Package["vzctl"];
	# kernel tuning for ovz
		"/etc/sysctl.conf":
			mode => 0644,
			owner => root,
			group => root,
			source => "puppet://${puppetserver}/openvz/etc/sysctl.conf",
			ensure => present;
	# deactivate SELinux
		"/etc/sysconfig/selinux":
			mode => 0644,
			owner => root,
			group => root,
			source => "puppet://${puppetserver}/openvz/etc/sysconfig/selinux",
			ensure => present;
	}
## TODO: this lines need the common module
#	append_if_no_such_line { "add module nfs":
#		file => "/etc/rc.d/rc.local",
#		line => "modprobe nfs"
#	}

	# stop unneeded services
	$stopped_services = $operatingsystem ? {
		"CentOS" => ["cups", "cpuspeed", "nfslock", "dsm_om_shrsvc", "dsm_om_connsvc", "auditd"],
		default => []
	}
	service {
		$stopped_services:
			enable => false,
			hasstatus => true,
			ensure => stopped;
	}

	# run ovz environment at boot
	service {
		"vz":
			enable => true,
			hasstatus => true,
			ensure => running,
			require => Package["vzctl"];
	}
}

