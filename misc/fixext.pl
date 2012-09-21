#!/usr/bin/perl
use Modern::Perl;
use File::MMagic;

# This script uses MAGIC (numbers) to rename images to have proper extensions. 
# (Okay, so it just calls a module to do it)
# There's a unix hashbang up there but I'm only testing this in windows (strawberry perl 5.12)

# INSTALL:
# Step 1: 
# Make sure you actually have perl (http://strawberryperl.com/). 
# Open a cmd window/terminal, type `cpan -i Modern::Perl`, wait for it, then `cpan -i File::MMagic`
#
# Step 2:
#  Windows: Make a file called fixext.bat containing the line 'perl "C:\path\to\fixext.pl"'.
#  Put the .bat file in C:\Windows\System32 or anywhere else in your PATH.
#
#  Linux: alias fixext='perl path/to/fixext.pl'
#
# Now you can invoke the script from any directory with "fixext".

# Aug 10, 2012 by protospork. public domain and shit

#useful trick, since I haven't added recursion yet:
# perl -MCwd -e "$here = cwd; for (<*>){ next if /\./; chdir $_; system 'fixext'; chdir $here; } system 'fixext';"

my $recurse = 1; 
#Scans into every subfolder. Can be disabled with the -l ("local") option

my $silent = 0; 
#1 if you don't want to be told what the script is doing. you can also call the script with -q ("quiet"). 
#If you enable this, I recommend enabling the next option too.

my $preserve_ext = 0; 
#1 if you want to always keep the original file extension, 
#but append the real one (to make it clickable/fix thumbnailing). Matches -p (backwards q / "preserve")

my $all_types = 0; 
#with this disabled, only scan jpe?g/gif/png (I recommend it stays disabled, you can use -e ("everything"))

if (@ARGV){
	if ($ARGV[0] =~ /^-(\w+)/){                 #SWITCHES
		my $args = $1;
		shift @ARGV; 
		if ($args =~ /l/){ $recurse      = 0; } #l for "local"
		if ($args =~ /q/){ $silent       = 1; } #q for "quiet"
		if ($args =~ /p/){ $preserve_ext = 1; } #p for "preserve" extensions (it's a backwards q)
		if ($args =~ /e/){ $all_types    = 1; } #e for "everything"
	}
}
my $stay = 0;

sub fixext {
	my $name;
	if ($recurse){ $name = $_; } else { $name = shift; }
	
	if (! $all_types && $name !~ /\.(jpe?g|gif|png|bmp)/i){ return; }
	
	my $diskmime = File::MMagic->new->checktype_filename($name);

	if ($diskmime !~ /image/){
		return if $diskmime =~ /x-system|octet-stream/; #folders are x-system/x-unix, I think IO errors are x-system too
		say 'not an image: '.$name unless $silent;
	}

	my $newext = $diskmime;
	$newext =~ s{image/jpeg}{.jpg}i
	|| $newext =~ s{image/png}{.png}i
	|| $newext =~ s{image/gif}{.gif}i
	|| $newext =~ s{image/bmp}{.bmp}i
	|| $newext =~ s{(^|/)}{.}g; #should filename-safe any erroneous mimetypes
			
	my $newname = $name;
	$newname =~ s/(\.(jpe?g|gif|png))?$|(\.[^.]+?)?$//i unless $preserve_ext; #second match case added for -e
	$newname .= $newext;

	if ($name ne $newname){
		if (! $silent){
			if ($recurse){
				say $File::Find::name.' => '.$newname;
			} else {
				say $name.' => '.$newname;
			}
		}
		rename $name, $newname;
		$stay++;
	}
}

if (! $recurse){
#pre-File::Find search method, doesn't check subdirs
	if ($all_types){
		fixext $_ for <*>; 
	} else {
		fixext $_ for <*.jpg *.jpeg>;
		fixext $_ for <*.png>;
		fixext $_ for <*.gif>;
		fixext $_ for <*.bmp>;
	}
} else {
#File::Find method, does
	use File::Find;
#	no warnings 'File::Find';
	finddepth(\&fixext, '.');
}



#make the window hang around until you press the Any key
if ($stay && ! $silent){
	$^O eq 'MSWin32' 
		? system 'pause' 
		: system 'read -p "Press any key to continue."';
	exit;
}