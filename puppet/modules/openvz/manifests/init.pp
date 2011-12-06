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

class s_openvz { }

class s_openvz::getTemplateCentOS64 {
        exec {
                "get CentOS5 64 template":
                        command => "wget -c http://download.openvz.org/template/precreated/centos-5-x86_64.tar.gz",
                        cwd => "/vz/template/cache/",
                        require => [Package["ovzkernel"],Package["vzctl"]],
                        creates => "/vz/template/cache/centos-5-x86_64.tar.gz";
        }
}

class s_openvz::getTemplateDebian64 {
        exec {
                "get Debian6 64 template":
                        command => "wget -c http://download.openvz.org/template/precreated/debian-6.0-x86_64.tar.gz",
                        cwd => "/vz/template/cache/",
                        require => [Package["ovzkernel"],Package["vzctl"]],
                        creates => "/vz/template/cache/debian-6.0-x86_64.tar.gz";
        }
}

