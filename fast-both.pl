#!/usr/bin/perl
# Author: Anthony Tonns
# 
# Copyright 2014 Corsis
# http://www.corsis.com/
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

use strict;
use Lchown;
use Getopt::Long;

select STDERR;
$|=1;
select STDOUT;
$|=1;

my $opt_debug = 0;
sub DEBUG { $opt_debug; }
my $opt_queue = 0;

sub fastBoth {
	my ($startdir,$modestring,$targetuid,$targetgid) = @_;
	my $targetmode = oct($modestring);
	my @dirs;
	my @modetodo;
	my @ownertodo;
	print STDOUT "traversing $startdir:\n";
	my $entcount = 0;
	my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks)
		= lstat($startdir);
	$mode &= 07777;
	if ( $mode != $targetmode ) {
		if ( $opt_queue )  {
			printf STDERR "mode queuing $startdir (%o)\n",$mode if DEBUG;
			push(@modetodo,$startdir);
		}
		else {
			print STDERR "CHMOD $startdir\n" if DEBUG;
			chmod($targetmode,$startdir);
		}
	}
	if ( $uid != $targetuid || $gid != $targetgid ) {
		if ( $opt_queue )  {
			print STDERR "owner queuing $startdir\n" if DEBUG;
			push(@ownertodo,$startdir);
		}
		else {
			print STDERR "CHOWN $startdir\n" if DEBUG;
			lchown($targetuid,$targetgid,$startdir);
		}
	}
	push(@dirs,$startdir);
	while($#dirs >= 0) {
		my $dir = pop(@dirs);
		print STDERR "popped $dir\n" if DEBUG;
		local *D;
		opendir(D,$dir);
		my @ents = readdir D;
		closedir(D);
		ENT: foreach my $ent (@ents) {
			next ENT if $ent eq ".";
			next ENT if $ent eq "..";
			print STDOUT "." if $entcount && $entcount % 1000 == 0;
			$entcount++;
			print STDERR "trying $dir/$ent\n" if DEBUG;
			my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks)
				= lstat("$dir/$ent");
			$mode &= 07777;
			if ( $mode != $targetmode) {
				if ( $opt_queue )  {
					printf STDERR "mode queuing $dir/$ent (%o)\n",$mode if DEBUG;
					push(@modetodo,"$dir/$ent");
				}
				else {
					print STDERR "CHMOD $dir/$ent\n" if DEBUG;
					chmod($targetmode,"$dir/$ent");
				}
			}
			if ( $uid != $targetuid || $gid != $targetgid ) {
				if ( $opt_queue )  {
					print STDERR "owner queuing $dir/$ent\n" if DEBUG;
					push(@ownertodo,"$dir/$ent");
				}
				else {
					print STDERR "CHOWN $dir/$ent\n" if DEBUG;
					lchown($targetuid,$targetgid,"$dir/$ent");
				}
			}
			if ( -d _ ) {
				push(@dirs,"$dir/$ent");
				next ENT;
			}
		}
	}
	print STDOUT "done. $entcount files and dirs examined.\n";
	if ( $opt_queue )  {
		my $modeqtotal = $#modetodo + 1;
		print STDOUT "mode queue total: $modeqtotal \n";
		my $modeqcount=0;
		foreach my $ent (@modetodo) {
			print STDERR "CHMOD $ent\n" if DEBUG;
			chmod($targetmode,$ent);
			print STDOUT "$modeqcount," if $modeqcount && $modeqcount % 1000 == 0;
			$modeqcount++
		}
		print STDOUT "done. $modeqcount chmod'd\n";
		my $ownerqtotal = $#ownertodo + 1;
		print STDOUT "owner queue total: $ownerqtotal \n";
		my $ownerqcount=0;
		foreach my $ent (@ownertodo) {
			print STDERR "CHOWN $ent\n" if DEBUG;
			lchown($targetuid,$targetgid,"$ent");
			print STDOUT "$ownerqcount," if $ownerqcount && $ownerqcount % 1000 == 0;
			$ownerqcount++
		}
		print STDOUT "done. $ownerqcount chown'd\n";

	}
}

my ($opt_path,$opt_uid,$opt_gid,$opt_mode);
Getopt::Long::Configure('bundling');
GetOptions(
        "p=s" => \$opt_path, "path=s" => \$opt_path,
        "m=i" => \$opt_mode, "mode=i" => \$opt_mode,
        "u=i" => \$opt_uid,  "uid=i" => \$opt_uid,
        "g=i" => \$opt_gid,  "gid=i" => \$opt_gid,
        "q" => \$opt_queue,  "queue" => \$opt_queue,
        "d" => \$opt_debug,  "debug" => \$opt_debug,
);

if (! $opt_path ) {
        print STDERR "need to supply a path with --path\n";
	exit(1);
}

if (! $opt_mode ) {
        print STDERR "need to supply a numeric mode with --mode\n";
	exit(1);
}

if (! $opt_uid ) {
        print STDERR "need to supply a numeric uid with --uid\n";
        exit(1);
}

if (! $opt_gid ) {
        print STDERR "need to supply a numeric gid with --gid\n";
        exit(1);
}

fastBoth($opt_path,$opt_mode,$opt_uid,$opt_gid);

