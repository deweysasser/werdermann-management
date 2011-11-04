#!/usr/bin/perl

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


use strict;
use Getopt::Long;

# --------------------------------------------------------------------
#
# Check for specified pattern in commandoutput. It executes the given command
# with given parameter and uses Perl regex to grep the output for the
# specified patterns.
#
# @author: Daniel Werdermann / dwerdermann@web.de
# @date: 2011-10-26 14:52:12 CEST
# @version:
my $plugin_version = "1.1";
#
# changes 1.1
#  - add license information
# -------------------------------------------------------------------

# nagios exit codes
use constant EXIT_OK            => 0;
use constant EXIT_WARNING       => 1;
use constant EXIT_CRITICAL      => 2;
use constant EXIT_UNKNOWN       => 3;

my $plugin_name = "Nagios check_execgrep";
my $version;
my $help;
my $contains = "YES";
my $critpattern;
my $warnpattern;
my $command;
my $parameter;

GetOptions (
	"version"     => \$version,
	"help"        => \$help,
	"contains=s"  => \$contains,
	"critical=s"  => \$critpattern,
	"warning=s"   => \$warnpattern,
	"command=s"   => \$command,
	"parameter=s" => \$parameter
);

version() if $version;
usage() if $help;

if ( !defined $critpattern ) {
	print "CRITICAL: no critical pattern defined!\n\n";
	usage();
} elsif ( !defined $warnpattern ) {
	print "CRITICAL: no warning pattern defined!\n\n";
	usage();
} elsif ( !defined $command ) {
	print "CRITICAL: no command for execution defined!\n\n";
	usage();
}

sub usage {
	print << "EOF"

This plugin executes a given command and greps for spedified patterns in the
output. It uses perl regex for matching.

Usage: $0 --help
       $0 [--contains YES|NO] --warning REGEX --critical REGEX --command Sring 
          [--parameter String]

Options:
 --help 
    Print detailed this screen
 --version
    Print version information
 --contains YES|NO
    Defines if the command output must or must not contain
    the patterns defined in warning and critical (Default: YES)
 --warning REGEX
    Regex to search for in command output for warning.
 --critical REGEX
    Regex to search for in command output for critical.
 --command STRING
    Command to be executed.
 --parameter STRING
    Parameter for the command.

Examples:
 $0 --contains YES --warning \"\\d{2}\" --critical 333 --command /bin/bla
    
    This returns a warning if the output of /bin/bla contains two 
    digist (e.g. 23 or 01) and a critical if 333 was found.

 $0 --contains NO --warning 22 --critical b --command /bin/cat --parameter /etc/services
    
    Execute `/bin/cat /etc/services` and send warning if NO "22" was found and
    critical if NO "b" was found in output.

 This plugin is NOT developped by the Nagios Plugin group.
 Please do not e-mail them for support on this plugin, since
 they won't know what you're talking about.

 For contact info, read the plugin itself...

EOF
;
	exit EXIT_CRITICAL;
}

sub version {
	print "$plugin_name v. $plugin_version\n";
	exit EXIT_OK;
}

my $crit_count = 0;
my $warn_count = 0;

if (! -x $command) {
	print "CRITICAL: Cannot execute command: '$command'";
	exit EXIT_CRITICAL;
}

my @execute = ($command, $parameter);

# make unbuffered output
$|=1;
open STDERR, ">&STDOUT" or die "Can’t dup STDOUT: $!";

eval {
	my @return = `@execute`;
	if ( $? != 0 ) {
		 print "command returns an errorcode $?: '@execute'";
		exit (2);
	}

	foreach ( @return ) {
		$crit_count++ if m/$critpattern/;
		$warn_count++ if m/$warnpattern/;
	}

	if ($crit_count == 0 && $contains eq "NO") {
		$crit_count++;
	} elsif ($crit_count && $contains eq "NO") {
		$crit_count = 0;
	}

	if ($warn_count == 0 && $contains eq "NO") {
		$warn_count++;
	} elsif ($warn_count && $contains eq "NO") {
		$warn_count = 0;
	}

	my $notstring = "not " if $contains eq "NO";
	if ($crit_count) {
		print "CRITICAL: '".$critpattern."' was ".$notstring."found in '@execute'";
		exit(2);
	} elsif ($warn_count) {
		print "WARNING: '".$warnpattern."' was ".$notstring." found in '@execute'";
		exit(1);
	}

	print "OK: nothing obvious in '@execute'";
	exit(0);
};

if ($@) {
	print "CRITICAL: $@";
	exit EXIT_CRITICAL;
}

print "OK: no critical or warning patterns found";
exit EXIT_OK;

