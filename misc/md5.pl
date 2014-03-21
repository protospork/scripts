#!C:\perl\perl\bin
use Modern::Perl;
use Digest::MD5;

my @files;
if (@ARGV){
	@files = @ARGV;
} else {
	@files = glob "*.jpg *.png";
}

for my $this (@files){
	my ($ext) = $this =~ /\.(\w{2,4})$/;
	
	open my $file, $this || die $!;
	binmode($file);
	my $md5 = Digest::MD5->new;
	while(<$file>){ $md5->add($_); }
	close $file;	
	my $hash = $md5->b64digest;
	
	$hash =~ s/\//_/g;
	say $this.' => '.$hash;
	rename ($this, $hash.'.'.$ext) || die $!;
}