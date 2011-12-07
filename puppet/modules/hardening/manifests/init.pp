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

class hardening {}

class hardening::all inherits hardening {
	include hardening::yum
	include hardening::disableInfrared
	include hardening::disableWireless
	include hardening::disableBluetooth
	include hardening::disableUnusedDeamons
}

class hardening::yum inherits hardening {

	# we do not want autoupdates
	# this maybe seems to be unlikely on "hardening"
	# but on servers I want to control which and at
	# what time updates are made. So the update
	# contorl should be realizes in a special
	# puppet module.

	package{ yum-updatesd: ensure => absent; }

#	service {
#		"yum-updatesd":
#			enable => false,
#			ensure => stopped,
#			hasstatus => true,
#			hasrestart => true;
#	}
}

class hardening::disableInfrared inherits hardening {

	package { irda-utils: ensure => absent }

}

class hardening::disableBluetooth inherits hardening {

	# erase bluetooth config tools

	package { bluez-utils: ensure => absent }

	# remove kernel drivers / need reboot
	exec {
		"delete bluetooth driver":
			command => "rm -rf /lib/modules/*/kernel/drivers/net/bluetooth/",
			onlyif => "test -d /lib/modules/$(uname -r)/kernel/drivers/bluetooth/";
	}
}

class hardening::disableWireless inherits hardening {

	# erase iwconfig tools

	package { wireless-tools: ensure => absent }

	# remove kernel drivers / need reboot
	exec {
		"delete wireless driver":
			command => "rm -rf /lib/modules/*/kernel/drivers/net/wireless/",
			onlyif => "test -d /lib/modules/`uname -r`/kernel/drivers/net/wireless/";
	}
}

class hardening::disableUnusedDeamons {

	# mcstrans category label translation
	service {
		"mcstrans":
			enable => false,
			ensure => stopped,
			hasstatus => false,
			hasrestart => true;
	}

	# Packages which are mostly unused

	# SElinux troubleshoot deamon
	package { setroubleshoot: ensure => absent }

	#  Talk server
	package { talk: ensure => absent }
	package { talk-server: ensure => absent }
}
