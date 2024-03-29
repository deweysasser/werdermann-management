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

# --------------------------------------------------------------------
# Check for specified pattern in commandoutput
#
# @author: Daniel Werdermann / dwerdermann@web.de
# @version: 1.1
# @date: Thu Oct 23 14:31:52 CEST 2008
#
# changes 1.1
#  - add license information
# --------------------------------------------------------------------

use strict;
use warnings;
use Getopt::Long;

my $help;
my $redirect;
my $table;

my $command = "/usr/sbin/relayctl";
my $parameter = "show summary";

GetOptions (
	"help"        => \$help,
	"redirect=s"  => \$redirect,
	"table=s"  => \$table,
);

usage() if $help;

sub usage {
	print << "EOF"
Usage: $0 --help
       $0 [--redirect STRING] [--table STRING]

This script checks the OpenBSD relayd. It returns a warning
if not all hosts in a table are up and a critical if a table
and/or redirect is totally down.

Options:
 --help 
    Print detailed this screen
 --redirect STRING
    String with name of redirect to check. Multiple redirects
    can be seperated by comma
 --table STRING
    String with name of table to check. Multiple tabless
    can be seperated by comma

Examples:
 $0 

    Checks if all redirects, tables and hosts which are
    defined at the relayd startup are active.

 $0 --redirect smtp --table pmtahost,pmtahostfallback
    
    Checks if the specified redirects and tables exists.
    Besides there will be an alert if any other redirect
    or table defined in the checked relayd is not active.
    Or if any hosts are down.

    This plugin is NOT developped by the Nagios Plugin group.
    Please do not e-mail them for support on this plugin, since
    they won't know what you're talking about.

    For contact info, read the plugin itself...

EOF
;
	exit(2);
}

my %cnt_redirects;
if (defined $redirect) {
	foreach ( split(/,/, $redirect) ) {
		$cnt_redirects{$_} = 0;
	}
}

my %cnt_tables;
if (defined $table) {
	foreach ( split(/,/, $table) ) {
		$cnt_tables{$_} = 0;
	}
}

my %cnt_hosts = (
	'down'	=> 0,
	'up'	=> 0
);


if (! -x $command) {
	print "CRITICAL: Cannot execute command: '$command'";
	exit(2);
}

my @execute = ($command, $parameter);

# make unbuffered output
$|=1;
open STDERR, ">&STDOUT" or die "Can’t dup STDOUT: $!";

eval {
	my @return = split(/\n/, `@execute`) 
		or die "command returns an errorcode $?: '@execute'";

	foreach ( @return ) {
		chomp;
		if (/up$/) { $cnt_hosts{'up'}++ ; next; }
		if (/down$/ or /disabled$/) { $cnt_hosts{'down'}++ ; next; }
		if (/\d+\s+redirect\s+(.*?)\s+active$/) {
			$cnt_redirects{$1}++;
			next;
		}
		if (/\d+\s+table\s+(.*?)\s+(.*?)\s/) {
			$cnt_tables{$1} = $2;
			next;
		}
	}

	if ( $cnt_hosts{'up'} == 0 ) {
		print "CRITICAL: relayd does not find any hosts up\n";
		exit(2);
	} 

	for my $red ( keys %cnt_redirects ) {
		if ( $cnt_redirects{$red} == 0 ) {
			print "CRITICAL: Redirect $red is not active\n";
			exit(2);
		}
	}

	for my $tab ( keys %cnt_tables ) {
		if ( $cnt_tables{$tab} ne "active" ) {
			print "CRITICAL: Table $tab is not active\n";
			exit(2);
		}
	}

	if ( $cnt_hosts{'down'} != 0 ) {
		print "WARNING: relayd cannot reach all hosts. $cnt_hosts{'down'} hosts are down or disabled\n";
		exit(1);
	}

	print "OK: nothing obvious in '@execute'";
	exit(0);
};

if ($@) {
	print "CRITICAL: $@";
	exit(2);
}

print "OK: no critical or warning patterns found";
exit(0);

