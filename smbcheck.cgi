#!/usr/bin/perl

use strict;
use warnings;

#Open files
open(FSTAB, "< /etc/fstab");
open(MOUNTS, "< /proc/mounts");

#Variables
my (%fstablines, %mountslines, $smbpaths, $smbmounts);

#Read from files
while( <FSTAB> ) 
{
#Erase commments to ignore
       s/#.*//;

#Skip blank lines
       next if /^(\s)*$/;

#Continue loop if line doesn't start with //
       next if !m/^\/\//;

#Regex to separate column one and two device/mountpoint
#This is the regular expression for Red Hat fstab. On other *nixes your mileage may vary.
#If the fstab does not contain a space behind the mount device and mount point (i.e. a tab),
#you will need to change the [\s] points to [\t] for tabs.

       /^(\/\/[a-zA-Z0-9\/].+?)[\s]([a-zA-Z0-9\/].+?)[\s].+?/;

       $fstablines{$1} = $2;
}

while( <MOUNTS> )
{
#Essentially the same lines of code above in the FSTAB parse
       s/#.*//;
       next if /^(\s)*$/;
       next if !m/^\/\//;
       /^(\/\/[a-zA-Z0-9\/].+?)[\s]([a-zA-Z0-9\/].+?)[\s].+?/;
       $mountslines{$1} = $2;
}

#print the header and html
print "Content-type: text/html\n\n";

print <<"EOF";
<HTML>

<HEAD>
<TITLE>Samba Checker</TITLE>
</HEAD>

<BODY>
EOF

#Make sure that the paths in /etc/fstab are in /proc/mounts
foreach my $smbpaths (keys %fstablines)
{
	if(exists $mountslines{$smbpaths})
	{
		print "$smbpaths: SUCCESS<BR>";
	}
	else
	{	
		$smbmounts = $fstablines{$smbpaths};
		print "$smbpaths: FAILURE<BR>";
		print "Should be mounted to $smbmounts<BR>";
	}
}

print "</BODY>\n</HTML>";
