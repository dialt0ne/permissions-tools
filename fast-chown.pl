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

sub fastChown {
	my ($startdir,$targetuid,$targetgid) = @_;
	my @dirs;
	my @todo;
	print STDOUT "traversing $startdir:\n";
	my $entcount = 0;
	my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks)
		= lstat($startdir);
	if ( $uid != $targetuid || $gid != $targetgid ) {
		if ( $opt_queue )  {
			print STDERR "queuing $startdir\n" if DEBUG;
			push(@todo,$startdir);
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
			print STDOUT "." if $entcount && $entcount % 1000 == 0;
			$entcount++;
			next ENT if $ent eq ".";
			next ENT if $ent eq "..";
			print STDERR "trying $dir/$ent\n" if DEBUG;
			my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks)
				= lstat("$dir/$ent");
			if ( $uid != $targetuid || $gid != $targetgid ) {
				if ( $opt_queue )  {
					print STDERR "queuing $dir/$ent\n" if DEBUG;
					push(@todo,"$dir/$ent");
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
		my $qtotal = $#todo + 1;
		print STDOUT "queue total: $qtotal \n";
		my $qcount=0;
		foreach my $ent (@todo) {
			print STDERR "CHOWN $ent\n" if DEBUG;
			lchown($targetuid,$targetgid,"$ent");
			print STDOUT "$qcount," if $qcount && $qcount % 1000 == 0;
			$qcount++
		}
		print STDOUT "done. $qcount chown'd\n";
	}
}

my ($opt_path,$opt_uid,$opt_gid);
Getopt::Long::Configure('bundling');
GetOptions(
        "p=s" => \$opt_path, "path=s" => \$opt_path,
        "u=i" => \$opt_uid,  "uid=i" => \$opt_uid,
        "g=i" => \$opt_gid,  "gid=i" => \$opt_gid,
	"q" => \$opt_queue,  "queue" => \$opt_queue,
        "d" => \$opt_debug,  "debug" => \$opt_debug,
);

if (! $opt_path ) {
        print STDERR "need to supply a path with --path\n";
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

fastChown($opt_path,$opt_uid,$opt_gid);

