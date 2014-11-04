#!C:\perl\perl\bin
use Modern::Perl;
$|++;

# http://www.matthewflickinger.com/lab/whatsinagif/bits_and_bytes.asp

my @files;
my $short = 0;
if (@ARGV){
	@files = @ARGV;
}
if (!@files){
	@files = glob "*.gif";
}

for my $srcfile (@files){
	my $destfile = $srcfile;
	$destfile =~ s/\.gif/_10fps.gif/;

	open my $inf, '<', $srcfile
		or die "\nCan't open $srcfile for reading: $!\n";

	binmode $inf;

	my $buf;
	read($inf, $buf, 838860800) #100 megs
		|| die $!;

	my $blob = unpack('H*', $buf)
		|| die $!;
	
	# according to the XMP spec ( http://wwwimages.adobe.com/www.adobe.com/content/dam/Adobe/en/devnet/xmp/pdfs/XMPSpecificationPart3.pdf ):
	# there should only be one XMP block in a file. also according to the XMP spec: XMP doesn't serve an actual purpose
	my $xmp = 0;
	if ($blob =~ s/21FF0B(584D50.+?)0000(?=21F9)//i){ 
		say 'Found some XMP in '.$srcfile;
		$xmp = $1; # pass this to gifinfo later just in case
	}
	
	#the actual part that repairs the gif
	if ($blob =~ s/(?<=21F904(?:\S\S))(0000)/0A00/gi || $xmp){
		say 'REPAIRING '.$srcfile;
		
		open my $outf, '>', $destfile
			|| die "\nCan't open $destfile for writing: $!\n";
		binmode $outf;	
		print($outf pack('H*', $blob));
		close $outf
			|| die "Can't close $destfile: $!\n";
	
		close $inf
			|| die "Can't close $srcfile: $!\n";
		
		unlink $srcfile #probably unnecessary; rename clobbers
			|| die $!;
		
		rename $destfile, $srcfile;
	}
	my ($rate, $pretty_info) = gifinfo($blob, $xmp);
	say (sprintf("%-26s", $srcfile).'||'.$pretty_info);
	say '';
}

$^O eq 'MSWin32' 
	? system 'pause' 
	: system 'read -p "Press any key to continue."';
exit;

sub gifinfo {
	my $blob = $_[0];
	my @dims = $blob =~ /474946383961(.{4})(.{4})/;
	map { $_ =~ s/(..)(..)/$2$1/ } @dims; #multibyte values in gifs are backwards
	my $dims = hex($dims[0]).'x'.hex($dims[1]);	
	
	my @frames = $blob =~ /(21F904)/ig;
	my $framect = scalar(@frames);
			
	if ($framect == 1){
		warn "This GIF is not animated\n";
	}
	
	# because you can set the delay of each frame, simply pulling the delay value from frame 1 can be inaccurate
	my @delays = $blob =~ /(?<=21F904(?:\S\S))([0-9A-F]{4})/ig;	
	map { $_ =~ s/(..)(..)/$2$1/ } @delays;
	my $play_time;
	for (@delays){
		$play_time += hex($_);
	}
	# $play_time is the total play time of the gif in milliseconds
	my $framerate = $play_time;
	$framerate /= $framect;
	# $framerate is the average frame interval in ms
	$play_time /= 100;
	# $play_time is now measured in seconds instead of milliseconds
		
	# my $fps = sprintf("%.2f", ($framerate/$framect));
	# $fps =~ s/(?:\.0)?0$//;
	
	my $size = sprintf("%f", ((0.5 * length $blob)/1024));
	
	my $out = sprintf " %s // %d frames @ %sms/f = %.1fs // %dkB",
		$dims, $framect, $framerate, $play_time, $size;
	
	return ($framerate, $out);
}