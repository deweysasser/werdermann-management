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



class atlassian {
	class { "tomcat": tcversion => 6}
}

class atlassian::jira inherits atlassian ($svcnr=01) {

	# now we install the jira sources into the tomcat

	file {
		"/opt/tomcat/webapps/jira-${svcnr}/":
			ensure => directory,
			owner => tomcat,
			group => services,
			mode => 755,
			require => File["/opt/tomcat"];
	}
}

class atlassian::confluence inherits atlassian {}

class atlassian::fisheye inherits atlassian {

	# so its a git source tool, we do need git tools

	include git::client
	
}
